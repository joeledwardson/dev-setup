#!/usr/bin/env bash
# Flash active borders red for 0.3s then restore.
# Uses hyprctl keyword (hyprlang syntax) — more reliable than hyprctl eval for runtime color changes.

IN_TMUX=${TMUX:+1}

hyprctl keyword general:col.active_border   "rgba(ff0000ff)"        >/dev/null 2>&1
hyprctl keyword group:col.border_active     "rgba(ff0000ff)"        >/dev/null 2>&1
hyprctl keyword group:groupbar:col.active   "rgba(ff0000ff)"        >/dev/null 2>&1
[ -n "$IN_TMUX" ] && tmux set -g pane-active-border-style 'fg=red,bold'

sleep 0.3

hyprctl keyword general:col.active_border   "rgba(b5e853ee) rgba(b5e853ee) 45deg" >/dev/null 2>&1
hyprctl keyword group:col.border_active     "rgba(b5e853ee) rgba(b5e853ee) 45deg" >/dev/null 2>&1
hyprctl keyword group:groupbar:col.active   "rgba(b5e853ff)"                       >/dev/null 2>&1
[ -n "$IN_TMUX" ] && tmux set -gF pane-active-border-style 'fg=#{@thm_lavender}'
