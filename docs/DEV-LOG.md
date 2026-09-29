# Dev Log

Dev Log is a **usage pattern of the `note` content type**, not a new type.
The shape is a convention, so the Foundation does not have to grow a content
type for it.

## When to use it

Use a Dev Log entry when the change is small enough to fit in a single note
but worth a dated, searchable record on the site. Build numbers, dependency
upgrades, layout decisions, broken-then-fixed moments — anything that future
you would want to grep the archive for.

Do not use it for things that need their own page bundle of screenshots and a
two-thousand-word write-up; that is `type: article`.

## How to create one

```bash
hugo new --kind devlog content/devlog/2026-09-29-fixture-greens/index.md
```

This generates a note with the devlog front matter pre-filled, inside a page
bundle so the entry can carry its own cover, screenshots, and attached files:

```text
content/devlog/
  2026-09-29-fixture-greens/
    index.md         # the entry
    cover.jpg        # optional, used by fn/article-shell
    screenshot.png   # optional, attached to the entry
  _index.md          # the section landing
```

The date in the directory name is the slug. Hugo sorts Dev Log entries by
`date` descending on the section listing; matching the slug to the date keeps
filesystem and rendered order identical.

## Front matter

A Dev Log entry is a `type: note` with three additions on top of the standard
note front matter:

| Key | Required | Meaning |
|---|---|---|
| `type` | yes | Always `"note"`. |
| `date` | yes | When the change landed. |
| `version` | optional | Build, release, or commit ref. Free-form string. |
| `changes` | optional | List of `added:`, `changed:`, `fixed:`, `removed:` items. |
| `tags` | recommended | Always include `devlog` so a `/tags/devlog/` listing works. |

A consumer that wants a richer Dev Log (e.g., a build number, a deploy
target, a release link) extends `changes` with their own keys. The Foundation
does not render `changes` itself; it is data the consumer's brand layer or a
later template hook can pick up.

## The section landing

A Dev Log section is just a Hugo section: `_index.md` at the section root.
The Foundation does not ship a `devlog` layout override; the standard
`note`-flavoured listing renders the entries in reverse chronological order,
which is what a log wants.

## Where Dev Log differs from a changelog

A changelog is generated from commit history and lives outside the content
tree. A Dev Log is hand-written and lives inside it, with the same
`editorial voice` as the rest of the site. A Dev Log entry can quote a
screenshot, link a discussion, name the bug, and tell the reader what to do
next. A changelog cannot.
