---
title: "Unity WebGL smoke test"
description: "Exercises the unity-webgl-player shortcode with stub build params."
---

A real Unity WebGL build is not required for the template to render — the
partial emits the markup and the JS hooks. What the smoke test asserts is
that the partial still parses after a change to it.

{{< unity-webgl-player
  gameTitle="Smoke test"
  width=960
  height=540
  buildURL="/Build"
  buildFileName="SmokeTest"
  playerID="smoke-test"
>}}
