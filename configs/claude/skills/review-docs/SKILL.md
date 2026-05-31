---
name: review-docs
description: Visual and structural documentation review. Screenshots live rendered pages, passes to Gemini vision for readability/colour/diagram analysis. Separate pass for structure, acronyms, assumed knowledge, and factual accuracy (broken links, stale code refs, image/claim mismatches). Persona is a junior researcher with no domain context.
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
You are a junior researcher from a completely different field who has been handed this
documentation to understand a project you know nothing about.

You have no domain knowledge. You do not know what the project does yet.
As a junior researcher, you are expected flag things you do not understand- assumed domain knowledge, 
acronyms, leaps in knowledge that are unclear. unlinked references points and logic points

Your job is to answer 6 questions. No code. Be specific — name files and sections.

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

---

## Pass 4 — factual verification

Checks that claims made in the docs are true. Three sub-steps run in order.

### 4a. Broken links (automated, no Gemini)

Extract every external URL from all in-scope markdown files and HTTP-check each one:

```bash
grep -rhoP '(?<=\()https?://[^\s)]+' docs/ | sort -u | while read url; do
  code=$(curl -sL -o /dev/null -w "%{http_code}" --max-time 10 "$url")
  [[ "$code" != "200" ]] && echo "BROKEN $code $url"
done
```

Flag every non-200 response. Include the status code — 404 (gone) and 301 (moved) are different problems.

### 4b. Code and file reference check (automated, no Gemini)

Extract every file path and inline code symbol mentioned in docs and verify it exists in the repo:

```bash
# File paths: anything that looks like a path (contains / or .) in backticks
grep -rhoP '`[^`]*[/\.][^`]*`' docs/ | grep -oP '(?<=`).*(?=`)' | sort -u | while read ref; do
  # skip URLs, commands, extensions-only strings
  [[ "$ref" =~ ^https? ]] && continue
  [[ "$ref" =~ ^[a-z]+\.[a-z]+$ ]] && continue
  # check if it exists anywhere in the project
  result=$(find . -path "./.git" -prune -o -path "$ref" -print -o -name "$(basename $ref)" -print 2>/dev/null | head -1)
  [[ -z "$result" ]] && echo "NOT FOUND: $ref"
done
```

Flag anything not found. Don't fail on ambiguous short names (e.g. `fn`, `id`) — only flag clear file/path references.

### 4c. Claim verification (per page, Gemini Flash + vision)

Two Gemini calls per page: one text call for factual prose claims, one vision call for any images.

**Text claim check** — for each page, pass markdown source + any referenced local file snippets:

```bash
# For files referenced in the page, inline their current content
REFS=$(grep -oP '`[^`]+\.(py|lua|ts|js|nix|toml|yaml|json)[^`]*`' <page.md> | grep -oP '(?<=`).*(?=`)')
SNIPPETS=""
for ref in $REFS; do
  [[ -f "$ref" ]] && SNIPPETS+="=== CURRENT CONTENT OF $ref ===\n$(cat $ref)\n\n"
done
{ echo 'VERIFY_PROMPT'; echo "=== DOC SOURCE ==="; cat <page.md>; echo "$SNIPPETS"; } | llm -m gemini-2.5-flash
```

**VERIFY_PROMPT**:

```
You are a fact-checker. You have been given a documentation page and, where available,
the current content of files it references.

Your job: find claims that are provably wrong or unverifiable. Ignore opinion, style, and clarity.
Focus only on factual accuracy.

List each flag on its own line. If nothing is wrong, output only: VERIFIED

FLAG categories — use exactly these labels:

STALE_REF:   A function, class, config key, or file path mentioned in the docs that does not
             appear in the provided file content. Means the docs describe something that no
             longer exists or has been renamed.
             Example: docs say "call `process_frame()`" but the file has no such function.

WRONG_CLAIM: A specific factual claim (number, behaviour, default value, flag name) that
             contradicts what the provided file content shows.
             Example: docs say "default timeout is 30s" but the code sets DEFAULT_TIMEOUT = 60.

UNVERIFIABLE: A specific factual claim that cannot be checked from the provided context
              (e.g. references an external service, a price, a third-party API response)
              and should be manually verified.
              Example: "the Skyscanner API returns prices in GBP" — cannot verify from source.

Format each flag as:
FLAG_TYPE: "<quoted claim from docs>" — <one sentence why it's flagged>
```

**Image claim check** — for each image (`![...]`) in the page, screenshot the rendered image and pass alongside the surrounding text:

```bash
# Extract surrounding 3 lines of context around each image reference
grep -n '!\[' <page.md> | while read match; do
  line=$(echo "$match" | cut -d: -f1)
  context=$(sed -n "$((line-3)),$((line+3))p" <page.md>)
  img_src=$(echo "$match" | grep -oP '(?<=\().*(?=\))')
  # screenshot the rendered image from the live page at that anchor
  llm -m gemini-2.5-pro 'IMAGE_VERIFY_PROMPT' -a "$img_src" <<< "$context"
done
```

**IMAGE_VERIFY_PROMPT**:

```
You are a fact-checker reviewing a documentation screenshot.
The surrounding text makes claims about what this image shows.

Surrounding context:
<CONTEXT>

Does the image match the claims in the surrounding text?

FLAG if: a number visible in the image contradicts a number stated in the text
         (e.g. text says "£300" but screenshot shows "£400").
FLAG if: the image shows an error state but the text describes it as working.
FLAG if: the image appears to be outdated (UI elements or data that contradict the text).

If the image matches or the context makes no specific verifiable claim: output only VERIFIED.

Format: IMAGE_MISMATCH: "<claim in text>" vs "<what image actually shows>"
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
