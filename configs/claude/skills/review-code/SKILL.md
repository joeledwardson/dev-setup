---
name: review-code
description: Junior-dev comprehension check on changed code. Per-file design review (role, assumed knowledge, wheel-reinvention), per-unit logic review (WHAT/WHY/LOGIC/SIMPLER), then a holistic diff review. Does NOT modify code.
---

# review-code

**What**: Three passes on every file changed since `main` — file-level design, unit-level logic, then the full diff as one.
**Why**: Claude reviews its own code with full project context. A stateless external call with no prior context catches what the author normalises away: unclear responsibilities, hidden assumptions, wheel-reinvention.

---

## Trigger

```
/review-code
/review-code path/to/specific/file.go
```

Without an argument: all files changed or added since `main`.

---

## Scope

```bash
git diff --name-only main..HEAD
git status --short | grep '^?? ' | awk '{print $2}'
```

Supported: `.go`, `.py`, any source file with recognisable structure.
Skip: generated files (`*.pb.go`, `*_generated.go`, `docs/grading/api/`).

---

## What counts as a unit

| Language | Units |
|----------|-------|
| Go | Each top-level `func` (including methods) |
| Python | Each `def` and `class` at module level |
| Any file, no recognisable structure | Whole file as one unit |

Claude identifies units by reading — no external parser.

---

## Pass 0 — architectural sweep (full codebase)

One `llm` call against all source files. Runs before per-file passes to establish architectural context.

```bash
find . -type f \( -name "*.go" -o -name "*.py" -o -name "*.ts" -o -name "*.tsx" \) \
  -not -path "*/vendor/*" -not -path "*/.git/*" -not -path "*/node_modules/*" \
  -not -name "*.pb.go" -not -name "*_generated.go" \
  | sort | xargs -I {} sh -c 'echo "=== {} ==="; cat {}' \
  | llm -m gemini-2.5-pro 'ARCH_PROMPT'
```

**ARCH_PROMPT**:

```
You are a senior architect reviewing this entire codebase cold. You have NOT worked on this project before.

Answer 5 questions. No code. Be specific — name files and functions where relevant.

ARCHITECTURE_INTENT:
  One paragraph: what architectural pattern does this codebase appear to be following?
  Name the layers and boundaries you can identify.

DRIFT:
  NONE — or — FLAG: any file or package that has drifted from the architectural pattern above.
  Specifically: what layer does it CLAIM to be in vs what layer is it ACTUALLY operating in?

CONSISTENCY:
  CLEAN — or — FLAG: the same problem solved differently in different parts of the codebase.
  Name the specific files and what pattern each uses.

COUPLING:
  CLEAN — or — FLAG: inappropriate dependencies between layers or modules.
  What is reaching into what it shouldn't? Be specific about file and function names.

ORPHANED:
  NONE — or — FLAG: code left over from a previous design iteration — abstractions with one
  implementer, interfaces nobody uses, patterns not followed elsewhere.
```

---

## Pass 1a — per-file: holistic design critique

One `llm` call per file. No checklist — asks whether the overall design approach is right.

```bash
{ echo 'DESIGN_PROMPT'; cat <file>; } | llm -m gemini-2.5-flash
```

**DESIGN_PROMPT** (substitute `<FILENAME>`):

```
You are a senior developer who has just read this file cold — no prior context about the project.

Design critique only. Answer 3 questions. No code.

File: <FILENAME>

INTENT: One sentence — what problem is this file solving?

CLEAN_ROOM: You are designing this from scratch, no constraints from the existing code.
In 3–4 sentences: what responsibilities would it own, what would it NOT own, and what
would the key design choices be?

DIVERGENCE: What is the single biggest difference between your clean-room design and what
actually exists? If the current design is reasonable, say so and why. If something
fundamental should be rethought, say what specifically.
```

---

## Pass 1b — per-file: rules checklist

Second `llm` call on the same file. Fine-grained checks for specific problems.

```bash
{ echo 'RULES_PROMPT'; cat <file>; } | llm -m gemini-2.5-flash
```

**RULES_PROMPT** (substitute `<FILENAME>`):

```
You are a junior developer reading this file for the first time.
Answer 7 questions. Do NOT write code. Do NOT suggest rewrites.
Put each answer on its own line, with a blank line between each.

File: <FILENAME>

WEAK_CONTRACTS:
  NONE — or — FLAG: any caller/callee boundary weaker than the signature suggests:
  - unused parameters, or parameters derivable from others already passed
  - struct passed when only one field is used; any/string where a narrower type would compile-enforce the contract
  - indirection (interface, wrapper, extra layer) with no comment explaining why it exists

TEST_CONTRACTS:
  NONE — or — FLAG: anything a reader must verify outside this file to trust the test:
  - fixture values with no comment on whether they're placeholders or meaningful
  - fields documented as "recorded for assertion" where nothing asserts
  - hardcoded slices when an authoritative constant/map exists to range over
  - unclear function→seam→control link: which step is controlled by what in the fake?
  Diagnostic: can a reader verify the test's intent without leaving this file?

COMPONENTS:
  CLEAR  — or —  FLAG: any function/class whose scope is unclear or overlaps another

SCOPE:
  CLEAR  — or —  FLAG: is the file doing more than one job? one function carrying most of the weight?

DEPTH:
  CLEAN  — or —  FLAG: functions with 3+ nesting levels, complex returns, or branching that obscures the happy path

NAMING:
  CLEAN  — or —  FLAG: any name that surprised you when you read the body. Also flag:
  - test fixtures named informally (canned, dummy, fake, stub) with no comment on what they simulate
  - fields named with generic suffixes (idx, cursor, counter, flag) inside structs where the
    state machine or protocol they implement is not explained

REINVENTING:
  NO  — or —  FLAG: anything here that exists in the standard library, a well-known ecosystem
  library, or already elsewhere in this project — including test utilities, string manipulation,
  file handling, HTTP helpers, and retry/polling logic. Also flag:
  - hardcoded string/int slices in tests when a canonical authoritative source (map, constant,
    enum) already exists in the codebase and could be ranged over instead

SHADOWS:
  NO  — or —  FLAG: any function/method that accepts a parameter with the same name as an instance attribute
  or outer-scope variable — flag if it's not immediately obvious why both exist

SIMPLER:
  NO  — or —  FLAG: a fundamentally simpler approach to what this file does — one sentence, no code
```

---

## Pass 2 — per-unit logic review

One `llm` call per function/class. Asks whether each unit makes sense in isolation.

```bash
{ echo 'UNIT_PROMPT'; cat <file>; } | llm -m gemini-2.5-flash
```

**UNIT_PROMPT** (substitute `<NAME>` and `<LINE>`):

```
You are a junior developer reading this code for the first time.
Your ONLY job is to answer 4 questions about one function.
Do NOT write code. Do NOT refactor. Do NOT suggest changes.
Put each answer on its own line, with a blank line between each.

Focus on `<NAME>` starting around line <LINE>.

WHAT:
  one sentence — what it does and what it returns. Say so if unclear.

WHY:
  one sentence — why does it exist separately? what breaks if inlined or removed?

LOGIC:
  CLEAR  — or —  FLAG: which step confused you and why

SIMPLER:
  NO  — or —  YES: one sentence describing a simpler approach, no code
```

---

## Pass 3 — holistic diff review

One call with the full diff after all per-file and per-unit passes.

```bash
{ echo 'HOLISTIC_PROMPT'; git diff main..HEAD; } | llm -m gemini-2.5-flash
```

**HOLISTIC_PROMPT**:

```
You are a junior developer who has just read a code diff.
Your ONLY job is to answer 3 questions. Do NOT write code.

COHERENT:  <CLEAR — or — FLAG: do the changes hang together as one coherent unit of work? what seems inconsistent?>
COMPLETE:  <CLEAR — or — FLAG: is anything obviously missing from what the diff seems to be trying to do?>
SURPRISES: <NONE  — or — FLAG: any file or change that doesn't fit with the rest?>
```

---

## Filter

Write to report only if **any answer across all passes contains FLAG or YES**.
All clear → print `review complete — no flags`, write nothing.

---

## Output

`docs/appendix/reviews/YYYY-MM-DD-<basename>.md`:

```markdown
# Code Review — path/to/file.go
_YYYY-MM-DD · gemini-2.5-pro (arch) + gemini-2.5-flash (file/unit/diff)_

---

### Architectural (full codebase)

ARCHITECTURE_INTENT: layered service/repo pattern with clear domain boundary
DRIFT:       FLAG: internal/scoring/gemini.go is making HTTP calls — that belongs in the adapter layer
CONSISTENCY: FLAG: error wrapping uses fmt.Errorf in some files, errors.Wrap in others
COUPLING:    CLEAN
ORPHANED:    FLAG: internal/legacy/parser.go — no callers, predates current pipeline

---

---

### File-level

FILE_ROLE:   CLEAR
ASSUMED:     FLAG: caller must know `scorer.Weights` sums to 1.0 — tested but not explained here
COMPONENTS:  CLEAR
REINVENTING: FLAG: walk-up .env parser duplicates logic already in cmd/grade/main.go
SIMPLER:     NO

---

### `parseResponse` — line 121

WHAT:    Extracts structured criterion scores from Gemini's raw JSON text.
WHY:     CLEAR
LOGIC:   FLAG: the fence-stripping step is defensive but the trigger condition is unexplained
SIMPLER: NO

---

### Holistic

COHERENT:  CLEAR
COMPLETE:  FLAG: diff adds a new error path in GradeVideo but cmd/grade doesn't handle the new error type
SURPRISES: NONE
```

Append a row to `docs/appendix/reviews/index.md`.

---

## Do not commit

Leave review output unstaged. User reads the diff and decides what to act on first.

---

## Model

`gemini-2.5-pro` — Pass 0 only. Full codebase fits in 1M context; Pro's reasoning is needed for
architectural drift detection where Flash misses cross-file patterns.

`gemini-2.5-flash` — Passes 1a, 1b, 2, 3. Strong enough to know language idioms (t.TempDir,
dataclass, etc.) without filling in gaps the author left. Flash-lite missed too many stdlib patterns.

`llm models | grep gemini` to verify aliases. Do NOT use the `gemini` agentic CLI.

---

## Does NOT

- Modify any code
- Run automatically
- Commit output
- Review generated files or docs API reference pages
