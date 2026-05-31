---
name: review-docs
description: Visual and structural documentation review. Screenshots live rendered pages, passes to Gemini vision for readability/colour/diagram analysis. Separate pass for structure, acronyms, and assumed knowledge. Persona is a junior researcher with no domain context.
---

# review-docs

**What**: Three passes — structural sweep of the full project (Gemini with native file access), visual per-page screenshot review, isolated per-page content check.
**Why**: Markdown that looks fine in source renders badly. Tool choice per pass matches the intended reviewer's information access — full context where cross-file awareness helps, strict isolation where it would corrupt the cold-read frame.

---

## Trigger

```
/review-docs
/review-docs docs/path/to/specific-page.md
```

Without argument: full project review. With argument: single page (Pass 1 skipped).

---

## Scope

```bash
find docs/ -name "*.md" -not -path "*/appendix/*" -not -name "index.md" | sort
```

Skip: `docs/appendix/` (reviews, ADRs, dev-log), auto-generated API reference.

---

## Step 0 — server

Find the docs port:
```bash
grep -oP '(?<=(docs|frontend|mkdocs)\s*=\s*)\d+' .registered-ports.toml | head -1
```

If not responding, start mkdocs:
```bash
WATCHDOG_USE_POLLING_OBSERVER=true mkdocs serve --dirty -a 0.0.0.0:<PORT> &
sleep 3
```

All subsequent steps use `http://localhost:<PORT>`.

---

## Pass 1 — project structure (full project, gemini CLI)

Run from project root. Gemini reads the docs tree natively — no piping or catting needed.

```bash
gemini -p 'STRUCTURE_PROMPT'
```

**STRUCTURE_PROMPT**:

```
Read all markdown files under docs/ (excluding docs/appendix/ and any auto-generated API reference).
You are a junior researcher from a completely different field handed this documentation cold.
You have no domain knowledge. Answer 6 questions. No code. Name files and sections where relevant.

FIRST_IMPRESSION:
  One sentence: from the navigation structure alone, what does this project appear to do?
  If you cannot tell, say so explicitly.

NAVIGATION:
  CLEAR — or — FLAG: any section or page whose purpose is unclear from its title alone.
  What would you expect to find there vs what is actually there?

ORPHANS:
  NONE — or — FLAG: any page that doesn't clearly belong to its parent section.

GAPS:
  NONE — or — FLAG: given the section structure, what obvious pages are missing?
  Example: a "Getting Started" section with no "Prerequisites" page.

ACRONYMS:
  NONE — or — FLAG: every acronym used without expansion on first use. List each one and the page.

ASSUMED:
  NONE — or — FLAG: any concept, tool, or term used as if the reader already knows it. Name the term and page.
```

---

## Pass 2 — visual review (per page, Gemini Pro vision, screenshot)

### Screenshot

```bash
SLUG=$(echo "<page-path>" | sed 's|docs/||;s|\.md$||;s|index$||')
URL="http://localhost:<PORT>/${SLUG}/"
chromium --headless=new \
  --screenshot="/tmp/docs-review/${SLUG//\//-}.png" \
  --window-size=1440,8000 \
  --hide-scrollbars \
  --no-sandbox \
  "${URL}"
```

8000px height: `--screenshot` clips to window height — a short viewport silently drops diagrams and render errors below the fold. Increase to 12000px for very long pages.

If `chromium` not found, try `google-chrome-stable` then `chromium-browser`.

### Visual analysis

```bash
llm -m gemini-2.5-pro 'VISUAL_PROMPT' -a "/tmp/docs-review/${SLUG//\//-}.png"
```

**VISUAL_PROMPT**:

```
You are a junior researcher who has just opened this documentation page in a browser.
You have no prior knowledge of the project. This is a screenshot of the rendered page.

IMPORTANT: Scan the ENTIRE image top to bottom before answering — diagrams and errors often appear in the lower half.

Answer 7 questions. Describe what you see, not what you assume.

TRUNCATED:
  OK — or — FLAG: page appears cut off mid-content (heading with no body, diagram without closing border,
  content ending abruptly with no footer). If truncated, flag it — screenshot height needs increasing.

RENDERS:
  OK — or — FLAG: any diagram, image, or code block that is broken, shows raw syntax (e.g. mermaid source
  instead of a rendered diagram), or is cut off. Check diagrams in ALL sections.

LEGIBLE:
  OK — or — FLAG: text inside diagrams too small to read, overlapping labels, colour contrast issues.

COLOUR:
  USED — or — FLAT: is colour used to create visual hierarchy and draw attention to key points?
  FLAT means black text on white with no callout boxes, colour-coded nodes, or visual emphasis.

HIERARCHY:
  CLEAR — or — FLAG: from a visual scan (not word-by-word), can you tell what is most important on this page?

DENSITY:
  OK — or — FLAG: long unbroken prose blocks, wide tables with 8+ columns, sections with no breathing room.

FIRST_QUESTION:
  One sentence: as a new reader, what is the first question this page leaves unanswered that it should have answered?
```

---

## Pass 3 — content review (per page, Gemini Flash, isolated)

One call per page. Strict isolation — `llm` sees only this file, no filesystem access.

```bash
llm -m gemini-2.5-flash 'CONTENT_PROMPT' -a <page.md>
```

**CONTENT_PROMPT** (substitute `<FILENAME>`):

```
You are a junior researcher reading this documentation page for the first time.
You have no domain knowledge. Answer 5 questions. No code.

Page: <FILENAME>

WHAT_WHY:
  PRESENT — or — MISSING: does the page open with a clear "what this is" and "why it exists"?
  If missing, say what the page seems to be about based on its content.

ACRONYMS:
  NONE — or — FLAG: every acronym or technical abbreviation used without expansion on first use on this page.

ASSUMED:
  NONE — or — FLAG: any tool, concept, or term used as if the reader already knows it, with no explanation.

DOES_NOT:
  PRESENT — or — MISSING: does the page make clear what it does NOT cover, so the reader knows when to look elsewhere?

SIMPLER:
  NO — or — FLAG: a section significantly more complex than it needs to be. One sentence — what and why.
```

---

## Filter

Write to report only if **any answer contains FLAG, FLAT, MISSING, or a substantive FIRST_QUESTION**.
All clear → print `docs review complete — no flags`, write nothing.

---

## Output

Single file: `docs/appendix/reviews/YYYY-MM-DD-docs-<scope>.md`

Structure: **Project Structure** section (Pass 1 output), then for each page a **Visual** and **Content** subsection together. Append a row to `docs/appendix/reviews/index.md`. Leave unstaged.

---

## Models

- Pass 1: `gemini` CLI — native filesystem access, full 1M context for cross-file structure analysis
- Pass 2: `llm -m gemini-2.5-pro` — vision capability required for screenshot analysis
- Pass 3: `llm -m gemini-2.5-flash` — isolated single-file call, no filesystem bleed
