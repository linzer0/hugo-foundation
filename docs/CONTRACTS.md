# Foundation View Contracts

Public API of the Hugo Foundation. Implements step 1 of
[issue #20](https://github.com/linzer0/linzer0.github.io/issues/20): describe the
data, slots, parameters, accessibility guarantees and override points of every
layout and component the Foundation exposes.

A consumer is either the **brand theme** (`linar-games-theme`) or the **site**
(the repository that owns `hugo.yaml`, content and deployment). This document is
binding on the Foundation and on every consumer.

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

## 2. Layer resolution (verified)

Hugo resolves a template by walking, in order:

1. the project's `layouts/` directory,
2. then each theme directory **in the exact order listed under `theme:`**,
3. first match wins. Templates at the same path are **not** merged.

Verified empirically against Hugo Extended 0.146.0 with a two-theme fixture that
both define `layouts/_default/single.html`:

| Config | Result |
|---|---|
| `theme: [A, B]` | A wins |
| `theme: [B, A]` | B wins |
| project `layouts/` + `theme: [A, B]` | project wins |

### Required chain

Because the first declaration wins, the chain is declared **most specific
first**, not most general first:

```yaml
theme:
  - linar-games-theme   # brand layer
  - hugo-foundation     # neutral View layer
  - PaperMod            # base theme
```

The same rule governs Hugo Modules: `module.imports` and `module.mounts` place
directories into the same ordered lookup, so module order equals theme order.

> **Known defect — `hugo.yaml:4-6` in the consumer.** The site currently declares
> `theme: [PaperMod, hugo-foundation]`, which is inverted. It works today only
> because the Foundation ships no `layouts/` at all. The moment Foundation gains
> a `single.html` or any `_default/` template, PaperMod's copy shadows it. The
> order must be flipped in the same change that introduces Foundation layouts —
> not after, or the first Foundation layout silently never renders.

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
beyond neutral fallbacks on generic properties. The brand layer supplies color.

Four override mechanisms, in increasing cost and decreasing portability:

1. **CSS custom properties** — preferred, no template edits, survives upgrades.
2. **Class-name skinning** in the brand stylesheet, targeting the documented
   class contract.
3. **Shadowing a Foundation partial** at the same path inside the brand theme.
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

Promotes the gallery shortcode to a partial. Takes `items` (slice of
`{src, alt, caption?, href?}`) **or** the page-bundle shortcut `page` + `folder`,
plus `columns`, `lightbox`, `class`, `strings`.

Output: `.fn-gallery` with `.fn-gallery__item` children and a single
`<dialog class="fn-gallery__dialog">` per page, loaded once via `Page.Scratch`.
Accessible names come from `strings.openPreview` / `strings.closePreview` /
`strings.previewDialogLabel`.

Custom properties: `--fn-gallery-columns`, `--fn-gallery-gap`,
`--fn-gallery-radius`, `--fn-gallery-dialog-bg`.

### 7.7 `fn/media/video.html`

| Param | Type | Default |
|---|---|---|
| `src` | string | — (required) |
| `type` | string | `video/mp4` |
| `poster`, `preload`, `autoplay`, `muted`, `loop`, `controls` | | `controls` true |
| `caption` | string | `nil` |
| `class`, `strings` | | |

Fallback text comes from `strings.videoFallback`.

### 7.8 `fn/media/unity-webgl.html`

| Param | Type | Default |
|---|---|---|
| `buildURL` | string | — (required) |
| `buildFileName` | string | — (required) |
| `playerID` | string | — (required, must be unique per page) |
| `width`, `height` | int | — (required) |
| `title` | string | `nil` |
| `progressImages` | `{empty, full}` | — (**required**) |
| `fullscreenImage` | string | `nil` |
| `class`, `strings` | | |

`progressImages` and `fullscreenImage` are required precisely because the
current Foundation CSS hardcodes `/img/progress-bar-empty-dark.png`,
`/img/progress-bar-full-dark.png` and `/img/fullscreen-button.png` — paths that
resolve against the consumer's site root and do not exist in this repository
(§9, item 9). The component must carry its own images.

All labels — load button, mobile warning, narrow-viewport hint, fullscreen
button — come from the strings dict.

### 7.9 `fn/page-shell.html`

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

---

## 8. Shortcode stability

These names are frozen and will not be renamed: `gallery`, `video`,
`unity-webgl-player`, `english-page-content`.

Changes are additive only. A new parameter must have a default that reproduces
today's output byte-for-byte, so that existing content keeps working without
edits. A rename requires a deprecation path shipped in the same release.

The shortcodes are **editor-facing syntax** over the same components. When a
composition has a natural content-author syntax, keep both: the partial is the
contract, the shortcode is the convenience.

---

## 9. Known violations in the current consumer

Found while writing this contract. Each is a concrete item for the migration in
issue #20, with the rule it breaks.

| # | Location | Violation | Rule |
|---|---|---|---|
| 1 | `layouts/partials/showcase/card-grid.html:34` | hardcoded `site.Language.Lang == "ru"` → `"Открыть обновление"` | R1, §4 |
| 2 | `layouts/partials/showcase/hero.html:48` | hardcoded `ru` → `"Дата"` | R1, §4 |
| 3 | `layouts/partials/showcase/hero.html:49` | reads `site.Params.DateFormat`, a PaperMod parameter | R4 |
| 4 | `layouts/partials/showcase/card-grid.html:26` | implicit `$.page` caller-context dependency | R3 |
| 5 | `layouts/partials/showcase/card-grid.html:6,20,57-60` | assumes `cover.image` / `hero.image` and hardcodes a summary fallback | R3 |
| 6 | `layouts/partials/showcase/card-grid.html:8-19,35-46` | procedural generated-preview art — brand presentation living inside a "generic" grid | R2 |
| 7 | `assets/css/accessibility-base.css:17-29,37-41` | hardcodes PaperMod selectors `.footer`, `#theme-toggle`, `.top-link` | R4 |
| 8 | `assets/css/accessibility-base.css:8,13` | `--site-*` variable namespace is site-flavored, not Foundation-flavored | §3 |
| 9 | `assets/css/shortcodes-base.css:94,99,107` | hardcoded site-root asset URLs that do not exist in this repository | R4, §7.8 |
| 10 | `assets/css/shortcodes-base.css:37,67,72,79,141,155` | hardcoded color literals instead of custom properties | §5 |
| 11 | `layouts/shortcodes/gallery.html:8,19,24` | hardcoded English `aria-label`s, no `strings` parameter | §4 |
| 12 | `layouts/shortcodes/unity-webgl-player.html:9,12,16` | hardcoded English labels | §4 |
| 13 | `hugo.yaml:4-6` | `theme:` order inverted against the required chain | §2 |

Items 1–5 and 11–12 are correctness problems: they are the reason a second
consumer cannot reuse these components today. Items 6–10 are boundary problems:
they mark where brand presentation has leaked into the neutral layer.

---

## 10. Anti-goals

The Foundation does not, and will not:

- own or reference site content, page bundles, or private working material;
- contain brand assets, logos, or visual identity;
- hardcode `baseURL`, menus, author data, or analytics IDs;
- hardcode another theme's selectors or asset paths;
- emit locale-dependent literal text;
- ship PaperMod. PaperMod stays a submodule at each consumer.

---

## 11. Verification

- `hugo --minify` in the consumer. CI is the authority for build success.
- `fixtures/build.ps1` (Windows) or `fixtures/build.sh` builds the fixture
  against every skin and asserts §12.
- `fixtures/neutrality-check.ps1` (Windows) or `fixtures/neutrality-check.sh`
  scans `layouts/` and `assets/` for brand names, analytics IDs, locale
  branching, host asset paths and base-theme selectors.

  Findings split in two. **Hard** findings — brand, analytics, locale
  branching — must be zero. **Known** findings are real §9 violations still
  waiting on the migration, listed in a baseline inside the script. The baseline
  may shrink; it may not grow, and a known-class finding outside it fails.

  Current state: 0 hard, 5 known (three `/img/` paths in `shortcodes-base.css`,
  two PaperMod selectors in `accessibility-base.css`).

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
