---
title: "Start here"
date: 2026-09-29
description: "What this repository is, what it refuses to be, and what you get when you clone it."
type: "article"
tags: ["foundation", "hugo"]
toc: true
---

Clone it, `hugo server`, and you have a working article site. That is the
whole pitch. Everything below is why it works that way.

## Three layers, three owners

| Layer | Lives in | Owns |
|---|---|---|
| Content model | `archetypes/`, `docs/CONTENT-MODEL.md` | What an article *is* |
| View | `layouts/partials/fn/`, `assets/` | How a piece *renders* |
| Composition | `layouts/article/`, `layouts/page/`, `layouts/note/` | What a page is *made of* |

A consumer adds a fourth layer on top — their brand, their templates. They
never edit the first three in place; they shadow them, so upgrading stays a
submodule pointer move.

The line that matters is View against Composition. A **component** renders one
thing and knows nothing about the page around it. A **composition** decides
what the page contains and in what order. Keeping them apart is what makes a
new content type a twenty-line change instead of a fork.

## A page opts in

```yaml
type: article
```

That is the entire opt-in. A page without `type` is never rendered by the
Foundation — it keeps whatever its base theme gives it. This is the containment
property, and it is why the Foundation can ship page templates at all.

## Write one

```bash
hugo new --kind article my-post.md
```

The archetype fills in the front matter. Add a `description` — it becomes the
lead paragraph and the meta description, and it is what makes a card readable
in a listing before the reader opens the page.

## Restyle without forking

Everything visual is a `--fn-*` custom property. Set the ones you care about
in your own stylesheet; the markup never changes.

```css
:root {
  --fn-prose-measure: 68ch;
  --fn-card-radius: 4px;
}
```

If you want to change what a page is *made of* rather than how it looks, shadow
the composition in your own `layouts/` instead. Reach for that second, not the
first, when the change is structural.

## What it will not do

It does not carry a brand, a domain, a menu, an author, or an analytics ID. It
does not decide your URLs. It does not branch on a language to pick a literal
— that is what the strings dictionary is for. A `fixtures/neutrality-check`
script fails the build if any of that starts happening.
