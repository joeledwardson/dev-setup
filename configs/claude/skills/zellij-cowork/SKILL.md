---
name: zellij-cowork
description: Run long-running or interactive commands in a separate zellij pane the user can watch and interact with. Use this for any command expected to take >30s, dev servers, watch modes, builds, tests, REPLs, migrations, or anything the user might need to Ctrl+C or send input to. Skip for quick one-shot commands (<30s, no prompts).
---

# zellij-cowork — share a zellij pane with the user for long commands

## Disambiguation: which cowork skill?

Both `tmux-cowork` and `zellij-cowork` are available. Pick correctly:

- User said **"zellij"** explicitly → `zellij-cowork` (this skill).
- User said **"tmux"** explicitly → `tmux-cowork`.
- User said just **"cowork"** with no multiplexer named:
  - If you're on a **remote server / unattended mode** (SSH session, `/unattended` skill in use, no local Wayland display) → default to `tmux-cowork` and proceed.
  - Otherwise → **ask the user** which one before proceeding. Don't guess.

The user runs Claude inside a zellij pane and wants to watch/interact with anything slow or interactive. Instead of using the Bash tool's sandbox, you spawn a sibling zellij pane the user can already see. They get scrollback and can Ctrl+C, send input, or just read progress.

## When to use

**Use a cowork pane for:**
- Any command expected to take >30 seconds
- Dev servers (`npm run dev`, `cargo watch`, `uvicorn`, etc.)
- Watch/test-runner modes (`vitest --watch`, `pytest -f`, etc.)
- Long builds (`nixos-rebuild`, `cargo build --release`, big `docker build`)
- Migrations, seeders, one-off scripts that take minutes
- Anything interactive (REPLs, `gh auth login`, db shells)

**Don't use a cowork pane for:**
- `git status`, `ls`, file reads, quick `grep` — overhead isn't worth it
- Anything sub-second

## Identifying Claude's own pane (the master)

Claude Code runs inside a zellij pane. The env vars are already set:

- `ZELLIJ_SESSION_NAME` — current zellij session
- `ZELLIJ_PANE_ID` — the integer pane id Claude is running in (e.g. `4`)

The master pane reference is therefore `terminal_$ZELLIJ_PANE_ID`.

**CRITICAL: never close `terminal_$ZELLIJ_PANE_ID`.** That's where Claude lives. Closing it kills the session. Every `close-pane` call must explicitly check the target id is not `$ZELLIJ_PANE_ID`.

## Naming convention

The user's convention is one **claude session per zellij tab**, with both named the same:

- **Tab name** = `<session-name>` — the same string passed to `yolo-claude --remote-control -n <session-name>` when this Claude was launched. If unknown, default to `basename "$PWD"` and confirm with the user.
- **Master pane** (Claude's own): `claude-code-master`
- **Cowork panes** (siblings in the same tab): `cowork-<task-name>` where `<task-name>` is short and descriptive (`build`, `dev-server`, `migrate-users`, `vitest`)

Rename on first use so the user can spot the tab/pane. Both are idempotent:

```
zellij action rename-tab  '<session-name>'
zellij action rename-pane -p $ZELLIJ_PANE_ID claude-code-master
```

`rename-tab` without `-t` renames the focused tab — fine when called from inside Claude's own pane, since that pane is in its own tab. To check the current tab name first:

```
zellij action list-panes -j | jq -r --arg id "$ZELLIJ_PANE_ID" \
  '.[] | select(.id==($id|tonumber) and (.is_plugin|not)) | .tab_name'
```

## Bootstrap (first invocation per task)

1. Ensure master is renamed (above).
2. Decide whether the task needs a fresh pane or can reuse an existing `cowork-<task>` pane. Check with:
   ```
   zellij action list-panes -j | jq -r '.[] | select(.title=="cowork-<task>") | .id'
   ```
   - Empty → create. Non-empty → reuse that integer id (use as `terminal_<id>`).
3. Create when missing:
   ```
   zellij action new-pane -n cowork-<task> --cwd "$PWD"
   ```
   `new-pane` prints the new pane id (`terminal_<id>`) to stdout — capture it.
4. Tell the user once which pane the command is going into (`cowork-build`, etc.) so they know where to look.

For parallel independent tasks, create separate panes with distinct names (`cowork-frontend`, `cowork-api`). Don't try to split a single pane like tmux — zellij handles layout itself.

## Running a command

Two-step send: write the command text, then press Enter.

```
zellij action write-chars -p terminal_<id> '<cmd>'
zellij action send-keys  -p terminal_<id> 'Enter'
```

`write-chars` is safer than `send-keys` for arbitrary text — `send-keys` interprets space-separated tokens as key names (`Ctrl c`, `Enter`, `F1`).

After sending, **you must poll until the command actually finishes** — do not hand control back to the user assuming it worked. Handing off a still-running command is the classic failure mode of this skill.

### Detecting completion

Use one of these patterns, not a blind sleep:

1. **Sentinel marker + log file** (most reliable): tee output to a scratchpads log file and append a sentinel.
   ```
   mkdir -p scratchpads
   zellij action write-chars -p terminal_<id> '<cmd> 2>&1 | tee scratchpads/<task>.log; echo __CC_DONE_${PIPESTATUS[0]}__'
   zellij action send-keys  -p terminal_<id> 'Enter'
   ```
   - Poll the log file (or `dump-screen -p terminal_<id>`) until you see `__CC_DONE_<exitcode>__`.
   - `${PIPESTATUS[0]}` (bash) captures the real exit code of `<cmd>`, not `tee`. In zsh use `${pipestatus[1]}`.
   - `scratchpads/` is already gitignored.
   - **Prefer reading the log file over `dump-screen` for parsing.** `dump-screen` is lossy (viewport cap unless `--full`, ANSI noise, wrapped lines); the log file has full raw output including stderr.

2. **Prompt return**: poll `dump-screen` and look for a fresh shell prompt on the last non-empty line. Less reliable than sentinel — prompt-matching gets confused by colored prompts and multi-line output.

3. **Pane exited**: `zellij action list-panes -j | jq '.[] | select(.id==<id>) | .exited, .exit_status'` works only if the pane was launched with `--close-on-exit` or the command was the pane's foreground process. Rarely applicable — our panes stay alive on the shell.

Prefer **pattern 1** unless the command is interactive or can't be wrapped.

### Polling cadence

- Active build/test: check every 10–20s
- Long idle operation (big download, rebuild): 30–60s
- Never loop with no backoff
- After ~5 minutes with no visible progress, surface that to the user rather than silently polling forever

### Reporting back

When the sentinel fires:
1. `tail -n 100 scratchpads/<task>.log` — use the file, not `dump-screen`, for parsing accuracy.
2. Parse exit code from the sentinel. Non-zero → investigate, don't silently claim success.
3. Tell the user what actually happened (exit code, key output), not just "started it".

## Multiple commands in the same pane

When chaining for the same task (e.g. `cargo build` then `cargo test`), reuse the pane and update its name as the current command changes:

```
zellij action rename-pane -p terminal_<id> cowork-<new-task>
```

## Reading state

```
zellij action dump-screen -p terminal_<id>          # current viewport
zellij action dump-screen -p terminal_<id> --full   # include scrollback
zellij action dump-screen -p terminal_<id> --path /tmp/dump.txt  # to file
```

Use `--full` if you need scrollback context. Strip ANSI when parsing (don't pass `-a`).

## Sending control keys / input

```
zellij action send-keys -p terminal_<id> 'Ctrl c'      # interrupt
zellij action send-keys -p terminal_<id> 'y' 'Enter'   # confirm prompt
zellij action write-chars -p terminal_<id> 'mypassword'
zellij action send-keys  -p terminal_<id> 'Enter'
```

Don't Ctrl+C from outside if the user is actively watching — let them do it. Only send control keys when you started the command and need to stop it yourself.

## Tearing down

Don't close panes the user might want to scroll back through. Closing a one-shot cowork pane after success is fine:

```
# GUARD: never close the master
[ "<id>" != "$ZELLIJ_PANE_ID" ] && zellij action close-pane -p terminal_<id>
```

If unsure, leave it. The user can close panes themselves.

## Master mode: spawning new tabs / claude sessions

The user keeps a dedicated zellij tab literally named **`master`**. The Claude running in that tab is the orchestrator — its job is **not** to do project work, it's to spawn new tabs, each running its own `yolo-claude --remote-control -n <new-session-name>`.

**You are the master if** the current tab name is `master`:

```
zellij action list-panes -j | jq -r --arg id "$ZELLIJ_PANE_ID" \
  '.[] | select(.id==($id|tonumber) and (.is_plugin|not)) | .tab_name'
```

If that returns `master`, follow the spawn flow below for the user's actual ask. If it returns anything else, you're a worker — do the task in this tab using cowork panes as normal, do **not** spawn new tabs.

### Spawn flow (master only)


1. **Pick the new session name.** Short, descriptive — typically the project / task (`dev-setup`, `ntfy-rollout`). The same string is used for both the zellij tab and the claude `-n`.
2. **Create the tab and capture its id:**
   ```
   TAB_ID=$(zellij action new-tab -n '<new-session-name>' --cwd "<project-cwd>")
   ```
   `new-tab` prints the tab id as a single integer.
3. **Find the pane id created inside that tab:**
   ```
   PANE_ID=$(zellij action list-panes -j \
     | jq -r --arg t "$TAB_ID" '.[] | select((.tab_id|tostring)==$t and (.is_plugin|not)) | .id' \
     | head -1)
   ```
4. **Launch the child Claude in it:**
   ```
   zellij action write-chars -p terminal_$PANE_ID 'yolo-claude --remote-control -n <new-session-name>'
   zellij action send-keys   -p terminal_$PANE_ID 'Enter'
   ```
5. **Optionally rename the pane** so it's spottable before the child renames itself:
   ```
   zellij action rename-pane -p terminal_$PANE_ID claude-code-master
   ```
   The child Claude will idempotently re-do this on its first cowork action anyway.
6. **Stay put** — the master Claude does not switch into the new tab and does not rename its own tab away from `master`. The user navigates there themselves. If they ask for it explicitly: `zellij action go-to-tab-name '<new-session-name>'`.

Don't spawn child claude sessions silently. Tell the user the tab name and that a child Claude is starting up there.

## Failure modes

- If `zellij` isn't on PATH or `ZELLIJ_PANE_ID` is unset, Claude is not running inside zellij — fall back to the Bash tool with `run_in_background: true` and tell the user.
- If a command hangs forever, surface it and let the user Ctrl+C in their pane rather than killing from outside.
- If `new-pane` fails (e.g. layout locked), report the error verbatim instead of retrying blindly.
