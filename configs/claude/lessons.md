# Lessons Learned

Accumulated patterns and anti-patterns. Each entry: what to notice → what to check → why it matters.

Read this before writing any utility, helper, external integration, or new abstraction.

---

## Explicit contracts over implicit ones

**The principle**: when correctness depends on knowledge that lives *outside the code* — in API docs,
tribal knowledge, or the caller's memory — that's an implicit contract. Make it explicit instead.

**Diagnostic**: can a reader verify correctness without leaving the file?
If they need to read external docs, find a matching handler elsewhere, or "just know" which values
are valid — the contract is implicit.

**Common forms and their fixes:**

| Implicit (fragile) | Explicit (enforced) |
|---|---|
| `map[string]any` with a known structure | define a typed struct |
| `if state == "processing"` | typed constant or enum |
| `data["skin_quality"]` map lookup | struct field access |
| HTTP payload built as raw map | typed request/response structs + doc link |
| `os.Getenv("MY_KEY")` scattered | single typed config struct loaded at startup |
| function takes `string` meaning "one of: a, b, c" | typed enum or interface |

**When you can't avoid implicit** (external API with no SDK, closed-source system):
use typed request/response structs with the API doc URL at the definition site.
That's the minimum — bring the implicit knowledge into the code itself.

**Example (Go, Kling API client):**
```go
// https://api.kie.ai/docs#createTask  ← doc link here
type klingCreateRequest struct {
    Model string         `json:"model"`
    Input klingTaskInput `json:"input"`
}
type klingTaskInput struct {
    ImageURLs []string `json:"image_urls"`  // field names compiler-checked
    Duration  string   `json:"duration"`    // string, not int — Kling requires it
}
```

---

## Silent contracts in test code

**The principle**: a test value, field, or comment that requires digging outside the file to
understand is a silent contract. It passes code review but breaks the next reader.

**Diagnostic**: can a reader verify the test's intent without leaving the file?

**Common forms:**

| Silent (fragile) | Explicit (self-contained) |
|---|---|
| `"test.mp4"` passed as a path arg with no comment | `const testVideoPath = "test.mp4" // placeholder — value irrelevant` |
| fake field `uploadedPath` with comment "so tests can assert" but no test does | assert on it or delete it |
| raw JSON string fixture that mirrors a real struct | comment that names the struct it simulates |
| hardcoded string slice `["skin_quality", …]` in test | range over the authoritative constant/map |

**Why it matters**: silent contracts compound — each one is minor, but three in a file means
a reader must hold a mental map of "which values matter and which don't" the whole time they read.

---

## Reinventing utilities

**The principle**: before writing any helper — env loading, file walking, retry logic, date parsing,
string manipulation, HTTP clients — stop and check in order:

1. Does the **stdlib** have this?
2. Is there a **canonical ecosystem library**?
3. Is it **already written in this codebase**?

First match wins. Write nothing.

**Diagnostic**: if the function you're about to write is shorter than a Google search query,
it almost certainly already exists.

**Classic examples by language:**

- Go `.env` loading → `github.com/joho/godotenv` (never hand-roll a walk-up parser)
- Go assertions in tests → `github.com/stretchr/testify`
- Python path handling → `pathlib` (never `os.path.join` chains)
- Python env loading → `python-dotenv` or `pydantic-settings`

**The duplication smell**: if you find the same utility written twice in a codebase, the third
instance is always wrong. Grep before you write.

---

## Test temp directories

**The principle**: use `t.TempDir()` in tests, never `os.TempDir()` (or `os.MkdirTemp`) directly.

**Why**: `os.TempDir()` returns the shared system temp directory (`/tmp`). Any directory you create
inside it persists after the test finishes — leftover state, parallel test collisions, disk accumulation.
`t.TempDir()` creates an isolated directory unique to that test run and deletes it automatically when
the test exits (pass or fail).

**Diagnostic**: grep for `os.TempDir()` or `os.MkdirTemp` in `_test.go` files — both are wrong.

```go
// wrong — leaks /tmp/myapp-test-output after every run
outDir := filepath.Join(os.TempDir(), "myapp-test-output")
os.MkdirAll(outDir, 0755)

// correct — cleaned up automatically
outDir := t.TempDir()
```

---

## DRY is about knowledge, not text

**The principle**: duplicating *text* is cheap; duplicating *knowledge* (a fact or decision that must
change in lockstep across places) is what DRY actually protects against. Deduplicate facts, not characters.

**Diagnostic**: "if this changes, how many places must change — and can they drift *silently*?"

- Two variants of a statement, adjacent (same function, < ~100 lines apart), each readable in full:
  **duplicate them**. A reader sees both; drift is caught on sight. Extract only at 3+ variants or
  once they stop being adjacent.
- The same *fact* stated in two systems (a hardcoded string in code that must match values in a DB
  table or external config): **knowledge duplication** — drifts silently, fails at runtime. The fix
  is not a shared constant; it's deriving the value from the canonical source.

| Looked like | Actually was | Right move |
|---|---|---|
| two near-identical SQL statements in an if/else | text duplication, adjacent | write both in full, psql-pastable — never mash fragments (`f"{base_sql} AND …{group_by}"`) |
| `DAMBLE_HUB88_OPERATOR = "damble_eu"` constant + comment warning that `"dambles"` returns 0 rows | knowledge duplication: the operator value lives in the rtps table AND in code | derive the lookup key from the row data (`operator_name`) — constant deleted, failure class gone |

**The tell**: a comment explaining why a literal must hold a specific value to match data living
elsewhere. That comment is the duplicated knowledge apologizing for itself — derive, don't restate.

---

## Use human language — NOT robotic

**The principle**: write docs and comments for a person reading them, not a spec sheet. Decode the jargon, cut long sentences in half, and illustrate with a concrete example instead of more abstract prose.

**Robotic word → plain English.** LLMs reach for vocabulary the reader then has to decode:

| Robotic (to avoid) | Plain English (to use) |
|---|---|
| high fidelity | nothing is lost / accurate |
| multimodal model | a model that reads text and images together |
| prose | the words / the writing |
| transcription | turning the picture into text |
| free-form caption | a chatty one-line description |
| leverage / utilise | use |
| "the categorisation of expected error" | "the expected category" |
| "frontmatter" (to a lay reader) | "the info at the top of the file" |

**Long sentence → short.** If a sentence has two "because" / "which means" / em-dashes, split it.

- ❌ "Highest fidelity: nothing is lost to a description step, so a subtle mismatch (the route diagram showing an 8-hour drive while the spec says 30 minutes) is visible to the same mind that reads the spec."
- ✅ "One model reads the words and the picture together. Most accurate — nothing is lost. Example: it sees the diagram says '8 hours' while the spec says '30 minutes'."

**Examples illustrate — they don't ramble.** A concrete example replaces a paragraph of abstraction. The example must carry the point.

- ❌ "Guard against its lossiness by prompting the vision model for a structured extraction rather than a free-form caption."
- ✅ "Prompt for a structured list, not a caption. Force the label `airport → 6 hours → hotel` so it can be checked against the spec's 'drive under 2 hours' and flagged."

**The tell**: if you would never say the sentence out loud to a colleague, rewrite it.

---

## Formatting: break the wall of text

**The principle**: this is as much about *shape on the page* as wording. Before shipping a paragraph, squint at it: does it read as a **wall of text** or as **short, scannable statements**? Good prose crammed into one dense block still reads badly. The fix is usually formatting, not rewriting.

**The devices** (Markdown / MDX):

| Use | For |
|---|---|
| a blank line between ideas | one thought per paragraph — let each breathe |
| a **bold lead** sentence | the claim, so a skimmer gets it without reading on |
| a `>` blockquote | a concrete example, set apart from the claim |
| a callout (`:::note` / `!!!`) | an aside or caveat (a "Downside", a "Catch") — lifts it out of the flow |

**Diagnostic**: three-plus sentences with no break, or a sentence carrying a claim *and* an example *and* a caveat at once → split it.

**Before → after** (real, from ADR 0003):

❌ One dense block:
> **Approach A — one model sees both.** A single model reads the words and the picture at once and judges them together. Most accurate, because nothing is lost turning the picture into words. Example: it can see the route diagram says "8 hours" while the spec says "30 minutes" — one mind, both facts. Downside: you swap the text model for a multimodal one, and you can't easily save-and-test what it "saw".

✅ Same words, broken to scan:
```markdown
**Approach A — one model sees both.** A single model reads words and picture together and judges them in one go.

Most accurate: nothing is lost turning the picture into words.

> **Example:** it sees the diagram says "8 hours" *and* the spec says "30 minutes" in one pass.

:::note Downside
Harder to tell what it actually "saw" in the image.
:::
```

Same sentences. The claim, the example, and the caveat each get their own line and their own visual weight — so the eye lands on the point instead of drowning in the block.
