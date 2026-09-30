# Localization Contract

How text reaches a page in the Hugo Foundation, and who owns which string.

This refines `docs/CONTRACTS.md` §4. It is binding in the same way. Where the
two disagree, §4 wins and this document is wrong.

> **Status: complete for the components that render text.** The resolver and the
> key set below are stable and shipped, and every shortcode that emits visible
> text now reads from it: `gallery` for its three accessible names, `video` for
> its fallback. `english-page-content` renders a page's existing content and
> invents no strings. The fourth shortcode that used to emit hardcoded English is
> gone — see §6.

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
| `videoFallback` | `There should have been a video here but your browser does not seem to support it.` | video |
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

## 6. Closed: the shortcode gap

This section used to name a hard defect. `layouts/shortcodes/unity-webgl-player.html`
emitted four hardcoded English strings — the narrow-viewport warning, the mobile
warning, `start loading`, and an unlabelled fullscreen button — while the
resolver carried a key for each. A Russian consumer could not fix them without
forking the shortcode, which is the exact thing §1 exists to prevent.

Two changes closed it, and they closed it in opposite directions.

`gallery` and `video` are now wired. Both delegate to a partial that resolves
strings: the gallery's three `aria-label`s and the video's fallback text. The
video default lost a comma it never had — the fallback was two hardcoded English
lines, and the `videoFallback` key wrote the same sentence with one. The default
was corrected to match the shipped text, so the rendered sentence is unchanged
and the key is finally used.

`unity-webgl-player` is gone. It was 40 lines of template and 155 lines of CSS
for a component no consumer wanted, and its four strings could not be fixed
without deciding which wording was right — `start loading` against `Start
loading`, two different hints for the same warning. Removing it took the
component, its fixture, its styles and the four now-dead keys with it. That is
a breaking change and `CHANGELOG.md` says so.

What is left is honest about its limits: the fixture has no second language, so
it cannot prove that an override actually reaches the markup. The keys are
resolved, and a bilingual stand is still what would make this enforceable
rather than merely stated — see §7.

---

## 7. Verification

- `fixtures/neutrality-check.ps1` fails on any `site.Language.Lang` branching
  in `layouts/` or `assets/`. That is the automated half of this contract.
- The fixture covers `layouts/shortcodes/**` at template level, so a shortcode
  that stops parsing or stops rendering its markup fails the gate.
- What the fixture cannot do is add a second language and prove an override
  reaches the output. That is the missing piece, tracked as issue #6, and it is
  what would make this contract enforceable rather than merely stated.
