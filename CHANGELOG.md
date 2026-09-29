# Changelog

All notable changes to this repository are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

The version is not in a file or a tag on a schedule. It is the tag on the
commit a consumer pins, and it describes **their** upgrade, not our calendar.

---

## What counts as a breaking change

A consumer pins this repository as a git submodule and upgrades by moving a
commit pointer. They do not read this file before they do, and they cannot see
what changed without diffing. So the promise has to be mechanical.

A change is **breaking** — a major bump — if it does any of these:

- removes or renames a public partial (`layouts/partials/fn/**`)
- removes or renames a shortcode, or an existing shortcode parameter
- changes the class contract, so a skin or brand stylesheet stops matching
- changes a `--fn-*` custom property name, or the generic property it feeds
- changes a documented default, so a consumer's override stops being needed
  the same way
- **widens which pages a Foundation template renders.** A template moving from
  `layouts/article/` to `layouts/_default/` is breaking, even though no line of
  the template changed.

The last one is the reason `docs/CONTENT-MODEL.md` §3 exists as a rule rather
than as advice.

Everything else is minor: new components, new optional parameters whose
defaults preserve current output, new archetypes, new content types, new
custom properties with neutral fallbacks.

---

## How to upgrade

```bash
cd themes/hugo-foundation
git fetch origin
git checkout <tag-or-commit>
cd -
git submodule update --remote themes/hugo-foundation
hugo --minify
```

Then run both gates before believing the result:

```bash
bash fixtures/build.sh              # or: powershell -File fixtures/build.ps1
bash fixtures/neutrality-check.sh   # or: powershell -File fixtures/neutrality-check.ps1
```

On Windows either shell runs the `.ps1`: `powershell` is Windows PowerShell 5.1
and is always present, `pwsh` is PowerShell 7 and is not installed by default.

CI runs both on the pinned Hugo version. It is the authority; a local green on
a different Hugo version is not a substitute.

### When an upgrade changes rendered markup

`fixtures/build.ps1` compares the rendered DOM against `fixtures/expected/`. If
it fails after a legitimate upgrade, the change was intended:

```bash
powershell -File fixtures/build.ps1 -Update   # re-record
```

Read the diff before committing. That directory is the record of what the
Foundation actually renders, and a snapshot that changes without an entry here
is a regression, not an improvement.

---

## [Unreleased]

## [0.1.0] - 2026-09-29

### Changed

- **Minimum Hugo version is now Extended 0.167.0.** The Foundation's partials
  reference each other relatively (`{{ partial "./strings.html" . }}`), which
  Hugo resolves only from inside a partial as of 0.167.0
  ([gohugoio/hugo#15376](https://github.com/gohugoio/hugo/pull/15376)). A
  consumer still on an older Hugo will not get a degraded build — the build
  fails with `partial "./…" not found`. There is no shim, by design: a silent
  fallback to absolute paths would reinstate the coupling this removes.

  Public API is unchanged. Consumers keep calling `partial "fn/hero.html"` and
  the rest of the documented `fn/**` entry paths; only Foundation's internal
  calls moved. `emptyPartial` and `mediaPartial` stay absolute on purpose,
  because they name a partial the caller owns and resolve from the theme root.

  The win is portability: a partial keeps working when the `fn/` tree is
  renamed, re-parented or mounted differently, because it resolves against the
  calling partial rather than the theme root. Shadowing still works — a brand
  theme's `fn/strings.html` wins over the Foundation's under both the old and
  the new form, verified on a two-theme fixture. See `docs/CONTRACTS.md` §1a.

### Added

- **Content model layer.** `archetypes/` (`default`, `article`, `note`,
  `bundle`), type-scoped composition templates `layouts/article/` and
  `layouts/note/`, the shared partials `fn/article-shell.html` and
  `fn/article-content.html`, and `assets/css/prose-base.css`. A new site can
  publish a dated article with `hugo new --kind article` and no template of
  its own. Documented in `docs/CONTENT-MODEL.md`.
- New strings keys: `publishedOn`, `updatedOn`, `readingTime`,
  `readingTimeFormat`, `tocLabel`, `tocTitle`, `tagsLabel`, `paginationLabel`,
  `newer`, `older`, `emptyList`.

### Fixed

- **Date formatting was locale-blind.** `fn/article-shell.html` hardcoded
  `2 January 2006`, so every language rendered English dates, and the
  `params.foundation.dateFormat` setting documented in `CONTENT-MODEL.md` was
  never actually read. Resolution order is now param → that setting → Hugo's
  locale-aware `:date_long`, which is correct per language with nothing
  configured.
- `fn/page-to-card.html` read `site.Params.DateFormat` — a base theme's
  parameter — before any Foundation one, which is the R4 violation
  `CONTRACTS.md` §9 item 3 names, and it made a card's date disagree with the
  article it linked to. The Foundation's own setting now takes precedence; the
  legacy parameter still works for existing consumers.
- `fn/page-to-card.html` called `partial ""` whenever no `mediaPartial` was
  passed. Hugo's `cond` evaluates every argument, so the guard did not guard:
  any consumer using `fn/card-grid.html` with `pages` and no media partial hit
  `partial "" not found`. Now an `if`.
- The DOM snapshot comparison read `fixtures/expected/` raw but compared it
  against a CRLF-normalised build, so every page failed on a Windows checkout.
  Both sides are now normalised, and `.gitattributes` pins the snapshots to LF.
  CI runs `windows-latest`, so this would have failed there too.
- `fixtures/build.{ps1,sh}` now pass `--cleanDestinationDir`. Without it, a page
  deleted from `content/` survives in `public-*/` and `-Update` records a
  snapshot for a page that no longer renders.
- A stray non-ASCII character in a `strings.html` contract reference.
- Prose headings get `scroll-margin-top` so a TOC link is not hidden under a
  sticky header. Tune with `--fn-prose-scroll-offset`.

### Notes for consumers

- Additive only. No existing partial, shortcode, parameter, class or custom
  property was removed or renamed, so this is a minor bump and a submodule
  pointer move.
- The one visible difference: a date with no explicit `dateFormat` now follows
  the page's language. On an English-only site `:date_long` and the old default
  are the same; on a multilingual one, dates are now correct rather than
  English. Set `params.foundation.dateFormat` to pin a specific shape.
- Article pages are opt-in. Nothing renders differently until a page declares
  `type: article` or `type: note`.
- If you have your own `layouts/article/` or `layouts/note/`, you keep winning:
  the project layer is resolved before any theme.
