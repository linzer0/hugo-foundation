# Build the fixture against every skin and assert the one property the fixture
# exists to prove: one View layer, byte-identical markup, different styling.
#
#   pwsh -File fixtures/build.ps1
#   bash fixtures/build.sh
#
# CI is the authority; this script is the local gate.

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$demo = Join-Path $root 'demo'

$skins = @('skin-a', 'skin-b')

if (-not (Get-Command hugo -ErrorAction SilentlyContinue)) {
    Write-Error 'hugo not found. Install Hugo Extended, or run this in CI.'
}

$outputs = @{}

foreach ($skin in $skins) {
    # hugo.yaml already selects skin A, so it needs no override. Every other
    # skin merges its own override on top. The file name must exist: Hugo does
    # not fail on a missing --config entry, it silently builds with what it
    # found, which would make the comparison below compare a build with itself.
    $config = 'hugo.yaml'
    if ($skin -ne 'skin-a') {
        $override = "hugo.$skin.yaml"
        if (-not (Test-Path -LiteralPath (Join-Path $demo $override))) {
            Write-Error "missing skin override: $demo\$override"
        }
        $config = "hugo.yaml,$override"
    }
    $dest = "public-$skin"
    Write-Host "==> building $skin (--config $config)"
    & hugo --source $demo --config $config --destination $dest --quiet
    if ($LASTEXITCODE -ne 0) {
        Write-Error "hugo failed for $skin"
    }
    $outputs[$skin] = Join-Path $demo "$dest/index.html"
}

# Normalise away the two things that are allowed to differ: the skin stylesheet
# link and the skin marker. Everything else must match exactly.
function Normalize([string]$path) {
    $lines = Get-Content -LiteralPath $path
    $kept = $lines | Where-Object { $_ -notmatch 'skin\.min\.' }
    return ($kept -join "`n") -replace 'data-skin="[^"]*"', 'data-skin="SKIN"'
}

$reference = $skins[0]
$referenceText = Normalize $outputs[$reference]
$referenceRaw = Get-Content -LiteralPath $outputs[$reference] -Raw
$failed = $false

foreach ($skin in $skins[1..($skins.Count - 1)]) {
    $raw = Get-Content -LiteralPath $outputs[$skin] -Raw

    # Guard against the check silently comparing a build with itself. If the two
    # raw builds are byte-identical, the skin never switched, and every
    # assertion below would pass for the wrong reason.
    if ($raw -eq $referenceRaw) {
        Write-Host "FAIL  $skin output is byte-identical to ${reference}: the skin never switched"
        $failed = $true
        continue
    }

    if ((Normalize $outputs[$skin]) -eq $referenceText) {
        Write-Host "OK  $skin markup is identical to $reference"
    }
    else {
        Write-Host "FAIL  $skin markup diverges from $reference"
        Compare-Object ($referenceText -split "`n") ((Normalize $outputs[$skin]) -split "`n") |
            Select-Object -First 20 | Format-Table -AutoSize
        $failed = $true
    }
}

# The Foundation stylesheet must be untouched by the skin choice.
$baseHash = @()
foreach ($skin in $skins) {
    $file = Get-ChildItem (Join-Path $demo "public-$skin\css") -Filter 'components-base*.css' |
        Select-Object -First 1
    $baseHash += $file.Name
}
if (($baseHash | Select-Object -Unique).Count -ne 1) {
    Write-Host "FAIL  the Foundation stylesheet differs between skins: $($baseHash -join ', ')"
    $failed = $true
}
else {
    Write-Host "OK  Foundation stylesheet is identical across skins"
}

if ($failed) {
    Write-Error 'fixture check failed: the View layer is not skin-agnostic'
}

Write-Host ''
Write-Host "All checks passed. Open $demo\public-skin-a\index.html and $demo\public-skin-b\index.html to compare."
