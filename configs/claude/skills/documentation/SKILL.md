---
name: documentation
description: Writing, structuring, and maintaining project documentation. Auto-loaded when creating or updating docs, mkdocs sites, architecture pages, or any markdown documentation.
---

# documentation

**What**: Rules for writing docs and code comments that a human can actually use.
**Why**: AI-generated documentation defaults to technically correct but reader-hostile — acronyms without explanation, prose where diagrams should be, no visual hierarchy.

---

## Rule 1 — pass the user test

Before any line goes into a doc or code comment, ask: **would someone with no prior context understand this?**

If no — either expand it inline or add an annotation. Never assume the reader has been in the same sessions as you.

- Expand acronyms on first use: "WanAnimate (the RunComfy character-swap model)" not just "WanAnimate"
- No shorthand that only makes sense inside the project: "BG swap" → "background swap"
- Each sentence should stand alone — re-read it as if you've never seen this codebase

---

## Rule 2 — name things before writing anything

Naming causes more rewrites than anything else. Before writing a page, file, or function:

- Pick the name. Say it out loud. Does it describe what the thing *does* or just what it *is*?
- If a user would confuse it with something adjacent ("Specification" vs "Humanness Rubric"), rename before writing
- Consistent terminology throughout — pick one term per concept and use it everywhere

---

## Rule 3 — diagram first, always

**A page describing structure, flow, or layout must contain a diagram. Tables and prose alone are not enough.**

If you're writing a list of routes, services, steps, or states — stop. That has shape. Draw it, then annotate.

Smell test: if you're using words like "sits behind", "flows from", "sits between" — you're describing a diagram you haven't drawn yet.

---

## Rule 4 — colour is designed in, not added after

Before writing content, decide:
- Which mermaid nodes get `classDef` colours? (blue = source, green = result, red = danger, grey = context)
- Which admonition types signal what? (`tip` = optional, `warning` = scope boundary, `danger` = breaking)
- Which inline code gets `#!lang` syntax highlighting vs plain backticks?

Use the **same colour for the same concept** everywhere it appears. A concept that's blue in the diagram should be blue in the code block and the prose annotation.

```mermaid
classDef source fill:#2471a3,color:#fff,stroke:#1a5276
classDef result fill:#1e8449,color:#fff,stroke:#196f3d
```

---

## Rule 5 — What + Why for every page and function (no exceptions)

**Every Go file. Every exported function. Every test file.** Not "the main ones" — all of them. A file without a package comment or a function without a directive is incomplete, not optional.

Every module page, doc page, and exported function opens with:

**What**: one sentence — what this does.
**Why**: one sentence — why it exists separately, or what problem it solves. Without the "why", a reader can't tell if this is the right thing to use or if something else does the same job.

Format for docs:
```markdown
**What**: Scores AI-generated video 0–10 for humanness.
**Why**: Separate from the pipeline so it runs against any video without starting the server.
```

Format for Go code:
```go
// Generate submits a Kling job and writes the result to req.OutputPath.
// In:  gen.Request — FirstFrame/LastFrame as accessible URLs, Duration in seconds
// Out: error — nil means file written; non-nil means nothing was written
func (c *Client) Generate(ctx context.Context, req gen.Request) error {
```

`In:` / `Out:` only when the type signature doesn't already say it clearly. Skip for trivial getters.

For test functions — the name is the spec:
```go
func TestGenerate_WritesOutputFile(t *testing.T) {   // ✓ clear directive
func TestGenerate_RequestShape(t *testing.T) {        // ✗ "shape" is not a behaviour
```

---

## Rule 6 — Does NOT

Explicitly banning scope is more useful than describing scope. Every module page gets:

```markdown
!!! warning "Does NOT"
    Upload frames, retry on failure, or manage output storage.
    Caller is responsible for all three.
```

---

## Update docs with code — trigger checklist

When code changes, docs change in the same commit:

- [ ] New CLI entry point → update Getting Started entry-point flowchart
- [ ] New route or tool → update index app table + architecture system map
- [ ] New external service → update architecture system map + external services table
- [ ] New env var → update Getting Started API keys section
- [ ] New pipeline stage → update data-flow sequence diagram
- [ ] New test → ensure module doc page references it
- [ ] Weight or criteria change → update grading spec
- [ ] New Generator provider → update video-generation spec provider table

---

## Anti-patterns

**❌ Prose describing positions** — "the cache sits between the API and the database" → draw it.

**❌ Plain backticks for everything** — when every inline snippet looks identical, the reader can't build a visual model. Use `` `#!lang symbol` `` for the *subject* of explanation.

**❌ Stale diagrams** — if a diagram describes code structure, either generate from code or add "last verified: date". Hand-drawn diagrams are fine for *intent*; not for *fact*.

**❌ Six tables on one page** — if a page has 4+ tables, it's probably six pages.

**❌ "See the README"** — README is for "what is this, how do I run it". Anything beyond goes in `docs/`.

---

## ADRs — decision logging

Non-trivial architectural decisions (language choice, tool choice, structural pattern) get an ADR. This can be brief — the goal is a record of *why*, not a technical reference.

Template: status, date, context (2 sentences), decision (1 sentence), consequences (bullet list).

---

## Before merging — docs checklist

- [ ] Every page describing structure has at least one diagram
- [ ] New routes/tools in the index app table
- [ ] `mkdocs build --strict` passes
- [ ] No new flat tables for things that have shape
- [ ] Every acronym expanded on first use

---

## Reference — mkdocs setup

```sh
uv tool install mkdocs --with mkdocs-material
mkdocs new .
WATCHDOG_USE_POLLING_OBSERVER=true mkdocs serve --dirty --livereload -a 0.0.0.0:<port>
```

### mkdocs.yml

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
  # navigation.instant omitted — breaks mermaid on page navigation

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

**Critical:**
- `pymdownx.emoji` required for `:material-*:` icons — without it they render as literal text
- Skip `navigation.instant` — makes mermaid go blank on page navigation

### Header pin (extra.css)

```css
.md-header__title--active .md-header__topic:first-child {
  opacity: 1 !important; transform: none !important;
  pointer-events: auto !important; z-index: 0 !important;
}
.md-header__title--active .md-header__topic + .md-header__topic {
  opacity: 0 !important; pointer-events: none !important; z-index: -1 !important;
}
```

### Material cheatsheet

```markdown
!!! tip "Use this when…"       <!-- blue — guidance -->
!!! warning "Does NOT"         <!-- orange — scope boundary -->
!!! danger "Breaking change"   <!-- red — stop and read -->

=== "Tab label is the punchline"
    content

```python linenums="1" hl_lines="2"
key_line = here  # (1)!
` ``
1. Annotation explains *why*, not *what*.

<div class="grid cards" markdown>
-   :material-rocket-launch: **Title**
    ---
    One sentence.
    [:octicons-arrow-right-24: Link](page.md)
</div>
```
