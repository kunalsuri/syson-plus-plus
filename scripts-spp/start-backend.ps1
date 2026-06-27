# Copyright (c) 2026 CEA LIST / Kunal Suri. All rights reserved.
#Requires -Version 5.1
# Starts the SysON++ Spring Boot backend on port 8080 as a background process.
# Output is written to: $env:TEMP\sysonpp-backend.log

$SCRIPT_DIR   = Split-Path -Parent $MyInvocation.MyCommand.Path
$ROOT_DIR     = Split-Path -Parent $SCRIPT_DIR
$BACKEND_PORT = 8080
$LOG_OUT      = "$env:TEMP\sysonpp-backend.log"
$LOG_ERR      = "$env:TEMP\sysonpp-backend-err.log"

function Write-OK($m)   { Write-Host "  [OK] $m" -ForegroundColor Green }
function Write-FAIL($m) { Write-Host "  [FAIL] $m" -ForegroundColor Red }
function Write-INFO($m) { Write-Host "  [..] $m" -ForegroundColor Gray }

Write-Host ""
Write-Host "  Starting Spring Boot backend (port $BACKEND_PORT)..." -ForegroundColor Cyan

# Discover the executable JAR — exclude -sources.jar (no Main-Class manifest)
$JAR = Get-Item "$ROOT_DIR\backend\application\syson-application\target\syson-application-*.jar" `
    -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -notmatch '-sources\.jar$' } |
    Select-Object -First 1

if (-not $JAR) {
    Write-FAIL "Backend JAR not found under backend\application\syson-application\target\"
    Write-FAIL "Build the project first:  .\scripts-spp\setup-dev.ps1"
    exit 1
}
if (-not (Get-Command java -ErrorAction SilentlyContinue)) {
    Write-FAIL "Java not found. Install JDK 21: winget install EclipseAdoptium.Temurin.21.JDK"
    exit 1
}

$env:SPRING_DATASOURCE_URL      = 'jdbc:postgresql://localhost:5432/postgres'
$env:SPRING_DATASOURCE_USERNAME = 'test_username'
$env:SPRING_DATASOURCE_PASSWORD = 'test_password'

Remove-Item $LOG_OUT, $LOG_ERR -ErrorAction SilentlyContinue

$proc = Start-Process -FilePath "java" `
    -ArgumentList @("-jar", $JAR.FullName) `
    -NoNewWindow -PassThru `
    -RedirectStandardOutput $LOG_OUT `
    -RedirectStandardError  $LOG_ERR

if (-not $proc) {
    Write-FAIL "Failed to launch java process."
    exit 1
}

Write-INFO "PID: $($proc.Id) | Log: $LOG_OUT"
Write-INFO "Waiting for port $BACKEND_PORT (up to 120s)..."

$tries = 0; $ready = $false
while ($tries -lt 40 -and -not $proc.HasExited -and -not $ready) {
    try {
        $t = New-Object System.Net.Sockets.TcpClient
        $t.Connect("127.0.0.1", $BACKEND_PORT); $t.Close()
        $ready = $true
    } catch {
        Start-Sleep -Seconds 3; $tries++
        Write-Host "." -NoNewline -ForegroundColor DarkGray
    }
}
Write-Host ""

if ($ready) {
    Write-OK "Backend is ready on http://localhost:$BACKEND_PORT"
    exit 0
} elseif ($proc.HasExited) {
    Write-FAIL "Backend process exited early (code $($proc.ExitCode))."
    Write-FAIL "Check log: $LOG_OUT"
    Get-Content $LOG_OUT -ErrorAction SilentlyContinue | Select-Object -Last 10 |
        ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
    exit 1
} else {
    Write-FAIL "Backend did not respond after 120s. Check log: $LOG_OUT"
    exit 1
}
