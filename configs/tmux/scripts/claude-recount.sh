#!/usr/bin/env bash
# Recompute the global "any window has a pending Claude session?" flag (@claude_any) that drives
# the terminal title. Run from the window/pane-change hooks after they unset the focused window's
# marker inline. Reads the live answer, so a missed clear elsewhere can't wedge the title on.
set -u
if tmux list-windows -a -F '#{@claude_pending}' 2>/dev/null | grep -q 1; then
    tmux set-option -g @claude_any 1
else
    tmux set-option -g @claude_any ''
fi
tmux refresh-client -S 2>/dev/null || true
