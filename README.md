# Hugo Foundation

Neutral, reusable Hugo foundation shared between Linar's sites (`linar.games` and the future `linar.world`).

This repository provides:

- **View components** — `page-shell`, `hero`, `banner`, `section-heading`,
  `card-grid` / `card`, `cta`, in `layouts/partials/fn/`.
- **Shortcodes** — `gallery`, `video`, `unity-webgl-player`, `english-page-content`.
- **JS** — `gallery-dialog.js` for lightbox behaviour, `fn-banner.js` for dismissal.
- **CSS baseline** — `components-base.css`, `shortcodes-base.css` and
  `accessibility-base.css`. Structural only. Brand-agnostic. Sites layer their
  own styles on top.

It does not include:

- Site identity values (base URL, menus, author data, analytics IDs).
- Authored content, page bundles, or private working material.
- Brand styling, logos, or visual identity assets.
- A complete site shell or required fallback theme. Each consumer chooses its
  own shell and optional fallback theme.

`docs/CONTRACTS.md` is the binding public API. Read it before changing anything.

## The shape of the layer

Foundation emits **structure**: semantic markup, a stable `fn-*` class contract,
and CSS custom properties. It never decides what a page looks like.

Everything a consumer can vary is either a parameter or a `--fn-*` custom
property:

- **Data** arrives as parameters. No component reads a specific front-matter key.
- **Look** arrives as custom properties. No colour is chosen in this repository.
- **Copy** arrives through the strings dict, so no component branches on
  `site.Language.Lang` to pick a literal.

## Consuming the foundation

Add this repository as a git submodule of your site:

```bash
git submodule add git@github.com:linzer0/hugo-foundation.git themes/hugo-foundation
```

Then wire Foundation into `hugo.yaml`. Site-level `layouts/` always take
precedence. When using PaperMod as a fallback, put Foundation first so its
components take precedence over matching PaperMod templates:

```yaml
theme:
  - hugo-foundation  # neutral View layer
  - PaperMod         # optional fallback theme
```

Order is not cosmetic. Hugo resolves the project's `layouts/` first, then each
theme in the exact order listed; first match wins and same-path templates are
not merged. A consumer with a reusable brand module may place that optional
module before Foundation. A single-site brand layer can stay in the consumer's
own CSS and partials; Foundation does not require a separate brand module. See
`docs/CONTRACTS.md` §2.

Then include the Foundation's CSS from your head partial:

```go
{{ $components := resources.Get "css/components-base.css" | minify | fingerprint }}
<link rel="stylesheet" href="{{ $components.RelPermalink }}" integrity="{{ $components.Data.Integrity }}">
```

Override or layer brand-specific styles in the consumer site's CSS and layouts.

## The fixture

`fixtures/` is a minimal consumer built against two fixture-local skins. It
depends on Foundation only; neither skin is a required external theme. It asserts
that the rendered body markup is byte-identical across both — proof that one
View layer is genuinely reusable and not secretly brand-specific.

```bash
pwsh -File fixtures/build.ps1   # Windows
bash fixtures/build.sh          # Linux / macOS / CI
```

See `fixtures/README.md`.

## Editing rules

- Do not add brand assets, site identity values, analytics IDs, or hard-coded host URLs here.
- Keep parameters generic. Avoid page-type-specific dependencies.
- Namespace everything `fn-` / `--fn-*` / `data-fn-*`.
- Existing shortcode names are frozen; new parameters must default to today's output.
- CI is the authority for build success across consuming sites.
