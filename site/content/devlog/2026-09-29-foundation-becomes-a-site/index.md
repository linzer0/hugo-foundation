---
title: "Foundation is now a site as well as a theme"
date: 2026-09-29
description: "The repository split into a theme at the root and a starter site at site/."
type: "note"
tags:
  - devlog
  - foundation
changes:
  - added: "site/ — a runnable starter wired to the Foundation as its own theme."
  - added: "docs/BASE-THEME.md and docs/DEV-LOG.md."
  - changed: "Foundation ships three content types: article, note, page."
  - fixed: "note pages rendered nothing without a base theme."
---

The Foundation is no longer just a directory of partials you wire into your
own site. Clone it and `hugo server --source site` gives you a working
article site; add it as a submodule and you get the same View layer under
someone else's content.

The split is enforced by Hugo, not by discipline. A theme's `hugo.yaml` is
merged into every consuming build, and its `content/` is mounted into the
consuming site. The repository root holds only what a consumer should
inherit; site material lives in `site/`. See `docs/BASE-THEME.md` for the
verified mechanism.
