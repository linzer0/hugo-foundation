# Foundation Development Guide

What to do when developing the Foundation itself, and how to do it without
breaking the consumers. Read `docs/CONTRACTS.md` and `docs/CONTENT-MODEL.md`
first — this guide assumes you already know the public API.

## Local toolchain

Hugo Extended **0.167.0** is the only supported version. It is pinned with
SHA256 checksums in `.github/workflows/ci.yml`. CI is the authority; a local
green on a different Hugo version is not a substitute.

```bash
# Verify
hugo version          # must end with +extended and match 0.167.0
```

Git is required for the submodule workflow. `gh` is required for releases
(`gh release create`) and for closing issues from the command line. If you
do not have `gh`, use the GitHub UI.

## Repository layout

```text
.
├── AGENTS.md               # binding rules for any agent on this repo
├── CHANGELOG.md            # semver, one section per release
├── README.md               # for consumers; what the repo IS
├── docs/
│   ├── CONTRACTS.md        # public API: layer resolution, components
│   ├── CONTENT-MODEL.md    # content types and their shells
│   ├── BASE-THEME.md       # the theme/site split and why
│   ├── DEV-LOG.md          # usage pattern for devlog entries
│   ├── DEV.md              # this file
│   └── LOCALIZATION.md     # the strings dict
├── archetypes/             # one .md per kind: default, article, note, page, devlog, bundle
├── layouts/
│   ├── _partials/fn/       # the components; one per file
│   ├── article/            # type-scoped shell for type: article
│   ├── note/               # type-scoped shell for type: note
│   ├── page/               # type-scoped shell for type: page
│   ├── shortcodes/         # gallery, video, unity-webgl-player, english-page-content
│   └── index.html          # the home; standalone document
├── assets/
│   ├── css/                # components-base, prose-base, shortcodes-base, accessibility-base
│   └── js/                 # fn-banner.js, gallery-dialog.js
├── site/                   # the Foundation's own demo site (NOT inherited by consumers)
├── themes/PaperMod/        # optional base theme for `site/` only (submodule)
└── fixtures/               # the gates; see below
```

## The gates

There are three local gates. CI runs all three on `ubuntu-latest` and
`windows-latest`. Run them yourself before pushing.

```powershell
powershell -File fixtures/build.ps1
powershell -File fixtures/neutrality-check.ps1
hugo --source site --config site/hugo.yaml,site/hugo.no-base-theme.yaml --destination public-ci-no-base
hugo --source site --config site/hugo.yaml,site/hugo.with-base-theme.yaml --destination public-ci-pm
```

On Linux / macOS the first two become `bash fixtures/build.sh` and
`bash fixtures/neutrality-check.sh`. The site builds work on every platform.

What each gate proves:

| Gate | What it proves |
|---|---|
| `fixtures/build.ps1` | The `fn/` View layer renders identically across two fixture skins; the rendered DOM matches `fixtures/expected/`. |
| `fixtures/neutrality-check.ps1` | `layouts/`, `assets/`, `archetypes/` contain no brand names, analytics IDs, host asset paths, PaperMod selectors, or non-ASCII literals. |
| `hugo --source site` (no-base) | Foundation produces a complete site with no base theme. |
| `hugo --source site` (with-base) | PaperMod is wired correctly and does not break Foundation rendering. |

A page deleted from `fixtures/demo/content/` must not survive as a stale file
in `fixtures/demo/public-*/`. `--cleanDestinationDir` handles that. Snapshots
in `fixtures/expected/` are the recorded truth.

## Add a new component

Components live in `layouts/partials/fn/`. One file per component, one
dict parameter, no implicit reads of front-matter.

1. Write `layouts/partials/fn/<name>.html`. Use relative `partial "./strings.html" .`
   for the strings dict and relative `partial "./<other>.html" .` for sibling components.
2. Document every accepted key in `docs/CONTRACTS.md` §7 (component table).
3. Add a fixture page under `fixtures/demo/content/` that uses the component with
   realistic params. The view across the two fixture skins must remain identical —
   that is what the gate proves.
4. Run `powershell -File fixtures/build.ps1`. If the rendered DOM changed in
   expected ways, run with `-Update` and read the diff before committing.
5. Run `powershell -File fixtures/neutrality-check.ps1`. New `fn-*` classes,
   `--fn-*` tokens, and `data-fn-*` hooks are namespaced; nothing else is.

## Add a new content type

Three things must move together: archetype, type-scoped shell, and
`docs/CONTENT-MODEL.md`. The rule is "scope to a `type:`, never `_default/`".

1. Write `archetypes/<type>.md` with the front matter you want `hugo new --kind <type>` to generate.
2. Write `layouts/<type>/single.html` (the page template) and `layouts/<type>/baseof.html`
   (the document shell). The shell uses `partial "fn/document-head.html" (dict "page" .)`
   for the head; do not duplicate the stylesheet list.
3. If `<type>` is a usage pattern of an existing type (`devlog` is a usage of
   `note`), document the convention in `docs/<TYPE>.md` and add a one-line entry
   to `docs/CONTENT-MODEL.md` near §2.
4. Add the type to `fixtures/demo/content/`, build the fixture, snapshot.
5. Update `AGENTS.md` "Content model" section with the new type.

## Update a shortcode

Shortcode names are frozen. New parameters default to today's output. The
fixture does **not** render every shortcode yet (see `docs/CONTRACTS.md` §13.2
and the linked issue for the gap); verify changes against a real consumer.

```bash
hugo server --source site
# open the page that uses the shortcode, exercise it manually
```

If the change moves markup, the consumer must opt in. A shortcode is a public
contract; breaking it is a major bump.

## Cut a release

```bash
# 1. Confirm gates green
powershell -File fixtures/build.ps1
powershell -File fixtures/neutrality-check.ps1
hugo --source site --config site/hugo.yaml,site/hugo.no-base-theme.yaml --destination public-check-no-base
hugo --source site --config site/hugo.yaml,site/hugo.with-base-theme.yaml --destination public-check-pm

# 2. Update CHANGELOG.md with a dated section in the Keep-a-Changelog shape.
#    Additive changes (new optional params, new components, new content types)
#    are minor. Breaking changes (renamed partial, renamed shortcode param,
#    template that widens which pages it renders) are major.

# 3. Commit, push, tag
git commit -am '...'
git push origin master
gh release create v0.x.y --generate-notes
```

Semver:

- **major** — broke a documented contract, removed/renamed anything public,
  or widened which pages a Foundation template renders.
- **minor** — additive only. New component, new optional param, new content
  type, new `fn/*` partial, new `--fn-*` token with a neutral fallback.
- **patch** — bug fixes that do not change rendered output for any consumer
  that did not already hit the bug.

`fixtures/expected/` is the recorded DOM; a snapshot that changes without an
entry in `CHANGELOG.md` is a regression.

## Submodules

`themes/PaperMod` is a submodule pinned to a specific commit for the
Foundation's own `site/`. Consumers never see it. When bumping it, do
**not** pull main:

```bash
# from the repo root
git submodule update --init --recursive
# bump only when needed
cd themes/PaperMod
git fetch
git checkout <pinned-commit>
cd ..
git add themes/PaperMod
git commit -m 'chore: bump PaperMod submodule to <short-sha>'
```

## What not to do

- Never add `layouts/_default/single.html` or `layouts/_default/baseof.html`.
  That template wins site-wide on every consumer and breaks every page.
- Never read a specific front-matter key inside a `fn/` component. Components
  take data as parameters.
- Never branch on `site.Language.Lang` to pick a literal. Use the strings
  dict.
- Never hardcode another theme's selector or asset path.
- Never commit a brand name, analytics ID, or host URL into the neutral
  layer; the neutrality guard will fail the build.
