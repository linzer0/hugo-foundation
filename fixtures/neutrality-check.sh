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

baseline_shortcodes='item 9: /img/ paths resolve against the consumer; must move to component params'
baseline_access='item 7: hardcoded PaperMod selectors; must become an opt-in hook'

mapfile -t files < <(find "$repo/layouts" "$repo/assets" -type f \( -name '*.html' -o -name '*.css' -o -name '*.js' \))

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
