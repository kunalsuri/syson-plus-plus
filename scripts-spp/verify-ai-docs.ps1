# Copyright (c) 2026 CEA LIST / Kunal Suri. All rights reserved.
# Licensed under the Eclipse Public License v2.0 (EPL-2.0)
#Requires -Version 5.1
<#
.SYNOPSIS
    Full ai/ knowledge-layer audit — runs backend and frontend verification in sequence.

.DESCRIPTION
    Convenience wrapper that calls:
      1. verify-ai-docs-backend.ps1   — Java / GraphQL / Grammar claims
      2. verify-ai-docs-frontend.ps1  — TypeScript / TSX claims

    Reports are written to ai/analysis/audit-reports/:
      BACKEND_VERIFICATION_REPORT.md
      FRONTEND_VERIFICATION_REPORT.md

    To run only one side, use the targeted scripts directly:
      .\scripts-spp\verify-ai-docs-backend.ps1
      .\scripts-spp\verify-ai-docs-frontend.ps1

.PARAMETER GenerateOnly
    Passed through to both subscripts — update manifests only, skip verification.

.PARAMETER VerifyOnly
    Passed through to both subscripts — verify existing manifests, skip re-parsing.

.PARAMETER RepoRoot
    Repository root. Defaults to the parent of the scripts-spp/ directory.

.EXAMPLE
    .\scripts-spp\verify-ai-docs.ps1            # full audit (both backend + frontend)
    .\scripts-spp\verify-ai-docs-backend.ps1    # backend devs: Java / GraphQL
    .\scripts-spp\verify-ai-docs-frontend.ps1   # frontend devs: TypeScript / TSX
#>
[CmdletBinding()]
param(
    [switch]$GenerateOnly,
    [switch]$VerifyOnly,
    [string]$RepoRoot = (Split-Path $PSScriptRoot -Parent)
)

$ErrorActionPreference = "Stop"

$backendScript  = Join-Path $PSScriptRoot "verify-ai-docs-backend.ps1"
$frontendScript = Join-Path $PSScriptRoot "verify-ai-docs-frontend.ps1"

Write-Host ""
Write-Host "╔══════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║     Full ai/docs Audit — SysON++            ║" -ForegroundColor Magenta
Write-Host "╚══════════════════════════════════════════════╝" -ForegroundColor Magenta
Write-Host ""

# ── 1. Backend ────────────────────────────────────────────────────────────────

$params = @{ RepoRoot = $RepoRoot }
if ($GenerateOnly.IsPresent) { $params["GenerateOnly"] = $true }
if ($VerifyOnly.IsPresent)   { $params["VerifyOnly"]   = $true }

& $backendScript @params

# ── 2. Frontend ───────────────────────────────────────────────────────────────

& $frontendScript @params

# ── Summary ───────────────────────────────────────────────────────────────────

$reportsDir = Join-Path (Join-Path $RepoRoot "ai\analysis") "audit-reports"
Write-Host ""
Write-Host "╔══════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║              FULL AUDIT DONE                ║" -ForegroundColor Magenta
Write-Host "╚══════════════════════════════════════════════╝" -ForegroundColor Magenta
Write-Host ""
Write-Host "  Reports written to: $reportsDir" -ForegroundColor Cyan
Write-Host "    BACKEND_VERIFICATION_REPORT.md"
Write-Host "    FRONTEND_VERIFICATION_REPORT.md"
Write-Host ""
Write-Host "  To re-run one side only:"
Write-Host "    .\scripts-spp\verify-ai-docs-backend.ps1    (Java / GraphQL / Grammar)"
Write-Host "    .\scripts-spp\verify-ai-docs-frontend.ps1   (TypeScript / TSX)"
Write-Host ""
