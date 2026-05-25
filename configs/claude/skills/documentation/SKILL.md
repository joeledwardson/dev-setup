---
name: documentation
description: Writing, structuring, and maintaining project documentation. Auto-loaded when creating or updating docs, mkdocs sites, architecture pages, or any markdown documentation. Contains the full doc-writing ruleset and mkdocs-material setup guide.
---

# Documentation — writing rules and mkdocs setup

Auto-loaded when doing any documentation work. These rules apply to every doc page produced.

---

## The one rule

**A doc page that describes structure, flow, or layout must contain a diagram. Tables and prose alone are not enough.**

A corollary: **assign a visual identity to each concept and keep it consistent.** A symbol that appears syntax-highlighted inline, colour-coded in the diagram, and highlighted in the code block is a thread the reader can follow. The same symbol in plain backticks everywhere is invisible.

---

## The colour rule

**Before writing a single line of content, name your colour sources.** If you can't answer these, stop and design the page first:

- Which concepts get `#!lang` inline highlighting? (key names, symbols, values being explained)
- Which mermaid nodes get `classDef` colours? (pick a palette, assign meaning — red = danger, blue = source, green = result)
- Which code lines get `hl_lines`? (the line that matters, not every line)
- Which admonition types (`warning`, `danger`, `tip`, `info`) signal what?

If the answer to all four is "none" — the page has no colour and will read as a wall of monochrome text. That is a failure mode, not a style choice. Going back to add colour after the fact requires multiple revision passes (as this skill itself demonstrates). Design it in upfront.

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

> no idea if the WATCHDOG_USE_POLLING_OBSERVER helps (i think --livereload is default anyway also?) but trying random stuff to make it hot reload - sometimes it forgets on new changes.... 😠

### Install

```sh
uv tool install mkdocs --with mkdocs-material
mkdocs new .          # scaffolds docs/ + mkdocs.yml
WATCHDOG_USE_POLLING_OBSERVER=true mkdocs serve --dirty --livereload -a 0.0.0.0:<project-port>
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

Default to **mermaid**. Keep diagrams under ~8 nodes. **Always use `classDef` to colour nodes** — colour = category membership, not decoration. Use the same colour for the same concept wherever it appears in prose and code. Suggested palette: blue = primary/source, red = danger/unexpected, green = result/output, grey = context. Max 4 colours.

```markdown
classDef source fill:#2471a3,color:#fff,stroke:#1a5276
classDef result fill:#1e8449,color:#fff,stroke:#196f3d
```

Shape nodes by kind:
- `([rounded])` — actors/users
- `[rect]` — services/processes
- `[(cylinder)]` — data stores
- `{diamond}` — decisions

---

## Material features cheatsheet

Each of these brings colour. That's the point — colour is how the reader's eye navigates before they read a word. Admonition type = semantic colour (orange warning, blue info, red danger). Tab label = coloured heading. `hl_lines` = blue highlight. `#!lang` inline = syntax colour. Use them instead of flat prose:

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

**Tabs** (for "same thing, multiple ways" OR "same operation applied to different inputs" — the tab label is itself an annotation, use it as the punchline):
```markdown
=== "`Ctrl+[` → `0x1B` (Escape!)"
    ```
    '[' = 91 → strip bit 6 → 27 = 0x1B = ESC
    ```

=== "`Ctrl+/` → `0x1F` (same as `Ctrl+_`)"
    ```
    '?' = 63 → strip bit 6 → 31 = 0x1F
    ```
```

**Code annotations + line highlighting** (for explaining specific lines):
```markdown
```python linenums="1" hl_lines="2"
client = Gemini(api_key=key)  # (1)!
response = client.generate(prompt)  # (2)!
` ``
1. Key resolved from `GEMINI_API_KEY` env var — not passed explicitly.
2. Blocks until complete; wrap in `asyncio.run()` for async callers.
```
`hl_lines="2"` draws the eye to the key line before the reader reads. Reserve annotations for *why*, not *what*.

**Inline syntax highlighting** (ties prose mentions to code colour):
```markdown
The mapping `#!lua ['<C-/>'] = 'action'` registered fine but never fired.
```
Use `` `#!lang symbol` `` for any inline symbol that is the *subject* of the explanation — key names, function names, specific values. Plain backticks for filenames and generic terms.

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

**❌ Plain backticks for everything** — when every inline code snippet looks identical, the reader can't build a visual model. Use `#!lang` for symbols that are the *subject* of explanation so they match their appearance in code blocks and diagrams.

**❌ "See the README"** — README is for "what is this and how do I run it". Anything beyond that goes in `docs/`.

### Decision logging
Typically in long projects it is good to have some record of decisions taken.

This should typically include architectural decisions / patterns like which tools, programming languages and architecture are chosen. This can be a mix of unprompted assumptions of explicitly decided with the user

These should be recorded in ADRs (see also research skill)

### Before merging — docs checklist

- [ ] Every page describing structure has at least one diagram
- [ ] New routes/tools added to the index app table
- [ ] New architectural decisions have an ADR (if non-trivial)
- [ ] `mkdocs build --strict` passes locally
- [ ] No new flat tables for things that have shape
