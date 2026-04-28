---
name: tmux-cowork
description: Run long-running or interactive commands in a tmux session the user can watch and interact with. Use this for any command expected to take >30s, dev servers, watch modes, builds, tests, REPLs, migrations, or anything the user might need to Ctrl+C or send input to. Skip for quick one-shot commands (<30s, no prompts).
---

# tmux-cowork — share a tmux window with the user for long commands

## Disambiguation: which cowork skill?

Both `tmux-cowork` and `zellij-cowork` are available. Pick correctly:

- User said **"tmux"** explicitly → `tmux-cowork` (this skill).
- User said **"zellij"** explicitly → `zellij-cowork`.
- User said just **"cowork"** with no multiplexer named:
  - If you're on a **remote server / unattended mode** (SSH session, `/unattended` skill in use, no local Wayland display) → default to `tmux-cowork` (this skill) and proceed.
  - Otherwise → **ask the user** which one before proceeding. Don't guess.

The user runs Claude in YOLO mode and wants to watch/interact with anything slow or interactive. Instead of using the Bash tool's sandbox, you push commands into a tmux window the user is attached to. They get scrollback and can Ctrl+C, send input, or just read progress.

## When to use

**Use tmux for:**
- Any command expected to take >30 seconds
- Dev servers (`npm run dev`, `cargo watch`, `uvicorn`, etc.)
- Watch/test-runner modes (`vitest --watch`, `pytest -f`, etc.)
- Long builds (`nixos-rebuild`, `cargo build --release`, big `docker build`)
- Migrations, seeders, one-off scripts that take minutes
- Anything interactive (REPLs, `gh auth login`, db shells)

**Don't use tmux for:**
- `git status`, `ls`, file reads, quick `grep` — overhead isn't worth it
- Anything sub-second

## Session and window naming

**Always** name the session explicitly — never let tmux auto-name it. Pick a session name from the project or task (e.g. `dev-setup`, `ntfy-rollout`).

- Session: `<session_name>` (ask user if unclear, else infer from cwd). If the user spawned this Claude via `claude-master` with `--remote-control -n <name>`, reuse `<name>` as the tmux session — your cowork windows live alongside the `claude` window in the same session.
- Cowork windows: `cowork-<task>` (e.g. `cowork-build`, `cowork-tests`), or split panes inside one
- Pane titles: descriptive of the current command (`build`, `dev-server`, `migration`, `tests`)

User attaches with `tmux attach -t <session_name>`.

## Bootstrap

Idempotent. Create the session if missing, then add a cowork window for the task:

```
tmux has-session -t <session_name> 2>/dev/null || tmux new-session -d -s <session_name> -n cowork-main -c <cwd>
tmux list-windows -t <session_name> -F '#W' | grep -qx 'cowork-<task>' || tmux new-window -t <session_name> -n cowork-<task> -c <cwd>
```

Tell the user once: `tmux attach -t <session_name>`.

> Spawning a fresh Claude session is **not** this skill's job — see `claude-master`. This skill is for the *child* Claude to run long/interactive commands in its own tmux panes.

## Running a command

Send keys into the target pane:

```
tmux send-keys -t <session_name>:<session_name>-cowork.<pane_id> '<cmd>' Enter
```

Then **you must poll until the command actually finishes** — do not hand control back to the user assuming it worked. Handing off a still-running command is the classic failure mode of this skill.

### Detecting completion

Use one of these patterns, not a blind sleep:

1. **Sentinel marker + log file** (most reliable): append a marker *and* tee output to a scratchpads log file.
   ```
   tmux send-keys -t <target> '<cmd> 2>&1 | tee scratchpads/<pane-title>.log; echo __CC_DONE_${PIPESTATUS[0]}__' Enter
   ```
   - Poll `capture-pane` until you see `__CC_DONE_<exitcode>__` in the output.
   - `${PIPESTATUS[0]}` (bash) captures the real exit code of `<cmd>`, not `tee`. In zsh use `${pipestatus[1]}`.
   - Ensure `scratchpads/` exists (`mkdir -p scratchpads`). It's already gitignored.
   - **Prefer reading the log file over `capture-pane` for parsing.** `capture-pane` is lossy (scrollback cap, ANSI noise, wrapped lines); the log file has the full raw output including stderr.

2. **Prompt return**: poll `capture-pane` and look for a fresh shell prompt on the last non-empty line (matches your `$ `, `➜ `, `%`, etc.). Less reliable than sentinel — prompt-matching can get confused by multi-line output or colored prompts.

3. **Pane-dead check** for one-shot foreground processes: use `tmux display-message -p -t <target> '#{pane_dead}'`. Rarely applicable — our panes stay alive on the shell.

Prefer **pattern 1** (sentinel) unless the command is interactive / can't be wrapped.

### Polling cadence

- Active build/test: capture every 10–20s
- Long idle operation (big download, rebuild): 30–60s
- Never loop with no backoff — wasted cycles
- After ~5 minutes with no visible progress, surface that to the user in the log / response rather than silently polling forever

### Reporting back

When the sentinel fires or the pane returns:
1. Read the tail of the log file (`tail -n 100 scratchpads/<pane-title>.log`) — use the file, not `capture-pane`, for parsing accuracy.
2. Parse exit code from the sentinel. Non-zero → investigate, don't silently claim success.
3. Tell the user what actually happened — including the exit code and relevant output — not just "started it".

## Multiple commands

- **Chaining long commands for the same task** (e.g. `cargo build` then `cargo test`): reuse the same pane. Rename the pane title as the current command changes:
  ```
  tmux select-pane -t <target> -T '<new-title>'
  ```

- **Parallel independent commands**: either spawn a new `cowork-<task>` window, or split an existing cowork window.
  - New window (preferred when tasks are unrelated): `tmux new-window -t <session_name> -n cowork-<task>`
  - 2 commands in one window → vertical split (side-by-side):
    ```
    tmux split-window -h -t <session_name>:cowork-<task>
    ```
  - 3+ commands → stacked layout for readability:
    ```
    tmux split-window -v -t <session_name>:cowork-<task>
    tmux select-layout -t <session_name>:cowork-<task> main-horizontal
    ```
  - Name each pane via `select-pane -T` so the user can tell them apart.

## Pane titles

Set a pane title on every command you launch. User-facing, keep it short:
```
tmux select-pane -t <target> -T 'migrate-users'
```

## Reading state

Use `capture-pane -p` (print to stdout) to read back. `-S -3000` grabs 3000 lines of scrollback. For "current screen only" drop `-S`.

## Tearing down

Don't kill the session unless the user asks. The user may want to scroll back later. Closing panes after a one-shot command is fine:
```
tmux kill-pane -t <target>
```

## Failure modes

- If `tmux` isn't installed, fall back to the regular Bash tool with `run_in_background: true` and tell the user.
- If the user says "I'm not attached" — remind them of `tmux attach -t <session_name>`.
- If a command hangs forever, tell the user; let them Ctrl+C it in their attached pane rather than killing from outside.
