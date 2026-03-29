#!/bin/bash
# Send a notification only if the terminal running this process is not focused.

if ! command -v hyprctl >/dev/null; then
    exit
fi

# Check if the active Hyprland window is our terminal
# WINDOW_PID is set in zshrc to the foot PID (works regardless of Zellij)
active_pid=$(hyprctl activewindow -j | jq -r '.pid')
if [ "$active_pid" != "$TERMINAL_WINDOW_PID" ]; then
    notify-send 'Claude Code (other window)' "$1"
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
    notify-send 'Claude Code (other pane)' "$1"
fi
