# Build the fixture against every skin and assert the two properties the fixture
# exists to prove:
#
#   1. one View layer  - body markup is identical across skins, once the
#                        normalisations below are applied;
#   2. a stable DOM    - that markup matches the committed snapshot.
#
# "Identical" here means identical after Normalize, not byte-identical. Five
# things are cut before the comparison - the skin link and data-skin marker,
# asset fingerprints, their integrity hashes, the Hugo version in the generator
# meta, and CR. A change to any of those is a legitimate change that must not
# fail this gate, and a real DOM change still cannot hide behind them.
#
#   powershell -File fixtures/build.ps1        # Windows PowerShell 5.1
#   pwsh -File fixtures/build.ps1              # PowerShell 7
#   powershell -File fixtures/build.ps1 -Update
#
# CI is the authority; this script is the local gate.

param(
    # Re-record fixtures/expected instead of comparing against it. Use only
    # when a markup change is intended, and read the diff before committing.
    [switch] $Update
)

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$demo = Join-Path $root 'demo'
$expected = Join-Path $root 'expected'

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
    # --cleanDestinationDir: a page deleted from content/ must not survive as a
    # stale file in public-*/, or -Update records a snapshot for a page that no
    # longer renders. Hugo does not clean by default.
    & hugo --source $demo --config $config --destination $dest --quiet --panicOnWarning --cleanDestinationDir
    if ($LASTEXITCODE -ne 0) {
        Write-Error "hugo failed for $skin"
    }
    $outputs[$skin] = Join-Path $demo "$dest\index.html"
}

# Reduce the rendered page to the part this fixture actually owns: the DOM the
# Foundation emits. Everything that changes without the DOM changing is
# normalised away, so the assertion cannot fail for an unrelated reason and
# cannot pass while the DOM drifts.
#
#   - the skin stylesheet link and the data-skin marker are the only two things
#     a skin is allowed to change;
#   - asset fingerprints and their integrity hashes change whenever CSS or JS
#     is edited, which is not a markup change;
#   - the generator meta carries the Hugo version, which is not this repo's;
#   - CRLF is dropped so a Windows checkout and a Linux runner agree.
function Normalize([string]$path) {
    $text = [System.IO.File]::ReadAllText($path)
    $text = $text -replace '(?m)^[ \t]*<link[^>]*skin\.min\.[^\r\n]*\r?\n?', ''
    $text = $text -replace 'data-skin="[^"]*"', 'data-skin="SKIN"'
    $text = $text -replace '\.min\.[0-9a-f]{32,}\.', '.min.HASH.'
    $text = $text -replace 'integrity="sha256-[^"]*"', 'integrity="sha256-INTEGRITY"'
    $text = $text -replace 'content="Hugo [^"]*"', 'content="Hugo VERSION"'
    return ($text -replace "`r", '')
}

$reference = $skins[0]
$referenceRoot = Join-Path $demo "public-$reference"
$failed = $false

# Every rendered page, not just the home page: the shell, the grid and the
# single page all exercise different Foundation partials.
# HTML pages, plus the plain-text home output. llms.txt is a template the
# Foundation ships, so it is compared the same way a page is: the only thing
# worse than a shipped template nobody renders is one nobody would notice
# breaking. The fixture declares no static files, so `*.txt` can only be that
# output.
$snapshotFilter = @('*.html', '*.txt')

$pages = Get-ChildItem -Recurse -File -Path $referenceRoot -Include $snapshotFilter |
    Sort-Object FullName

if (-not $pages) {
    Write-Error "nothing was rendered into $referenceRoot; the build is not exercising the Foundation"
}

# LF, no BOM: the committed snapshot must not depend on the platform that
# recorded it. Windows PowerShell 5.1 has no utf8NoBOM option, and its
# Out-File -Encoding UTF8 would add a BOM that then shows up in every diff of
# this file. Neither survives the comparison, so this is about the checked-in
# artefact, not about what the gate can see.
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

foreach ($page in $pages) {
    $rel = $page.FullName.Substring($referenceRoot.Length).TrimStart('\', '/')
    $target = Join-Path $expected $rel
    $actual = Normalize $page.FullName

    if ($Update) {
        $dir = Split-Path -Parent $target
        if (-not (Test-Path -LiteralPath $dir)) {
            New-Item -ItemType Directory -Force -Path $dir | Out-Null
        }
        [System.IO.File]::WriteAllText($target, $actual, $utf8NoBom)
        Write-Host "REC  $rel"
        continue
    }

    if (-not (Test-Path -LiteralPath $target)) {
        Write-Host "FAIL  no snapshot for $rel; run this script with -Update to record one"
        $failed = $true
        continue
    }

    # Normalise the recorded side too, not just the built one. Git's default
    # checkout on Windows writes CRLF into fixtures/expected/, and comparing
    # that raw against a normalised build can never match. Normalising both
    # sides makes the comparison depend on the DOM and nothing else, on every
    # platform this script runs on.
    $recorded = Normalize $target
    if ($recorded -eq $actual) {
        Write-Host "OK  $rel matches the snapshot"
    }
    else {
        Write-Host "FAIL  $rel diverges from the snapshot"
        Compare-Object ($recorded -split "`n") ($actual -split "`n") |
            Select-Object -First 20 | Format-Table -AutoSize
        $failed = $true
    }
}

# Nothing may be deleted from the snapshot without the script noticing: a page
# that stopped rendering is a regression, not a smaller fixture.
if (-not $Update) {
    $recordedPages = Get-ChildItem -Recurse -File -Path $expected -Include $snapshotFilter -ErrorAction SilentlyContinue
    if ($recordedPages) {
        $builtRel = $pages | ForEach-Object { $_.FullName.Substring($referenceRoot.Length).TrimStart('\', '/') }
        $orphan = $recordedPages | ForEach-Object { $_.FullName.Substring($expected.Length).TrimStart('\', '/') } |
            Where-Object { $builtRel -notcontains $_.Replace('\', '/') -and $builtRel -notcontains $_ }
        foreach ($o in $orphan) {
            Write-Host "FAIL  snapshot contains $o but the build did not render it"
            $failed = $true
        }
    }
}

$referenceText = Normalize $outputs[$reference]
$referenceRaw = Get-Content -LiteralPath $outputs[$reference] -Raw

foreach ($skin in $skins[1..($skins.Count - 1)]) {
    $raw = Get-Content -LiteralPath $outputs[$skin] -Raw

    # Guard against the check silently comparing a build with itself. If the two
    # raw, unnormalised builds are identical, the skin never switched, and
    # every assertion below would pass for the wrong reason.
    if ($raw -eq $referenceRaw) {
        Write-Host "FAIL  $skin output is identical to ${reference} even before normalising: the skin never switched"
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

# The Foundation stylesheet must be untouched by the skin choice. What is
# compared is the fingerprinted *file name*, not the bytes: Hugo derives the
# fingerprint from the content, so equal names mean equal bytes, and the gate
# never has to read a large stylesheet to decide.
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
