# Copyright (c) 2026 CEA LIST / Kunal Suri. All rights reserved.
#Requires -Version 5.1
# Starts the SysON++ React/Vite frontend on port 5173 as a background process.
# Uses fnm Node v22 to avoid the nvm4w EPERM issue on Windows.
# Output is written to: $env:TEMP\sysonpp-frontend.log

$SCRIPT_DIR    = Split-Path -Parent $MyInvocation.MyCommand.Path
$ROOT_DIR      = Split-Path -Parent $SCRIPT_DIR
$FRONTEND_PORT = 5173
$NODE_VERSION  = "22.16.0"   # Update here if the project upgrades Node
$TURBO_EXE     = Join-Path $ROOT_DIR "node_modules\@turbo\windows-64\bin\turbo.exe"
if (-not (Test-Path $TURBO_EXE)) {
    $ALT_TURBO = Join-Path $ROOT_DIR "node_modules\turbo-windows-64\bin\turbo.exe"
    if (Test-Path $ALT_TURBO) {
        $TURBO_EXE = $ALT_TURBO
    }
}
$LOG_OUT       = "$env:TEMP\sysonpp-frontend.log"
$LOG_ERR       = "$env:TEMP\sysonpp-frontend-err.log"

function Write-OK($m)   { Write-Host "  [OK] $m" -ForegroundColor Green }
function Write-FAIL($m) { Write-Host "  [FAIL] $m" -ForegroundColor Red }
function Write-INFO($m) { Write-Host "  [..] $m" -ForegroundColor Gray }

Write-Host ""
Write-Host "  Starting React/Vite frontend (port $FRONTEND_PORT)..." -ForegroundColor Cyan

if (-not (Test-Path $TURBO_EXE)) {
    Write-FAIL "turbo.exe not found at: $TURBO_EXE"
    Write-FAIL "Install npm packages first:  .\scripts-spp\setup-dev.ps1"
    exit 1
}

# Activate fnm Node v22 - required because nvm4w's npm crashes on this machine (EPERM on admin-local AppData)
if (Get-Command fnm -ErrorAction SilentlyContinue) {
    try { fnm env --shell powershell | Out-String | Invoke-Expression } catch { }
    try { fnm use $NODE_VERSION 2>$null } catch { }
    Write-INFO "Node: $(node --version 2>$null)"
} else {
    Write-INFO "fnm not found - using system Node. If npm crashes, install fnm: winget install Schniz.fnm"
}

Remove-Item $LOG_OUT, $LOG_ERR -ErrorAction SilentlyContinue

$proc = Start-Process -FilePath $TURBO_EXE `
    -ArgumentList @("run", "start") `
    -WorkingDirectory $ROOT_DIR `
    -NoNewWindow -PassThru `
    -RedirectStandardOutput $LOG_OUT `
    -RedirectStandardError  $LOG_ERR

if (-not $proc) {
    Write-FAIL "Failed to launch turbo process."
    exit 1
}

Write-INFO "PID: $($proc.Id) | Log: $LOG_OUT"
Write-INFO "Waiting for port $FRONTEND_PORT (up to 60s)..."

$tries = 0; $ready = $false
while ($tries -lt 20 -and -not $proc.HasExited -and -not $ready) {
    try {
        $t = New-Object System.Net.Sockets.TcpClient
        $t.Connect("127.0.0.1", $FRONTEND_PORT); $t.Close()
        $ready = $true
    } catch {
        Start-Sleep -Seconds 3; $tries++
        Write-Host "." -NoNewline -ForegroundColor DarkGray
    }
}
Write-Host ""

if ($ready) {
    Write-OK "Frontend is ready -> open http://localhost:$FRONTEND_PORT in your browser."
    exit 0
} elseif ($proc.HasExited) {
    Write-FAIL "Frontend process exited early (code $($proc.ExitCode))."
    Write-FAIL "Check log: $LOG_OUT"
    Get-Content $LOG_OUT -ErrorAction SilentlyContinue | Select-Object -Last 10 |
        ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
    exit 1
} else {
    Write-FAIL "Frontend did not respond after 60s. Check log: $LOG_OUT"
    exit 1
}
