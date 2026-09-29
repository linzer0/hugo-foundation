---
title: "{{ replace .File.ContentBaseName `-` ` ` | title }}"
date: {{ .Date }}
description: ""
type: "note"
draft: true
tags:
  - devlog
changes:
  - added: ""
---

<!--
  Dev Log entry - a usage pattern of the `note` content type.

  This archetype exists so `hugo new --kind devlog ...` generates a note
  shaped for devlog use: dated, optionally carrying a `version`, always
  tagging itself as `devlog`, and pre-stamping a `changes` list to fill in.
  Rendered by the same template as any other note. The shape is a convention,
  not a new content type. See docs/DEV-LOG.md.
-->

What changed and why.
