# Fixture

A minimal site that proves the Foundation is a reusable View layer: the same
markup, styled by independent skins.

It exists because "brand-agnostic" is a claim, and claims about architecture
rot unless something checks them. This fixture checks it.

## What it proves

Build it against every skin. The rendered body markup must be **byte-identical**
across builds. Only two things may differ: the `data-skin` marker and the
`<link>` to the skin stylesheet.

If a skin can change the page by editing a template, the layering has leaked
and the check fails.

## Running it

```bash
pwsh -File fixtures/build.ps1           # Windows
bash fixtures/build.sh                  # Linux / macOS / CI
```

Then open `fixtures/demo/public-skin-a/index.html` and
`fixtures/demo/public-skin-b/index.html` side by side.

- **skin A — "precision"** is dark, square-cornered, sans-serif, and lays the
  card grid out in multiple columns.
- **skin B — "editorial"** is light, warm, serif, heavily rounded, and collapses
  the same grid to a single ruled column.

They share nothing but the Foundation.

## Neutrality guard

```bash
pwsh -File fixtures/neutrality-check.ps1
bash fixtures/neutrality-check.sh
```

Scans `layouts/` and `assets/` in this repository for the things a shared
Foundation must not contain: brand names, analytics IDs, locale branching,
host asset paths, and base-theme selectors.

Findings are split in two. **Hard** findings — brand, analytics, locale
branching — must be zero, always. **Known** findings are real violations of
`docs/CONTRACTS.md` §9 that are still waiting on the migration; they are listed
in a baseline inside the script. The baseline may shrink. It may not grow, and
a known-class finding outside it fails the run.

Right now the baseline holds five lines: three `/img/` paths in
`shortcodes-base.css` and two PaperMod selectors in `accessibility-base.css`.

## Layout

```
demo/
  hugo.yaml             base config; skin A by default
  hugo.skin-b.yaml      override merged with --config hugo.yaml,hugo.skin-b.yaml
  content/              placeholder entries, no real content
  layouts/              site-owned composition: what the page is made of
  partials/
    home.html           the page composition, calling Foundation partials
    card-media.html     demo-owned artwork, passed through the card `media` slot
  skins/
    skin-a/assets/css/skin.css
    skin-b/assets/css/skin.css
```

`layouts/` is the **site** layer: it decides what the page contains. The
**Foundation** decides how each piece renders. The **skin** decides what it
looks like. Each layer only knows about the one below it.

## Wiring

The fixture sets `themesDir: "."` so it can reach two things at once: the skin
sitting beside the site, and the Foundation two directories up. A real consumer
uses a git submodule under `themes/` instead — `linzer0.github.io` does exactly
that. The fixture cannot use a submodule, so it points at the checkout.

The theme list is ordered most specific first, per `docs/CONTRACTS.md` §2:

```yaml
theme:
  - skins/skin-a
  - ../..
```

Swapping skins swaps the first entry only.

## Rules for changing this fixture

- The Foundation must never learn a skin's name.
- A skin must never need a template edit. If it does, the theming surface in
  `docs/CONTRACTS.md` §5 has a gap — fix the contract, not the fixture.
- `layouts/partials/card-media.html` is deliberately consumer-owned. It is the
  `media` slot in action: brand artwork with the Foundation staying out of it.
