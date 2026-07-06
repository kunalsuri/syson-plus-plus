# Copyright (c) 2026 CEA LIST / Kunal Suri. All rights reserved.
#!/usr/bin/env pwsh
#Requires -Version 5.1
<#
.SYNOPSIS
    Stop SysON++ services only — does NOT touch unrelated Java or Node processes.

.DESCRIPTION
    Targeted shutdown:
      [1] Java backend  — identified by "syson-application" in its command line (port 8080)
      [2] React frontend — identified by ownership of port 5173
      [3] PostgreSQL     — docker compose stop (container preserved, not removed)

.EXAMPLE
    .\stop-dev.ps1
#>

$SCRIPT_DIR   = Split-Path -Parent $MyInvocation.MyCommand.Path
$ROOT_DIR     = Split-Path -Parent $SCRIPT_DIR
$COMPOSE_FILE = Join-Path $ROOT_DIR "backend\application\syson-application\docker-compose.yml"

function Write-OK($msg)   { Write-Host "  [✓] $msg" -ForegroundColor Green }
function Write-WARN($msg) { Write-Host "  [!] $msg" -ForegroundColor Yellow }
function Write-INFO($msg) { Write-Host "  [·] $msg" -ForegroundColor Gray }
function Write-FAIL($msg) { Write-Host "  [✗] $msg" -ForegroundColor Red }

Write-Host ""
Write-Host "  ╔══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "  ║   SysON++ — Stopping all services        ║" -ForegroundColor Cyan
Write-Host "  ╚══════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# ── 1. Backend — only kill the SysON java process ─────────
# Matches on command line so IntelliJ / Eclipse / other JVMs are NOT touched.
Write-INFO "Stopping SysON++ Java backend (port 8080)..."

$sysonJava = Get-CimInstance Win32_Process -Filter "Name='java.exe'" |
    Where-Object { $_.CommandLine -like '*syson-application*' }

if ($sysonJava) {
    foreach ($p in $sysonJava) {
        Stop-Process -Id $p.ProcessId -Force -ErrorAction SilentlyContinue
        Write-OK "Stopped Java PID $($p.ProcessId)."
    }
} else {
    # Fallback: process on port 8080 if command-line match fails (e.g. process already exiting)
    $port8080 = Get-NetTCPConnection -LocalPort 8080 -State Listen -ErrorAction SilentlyContinue |
        ForEach-Object { Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue } |
        Where-Object { $_.Name -eq 'java' }
    if ($port8080) {
        $port8080 | ForEach-Object {
            Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
            Write-OK "Stopped Java process on port 8080 (PID $($_.Id))."
        }
    } else {
        Write-WARN "No SysON++ Java process found — already stopped."
    }
}

# ── 2. Frontend — only kill the process owning port 5173 ──
# Does NOT blindly kill all node processes (would break VS Code, other servers).
Write-INFO "Stopping SysON++ frontend (port 5173)..."

$port5173 = Get-NetTCPConnection -LocalPort 5173 -State Listen -ErrorAction SilentlyContinue |
    ForEach-Object { Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue } |
    Where-Object { $_ }

if ($port5173) {
    $port5173 | Sort-Object Id -Unique | ForEach-Object {
        Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
        Write-OK "Stopped frontend process '$($_.Name)' (PID $($_.Id))."
    }
} else {
    Write-WARN "No process listening on port 5173 — already stopped."
}

# ── 3. PostgreSQL — stop only, do NOT remove the container ─
# 'docker compose stop' pauses the container; it stays visible in Docker Desktop.
# 'docker compose down' would DELETE it — do not use that here.
Write-INFO "Stopping PostgreSQL container (will stay visible in Docker Desktop)..."

if (-not (Test-Path $COMPOSE_FILE)) {
    Write-FAIL "Compose file not found: $COMPOSE_FILE"
} elseif (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-WARN "Docker not found — skipping."
} else {
    $dockerInfo = docker info 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-WARN "Docker daemon not running — skipping."
    } else {
        docker compose -f $COMPOSE_FILE stop database 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-OK "PostgreSQL container stopped (not removed)."
        } else {
            Write-FAIL "docker compose stop failed — check Docker Desktop."
        }
    }
}

Write-Host ""
Write-Host "  All SysON++ services stopped." -ForegroundColor Green
Write-Host "  To restart: .\scripts-spp\setup-dev.ps1 -SkipBuild" -ForegroundColor Gray
Write-Host ""
