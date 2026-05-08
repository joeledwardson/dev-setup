#!/usr/bin/env bash
# Flash the active pane border red — edge-of-layout feedback for Alt-hjkl.
# Restore color uses @thm_lavender (set by catppuccin) so it stays in sync
# with the theme. -F asks tmux to expand the format on set.
tmux set -g pane-active-border-style 'fg=red,bold'
sleep 0.2
tmux set -gF pane-active-border-style 'fg=#{@thm_lavender}'
