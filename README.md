# Hugo Foundation

Neutral, reusable Hugo foundation shared between Linar's sites (`linar.games` and the future `linar.world`).

This repository provides:

- **Shortcodes** — `gallery`, `video`, `unity-webgl-player`, `english-page-content`.
- **JS** — `gallery-dialog.js` for lightbox behaviour.
- **CSS baseline** — `shortcodes-base.css` and `accessibility-base.css`. Brand-agnostic. Sites layer their own styles on top.

It does not include:

- Site identity values (base URL, menus, author data, analytics IDs).
- Authored content, page bundles, or private working material.
- Brand styling, logos, or visual identity assets.
- Theme code (PaperMod stays a submodule at each consumer site).

## Consuming the foundation

Add this repository as a git submodule of your site, for example:

```bash
git submodule add [email protected]:linzer0/hugo-foundation.git themes/hugo-foundation
```

Then include the foundation as one of the themes so its shortcodes and assets are picked up:

```yaml
# hugo.yaml
theme:
  - PaperMod
  - hugo-foundation
```

The foundation sits under `themes/hugo-foundation/` in the consuming site. Hugo searches theme paths after the project-level `layouts/`, so sites can still override foundation templates locally.

## CSS baseline

Reference the foundation's CSS files from your site's head partial, for example:

```go
{{ $shortcodes := resources.Get "css/shortcodes-base.css" }}
<link rel="stylesheet" href="{{ $shortcodes.RelPermalink }}">
```

Override or layer brand-specific styles in your own site CSS.