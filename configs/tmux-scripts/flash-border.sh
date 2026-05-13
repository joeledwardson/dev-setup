#!/usr/bin/env bash
# Flash the active pane border red — edge-of-layout feedback for Alt-hjkl.
# Restore color uses @thm_lavender (set by catppuccin) so it stays in sync
# with the theme. -F asks tmux to expand the format on set.
tmux set -g pane-active-border-style 'fg=red,bold'
hyprctl keyword general:col.active_border "rgba(ff0000ff)" >/dev/null 2>&1
hyprctl keyword group:col.border_active "rgba(ff0000ff)" >/dev/null 2>&1
hyprctl keyword group:groupbar:col.active "rgba(ff0000ff)" >/dev/null 2>&1
sleep 0.2
active_col="rgba(b5e853ee) rgba(b5e853ee) 45deg"
hyprctl keyword general:col.active_border "$active_col" >/dev/null 2>&1
hyprctl keyword group:col.border_active "$active_col" >/dev/null 2>&1
hyprctl keyword group:groupbar:col.active "$active_col" >/dev/null 2>&1
tmux set -gF pane-active-border-style 'fg=#{@thm_lavender}'
