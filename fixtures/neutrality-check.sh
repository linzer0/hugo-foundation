#!/usr/bin/env bash
# Neutrality guard. See neutrality-check.ps1 for the full rationale.
#
#   bash fixtures/neutrality-check.sh
#
# HARD  - brand names, analytics IDs, locale branching. Must be zero, always.
# KNOWN - host asset paths and base-theme selectors still awaiting the migration,
#         listed in the baseline. The baseline may shrink; it may not grow.

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo="$(dirname "$root")"

# Both clean today: shortcodes-base.css has no /img/ path and
# accessibility-base.css has no base-theme selector. Kept as tripwires for
# those two files, not as acknowledgements of live defects — CONTRACTS.md §9.
baseline_shortcodes='item 9: was /img/ paths resolving against the consumer; now clean'
baseline_access='item 7: was hardcoded PaperMod selectors; now clean'

# archetypes/ is included: an archetype is the starting point for every article
# on every consumer's site, so a brand name or a site-specific path that leaks
# into one propagates to everything written after it.
mapfile -t files < <(
    find "$repo/layouts" "$repo/assets" -type f \( -name '*.html' -o -name '*.css' -o -name '*.js' \)
    if [ -d "$repo/archetypes" ]; then
        find "$repo/archetypes" -type f \( -name '*.md' -o -name '*.html' \)
    fi
)

hard=0
known=0

scan() { # pattern kind reason
    local pattern="$1" kind="$2" reason="$3" file line base
    while IFS= read -r file; do
        [ -n "$file" ] || continue
        while IFS= read -r line; do
            [ -n "$line" ] || continue
            local num="${line%%:*}"
            local base=''
            case "$(basename "$file")" in
                shortcodes-base.css)    base="$baseline_shortcodes" ;;
                accessibility-base.css) base="$baseline_access" ;;
            esac
            if [ "$kind" = known ] && [ -n "$base" ]; then
                echo "KNOWN  $(basename "$file"):$num  $reason  [$base]"
                known=$((known + 1))
            else
                echo "FAIL   $(basename "$file"):$num  $reason"
                hard=$((hard + 1))
            fi
        done < <(grep -nE -- "$pattern" "$file" 2>/dev/null || true)
    done < <(printf '%s\n' "${files[@]}")
}

scan '\bLinar\b|\blinar\.(games|world)'        hard  'brand name'
scan 'yandexMetrika|googleAnalyticsId|G-[A-Z0-9]{8}' hard 'analytics ID'
scan 'site\.Language\.Lang'                     hard  'locale branching; use the strings dict'
scan '(^|[^[:alnum:]_-])/img/'                  known 'host asset path'
scan '\.top-link|#theme-toggle'                 known 'base-theme selector'

echo
if [ "$hard" -ne 0 ]; then
    echo "neutrality check failed: $hard new, $known known violations still tracked" >&2
    exit 1
fi

echo "neutrality OK: 0 new, $known known violations still tracked"
