# ADR-003 — Claude Session Monitor: event-driven, multi-host state tracking

**Status**: Accepted  
**Date**: 2026-06-14  
**Context**: One at-a-glance view of every Claude Code session across all machines — the local desktop **and** remote boxes reached over SSH (Secure Shell). Each session is **running**, **idle**, or **pending** ("Claude stopped or is asking, and you haven't looked yet"). This records the chosen architecture. (Full feature spec: `dev-notes/claude-session-monitor-spec.md`.)

**Decision**: One `claude-mon` daemon on the local desktop. **Events decide *when* to refresh; a pull decides *what's true*.** ntfy + Hyprland + tmux hooks are triggers; an SSH-pull of `~/.claude/sessions/*.json` is the source of truth. Remotes run only a tiny `claude-mon collect` script — no daemon, no API.

!!! warning "Does NOT cover"
    Render surface (Waybar vs HTTP vs CLI), state-precedence rules, and the stale-timeout value — those are D1–D5 in the spec, unchanged.

---

## The state model

Two independent questions per session; combine them for the three reportable states:

```mermaid
flowchart TD
    classDef axis  fill:#85c1e9,color:#1a252f,stroke:#2471a3
    classDef state fill:#52be80,color:#145a32,stroke:#196f3d
    classDef warn  fill:#f0b27a,color:#784212,stroke:#e67e22
    classDef dec   fill:#717d7e,color:#fff,stroke:#5d6d7e

    S["a session"]:::axis --> Q1{"busy?"}:::dec
    Q1 -->|yes| R["RUNNING<br/>(working — leave it)"]:::state
    Q1 -->|"no (stopped / asking)"| Q2{"focused?"}:::dec
    Q2 -->|yes| I["IDLE<br/>(you're already there)"]:::state
    Q2 -->|no| P["⚠ PENDING<br/>(needs you)"]:::warn
```

The **state** axis (busy?) and the **focus** axis (looking at it?) come from different inputs — that's why there are two pipelines below.

!!! abstract "The one idea that drives the whole design: edges vs levels"
    ntfy is a stream of **transitions** (edges) — "a session just stopped". It can *never* tell you what's running *right now* or even what sessions exist (levels). So ntfy is a perfect **trigger**, but the **source of truth** has to be a direct read of the session files. Hence: event triggers a *pull*, the pull is ground truth.

---

## Architecture

```mermaid
flowchart TD
    classDef trig fill:#c39bd3,color:#4a235a,stroke:#7d3c98
    classDef ev   fill:#85c1e9,color:#1a252f,stroke:#2471a3
    classDef mon  fill:#52be80,color:#145a32,stroke:#196f3d
    classDef src  fill:#717d7e,color:#fff,stroke:#5d6d7e
    classDef out  fill:#f0b27a,color:#784212,stroke:#e67e22

    NT["ntfy jollof-claude<br/>(state changed)"]:::trig --> D
    HY["Hyprland socket2<br/>(window focus)"]:::ev --> D
    TM["tmux hooks<br/>(pane/window focus)"]:::ev --> D

    D["claude-mon daemon<br/>(local desktop only)"]:::mon
    D -->|"on any trigger:<br/>reconcile (debounced)"| RD["read local sessions<br/>+ ssh-pull remotes<br/>(host list from tailscale)"]:::src
    RD --> D
    D --> OUT["render: Waybar / CLI / HTTP"]:::out
```

One daemon, three triggers, one authoritative pull, one render. Remotes are passive — they just hold their `~/.claude/sessions/*.json` and answer `ssh <host> claude-mon collect`.

---

## The decisions

| # | Decision | Chosen | Why |
|---|----------|--------|-----|
| **D6** | Remote-host list | **Tailscale** — `tailscale status --json`, filter to online peers | No config to maintain; **read-only, needs no sudo** |
| **D7** | Acquire remote state | **SSH-pull** = source of truth; ntfy = trigger only. No per-host API | Pull gives complete *levels*; reuses SSH + Tailscale already in place; no daemon on remotes |
| **D8** | Focus transport | **Event-driven**: Hyprland `socket2` + tmux hooks | Already proven for `waybar-focus.sh`; no polling |
| **D9** | Remote (SSH) focus | **Pull on local focus event** — piggyback the SSH-pull | No remote-push channel, no ntfy side-topic, no key interception |
| **D10** | The `CLAUDE!` terminal-title flag across hosts | **Open** — title is a 4th render surface; see below | Today it's per-tmux-server and misses remote/other-server pending sessions |

### D7 — how the pull works

Local sessions are a plain file read. Remote sessions: the daemon runs `ssh <host> claude-mon collect`, which returns the host's session JSON. This is the ground-truth *level* snapshot and the fallback whenever ntfy is down (ntfy's `since=` replays missed edges after downtime). Pull only on a trigger, debounced — so it's cheap.

### D8 — focus, two doors

- **Hyprland (window focus):** tail `socket2` with `socat` for `activewindow` — the same pattern as `configs/hypr/scripts/waybar-focus.sh`. Covers groups for free (the active window *is* the visible group tab).
- **tmux (pane/window focus):** no socket, but global hooks — `set-hook -g pane-focus-in 'run-shell …'` (plus `after-select-pane` / `after-select-window`) poke the daemon when you switch panes.
- **Matching:** `hyprctl activewindow -j \| .pid` → the session whose `TERMINAL_WINDOW_PID` (from `/proc/<pid>/environ`, no hook needed) matches; if inside tmux, confirm `pane_active && window_active`. Logic lifted from `notify-if-unfocused.sh`.

### D9 — remote focus without a remote channel

For an SSH session the tmux that matters runs on the *remote* host. Rather than have the remote push its focus back (another channel to keep alive), the daemon pulls: **when local Hyprland focus lands on the terminal that's SSH'd into `<host>`, the same SSH-pull also returns that host's tmux focus bits**, computed where tmux actually lives. Remote focus = *local* window event → pull. No remote push.

### D10 — the `CLAUDE!` terminal-title flag is per-server (open)

There is a pre-existing affordance, separate from `claude-mon`: the outer terminal's title gains a `CLAUDE! ` prefix while a Claude session is pending. It's driven by `set -g set-titles-string '#{?#{@claude_any},CLAUDE! ,}#H:#S'` (`configs/tmux/tmux.conf:14`), where `@claude_any` is a tmux **server-global** option set/cleared by `configs/tmux/scripts/claude-flag.sh` (recomputed from *all* windows), driven by the notify hook on pending and the focus hooks on view.

!!! warning "The gap"
    `@claude_any` lives on **one tmux server**. So:

    - **Within that server** the title already flips for *any* pending window, focused or not — `refresh-client -S` pushes it to every client. This part works.
    - **Across servers / hosts** it can't: a session pending on pi-box (or any remote, or a second local tmux socket) sets `@claude_any` on *that* server only. The terminal you're actually looking at never sees it → no `CLAUDE!`.

    This is precisely the multi-host case the daemon exists for. The title is just an **unrecognised fourth render surface** (alongside Waybar / CLI / HTTP in D2) that was never wired to the daemon's fleet-wide truth.

**Honest framing:** this surface partly duplicates the Waybar badge and the ntfy push the daemon already drives. Its only real edge is being glanceable when Waybar is hidden or a window is fullscreen. Record the options; don't assume it's worth building.

| Approach | How | Trade-off |
|---|---|---|
| **A — daemon owns a global title flag** (recommended if built) | Daemon writes a separate `@claude_remote_pending` option into each local tmux server on reconcile; title becomes `#{?#{\|\|:#{@claude_any},#{@claude_remote_pending}},CLAUDE! ,}`. Local hook fast-path (`@claude_any`) stays untouched; remote/fleet truth is OR'd in. | Cleanest separation: local stays instant, remote rides the daemon. Daemon must enumerate local tmux sockets and clear the flag when the fleet goes quiet. |
| **B — daemon writes a status file, zsh `precmd` reads it** | Daemon writes e.g. `/run/user/$UID/claude-mon/any-pending`; a `precmd` hook prefixes the title from it. | Works for plain (non-tmux) zsh too. But `precmd` only fires at prompt redraw → stale until you hit Enter; more moving parts than reusing `set-titles`. |
| **C — leave title local, rely on Waybar/ntfy for cross-host** (do-nothing) | Explicitly decide the title is a *local-server* affordance; the daemon-driven Waybar badge is the cross-host glanceable surface. | Zero new code; accepts that a remote-only pending session shows in Waybar/ntfy but not the local title. Likely the right v1 call given the redundancy above. |

Note that `@claude_pending` (the per-window marker driving `claude-next.sh`'s "jump to next pending window" and the per-tab label) is inherently local — you can't `select-window` onto a remote host's window — so only `@claude_any` (the title flag) is a candidate for going fleet-wide; the per-window marker stays per-server.

---

## Consequences

- ✓ Remotes stay dumb: one `collect` script, no daemon, no API, no open ports.
- ✓ Reuses what's already working: ntfy hook, Tailscale, SSH, the Hyprland-socket pattern.
- ✓ Push latency without trusting push as truth (event-triggered reconciliation).
- ✗ A daemon to supervise (start/restart, debounce, missed-event catch-up) — more than a naive 2s poll, but the cost of low latency.
- ✗ SSH-pull adds per-trigger latency; if it ever hurts, the escape hatch is a per-host API (D7 Option 3), explicitly deferred until proven necessary.
