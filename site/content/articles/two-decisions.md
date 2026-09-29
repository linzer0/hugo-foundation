---
title: "The two decisions you actually have to make"
date: 2026-09-29
description: "Which shell renders a page, and which base theme renders the rest. Everything else is a default you can change later."
type: "article"
---

The Foundation makes exactly two decisions on your behalf, and both are
reversible. Knowing what they are saves an afternoon.

## 1. Which document shell wraps your content

The Foundation's `article/baseof.html` is a complete, minimal document: head,
stylesheets, one `<main>`, no header, no menu, no footer. On its own it is a
perfectly good site and it needs nothing else to work.

If you are using a base theme, you have two options that are **not**
equivalent:

- **Keep the Foundation's shell.** Article pages get a clean minimal document;
  everything else keeps your base theme's chrome. Mixed, and fully contained —
  the Foundation cannot break pages it does not own.
- **Shadow `layouts/article/baseof.html`** in your own `layouts/` and build on
  your base theme's shell instead. Now articles match the rest of the site.

The Foundation does not pick for you. It has no way to know what your header
looks like, and guessing would put your brand in the neutral layer.

## 2. Whether there is a base theme at all

The optional base theme sits at the *end* of the chain. It fills in pages the
Foundation does not own, and it is where a menu, a dark-mode toggle, and a
footer come from. Removing it leaves a working site with fewer pages.

Set it once, in `hugo.yaml`:

```yaml
theme:
  - PaperMod
```

Everything on this site declares a `type:`, so the Foundation renders all of it
itself and the base theme is never consulted. That is the containment property
doing its job — and it also means the base theme is your call, not a
requirement.

## What is not a decision

Front matter keys are additive. An unread key is not an error; it is simply not
rendered. A typo in your own content model costs you a line of output, not a
build failure, and you can read your own keys in a shadowed shell without
filing anything upstream.
