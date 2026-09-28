#!/usr/bin/env bash
# Build the fixture against every skin and assert the one property the fixture
# exists to prove: one View layer, byte-identical markup, different styling.
#
#   bash fixtures/build.sh
#
# CI is the authority; this script is the local gate.

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
demo="$root/demo"

skins=(skin-a skin-b)

command -v hugo >/dev/null 2>&1 || {
    echo "hugo not found. Install Hugo Extended, or run this in CI." >&2
    exit 1
}

declare -A outputs

for skin in "${skins[@]}"; do
    # hugo.yaml already selects skin A, so it needs no override. Every other
    # skin merges its own override on top. The file must exist: Hugo does not
    # fail on a missing --config entry, it silently builds with what it found,
    # which would make the comparison below compare a build with itself.
    config="hugo.yaml"
    if [ "$skin" != "skin-a" ]; then
        override="hugo.$skin.yaml"
        [ -f "$demo/$override" ] || { echo "missing skin override: $demo/$override" >&2; exit 1; }
        config="hugo.yaml,$override"
    fi
    echo "==> building $skin (--config $config)"
    hugo --source "$demo" --config "$config" --destination "public-$skin" --quiet
    outputs["$skin"]="$demo/public-$skin/index.html"
done

# Normalise away the two things that are allowed to differ: the skin stylesheet
# link and the skin marker. Everything else must match exactly.
normalize() {
    grep -v 'skin\.min\.' "$1" | sed -E 's/data-skin="[^"]*"/data-skin="SKIN"/'
}

reference="${skins[0]}"
failed=0

for skin in "${skins[@]:1}"; do
    # Guard against the check silently comparing a build with itself. If the two
    # raw builds are byte-identical, the skin never switched, and every
    # assertion below would pass for the wrong reason.
    if [ "$(cat "${outputs[$skin]}")" = "$(cat "${outputs[$reference]}")" ]; then
        echo "FAIL  $skin output is byte-identical to $reference: the skin never switched"
        failed=1
        continue
    fi

    if [ "$(normalize "${outputs[$skin]}")" = "$(normalize "${outputs[$reference]}")" ]; then
        echo "OK  $skin markup is identical to $reference"
    else
        echo "FAIL  $skin markup diverges from $reference"
        diff <(normalize "${outputs[$reference]}") <(normalize "${outputs[$skin]}") || true
        failed=1
    fi
done

# The Foundation stylesheet must be untouched by the skin choice.
base_names=$(for skin in "${skins[@]}"; do
    find "$demo/public-$skin/css" -name 'components-base*.css' -printf '%f\n' | head -n 1
done)
if [ "$(echo "$base_names" | sort -u | wc -l)" -ne 1 ]; then
    echo "FAIL  the Foundation stylesheet differs between skins: $base_names"
    failed=1
else
    echo "OK  Foundation stylesheet is identical across skins"
fi

if [ "$failed" -ne 0 ]; then
    echo "fixture check failed: the View layer is not skin-agnostic" >&2
    exit 1
fi

echo
echo "All checks passed. Compare $demo/public-skin-a/index.html and $demo/public-skin-b/index.html."
