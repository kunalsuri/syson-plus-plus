# Copyright (c) 2026 CEA LIST / Kunal Suri. All rights reserved.
# Licensed under the Eclipse Public License v2.0 (EPL-2.0)
#Requires -Version 5.1
<#
.SYNOPSIS
    Verifies frontend (TypeScript / TSX) claims in the ai/ knowledge-layer catalogs.

.DESCRIPTION
    Reads FEATURE_CATALOG.md and FEATURE_CATALOG_FRONTEND.md (from ai/analysis/).
    Extracts every backtick-quoted .tsx / .ts claim, cross-checks each against the actual
    frontend/ source tree (plus integration-test config files), and produces:
      - ai/analysis/audit-reports/VERIFICATION_MANIFEST_FRONTEND.json  (structured claims)
      - ai/analysis/audit-reports/FRONTEND_VERIFICATION_REPORT.md      (human-readable results)

    Phase 1 — Generate: parse Markdown → write / merge manifest.
    Phase 2 — Verify:   scan frontend/ once, check every claim, write report.
    Both phases run by default.

.PARAMETER GenerateOnly
    Parse Markdown and update the manifest only; skip codebase scan.

.PARAMETER VerifyOnly
    Verify the existing manifest against the codebase; skip Markdown re-parsing.

.PARAMETER RepoRoot
    Repository root. Defaults to the parent of the scripts-spp/ directory.

.EXAMPLE
    .\scripts-spp\verify-ai-docs-frontend.ps1
    .\scripts-spp\verify-ai-docs-frontend.ps1 -GenerateOnly
    .\scripts-spp\verify-ai-docs-frontend.ps1 -VerifyOnly
#>
[CmdletBinding()]
param(
    [switch]$GenerateOnly,
    [switch]$VerifyOnly,
    [string]$RepoRoot = (Split-Path $PSScriptRoot -Parent)
)

$ErrorActionPreference = "Stop"

$analysisDir  = Join-Path $RepoRoot "ai\analysis"
$reportsDir   = Join-Path $analysisDir "audit-reports"
$manifestFile  = Join-Path $reportsDir "VERIFICATION_MANIFEST_FRONTEND.json"
$reportFile    = Join-Path $reportsDir "FRONTEND_VERIFICATION_REPORT.md"

if (-not (Test-Path $reportsDir)) { New-Item -ItemType Directory -Path $reportsDir | Out-Null }

# Catalog files that contain frontend claims — full paths split by folder after 2026-06-08 restructure.
# FEATURE_CATALOG.md (master) has both backend and frontend; we extract only TS/TSX from it.
$CatalogFilePaths = @(
    (Join-Path $analysisDir "FEATURE_CATALOG.md"),
    (Join-Path $analysisDir "FEATURE_CATALOG_FRONTEND.md")
)

# Directories to scan for TypeScript source files
$TsScanDirs = @(
    "frontend",
    "integration-tests-cypress",
    "integration-tests-playwright"
)

# ─── Helpers ──────────────────────────────────────────────────────────────────

function Get-GitCommit {
    try { return (git -C $RepoRoot rev-parse --short HEAD 2>$null).Trim() }
    catch { return "unknown" }
}

function Get-Confidence {
    param([string]$Line)
    if ($Line -match '`\[v\]`|\[verified\]') { return "verified" }
    if ($Line -match '\[inferred\]')          { return "inferred"  }
    return "unknown"
}

# ─── Phase 1: Extract frontend claims from Markdown ───────────────────────────

function Extract-FrontendClaims {
    param([string]$Content, [string]$SourceFile)

    $claims    = [System.Collections.Generic.List[PSCustomObject]]::new()
    $localSeen = [System.Collections.Generic.HashSet[string]]::new()

    foreach ($line in ($Content -split "`n")) {

        # TypeScript / TSX files — bare: `FileName.tsx`  OR path: `path/to/FileName.tsx`
        # The path-prefix group is non-capturing; the filename is always captured in group 1.
        foreach ($m in [regex]::Matches($line, '`(?:[A-Za-z0-9_.-]+/)*([A-Za-z][A-Za-z0-9_.-]+\.tsx?)`')) {
            $fn = $m.Groups[1].Value
            # Skip declaration, test, and story files
            if ($fn -match '\.(d\.ts|spec\.ts|test\.ts|spec\.tsx|test\.tsx|stories\.tsx?)$') { continue }
            $id = "ts_$($fn -replace '[^A-Za-z0-9]', '_')"
            if ($localSeen.Add($id)) {
                $null = $claims.Add([PSCustomObject]@{
                    id         = $id
                    type       = if ($fn -match '\.tsx$') { "tsx" } else { "typescript" }
                    name       = $fn
                    fileName   = $fn
                    sourceFile = $SourceFile
                    confidence = Get-Confidence $line
                    status     = "pending"
                    foundAt    = $null
                    note       = $null
                })
            }
        }
    }

    return $claims
}

# ─── Phase 2: Single-pass codebase indexing ───────────────────────────────────

function Build-FileIndex {
    param([string]$SearchDir, [string[]]$Extensions, [string]$Label)

    Write-Host "    Indexing $Label ..." -ForegroundColor DarkGray
    $index = @{}
    if (-not (Test-Path $SearchDir)) {
        Write-Host "    WARNING: directory not found: $SearchDir" -ForegroundColor DarkYellow
        return $index
    }

    Get-ChildItem -Path $SearchDir -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $Extensions -contains $_.Extension.TrimStart('.') } |
        ForEach-Object {
            $rel = $_.FullName.Replace($RepoRoot, "").TrimStart('\/')
            if (-not $index.ContainsKey($_.Name)) {
                $index[$_.Name] = $rel
            } else {
                $prior = $index[$_.Name]
                if ($prior -is [string]) {
                    $list = [System.Collections.Generic.List[string]]::new()
                    $list.Add($prior); $list.Add($rel); $index[$_.Name] = $list
                } else { $index[$_.Name].Add($rel) }
            }
        }
    return $index
}

# ─── Phase 3: Verify each claim ───────────────────────────────────────────────

function Resolve-Claim {
    param([PSCustomObject]$Claim, [hashtable]$TsIdx)

    # Pattern-documentation entries (Xxx placeholder) document a naming convention,
    # not a real file. Treat as informational, not an error.
    if ($Claim.fileName -match 'Xxx') {
        $Claim.status = "pattern_template"
        $Claim.note   = "Template placeholder — 'Xxx' replaced by actual node type name in real files"
        return $Claim
    }

    if (-not $TsIdx.ContainsKey($Claim.fileName)) {
        $Claim.status = "not_found"
        return $Claim
    }

    $entry = $TsIdx[$Claim.fileName]
    if ($entry -is [string]) {
        $Claim.status  = "confirmed"
        $Claim.foundAt = $entry
    } else {
        $Claim.status  = "confirmed_multiple"
        $Claim.foundAt = ($entry -join " | ")
        $Claim.note    = "Filename is not unique — $($entry.Count) matches found"
    }
    return $Claim
}

# ─── Phase 4: Coverage gap analysis ──────────────────────────────────────────

function Get-FrontendCoverageStats {
    param([hashtable]$TsIdx, [array]$Claims)

    # TSX components (React components) — exclude test and story files
    $allTsx = $TsIdx.Keys | Where-Object {
        $_ -match "\.tsx$" -and $_ -notmatch "\.spec\.|\.test\.|\.stories\."
    } | Sort-Object

    $docTsx = @($Claims | Where-Object { $_.type -eq "tsx" -and $_.status -like "confirmed*" } |
                Select-Object -ExpandProperty fileName)

    # TypeScript hooks/utilities (.ts files — hooks, converters, handlers)
    $allTs = $TsIdx.Keys | Where-Object {
        $_ -match "\.ts$" -and $_ -notmatch "\.d\.ts$|\.spec\.|\.test\.|config\.ts$"
    } | Sort-Object

    $docTs = @($Claims | Where-Object { $_.type -eq "typescript" -and $_.status -like "confirmed*" } |
               Select-Object -ExpandProperty fileName)

    return [PSCustomObject]@{
        tsxTotal      = $allTsx.Count
        tsxDocumented = ($allTsx | Where-Object { $docTsx -contains $_ }).Count
        tsxGaps       = @($allTsx | Where-Object { $docTsx -notcontains $_ })
        tsTotal       = $allTs.Count
        tsDocumented  = ($allTs  | Where-Object { $docTs  -contains $_ }).Count
        tsGaps        = @($allTs  | Where-Object { $docTs  -notcontains $_ })
    }
}

# ─── Phase 5: Write frontend report ───────────────────────────────────────────

function Write-FrontendReport {
    param([array]$Claims, [PSCustomObject]$Cov, [string]$Commit)

    $now       = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
    $confirmed = @($Claims | Where-Object { $_.status -like "confirmed*" })
    $notFound  = @($Claims | Where-Object { $_.status -eq "not_found" })
    $patterns  = @($Claims | Where-Object { $_.status -eq "pattern_template" })
    $total     = $Claims.Count

    $Pct = { param($n, $d) if ($d -gt 0) { "$([math]::Round($n / $d * 100))%" } else { "n/a" } }
    $txPct = if ($Cov.tsxTotal -gt 0) { [math]::Round($Cov.tsxDocumented / $Cov.tsxTotal * 100) } else { 0 }
    $tsPct = if ($Cov.tsTotal  -gt 0) { [math]::Round($Cov.tsDocumented  / $Cov.tsTotal  * 100) } else { 0 }

    $sb = [System.Text.StringBuilder]::new()
    $null = $sb.AppendLine("<!-- Copyright (c) 2026 CEA LIST / Kunal Suri. All rights reserved. -->")
    $null = $sb.AppendLine("# Frontend Verification Report — SysON++")
    $null = $sb.AppendLine("")
    $null = $sb.AppendLine("> **Generated:** $now")
    $null = $sb.AppendLine("> **Repo commit:** ``$Commit``")
    $null = $sb.AppendLine("> **Manifest:** ``ai/analysis/audit-reports/VERIFICATION_MANIFEST_FRONTEND.json``")
    $null = $sb.AppendLine("> **Scope:** TypeScript components (.tsx) · Hooks & utilities (.ts)")
    $null = $sb.AppendLine("> **Scanned directories:** ``frontend/`` · ``integration-tests-cypress/`` · ``integration-tests-playwright/``")
    $null = $sb.AppendLine("> **Total claims checked:** $total")
    $null = $sb.AppendLine("")
    $null = $sb.AppendLine("---")
    $null = $sb.AppendLine("")
    $null = $sb.AppendLine("## Summary")
    $null = $sb.AppendLine("")
    $null = $sb.AppendLine("| Status | Count | % of claims |")
    $null = $sb.AppendLine("|---|---|---|")
    $null = $sb.AppendLine("| ✅ Confirmed (file found in frontend/) | $($confirmed.Count) | $(&$Pct $confirmed.Count $total) |")
    $null = $sb.AppendLine("| ❌ Not found — fix or remove from catalog | $($notFound.Count) | $(&$Pct $notFound.Count $total) |")
    $null = $sb.AppendLine("| 📐 Pattern template (intentional Xxx placeholder) | $($patterns.Count) | $(&$Pct $patterns.Count $total) |")
    $null = $sb.AppendLine("")
    $null = $sb.AppendLine("### Frontend catalog coverage")
    $null = $sb.AppendLine("")
    $null = $sb.AppendLine("> What percentage of actual ``frontend/`` source files are documented in the ai/ knowledge layer?")
    $null = $sb.AppendLine("> Test, story, and declaration files are excluded from the counts.")
    $null = $sb.AppendLine("")
    $null = $sb.AppendLine("| Type | In codebase | In catalog | Coverage |")
    $null = $sb.AppendLine("|---|---|---|---|")
    $null = $sb.AppendLine("| React components (.tsx) | $($Cov.tsxTotal) | $($Cov.tsxDocumented) | $txPct% |")
    $null = $sb.AppendLine("| Hooks & utilities (.ts) | $($Cov.tsTotal) | $($Cov.tsDocumented) | $tsPct% |")
    $null = $sb.AppendLine("")
    $null = $sb.AppendLine("---")

    # Not-found
    if ($notFound.Count -gt 0) {
        $null = $sb.AppendLine("")
        $null = $sb.AppendLine("## ❌ Not Found — Fix These ($($notFound.Count))")
        $null = $sb.AppendLine("")
        $null = $sb.AppendLine("> These names appear in the ai/ catalogs but **no matching file exists** in ``frontend/``.")
        $null = $sb.AppendLine("> They are likely hallucinated, renamed, or deleted. Open the source catalog and fix or delete each row.")
        $null = $sb.AppendLine("")
        $null = $sb.AppendLine("| Claimed File | Type | Confidence | Source Catalog |")
        $null = $sb.AppendLine("|---|---|---|---|")
        foreach ($c in ($notFound | Sort-Object sourceFile, fileName)) {
            $null = $sb.AppendLine("| ``$($c.fileName)`` | $($c.type) | $($c.confidence) | [$($c.sourceFile)](../$(($c.sourceFile))) |")
        }
        $null = $sb.AppendLine("")
        $null = $sb.AppendLine("---")
    }

    # Pattern templates
    if ($patterns.Count -gt 0) {
        $null = $sb.AppendLine("")
        $null = $sb.AppendLine("## 📐 Pattern Templates ($($patterns.Count) entries)")
        $null = $sb.AppendLine("")
        $null = $sb.AppendLine("> These use ``Xxx`` as a placeholder documenting the Node Component Triad Pattern.")
        $null = $sb.AppendLine("> Replace ``Xxx`` with a node type name (``Package``, ``Note``, ``ViewFrame``, ``ImportedPackage``) to get actual files.")
        $null = $sb.AppendLine("> All actual node-type files are confirmed ✅ in the list above.")
        $null = $sb.AppendLine("")
        $null = $sb.AppendLine("| Template | Source |")
        $null = $sb.AppendLine("|---|---|")
        foreach ($c in ($patterns | Sort-Object fileName)) {
            $null = $sb.AppendLine("| ``$($c.fileName)`` | $($c.sourceFile) |")
        }
        $null = $sb.AppendLine("")
        $null = $sb.AppendLine("---")
    }

    # Coverage gaps — TSX
    if ($Cov.tsxGaps.Count -gt 0) {
        $null = $sb.AppendLine("")
        $null = $sb.AppendLine("## Coverage Gaps — React Components Not in Catalog ($($Cov.tsxGaps.Count))")
        $null = $sb.AppendLine("")
        $null = $sb.AppendLine("> These ``.tsx`` files exist in ``frontend/`` but are **not mentioned** in any ai/ knowledge file.")
        $null = $sb.AppendLine("")
        $Cov.tsxGaps | ForEach-Object { $null = $sb.AppendLine("- ``$_``") }
        $null = $sb.AppendLine("")
        $null = $sb.AppendLine("---")
    }

    # Coverage gaps — TS hooks
    if ($Cov.tsGaps.Count -gt 0) {
        $showN = [math]::Min($Cov.tsGaps.Count, 60)
        $note  = if ($Cov.tsGaps.Count -gt 60) { "Top $showN of $($Cov.tsGaps.Count) shown." } else { "All $($Cov.tsGaps.Count) shown." }
        $null = $sb.AppendLine("")
        $null = $sb.AppendLine("## Coverage Gaps — TypeScript Hooks & Utilities Not in Catalog ($($Cov.tsGaps.Count))")
        $null = $sb.AppendLine("")
        $null = $sb.AppendLine("> These ``.ts`` files (hooks, converters, handlers, types) exist in ``frontend/`` but are not in any ai/ knowledge file. $note")
        $null = $sb.AppendLine("")
        $Cov.tsGaps | Select-Object -First 60 | ForEach-Object { $null = $sb.AppendLine("- ``$_``") }
        $null = $sb.AppendLine("")
        $null = $sb.AppendLine("---")
    }

    # Confirmed
    $confirmedTsx  = @($confirmed | Where-Object { $_.type -eq "tsx" })
    $confirmedTs   = @($confirmed | Where-Object { $_.type -eq "typescript" })

    $null = $sb.AppendLine("")
    $null = $sb.AppendLine("## ✅ Confirmed Claims ($($confirmed.Count))")
    $null = $sb.AppendLine("")
    $null = $sb.AppendLine("<details>")
    $null = $sb.AppendLine("<summary>Expand — React components ($($confirmedTsx.Count)) and TypeScript hooks/utilities ($($confirmedTs.Count))</summary>")
    $null = $sb.AppendLine("")
    $null = $sb.AppendLine("| File | Type | Confidence | Source | Found At |")
    $null = $sb.AppendLine("|---|---|---|---|---|")
    foreach ($c in ($confirmed | Sort-Object type, fileName)) {
        $at   = if ($c.foundAt) { "``$($c.foundAt)``" } else { "—" }
        $note = if ($c.note)    { " ⚠️ $($c.note)"    } else { "" }
        $null = $sb.AppendLine("| ``$($c.fileName)`` | $($c.type) | $($c.confidence) | $($c.sourceFile) | $at$note |")
    }
    $null = $sb.AppendLine("")
    $null = $sb.AppendLine("</details>")
    $null = $sb.AppendLine("")
    $null = $sb.AppendLine("---")
    $null = $sb.AppendLine("")
    $null = $sb.AppendLine("## Human Audit Checklist (Frontend)")
    $null = $sb.AppendLine("")
    $null = $sb.AppendLine("Automated checks verify **file existence only**. Descriptions require human eyes:")
    $null = $sb.AppendLine("")
    $null = $sb.AppendLine("- [ ] **Fix every ❌ Not Found** — open the source catalog, correct the filename or delete the row.")
    $null = $sb.AppendLine("- [ ] **Audit ``[inferred]`` descriptions** — open each confirmed-but-inferred component and verify")
    $null = $sb.AppendLine("       the stated role is accurate. Mark ``[verified]`` in the catalog when done.")
    $null = $sb.AppendLine("- [ ] **Known bug** — ``SysMLViewFrameNodePaletteAppearanceSection.canHandle`` checks for")
    $null = $sb.AppendLine("       ``'sysMLNoteNode'`` instead of ``'sysMLViewFrameNode'`` → appearance panel never triggers.")
    $null = $sb.AppendLine("       See FEATURE_MAP.md for details.")
    $null = $sb.AppendLine("- [ ] **Review Coverage Gaps** — decide if undocumented TSX/TS files belong in the catalog.")
    $null = $sb.AppendLine("- [ ] **Re-run** after fixes: ``.\scripts-spp\verify-ai-docs-frontend.ps1``")

    Set-Content -Path $reportFile -Value $sb.ToString() -Encoding UTF8
}

# ═══ Main ═════════════════════════════════════════════════════════════════════

Write-Host ""
Write-Host "╔══════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  Frontend Verification Tool — SysON++       ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host "  Repo: $RepoRoot"
Write-Host ""

$runGenerate = -not $VerifyOnly.IsPresent
$runVerify   = -not $GenerateOnly.IsPresent

$allClaims = [System.Collections.Generic.List[PSCustomObject]]::new()

# ── Phase 1: Extract frontend claims ─────────────────────────────────────────

if ($runGenerate) {
    Write-Host "[Phase 1/4] Extracting frontend claims from ai/ knowledge-layer Markdown..." -ForegroundColor Yellow

    $globalSeen = [System.Collections.Generic.HashSet[string]]::new()

    foreach ($fp in $CatalogFilePaths) {
        $fn = Split-Path $fp -Leaf
        if (-not (Test-Path $fp)) {
            Write-Host "    SKIP (not found): $fn" -ForegroundColor DarkGray
            continue
        }
        $extracted = Extract-FrontendClaims -Content (Get-Content $fp -Raw) -SourceFile $fn
        $added = 0
        foreach ($c in $extracted) {
            if ($globalSeen.Add($c.id)) { $allClaims.Add($c); $added++ }
        }
        Write-Host "    $fn  →  $added claims"
    }

    Write-Host "  Total unique frontend claims: $($allClaims.Count)"

    # Merge with existing manifest — preserve prior verification status
    if (Test-Path $manifestFile) {
        try {
            $prior = Get-Content $manifestFile -Raw | ConvertFrom-Json
            $priorMap = @{}
            foreach ($e in $prior.claims) { $priorMap[$e.id] = $e }
            $preserved = 0
            foreach ($c in $allClaims) {
                if ($priorMap.ContainsKey($c.id) -and $priorMap[$c.id].status -ne "pending") {
                    $c.status  = $priorMap[$c.id].status
                    $c.foundAt = $priorMap[$c.id].foundAt
                    $c.note    = $priorMap[$c.id].note
                    $preserved++
                }
            }
            Write-Host "  Merged with prior manifest — $preserved prior results preserved."
        } catch {
            Write-Host "  Warning: existing manifest could not be parsed; starting fresh." -ForegroundColor DarkYellow
        }
    }

    $manifest = [ordered]@{
        _comment    = "Auto-generated by scripts-spp/verify-ai-docs-frontend.ps1 — safe to edit manually"
        generated   = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
        repoCommit  = (Get-GitCommit)
        scope       = "frontend — TypeScript / TSX"
        totalClaims = $allClaims.Count
        claims      = @($allClaims)
    }
    $manifest | ConvertTo-Json -Depth 10 | Set-Content -Path $manifestFile -Encoding UTF8
    Write-Host ""
    Write-Host "  ✅ Manifest written: $manifestFile  ($($allClaims.Count) claims)" -ForegroundColor Green
}

# ── Phase 2: Load manifest for VerifyOnly ────────────────────────────────────

if ($runVerify -and $allClaims.Count -eq 0) {
    if (-not (Test-Path $manifestFile)) {
        Write-Error "Manifest not found at '$manifestFile'. Run without -VerifyOnly first."
    }
    $existing = Get-Content $manifestFile -Raw | ConvertFrom-Json
    foreach ($e in $existing.claims) { $allClaims.Add($e) }
    Write-Host "[Loaded frontend manifest: $($allClaims.Count) claims]"
}

# ── Phase 3: Codebase scan & verify ─────────────────────────────────────────

if ($runVerify) {
    Write-Host ""
    Write-Host "[Phase 2/4] Indexing frontend source trees..." -ForegroundColor Yellow

    # Build a combined index across all TypeScript source directories
    $tsIdx = @{}
    foreach ($subDir in $TsScanDirs) {
        $dir = Join-Path $RepoRoot $subDir
        if (-not (Test-Path $dir)) { continue }
        $partial = Build-FileIndex -SearchDir $dir -Extensions @("ts", "tsx") -Label "$subDir/ *.ts(x)"
        foreach ($key in $partial.Keys) {
            if (-not $tsIdx.ContainsKey($key)) {
                $tsIdx[$key] = $partial[$key]
            } else {
                $prior = $tsIdx[$key]
                if ($prior -is [string]) {
                    $list = [System.Collections.Generic.List[string]]::new()
                    $list.Add($prior); $list.Add($partial[$key]); $tsIdx[$key] = $list
                } else { $tsIdx[$key].Add($partial[$key]) }
            }
        }
    }

    Write-Host ""
    Write-Host "    TypeScript files indexed : $($tsIdx.Count)"

    Write-Host ""
    Write-Host "[Phase 3/4] Verifying $($allClaims.Count) frontend claims..." -ForegroundColor Yellow

    $resolved = [System.Collections.Generic.List[PSCustomObject]]::new()
    foreach ($c in $allClaims) {
        $resolved.Add((Resolve-Claim -Claim $c -TsIdx $tsIdx))
    }

    Write-Host ""
    Write-Host "[Phase 4/4] Coverage analysis & report..." -ForegroundColor Yellow
    $cov = Get-FrontendCoverageStats -TsIdx $tsIdx -Claims @($resolved)
    Write-Host "    TSX coverage : $($cov.tsxDocumented) / $($cov.tsxTotal) components"
    Write-Host "    TS coverage  : $($cov.tsDocumented) / $($cov.tsTotal) hooks & utilities"

    Write-FrontendReport -Claims @($resolved) -Cov $cov -Commit (Get-GitCommit)

    # Update manifest with resolved status
    $manifest = [ordered]@{
        _comment    = "Auto-generated by scripts-spp/verify-ai-docs-frontend.ps1 — safe to edit manually"
        generated   = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
        repoCommit  = (Get-GitCommit)
        scope       = "frontend — TypeScript / TSX"
        totalClaims = $resolved.Count
        claims      = @($resolved)
    }
    $manifest | ConvertTo-Json -Depth 10 | Set-Content -Path $manifestFile -Encoding UTF8

    # Console summary
    $confirmed = @($resolved | Where-Object { $_.status -like "confirmed*" })
    $notFound  = @($resolved | Where-Object { $_.status -eq "not_found" })
    $patterns  = @($resolved | Where-Object { $_.status -eq "pattern_template" })
    $txPct     = if ($cov.tsxTotal -gt 0) { [math]::Round($cov.tsxDocumented / $cov.tsxTotal * 100) } else { 0 }
    $tsPct     = if ($cov.tsTotal  -gt 0) { [math]::Round($cov.tsDocumented  / $cov.tsTotal  * 100) } else { 0 }

    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║          FRONTEND RESULTS                   ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════╝"
    Write-Host ("  ✅ Confirmed   : {0,-5}" -f $confirmed.Count) -ForegroundColor $(if ($notFound.Count -eq 0) { "Green" } else { "White" })
    if ($notFound.Count -gt 0) {
        Write-Host ("  ❌ Not found  : {0,-5}  ← REVIEW THESE IN REPORT" -f $notFound.Count) -ForegroundColor Red
    } else {
        Write-Host ("  ❌ Not found  : 0     ← all frontend claims verified!") -ForegroundColor Green
    }
    Write-Host ("  📐 Patterns   : {0,-5} (intentional Xxx placeholders)" -f $patterns.Count) -ForegroundColor DarkGray
    Write-Host ("  TSX coverage  : {0} / {1} ({2}%)" -f $cov.tsxDocumented, $cov.tsxTotal, $txPct)
    Write-Host ("  TS coverage   : {0} / {1} ({2}%)" -f $cov.tsDocumented,  $cov.tsTotal,  $tsPct)
    Write-Host ""
    Write-Host "  Report : $reportFile" -ForegroundColor Cyan
    Write-Host ""
}

Write-Host "Done (frontend)." -ForegroundColor Green
Write-Host ""
