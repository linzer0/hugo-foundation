---
title: "The Foundation is now a site"
date: 2026-09-29
description: "This repository is no longer only a theme. It builds."
type: "note"
---

Until now this repository was a theme with no site attached: everything you
could run lived under `fixtures/`, and the top level had no `hugo.yaml`.

It does now. Clone it and `hugo server` gives you a working article site with
no base theme configured, no brand, and no domain of mine in it.

Two things came with that. There is a third content type, `page`, for the
static pages every site needs and no article type was honest about. And the
base theme is genuinely optional rather than aspirational — the start-here
article says what that buys you.
