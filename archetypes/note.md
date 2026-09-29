---
title: "{{ replace .File.ContentBaseName `-` ` ` | title }}"
date: {{ .Date }}
description: ""
type: "note"
draft: true
---

<!--
  Note - a short update, changelog entry or devlog note.

  Same optional fields as `article`, minus `series` and `toc`. Notes are meant
  to be short: what changed, why it matters, what it connects to next.
-->
