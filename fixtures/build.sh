#!/usr/bin/env bash
# Build the fixture against every skin and assert the two properties the fixture
# exists to prove:
#
#   1. one View layer  - body markup is identical across skins, once the
#                        normalisations below are applied;
#   2. a stable DOM    - that markup matches the committed snapshot.
#
# "Identical" here means identical after normalize(), not byte-identical. Five
# things are cut before the comparison - the skin link and data-skin marker,
# asset fingerprints, their integrity hashes, the Hugo version in the generator
# meta, and CR. A change to any of those is a legitimate change that must not
# fail this gate, and a real DOM change still cannot hide behind them.
#
#   bash fixtures/build.sh
#   bash fixtures/build.sh --update
#
# CI is the authority; this script is the local gate.

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
demo="$root/demo"
expected="$root/expected"

update=0
[ "${1:-}" = "--update" ] && update=1

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
    # --cleanDestinationDir: a page deleted from content/ must not survive as a
    # stale file in public-*/, or -Update records a snapshot for a page that no
    # longer renders. Hugo does not clean by default.
    hugo --source "$demo" --config "$config" --destination "public-$skin" --quiet --panicOnWarning --cleanDestinationDir
    outputs["$skin"]="$demo/public-$skin/index.html"
done

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
#   - CR is dropped so a Windows checkout and a Linux runner agree.
normalize() {
    sed -E \
        -e '/^[[:space:]]*<link[^>]*skin\.min\./d' \
        -e 's/data-skin="[^"]*"/data-skin="SKIN"/' \
        -e 's/\.min\.[0-9a-f]{32,}\./.min.HASH./' \
        -e 's/integrity="sha256-[^"]*"/integrity="sha256-INTEGRITY"/' \
        -e 's/content="Hugo [^"]*"/content="Hugo VERSION"/' \
        -e 's/\r$//' \
        "$1"
}

reference="${skins[0]}"
reference_root="$demo/public-$reference"
failed=0

# Every rendered page, not just the home page: the shell, the grid and the
# single page all exercise different Foundation partials.
pages=()
while IFS= read -r page; do
    pages+=("$page")
# HTML pages, plus the plain-text home output. llms.txt is a template the
# Foundation ships, so it is compared the same way a page is: the only thing
# worse than a shipped template nobody renders is one nobody would notice
# breaking. The fixture declares no static files, so `*.txt` can only be that
# output.
done < <(find "$reference_root" \( -name '*.html' -o -name '*.txt' \) -type f | LC_ALL=C sort)

[ "${#pages[@]}" -gt 0 ] || {
    echo "nothing was rendered into $reference_root; the build is not exercising the Foundation" >&2
    exit 1
}

for page in "${pages[@]}"; do
    rel="${page#"$reference_root"/}"
    target="$expected/$rel"

    if [ "$update" -eq 1 ]; then
        mkdir -p "$(dirname "$target")"
        normalize "$page" > "$target"
        echo "REC  $rel"
        continue
    fi

    if [ ! -f "$target" ]; then
        echo "FAIL  no snapshot for $rel; run this script with --update to record one"
        failed=1
        continue
    fi

    # Normalise the recorded side too. A Windows checkout can leave CRLF in
    # fixtures/expected/, and comparing that raw against a normalised build can
    # never match. Both sides go through the same function so the comparison
    # depends on the DOM and nothing else.
    if [ "$(normalize "$page")" = "$(normalize "$target")" ]; then
        echo "OK  $rel matches the snapshot"
    else
        echo "FAIL  $rel diverges from the snapshot"
        diff <(normalize "$target") <(normalize "$page") | head -20 || true
        failed=1
    fi
done

# Nothing may be deleted from the snapshot without the script noticing: a page
# that stopped rendering is a regression, not a smaller fixture.
if [ "$update" -eq 0 ]; then
    for recorded in $(cd "$expected" 2>/dev/null && find . \( -name '*.html' -o -name '*.txt' \) -type f | sed 's|^\./||' | LC_ALL=C sort); do
        found=0
        for page in "${pages[@]}"; do
            [ "${page#"$reference_root"/}" = "$recorded" ] && { found=1; break; }
        done
        if [ "$found" -eq 0 ]; then
            echo "FAIL  snapshot contains $recorded but the build did not render it"
            failed=1
        fi
    done
fi

for skin in "${skins[@]:1}"; do
    # Guard against the check silently comparing a build with itself. If the two
    # raw, unnormalised builds are identical, the skin never switched, and every
    # assertion below would pass for the wrong reason.
    if [ "$(cat "${outputs[$skin]}")" = "$(cat "${outputs[$reference]}")" ]; then
        echo "FAIL  $skin output is identical to $reference even before normalising: the skin never switched"
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

# The Foundation stylesheet must be untouched by the skin choice. What is
# compared is the fingerprinted *file name*, not the bytes: Hugo derives the
# fingerprint from the content, so equal names mean equal bytes, and the gate
# never has to read a large stylesheet to decide.
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
