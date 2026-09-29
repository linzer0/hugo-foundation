---
title: "{{ replace .File.ContentBaseName `-` ` ` | title }}"
date: {{ .Date }}
description: ""
type: "page"
draft: true
---

<!--
  Page - a static page: about, contact, colophon, privacy.

  Rendered by the Foundation's `page` type template. Same optional fields as
  `article`, minus the long-form ones: no `toc`, no `readingTime`, no `series`.
  A page without a `date` renders no date row at all.

  Delete the `date` line if the page should never look dated.
-->

Say what the reader needs, at the top.
