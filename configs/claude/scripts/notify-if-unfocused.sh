#!/bin/bash
# Route Claude Code hook events to two places:
#   1. ntfy.sh — always, unified desktop + mobile push across every machine
#   2. notify-send — local Hyprland box only, and only if terminal is unfocused
#
# ntfy credentials: NTFY_TOKEN + NTFY_TOPIC env vars, or fallback to
# /run/agenix/ntfy-token + topic "jollof-claude".

INPUT=$(timeout 1 cat)
if [ $? -eq 124 ]; then
    notify-send "Claude Hook Error" "notify-if-unfocused: stdin read timed out" 2>/dev/null
    exit 0
fi
EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // "unknown"')
PROJECT=$(echo "$INPUT" | jq -r '.cwd // ""' | xargs basename 2>/dev/null)
FULL_MSG=$(echo "$INPUT" | jq -r '.last_assistant_message')
if [ ${#FULL_MSG} -gt 200 ]; then
    MSG="${FULL_MSG:0:200}..."
else
    MSG="$FULL_MSG"
fi

echo "$INPUT" >>/tmp/claude-notify-log.log

# Decide whether to fire the notification at all. On a local Hyprland host
# we suppress when the user is actively watching the claude terminal pane.
# On remote/Docker/SSH (no hyprctl) we always fire — user has no local display.
should_notify() {
    command -v hyprctl >/dev/null || return 0  # remote: always notify
    # hyprctl prints non-JSON "Invalid" to stdout when its socket isn't reachable
    # (e.g. running outside a user session), so silence jq stderr and guard empty.
    local active_pid
    active_pid=$(hyprctl activewindow -j 2>/dev/null | jq -r '.pid // empty' 2>/dev/null)
    [ -z "$active_pid" ] && return 0  # can't determine focus → notify
    [ "$active_pid" = "$TERMINAL_WINDOW_PID" ] || return 0  # terminal unfocused
    # terminal focused, but maybe user is in a different zellij pane
    [ -n "$ZELLIJ" ] && [ -n "$ZELLIJ_PANE_ID" ] || return 1
    local focused_pane
    focused_pane=$(zellij action list-panes --state --json 2>/dev/null |
        jq -r '.[] | select(.is_plugin == false and .is_focused == true) | .id' 2>/dev/null)
    [ "$focused_pane" != "$ZELLIJ_PANE_ID" ]
}

should_notify || exit 0

# ntfy: unified desktop + mobile push across every machine. The desktop pathway
# runs via a local ntfy subscriber (see nixos-core-desktop.nix) that bridges to
# notify-send, so we don't call notify-send directly here — the subscriber
# handles local rendering, and the mobile app handles phone push.
TOKEN="${NTFY_TOKEN:-$(cat /run/agenix/ntfy-token 2>/dev/null)}"
TOPIC="${NTFY_TOPIC:-jollof-claude}"
if [ -n "$TOKEN" ] && [ -n "$TOPIC" ]; then
    if [ "$EVENT" = "Notification" ]; then
        tags="question"
        priority="high"
    else
        tags="white_check_mark"
        priority="default"
    fi
    curl -sS -u ":$TOKEN" \
        -H "Title: Claude $EVENT / $PROJECT @ $(hostname)" \
        -H "Tags: $tags" \
        -H "Priority: $priority" \
        -d "$MSG" \
        "https://ntfy.sh/$TOPIC" >/dev/null 2>&1 &
fi
