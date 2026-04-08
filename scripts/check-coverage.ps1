# RRX: AC vs TC coverage (PowerShell). Same contract as check-coverage.sh.
param(
    [Parameter(Mandatory = $true)][string]$FeatureDir,
    [switch]$StrictTrace
)

$ErrorActionPreference = "Stop"

$spec = Join-Path $FeatureDir "spec.md"
$tcases = Join-Path $FeatureDir "rrx\test-cases.md"
$trace = Join-Path $FeatureDir "rrx\trace-ac.md"

if (-not (Test-Path $spec -PathType Leaf)) {
    Write-Error "missing spec: $spec"
}
if (-not (Test-Path $tcases -PathType Leaf)) {
    Write-Error "missing $tcases (run /speckit.rrx.spec first)"
}

$specText = Get-Content -Raw $spec
$tcText = Get-Content -Raw $tcases

$acMatches = [regex]::Matches($specText, '\bAC-\d+\b') | ForEach-Object { $_.Value } | Sort-Object -Unique
if ($acMatches.Count -eq 0) {
    Write-Error "no AC-NN tokens found in spec.md"
}

$missing = @()
foreach ($ac in $acMatches) {
    $stem = $ac -replace '^AC-', ''
    $hdr = "^## $ac\b"
    # TC-003-A style: optional leading zeros before stem
    $tcPat = "\bTC-0*$stem-[A-Z]+\b"
    $okHdr = $tcText -match $hdr
    $okTc = $tcText -match $tcPat
    if (-not ($okHdr -or $okTc)) {
        $missing += $ac
    }
}

if ($missing.Count -gt 0) {
    Write-Host "RRX coverage gate: FAIL"
    Write-Host "Acceptance criteria in spec.md without TC coverage in test-cases.md:"
    $missing | ForEach-Object { Write-Host "  - $_" }
    exit 1
}

if ($StrictTrace -and (Test-Path $trace -PathType Leaf)) {
    $tr = Get-Content -Raw $trace
    foreach ($ac in $acMatches) {
        if ($tr -notmatch [regex]::Escape($ac)) {
            Write-Error "trace-ac.md missing row for $ac"
        }
    }
}

Write-Host "RRX coverage gate: OK ($($acMatches.Count) acceptance criteria have TC stubs in test-cases.md)"
exit 0
