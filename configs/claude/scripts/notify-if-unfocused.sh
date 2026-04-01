#!/bin/bash
# Send a notification only if the terminal running this process is not focused.
# In Docker containers, sends via socat to host notification socket.

NOTIFY_SOCKET="/tmp/notify-forward/notify.sock"

INPUT=$(cat)
EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // "unknown"')
PROJECT=$(echo "$INPUT" | jq -r '.cwd // ""' | xargs basename 2>/dev/null)
FULL_MSG=$(echo "$INPUT" | jq -r '.last_assistant_message // "no message"')
if [ ${#FULL_MSG} -gt 20 ]; then
    MSG="${FULL_MSG:0:20}..."
else
    MSG="$FULL_MSG"
fi

# Docker container: always notify via socat socket
if [ -f /.dockerenv ]; then
    if [ -S "$NOTIFY_SOCKET" ]; then
        echo "Docker: Claude ($EVENT) $PROJECT|$MSG" | socat - UNIX-CONNECT:"$NOTIFY_SOCKET" &
    fi
    exit 0
fi

if ! command -v hyprctl >/dev/null; then
    exit
fi

# Check if the active Hyprland window is our terminal
# WINDOW_PID is set in zshrc to the foot PID (works regardless of Zellij)
active_pid=$(hyprctl activewindow -j | jq -r '.pid')
if [ "$active_pid" != "$TERMINAL_WINDOW_PID" ]; then
    notify-send "Claude ($EVENT) $PROJECT" "$MSG"
    exit 0
fi

# Not in Zellij — nothing more to check
if [ -z "$ZELLIJ" ] || [ -z "$ZELLIJ_PANE_ID" ]; then
    exit 0
fi

# Check if our pane is the focused pane
focused_pane=$(zellij action list-panes --state --json 2>/dev/null |
    jq -r '.[] | select(.is_plugin == false and .is_focused == true) | .id')
if [ "$focused_pane" != "$ZELLIJ_PANE_ID" ]; then
    notify-send "Claude ($EVENT) $PROJECT" "$MSG"
fi
