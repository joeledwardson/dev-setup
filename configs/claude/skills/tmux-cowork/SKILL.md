---
name: tmux-cowork
description: Run long-running or interactive commands in a tmux session the user can watch and interact with. Use this for any command expected to take >30s, dev servers, watch modes, builds, tests, REPLs, migrations, or anything the user might need to Ctrl+C or send input to. Skip for quick one-shot commands (<30s, no prompts).
---

# tmux-cowork — share a tmux window with the user for long commands

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

- Session: `<session_name>` (ask user if unclear, else infer from cwd)
- Window: `<session_name>-cowork`
- Pane titles: descriptive of the current command (`build`, `dev-server`, `migration`, `tests`)

User attaches from zellij with `tmux attach -t <session_name>`.

## Bootstrap

Before first use in a session, ensure the tmux session and cowork window exist. Idempotent:

```
tmux has-session -t <session_name> 2>/dev/null || tmux new-session -d -s <session_name> -n <session_name>-cowork
tmux list-windows -t <session_name> -F '#W' | grep -qx '<session_name>-cowork' || tmux new-window -t <session_name> -n <session_name>-cowork
```

Tell the user once which session they should `tmux attach -t <session_name>`.

## Running a command

Send keys into the target pane, then poll output:

```
tmux send-keys -t <session_name>:<session_name>-cowork.<pane_id> '<cmd>' Enter
tmux capture-pane -pt <session_name>:<session_name>-cowork.<pane_id> -S -3000
```

Use pane indexes (`.0`, `.1`, ...) or pane titles to target the right one.

Poll the pane with `capture-pane` periodically. Don't spam — wait enough for meaningful output to accumulate.

## Multiple commands

- **Chaining long commands for the same task** (e.g. `cargo build` then `cargo test`): reuse the same pane. Rename the pane title as the current command changes:
  ```
  tmux select-pane -t <target> -T '<new-title>'
  ```

- **Parallel independent commands**: split the window.
  - 2 commands → vertical split (side-by-side):
    ```
    tmux split-window -h -t <session_name>:<session_name>-cowork
    ```
  - 3+ commands → stacked layout for readability:
    ```
    tmux split-window -v -t <session_name>:<session_name>-cowork
    tmux select-layout -t <session_name>:<session_name>-cowork main-horizontal
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
