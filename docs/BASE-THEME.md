# The Base Theme

What the optional base theme is, why it lives in this repository, and how to
turn it on, off, or replace it.

---

## 1. The two roles of this repository

| Role | Lives in | Used by |
|---|---|---|
| **Theme** | `layouts/`, `assets/`, `archetypes/` at the repository root | Consumers, through `theme:` |
| **Site** | `site/` | This repository, through `hugo --source site` |

```bash
hugo server --source site                    # the site, Foundation only
hugo server --source site \
  --config hugo.yaml,hugo.with-base-theme.yaml   # the site, plus PaperMod
```

`themes/PaperMod` is a submodule at the repository root. It belongs to the
**site** role only. A consumer who adds Foundation as a theme never gets it
unless they put it in their own `theme:` list.

---

## 2. Why the site is in `site/` and not at the root

This is not tidiness. It is Hugo, and both mechanisms were verified against
Hugo Extended 0.167.0 by building the fixture and watching it break.

**A theme's `hugo.yaml` is merged into every consuming build.** With
`theme: [PaperMod]` at the repository root, `linzer0.github.io` and the fixture
both tried to resolve PaperMod from their own tree and failed with
`module "PaperMod" not found`. Every other root key leaks the same way —
`disableKinds`, `pagination.pagerSize`, `outputs` — quietly, and each one is a
setting a consumer chose for themselves.

**A theme's `content/` is mounted into the consuming site.** The starter
articles at the root appeared in the fixture as uninvited `/about/`,
`/articles/` and `/notes/` pages. On `linzer0.games` that would have collided
with real content.

There is no opt-out. One config file governs both roles, so a mount exclusion
intended for the consumer would also empty the Foundation's own site. The
directory split is the only correct answer, and it is the reason
`docs/CONTRACTS.md` §10a exists.

---

## 3. What the base theme actually does

Measured, not assumed. The same content built both ways:

| Build | Pages | Difference |
|---|---|---|
| `hugo.yaml` | 9 | — |
| `+ hugo.with-base-theme.yaml` | 10 | `404.html` |

One page. Every starter page declares a Foundation `type:`, so the Foundation
renders all of them and the base theme is never consulted. PaperMod's
contribution here is its 404, and nothing else.

That is the intended shape: a starter that needs a base theme is not a
foundation. Turn the base theme on when you add a page that wants PaperMod's
header, menu and footer, and expect it to stay invisible until you do.

---

## 4. Config paths are relative to `--source`

```bash
# works
hugo --source site --config hugo.yaml,hugo.with-base-theme.yaml

# silently produces an empty site
hugo --source site --config site/hugo.yaml,site/hugo.with-base-theme.yaml
```

The second form cannot find either file. Hugo falls back to built-in defaults,
which drops the theme list and `themesDir` along with it, and then reports
`found no layout file` for every kind. It reads as a template problem. It is a
path problem, and the fastest way to recognise it is that the Foundation
templates disappear too.

---

## 5. Using a different base theme

The chain is an ordinary Hugo `theme:` list, ordered most specific first
(`docs/CONTRACTS.md` §2):

```yaml
themesDir: "."
theme:
  - ..          # the Foundation, always first
  - <yours>     # your base theme, resolved from themesDir
```

The Foundation is first so its templates win at any path both define. Your base
theme fills in everything the Foundation does not own.

**Two rules for your own templates:**

- Never write `layouts/_default/single.html` or `layouts/_default/baseof.html`.
  They shadow the base theme site-wide and fail silently
  (`docs/CONTENT-MODEL.md` §7).
- Never add site content or a site config at the repository root of the
  Foundation. §2 above, again.

---

## 6. What the Foundation needs from a base theme

Nothing. That is the point, and it is what the two builds above demonstrate.

If you do enable one, it may need configuration of its own. PaperMod's RSS
template reads `params.author.name` and `params.author.email`, and without them
the build fails on `site.Author` — a field that no longer exists in current
Hugo. `site/hugo.yaml` carries a placeholder for exactly this reason.

---

## 7. A note on PaperMod deprecations

Building with PaperMod emits two warnings from PaperMod's own templates:

```
.Language.LanguageDirection was deprecated in Hugo v0.158.0
.Language.LanguageCode was deprecated in Hugo v0.158.0
```

They come from the theme, not from the Foundation, and disappear when PaperMod
is updated upstream. They are the reason the site build does **not** pass
`--panicOnWarning`, which the fixture does.
