#!/usr/bin/env bash
# Persistent notification showing hotkeys for the Hyprland "group" submap.
# Triggered by $mainMod ALT, G — see the interactive_group submap in hyprland.lua.
# Replace ID 9998 keeps the bubble in place across re-trigger.
hyprctl dispatch "hl.dsp.submap 'interactive_group'"
notify-send -t 0 -r 9998 \
    "group mode" \
    "t toggle    L lock
h/j/k/l move-in    u move-out
n/p cycle tab     , . reorder
esc/q exit"
