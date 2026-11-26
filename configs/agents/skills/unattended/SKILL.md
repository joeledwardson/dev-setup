---
name: unattended
description: Switch to unattended/solo mode for research and long-running tasks. Push through friction instead of pausing. Only invoked on explicit /unattended — never auto-load.
disable-model-invocation: true
hooks:
  PostToolUse:
    - matcher: "Edit|Write|MultiEdit"
      hooks:
        - type: command
          command: |
            printf '%s' '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"After writing code run /review-code, after updating documentation run /review-docs. Maximum 2 iterations where feedback is given."}}'
---

# unattended — push through, don't wait

**What**: Operating mode for tasks where the user isn't watching. Default to doing rather than asking.
**Does NOT**: remove all judgement — stop for credentials, destructive ops, paid resources, scope explosions.

---

## Before starting — plan phase

Before writing a single line of code, produce a plan and show it to the user:

```
## What I understood
<one paragraph — restate the task in your own words>

## Structure I'll create
- file or package: What it does / In: inputs / Out: outputs
- file or package: What it does / In: inputs / Out: outputs

## Tests I'll write first
- TestBehaviour_Condition: what this proves (one per behaviour, not per function)

## Does NOT (explicit scope boundary)
- <what I'm deliberately not building>

## Unknowns
- <anything that needs a decision before I start>

Ready to start — say "go" to proceed, or correct anything above.
```

Wait for confirmation unless the user explicitly said to skip review ("just do it", "no review needed").

---

## Default stance

Normal mode: "ask if unsure" → unattended mode: "act if unsure, log what you chose".

When ambiguous, pick the less-destructive option, record it in the log, keep going. User reviews on return.

---

## Worked examples

1. **Found a problem in a dependency** → clone it, reproduce locally, patch via fork or vendor. Don't stop.
2. **"The fix is done"** → not yet. Write/update tests, run the full suite, exercise end-to-end. Then it's done.
3. **Architectural decision A vs B** → research official docs, pick the simplest option. If still unclear, implement both on branches, compare empirically. Log the comparison.
4. **Need to install a tool** → install it. Use Nix on NixOS boxes. Don't ask permission for dev tools.
6. **Stuck on a task** → time-box it. If budget runs out, write up the blocker clearly and move to next task.

---

## Guardrails — when to stop

- **Credentials / auth** — need a password, token, or 2FA. Don't guess.
- **Destructive on shared state** — force-push, drop prod database, rewrite published history.
- **Paid operations** — anything that costs real money. Estimate first, log, ask.
- **Scope explosion** — "fix this bug" turns into "rewrite this subsystem". Stop, log, let user decide scope.
- **Truly ambiguous intent** — two plausible readings with materially different outcomes. Pick less-destructive, ask.
- **Repeated failure** — same approach failed 3+ times. Stop, log, try a different angle or wait.

---

## Time-boxing

- Single bug: ~2 hours before parking
- Architectural experiment: ~1 day per branch
- Research: ~30 min reading before prototyping

Log when you exceed budgets. Don't pretend you didn't.

---

## Vibe coding — preventing drift and bloat

**Spec-first.** Write what a file does, what goes in, what comes out — before writing the file. If AI generates something not in the spec, delete it.

**Spec comments on every exported function — required, not optional.** Every exported function must have: one-line summary of what it does, `// In: param — description` for each non-obvious parameter, `// Out: what is returned and under what condition`. This is the function's contract, not decoration. If you can't write it in 3 lines, the function is doing too much.

**Stdlib and ecosystem first — never reinvent.** Before writing any utility function, ask in order: (1) does the stdlib have this? (2) is there a canonical library in this ecosystem? (3) is this logic already written elsewhere in this codebase? First yes wins — use it. Re-implementing `.env` parsing, string repetition, path walking, or JSON decoding when a library exists is always a bug, not a shortcut.

**The 3-caller rule.** No helper function unless it has 3 call sites. One call site = inline it.

**File length trigger.** File exceeds ~250 lines → something gets deleted or split. Use it as a review prompt, not a hard limit.

**End-of-session deletion pass.** `git diff --stat` before committing. Any file that grew >50 lines needs to justify each addition.

**No abstraction without 2 implementations.** No interface or wrapper until 2 concrete things use it.

**Error handling at boundaries only.** Validate at system edges (user input, API responses). Trust internal code.

**Tests prove behaviour, not implementation.** Name each test after what it proves (`TestX_WhenYThenZ`). One assertion. If test setup is longer than the function being tested, something is wrong — either split the function or simplify the test.

---

## The log

Append to the current month's dev log file, `docs/dev-log/YYYY-MM.md` (there is no root `DEV-LOG.md`). One entry per meaningful event:

```
## YYYY-MM-DD HH:MM — title
Context: what I was doing
Action: what I did / chose
Why: reasoning in one or two sentences
Result: outcome, test evidence, next step
```

Log decisions, blockers, pivots, completions. Not every bash command.

---

## Review loop — after writing

After completing any code changes, invoke `/review-code` and act on every flag it raises.
After updating any documentation (`.md` files), invoke `/review-docs` on the changed pages and act on every flag it raises.

**Two review cycles maximum per task.** Fix all flags, re-run the review once. If flags remain after the second cycle, log them in the dev log and move on — do not loop indefinitely.

---

## Documentation

For anything beyond a top-level README, use mkdocs. Full setup in the **`documentation` skill**.

Run `mkdocs serve` in a named cowork pane (`<project>-docs`), bound on the project port block.

---

## Push notifications — be verbose

Fire notifications at semantic milestones via `ntfy.sh` (token at `/run/agenix/ntfy-token`, topic `jollof-claude`):

```sh
TOKEN=$(cat /run/agenix/ntfy-token)
curl -sS -u ":$TOKEN" \
  -H "Title: <project> @ <hostname>: <summary>" \
  -H "Tags: <emoji>" -H "Priority: <1-5>" \
  -d "<body>" https://ntfy.sh/jollof-claude >/dev/null
```

| Event | Tag | Priority |
|---|---|---|
| Starting a batch | `rocket` | 3 |
| Task complete | `white_check_mark` | 3 |
| Blocker (still working around it) | `warning` | 3 |
| Stopped — need user input | `octagonal_sign` | **4** |
| Non-obvious autonomous decision | `thinking` | 3 |
| Finished all tasks | `checkered_flag` | 3 |

Title: lead with `project @ hostname` so multi-session notifications are scannable on a phone.

---

## Commits in unattended mode

Commit frequently in small logical units. The user reviews via `git log`, not by watching.

- **DO** commit work you produced, safe hygiene (gitignore, lockfiles you regenerated)
- **DO NOT** commit pre-existing uncommitted changes that were there when you started
- **DO NOT** push unless explicitly asked
- **DO NOT** amend commits that aren't yours

**Exception — after `/review-functions`**: do NOT commit. Leave the review file and index update unstaged. The user reads the diff and decides what to act on first.

---

## Desktop automation

When a task needs headful interaction — UI testing, visual verification, driving a browser — see the **`desktop-automation` skill**.

---

## On finishing

1. Log what completed and what's parked
2. List blockers with proposed resolutions
3. Stop — don't invent work to stay busy
