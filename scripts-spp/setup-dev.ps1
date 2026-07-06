# Copyright (c) 2026 CEA LIST / Kunal Suri. All rights reserved.
#Requires -Version 5.1
<#
.SYNOPSIS
    SysON++ Developer Setup & Run — one-click Windows launcher.

.DESCRIPTION
    Checks every required dependency, guides you through any missing
    installations, then starts all three tiers in separate windows:
      [1] PostgreSQL via Docker          (port 5432)
      [2] Java / Spring Boot backend     (port 8080)
      [3] React / TypeScript frontend    (port 5173)

    On first run the Maven build takes 5-15 min; subsequent runs with
    -SkipBuild take ~30 seconds.

.PARAMETER SkipBuild
    Skip the Maven build and npm install steps. Use when restarting
    after a clean shutdown without code changes.

.PARAMETER ForceBuild
    Force building the backend and installing npm packages even if they are already built.

.PARAMETER BackendOnly
    Start only the database and backend.

.PARAMETER FrontendOnly
    Start only the frontend dev server. Assumes the backend is running.

.PARAMETER CheckOnly
    Check dependencies and exit — do not build or start anything.

.PARAMETER StopAll
    Stop all running SysON++ services (database, backend, frontend).

.EXAMPLE
    .\scripts-spp\setup-dev.ps1                   # First-time setup and full start
    .\scripts-spp\setup-dev.ps1 -SkipBuild        # Quick restart (no rebuild)
    .\scripts-spp\setup-dev.ps1 -CheckOnly        # Verify your environment
    .\scripts-spp\setup-dev.ps1 -StopAll          # Stop everything
#>

[CmdletBinding()]
param(
    [switch]$SkipBuild,
    [switch]$ForceBuild,
    [switch]$BackendOnly,
    [switch]$FrontendOnly,
    [switch]$CheckOnly,
    [switch]$StopAll
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ── Pinned versions (from package.json / pom.xml) ─────────
$NODE_MAJOR_REQUIRED   = 22
$NODE_EXACT_REQUIRED   = "22.16.0"
$NPM_EXACT_REQUIRED    = "10.9.2"
$JAVA_MAJOR_REQUIRED   = 21
$APP_VERSION           = "2026.5.2"
$BACKEND_PORT          = 8080
$FRONTEND_PORT         = 5173
$DB_PORT               = 5432

# PostgreSQL creds (match docker-compose.yml in backend/application/syson-application/)
$DB_USER     = "test_username"
$DB_PASSWORD = "test_password"
$DB_NAME     = "postgres"

$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$ROOT_DIR   = Split-Path -Parent $SCRIPT_DIR
$COMPOSE_FILE = Join-Path $ROOT_DIR "backend\application\syson-application\docker-compose.yml"
$SETTINGS_XML = Join-Path $ROOT_DIR "settings.xml"

# Discover the executable JAR dynamically if it exists; fall back to versioned JAR if not built yet
$discoveredJar = Get-Item "$ROOT_DIR\backend\application\syson-application\target\syson-application-*.jar" `
    -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -notmatch '-sources\.jar$' } |
    Select-Object -First 1

if ($discoveredJar) {
    $BACKEND_JAR = $discoveredJar.FullName
} else {
    $BACKEND_JAR = Join-Path $ROOT_DIR "backend\application\syson-application\target\syson-application-$APP_VERSION.jar"
}

# ── Environment bootstrap ──────────────────────────────────
# Refresh PATH and activate fnm-managed Node on every run so checks are accurate
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
            [System.Environment]::GetEnvironmentVariable("Path", "User")
if (-not [string]::IsNullOrEmpty($env:JAVA_HOME)) {
    $env:Path = "$env:JAVA_HOME\bin;$env:Path"
} elseif (Get-Command java -ErrorAction SilentlyContinue) {
    $javaExe = (Get-Command java).Source
    $env:JAVA_HOME = Split-Path (Split-Path $javaExe -Parent) -Parent
}
if (Get-Command fnm -ErrorAction SilentlyContinue) {
    try { fnm env --shell powershell | Out-String | Invoke-Expression } catch { }
    try { fnm use $NODE_EXACT_REQUIRED 2>$null } catch { }
}

# Resolve GitHub username (GitHub packages auth uses USERNAME and PASSWORD env vars via settings.xml)
$ghUser = $env:GITHUB_USERNAME
if ([string]::IsNullOrWhiteSpace($ghUser)) {
    $ghUser = [Environment]::GetEnvironmentVariable("GITHUB_USERNAME", "User")
}
if ([string]::IsNullOrWhiteSpace($ghUser)) {
    $ghUser = [Environment]::GetEnvironmentVariable("GITHUB_USERNAME", "Machine")
}
if ([string]::IsNullOrWhiteSpace($ghUser) -and (Get-Command git -ErrorAction SilentlyContinue)) {
    $gitUser = (git config user.name 2>$null)
    if (-not [string]::IsNullOrWhiteSpace($gitUser) -and $gitUser -notmatch '\s') {
        $ghUser = $gitUser
    } else {
        $gitEmail = (git config user.email 2>$null)
        if (-not [string]::IsNullOrWhiteSpace($gitEmail) -and $gitEmail -match '^([^@]+)@') {
            $ghUser = $Matches[1]
        }
    }
}
if (-not [string]::IsNullOrWhiteSpace($ghUser)) {
    $env:USERNAME = $ghUser
}

# ── Helper functions ───────────────────────────────────────
function Write-Banner {
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║         SysON++ — Developer Environment Setup & Run         ║" -ForegroundColor Cyan
    Write-Host "  ║       Java backend  +  React/TS frontend  +  PostgreSQL      ║" -ForegroundColor Cyan
    Write-Host "  ╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Section($title) {
    Write-Host ""
    Write-Host "  ┌─ $title" -ForegroundColor Cyan
    Write-Host "  │" -ForegroundColor DarkCyan
}

function Write-OK($msg)   { Write-Host "  │  [✓] $msg" -ForegroundColor Green }
function Write-WARN($msg) { Write-Host "  │  [!] $msg" -ForegroundColor Yellow }
function Write-FAIL($msg) { Write-Host "  │  [✗] $msg" -ForegroundColor Red }
function Write-INFO($msg) { Write-Host "  │      $msg" -ForegroundColor Gray }
function Write-SectionEnd { Write-Host "  └" -ForegroundColor DarkCyan }

function Test-CommandExists($cmd) {
    $null -ne (Get-Command $cmd -ErrorAction SilentlyContinue)
}

function Invoke-WinGet($packageId, $version = $null) {
    if (-not (Test-CommandExists "winget")) {
        Write-FAIL "winget is not available. Please install from the Microsoft Store (App Installer)."
        return $false
    }
    $args = @("install", "--id", $packageId, "--exact", "--accept-package-agreements", "--accept-source-agreements")
    if ($version) { $args += @("--version", $version) }
    winget @args
    return ($LASTEXITCODE -eq 0)
}

function Refresh-Path {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("Path", "User")
    # Auto-detect JAVA_HOME if not set
    if ([string]::IsNullOrEmpty($env:JAVA_HOME) -and (Get-Command java -ErrorAction SilentlyContinue)) {
        $javaExe = (Get-Command java).Source
        $env:JAVA_HOME = Split-Path (Split-Path $javaExe -Parent) -Parent
    }
    # Re-initialise fnm so the correct Node version is active
    if (Get-Command fnm -ErrorAction SilentlyContinue) {
        try { fnm env --shell powershell | Out-String | Invoke-Expression } catch { }
        try { fnm use $NODE_EXACT_REQUIRED 2>$null } catch { }
    }
}

function Prompt-YesNo($question) {
    $ans = Read-Host "  │  $question [Y/n]"
    return ($ans -ne 'n' -and $ans -ne 'N')
}

function Wait-ForPort($port, $timeoutSec = 60, $label = "service") {
    Write-INFO "Waiting for $label to listen on port $port (up to ${timeoutSec}s)..."
    $elapsed = 0
    while ($elapsed -lt $timeoutSec) {
        try {
            $tcp = New-Object System.Net.Sockets.TcpClient
            $tcp.Connect("127.0.0.1", $port)
            $tcp.Close()
            Write-OK "$label is ready on port $port"
            return $true
        } catch { }
        Start-Sleep -Seconds 2
        $elapsed += 2
        Write-Host "." -NoNewline -ForegroundColor Gray
    }
    Write-Host ""
    Write-WARN "$label did not respond on port $port after ${timeoutSec}s — check the service window for errors."
    return $false
}

function Open-ServiceWindow($title, $command, $workDir) {
    $escapedCmd = $command -replace '"', '\"'
    $ps = "Set-Location '$workDir'; Write-Host '$title' -ForegroundColor Cyan; $escapedCmd; Write-Host 'Process exited.' -ForegroundColor Yellow; Read-Host 'Press Enter to close'"
    $wt = Get-Command "wt.exe" -ErrorAction SilentlyContinue
    if ($wt) {
        Start-Process "wt.exe" -ArgumentList "new-tab", "--title", $title, "pwsh", "-NoExit", "-Command", $ps
    } else {
        Start-Process "pwsh" -ArgumentList "-NoExit", "-Command", $ps
    }
}

# ── Stop mode ─────────────────────────────────────────────
if ($StopAll) {
    Write-Banner
    Write-Section "Stopping SysON++ services"

    # [1] Backend — match on command line so other JVMs (IntelliJ etc.) are NOT touched
    Write-INFO "Stopping SysON++ Java backend..."
    $sysonJava = Get-CimInstance Win32_Process -Filter "Name='java.exe'" |
        Where-Object { $_.CommandLine -like '*syson-application*' }
    if ($sysonJava) {
        foreach ($p in $sysonJava) {
            Stop-Process -Id $p.ProcessId -Force -ErrorAction SilentlyContinue
            Write-OK "Stopped Java PID $($p.ProcessId)."
        }
    } else {
        # Fallback: java process owning port 8080 only
        $port8080 = Get-NetTCPConnection -LocalPort $BACKEND_PORT -State Listen -ErrorAction SilentlyContinue |
            ForEach-Object { Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue } |
            Where-Object { $_ -and $_.Name -eq 'java' }
        if ($port8080) {
            $port8080 | ForEach-Object {
                Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
                Write-OK "Stopped Java on port $BACKEND_PORT (PID $($_.Id))."
            }
        } else {
            Write-WARN "No SysON++ Java process found — already stopped."
        }
    }

    # [2] Frontend — kill only the process owning port 5173, not all node processes
    Write-INFO "Stopping SysON++ frontend (port $FRONTEND_PORT)..."
    $port5173 = Get-NetTCPConnection -LocalPort $FRONTEND_PORT -State Listen -ErrorAction SilentlyContinue |
        ForEach-Object { Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue } |
        Where-Object { $_ }
    if ($port5173) {
        $port5173 | Sort-Object Id -Unique | ForEach-Object {
            Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
            Write-OK "Stopped frontend '$($_.Name)' (PID $($_.Id))."
        }
    } else {
        Write-WARN "No process on port $FRONTEND_PORT — already stopped."
    }

    # [3] PostgreSQL — stop only, container stays visible in Docker Desktop
    # NOTE: 'compose stop' preserves the container. 'compose down' would delete it — do not use.
    Write-INFO "Stopping PostgreSQL container (container preserved, not removed)..."
    if (-not (Test-Path $COMPOSE_FILE)) {
        Write-FAIL "Compose file not found: $COMPOSE_FILE"
    } elseif (Get-Command docker -ErrorAction SilentlyContinue) {
        $oldEAP = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        docker info 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            docker compose -f $COMPOSE_FILE stop database 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-OK "PostgreSQL container stopped (not removed)."
            } else {
                Write-FAIL "docker compose stop failed — check Docker Desktop."
            }
        } else {
            Write-WARN "Docker daemon not running — skipping."
        }
        $ErrorActionPreference = $oldEAP
    } else {
        Write-WARN "Docker not found — skipping."
    }

    Write-SectionEnd
    Write-Host "`n  All SysON++ services stopped.`n" -ForegroundColor Green
    exit 0
}

# ═══════════════════════════════════════════════════════════
# PHASE 1 — DEPENDENCY CHECK
# ═══════════════════════════════════════════════════════════
Clear-Host
Write-Banner
Write-Section "Phase 1 of 5 — Dependency Check"

# Temporarily set ErrorActionPreference to Continue so stderr from java/mvn doesn't crash the script
$oldEAP = $ErrorActionPreference
$ErrorActionPreference = "Continue"

$missing = [System.Collections.Generic.List[string]]::new()

# Git
if (Test-CommandExists "git") {
    Write-OK "Git: $(git --version 2>&1)"
} else {
    Write-FAIL "Git: not found"
    $missing.Add("git")
}

# Node.js
if (Test-CommandExists "node") {
    $nodeRaw = (node --version 2>&1).ToString().TrimStart("v")
    $nodeMajor = [int]($nodeRaw.Split(".")[0])
    if ($nodeMajor -eq $NODE_MAJOR_REQUIRED) {
        if ($nodeRaw -eq $NODE_EXACT_REQUIRED) {
            Write-OK "Node.js: v$nodeRaw"
        } else {
            Write-OK "Node.js: v$nodeRaw  (exact recommended: v$NODE_EXACT_REQUIRED)"
        }
    } else {
        Write-FAIL "Node.js: v$nodeRaw found — v$NODE_EXACT_REQUIRED (Node $NODE_MAJOR_REQUIRED) required"
        $missing.Add("nodejs")
    }
} else {
    Write-FAIL "Node.js: not found  →  required: v$NODE_EXACT_REQUIRED"
    $missing.Add("nodejs")
}

# npm
if (Test-CommandExists "npm") {
    $npmVer = (npm --version 2>&1).ToString().Trim()
    Write-OK "npm: v$npmVer  (recommended: v$NPM_EXACT_REQUIRED)"
} else {
    Write-FAIL "npm: not found  (installs with Node.js)"
    $missing.Add("npm")
}

# Java
if (Test-CommandExists "java") {
    $javaOut = (java -version 2>&1) | Select-Object -First 1
    if ($javaOut -match '"(\d+)') {
        $javaMajor = [int]$Matches[1]
        if ($javaMajor -ge $JAVA_MAJOR_REQUIRED) {
            Write-OK "Java: $javaOut"
        } else {
            Write-FAIL "Java: found v$javaMajor — JDK $JAVA_MAJOR_REQUIRED+ required"
            $missing.Add("java")
        }
    } else {
        Write-WARN "Java: found but could not parse version from: $javaOut"
    }
} else {
    Write-FAIL "Java: not found  →  required: JDK $JAVA_MAJOR_REQUIRED"
    $missing.Add("java")
}

# Maven
if (Test-CommandExists "mvn") {
    $mvnVer = (mvn --version 2>&1) | Select-Object -First 1
    Write-OK "Maven: $mvnVer"
} else {
    Write-FAIL "Maven: not found"
    $missing.Add("maven")
}

# Docker
if (Test-CommandExists "docker") {
    Write-OK "Docker CLI: $(docker --version 2>&1)"
    $dockerPing = docker info 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-OK "Docker daemon: running"
    } else {
        Write-FAIL "Docker daemon: not running — start Docker Desktop first"
        $missing.Add("docker-daemon")
    }
} else {
    Write-FAIL "Docker: not found  (needed to run PostgreSQL)"
    $missing.Add("docker")
}

# GitHub Token (for Maven packages from GitHub Package Registry)
Write-INFO ""
Write-INFO "Checking GitHub Package Registry auth (needed for Maven build)..."
Write-INFO "  Maven settings.xml uses: USERNAME=`$env:USERNAME  PASSWORD=`$env:PASSWORD"
$ghUser  = $env:USERNAME
$ghToken = $env:PASSWORD
if ([string]::IsNullOrWhiteSpace($ghToken)) {
    Write-FAIL "GitHub token (PASSWORD env var): not set"
    Write-INFO "  Required to download Sirius Web / sirius-emf-json from GitHub Packages."
    $missing.Add("github-token")
} else {
    Write-OK "GitHub token (PASSWORD env var): set  (GitHub user will be: $ghUser)"
}

Write-SectionEnd

# Restore ErrorActionPreference to Stop for execution phases
$ErrorActionPreference = $oldEAP

if ($CheckOnly) {
    if ($missing.Count -eq 0) {
        Write-Host "`n  All dependencies satisfied. You're ready to run!`n" -ForegroundColor Green
    } else {
        Write-Host "`n  Missing: $($missing -join ', ')`n" -ForegroundColor Yellow
    }
    exit 0
}

# ═══════════════════════════════════════════════════════════
# PHASE 2 — INSTALL MISSING DEPENDENCIES
# ═══════════════════════════════════════════════════════════
if ($missing.Count -gt 0) {
    Write-Section "Phase 2 of 5 — Installing Missing Dependencies"
    Write-WARN "Missing: $($missing -join '  |  ')"
    Write-INFO ""

    $needsRestart = $false

    foreach ($dep in $missing) {
        switch ($dep) {

            "git" {
                Write-INFO "──────────────────────────────"
                Write-INFO "Git — version control"
                Write-INFO "  winget install --id Git.Git --exact"
                if (Prompt-YesNo "Install Git via winget?") {
                    Invoke-WinGet "Git.Git"
                }
            }

            "nodejs" {
                Write-INFO "──────────────────────────────"
                Write-INFO "Node.js $NODE_EXACT_REQUIRED — JS runtime + npm"
                if (Get-Command fnm -ErrorAction SilentlyContinue) {
                    Write-INFO "  fnm (Fast Node Manager) detected — will install via fnm"
                    if (Prompt-YesNo "Install Node.js $NODE_EXACT_REQUIRED via fnm?") {
                        fnm install $NODE_EXACT_REQUIRED
                        try { fnm env --shell powershell | Out-String | Invoke-Expression } catch { }
                        fnm use $NODE_EXACT_REQUIRED
                        Write-OK "Node.js $NODE_EXACT_REQUIRED activated via fnm."
                    }
                } else {
                    Write-INFO "  Installing fnm (Fast Node Manager) then Node $NODE_EXACT_REQUIRED..."
                    if (Prompt-YesNo "Install fnm + Node.js $NODE_EXACT_REQUIRED?") {
                        Invoke-WinGet "Schniz.fnm"
                        Refresh-Path
                        if (Get-Command fnm -ErrorAction SilentlyContinue) {
                            fnm install $NODE_EXACT_REQUIRED
                            try { fnm env --shell powershell | Out-String | Invoke-Expression } catch { }
                            fnm use $NODE_EXACT_REQUIRED
                            Write-OK "Node.js $NODE_EXACT_REQUIRED activated via fnm."
                        } else {
                            Write-INFO "  Falling back to direct winget install..."
                            Invoke-WinGet "OpenJS.NodeJS" $NODE_EXACT_REQUIRED
                            $needsRestart = $true
                        }
                    }
                }
            }

            "java" {
                Write-INFO "──────────────────────────────"
                Write-INFO "Eclipse Temurin JDK $JAVA_MAJOR_REQUIRED — Java runtime for Spring Boot"
                Write-INFO "  winget install --id EclipseAdoptium.Temurin.$JAVA_MAJOR_REQUIRED.JDK"
                Write-INFO "  Alternatively: https://adoptium.net/"
                if (Prompt-YesNo "Install Temurin JDK $JAVA_MAJOR_REQUIRED via winget?") {
                    Invoke-WinGet "EclipseAdoptium.Temurin.$JAVA_MAJOR_REQUIRED.JDK"
                    $needsRestart = $true
                }
            }

            "maven" {
                Write-INFO "──────────────────────────────"
                Write-INFO "Apache Maven 3.9.x — Java build tool"
                Write-INFO "  Will download from Apache CDN and install to C:\tools\apache-maven-3.9.16"
                if (Prompt-YesNo "Install Maven 3.9.16 from Apache CDN?") {
                    $mvnVer = "3.9.16"
                    $mvnUrl = "https://dlcdn.apache.org/maven/maven-3/$mvnVer/binaries/apache-maven-$mvnVer-bin.zip"
                    $mvnZip = "$env:TEMP\apache-maven-$mvnVer-bin.zip"
                    $mvnInstallDir = "C:\tools"
                    Write-INFO "Downloading Maven $mvnVer..."
                    Invoke-WebRequest -Uri $mvnUrl -OutFile $mvnZip -UseBasicParsing
                    New-Item -ItemType Directory -Path $mvnInstallDir -Force | Out-Null
                    Expand-Archive -Path $mvnZip -DestinationPath $mvnInstallDir -Force
                    $mvnBin = "$mvnInstallDir\apache-maven-$mvnVer\bin"
                    $curUserPath = [Environment]::GetEnvironmentVariable("Path", "User")
                    if ($curUserPath -notlike "*apache-maven*") {
                        [Environment]::SetEnvironmentVariable("Path", "$curUserPath;$mvnBin", "User")
                    }
                    $env:Path += ";$mvnBin"
                    Write-OK "Maven $mvnVer installed at $mvnInstallDir\apache-maven-$mvnVer"
                }
            }

            "docker" {
                Write-INFO "──────────────────────────────"
                Write-INFO "Docker Desktop — required to run the PostgreSQL database container"
                Write-INFO "  winget install --id Docker.DockerDesktop"
                Write-WARN "After Docker Desktop installs, you must RESTART your computer,"
                Write-WARN "then open Docker Desktop and let it fully start before re-running this script."
                if (Prompt-YesNo "Install Docker Desktop via winget?") {
                    Invoke-WinGet "Docker.DockerDesktop"
                    Write-WARN "Docker Desktop installed. Please RESTART your computer, then re-run this script."
                    Write-Host "`n  Exiting — please restart and run again.`n" -ForegroundColor Yellow
                    exit 0
                }
            }

            "docker-daemon" {
                Write-INFO "──────────────────────────────"
                Write-INFO "Docker Desktop is installed but not running."
                if (Prompt-YesNo "Would you like to start Docker Desktop automatically?") {
                    $dockerPath = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
                    if (Test-Path $dockerPath) {
                        Write-INFO "Starting Docker Desktop..."
                        Start-Process $dockerPath
                        Write-INFO "Waiting for Docker daemon to become ready (up to 60s)..."
                        $elapsed = 0
                        $started = $false
                        while ($elapsed -lt 60) {
                            docker info >$null 2>&1
                            if ($LASTEXITCODE -eq 0) {
                                $started = $true
                                break
                            }
                            Start-Sleep -Seconds 2
                            $elapsed += 2
                            Write-Host "." -NoNewline -ForegroundColor Gray
                        }
                        Write-Host ""
                        if ($started) {
                            Write-OK "Docker daemon is running!"
                        } else {
                            Write-WARN "Docker Desktop started but daemon is not responding yet."
                            Read-Host "  │  Please check Docker Desktop and press Enter when it is fully ready"
                        }
                    } else {
                        Write-WARN "Docker Desktop executable not found at typical path: $dockerPath"
                        Write-INFO "  Please open Docker Desktop manually."
                        Read-Host "  │  Press Enter once Docker Desktop is fully started"
                    }
                } else {
                    Write-INFO "  Please open Docker Desktop from the Start Menu."
                    Write-INFO "  Wait for the whale icon in the system tray to stop animating."
                    Write-Host ""
                    Read-Host "  │  Press Enter once Docker Desktop is fully started"
                }
            }

            "github-token" {
                Write-INFO "──────────────────────────────"
                Write-INFO "GitHub Personal Access Token — needed for Maven to download Sirius Web packages"
                Write-INFO ""
                Write-INFO "  Steps to create one:"
                Write-INFO "  1. Go to: https://github.com/settings/tokens  (or Settings > Developer settings > PAT)"
                Write-INFO "  2. Click 'Generate new token (classic)'"
                Write-INFO "  3. Give it a name (e.g. 'syson-dev') and check the 'read:packages' scope"
                Write-INFO "  4. Copy the generated token  (you only see it once!)"
                Write-INFO ""
                Write-INFO "  The username '$ghUser' will be used as the GitHub username."
                Write-INFO "  If your GitHub username differs, set GITHUB_USERNAME (e.g. `$env:GITHUB_USERNAME = 'user')."
                Write-INFO ""
                $secureToken = Read-Host "  │  Paste your GitHub PAT here (input is hidden)" -AsSecureString
                $plainToken = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
                    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureToken)
                )
                $env:PASSWORD = $plainToken
                Write-OK "Token stored for this session."
                Write-INFO ""
                Write-INFO "  To avoid entering it next time, add this to your PowerShell profile"
                Write-INFO "  (run: notepad `$PROFILE) :"
                Write-INFO "      `$env:PASSWORD = 'your-token-here'"
                Write-INFO ""
                Write-INFO "  Or set it as a permanent system env var (safe approach):"
                Write-INFO "      [Environment]::SetEnvironmentVariable('PASSWORD','your-token','User')"
            }
        }
    }

    # Refresh PATH after installations
    Refresh-Path
    Write-INFO ""
    Write-INFO "Refreshed PATH from system/user environment."

    # Re-verify
    Write-SectionEnd
    Write-Section "Re-checking after installations"

    $stillMissing = [System.Collections.Generic.List[string]]::new()
    if ("nodejs" -in $missing -and -not (Test-CommandExists "node"))  { $stillMissing.Add("nodejs") }
    if ("npm"    -in $missing -and -not (Test-CommandExists "npm"))    { $stillMissing.Add("npm") }
    if ("java"   -in $missing -and -not (Test-CommandExists "java"))   { $stillMissing.Add("java") }
    if ("maven"  -in $missing -and -not (Test-CommandExists "mvn"))    { $stillMissing.Add("maven") }
    if ("docker" -in $missing -and -not (Test-CommandExists "docker")) { $stillMissing.Add("docker") }

    if ($stillMissing.Count -gt 0) {
        Write-FAIL "Still not found after install: $($stillMissing -join ', ')"
        Write-WARN "This usually means you need to open a NEW terminal window for PATH to update."
        Write-WARN "Close this window, open a new PowerShell, and run the script again."
        Write-SectionEnd
        exit 1
    }

    if ($needsRestart) {
        Write-WARN "Some tools were just installed. If you see errors below, open a"
        Write-WARN "new terminal and re-run the script — PATH needs to refresh."
    }

    Write-OK "All dependencies are now present."
    Write-SectionEnd
} else {
    Write-Section "Phase 2 of 5 — Dependencies"
    Write-OK "All dependencies already installed — skipping install phase."
    Write-SectionEnd
}

# ═══════════════════════════════════════════════════════════
# PHASE 3 — START DATABASE
# ═══════════════════════════════════════════════════════════
if (-not $FrontendOnly) {
    Write-Section "Phase 3 of 5 — Starting PostgreSQL Database"

    Write-INFO "Using compose file: $COMPOSE_FILE"
    Write-INFO "Starting 'database' service (postgres:15, port $DB_PORT)..."

    $oldEAP = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    docker compose -f $COMPOSE_FILE up -d database 2>&1
    $ErrorActionPreference = $oldEAP
    if ($LASTEXITCODE -ne 0) {
        Write-FAIL "docker compose failed. Is Docker Desktop running?"
        Write-SectionEnd
        exit 1
    }

    $dbReady = Wait-ForPort $DB_PORT 45 "PostgreSQL"
    if (-not $dbReady) {
        Write-WARN "PostgreSQL may not be fully ready yet; proceeding anyway."
    }

    $env:SPRING_DATASOURCE_URL      = "jdbc:postgresql://localhost:$DB_PORT/$DB_NAME"
    $env:SPRING_DATASOURCE_USERNAME = $DB_USER
    $env:SPRING_DATASOURCE_PASSWORD = $DB_PASSWORD

    Write-OK "SPRING_DATASOURCE_URL      = $env:SPRING_DATASOURCE_URL"
    Write-OK "SPRING_DATASOURCE_USERNAME = $DB_USER"
    Write-SectionEnd
}

# ═══════════════════════════════════════════════════════════
# PHASE 4 — BUILD
# ═══════════════════════════════════════════════════════════
$AutoSkipped = $false
if (-not $SkipBuild -and -not $ForceBuild) {
    $hasBackendBuild = -not $FrontendOnly -and (Test-Path $BACKEND_JAR)
    $hasFrontendBuild = -not $BackendOnly -and (Test-Path (Join-Path $ROOT_DIR "node_modules"))

    $canSkipBackend = $FrontendOnly -or $hasBackendBuild
    $canSkipFrontend = $BackendOnly -or $hasFrontendBuild

    if ($canSkipBackend -and $canSkipFrontend) {
        $SkipBuild = $true
        $AutoSkipped = $true
    }
}

if (-not $SkipBuild) {
    Write-Section "Phase 4 of 5 — Building"

    # Frontend deps
    if (-not $BackendOnly) {
        Write-INFO "Installing npm packages (root workspace)..."
        # Ensure fnm Node is active so npm doesn't use the system (nvm4w) node
        if (Get-Command fnm -ErrorAction SilentlyContinue) {
            try { fnm env --shell powershell | Out-String | Invoke-Expression } catch { }
            try { fnm use $NODE_EXACT_REQUIRED 2>$null } catch { }
        }
        Set-Location $ROOT_DIR
        # Use cmd /c npm to avoid .ps1 path resolution issues
        cmd /c "npm install"
        if ($LASTEXITCODE -ne 0) {
            Write-FAIL "npm install failed."
            Write-SectionEnd
            exit 1
        }
        Write-OK "npm packages installed."
    }

    # Backend build
    if (-not $FrontendOnly) {
        Write-INFO ""
        Write-INFO "Building Maven backend..."
        Write-INFO "(First run: downloads ~500 MB of dependencies — takes 5-15 min)"
        Write-INFO "Command: mvn -B clean install -DskipTests -s settings.xml"
        Write-INFO ""

        Set-Location $ROOT_DIR
        mvn -B clean install -DskipTests -s $SETTINGS_XML
        if ($LASTEXITCODE -ne 0) {
            Write-FAIL "Maven build failed. Check output above for the first ERROR line."
            Write-INFO "Common causes:"
            Write-INFO "  - GitHub token (PASSWORD) incorrect or expired"
            Write-INFO "  - Network issues downloading packages"
            Write-INFO "  - Wrong Java version (need JDK $JAVA_MAJOR_REQUIRED)"
            Write-SectionEnd
            exit 1
        }
        Write-OK "Backend built successfully: $BACKEND_JAR"
    }

    Write-SectionEnd
} else {
    Write-Section "Phase 4 of 5 — Build"
    if ($AutoSkipped) {
        Write-OK "Existing build artifacts found (backend JAR and/or node_modules)."
        Write-INFO "Skipping build phase to start up faster. Use -ForceBuild to compile again."
    } else {
        Write-WARN "-SkipBuild: skipping npm install and Maven build."
    }

    if (-not $FrontendOnly -and -not (Test-Path $BACKEND_JAR)) {
        Write-FAIL "Backend JAR not found at:"
        Write-FAIL "  $BACKEND_JAR"
        Write-INFO "Run without -SkipBuild at least once to compile the backend."
        Write-SectionEnd
        exit 1
    }
    Write-OK "Using existing artifacts."
    Write-SectionEnd
}

# ═══════════════════════════════════════════════════════════
# PHASE 5 — RUN SERVICES
# ═══════════════════════════════════════════════════════════
Write-Section "Phase 5 of 5 — Starting Services"

if (-not $FrontendOnly) {
    Write-INFO "Launching backend in a new terminal window..."

    # Write backend start commands to a temp script to avoid $env: escaping issues
    # when passing multi-line commands through Start-Process argument lists.
    $backendScript = Join-Path $env:TEMP "sysonpp-backend-start.ps1"
    @"
`$env:SPRING_DATASOURCE_URL      = 'jdbc:postgresql://localhost:$DB_PORT/$DB_NAME'
`$env:SPRING_DATASOURCE_USERNAME = '$DB_USER'
`$env:SPRING_DATASOURCE_PASSWORD = '$DB_PASSWORD'
Write-Host 'Starting SysON++ Backend on port $BACKEND_PORT...' -ForegroundColor Cyan
java -jar '$BACKEND_JAR'
Write-Host 'Backend stopped.' -ForegroundColor Yellow
Read-Host 'Press Enter to close'
"@ | Set-Content -Path $backendScript -Encoding UTF8

    $wt = Get-Command "wt.exe" -ErrorAction SilentlyContinue
    if ($wt) {
        Start-Process "wt.exe" -ArgumentList "new-tab", "--title", "SysON++ Backend", "pwsh", "-NoExit", "-File", $backendScript
    } else {
        Start-Process "pwsh" -ArgumentList "-NoExit", "-File", $backendScript
    }
    Write-OK "Backend window launched."

    Write-INFO "Waiting for backend to start (port $BACKEND_PORT, up to 180s)..."
    $null = Wait-ForPort $BACKEND_PORT 180 "Spring Boot backend"
}

if (-not $BackendOnly) {
    Write-INFO "Launching frontend in a new terminal window..."

    # Use the native turbo.exe to avoid npx/.ps1 issues on Windows.
    # fnm use only affects the current shell; the new tab needs explicit activation.
    $fnmExe = (Get-Command fnm -ErrorAction SilentlyContinue).Source
    $turboExe = Join-Path $ROOT_DIR "node_modules\@turbo\windows-64\bin\turbo.exe"
    if (-not (Test-Path $turboExe)) {
        $altTurbo = Join-Path $ROOT_DIR "node_modules\turbo-windows-64\bin\turbo.exe"
        if (Test-Path $altTurbo) {
            $turboExe = $altTurbo
        }
    }

    if ($fnmExe -and (Test-Path $turboExe)) {
        $frontendPs = "& '$fnmExe' env --shell powershell | Out-String | Invoke-Expression; & '$fnmExe' use $NODE_EXACT_REQUIRED 2>`$null; Write-Host 'Starting SysON++ Frontend (port $FRONTEND_PORT, Node ' + (node --version) + ')...' -ForegroundColor Cyan; Set-Location '$ROOT_DIR'; & '$turboExe' run start; Write-Host 'Frontend stopped.' -ForegroundColor Yellow; Read-Host 'Press Enter to close'"
    } else {
        # Fallback: use cmd /c so .cmd wrappers work
        $frontendPs = "Set-Location '$ROOT_DIR'; Write-Host 'Starting SysON++ Frontend on port $FRONTEND_PORT...' -ForegroundColor Cyan; cmd /c 'node_modules\.bin\turbo.cmd run start'; Read-Host 'Frontend stopped. Press Enter to close'"
    }

    $wt = Get-Command "wt.exe" -ErrorAction SilentlyContinue
    if ($wt) {
        Start-Process "wt.exe" -ArgumentList "new-tab", "--title", "SysON++ Frontend", "pwsh", "-NoExit", "-Command", $frontendPs
    } else {
        Start-Process "pwsh" -ArgumentList "-NoExit", "-Command", $frontendPs
    }
    Write-OK "Frontend window launched."
}

Write-SectionEnd

# ── Final summary ──────────────────────────────────────────
Write-Host ""
Write-Host "  ╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "  ║  SysON++ is starting up!                                     ║" -ForegroundColor Green
Write-Host "  ║                                                              ║" -ForegroundColor Green
Write-Host "  ║  Frontend app  ->  http://localhost:$FRONTEND_PORT                   ║" -ForegroundColor Green
Write-Host "  ║  Backend API   ->  http://localhost:$BACKEND_PORT                    ║" -ForegroundColor Green
Write-Host "  ║  GraphQL       ->  http://localhost:$BACKEND_PORT/api/graphql        ║" -ForegroundColor Green
Write-Host "  ║  PostgreSQL    ->  localhost:$DB_PORT  (db: $DB_NAME)           ║" -ForegroundColor Green
Write-Host "  ║                                                              ║" -ForegroundColor Green
Write-Host "  ║  Watch the new terminal windows for startup progress.        ║" -ForegroundColor Green
Write-Host "  ╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "  To stop everything:  .\scripts-spp\setup-dev.ps1 -StopAll" -ForegroundColor Yellow
Write-Host "  Fast restart:        .\scripts-spp\setup-dev.ps1 -SkipBuild" -ForegroundColor Yellow
Write-Host "  Force rebuild:       .\scripts-spp\setup-dev.ps1 -ForceBuild" -ForegroundColor Yellow
Write-Host "  Check deps only:     .\scripts-spp\setup-dev.ps1 -CheckOnly" -ForegroundColor Yellow
Write-Host ""
