---
name: research
description: Produce long-form research / analysis / competitive-landscape / market / strategic documents that are actually readable. Applies a reader-first style rubric (TL;DR, expanded acronyms, "so what" synthesis, tables, citations) with a self-review loop. Use when the user asks for research, a deep-dive, an analysis doc, a competitive landscape, a market overview, a buyer/seller map, a strategic memo, or any document >2 screens.
---

# research — reader-first long-form documents

The default Claude style is optimised for chat and code (per user's `CLAUDE.md`). That style produces research docs that are information-dense but cognitively expensive to ingest: unexplained acronyms, tease-forward filler, bullet soup, no synthesis. This skill flips the optimisation — for long-form artifacts, **optimise for the reader re-reading**, not for brevity.

## When to use

**Use for:**
- Research reports ("research X", "deep-dive on Y", "state of Z")
- Market / competitive landscape analyses
- Buyer / customer / TAM maps
- Strategic memos
- Design docs (> ADR-sized)
- Any document the user will re-read, share, or search through
- Anything the user says should be "a full writeup"

**Don't use for:**
- ADRs (use a separate ADR template if needed — shorter, more structured)
- Code review writeups (conversational concision is correct)
- README / module docs (use `/init`)
- PR descriptions
- Chat answers, however long

## Attended vs unattended mode

Research is **typically run in attended mode**. The scope is often ambiguous, and clarifying upfront saves a wasted draft.

### Attended (default)
Before drafting, ask the user (once, in one message, bundled):

1. **Scope bound** — how deep? e.g. "10 sources and a 1-page doc", "exhaustive, 10+ pages"
2. **Audience** — for you alone? for a colleague? for investors? changes reading level and jargon assumption
3. **Decision orientation** — is this informing a specific decision ("should I buy X?") or general mapping? Doc structure changes accordingly
4. **Sources preference** — any sources they trust / distrust / require? (e.g. prefer primary sources, avoid specific outlets)
5. **Output format** — single markdown file? companion diagrams? tables preferred?

If these are already obvious from the request, skip — don't ask just to ask.

### Unattended (under `/unattended`)
Do not block on clarifying questions. Pick reasonable defaults, log them to `DEV-LOG.md` per the unattended skill, and proceed. Bias toward:
- Scope: medium (5–15 sources, 2–4 pages)
- Audience: the user themselves, technically fluent
- Decision-oriented if any hint of a decision exists
- General-purpose reputable sources (official docs, well-cited analyses, primary regulators, FT/Economist/academic)

## Source-gathering

Before drafting, make an explicit sourcing plan. Write it down (at the top of the draft file, to be deleted before presenting).

Tools:
- `WebSearch` for discovery
- `WebFetch` to read specific pages
- For paywalled / gated content, note the gate rather than fabricating

Track sources as you go in a `## Sources` section at the bottom of the draft. Every claim that isn't common knowledge gets an inline footnote marker `[^n]` pointing to that section.

**Fabrication check**: never cite a source you haven't actually fetched. If a source is cited from training-data recall rather than a fresh fetch, flag it explicitly or re-fetch.

## Output location

Save to `scratchpads/research-<topic>.md`. Examples:
- `scratchpads/research-london-smb-acquisitions.md`
- `scratchpads/research-rcm-vendors-uk.md`

If the user later asks to iterate, re-read from the file. Don't regenerate from scratch.

For very long research (>2000 words), split by theme into `scratchpads/research-<topic>-<theme>.md` with an `index.md` linking them. Keeps each file scannable.

## The rubric — apply while drafting, not retroactively

**Every document must have:**

### 1. TL;DR at top
- Exactly one `## TL;DR` section at the top, before the table of contents
- 3–5 bullets, each a **standalone finding** (not "we looked at X" / "this report covers Y")
- Each bullet ≤ 20 words
- Good bullet: `- Compliance & Risk is the highest-paying buyer segment — banks/insurers pay £20-100K/yr for RCA enrichment`
- Bad bullet: `- We analyzed the compliance sector`

### 2. Glossary on first mention
- Every acronym, piece of jargon, or domain term gets **expanded inline the first time it appears**, in the form: `SDE (Seller's Discretionary Earnings — the owner's total take-home from the business)`
- Subsequent mentions use the acronym freely
- If >10 terms, add a dedicated `## Glossary` section at the top and reference-link them

### 3. "So what" at the end of every top-level section
- Every `##` section ends with a single italicised line starting with `**So what:**`
- Must be decision-oriented or synthesis, not summary
- Good: `**So what:** Use SDE for deals under £2M; switch to EBITDA once working capital and financing assumptions matter.`
- Bad: `**So what:** SDE and EBITDA are different.`

### 4. Tables for comparisons
- Any `X vs Y` content becomes a markdown table, not bullets
- Any `>2 items with shared attributes` becomes a table
- Columns should be the attributes; rows the items
- Never nest bullets 3+ levels deep — that's a table in disguise

### 5. Concrete ↔ abstract oscillation
- After any abstract claim, give a concrete example within 2 lines
- After any concrete example, name the principle it illustrates
- Abstract-only paragraphs are a smell; concrete-only paragraphs are a smell

### 6. Citations inline, sources at end
- Every non-obvious claim ends with `[^n]`
- Collect sources at the end under `## Sources`:
  ```
  [^1]: Title — URL — 2026-04
  [^2]: ...
  ```
- Include fetch date for any web source (they rot)

### 7. No tease-forward filler
- **Banned phrases** (delete, don't replace):
  - "informs [later section]"
  - "sets the stage for"
  - "provides context for"
  - "plumbing for"
  - "the foundation of"
  - "cornerstone of"
  - "lays the groundwork"
- If a sentence promises value rather than delivering it, delete the sentence
- If a section exists only to set up a later section, cut it and inline the necessary facts

### 8. Progressive disclosure in structure
- `H1` = topic (one per document)
- `H2` = key finding or key decision point (not "Background", "Overview" — those are tease sections)
- `H3` = supporting detail under each finding

If a section's H2 is "Introduction", "Overview", "Background", "Context" — rewrite it so the heading is an actual finding.

### 9. Length discipline
- No single section > 400 words without sub-sections
- No document >4 pages without a navigation / index section
- If hitting length, split by theme across multiple files

## Dating

Always date the report. Two pieces:

- **Created** at the top of the document — full ISO date (YYYY-MM-DD).
- **Last updated** as a small subsection right under the header — same format, plus a one-line note on what changed if it's a substantive revision.

Reason: research goes stale fast, and a reader returning weeks later needs to know whether the snapshot is still load-bearing. Don't make them open `git log` to find out.

When updating an existing report, bump **Last updated** to today's date and add a brief change note. If the document was created today, omit the **Last updated** subsection until there's a real revision.

## Draft template

```markdown
# <Topic> — <angle or decision>

**Audience:** <who>
**Scope:** <bounds>
**Created:** <YYYY-MM-DD>

> **Last updated:** <YYYY-MM-DD> — <one-line summary of what changed>
>
> *(omit this block if today is the creation date)*

## TL;DR

- Finding 1
- Finding 2
- Finding 3
- Finding 4 (optional)
- Finding 5 (optional)

## Glossary (if >10 terms)

- **SDE** — Seller's Discretionary Earnings...
- **EBITDA** — Earnings Before Interest, Tax, Depreciation, Amortisation...

## <H2 — first finding / decision>

<concrete-abstract paragraph>

<optional table>

**So what:** <decision-oriented synthesis>

## <H2 — second finding / decision>

...

**So what:** ...

## Open questions

- <things you couldn't resolve with available sources>

## Sources

[^1]: ...
[^2]: ...
```

## Self-review loop

After drafting, before presenting, **read your own output back** and score against the rubric. Be blunt.

Checklist:
- [ ] TL;DR present, ≤5 bullets, each a standalone finding
- [ ] All acronyms expanded on first mention
- [ ] Every `##` section ends with `**So what:**`
- [ ] At least one table (if content warrants — most research docs do)
- [ ] At least 3 inline citation markers, all matching footnotes
- [ ] No banned tease-forward phrases (search for "informs", "sets the stage", "plumbing for", "foundation")
- [ ] No `##` headings named "Introduction", "Overview", "Background"
- [ ] No section > 400 words without sub-sections
- [ ] No nested bullets >2 levels deep

Grep-check your own draft:
```
rg -i 'informs|sets the stage|plumbing for|lays the groundwork|cornerstone|foundation of' scratchpads/research-<topic>.md
```

If any rubric fails, fix before presenting. If after 2 revision passes it still fails, present with a flag: "I was unable to hit the rubric for reasons X; here's what I have".

## Integration with other skills

### `/unattended`
- Research is normally attended, but if `/unattended` is active, skip clarifying questions
- Log scope decisions to `DEV-LOG.md`
- Keep drafting and delivering — don't block waiting for user on ambiguous scope
- Before final delivery under unattended, run an extra self-review pass since no human reviewed the scope

### `/diagram`
- If the data shape warrants a visual (quadrant, matrix, network, flow), invoke `/diagram` and embed the result
- Especially useful for: buyer/seller maps, competitive landscapes, decision trees, timelines
- Embed in the doc via markdown image: `![Buyer segments](./research-<topic>-diagram.png)`
- Don't force a diagram if the content is purely prose

### `tmux-cowork`
- Not usually needed — `WebSearch` / `WebFetch` are fast
- If doing programmatic scraping or batch source-gathering, push to tmux

## Common failure modes

| Symptom | Cause | Fix |
|---|---|---|
| Reader needs a glossary tab open | Acronyms not expanded on first use | Apply rubric #2 — find first mention of each term, expand it |
| Reads like minutes ("we looked at X, then we looked at Y") | Progress narrative instead of findings | Rewrite `H2`s as findings; remove "we looked at" framing |
| Wall of bullets, can't find the point | No synthesis | Add `**So what:**` per section; promote synthesis bullets to prose |
| Same idea repeated at different abstraction levels | Mid-altitude stuck | Apply rubric #5 — pair abstract claims with concrete examples |
| Claims without sources | Training-data recall dressed as research | Fetch real sources; flag unverified claims explicitly |
| Section #1 is "Background" / "Introduction" | Tease-section habit | Rename H2 to the actual finding; merge or delete intro |
| "This report will cover..." opener | Self-referential meta-paragraph | Delete it; the TL;DR does this job |
| Tables missing, bullet matrices instead | Defaulted to bullets | Anything with repeated attributes → table |

## Tone

Reader-first doesn't mean wordy. It means every word is load-bearing. Cut filler, keep scaffolding. A reader should be able to:
1. Get the core finding from TL;DR in 30 seconds
2. Find a specific sub-finding via skimming `##` headings in 10 seconds
3. Trust a claim by clicking a footnote in 1 click
4. Walk away with a decision, not just information

If the doc doesn't serve those four reader behaviours, the rubric failed somewhere.
