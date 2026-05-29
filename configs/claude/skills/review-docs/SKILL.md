---
name: review-docs
description: Visual and structural documentation review. Screenshots live rendered pages, passes to Gemini vision for readability/colour/diagram analysis. Separate pass for structure, acronyms, and assumed knowledge. Persona is a junior researcher with no domain context.
---

# review-docs

**What**: Multi-pass review of rendered documentation — one structural pass over all markdown source, one visual pass per page via screenshot, one content pass per page for assumed knowledge and clarity.
**Why**: Markdown that looks fine in source renders badly: mermaid diagrams truncate, colour is lost, hierarchy flattens. Only a screenshot pass catches what a real reader sees.

---

## Trigger

```
/review-docs
/review-docs docs/path/to/specific-page.md
```

Without argument: full project review (all pages under `docs/`).
With argument: single page review (structure pass skipped, visual + content passes only).

---

## Scope

Pages to review:
```bash
find docs/ -name "*.md" -not -path "*/appendix/*" -not -name "index.md" | sort
```

Skip: `docs/appendix/` (reviews, ADRs, dev-log — not reader-facing), auto-generated API reference.

---

## Step 0 — server

Find the docs port from `.registered-ports.toml` in the project root:
```bash
grep -E "^docs|^frontend|^mkdocs" .registered-ports.toml | head -1 | awk -F= '{print $2}' | tr -d ' '
```

If the port is not responding, start mkdocs in the background:
```bash
WATCHDOG_USE_POLLING_OBSERVER=true mkdocs serve --dirty -a 0.0.0.0:<PORT> &
sleep 3
```

All subsequent steps use `http://localhost:<PORT>`.

---

## Pass 1 — project structure (full project, Gemini Pro, text)

One call. Concatenate all in-scope markdown files and pass to Gemini Pro.

```bash
find docs/ -name "*.md" -not -path "*/appendix/*" \
  | sort | xargs -I {} sh -c 'echo "\n\n=== FILE: {} ===\n"; cat {}' \
  | llm -m gemini-2.5-pro 'STRUCTURE_PROMPT'
```

**STRUCTURE_PROMPT**:

```
You are a junior researcher from a completely different field who has been handed this
documentation to understand a project you know nothing about.

You have no domain knowledge. You do not know what the project does yet.
Your job is to answer 6 questions. No code. Be specific — name files and sections.

FIRST_IMPRESSION:
  One sentence: from the navigation structure alone, what does this project appear to do?
  If you cannot tell, say so explicitly.

NAVIGATION:
  CLEAR — or — FLAG: any section or page whose purpose is unclear from its title alone.
  What would you expect to find there vs what is actually there?

ORPHANS:
  NONE — or — FLAG: any page that doesn't clearly belong to its parent section.
  Name the page and which section it would logically live in instead.

GAPS:
  NONE — or — FLAG: given the section structure, what obvious pages are missing?
  Example: a "Getting Started" section with no "Prerequisites" page.

ACRONYMS:
  NONE — or — FLAG: every acronym or abbreviation used without being expanded on first use.
  List each one and the page it first appears on.

ASSUMED:
  NONE — or — FLAG: any concept, tool, or domain term used as if the reader already knows it,
  with no explanation or link. Name the term and the page.
```

---

## Pass 2 — visual review (per page, Gemini Pro vision, screenshot)

For each page, take a full-page screenshot and pass to Gemini Pro with the visual prompt.

### Screenshot

```bash
SLUG=$(echo "<page-path>" | sed 's|docs/||;s|\.md$||;s|index$||')
URL="http://localhost:<PORT>/${SLUG}/"
chromium --headless=new \
  --screenshot="/tmp/docs-review/${SLUG//\//-}.png" \
  --window-size=1440,900 \
  --hide-scrollbars \
  "${URL}"
```

If `chromium` is not found, try `google-chrome-stable` then `chromium-browser`.

### Visual analysis

```bash
llm -m gemini-2.5-pro 'VISUAL_PROMPT' -a "/tmp/docs-review/${SLUG//\//-}.png"
```

**VISUAL_PROMPT**:

```
You are a junior researcher who has just opened this documentation page in a browser.
You have no prior knowledge of the project. This is a screenshot of the rendered page.

Answer 6 questions. Be specific — describe what you see, not what you assume.

RENDERS:
  OK — or — FLAG: any diagram, image, or code block that appears broken, truncated,
  shows raw syntax (e.g. mermaid source instead of a diagram), or is cut off by the viewport.

LEGIBLE:
  OK — or — FLAG: any diagram where the text inside it is too small to read at this zoom level,
  or where node labels overlap. Include colour contrast issues (light text on light background).

COLOUR:
  USED — or — FLAT: is colour used to create visual hierarchy and draw attention to key points?
  FLAT means the page is mostly black text on white with no meaningful use of colour, callout
  boxes, or visual emphasis.

HIERARCHY:
  CLEAR — or — FLAG: from a visual scan (not reading word-by-word), can you tell what is most
  important on this page? If everything looks the same visual weight, flag it.

DENSITY:
  OK — or — FLAG: is the page overwhelming? Long unbroken prose blocks, tables that span the
  full width with 8+ columns, or sections with no breathing room between them.

FIRST_QUESTION:
  One sentence: as a new reader, what is the first question this page leaves unanswered that
  it should have answered?
```

---

## Pass 3 — content review (per page, Gemini Flash, text)

One call per page. Reads the markdown source. Checks for assumed knowledge and structural completeness.

```bash
{ echo 'CONTENT_PROMPT'; cat <page.md>; } | llm -m gemini-2.5-flash
```

**CONTENT_PROMPT** (substitute `<FILENAME>`):

```
You are a junior researcher reading this documentation page for the first time.
You have no domain knowledge of the project.
Answer 5 questions. No code. Put each answer on its own line with a blank line between.

Page: <FILENAME>

WHAT_WHY:
  PRESENT — or — MISSING: does the page open with a clear "what this is" and "why it exists"?
  If missing, say what the page seems to be about based on the content.

ACRONYMS:
  NONE — or — FLAG: every acronym or technical abbreviation used without being spelled out
  on first use on this page. List each one.

ASSUMED:
  NONE — or — FLAG: any tool, concept, or term used as if the reader already knows it,
  with no explanation. Be specific about the term and where it appears.

DOES_NOT:
  PRESENT — or — MISSING: does the page make clear what it does NOT cover, so the reader
  knows when to look elsewhere? If missing and the scope is ambiguous, flag it.

SIMPLER:
  NO — or — FLAG: is there a section that is significantly more complex than it needs to be?
  One sentence — what is it and why is it hard to follow?
```

---

## Filter

Write to report only if **any answer across all passes contains FLAG, FLAT, MISSING, or FIRST_QUESTION has substance**.
All clear → print `docs review complete — no flags`, write nothing.

---

## Output

`docs/appendix/reviews/YYYY-MM-DD-docs-<scope>.md`:

```markdown
# Docs Review — <scope>
_YYYY-MM-DD · gemini-2.5-pro (structure + visual) + gemini-2.5-flash (content)_

---

### Project Structure

FIRST_IMPRESSION: appears to be a video grading pipeline, but the relationship between
                  "Grading" and "Evaluation" sections is unclear
NAVIGATION:  FLAG: "Humanness Rubric" page — title implies a spec but it reads as a design doc
ORPHANS:     FLAG: docs/appendix/grading-notes.md — belongs under Grading, not appendix
GAPS:        FLAG: Getting Started has no Prerequisites page — reader doesn't know what to install
ACRONYMS:    FLAG: "SDE" used on docs/pipeline/overview.md without expansion
ASSUMED:     FLAG: "ComfyUI" used on 3 pages with no explanation of what it is

---

### Visual — docs/pipeline/overview.md

RENDERS:   FLAG: mermaid diagram shows raw source — "graph TD" visible, not rendered
LEGIBLE:   OK
COLOUR:    FLAT: page is entirely black text, no callouts, no colour-coded nodes in diagrams
HIERARCHY: FLAG: all sections look equal weight — no visual signal for what to read first
DENSITY:   OK
FIRST_QUESTION: what does this pipeline actually produce — a score, a file, a report?

---

### Content — docs/pipeline/overview.md

WHAT_WHY:  MISSING: page starts with a mermaid diagram with no introductory sentence
ACRONYMS:  FLAG: "WanAnimate", "KLING", "BG" used without expansion
ASSUMED:   FLAG: "Temporal consistency" used as if reader knows what it means in ML context
DOES_NOT:  MISSING: unclear whether this page covers the full pipeline or just the video stage
SIMPLER:   NO
```

Append a row to `docs/appendix/reviews/index.md`.

---

## Model

`gemini-2.5-pro` — Passes 1 and 2. Full project structure (1M context) and vision analysis of screenshots require Pro's reasoning and multimodal capability.

`gemini-2.5-flash` — Pass 3. Per-page text content checks. Fast, cheap, sufficient for line-level checklist.

`llm models | grep gemini` to verify aliases. Do NOT use the `gemini` agentic CLI.

---

## Does NOT

- Modify any documentation
- Run automatically
- Commit output
- Review `docs/appendix/` (reviews, ADRs, dev-log)
- Review API reference pages generated from code
