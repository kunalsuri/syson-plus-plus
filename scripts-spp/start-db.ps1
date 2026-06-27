# Copyright (c) 2026 CEA LIST / Kunal Suri. All rights reserved.
#Requires -Version 5.1
# Starts the SysON++ PostgreSQL database container.
# The container is paused on stop — it is never deleted by stop-dev.ps1.

$SCRIPT_DIR   = Split-Path -Parent $MyInvocation.MyCommand.Path
$ROOT_DIR     = Split-Path -Parent $SCRIPT_DIR
$COMPOSE_FILE = Join-Path $ROOT_DIR "backend\application\syson-application\docker-compose.yml"
$DB_PORT      = 5432

function Write-OK($m)   { Write-Host "  [OK] $m" -ForegroundColor Green }
function Write-FAIL($m) { Write-Host "  [FAIL] $m" -ForegroundColor Red }
function Write-INFO($m) { Write-Host "  [..] $m" -ForegroundColor Gray }

Write-Host ""
Write-Host "  Starting PostgreSQL (port $DB_PORT)..." -ForegroundColor Cyan

if (-not (Test-Path $COMPOSE_FILE)) {
    Write-FAIL "Compose file not found: $COMPOSE_FILE"
    exit 1
}
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-FAIL "Docker not found. Install Docker Desktop and restart."
    exit 1
}
docker info 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-FAIL "Docker daemon is not running. Open Docker Desktop and wait for it to be ready."
    exit 1
}

docker compose -f $COMPOSE_FILE up -d database 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-FAIL "docker compose up failed. Check Docker Desktop for errors."
    exit 1
}

Write-INFO "Waiting for PostgreSQL on port $DB_PORT (up to 40s)..."
$tries = 0; $ready = $false
while ($tries -lt 20 -and -not $ready) {
    try {
        $t = New-Object System.Net.Sockets.TcpClient
        $t.Connect("127.0.0.1", $DB_PORT); $t.Close()
        $ready = $true
    } catch {
        Start-Sleep -Seconds 2; $tries++
        Write-Host "." -NoNewline -ForegroundColor DarkGray
    }
}
Write-Host ""

if ($ready) {
    Write-OK "PostgreSQL is ready on port $DB_PORT."
    exit 0
} else {
    Write-FAIL "PostgreSQL did not respond after 40s. Check Docker Desktop."
    exit 1
}
