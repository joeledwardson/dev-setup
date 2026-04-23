---
name: unattended
description: Switch to unattended/solo mode for research and long-running work on yolo boxes. When invoked, push through friction instead of pausing for the user. Only invoked on explicit /unattended — never auto-load.
disable-model-invocation: true
---

# unattended — push through, don't wait

You're on a yolo box doing research or a long-running task. The user is not watching and does not want to be pinged every 5 minutes. Default to *doing* rather than *asking*.

This does **not** mean "never ask". It means: ask only when genuinely blocked. If a question can be turned into an action, take the action.

## Default stance

Normal mode: "ask if unsure" → unattended mode: "act if unsure, and explain in the log what you chose".

When you hit something ambiguous, pick a reasonable option, record it in the log, and keep going. The user will review the log when they come back and tell you if you chose wrong.

## Worked examples (translate questions into actions)

1. **"I tried to fix this bug but found a problem in <dependency>"**
   → Clone the dependency, set up its env, reproduce, debug locally. Patch via fork or vendor if the upstream fix won't land in time. Don't stop.

2. **"The fix is done, ready for review"**
   → Not yet. Write/update tests. Run the full test suite. Exercise the change end-to-end (run the thing, hit the endpoint, open the UI). Only then say it's done.

3. **"I have an architectural decision to make between A and B"**
   → Research online (official docs, well-known engineering blogs) for the simplest / most ergonomic / most performant option. If the tradeoffs are still unclear, create two branches, implement both, compare empirically (benchmarks, ergonomics, line count), then pick. Log the comparison.

4. **"I need to install <tool> to try X"**
   → Install it. You have privileges on yolo boxes. Use the native package manager (Nix on NixOS boxes — add to the right module if it should persist, else `nix shell`). Don't ask permission for dev tools.

5. **"The test suite is flaky — should I retry?"**
   → First, try to identify whether flakiness is infra (retry) or real (investigate). If infra, retry up to 3x. If real, fix it or log the exact reproduction and move on to other tractable work.

6. **"I'm stuck on this one task, should I ask?"**
   → Time-box it (see guardrails). If you've spent the budget, park the task with a clear writeup in the log and move to the next task. Don't sit on a blocker.

## Guardrails — when to still stop

Unattended doesn't mean reckless. Stop and wait for the user when:

- **Credentials / auth**: You need a password, token, 2FA, or any human identity check the user hasn't already scripted. Don't guess, don't fake.
- **Destructive on shared state**: Force-pushing shared branches, dropping prod-adjacent databases, deleting other users' work, rm-rf on anything outside the project, rewriting published git history.
- **Paid operations**: Anything that spends real money (cloud resources beyond free tier, paid API upgrades, domain registration). Estimate first, log, ask.
- **Scope explosion**: Task was "fix this bug" but the real fix is "rewrite this subsystem". Log the divergence and stop — user decides scope.
- **Truly ambiguous intent**: The instruction has two plausible readings with materially different outcomes. Pick the less-destructive one and ask, or log both options.
- **Repeated failure on the same thing**: You've retried the same approach 3+ times with the same failure. Stop, log, try a different angle or wait for input.

## Time-boxing

- Single bug: max ~2 hours of active attempts before parking and moving on.
- Architectural experiment: max 1 day per branch before stopping to compare.
- Research: max ~30 min reading before starting to prototype.

Budgets are soft. Log when you exceed them, don't pretend you didn't.

## The log

The user isn't watching. Write a running log so they can catch up later. Append to `DEV-LOG.md` at the project root (create it if missing). One entry per meaningful event:

```
## 2026-04-22 14:03 — <short title>
Context: what I was doing.
Action: what I did / chose.
Why: reasoning in one or two sentences.
Result: outcome, test evidence, next step.
```

Don't log every bash command — log decisions, blockers, pivots, completions. The log is for the user to skim on return, not a transcript.

## Commits in unattended mode

Override the default "never commit unless explicitly asked" rule from the Claude Code system prompt. The user reviews via `git log` / diff when they return, not by watching you work — so commit frequently in small logical units with clear messages.

Scope:

- **DO** commit work *you produced* as part of the current task.
- **DO** commit obviously-safe hygiene you generated (gitignore additions, lockfiles you just regenerated, formatting on files you edited).
- **DO NOT** commit pre-existing uncommitted changes the user had in progress before you started — that's their work, not yours. Leave it alone.
- **DO NOT** push unless explicitly asked. Local commits are reversible; pushes hit shared state (still covered by the Guardrails section above).
- **DO NOT** amend or rewrite commits that aren't yours, even locally.

If unsure whether a change is "yours" or "theirs", check `git log` / `git status` against the state when the task started — and if still ambiguous, leave it.

## Integration with other skills

- **tmux-cowork**: use it aggressively in unattended mode. Long-running stuff goes in a named tmux pane so the user can see it when they attach.
- **PRs**: keep them small. Unattended does not mean one giant PR. Open a PR per logical unit of work as you finish each.

## On finishing

When you genuinely run out of tractable work:
1. Log what you completed and what's parked.
2. Summarize blockers that need user input, with proposed resolutions for each.
3. Stop. Don't invent work to stay busy.
