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

## Desktop automation on NixOS + Hyprland

When a task truly needs headful interaction (testing web UIs, verifying click flows, reproducing a GUI bug, pasting an image into a running TUI), drive the desktop instead of asking the user. This is a yolo box — treat the desktop like any other tool.

### Session env (the SSH caveat — set this first)

If you're SSH'd in, `WAYLAND_DISPLAY` and `HYPRLAND_INSTANCE_SIGNATURE` are unset by default. `hyprctl` fails with "HYPRLAND_INSTANCE_SIGNATURE not set!", `wl-copy` / `wtype` fail silently. Export both once before anything else:

```sh
export WAYLAND_DISPLAY="$(ls /run/user/$(id -u)/ | grep -E '^wayland-[0-9]+$' | head -1)"
export HYPRLAND_INSTANCE_SIGNATURE="$(ls /run/user/$(id -u)/hypr/ | head -1)"
```

### The toolchain

- **`wtype`** — Wayland virtual-keyboard client. Keys, chords, text. No `uinput`, no root. Sends to whatever window currently has keyboard focus. Example: `wtype -M ctrl -p v -m ctrl` = Ctrl+V. Good default for typing/chords.
- **`hyprctl dispatch sendshortcut KEY,CHAR,class:^(foo)$`** — fires a key chord at a window selected by class/title regex, **bypasses focus entirely**. Prefer this over `wtype` when you know the target. Example: `hyprctl dispatch sendshortcut "CTRL,V,class:^(kitty)$"`.
- **`ydotool`** — uinput-level dispatcher. Needed for mouse (clicks, moves, drags) and when a key event has to look like real hardware. Requires `ydotoold` running (usually is) **and** your user in the `ydotool` group — the socket is `0660 root:ydotool`. If you see `failed to connect socket '/run/ydotoold/socket': Permission denied`, stop: check `id` / `getent group ydotool`. For keys only, fall back to `wtype` or `sendshortcut`. For clicks, there's no non-root fallback — ask the user. Button code `0xC0` = left click.
- **`hyprctl dispatch`** — Hyprland's IPC for window actions: `focuswindow`, `movewindow`, `workspace`, `togglefloating`, `closewindow`, `exec` (with `[float; size W H; center]` prefix for rule injection). Not for arbitrary pixel clicks.
- **`hyprctl clients -j`** / **`hyprctl activewindow -j`** — JSON view of the window tree. Locate by class/title *before* acting, rather than guessing coordinates. Gotcha: `activewindow` returns `Invalid` when no window has keyboard focus (common right after a headless `dispatch exec`) — not a bug, just means no seat focus yet.
- **`hyprshot`** — convenience screenshot tool. `-m window -m active` for active window, `-m region` for a rect, `-m output` for full screen. Fails with `invalid geometry` if `activewindow` is Invalid — fall back to `grim`.
- **`grim`** — raw wlroots screenshot, no window-state dependency. `grim /tmp/out.png` for full screen, `grim -g "X,Y WxH" /tmp/out.png` for a rect (pull the geometry out of `hyprctl clients -j`). Outputs PNG you can `Read` to verify state.

### Clipboard

- **`wl-copy --type image/png < file.png`** — load an image onto the clipboard with a specific MIME type. Without `--type`, `wl-copy` infers text and image-aware apps won't find it.
- **`wl-paste -l`** — list MIME types currently on the clipboard. Sanity check after `wl-copy`.
- **`wl-copy --clear`** — empty the clipboard (teardown).
- Requires `WAYLAND_DISPLAY` set (see above).

### The loop

Fire-and-forget doesn't work. Always loop:

1. **Observe** — `hyprctl activewindow -j` and/or `grim /tmp/out.png`; `Read` the PNG to see actual state.
2. **Act** — `hyprctl dispatch sendshortcut ...` / `wtype ...` / `hyprctl dispatch ...` / `ydotool ...`.
3. **Verify** — screenshot again, diff against expectation, log the result.

If step 3 doesn't show the expected change, don't just retry — something is off (wrong window focused, modal on top, element moved, no seat focus after `exec`). Re-observe first.

### Common patterns

- **Launch and verify a browser for UI testing**:
  ```
  hyprctl dispatch exec "[float; size 1200 800; center 1] firefox --new-window http://localhost:3000"
  ```
  wait, `grim`, `Read`, confirm page loaded.
- **Send a key chord to a known window without stealing focus** (preferred over `wtype` when the target class is known):
  ```
  hyprctl dispatch sendshortcut "CTRL,V,class:^(kitty)$"
  ```
- **Focus a specific window before typing free-form text**:
  ```
  hyprctl dispatch focuswindow "class:^(firefox)$"
  wtype "hello"
  ```
- **Click a known element** (requires `ydotool` socket access):
  ```
  ydotool mousemove --absolute -x N -y M && ydotool click 0xC0
  ```

### When not to

- Don't automate the user's logged-in accounts, messaging apps, or anything touching their identity.
- Don't spam notifications or steal focus while the user is actively using the machine (if they're away, fine).
- If three observe→act→verify cycles fail on the same step, stop and log — the UI probably changed or your model of it is wrong.

## Integration with other skills

- **tmux-cowork**: use it aggressively in unattended mode. Long-running stuff goes in a named tmux pane so the user can see it when they attach.
- **PRs**: keep them small. Unattended does not mean one giant PR. Open a PR per logical unit of work as you finish each.

## On finishing

When you genuinely run out of tractable work:
1. Log what you completed and what's parked.
2. Summarize blockers that need user input, with proposed resolutions for each.
3. Stop. Don't invent work to stay busy.
