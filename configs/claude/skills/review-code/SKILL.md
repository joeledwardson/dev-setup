---
name: review-code
description: Junior-dev comprehension check on changed code. Per-file design review (role, assumed knowledge, wheel-reinvention), per-unit logic review (WHAT/WHY/LOGIC/SIMPLER), then a holistic diff review. Does NOT modify code.
---

# review-code

**What**: Three passes on every file changed since `main` — architectural sweep of the full codebase, per-file design + unit review, then the full diff as one.
**Why**: Claude reviews its own code with full project context. A stateless external call with no prior context catches what the author normalises away: unclear responsibilities, hidden assumptions, wheel-reinvention. Tool choice per pass matches the intended reviewer's information access.

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
git status --short | grep '^?? '
```

Supported: `.go`, `.py`, any source file with recognisable structure.
Skip: generated files (`*.pb.go`, `*_generated.go`, `docs/grading/api/`).

---

## Pass 0 — architectural sweep (full codebase, gemini CLI)

Run from project root. Gemini reads the codebase natively — no piping needed.

```bash
gemini -p 'ARCH_PROMPT'
```

**ARCH_PROMPT**:

```
Read all source files in this project (excluding vendor/, node_modules/, generated files like *.pb.go and *_generated.go).
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

## Pass 1 — per-file: design + rules (Gemini Flash, isolated)

One call per changed file. Uses `llm -a` — model sees only this file, enforcing the cold-read frame.

```bash
llm -m gemini-2.5-flash 'FILE_PROMPT' -a <file>
```

**FILE_PROMPT** (substitute `<FILENAME>`):

```
You are a senior developer and junior developer reading this file cold — no prior context about the project.
Answer all questions below. No code. File: <FILENAME>

--- DESIGN ---

INTENT: One sentence — what problem is this file solving?

CLEAN_ROOM: You are designing this from scratch, no constraints from the existing code.
In 3–4 sentences: what responsibilities would it own, what would it NOT own, and what
would the key design choices be?

DIVERGENCE: What is the single biggest difference between your clean-room design and what
actually exists? If the current design is reasonable, say so and why.

--- RULES ---

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

SCOPE:
  CLEAR — or — FLAG: is the file doing more than one job? one function carrying most of the weight?

DEPTH:
  CLEAN — or — FLAG: functions with 3+ nesting levels or branching that obscures the happy path

NAMING:
  CLEAN — or — FLAG: any name that surprised you when you read the body. Also flag:
  - test fixtures named informally with no comment on what they simulate
  - fields named with generic suffixes (idx, cursor, counter, flag) where the state machine is unexplained

REINVENTING:
  NO — or — FLAG: anything here that exists in the standard library, a well-known ecosystem
  library, or already elsewhere in this project — including test utilities, retry/polling logic,
  string manipulation, file handling, HTTP helpers.

SIMPLER:
  NO — or — FLAG: a fundamentally simpler approach to what this file does — one sentence, no code
```

---

## Pass 2 — per-file: unit logic review (Gemini Flash, isolated)

One call per changed file covering all units. Uses `llm -a` — model sees only this file.

```bash
llm -m gemini-2.5-flash 'UNIT_PROMPT' -a <file>
```

**UNIT_PROMPT** (substitute `<FILENAME>`):

```
You are a junior developer reading this code for the first time.
File: <FILENAME>

For EACH top-level function, method, class, or def in this file, answer 4 questions.
Emit the unit name as a header before each set of answers.
Do NOT write code. Do NOT refactor.

WHAT:  one sentence — what it does and what it returns. Say so if unclear.
WHY:   one sentence — why does it exist separately? what breaks if inlined or removed?
LOGIC: CLEAR — or — FLAG: which step confused you and why
SIMPLER: NO — or — YES: one sentence describing a simpler approach, no code
```

---

## Pass 3 — holistic diff review (Gemini Flash)

One call with the full diff after all per-file passes.

```bash
git diff main..HEAD | llm -m gemini-2.5-flash 'HOLISTIC_PROMPT'
```

**HOLISTIC_PROMPT**:

```
You are a junior developer who has just read a code diff.
Your ONLY job is to answer 3 questions. Do NOT write code.

COHERENT:  CLEAR — or — FLAG: do the changes hang together as one coherent unit of work? what seems inconsistent?
COMPLETE:  CLEAR — or — FLAG: is anything obviously missing from what the diff seems to be trying to do?
SURPRISES: NONE  — or — FLAG: any file or change that doesn't fit with the rest?
```

---

## Filter

Write to report only if **any answer across all passes contains FLAG or YES**.
All clear → print `review complete — no flags`, write nothing.

---

## Output

`docs/appendix/reviews/YYYY-MM-DD-<basename>.md` — one file per review run.

Structure: **Architectural** section (Pass 0), then per file: **File** and **Units** subsections together, then **Holistic** section (Pass 3). Append a row to `docs/appendix/reviews/index.md`. Leave unstaged.

---

## Models

- Pass 0: `gemini` CLI — native filesystem access, full 1M context for cross-file architectural analysis
- Pass 1, 2: `llm -m gemini-2.5-flash` — isolated single-file calls, cold-read frame enforced via `-a`
- Pass 3: `llm -m gemini-2.5-flash` — diff piped via stdin, no filesystem access needed
