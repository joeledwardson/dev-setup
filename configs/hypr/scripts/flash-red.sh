#!/usr/bin/env bash
# Flash all active borders red, then restore.
# Auto-detects tmux via $TMUX env var.
#
# NOTE: restore colors are hardcoded below. If you change:
#   - Hyprland border color: update RESTORE_HYPR_COLOR (see hyprland.conf)
#   - Tmux theme/border color: update the tmux restore line (uses @thm_lavender from catppuccin)

IN_TMUX=${TMUX:+1}

hyprctl eval "$(cat <<'EOF'
hl.config({
  general  = { ["col.active_border"] = "rgba(ff0000ff)" },
  group    = { ["col.border_active"] = "rgba(ff0000ff)", groupbar = { ["col.active"] = "rgba(ff0000ff)" } },
})
EOF
)" >/dev/null 2>&1
hyprctl dispatch 'hl.dsp.submap("reset")' >/dev/null 2>&1
[ -n "$IN_TMUX" ] && tmux set -g pane-active-border-style 'fg=red,bold'

sleep 0.3

hyprctl eval "$(cat <<'EOF'
local g = { colors = { "rgba(b5e853ee)", "rgba(b5e853ee)" }, angle = 45 }
hl.config({
  general  = { ["col.active_border"] = g },
  group    = { ["col.border_active"] = g, groupbar = { ["col.active"] = "rgba(b5e853ff)" } },
})
EOF
)" >/dev/null 2>&1
hyprctl dispatch 'hl.dsp.submap("reset")' >/dev/null 2>&1
[ -n "$IN_TMUX" ] && tmux set -gF pane-active-border-style 'fg=#{@thm_lavender}'
