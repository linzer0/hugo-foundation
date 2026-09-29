---
title: "{{ replace .File.ContentBaseName `-` ` ` | title }}"
date: {{ .Date }}
description: ""
type: "page"
draft: true
---

<!--
  Page - a static page: about, contact, colophon, privacy.

  Rendered by the Foundation's `page` type template. It reuses the article
  shell, so the same optional fields apply as for `article` — see
  docs/CONTENT-MODEL.md §7. Nothing is switched off by the type itself:

  - Reading time is shown by default, as on every type. Add
    `readingTime: false` to drop the row.
  - A table of contents is off by default, as on every type. Add `toc: true`
    to get one.

  A page without a `date` renders no date row at all.

  Delete the `date` line if the page should never look dated.
-->

Say what the reader needs, at the top.
