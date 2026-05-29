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
- Which mermaid nodes get `classDef` colours?
- Which admonition types signal what? (`tip` = optional, `warning` = scope boundary, `danger` = breaking)
- Which inline code gets `#!lang` syntax highlighting vs plain backticks?

Use the **same colour for the same concept** everywhere it appears across every diagram in a doc set.

**Standard palette — use these, don't invent new ones:**

| Colour | Hex | Meaning |
|--------|-----|---------|
| Blue | `#85c1e9` | Entry points, callers, CLI |
| Green | `#52be80` | Business logic, production code |
| Purple | `#c39bd3` | Interfaces, seam boundaries |
| Orange | `#f0b27a` | Fakes, mocks, test doubles |
| Grey | `#717d7e` | External systems, network, third-party APIs |

```
classDef entry    fill:#85c1e9,color:#1a252f,stroke:#2471a3
classDef logic    fill:#52be80,color:#145a32,stroke:#196f3d
classDef boundary fill:#c39bd3,color:#4a235a,stroke:#7d3c98
classDef fake     fill:#f0b27a,color:#784212,stroke:#e67e22
classDef external fill:#717d7e,color:#fff,stroke:#5d6d7e
```

---

## Rule 5 — What + Why for every page and function (no exceptions)

**Every file. Every exported function. Every test file.** Not "the main ones" — all of them. A file without a package comment or a function without a directive is incomplete, not optional.

Every module page, doc page, and exported function opens with:

**What**: one sentence — what this does.
**Why**: one sentence — why it exists separately, or what problem it solves. Without the "why", a reader can't tell if this is the right thing to use or if something else does the same job.

Format for docs:
```markdown
**What**: Scores AI-generated video 0–10 for humanness.
**Why**: Separate from the pipeline so it runs against any video without starting the server.
```

Format for Go code (but also applies more generally - spec/in/out)):
```go
// Generate submits a Kling job and writes the result to req.OutputPath.
// In:  gen.Request — FirstFrame/LastFrame as accessible URLs, Duration in seconds
// Out: error — nil means file written; non-nil means nothing was written
func (c *Client) Generate(ctx context.Context, req gen.Request) error {
```

`In:` / `Out:` only when the type signature doesn't already say it clearly. Skip for trivial getters.


---

## Rule 6 — Does NOT

Explicitly banning scope is more useful than describing scope. Every module page gets:

```markdown
!!! warning "Does NOT"
    Upload frames, retry on failure, or manage output storage.
    Caller is responsible for all three.
```

---

## Rule 7 — Visual hierarchy: guide the reader's eye

`**What**:` and `**Why**:` as plain bold text are a smell. They are acceptable for **code comments and API reference** where prose is expected to be dense. For **explanation and concept pages**, they bury the most important information in a wall of equal-weight text.

**The test**: if a reader skimmed only the coloured/boxed elements on the page, would they get the point? If not, the visual hierarchy is wrong.

### Information tiers — treat them differently

| Tier | What it is | How to render it |
|------|-----------|-----------------|
| **Hook** | The single thing the reader MUST know | Opening sentence in bold, or `!!! abstract "TL;DR"` |
| **Key decision** | Non-obvious design choice or "why it works this way" | `!!! tip` or `!!! note` callout — never inline prose |
| **Reference data** | Numbers, weights, flags, tables | Tables, not prose lists |
| **How-to** | Step-by-step or code | Numbered steps or annotated code blocks |
| **Edge case / gotcha** | What breaks, what not to do | `!!! warning` |

### Pattern by page type

**Concept/explanation page** (e.g. "why this prompt works", "how the scoring formula was chosen"):
```markdown
!!! abstract "Key insight"
    One sentence. The thing that makes the rest make sense.

Then expand. Key decisions in `!!! tip` blocks, not inline.
```

**Reference page** (API, code, module):
```markdown
**What**: one sentence.
**Why**: one sentence.

Table → code block → Does NOT box.
```

**Index / section home**:
```markdown
Card grid → criteria table → section map.
No opening prose paragraph.
```

**Architecture page**:
```markdown
Diagram first. One-sentence annotation per component. Then tables for edge cases.
```

### The "Why deserves a callout" rule

If you are writing a sentence that contains "because", "so that", "in order to", or "which means" — that explanation is non-obvious and belongs in a `!!! tip` or `!!! note`, not buried in a paragraph. Explanatory content earns visual prominence.

**❌ Wrong:**
> The baseline is set explicitly because without it, Gemini tends to comment on gross anatomy failures rather than subtle artifacts.

**✓ Right:**
```markdown
!!! tip "Why the baseline matters"
    Without it, Gemini comments on gross anatomy failures rather than subtle artifacts.
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
- [ ] New architectural decision → write ADR in `docs/appendix/adr/`, update index table
- [ ] Code review completed → save to `docs/appendix/reviews/`, update log table

---

## Anti-patterns

**❌ Prose describing positions** — "the cache sits between the API and the database" → draw it.

**❌ Plain backticks for everything** — when every inline snippet looks identical, the reader can't build a visual model. Use `` `#!lang symbol` `` for the *subject* of explanation.

**❌ Stale diagrams** — if a diagram describes code structure, either generate from code or add "last verified: date". Hand-drawn diagrams are fine for *intent*; not for *fact*.

**❌ Six tables on one page** — if a page has 4+ tables, it's probably six pages.

**❌ "See the README"** — README is for "what is this, how do I run it". Anything beyond goes in `docs/`.

---

## Project records — three types, one place

All project history lives in `docs/appendix/`. Three types:

### Dev Log (`docs/appendix/dev-log.md` → `DEV-LOG.md`)

Append one entry per meaningful session event. Format:

```
## YYYY-MM-DD — title
Context: what I was doing
Action: what I did / chose
Why: reasoning in one or two sentences
Result: outcome, test evidence, next step
```

Log decisions, blockers, pivots, completions. Not every bash command.

### ADRs (`docs/appendix/adr/`)

Non-trivial architectural decisions (language choice, tool choice, structural pattern). One file per decision, named `NNN-slug.md`. Goal: record *why*, not a technical reference.

Format:
```markdown
## ADR-NNN — Title
**Status**: Accepted | Superseded by ADR-NNN | Proposed
**Date**: YYYY-MM-DD
**Context**: 1–2 sentences. What forced this decision?
**Decision**: 1 sentence. What was chosen.
**Consequences**:
- ✓ what this enables
- ✗ what this rules out or costs
```

Update the index table in `docs/appendix/adr/index.md` when adding.

### Code Reviews (`docs/appendix/reviews/`)

Output of function-level comprehension reviews (run by a separate model, not Claude). One file per review session, named `YYYY-MM-DD-<module>.md`. Update the log table in `docs/appendix/reviews/index.md`.

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

## Rule 8 — Test docs: the function→seam→control triad

Any page explaining HOW tests work must show three things in one diagram:

1. **Code path** — the function's steps in execution order (numbered, one subgraph)
2. **Seam** — the injection point: an interface field, a URL field, a fake server
3. **Test control** — what the fake controls at each step (second subgraph)

Connect them with **dashed arrows** (`-.->|"what it controls"|`). Each arrow is a claim: "this step's behaviour is controlled by this thing."

```
subgraph code["module.go — Function flow"]
    direction TB
    S1["1. step one"]:::logic
    S2["2. step two"]:::logic
    S1 --> S2
end

subgraph fake["FakeXxx controls"]
    C1["field / queue controlling step 1"]:::fake
    C2["field / queue controlling step 2"]:::fake
end

S1 -.->|"initial state"| C1
S2 -.->|"poll sequence"| C2
```

Solid arrows = calls. Dashed arrows = controlled by. The distinction is what makes this a test spec, not just a call graph.

Follow the diagram with a table: `Test | Which step | What the fake controls`

---

# a closing note
**ALWAYS remember**
- colour! 
- engagement
- this is a person reading the documentation (not a robot)
- it should be engaging using colour and diagrams to emphasise the important points

