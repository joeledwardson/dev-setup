#!/bin/bash
# Flash all active borders red, then restore.
# Auto-detects tmux via $TMUX env var.
#
# NOTE: restore colors are hardcoded below. If you change:
#   - Hyprland border color: update RESTORE_HYPR_COLOR (see hyprland.conf)
#   - Tmux theme/border color: update the tmux restore line (uses @thm_lavender from catppuccin)

RESTORE_HYPR_COLOR="rgba(b5e853ee) rgba(b5e853ee) 45deg"
IN_TMUX=${TMUX:+1}

# Flash red
hyprctl keyword general:col.active_border "rgba(ff0000ff)" >/dev/null 2>&1
hyprctl keyword group:col.border_active "rgba(ff0000ff)" >/dev/null 2>&1
hyprctl keyword group:groupbar:col.active "rgba(ff0000ff)" >/dev/null 2>&1
[ -n "$IN_TMUX" ] && tmux set -g pane-active-border-style 'fg=red,bold'

sleep 0.3

# Restore
hyprctl keyword general:col.active_border "$RESTORE_HYPR_COLOR" >/dev/null 2>&1
hyprctl keyword group:col.border_active "$RESTORE_HYPR_COLOR" >/dev/null 2>&1
hyprctl keyword group:groupbar:col.active "$RESTORE_HYPR_COLOR" >/dev/null 2>&1
[ -n "$IN_TMUX" ] && tmux set -gF pane-active-border-style 'fg=#{@thm_lavender}'
