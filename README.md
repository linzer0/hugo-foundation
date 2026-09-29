# Hugo Foundation

Neutral, reusable Hugo foundation shared between Linar's sites (`linar.games` and the future `linar.world`).

This repository is **both a theme and a working site**. Clone it and you have
an article site that runs; add it as a submodule and you have the same View
layer underneath someone else's content.

| Role | Lives in |
|---|---|
| Theme — what a consumer inherits | `layouts/`, `assets/`, `archetypes/` |
| Site — this repository's own | `site/` |

```bash
hugo server --source site
```

The split is enforced by Hugo rather than by discipline: a theme's `hugo.yaml`
is merged into every consuming build, and its `content/` is mounted into the
consuming site. Keep site material out of the root or every consumer inherits
it. See `docs/BASE-THEME.md`.

This repository provides:

- **Content model** — `archetypes/` and the `article` / `note` / `page` content
  types: what an article is, which front matter it takes, and where it is laid
  out. See `docs/CONTENT-MODEL.md`.
- **View components** — `page-shell`, `hero`, `banner`, `section-heading`,
  `card-grid` / `card`, `cta`, `article-shell` / `article-content`, in
  `layouts/partials/fn/`.
- **Page templates** — `layouts/article/`, `layouts/page/`, `layouts/note/`, and
  a standalone `layouts/index.html` for the home. Type-scoped, so they render
  only the pages that opt in with `type:` and never shadow a base theme.
- **Shortcodes** — `gallery`, `video`, `unity-webgl-player`, `english-page-content`.
- **JS** — `gallery-dialog.js` for lightbox behaviour, `fn-banner.js` for dismissal.
- **CSS baseline** — `components-base.css`, `prose-base.css`,
  `shortcodes-base.css` and `accessibility-base.css`. Structural only.
  Brand-agnostic. Sites layer their own styles on top.
- **An optional base theme** — `themes/PaperMod` as a submodule, used by `site/`
  only. Off by default; see `docs/BASE-THEME.md`.

It does not include:

- Site identity values (base URL, menus, author data, analytics IDs).
- Brand styling, logos, or visual identity assets.
- A base theme in the chain a consumer receives.
- Any required brand theme. See `docs/CONTRACTS.md` §2.

`docs/CONTRACTS.md` and `docs/CONTENT-MODEL.md` are the binding public API.
Read them before changing anything. `CHANGELOG.md` records what a consumer has to
react to when they upgrade.

**Toolchain:** Hugo **Extended 0.167.0**, pinned with checksums in
`.github/workflows/ci.yml`. See `docs/CONTRACTS.md` §13.

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
  - hugo-foundation  # neutral View + content-model layer
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

## Your first article

Once the submodule is wired, a dated, structured article needs no template of
your own:

```bash
hugo new --kind bundle posts/my-first-article/index.md
```

Put a cover image next to `index.md` if you want one. The archetype sets
`type: article`, and Hugo resolves that to the Foundation's own
`layouts/article/single.html` and `article/baseof.html`.

Pages that do not set `type:` are untouched by all of this and keep your base
theme's templates — which is the property that makes it safe to adopt alongside
an existing site rather than only in a greenfield one.

To restyle without forking, set the `--fn-*` properties; to change what a page
is made of, shadow `layouts/partials/fn/article-shell.html` in your own
`layouts/`. Both are covered in `docs/CONTENT-MODEL.md`.

## Where things go

The Foundation ships three content types. Each one is opt-in per page and the
archetype sets `type:` for you:

| You want | Command | Where it lands | Front matter |
|---|---|---|---|
| Long-form article | `hugo new --kind bundle posts/my-article/index.md` | `posts/<slug>/index.md` (page bundle, cover next to it) | `type: article`, `date`, `description`, `tags`, `toc` |
| Short note | `hugo new --kind note notes/my-update.md` | `notes/<slug>.md` | `type: note`, `date`, `description`, `tags` |
| Static page (about, contact) | `hugo new --kind page about.md` | `about.md` | `type: page`, `description` |
| Dev Log entry | `hugo new --kind devlog content/devlog/2026-09-29-slug/index.md` | `devlog/<date-slug>/index.md` (page bundle) | `type: note` + `version`, `changes`, `tags: [devlog, …]` |

`public/` is never committed — it is the build output and is regenerated by
`hugo`. The Foundation's own `public*` artifacts live under `fixtures/demo/`
and are gitignored. See `.gitignore`.

Dev Log is a usage pattern of `type: note`, not a new content type. The
archetype pre-fills the front matter and `docs/DEV-LOG.md` documents the
convention.

## Upgrading

Pin a tag, move the pointer, run the gates. `CHANGELOG.md` lists what counts as
a breaking change, including the one that matters most here: a Foundation
template that widens which pages it renders.

## The fixture

`fixtures/` is a minimal consumer built against two fixture-local skins. It
depends on Foundation only; neither skin is a required external theme. It asserts
that the rendered body markup is byte-identical across both — proof that one
View layer is genuinely reusable and not secretly brand-specific.

```bash
powershell -File fixtures/build.ps1   # Windows; `pwsh -File` works too
bash fixtures/build.sh                # Linux / macOS / CI
```

Both shells run the same `.ps1` on Windows. `powershell` is Windows PowerShell
5.1 and ships with Windows; `pwsh` is PowerShell 7 and is not installed by
default, so prefer `powershell` unless you know you have it.

CI runs both scripts, plus the neutrality guard, on Linux and Windows against the
pinned Hugo. See `fixtures/README.md`.

## Editing rules

- Do not add brand assets, site identity values, analytics IDs, or hard-coded host URLs here.
- Keep parameters generic. Avoid page-type-specific dependencies.
- Namespace everything `fn-` / `--fn-*` / `data-fn-*`.
- Existing shortcode names are frozen; new parameters must default to today's output.
- CI is the authority for build success across consuming sites.
