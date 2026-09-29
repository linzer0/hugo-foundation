---
title: "{{ replace .File.ContentBaseName `-` ` ` | title }}"
date: {{ .Date }}
description: ""
type: "article"
draft: true
series: ""
tags: []
---

<!--
  Bundled article - use when the page owns its images.

  Created as a leaf bundle so the page resources sit next to the text:

    content/posts/my-article/index.md
    content/posts/my-article/cover.webp

  The `cover` field names a resource in this bundle; the hero picks it up as a
  background image.
-->
