# Content Model

How an article is written and laid out. This document is binding on the
Foundation and on every consumer, in the same way `CONTRACTS.md` is binding on
the components.

`CONTRACTS.md` describes **how a piece renders**. This document describes **what
a piece of content is**. They are separate contracts because they change for
different reasons: a brand restyles without touching the content model, and a
new content type arrives without touching a single component.

---

## 1. The three layers

| Layer | Lives in | Answers | Owned by |
|---|---|---|---|
| **Content model** | `archetypes/`, this document | What is an article? | Foundation |
| **View** | `layouts/partials/fn/`, `assets/` | How does it render? | Foundation |
| **Composition** | `layouts/article/`, `layouts/note/` | What is the page made of? | Foundation, shadowable |

A consumer adds a fourth layer on top — brand styling, and site-specific
templates in its own `layouts/`. It never edits the first three in place; it
shadows them, so an upgrade stays a submodule bump.

The line between View and Composition is the one that matters. A **component**
renders one thing and knows nothing about the page around it. A **composition**
decides what the page contains and in what order. Keeping them apart is what
makes a new content type a twenty-line change instead of a fork.

---

## 2. Content types

The Foundation defines two types. Both are opt-in per page.

| Type | Template | For |
|---|---|---|
| `article` | `layouts/article/single.html` | Long-form, dated, structured writing |
| `note` | `layouts/note/single.html` | Short updates, changelog entries, devlog notes |

A page opts in with one front-matter key:

```yaml
type: article
```

**A page without `type` is not rendered by the Foundation.** It keeps whatever
the base theme or the consumer's own templates give it. This is the containment
property, and it is the reason the Foundation can ship page templates at all —
see §3.

---

## 3. Layer resolution for type-scoped templates

Hugo resolves a page template, and the `baseof` that wraps it, by walking:

1. the project's `layouts/`,
2. then each theme in `theme:` order,

taking the **most specific match first**, and never merging two templates at the
same path.

Verified against Hugo Extended 0.167.0, with a Foundation placed ahead of
PaperMod:

| Question | Answer |
|---|---|
| Page with `type: article` | Foundation's `article/single.html` + `article/baseof.html` |
| Page with no `type` | PaperMod's own template, untouched |
| Foundation shipping `_default/single.html` | **Every** page on the site, including unrelated ones |
| Project `layouts/` override | Wins over both |

The third row is the trap this design exists to avoid. A template at
`layouts/_default/single.html` is found before PaperMod's, so it would take over
every page — an about page, a contact page, anything — because it is *more
specific by position*, not by intent. The failure is silent: the site builds
green and every page is wrong.

Scoping to `layouts/article/` and `layouts/note/` makes the blast radius exactly
the set of pages that asked for it. `fixtures/build.ps1` enforces this: the demo
site's own pages still match their pre-existing DOM snapshots, so a regression
that widened the blast radius fails the build.

### The one thing a consumer must decide

Foundation's `article/baseof.html` is a complete, minimal document. A consumer
that has a base theme with its own chrome has two options, and they are not
equivalent:

- **Keep the Foundation's shell.** Article pages get Foundation's minimal
  document; everything else keeps the base theme's. Mixed chrome, fully
  contained.
- **Shadow `layouts/article/baseof.html`** in the consumer's own `layouts/` and
  build on its base theme instead. Then article pages match the rest of the site.

The Foundation does not pick. It has no way to know what a consumer's header
looks like, and guessing would put brand knowledge in the neutral layer.

---

## 4. Front matter

Read by `fn/article-shell.html` and `fn/article-content.html`. Every key is
optional except the three marked required. An unread key is not an error; it is
simply not rendered.

| Key | Type | Default | Effect |
|---|---|---|---|
| `type` | string | — | **Required** to get a Foundation template. `article` or `note`. |
| `title` | string | — | **Required.** The `h1`. |
| `date` | date | omitted | Ordering, and a `Published` meta item. Omit to hide it. |
| `description` | string | — | **Required in practice.** The hero lead. Also the meta description. |
| `cover` | string or `{image, alt}` | — | Hero background. A page-bundle resource name, never a host-root path. |
| `overline` | string | — | Small label above the title. `kicker` is accepted as an alias. |
| `tags` | list of strings | — | Rendered as chips below the content. |
| `updated` | date | — | Shown as `Updated` only when later than `date`. |
| `readingTime` | bool | `true` | `false` removes the reading-time meta item. |
| `toc` | bool | `false` | `true` renders a table of contents. |
| `banner` | dict | — | `{text, tone, link, dismissible}`, forwarded to `fn/banner.html`. |

Unknown keys are ignored. A consumer can add its own and read them in a
shadowed `fn/article-shell.html` without a Foundation change.

### Locale-dependent values

`date` is formatted with `dateFormat`, resolved in this order: the parameter
passed to `fn/article-shell.html`, then `site.Params.foundation.dateFormat`,
then Hugo's `:date_long`.

The last one is locale-aware, so a bilingual site renders correct dates per
language with nothing configured — English text in a Russian page would require
a hardcoded format, which is exactly what the Foundation does not do. A consumer
overrides it only when it wants a specific shape:

```yaml
params:
  foundation:
    dateFormat: "2 January 2006"
languages:
  ru:
    params:
      foundation:
        dateFormat: "2 January 2006"
```

The same setting drives card dates in a section listing, so a card and the
article it links to always agree.

### Table of contents depth

`toc: true` renders Hugo's own table of contents. Which heading levels appear is
Hugo's `markup.tableOfContents` site setting, not a Foundation parameter:

```yaml
markup:
  tableOfContents:
    startLevel: 2
    endLevel: 3
```

---

## 5. Archetypes

The Foundation ships archetypes so that a new site is productive before it has
written a line of template. Hugo resolves them from a theme when the site has
no archetype of its own, which is what makes this work.

| File | Used by |
|---|---|
| `archetypes/default.md` | `hugo new anything.md` |
| `archetypes/article.md` | `hugo new --kind article my-post.md` |
| `archetypes/note.md` | `hugo new --kind note my-update.md` |
| `archetypes/bundle.md` | `hugo new --kind bundle posts/my-post/index.md` |

Verified against Hugo Extended 0.167.0: a theme archetype is used when the
site has none, and a section archetype wins over the default one.

Prefer the leaf bundle whenever a page owns images — that is what makes
`cover: cover.webp` resolve to a page resource instead of a host-root URL:

```
content/posts/my-post/
  index.md
  cover.webp
```

A consumer's own `archetypes/` always wins over the Foundation's, so a site can
put its house style into every `hugo new` without a submodule fork.

---

## 6. The theming surface for content

Everything above is structure. Appearance arrives the same way it does for
components: through custom properties. `assets/css/prose-base.css` styles the
markup the Markdown renderer produces and reads only `--fn-*` properties.

| Property | Controls |
|---|---|
| `--fn-prose-measure` | Line length of the body copy |
| `--fn-prose-fg`, `--fn-prose-muted` | Body and secondary text |
| `--fn-prose-link` | Link colour |
| `--fn-prose-rule` | Borders, table cells |
| `--fn-prose-code-bg`, `--fn-prose-code-fg` | Inline and block code |
| `--fn-prose-h2`, `--fn-prose-h3`, `--fn-prose-h4` | Heading scale |
| `--fn-article-list-columns` | Cards per row in a section listing |
| `--fn-toc-*` | Table-of-contents block |
| `--fn-article__tag*` | Tag chips |

`prose-base.css` is loaded by `article/baseof.html` and is separate from
`components-base.css` on purpose: a site that publishes no prose can skip it.

---

## 7. Adding a content type

The whole extension point, in order:

1. Add `archetypes/<type>.md` with `type: <type>` set.
2. Add `layouts/<type>/baseof.html` — copy `article/baseof.html`.
3. Add `layouts/<type>/single.html` calling `fn/article-shell.html`.
4. Optionally add `layouts/<type>/list.html` for a section index.
5. Document the front matter in this file, and the markup in `CONTRACTS.md` §7.
6. Add one fixture page and run `fixtures/build.ps1 -Update`.

**Never** add `layouts/_default/single.html` or `layouts/_default/baseof.html`.
That is the one move that breaks every other page on the consumer's site, and
it fails silently.

---

## 8. What this layer deliberately does not do

- It does not own content. The Foundation ships no articles, and never will.
- It does not decide a section's URL, menu placement, or language.
- It does not invent metadata. If a page does not declare a date, no date is
  rendered.
- It does not force a base theme. With no base theme, the Foundation's own
  `article/baseof.html` produces a complete document on its own.
