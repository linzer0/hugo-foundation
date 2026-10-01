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

### Removed

- **`unity-webgl-player` shortcode.** This is a breaking change: the name is no
  longer frozen (see "What counts as a breaking change" above) and any page
  using it will render nothing. It went with its fixture, 155 lines of
  `.webgl-player` / `.unity-*` styling in `assets/css/shortcodes-base.css`, and
  the four `strings` keys it needed — `loadGame`, `mobileUnsupported`,
  `narrowViewportHint`, `fullscreen`. It was the only component that could not
  be localised, because its hardcoded English and the defaults written for it
  disagreed word for word, and no consumer wanted it. `AGENTS.md` says not to
  reintroduce it without one.
- **`assets/css/base-theme-papermod.css`** — the opt-in PaperMod `.footer`
  adapter. No Foundation template ever loaded it, and the only consumer in this
  repository's orbit (`linar.games`) explicitly does not either, so removing it
  is not a breaking change: no consumer-visible default is lost, and the file
  is not part of any public partial, shortcode, class, or `--fn-*` token. Per
  decision #51, PaperMod-specific styling belongs to the PaperMod-selecting
  consumer, not to the shared Foundation. Consumers that need an equivalent
  `.footer` treatment keep it in their own `assets/css/`.

### Changed

- **`gallery` dialog reads `--fn-*` tokens.** The five `var(--entry|…|--primary|--secondary|--border|--theme, …)`
  calls in `assets/css/shortcodes-base.css` are now `--fn-surface`,
  `--fn-text`, `--fn-text-muted`, `--fn-border` and `--fn-surface-sunken`. The
  neutral fallbacks reproduce the literal defaults that were on the PaperMod
  variables, so a consumer that does not define the new tokens renders
  byte-identical to before; a consumer that does (e.g. `linar.games`, which
  already projects onto `--fn-surface` / `--fn-text` / `--fn-text-muted`) gets
  the brand values, also as before. Two new tokens are added to the theming
  surface: `--fn-border` (default `#ddd`) and `--fn-surface-sunken` (default
  `#f5f5f5`). Documented in `docs/CONTRACTS.md` §7.6. Not a breaking change
  per the contract: no public class, shortcode, partial, or existing
  `--fn-*` token renamed; only neutral fallbacks carry the same defaults.
- **`gallery` and `video` moved behind partials.** `fn/media/gallery.html` and
  `fn/media/video.html` now hold the compositions and the shortcodes call them,
  which is the arrangement §7.6–7.7 and §8 have always described. The partial is
  the contract; a consumer restyles a gallery by shadowing the partial rather
  than the shortcode. **The rendered output is byte-identical** for the gallery,
  verified by building the same content with the inline shortcode and with the
  partial and diffing. The one visible change is in `video`: its fallback text
  was two hardcoded English lines and is now `strings.videoFallback`, one line
  with the same words. HTML collapses the line break, so the sentence a browser
  reads is unchanged.
- `videoFallback`'s default lost a comma it never had in the shipped markup, so
  the key now matches what the component actually rendered.
- `CONTRACTS.md` §7.6 and §7.7 describe the markup that exists rather than a
  `.fn-gallery` naming that was never shipped. §7.8 is gone with the component,
  and §7.9/§7.10 are renumbered §7.8/§7.9.
- `docs/LOCALIZATION.md` §6 moves from "known gap" to closed. Every shortcode
  that renders text now resolves strings.

### Fixed

- **The gallery fixture matched nothing.** `shortcodes/gallery/index.md` passes
  `folder="cover"` while its image sat at the bundle root, and the shortcode
  matches `<folder>/*`, so the recorded snapshot was an empty container that
  read like coverage. The image now lives in `cover/` and the fixture renders a
  real card, which is the first time the orientation logic, the resize targets
  and the link's `aria-label` have been asserted anywhere.
- The gallery's three `aria-label`s resolve through `fn/strings.html` instead of
  being written in the markup. The keys were in the resolver the whole time,
  unused; a bilingual consumer could not change them without forking the
  shortcode. Output is byte-identical.

## [0.2.0] - 2026-09-29

The Foundation is now a site as well as a theme. Clone it and `hugo server
--source site` gives you a working article site; add it as a submodule and you
get the same View layer underneath your own content.

### Added

- **`site/` — the Foundation's own site.** A home page, an articles section, a
  notes section, a Dev Log entry and an about page, wired to the Foundation as
  its own theme. This is what makes the repository a starting point rather
  than a directory of partials. It builds with no base theme at all.
- **A `page` content type** — `layouts/page/single.html` and
  `layouts/page/baseof.html`, plus `archetypes/page.md`. About, contact and
  colophon pages have no honest home in `article` or `note`, and without a
  Foundation type they were the reason a site needed a base theme just to
  exist. See `docs/CONTENT-MODEL.md` §2.
- **`layouts/llms.txt`** — the site index for LLM crawlers, so the `llms` output
  format declared in `site/hugo.yaml` has something to render even with no base
  theme. PaperMod ships an equivalent, but PaperMod is optional here.
- **`partials/fn/document-head.html`** — the shared `<head>` of the article,
  page and note shells, and the home. A baseof must expose Hugo's `main` block
  and a partial cannot carry a block, so the shells stay separate files; the
  head did not have to be, and three copies of a stylesheet list is three
  places to forget a file.
- **`themes/PaperMod` as a submodule** — the optional base theme for `site/`
  only, enabled by `site/hugo.with-base-theme.yaml`. Off by default. Consumers
  who add Foundation as a theme never see it.
- **Dev Log as a usage pattern of `note`.** `archetypes/devlog.md` generates a
  `type: note` with a `version` field, a `changes` list, and the `devlog`
  tag pre-stamped; `docs/DEV-LOG.md` records the convention. The Foundation
  does not render `changes` itself — a consumer extends the list with their
  own keys rather than asking for a new template. A starter entry under
  `site/content/devlog/` exercises it.
- **Shortcode smoke coverage in the fixture.** Fixture pages under
  `fixtures/demo/content/shortcodes/` exercise `gallery`, `video` and
  `unity-webgl-player` at template level, so a parsing or markup regression
  in a shortcode now fails the local gate. Visual fidelity (Unity builds,
  multilingual stands) is the half the gate cannot bridge; see
  `docs/CONTRACTS.md` §13.2 and
  [#6](https://github.com/linzer0/hugo-foundation/issues/6).
- **`docs/BASE-THEME.md`, `docs/LOCALIZATION.md`, `docs/DEV.md`, `docs/DEV-LOG.md`.**

### Fixed

- **PR #9: `merge` in `fn/strings.html` normalised every key to lower case**
  and stored the lower-cased spelling on collision. The defaults above are
  camelCase, so the moment a consumer supplied a single string the returned
  map lost every camelCase key and every caller read nil. Replaced `merge`
  with a `Scratch`-based resolver that matches incoming keys against the
  defaults case-insensitively, so a lower-cased configuration key still lands
  on the camelCase default, and a key that matches no default is passed
  through untouched. Verified against the fixture and against
  `linzer0.github.io`.
- **`note` pages rendered nothing without a base theme.** `note/single.html`
  existed with no baseof to pair it, so a note page resolved its content
  template and then found no document shell. The fixture never caught it: the
  demo's own `layouts/_default/baseof.html` sat in the project and answered the
  request. This contradicted `CONTENT-MODEL.md` §8.
- **`fn-banner.js` and `gallery-dialog.js` were never loaded.** No Foundation
  shell referenced them, so a dismissible banner did not dismiss and the
  gallery dialog did not open. The fixture masked it for the banner because
  its own baseof loads `fn-banner.js`.
- **`.AlternativeOutputFormats` was iterated twice** in the document shells. On
  a page with any alternative output — an RSS-enabled site, which is the normal
  case — this failed the build with `range can't iterate over
  {alternate {rss …}}`. It never fired in the fixture, which disables RSS.
- **`llms.txt` newlines.** Section headings ran into the first list item:
  `# Articles- [Start here](…)`.

### Changed

- **A `note` page now renders in the Foundation's shell**, like an `article`
  page, instead of falling through to the base theme's `_default/baseof.html`.
  This is the change most likely to be visible on a consumer, so it is called
  out under breaking changes below.
- **Foundation shells emit two `<script>` tags** (`fn-banner.js`,
  `gallery-dialog.js`) that they did not emit before. A consumer shadowing
  `article/baseof.html` gets its own head and is unaffected.
- **`CONTRACTS.md` §10 rewritten.** The anti-goals now bind the *neutral layer*
  rather than the repository, and a new §10a records the theme/site split and
  why the site's material cannot live at the root.

### Documented

- **The home page has no scoped baseof.** Verified against 0.167.0: Hugo resolves
  the home baseof only from `layouts/_default/baseof.html`, which this
  repository may not ship. `index.baseof.html` and `home.baseof.html` are not
  found, and Hugo reports the failure as "no layout file" rather than as a
  missing template. The home is therefore a standalone document.
- **A theme's `hugo.yaml` and `content/` leak into every consuming build**, and
  there is no opt-out from the theme side. This is why the site lives in
  `site/` and the repository root holds only what a consumer should inherit.
- **`--config` paths are relative to `--source`.** Written as
  `--config site/hugo.yaml,…` Hugo finds neither file, falls back to defaults,
  drops the theme list with them, and reports "no layout file" for every kind.

### Breaking for consumers

- A `type: note` page now renders with `layouts/note/baseof.html` rather than
  with the base theme's `_default/baseof.html`. A consumer that relied on notes
  inheriting their base theme's chrome — PaperMod's header, menu and footer —
  will see notes switch to the Foundation's minimal document. Fix by shadowing
  `layouts/note/baseof.html` in your own `layouts/`, exactly as you would for
  `layouts/article/baseof.html`. A consumer that does not care is unaffected:
  both shells are complete documents.

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
