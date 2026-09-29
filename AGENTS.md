# Foundation Instructions

## Scope

- This repository is both a theme and a working site. The theme (layouts, assets, archetypes, neutral CSS, JS) is what consumers inherit. The site (`site/`) is a runnable starter wired to that theme, used as the Foundation's own demo and as a CI gate. See `docs/BASE-THEME.md`.
- A theme's `hugo.yaml` is merged into every consuming build, and its `content/` is mounted into the consuming site — both verified against Hugo Extended 0.167.0. There is no opt-out. Site material therefore lives in `site/`, never at the repository root.
- `themes/PaperMod` is a submodule and the optional base theme of `site/` only. Consumers who add Foundation as a theme never get PaperMod unless they put it in their own `theme:` list.
- This repository contains no site identity values, brand styling, or analytics IDs.

## Contracts

- `docs/CONTRACTS.md` is the binding public API: layer resolution, naming, strings/i18n, theming surface, accessibility, per-component parameter tables, and override points.
- Read it before adding or changing any component. A change that breaks a documented contract is a breaking change.

## Rules

- Namespace everything: `fn-` classes, `--fn-*` custom properties, `data-fn-*` hooks, `layouts/partials/fn/**` paths. Never emit unprefixed generic class names.
- Take every user-visible value as a parameter. Do not read specific front-matter keys and do not depend on the caller's implicit context.
- No locale-dependent literal text. All copy resolves through the strings dict (component param → `site.Params.foundation.strings` → English defaults).
- Never hardcode another theme's selectors or asset paths, including PaperMod's classes and site-root `/img/` URLs. Carry required images as parameters.
- Brand theme overrides via `--fn-*` custom properties first; template shadowing is a last resort.
- Existing shortcode names are frozen and changes are additive only: a new parameter's default must reproduce today's output.

## Consumer ordering

- Consumers must declare the chain most specific first:
  `hugo-foundation` → `PaperMod`, with an optional brand theme above the
  Foundation. No private brand theme is required to consume this repository.
- Hugo resolves the project `layouts/` first, then each theme in `theme:` order, first match wins, and same-path templates are not merged. Getting this order wrong silently shadows Foundation layouts — see `docs/CONTRACTS.md` §2.

## View components

Partials in `layouts/partials/fn/`. Each takes a single dict and is documented in `docs/CONTRACTS.md` §7.

- `page-shell` — page composition: skip link, hero, banner, `main`, aside, slots.
- `hero` — overline, title, lead, arbitrary meta list, background via custom property.
- `banner` — notice strip with optional dismissal.
- `section-heading` — kicker, title, description, trailing link.
- `card-grid` / `card` — content cards. `card` takes plain dicts; `page-to-card` is the shadowable Page→dict convenience mapping.
- `cta` — title, text, action list.
- `article-shell` / `article-content` — the composition shared by every content type. See `docs/CONTENT-MODEL.md` §3.
- `strings` — the i18n resolver every component above calls first.

## Content model

The layer that answers "what is an article", as opposed to "how does it render".
Binding contract: `docs/CONTENT-MODEL.md`.

- `archetypes/` — `default`, `article`, `note`, `page`, `devlog`, `bundle`. `devlog` is a usage pattern of `note`; see `docs/DEV-LOG.md`.
- `layouts/article/`, `layouts/note/`, `layouts/page/` — type-scoped page templates, each with its own `baseof.html`. Each renders only pages that opt in with the matching `type:`.

**Never add `layouts/_default/single.html` or `layouts/_default/baseof.html`.** A template at `_default/` is found before the base theme's copy and takes over every page on the consumer's site, not just the ones that asked for it. The build stays green; every page is wrong. Keep templates scoped to a `type:` — `docs/CONTENT-MODEL.md` §3 has the verified resolution table.

## Shortcodes

- `gallery` — page-bundle image gallery with lightbox dialog.
- `video` — generic HTML5 video embed.
- `unity-webgl-player` — Unity WebGL build loader with progress bar and fullscreen button.
- `english-page-content` — pulls the English version of a page into another language.

Shortcode names are frozen. New parameters must default to today's output.

## Assets

- `assets/js/gallery-dialog.js` — lightbox behaviour for the gallery shortcode. Loaded once per page via `Page.Scratch`.
- `assets/js/fn-banner.js` — banner dismissal, with opt-in session persistence keyed on banner `id`.
- `assets/css/components-base.css` — structural defaults for the `fn/` components. Positions, stacks and sizes. No brand colour: every colour-bearing property reads a `--fn-*` custom property.
- `assets/css/prose-base.css` — structural defaults for rendered Markdown inside `.fn-prose`. Separate from components-base.css because a site with no prose can skip it.
- `assets/css/shortcodes-base.css` — neutral styles for the shortcodes. Sites layer their own brand skin on top.
- `assets/css/accessibility-base.css` — focus ring and reduced-motion baseline. Sites add their own component selectors.

## Editing Rules

- Do not add Linar Games brand assets, site identity values, analytics IDs, or hard-coded URLs to this repo.
- Keep shortcode parameters generic. Avoid page-type-specific dependencies.
- Preserve shortcode names; downstream sites depend on them.

## Verification

- Supported toolchain is Hugo **Extended 0.167.0**, pinned with checksums in `.github/workflows/ci.yml`. Do not test against an arbitrary local Hugo and call it a pass. See `docs/CONTRACTS.md` §13.
- CI is the authority. It runs three gates on `ubuntu-latest` and `windows-latest`:
  1. `fixtures/build.ps1` — the View layer renders identically across two skins; the rendered DOM matches the committed snapshot.
  2. `fixtures/neutrality-check.ps1` — no brand names, analytics IDs, host asset paths, PaperMod selectors, or non-ASCII literals in `layouts/`, `assets/`, `archetypes/`.
  3. Site builds — `hugo --source site` builds with no base theme, and again with PaperMod. This is the gate that keeps the "optional base theme" claim honest; a Foundation that only built in its base-theme configuration would pass 1 and 2 while quietly requiring PaperMod for its own pages.
- Run all three locally before claiming a release. CI is the final word; a local green on a different Hugo version is not a substitute.
- The fixture covers the `fn/` partials only — it renders no shortcode. A change to `layouts/shortcodes/**` is not covered by the local gate; verify it against a consumer. See `docs/CONTRACTS.md` §13.2.
- If Hugo Extended is not available locally, state that explicitly and do not claim the build is green.
- Neutrality guard: `layouts/`, `assets/`, and `i18n/` must contain no brand names, analytics IDs, host asset paths (`/img/`), PaperMod selectors (`.top-link`, `#theme-toggle`, `.footer`), or non-ASCII literals. `docs/` and `fixtures/` are excluded. `site/` is the Foundation's own demo, not a consumer site, and is also excluded from the neutrality scan.