# Foundation View Contracts

Public API of the Hugo Foundation. Implements step 1 of
[issue #20](https://github.com/linzer0/linzer0.github.io/issues/20): describe the
data, slots, parameters, accessibility guarantees and override points of every
layout and component the Foundation exposes.

A consumer is the site that owns `hugo.yaml`, content, identity and deployment.
It may keep its brand CSS and overrides in the site itself. A separate brand
module is optional and useful when multiple sites reuse that same brand layer.
This document is binding on the Foundation and on every consumer.

Content types, front matter and archetypes are a separate, equally binding
contract: see `CONTENT-MODEL.md`.

---

## 1. What counts as "in contract"

A Foundation component satisfies all four rules, or it does not ship.

| Rule | Statement |
|---|---|
| **R1 Neutrality** | No brand, site identity, authored content, analytics IDs, hardcoded host URLs, or locale-dependent literal text. |
| **R2 Structure over style** | Foundation emits semantic DOM, stable class names and CSS custom properties. It never decides visual identity. |
| **R3 Total data input** | Every user-visible value arrives as a parameter. No implicit reads of specific front-matter keys, no implicit `$.Page`/caller context. |
| **R4 No host coupling** | Foundation never hardcodes another theme's class names, selectors or asset paths. |

R3 is the rule that most often gets violated by "helpful" convenience: reading
`cover.image` because a consumer happens to use it turns a reusable component
into a site-specific one.

---

## 1a. Minimum Hugo version

**Hugo Extended 0.167.0.** §13 is the canonical statement of the supported
toolchain; this section only records why the floor sits there.

This is a floor, not a preference. Foundation's partials reference each other
with relative paths (`{{ partial "./strings.html" . }}`), which Hugo only
resolves from inside a partial as of 0.167.0
([#15376](https://github.com/gohugoio/hugo/pull/15376)). On 0.146.0 the same
call fails the build outright:

```
error calling partial: partial "./strings.html" not found
```

There is no compatibility shim. A consumer on an older Hugo must upgrade before
consuming this Foundation; that is deliberate, because a silent fallback to
absolute paths would reintroduce exactly the coupling relative references
remove.

### Why relative, and what it does not change

Relative references make the `fn/` tree movable: a partial keeps working after
the directory is renamed, re-parented or mounted differently, because it
resolves against the calling partial rather than against the theme root. That is
the portability win, and it is why the internal calls are worth the version
bump.

**The public API is untouched.** Consumers keep calling `partial "fn/hero.html"`;
only Foundation's own internal calls changed. The two partial names that a
caller supplies at runtime — `emptyPartial` in `fn/card-grid` and
`mediaPartial` in `fn/page-to-card` — stay absolute on purpose, because they
name a partial the caller owns and resolves from the theme root, not from
inside `fn/`.

---

## 2. Layer resolution (verified)

Hugo resolves a template by walking, in order:

1. the project's `layouts/` directory,
2. then each theme directory **in the exact order listed under `theme:`**,
3. first match wins. Templates at the same path are **not** merged.

Verified empirically against Hugo Extended 0.167.0 with a two-theme fixture that
both define `layouts/_default/single.html`:

| Config | Result |
|---|---|
| `theme: [A, B]` | A wins |
| `theme: [B, A]` | B wins |
| project `layouts/` + `theme: [A, B]` | project wins |

### Recommended consumer chain

Because the first declaration wins, the chain is declared **most specific
first**, not most general first:

```yaml
theme:
  - hugo-foundation  # neutral View + content-model layer
  - PaperMod         # optional fallback theme
```

Project-level `layouts/` take precedence over all themes. A reusable consumer
brand module may appear before Foundation, but it is optional and is not part of
Foundation's dependency contract. A consumer may use Foundation without
PaperMod when it supplies the rest of its own site templates.

The same rule governs Hugo Modules: `module.imports` and `module.mounts` place
directories into the same ordered lookup, so module order equals theme order.

The consumer fixture enforces the documented order and renders Foundation
components with fixture-local skins. Consumers should keep this check when
changing their theme chain; reversing Foundation and its fallback can shadow
Foundation templates.

**The Foundation now ships page templates**, at `layouts/article/`,
`layouts/page/` and `layouts/note/`. The corrected order is what makes them
visible, but it is not what keeps them safe: they are scoped to a `type:`, so
they render only the pages that opt in with one. A template at
`layouts/_default/` would shadow the base theme site-wide whatever the order
says — that distinction, order makes a template reachable and specificity keeps
it contained, is why the content types live where they do. See
`CONTENT-MODEL.md` §3.

### The home page has no scoped baseof (verified)

The home page is the one kind where a type-scoped baseof does not work, and it
is worth recording because the failure is misleading.

| Home shell lives at | Result |
|---|---|
| `layouts/_default/baseof.html` | works |
| `layouts/index.baseof.html` | **not found** |
| `layouts/home.baseof.html` | **not found** |
| `layouts/index.html` as a complete document | works |

Hugo resolves the home baseof **only** from `layouts/_default/baseof.html`.
With any other name it reports `found no layout file for "html" for kind home`
and renders nothing at all — no error, an empty site.

`_default/baseof.html` is the one path this repository may never ship
(`CONTENT-MODEL.md` §7), so the home is a standalone document at
`layouts/index.html`. Its head is shared with the article, page and note shells
through `partials/fn/document-head.html` rather than copied.

---

## 3. Naming contract

| Thing | Form | Example |
|---|---|---|
| Class | `fn-block__element--modifier` | `fn-hero__title`, `fn-banner--warning` |
| CSS custom property | `--fn-*` | `--fn-hero-image` |
| JS/data hook | `data-fn-*` | `data-fn-gallery-dialog` |
| Partial path | `layouts/partials/fn/**` | `partials/fn/hero.html` |
| Shortcode name | no prefix (frozen, see §8) | `gallery` |

Rationale: a namespace that cannot collide with brand classes (`showcase-*` stays
on the brand side) or with the base theme's own classes (`.footer`, `.top-link`,
`#theme-toggle`). Foundation **must not** emit unprefixed generic class names.

This is what makes the migration in §9 cost real work: `showcase-*` and
`gallery-*` have to become `fn-*`. That is intentional — a shared namespace that
collides with the base theme's namespace does not survive a second consumer.

---

## 4. Strings / i18n contract

Foundation emits no locale-dependent literal text. All user-visible copy resolves
through a strings dict, first hit wins:

1. the `strings` dict passed to the component call,
2. `site.Params.foundation.strings`,
3. the Foundation's English defaults.

Foundation's defaults are part of the public contract. Consumers override them
wholesale; the defaults are never patched key-by-key inside the Foundation.

### Keys

`date`, `readMore`, `openPreview`, `closePreview`, `previewDialogLabel`,
`videoFallback`, `loadGame`, `mobileUnsupported`, `narrowViewportHint`,
`fullscreen`, `bannerDismiss`, `skipToContent`.

### Consumer configuration

```yaml
params:
  foundation:
    strings:
      date: "Date"
      readMore: "Read update"
      # ...
```

Per language, under `languages.<lang>.params.foundation.strings`.

Components must not branch on `site.Language.Lang` to choose a literal. If a
component needs language-dependent *structure* rather than text, that structure
is a parameter too.

---

## 5. Theming surface

Foundation's CSS expresses everything that may differ between brands through
`--fn-*` custom properties. It ships structural defaults — positioning,
stacking, minimum sizes, focus behaviour, reduced motion — and **no color values**
beyond neutral fallbacks on generic properties. Consumer brand styles supply
color, either in the site itself or in an optional reusable brand module.

Four override mechanisms, in increasing cost and decreasing portability:

1. **CSS custom properties** — preferred, no template edits, survives upgrades.
2. **Class-name skinning** in the brand stylesheet, targeting the documented
   class contract.
3. **Shadowing a Foundation partial** at the same path inside a consumer-owned
   brand module, when one exists.
   Contract-safe only if the brand partial honours the same output DOM contract
   in §7.
4. **Site-level override** in the site's own `layouts/`. Highest precedence, but
   site-specific: it is for exceptions, never for theming. Anything done here is
   invisible to the next consumer.

---

## 6. Accessibility contract

Every Foundation component guarantees:

- **Heading order.** One `h1` per page. Compositions take `level` and default to
  the correct value for their position in the document.
- **Landmarks.** The shell exposes a single `main`; side content uses `<aside>`;
  a live banner uses `role="status"`.
- **Images.** Content images get `alt`; decorative images get `alt=""`.
  Background imagery is delivered as a CSS custom property, never an `<img>`,
  so it needs no alt and stays out of the accessibility tree.
- **Names.** Every action has an accessible name sourced from the strings dict,
  never from a hardcoded literal.
- **Focus and motion.** `accessibility-base.css` guarantees a visible
  `:focus-visible` ring on Foundation's own hooks, plus a
  `prefers-reduced-motion` baseline.
- **No hover-only interaction.** Nothing is reachable only by hover.

---

## 7. Component contracts

Each component is a partial taking a single dict. It renders nothing when its
required input is missing, rather than emitting a broken shell.

### 7.1 `fn/hero.html`

Top-of-page identity block: background image, overline, title, lead, meta list.

| Param | Type | Default | Notes |
|---|---|---|---|
| `page` | Page | current page | Used **only** to fill in values the caller did not pass. Foundation does not read named front-matter keys. |
| `title` | string | — | Rendered as the heading at `level`. |
| `description` | string | — | Lead paragraph. |
| `overline` | string | — | Small label above the title. |
| `image` | string | — | URL or page-bundle resource name. |
| `imageAlt` | string | — | Advisory; the background is decorative. |
| `level` | int | `1` | Heading level. |
| `meta` | slice of `{term, value, datetime?}` | `nil` | Arbitrary meta. This replaces Foundation's hardcoded date. |
| `align` | `start`\|`center`\|`end` | `start` | |
| `class` | string | `""` | Appended, never replaces the `fn-` block class. |
| `strings` | dict | §4 | |

Output:

```html
<header class="fn-hero fn-hero--align-center" style="--fn-hero-image:url('…')">
  <div class="fn-hero__shade" aria-hidden="true"></div>
  <div class="fn-hero__content">
    <p class="fn-hero__overline">…</p>
    <h1 class="fn-hero__title">…</h1>
    <p class="fn-hero__lead">…</p>
    <dl class="fn-hero__meta">…</dl>
  </div>
</header>
```

Custom properties: `--fn-hero-image`, `--fn-hero-overlay`, `--fn-hero-min-height`,
`--fn-hero-content-width`, `--fn-hero-align`, `--fn-hero-overlay-strength`.

### 7.2 `fn/banner.html`

Full-width notice strip above or below content.

| Param | Type | Default |
|---|---|---|
| `text` | string \| `template.HTML` | — |
| `tone` | `info`\|`success`\|`warning`\|`critical` | `info` |
| `link` | `{url, label}` | `nil` |
| `dismissible` | bool | `false` |
| `role` | string | `nil` — see below |
| `class`, `strings` | | |

`role` is opt-in. A server-rendered banner is static content: making it a live
region would announce it on load for no reason. Pass `role: "status"` only when
the banner is injected dynamically after page load.

Output: `<div class="fn-banner fn-banner--info" role="status">` with an optional
`<button class="fn-banner__dismiss" aria-label="{strings.bannerDismiss}">`.

Custom properties: `--fn-banner-bg`, `--fn-banner-fg`, `--fn-banner-accent`,
`--fn-banner-padding`, `--fn-banner-radius`.

### 7.3 `fn/section-heading.html`

| Param | Type | Default |
|---|---|---|
| `id` | string | `nil` — placed on the heading, for in-page anchors |
| `kicker` | string | `nil` |
| `title` | string | — |
| `description` | string | `nil` |
| `link` | `{url, label}` | `nil` |
| `level` | int | `2` |
| `class` | string | `""` |

Output: `<div class="fn-section-heading">` containing the heading block and an
optional `a.fn-section-heading__link`.

Custom properties: `--fn-section-gap`, `--fn-kicker-color`, `--fn-kicker-size`.

### 7.4 `fn/card-grid.html` and `fn/card.html`

`fn/card-grid` takes `pages` (slice of `Page`) **or** `items` (slice of dicts),
plus `columns` (`auto`\|`1`–`6`, default `auto`), `gap`, `variant`,
`emptyPartial`, `card` (dict of defaults forwarded to each card), `class`,
`strings`.

`fn/card` takes `url`, `title`, `description`, `image`, `imageAlt`,
`meta` (slice of `{label, value, datetime?}`), `tags`, `headingLevel`
(default `3`), `variant`, `class`.

**Page → card mapping is a consumer concern.** Foundation's `fn/card` accepts
plain dicts; the consumer builds those dicts from its own front matter. The
Foundation ships `fn/page-to-card` as a shadowable helper that applies the
documented default mapping above, kept in a separate partial precisely so a
consumer can replace it without touching `fn/card` or `fn/card-grid`. It is a
convenience, not a contract; the mapping stays the consumer's choice.

Accessibility: a card is a single link wrapping the whole card, so its
`aria-label` comes from `strings.readMore` plus the title. The heading sits
inside the link, which keeps one focus stop per card while preserving heading
semantics.

Custom properties: `--fn-card-grid-columns`, `--fn-card-gap`, `--fn-card-radius`,
`--fn-card-media-aspect`, `--fn-card-bg`, `--fn-card-border`, `--fn-card-shadow`.

### 7.5 `fn/cta.html`

| Param | Type | Default |
|---|---|---|
| `title` | string | `nil` |
| `text` | string | `nil` |
| `actions` | slice of `{url, label, variant, external?}` | `nil` |
| `align` | `start`\|`center` | `center` |
| `level` | int | `2` |
| `id` | string | `nil` — for in-page anchors |
| `class` | string | `""` |

`variant` is `primary`\|`secondary`. Output is a `<section class="fn-cta">` with a
`ul.fn-cta__actions` list — a list, not a bare row of anchors, so the action set
is announced as a set.

Custom properties: `--fn-cta-bg`, `--fn-cta-fg`, `--fn-cta-pad`, `--fn-cta-gap`,
`--fn-cta-radius`.

### 7.6 `fn/media/gallery.html`

The composition behind the `gallery` shortcode.

| Param | Type | Default |
|---|---|---|
| `page` | Page | required — the page whose resources are matched |
| `folder` | string | required — matched as `<folder>/*` against the page bundle |
| `strings` | dict | resolved here if absent |

Output: `<div class="gallery-container">` holding one
`<a class="gallery-item gallery-item--portrait|landscape">` per matched image,
each wrapping `<div class="image"><img></div>`, and a single
`<dialog class="gallery-dialog">` per page with its script, guarded through
`page.Scratch` so a page with three galleries carries one dialog. A folder that
matches nothing still emits the container, empty.

Accessible names come from `strings.openPreview` (the link, suffixed with the
file name), `strings.closePreview` and `strings.previewDialogLabel`.

Orientation is `portrait` when the image is taller than it is wide, and the
resize follows: `420x640 q90` for portrait, `600x400 q90` for landscape, through
Hugo Extended's image pipeline.

The class names are the shortcode's, unchanged since this component was
inlined. The `fn-` names an earlier draft of this document used
(`.fn-gallery`, `.fn-gallery__item`, `.fn-gallery__dialog`) were never shipped,
and adopting them would have restyled a live site's galleries and repointed the
dialog JavaScript's hooks for no gain. `assets/css/shortcodes-base.css` styles
the names that exist.

Note that `folder` is a directory: the match is `<folder>/*`, so an image
sitting at the bundle root is not found. `fixtures/demo/content/shortcodes/gallery/`
keeps its image in `cover/`, and the fixture fails if that stops being true —
it did once, which is how the empty-container case was discovered.

### 7.7 `fn/media/video.html`

The composition behind the `video` shortcode.

| Param | Type | Default |
|---|---|---|
| `src` | string | — (required) |
| `type` | string | — (required) |
| `preload` | string | — (required) |
| `class` | string | `video-shortcode` |
| `strings` | dict | resolved here if absent |

Output: `<video class="video-shortcode" preload="…" controls>` with one
`<source>`. Fallback text comes from `strings.videoFallback`, so a browser
without codec support reads a localised sentence instead of two hardcoded
English lines.

### 7.8 `fn/page-shell.html`

The single place where page composition is decided.

| Param | Type | Default |
|---|---|---|
| `page` | Page | current page |
| `hero` | dict | `nil` — forwarded verbatim to `fn/hero` |
| `beforeContent`, `afterContent` | `template.HTML` | `nil` — slots |
| `aside` | `template.HTML` | `nil` |
| `contentClass`, `class`, `strings` | | |

Output: `<div class="fn-shell">`, an optional
`<header class="fn-shell__header">` when `hero` is set, then
`<main class="fn-shell__main" id="main">` and an optional
`<aside class="fn-shell__aside">`.

The Foundation may ship `layouts/_default/single.html` and `list.html` that
delegate here. A consumer may shadow those two files instead of calling the
partial — see the ordering constraint in §2.

### 7.9 `fn/list-shell.html`

The section-index composition, shared by all three content types. It resolves
the section's pages (falling back to the English translation's pages when a
translation has none of its own), paginates them, maps each through
`fn/page-to-card.html` and `fn/card.html`, and delegates the document to
`fn/page-shell.html`.

| Param | Type | Default |
|---|---|---|
| `page` | Page | required — the section |
| `prefix` | string | `fn-article-list` — the class prefix for this type |
| `strings` | dict | resolved here if absent |

Output: the page shell with `class="<prefix>"` and
`contentClass="<prefix>__main"`, a hero from the section's title, description
and `kicker`, then either `<div class="<prefix>__grid">` of cards or, when the
section has no pages, `<p class="<prefix>__empty">` with `strings.emptyList`.
Pagination is `<nav class="fn-pagination">` with a `__link` per direction, and
is omitted when the section fits on one page.

Prefixes in use: `fn-article-list`, `fn-note-list`, `fn-page-list`. The grid
and empty class are per-prefix; the card and pagination classes are shared.
Custom properties: `--fn-list-columns`, `--fn-list-columns-narrow`,
`--fn-card-gap`. `--fn-article-list-columns` and
`--fn-article-list-columns-narrow` remain as fallbacks for overrides written
before the property was shared.

Shipped prefixes: the article list predates this partial and its markup is
unchanged by it. The note and page lists are the same composition under their
own prefixes — before they existed, a section index carrying `type: note` or
`type: page` had no Foundation template and the base theme rendered it.

---

## 8. Shortcode stability

These names are frozen and will not be renamed: `gallery`, `video`,
`english-page-content`.

`unity-webgl-player` was one of them and no longer is. It was removed rather
than deprecated: the component is 40 lines of template plus 155 lines of CSS, it
carried three hardcoded English strings and the only accessible-name gap in the
repository, and no consumer wanted it. Removing it deleted the component, its
fixture, its styles and four dead `strings` keys rather than leaving a shim
that would have to be maintained forever. This is a breaking change and is
called out in `CHANGELOG.md` as one.

Changes are additive only. A new parameter must have a default that reproduces
today's output byte-for-byte, so that existing content keeps working without
edits. A rename requires a deprecation path shipped in the same release.

The shortcodes are **editor-facing syntax** over the same components. When a
composition has a natural content-author syntax, keep both: the partial is the
contract, the shortcode is the convenience.

That is now true for both media shortcodes. `gallery` and `video` delegate to
`fn/media/gallery.html` and `fn/media/video.html` (§7.6, §7.7), and a consumer
restyles one by shadowing the partial, not the shortcode. `english-page-content`
has no partial and none is planned — it is a one-liner over `hugo.Sites` and
the shortcode is the whole component.

---

## 9. Violations found while writing this contract

Found while writing this contract, as concrete items for the migration in issue
#20. Most of them lived in the *consumer* — `linzer0.github.io`, a different
repository — and were closed by the Foundation migration rather than by edits
here. The status column is what a reader needs; without it this table reads as
a live list of defects in a repository that is clean.

| # | Location | Violation | Rule | Status |
|---|---|---|---|---|
| 1 | consumer `layouts/partials/showcase/card-grid.html:34` | hardcoded `site.Language.Lang == "ru"` → `"Открыть обновление"` | R1, §4 | moot — `showcase/` deleted, replaced by `fn/*` adapters |
| 2 | consumer `showcase/hero.html:48` | hardcoded `ru` → `"Дата"` | R1, §4 | moot, as above |
| 3 | consumer `showcase/hero.html:49` | reads `site.Params.DateFormat`, a PaperMod parameter | R4 | moot, as above |
| 4 | consumer `showcase/card-grid.html:26` | implicit `$.page` caller-context dependency | R3 | moot, as above |
| 5 | consumer `showcase/card-grid.html:6,20,57-60` | assumes `cover.image` / `hero.image`, hardcodes a summary fallback | R3 | moot, as above |
| 6 | consumer `showcase/card-grid.html:8-19,35-46` | generated-preview art — brand presentation inside a "generic" grid | R2 | moot, as above |
| 7 | consumer `assets/css/accessibility-base.css:17-29,37-41` | hardcoded PaperMod selectors | R4 | fixed in Foundation `accessibility-base.css`, which now has none |
| 8 | consumer `accessibility-base.css:8,13` | `--site-*` namespace, site-flavoured | §3 | fixed — the Foundation uses `--fn-*`; the consumer loads the Foundation's file |
| 9 | `assets/css/shortcodes-base.css:94,99,107` | hardcoded site-root asset URLs | R4, §7.8 | fixed — 0 `/img/` in this repository, and the neutrality guard fails the build if one returns |
| 10 | consumer `shortcodes-base.css` | hardcoded colour literals instead of custom properties | §5 | fixed — the consumer loads the Foundation's `--fn-*` file |
| 11 | `layouts/shortcodes/gallery.html:8,19,24` | hardcoded English `aria-label`s, no `strings` parameter | §4 | **fixed** — labels resolve through `fn/strings.html`; output byte-identical, and the existing keys were already there unused |
| 12 | `layouts/shortcodes/unity-webgl-player.html:9,12,16` | hardcoded English labels | §4 | **removed** — the shortcode, its fixture and 155 lines of CSS are gone, and the four `strings` keys it needed went with it |
| 13 | consumer `hugo.yaml` | keep Foundation before any optional fallback theme | §2 | satisfied — the consumer lists `hugo-foundation` before `PaperMod` |

Items 11 and 12 were the reason a second consumer could not localise these
components. Both are closed: `gallery` reads its accessible names from
`fn/strings.html`, and the component that could not be localised is no longer
shipped. `video` was in the same position and is now wired too — its fallback
text was two hardcoded English lines while `strings.videoFallback` sat unused.

---

## 10. Anti-goals

The Foundation's **neutral layer** — `layouts/partials/fn/`, `assets/`,
`archetypes/`, and the type-scoped templates — does not, and will not:

- own or reference site content, page bundles, or private working material;
- contain brand assets, logos, or visual identity;
- hardcode `baseURL`, menus, author data, or analytics IDs;
- hardcode another theme's selectors or asset paths;
- emit locale-dependent literal text;
- name a base theme. The neutral layer must build with none, and must not
  change its output when one is added.

### 10a. The repository is both a theme and a site

This repository is used two ways, and the split between them is not cosmetic —
it is enforced by Hugo, not by discipline.

| Role | Where | Used by |
|---|---|---|
| **Theme** | `layouts/`, `assets/`, `archetypes/` at the repository root | Consumers, via `theme:` |
| **Site** | `site/` | This repository, via `hugo --source site` |

`themes/PaperMod` is a submodule and the optional base theme of `site/` only.

**Never move site material to the repository root.** Two mechanisms force
this, both verified against Hugo Extended 0.167.0:

1. A theme's own `hugo.yaml` is merged into every consuming build. A `theme:`
   key at the root made `linzer0.github.io` and the fixture look for PaperMod
   in their own tree.
2. A theme's `content/` is mounted into the consuming site. The starter
   articles at the root appeared in the fixture as uninvited `/about/`,
   `/articles/` and `/notes/` pages.

There is no way to opt out of either from the theme's side: one config governs
both roles, so an exclusion rule would empty the Foundation's own site too. The
only correct answer is the directory split above. See `docs/BASE-THEME.md`.

---

## 11. Verification

- `hugo --minify` in the consumer. CI is the authority for build success.
- `.github/workflows/ci.yml` builds the fixture and runs the neutrality guard
  on Hugo **Extended 0.167.0** on both `ubuntu-latest` and `windows-latest`. The
  version and the release checksums are pinned there, so a green run names the
  exact toolchain that produced it. See §13.
- `fixtures/build.ps1` (Windows) or `fixtures/build.sh` builds the fixture
  against every skin and asserts §12. Both pass `--panicOnWarning`: a Hugo
  deprecation notice fails the build instead of scrolling past.
- `fixtures/neutrality-check.ps1` (Windows) or `fixtures/neutrality-check.sh`
  scans `layouts/` and `assets/` for brand names, analytics IDs, locale
  branching, host asset paths and base-theme selectors.

  Findings split in two. **Hard** findings — brand, analytics, locale
  branching — must be zero. **Known** findings are real §9 violations still
  waiting on the migration, listed in a baseline inside the script. The baseline
  may shrink; it may not grow, and a known-class finding outside it fails.

  Current state: 0 hard, 0 known. The baseline still names
  `shortcodes-base.css` and `accessibility-base.css` as tripwires for the two
  classes §9 recorded there (items 7 and 9), but neither file contains a
  finding any more, so a regression in either is reported as new and fails.

If Hugo Extended is not available locally, say so explicitly. Do not claim the
build is green.

---

## 12. The fixture is the enforcement mechanism

`fixtures/` builds one minimal site against two skins and asserts the property
this document claims:

> The rendered body markup is **byte-identical** across skins. Only the
> `data-skin` marker and the `<link>` to the skin stylesheet may differ.

A skin changes a page by setting `--fn-*` custom properties and by targeting
the documented `fn-*` class contract — never by editing a template. If that
ever stops being true, the layering has leaked and the build fails.

The check is deliberately paranoid, because a check that cannot fail is worse
than no check:

- It asserts the two builds differ **before** normalisation. If they are
  byte-identical, the skin never switched and every other assertion would pass
  for the wrong reason.
- It verifies each `--config` override file exists before invoking Hugo. Hugo
  does **not** fail on a missing entry in `--config`; it silently builds with
  what it found.

> This was not hypothetical. An earlier version of the script interpolated a
> config path incorrectly, Hugo silently ignored the missing override, both
> builds produced skin A, and the comparison happily reported success while
> comparing a build with itself. The pre-normalisation guard and the file
> existence check exist because of that.

### 12.1 The DOM snapshot

The skin comparison above proves two builds of *today* agree. It cannot notice a
change that moves both builds together — a partial edited to emit one extra
attribute fails nothing, because both skins are wrong in the same way.

`fixtures/expected/` closes that hole. It holds the normalised DOM of every
rendered page, and both build scripts assert against it:

```bash
bash fixtures/build.sh          # compare
bash fixtures/build.sh --update # re-record, deliberately
```

Normalisation removes exactly what may change without the DOM changing: the skin
stylesheet link, the `data-skin` marker, asset fingerprints and their integrity
hashes, the Hugo version in the generator meta, and CRLF so a Windows checkout
and a Linux runner agree. Everything the Foundation emits is compared.

The check is designed to be impossible to pass vacuously:

- A page present in the snapshot but missing from the build **fails**. A page
  that stopped rendering is a regression, not a smaller fixture.
- A page missing from the snapshot **fails** until one is recorded, so a new page
  cannot slip in unasserted.
- Only `-Update` / `--update` writes the snapshot, and re-recording is a visible
  diff in review, not a silent reset.

This is what makes a refactor such as the relative-reference conversion in §1a
provable: the markup after the change is byte-identical to the markup before it,
and stays that way afterwards.

---

## 13. Supported Hugo version

| | |
|---|---|
| **Verified version** | Hugo **Extended 0.167.0** |
| **Minimum version** | **0.167.0.** Raised by the Foundation's own relative partial references, which resolve only from that version on. See §1a and §13.1 item 9. |
| **Edition** | Extended, never standard. `gallery` resizes page resources; the non-extended build fails late and confusingly. |
| **Pinned in** | `.github/workflows/ci.yml`, with release checksums |

The Foundation does not track "whatever Hugo is current". A shared View layer is
consumed by sites that build for months, so the version is an explicit promise:

- CI installs exactly the version above and asserts the `+extended` suffix.
- `--panicOnWarning` makes a deprecation a build failure, so a version bump that
  invalidates a template cannot pass quietly.
- Raising the minimum is allowed, and is a normal, recorded change. Lowering the
  promise below what CI pins is not.

### 13.1 Recorded changes, 0.146.0 → 0.167.0

Established by building the fixture **and** a multilingual stand that exercises
the shortcodes on both versions, then diffing the rendered output. Items
marked *consumer* change consumer behaviour and are verified in the consumer, not
here — this repository deliberately does not build them.

| # | Change | Where it lands | Status |
|---|---|---|---|
| 1 | `.Site.Sites` / `.Page.Sites` deprecated in 0.156.0, use `hugo.Sites` | `english-page-content.html` used the old form | **Fixed.** Output byte-identical on 0.167.0, and the new form still resolves on 0.146.0 — forward- and backward-compatible. |
| 2 | A page title containing `/` now produces a single URL segment instead of a nested one (0.166.0) | *consumer* — content URLs, not Foundation markup | Consumers with slashes in titles must re-check their URLs. |
| 3 | `languages.<lang>.languageName` deprecated in 0.158.0, use `label` | *consumer* config | Consumers must rename the key. |
| 4 | Org content is denied by default; opt back in via `security.allowContent` | *consumer* | Only affects sites with Org content. |
| 5 | `{{ return }}` outside a partial is now an error (was silently ignored) | Foundation | No occurrence; verified by a clean build. |
| 6 | `transform.ToMath` with `output: html` needs KaTeX ≥ 0.18.4 | *consumer* | The Foundation does no math rendering. |
| 7 | Alias pages no longer emit `<meta name="robots" content="noindex">` | *consumer* | Anything depending on that tag must be re-checked. |
| 8 | Image processing output differs, so fingerprinted asset URLs change | both | Benign, but a deploy is not byte-stable across a Hugo bump. Plan for new URLs. |
| 9 | Relative partial references (`{{ partial "./x.html" }}`) resolve from inside a partial | Foundation `fn/` internals | **Adopted.** The Foundation's own internal calls use them, which is what makes 0.167.0 the minimum. Public `fn/…` entry paths are unchanged. |

### 13.2 What this verification does not cover

The fixture exercises each shortcode at template level: `gallery` against a
real page bundle, `video` with stub params, `english-page-content` against a
page that exists, and the section landing is a regular page. A green fixture run
therefore asserts that the shortcode templates still parse, still link the
stylesheet, and still emit the markup the snapshot recorded.

`english-page-content` is the one whose snapshot does not say much. The fixture
is single-language, so the English site it resolves *is* the site, and the call
never crosses a language boundary. What is asserted is that the `hugo.Sites`
lookup, the `GetPage` path and the `.Content` emission still work — a deprecation
of `hugo.Sites` would fail it. What is not asserted is the branch that matters
most: a translation pulling the English page's body. That needs a bilingual
fixture, tracked as issue #6.

It does **not** assert visual fidelity. `gallery` rendering depends on the
image pipeline — portrait versus landscape, and the two resize targets — which a
multilingual stand cannot reproduce cheaply. That is the gap the gate cannot
bridge, and it is why the gallery fixture keeps a real image: without one the
shortcode matched nothing and the snapshot recorded an empty container that
looked like coverage.

Multilingual coverage for `english-page-content` follows in v0.3.0. Until
then, verify any change to `english-page-content.html` against a consumer that
runs more than one language.

The 13.1 shortcode findings were originally established from a stand built
outside this repository, so they were not reproducible from the fixture. The
template-level coverage closes that half; the visual half is tracked in
[#6](https://github.com/linzer0/hugo-foundation/issues/6).
