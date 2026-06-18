#!/usr/bin/env bash
# Flash both the active window border and the active tmux pane border red,
# then restore. Bound from tmux.conf's nav binds (M-h/j/k/l at a pane edge,
# M-a/M-d at a window edge) so hitting an edge gives feedback in both the
# compositor and tmux.

# Window border: trigger the lua flash defined in hyprland.lua.
hyprctl eval "FlashActiveBorder()" >/dev/null 2>&1

# tmux pane border: flash in a backgrounded subshell so this returns
# immediately rather than blocking on the sleep; the subshell finishes the
# restore on its own. Capture and restore the original style (set in tmux.conf)
# rather than hardcoding the theme colour.
(
  tmux set -g pane-active-border-style 'fg=red,bold'
  sleep 0.3
  tmux set -g pane-active-border-style "fg=#{@thm_lavender}"
) &
