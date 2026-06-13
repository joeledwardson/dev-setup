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

