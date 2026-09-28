# Foundation Instructions

## Scope

- This repository provides the brand-agnostic Hugo foundation shared between Linar's sites (currently `linar.games`; future `linar.world`).
- It contains only generic shortcodes, supporting JS, and a neutral CSS baseline. No site identity, brand styling, authored content, or analytics IDs.
- Consuming sites wire this repository as a git submodule.

## Shortcodes

- `gallery` — page-bundle image gallery with lightbox dialog.
- `video` — generic HTML5 video embed.
- `unity-webgl-player` — Unity WebGL build loader with progress bar and fullscreen button.
- `english-page-content` — pulls the English version of a page into another language.

## Assets

- `assets/js/gallery-dialog.js` — lightbox behaviour for the gallery shortcode. Loaded once per page via `Page.Scratch`.
- `assets/css/shortcodes-base.css` — neutral styles for the shortcodes. Sites layer their own brand skin on top.
- `assets/css/accessibility-base.css` — focus ring and reduced-motion baseline. Sites add their own component selectors.

## Editing Rules

- Do not add Linar Games brand assets, site identity values, analytics IDs, or hard-coded URLs to this repo.
- Keep shortcode parameters generic. Avoid page-type-specific dependencies.
- Preserve shortcode names; downstream sites depend on them.

## Verification

- CI is the authority for build success across consuming sites.
- If Hugo Extended is not available locally, state that explicitly and do not claim the build is green.