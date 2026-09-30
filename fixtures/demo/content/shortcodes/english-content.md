---
title: "English content smoke test"
description: "Exercises the english-page-content shortcode against a page in the same language."
---

{{< english-page-content page="/work/alpha/" >}}

The shortcode resolves the English site's page at that path and emits its
rendered content. On a single-language fixture the English site is this site, so
the call is a real one rather than a no-op: the snapshot below is the body of
`/work/alpha/`, and the shortcode's own text is this sentence.
