---
title: "Gallery smoke test"
description: "Exercises the gallery shortcode against a single page resource."
---

A page bundle with one image. The `gallery` shortcode matches it through
`.Page.Resources.Match` and resizes it through Hugo Extended's image pipeline.

{{< gallery folder="cover" >}}
