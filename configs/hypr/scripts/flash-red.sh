#!/usr/bin/env bash
# Flash the active window's border red for 0.3s then restore.
# Hyprland 0.55 (lua config): `hyprctl keyword` is rejected ("keyword can't
# work with non-legacy parsers") and runtime config changes don't repaint the
# focused window until its focus state next changes. The per-window
# active_border_color prop DOES repaint immediately, for grouped and
# non-grouped windows alike, so flash via set_prop on the active window.
# Restore value must match active_colour in hyprland.lua.

IN_TMUX=${TMUX:+1}

hyprctl dispatch "hl.dsp.window.set_prop({prop='active_border_color', value='rgba(ff0000ff)'})" >/dev/null 2>&1
[ -n "$IN_TMUX" ] && tmux set -g pane-active-border-style 'fg=red,bold'

sleep 0.3

hyprctl dispatch "hl.dsp.window.set_prop({prop='active_border_color', value='rgba(b5e853ee) rgba(b5e853ee) 45deg'})" >/dev/null 2>&1
[ -n "$IN_TMUX" ] && tmux set -gF pane-active-border-style 'fg=#{@thm_lavender}'
