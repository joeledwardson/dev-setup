#!/bin/bash
# Notification hook for Claude Code Stop / Notification events.
# Routes events to:
#   1. ntfy.sh — always, unified desktop + mobile push
#   2. notify-send — local errors / hook failures
#
# Hard guarantees:
#   - Never blocks Claude. Watchdog SIGKILLs after HOOK_TIMEOUT seconds.
#   - Every external command is `timeout`-bounded.
#   - Errors are surfaced via notify-send AND logged to /tmp/claude-notify-debug.log.
#   - Always exits 0 — hooks must not propagate failure to Claude.
set -uo pipefail

HOOK_TIMEOUT=5
DEBUG_LOG=/tmp/claude-notify-debug.log
EVENT_LOG=/tmp/claude-notify-log.log

# ===== watchdog: kill self after HOOK_TIMEOUT no matter what =====
(sleep "$HOOK_TIMEOUT" && kill -9 $$ 2>/dev/null) &
WATCHDOG_PID=$!
trap 'kill "$WATCHDOG_PID" 2>/dev/null || true' EXIT

# ===== helpers =====
log_debug() { echo "[$(date -Iseconds)] $*" >>"$DEBUG_LOG"; }

notify_error() {
    log_debug "ERROR: $*"
    timeout 1 notify-send -u critical "Claude Hook Error" "$*" 2>/dev/null || true
}

# Run a command with a per-call timeout. Logs failures, returns non-zero on failure.
# Usage: out=$(safe_run 1 hyprctl activewindow -j) || handle
safe_run() {
    local secs=$1
    shift
    local output rc
    output=$(timeout "$secs" "$@" 2>/dev/null)
    rc=$?
    if [ "$rc" -ne 0 ]; then
        log_debug "FAIL rc=$rc: $*"
        return 1
    fi
    printf '%s' "$output"
}

# ===== read input (Claude pipes the event JSON to stdin) =====
INPUT=$(timeout 1 cat) || {
    notify_error "notify-if-unfocused: stdin read timed out"
    exit 0
}

EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // "unknown"' 2>/dev/null) || EVENT=unknown
PROJECT=$(echo "$INPUT" | jq -r '.cwd // ""' 2>/dev/null | xargs basename 2>/dev/null) || PROJECT=""
FULL_MSG=$(echo "$INPUT" | jq -r '.last_assistant_message // ""' 2>/dev/null) || FULL_MSG=""
if [ ${#FULL_MSG} -gt 200 ]; then
    MSG="${FULL_MSG:0:200}..."
else
    MSG="$FULL_MSG"
fi

echo "$INPUT" >>"$EVENT_LOG"

# ===== decide whether to fire (suppress when user is on the claude pane) =====
# On a local Hyprland host: suppress when terminal AND tmux pane both focused.
# On remote/Docker/SSH (no hyprctl): always notify.
should_notify() {
    command -v hyprctl >/dev/null || return 0

    local active_pid
    active_pid=$(safe_run 1 hyprctl activewindow -j | jq -r '.pid // empty' 2>/dev/null)
    [ -z "$active_pid" ] && return 0
    [ "$active_pid" = "${TERMINAL_WINDOW_PID:-}" ] || return 0

    [ -n "${TMUX:-}" ] && [ -n "${TMUX_PANE:-}" ] || return 1

    local pane_active window_active
    pane_active=$(safe_run 1 tmux display-message -t "$TMUX_PANE" -p '#{pane_active}')
    window_active=$(safe_run 1 tmux display-message -t "$TMUX_PANE" -p '#{window_active}')
    [ "$pane_active" = "1" ] && [ "$window_active" = "1" ] && return 1
    return 0
}

should_notify || exit 0

# ===== mark this session's tmux window as pending =====
# We only reach here when stopped/asking AND unfocused = "pending, needs you". Flag the window
# (a per-window tmux option — no rename, so automatic-rename and names like cowork-docs survive)
# and the global flag that drives the terminal title. Cleared by the pane-focus-in hook in
# tmux.conf when you focus the window. See configs/tmux/scripts/claude-{clear,next}.sh.
if [ -n "${TMUX:-}" ] && [ -n "${TMUX_PANE:-}" ]; then
    timeout 1 tmux set-window-option -t "$TMUX_PANE" @claude_pending 1 2>/dev/null || true
    timeout 1 tmux set-option -g @claude_any 1 2>/dev/null || true
    timeout 1 tmux refresh-client -S 2>/dev/null || true
fi

# ===== fire ntfy (curl is backgrounded so it never blocks the hook) =====
TOKEN="${NTFY_TOKEN:-$(cat /run/agenix/ntfy-token 2>/dev/null)}"
TOPIC="${NTFY_TOPIC:-jollof-claude}"
if [ -z "$TOKEN" ] || [ -z "$TOPIC" ]; then
    exit 0
fi
if [ "$EVENT" = "Notification" ]; then
    tags="question"
    priority="high"
else
    tags="white_check_mark"
    priority="default"
fi
timeout 3 curl -sS -u ":$TOKEN" \
    -H "Title: Claude $EVENT / $PROJECT @ $(hostname)" \
    -H "Tags: $tags" \
    -H "Priority: $priority" \
    -d "$MSG" \
    "https://ntfy.sh/$TOPIC" >/dev/null 2>&1 &

exit 0
