# Neutrality guard.
#
# The Foundation is shared by sites that do not share a brand. This checks that
# it has not quietly grown one.
#
#   powershell -File fixtures/neutrality-check.ps1   # Windows PowerShell 5.1
#   pwsh -File fixtures/neutrality-check.ps1         # PowerShell 7
#   bash fixtures/neutrality-check.sh
#
# Two classes of finding:
#
#   HARD  - brand names, analytics IDs, locale branching. Must be zero, always.
#   KNOWN - host asset paths and base-theme selectors, listed in $Baseline below.
#           Each entry is a real violation of docs/CONTRACTS.md 9 that is still
#           waiting on the migration. The baseline may shrink; it may not grow.
#           A finding in that class, outside the baseline, is a failure.
#
# Note: Select-String is given explicit -LiteralPath here on purpose. Piping
# FileInfo objects into it binds to -InputObject instead of -Path, which finds
# nothing and, under `powershell -File`, blocks on stdin.

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$repo = Split-Path -Parent $root

# file -> why it is still here
$Baseline = @{
    # Both of these are clean today: `shortcodes-base.css` has no `/img/` path
    # and `accessibility-base.css` has no base-theme selector. The entries stay
    # as tripwires for those two files, not as acknowledgements of live defects
    # — see CONTRACTS.md §9. Removing a waiver for a fixed file is what lets the
    # baseline shrink, and the class is still `known` rather than `hard` so a
    # deliberate future image stays a review question instead of a hard stop.
    'shortcodes-base.css'     = 'item 9: was /img/ paths resolving against the consumer; now clean'
    'accessibility-base.css'  = 'item 7: was hardcoded PaperMod selectors; now clean'
}

# archetypes/ is included: an archetype is the starting point for every article
# on every consumer's site, so a brand name or a site-specific path that leaks
# into one propagates to everything written after it. .md is scanned there only;
# layouts/ and assets/ keep their own extension list.
$paths = @(
    Get-ChildItem -Path (Join-Path $repo 'layouts'), (Join-Path $repo 'assets') -Recurse -File |
        Where-Object { $_.Extension -in '.html', '.css', '.js' }
    Get-ChildItem -Path (Join-Path $repo 'archetypes') -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Extension -in '.md', '.html' }
) | ForEach-Object { $_.FullName }

$Rules = @(
    @{ Pattern = '\bLinar\b|\blinar\.(games|world)';        Kind = 'hard';  Reason = 'brand name' }
    @{ Pattern = 'yandexMetrika|googleAnalyticsId|G-[A-Z0-9]{8}'; Kind = 'hard'; Reason = 'analytics ID' }
    @{ Pattern = 'site\.Language\.Lang';                     Kind = 'hard';  Reason = 'locale branching; use the strings dict' }
    @{ Pattern = '(?<![\w-])/img/';                          Kind = 'known'; Reason = 'host asset path' }
    @{ Pattern = '\.top-link|#theme-toggle';                 Kind = 'known'; Reason = 'base-theme selector' }
)

$findings = @()
foreach ($rule in $Rules) {
    $hits = @(Select-String -LiteralPath $paths -Pattern $rule.Pattern)
    foreach ($hit in $hits) {
        $findings += [pscustomobject]@{
            File     = Split-Path -Leaf $hit.Path
            Line     = $hit.LineNumber
            Kind     = $rule.Kind
            Reason   = $rule.Reason
            Baseless = ($rule.Kind -eq 'known') -and (-not $Baseline.ContainsKey((Split-Path -Leaf $hit.Path)))
        }
    }
}

Write-Host "scanned $($paths.Count) files in layouts/ and assets/"

$known    = @($findings | Where-Object { $_.Kind -eq 'known' -and -not $_.Baseless })
$unbased  = @($findings | Where-Object { $_.Baseless })
$hard     = @($findings | Where-Object { $_.Kind -eq 'hard' })

foreach ($f in $known) {
    Write-Host "KNOWN  $($f.File):$($f.Line)  $($f.Reason)  [$($Baseline[$f.File])]"
}
foreach ($f in $unbased) {
    Write-Host "FAIL   $($f.File):$($f.Line)  $($f.Reason)  (not in the baseline)"
}
foreach ($f in $hard) {
    Write-Host "FAIL   $($f.File):$($f.Line)  $($f.Reason)"
}

if ($hard.Count -gt 0 -or $unbased.Count -gt 0) {
    Write-Error 'neutrality check failed'
}

Write-Host ''
Write-Host "neutrality OK: $($hard.Count + $unbased.Count) new, $($known.Count) known violations still tracked"
