# Spec — Claude Session Monitor (`claude-mon`)

**Status:** DRAFT for review — 2026-06-14
**One-liner:** A read-only monitor that shows, at a glance, the state of every Claude Code session across all your machines: **running**, **idle**, or **pending** — where "pending" means Claude has stopped/is asking and *you haven't looked at it yet*.

---

## What I understood

You want a simple monitor that tells you which Claude sessions need your attention. The novel bit is the **focus-aware** state: a stopped session only counts as needing attention ("pending") until you actually look at it, at which point it flips to "idle". "Looking at it" is strict — it must be the focused Hyprland window **and** (if tmux is involved) the active tmux pane in the active tmux window **and** (if grouped) the active group tab. This must also cover sessions running on remote machines over SSH (Secure Shell).

---

## The three states

| State | Meaning | Needs your attention? |
|---|---|---|
| **running** | Claude is actively processing a turn | No — it's working |
| **pending** | Claude has stopped or is asking for input, **and you are not focused on it** | **Yes** — this is the whole point |
| **idle** | Claude has stopped/is asking, **and you are currently focused on it** | No — you're already there |

State is computed from exactly two inputs per session:

1. **Claude's processing status** — `busy` vs `idle`, read from the session file Claude already writes (see below). This is the running-vs-stopped axis.
2. **Focus** — are you, right now, looking at this exact session? This is the focused-vs-unfocused axis.

### State machine

```
alive?  ── no ──▶  (drop — stale session file)
  │ yes
status == "busy"  ── yes ──▶  RUNNING
  │ no  (stopped / asking)
focused?  ── yes ──▶  IDLE
  │ no
  └────────────────▶  PENDING
```

**Decision point D1 (state precedence):** when Claude is `busy` *and* you're focused on it, I default to **running** (the work signal wins — "idle" is meaningless while it's typing). Flag if you'd rather focus always win.

---

## How each input is obtained (this is the load-bearing part)

### Input 1 — processing status (free, no hook needed)

Claude Code already writes one file per live session at `~/.claude/sessions/<pid>.json`:

```json
{"pid":709746,"sessionId":"1aadcfe3-…","cwd":"/home/claude/dev-setup",
 "status":"busy","updatedAt":1781429745462,"kind":"interactive", …}
```

- `status` is `"busy"` while processing, `"idle"` when stopped/waiting. **This is the authoritative running/stopped signal — we do not need a Claude hook to derive it.**
- **Staleness guard:** these files linger after a crash (I found one 2 days old). A session is only counted if `/proc/<pid>` exists *and* its start time matches `procStart` (guards against PID reuse). A session that is `busy` but whose `updatedAt` is older than a threshold (D5, default 120 s) is reported as **stale**, not running.

### Input 2 — focus (free, no hook needed)

For each live session PID we read `/proc/<pid>/environ` (same-user readable) to recover the variables Claude's launching terminal set:

- `TERMINAL_WINDOW_PID` — the Hyprland window the terminal lives in.
- `TMUX`, `TMUX_PANE` — present only if Claude runs inside tmux.
- `SSH_CONNECTION` / `SSH_TTY` — present only if this session is itself remote.

These never change after process start, so a one-time read per PID is enough.

A **local** session is **focused** when **all** of:

1. `hyprctl activewindow -j | .pid` == the session's `TERMINAL_WINDOW_PID`
   — the terminal is the focused window.
   *(This single check also covers Hyprland **groups** for free: the active window is by definition the visible/active group tab. A grouped terminal that isn't the front tab simply isn't `activewindow`, so it reads as unfocused — exactly what we want.)*
2. If `TMUX` is set: `tmux display-message -t <TMUX_PANE> -p '#{pane_active}|#{window_active}'` is `1|1`
   — the active pane of the active tmux window.
3. *(Implicit)* the tmux session is the one displayed in that focused terminal — guaranteed by 1+2 together on a local host.

This logic is lifted almost verbatim from the existing, working `configs/claude/scripts/notify-if-unfocused.sh` (lines 66–81) — we are extracting and reusing it, not inventing it.

### Input 3 — SSH (remote) sessions

A session running on a remote host can't be seen by the local data sources above: its `sessions/*.json`, its `/proc`, and its tmux all live on the remote machine, while the **window** you look through is local. Focus for a remote session is therefore a logical AND of one local fact and one remote fact:

> **focused(remote)** = *the locally-focused Hyprland window is the terminal SSH'd into that host* **AND** *on the remote host, that session's tmux pane is the active pane of the active window of an attached tmux client*.

**Transport — decision point D3.** Recommended: **SSH-pull**. The local aggregator runs `ssh <host> claude-mon collect`, which prints that host's sessions as JSON (status + per-session tmux focus bits, computed on the remote where tmux actually lives). No daemon to install on remotes; reuses your existing SSH config. Alternative: a tiny push/HTTP daemon per remote (lower latency, more moving parts). Recommend pull for v1; remotes polled on a slower cadence (~5 s) and cached.

**Window↔host matching — decision point D4.** To decide whether the focused local window is "the SSH terminal for host X", recommended: walk the process descendants of the focused window's PID, find an `ssh` child, and parse its destination host. Robust and needs no setup. Fallback: a terminal-title convention (`ssh: <host>`) set on connect. Recommend process-tree detection, title as fallback.

**What `collect` reports per remote session:** `sessionId, host, cwd, status, updatedAt, tmux_pane_active, tmux_window_active, tmux_attached`. It deliberately does **not** try to evaluate window focus — that's local-only and the aggregator's job.

---

## Structure I'll create

One self-contained Python file (zero dependencies, `uv run` shebang — same pattern as `configs/bin/port-dash`), symlinked to `~/.local/bin/claude-mon` via `install.conf.yaml`.

- **`configs/bin/claude-mon`** — the whole tool. Subcommands:
  - `claude-mon collect` — *In:* this host's `~/.claude/sessions/*.json` + `/proc` + local `tmux`. *Out:* JSON list of this host's sessions with status + tmux focus bits. Safe to invoke over SSH; does no Hyprland/window reasoning.
  - `claude-mon status` — *In:* local `collect` + `ssh <host> collect` for each configured remote + live `hyprctl activewindow` + window↔ssh mapping. *Out:* every session with its computed state (running/pending/idle/stale), as a table (default) or `--json`.
  - `claude-mon waybar` — *Out:* one line of Waybar JSON, e.g. `{"text":"▲2 ●1","class":"pending","tooltip":"…per-session list…"}`. `class` reflects the worst state present (pending > running > idle) for colouring.
- **`configs/claude-mon/hosts.toml`** *(optional)* — list of remote hosts to poll. Empty/absent ⇒ local-only.
- **Waybar wiring** — add a `custom/claude` module to `configs/waybar/modules.json` (mirroring the existing `custom/focus`: `return-type:"json"`, `restart-interval`) and place it in `configs/waybar/config.jsonc`. Reuse the PATH-shim header from `waybar-focus.sh` so Waybar's locked PATH finds `jq`/`hyprctl`.

### Refresh model
Poll-based for simplicity: Waybar re-runs `claude-mon waybar` every ~2 s (local sources are cheap file/IPC reads); remote hosts polled every ~5 s with a short cache to keep SSH cost down. Event-driven (Hyprland `socket2` + filesystem watch on the sessions dir) is noted as a later optimization, not v1.

---

## Rendering surfaces — decision point D2

Which surface(s) do you want first?

- **Waybar badge** (recommended primary) — always-visible count + colour on your bar; tooltip lists each session `host/project → state`.
- **CLI table** (`claude-mon status`) — for a terminal glance / scripting; comes essentially for free.
- **HTTP dashboard** — a `port-dash`-style page aggregating all hosts, registered in `.registered-ports.toml` so it shows up at `:9999`. Best for the multi-machine view but the most work.

Recommendation: ship **Waybar badge + CLI table** first (they share all the logic), add the HTTP dashboard in a second pass if the badge isn't enough for the SSH/multi-host case.

---

## What I'll reuse (not rebuild)

| Need | Reused from |
|---|---|
| Running/stopped status | `~/.claude/sessions/<pid>.json` `status` field (Claude writes it already) |
| Focus rule (window + tmux + group) | `configs/claude/scripts/notify-if-unfocused.sh` lines 66–81 |
| Zero-dep Python single-file tool | `configs/bin/port-dash` (`uv run` shebang) |
| Waybar custom-module wiring + PATH shim | `configs/waybar/modules.json` `custom/focus` + `configs/hypr/scripts/waybar-focus.sh` |
| Hyprland active-window / clients queries | `hyprctl activewindow -j`, `hyprctl clients -j` (used throughout `configs/hypr/scripts/`) |
| Multi-host port registration | `.registered-ports.toml` + `port-dash` (only if HTTP surface chosen) |

---

## Tests I'll write first

Pure state-machine logic is unit-testable by feeding fixture inputs (no live desktop needed):

- `TestState_BusyStatus_IsRunning` — `status:busy` ⇒ running, regardless of focus.
- `TestState_Stopped_Unfocused_IsPending` — `status:idle` + not focused ⇒ pending.
- `TestState_Stopped_Focused_IsIdle` — `status:idle` + focused ⇒ idle.
- `TestFocus_RequiresWindowAndTmuxAndTab` — focused only when window PID matches **and** tmux `pane_active&&window_active`; flipping any one to 0 ⇒ unfocused.
- `TestFocus_GroupedNonActiveTab_IsUnfocused` — terminal grouped but not the front tab ⇒ unfocused.
- `TestStale_DeadPid_IsDropped` — session file with no live `/proc/<pid>` ⇒ excluded.
- `TestStale_BusyButOld_IsStale` — `busy` with `updatedAt` past threshold ⇒ stale, not running.
- `TestRemote_FocusedOnlyWhenSshWindowActiveAndRemotePaneActive` — remote session focused only when local SSH window is active **and** remote tmux pane is active; either alone ⇒ pending.

---

## Does NOT (explicit scope boundary)

- Does **not** replace the existing `notify-if-unfocused.sh` ntfy push hook. The monitor is the *at-a-glance visual*; the hook stays as the *push*. (They can later share the extracted focus helper.)
- Does **not** control sessions — read-only. No focusing/killing/sending input in v1.
- Does **not** add a Claude Code hook — status comes from the files Claude already writes.
- Does **not** persist history, metrics, or a timeline.
- Does **not** add authentication to any HTTP surface — LAN-only, same posture as `port-dash`.
- Does **not** install anything on remote hosts beyond the single `claude-mon` script (needed there only for the `collect` subcommand).

---

## Open decisions for your review

| # | Decision | My recommendation |
|---|---|---|
| **D1** | `busy` + focused → running or idle? | **running** (work signal wins) |
| **D2** | Which rendering surface(s) first? | **Waybar badge + CLI table**; HTTP dashboard later |
| **D3** | SSH transport | **SSH-pull** (`ssh host claude-mon collect`), no remote daemon |
| **D4** | Map focused window → SSH host | **process-tree `ssh` detection**; title convention as fallback |
| **D5** | "busy but stale" timeout | **120 s** |
| **D6** | Remote host list source | small **`hosts.toml`** (recommend) vs parse `~/.ssh/config` |

---

**Ready for your review.** Tell me which way to go on D1–D6 (or "defaults are fine"), and I'll come back with the implementation following the unattended workflow.
