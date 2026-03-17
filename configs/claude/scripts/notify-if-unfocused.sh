#!/bin/bash
# Send a notification only if the terminal running this process is not focused.
# Walks up the process tree and checks against Hyprland's active window PID.

active_pid=$(hyprctl activewindow -j | jq -r '.pid')
pid=$$
while [ "$pid" -gt 1 ]; do
    [ "$pid" = "$active_pid" ] && exit 0
    pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
done

notify-send 'Claude Code' "$1"
