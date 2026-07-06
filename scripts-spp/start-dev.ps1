# Copyright (c) 2026 CEA LIST / Kunal Suri. All rights reserved.
#Requires -Version 5.1
<#
.SYNOPSIS
    Daily developer orchestrator — starts all SysON++ services in order.

.DESCRIPTION
    Calls start-db.ps1 → start-backend.ps1 → start-frontend.ps1 in sequence,
    waiting for each service to be ready before starting the next.

    First time on a new machine? Run .\scripts-spp\setup-dev.ps1 instead.
    That script installs dependencies and builds the backend.

.EXAMPLE
    .\scripts-spp\start-dev.ps1
#>

$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host ""
Write-Host "  +--------------------------------------------------+" -ForegroundColor Cyan
Write-Host "  |        SysON++ - Starting all services           |" -ForegroundColor Cyan
Write-Host "  |   Database  ->  Backend  ->  Frontend            |" -ForegroundColor Cyan
Write-Host "  +--------------------------------------------------+" -ForegroundColor Cyan

function Stop-WithError($msg) {
    Write-Host ""
    Write-Host "  [FAIL] $msg" -ForegroundColor Red
    Write-Host "  First time? Run: .\scripts-spp\setup-dev.ps1" -ForegroundColor Yellow
    Write-Host "  Already built but failed? Check the log files shown above." -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

# ── Step 1: Database ──────────────────────────────────────
& "$SCRIPT_DIR\start-db.ps1"
if ($LASTEXITCODE -ne 0) { Stop-WithError "Database failed to start. Fix the issue above and try again." }

# ── Step 2: Backend ───────────────────────────────────────
& "$SCRIPT_DIR\start-backend.ps1"
if ($LASTEXITCODE -ne 0) { Stop-WithError "Backend failed to start. Fix the issue above and try again." }

# ── Step 3: Frontend ──────────────────────────────────────
& "$SCRIPT_DIR\start-frontend.ps1"
if ($LASTEXITCODE -ne 0) { Stop-WithError "Frontend failed to start. Fix the issue above and try again." }

# ── All up ────────────────────────────────────────────────
Write-Host ""
Write-Host "  +---------------------------------------------------------+" -ForegroundColor Green
Write-Host "  |   All services are running!                             |" -ForegroundColor Green
Write-Host "  |                                                         |" -ForegroundColor Green
Write-Host "  |   Open in browser  ->  http://localhost:5173            |" -ForegroundColor Green
Write-Host "  |   Backend API      ->  http://localhost:8080            |" -ForegroundColor Green
Write-Host "  |   GraphQL          ->  http://localhost:8080/api/graphql|" -ForegroundColor Green
Write-Host "  |   PostgreSQL       ->  localhost:5432                   |" -ForegroundColor Green
Write-Host "  |                                                         |" -ForegroundColor Green
Write-Host "  |   Backend log   ->  %TEMP%\sysonpp-backend.log          |" -ForegroundColor Green
Write-Host "  |   Frontend log  ->  %TEMP%\sysonpp-frontend.log         |" -ForegroundColor Green
Write-Host "  |                                                         |" -ForegroundColor Green
Write-Host "  |   To stop:  .\scripts-spp\stop-dev.ps1                 |" -ForegroundColor Green
Write-Host "  +---------------------------------------------------------+" -ForegroundColor Green
Write-Host ""
