# Localization Contract

How text reaches a page in the Hugo Foundation, and who owns which string.

This refines `docs/CONTRACTS.md` §4. It is binding in the same way. Where the
two disagree, §4 wins and this document is wrong.

> **Status: partial.** The resolver and the key set below are stable and
> shipped. Three of the four shortcodes still emit hardcoded English and do
> not call the resolver. The gap is named in §6 rather than hidden, because a
> contract that quietly describes an unimplemented future is worse than one
> that admits what is missing.

---

## 1. Ownership

| Owns | Means | Does not own |
|---|---|---|
| **Foundation** | Interface chrome: labels of its own components, accessibility text, empty-state copy, format strings. | Editorial prose, page titles, section names, navigation, anything a human wrote. |
| **Consumer** | Everything a human wrote, plus the translation of Foundation's chrome into the consumer's languages. | The resolver, the key set, or the merge order. |

The line is not "Foundation text is English". The line is: **the Foundation
ships keys, the consumer ships meanings.**

A consumer localizing the Foundation is not forking templates. A consumer
adding a language is not proposing a new key. If you find yourself editing a
Foundation partial to change a word, the answer is in §3, not in the template.

---

## 2. There is one resolver

`layouts/partials/fn/strings.html` is the only mechanism.

There is deliberately **no** `i18n/en.yaml` / `i18n/ru.yaml` pair, no
`T()` function, no per-locale partial directory, and no adapter layer. A second
resolver would be a second source of truth, and two sources of truth drift
within one release. If a proposal needs one, it needs to replace this one
first.

The resolver returns a dict, merged in this order, later winning:

1. Foundation's English defaults,
2. `site.Params.foundation.strings`,
3. the `strings` dict passed into the component call.

```go-html-template
{{ $s := partial "fn/strings.html" . }}
{{ $s.readMore }}
```

---

## 3. Consumer configuration

Site-wide, per language, in `hugo.yaml`:

```yaml
languages:
  en:
    params:
      foundation:
        strings:
          readMore: "Read update"
  ru:
    params:
      foundation:
        strings:
          readMore: "Читать обновление"
```

Single-language consumers use the unscoped form, and that is a supported
configuration, not a degenerate one:

```yaml
params:
  foundation:
    strings:
      readMore: "Read more"
```

Per component, for one call only:

```go-html-template
{{ partial "fn/card.html" (dict "title" $p.Title "strings" (dict "readMore" "Читать")) }}
```

**Override semantics.** The merge is a deep merge over the defaults, so a
consumer overrides the two keys it cares about and inherits the other
twenty-two. Defaults are never patched key-by-key inside the Foundation, and
a consumer never has to restate the full set to change one string.

**Scope note.** `site.Params` is already language-scoped by Hugo. The
Foundation does not read `site.Language.Lang` to pick a literal — the language
comes from the params Hugo already resolved. Branching on the language is a
**hard** neutrality failure and the guard in
`fixtures/neutrality-check.ps1` fails the build on it.

---

## 4. The key set

Frozen. Removing or renaming a key is a breaking change; adding one requires
an English default that reproduces current output.

| Key | Default | Used by |
|---|---|---|
| `date` | `Date` | hero meta, article byline |
| `readMore` | `Read more` | card, list item |
| `openPreview` | `Open image preview` | gallery trigger |
| `closePreview` | `Close image preview` | gallery dialog close |
| `previewDialogLabel` | `Image preview` | gallery `<dialog>` label |
| `videoFallback` | `There should have been a video here, but your browser does not seem to support it.` | video |
| `loadGame` | `Start loading` | WebGL load button — **not wired yet**, §6 |
| `mobileUnsupported` | `This content is not supported on mobile devices.` | WebGL mobile warning — **not wired yet**, §6 |
| `narrowViewportHint` | `This content does not resize on smaller browser widths. Try the fullscreen button after loading.` | WebGL viewport warning — **not wired yet**, §6 |
| `fullscreen` | `Fullscreen` | WebGL fullscreen button — **not wired yet**, §6 |
| `bannerDismiss` | `Dismiss` | banner |
| `skipToContent` | `Skip to content` | page shell |
| `publishedOn` | `Published` | article meta |
| `updatedOn` | `Updated` | article meta |
| `readingTime` | `Reading time` | article meta |
| `readingTimeFormat` | `%d min read` | article meta, `printf`-style |
| `tocLabel` | `Table of contents` | article TOC |
| `tocTitle` | `On this page` | article TOC |
| `tagsLabel` | `Tags` | article meta |
| `paginationLabel` | `Pagination` | list pagination |
| `newer` / `older` | `Newer` / `Older` | list pagination |
| `emptyList` | `Nothing here yet.` | empty card grid |

`readingTimeFormat` is a **format string**, not a pluralisation site. A
language with more than two plural forms should precompute the word in the
component and pass `readingTime` directly, rather than trying to express the
plural rule inside a `%d` template.

---

## 5. What a bilingual consumer does

1. Copy the key set, translate the values, put them under
   `languages.<lang>.params.foundation.strings`.
2. Leave the default language in place. A missing key falls back to English
   per key, not per language, so a half-translated language degrades one string
   at a time instead of showing a blank page.
3. Do not add a language Foundation has never heard of. A new `languageCode` in
   the consumer's config is a consumer concern and needs nothing here.

A consumer that has no translation work at all ships no `params.foundation`
block. The Foundation is not bilingual by default and does not want to be.

---

## 6. Known gap: shortcodes still bypass the resolver

`layouts/shortcodes/unity-webgl-player.html` emits four hardcoded English
strings: the narrow-viewport warning, the mobile warning, `start loading`, and
the unlabelled fullscreen button. The resolver has carried keys for all four
since it was written; nothing calls it.

This is `docs/CONTRACTS.md` §9 items 11 and 12. It is a **hard** localization
defect, not a style preference: a Russian consumer currently cannot fix those
four strings without forking the shortcode, which is the exact thing §1 exists
to prevent.

Closing it is a behaviour change, so it gets its own change, not a drive-by:
the English defaults and the current literals differ in case
(`Start loading` vs `start loading`), and the shortcode names are frozen under
§8. The fix must ship the wiring, the fixture assertion, and a changelog entry
together.

Until then, treat the WebGL shortcode as **English-only**, and say so in any
consumer that uses it.

---

## 7. Verification

- `fixtures/neutrality-check.ps1` fails on any `site.Language.Lang` branching
  in `layouts/` or `assets/`. That is the automated half of this contract.
- The automated half is currently the *only* automated half. Nothing in the
  fixture asserts that a key is actually resolved, and `layouts/shortcodes/**`
  is not covered by the fixture gate at all — tracked as issue #6.
- A bilingual fixture (two languages, overrides in one, defaults in the other)
  is the missing piece, and it is what would make this contract enforceable
  rather than merely stated.
