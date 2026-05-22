---
name: documentation
description: Writing, structuring, and maintaining project documentation. Auto-loaded when creating or updating docs, mkdocs sites, architecture pages, or any markdown documentation. Contains the full doc-writing ruleset and mkdocs-material setup guide.
---

# Documentation — writing rules and mkdocs setup

Auto-loaded when doing any documentation work. These rules apply to every doc page produced.

---

## The one rule

**A doc page that describes structure, flow, or layout must contain a diagram. Tables and prose alone are not enough.**

If you find yourself writing a list of routes, components, ports, services, pipelines, states, or message flows — stop. That information has shape. Draw the shape, then annotate it. Prose is the *annotation*, not the explanation.

The smell test: read the page out loud. If you're describing positions ("the API sits behind…", "requests flow from…", "the cache is between…"), you're describing a diagram you haven't drawn yet.

---

## Vibe coding docs rules (apply alongside the anti-drift rules in /unattended)

**Spec-first for new pages.** Before writing a new doc page, write two lines: what question it answers, who reads it. If you can't answer those, don't write the page.

**Every module/package page opens with "What + Why".** The two questions a new reader always has:
- **What is this?** — one sentence describing what the code does.
- **Why does it exist?** — one sentence on the problem it solves, or why it's separate from adjacent things. Without the "why", a reader can't tell if this is the right module to use, if it's legacy, or if something else does the same job.

Format:
```markdown
# `package/name`

**What**: Scores AI-generated video 0–10 for humanness using Gemini.
**Why**: Separate from the pipeline so it can be run against any video without starting the full server.
```

**"Does NOT" section per module page.** Explicitly banning scope is more powerful than describing scope. Every module/component reference page gets a `!!! warning "Does NOT"` admonition saying what it intentionally doesn't cover.

**Document entry points.** Any module with a callable interface (CLI command, exported function, HTTP endpoint) must show the exact invocation — copy-pasteable, no placeholders. If there are multiple ways to call it, use tabs.

**Reference tests in docs.** If a module has tests, the page shows how to run them:
```markdown
## Tests
```bash
go test ./grading/go/internal/gen/...
go test -run Integration ./grading/go/internal/gen/... # requires API keys
` ``
```
This makes tests discoverable without reading source. Never let tests be invisible.

**Update docs in the same commit as the code.** The trigger table:

| Code change | Required doc update |
|---|---|
| New CLI entry point | Update Getting Started entry-point flowchart |
| New route / Gradio tool | Update index.md app table + architecture overview |
| New external service | Update architecture system map |
| New env var | Update Getting Started API keys section |
| New pipeline stage | Update architecture data-flow sequence diagram |
| New failure mode found | Add runbook entry |
| Weight or criteria change | Update grading specification |
| New Generator implementation | Update video-generation spec provider table |
| New test added | Ensure module doc page references it |

---

## mkdocs setup

For anything beyond a top-level README (design docs, runbooks, architecture refs, multi-page investigation writeups), set up **mkdocs** rather than letting markdown sprawl.

### Install

```sh
uv tool install mkdocs --with mkdocs-material
mkdocs new .          # scaffolds docs/ + mkdocs.yml
mkdocs serve -a 0.0.0.0:<project-port>
```

### mkdocs.yml — full working config

```yaml
site_name: <project>
theme:
  name: material
  features:
    - navigation.tabs
    - navigation.sections
    - navigation.indexes
    - content.code.copy
    - content.code.annotate
    - content.tabs.link
    - search.suggest
    - toc.follow
  # navigation.instant deliberately omitted — breaks mermaid on page navigation

markdown_extensions:
  - admonition
  - pymdownx.details
  - pymdownx.superfences:
      custom_fences:
        - name: mermaid
          class: mermaid
          format: !!python/name:pymdownx.superfences.fence_code_format
  - pymdownx.tabbed:
      alternate_style: true
  - pymdownx.emoji:
      emoji_index: !!python/name:material.extensions.emoji.twemoji
      emoji_generator: !!python/name:material.extensions.emoji.to_svg
  - attr_list
  - md_in_html
  - toc:
      permalink: true

plugins:
  - search

extra_css:
  - stylesheets/extra.css
```

**Critical notes:**
- **Skip `navigation.instant`** — it SPA-routes between pages, which makes mermaid diagrams go blank on navigation. Not worth the perf gain.
- **`pymdownx.emoji` is required for `:material-*:` and `:octicons-*:` icons** — without it the shortcodes render as literal text. The `twemoji` index from `material.extensions.emoji` covers Material Icons, Octicons, and emoji.
- Icons render as inline SVG via `<span class="twemoji"><svg ...>` — if you grep for the icon name in built HTML it won't match; grep for `class="twemoji"` instead.

### Header title pin (extra.css)

mkdocs-material swaps the header title to the current page H1 on scroll. Looks janky. Always add:

```css
/* docs/stylesheets/extra.css */
.md-header__title--active .md-header__topic:first-child {
  opacity: 1 !important;
  transform: none !important;
  pointer-events: auto !important;
  z-index: 0 !important;
}
.md-header__title--active .md-header__topic + .md-header__topic {
  opacity: 0 !important;
  pointer-events: none !important;
  z-index: -1 !important;
}
```

---

## Diagram tool selection

| You're describing… | Use |
|---|---|
| Boxes connected by arrows — architecture, pipelines | `flowchart LR` (mermaid) |
| Request lifecycle, what-calls-what across services | `sequenceDiagram` (mermaid) |
| State machine | `stateDiagram-v2` (mermaid) |
| Big-picture "what is this whole thing" — one per project | Excalidraw (export SVG) |

Default to **mermaid**. Keep diagrams under ~8 nodes. Shape nodes by kind:
- `([rounded])` — actors/users
- `[rect]` — services/processes
- `[(cylinder)]` — data stores
- `{diamond}` — decisions

---

## Material features cheatsheet

Use these before writing flat prose:

```markdown
!!! tip "When to use this"
    Best for "you probably want this" guidance.

!!! warning "Does NOT"
    Explicitly document what this module/page doesn't cover.

??? example "Collapsible — for long examples"
    Hidden by default.
```

**Grid cards** (for "list of N things, each with a purpose"):
```markdown
<div class="grid cards" markdown>

-   :material-rocket-launch: **Title**

    ---

    Description sentence.

    [:octicons-arrow-right-24: Link text](page.md)

</div>
```

**Tabs** (for "same thing, multiple ways"):
```markdown
=== "Go"
    ```bash
    go run ./cmd/grade/... video.mp4
    ```

=== "Python"
    ```bash
    uv run python -m src.grading.cli grade video.mp4
    ```
```

**Code annotations** (for explaining specific lines):
```markdown
```python
client = Gemini(api_key=key)  # (1)!
```
1. Key is resolved from GEMINI_API_KEY env var or .env walk-up.
```

---

## Page structure templates

### Architecture overview page

```markdown
# Architecture

> One paragraph: what this system is, who uses it, what it isn't.

## System map

(Mermaid flowchart — the first thing a new dev sees.)

## Key flows

(Sequence diagrams for the 2–3 most important paths.)

## Code layout

(Directory tree with one-line purpose per entry.)

## External services

(Table: service | used for | where configured)
```

### Module reference page

```markdown
# `module.name`

One sentence: what this is.

!!! warning "Does NOT"
    What this module deliberately doesn't do.

## How it fits

(Mermaid showing inputs → this module → outputs.)

## API reference

(Hand-written usage example, then generated reference.)
```

### Getting Started page

```markdown
# Getting Started

## What you need
## Entry points

(Flowchart: "what do you want?" → correct command)

## Step-by-step first run
## Config / env vars
```

---

## Full doc-writing ruleset (from scratchpads/doc-guidelines.md)

### Anti-patterns

**❌ Prose describing positions** — "The cache sits between the API and the database…" → draw it.

**❌ A table where a tree would do** — if rows have parent-child relationships, draw a tree.

**❌ Auto-generated API ref as primary doc** — mkdocstrings output is a *lookup*. Every module page needs hand-written purpose + when-to-use *above* the generated ref.

**❌ Six tables on one page** — if a page has 4+ tables, it's probably six pages crammed into one.

**❌ Diagrams that go stale silently** — if a diagram describes code structure, either generate it from code or put an explicit "last verified" date on it. Static hand-drawn diagrams are fine for *intent*; don't use them for *fact*.

**❌ "See the README"** — README is for "what is this and how do I run it". Anything beyond that goes in `docs/`.

### Before merging — docs checklist

- [ ] Every page describing structure has at least one diagram
- [ ] New routes/tools added to the index app table
- [ ] New architectural decisions have an ADR (if non-trivial)
- [ ] `mkdocs build --strict` passes locally
- [ ] No new flat tables for things that have shape
