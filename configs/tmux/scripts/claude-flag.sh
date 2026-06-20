#!/usr/bin/env bash
# Single source of truth for the "CLAUDE!" pending-session title flag.
#
#   claude-flag.sh pending <pane>     mark a window pending  (called by Claude's notify hook)
#   claude-flag.sh seen    <window>   clear a window's mark  (called by tmux focus hooks)
#
# Either way, recompute the server-global @claude_any (any window pending?) from live state and
# push it to all clients. @claude_pending is per-window (drives claude-next.sh's jump + the tab
# label); @claude_any is the global that drives set-titles-string. See tmux.conf.
set -u

case "${1:-}" in
    pending) tmux set-window-option -t "$2" @claude_pending 1  ;;
    seen)    tmux set-window-option -t "$2" @claude_pending '' ;;
    *) echo "usage: claude-flag.sh {pending <pane>|seen <window>}" >&2; exit 2 ;;
esac

# Recompute the global from the live answer, so a missed clear elsewhere can't wedge the title on.
if tmux list-windows -a -F '#{@claude_pending}' 2>/dev/null | grep -q 1; then
    tmux set-option -g @claude_any 1
else
    tmux set-option -g @claude_any ''
fi
tmux refresh-client -S 2>/dev/null || true
