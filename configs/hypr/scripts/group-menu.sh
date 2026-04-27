#!/bin/bash
# Persistent notification showing hotkeys for the Hyprland "group" submap.
# Triggered by $mainMod ALT, G — see hyprland.conf submap definition.
# Replace ID 9998 keeps the bubble in place across re-trigger.

notify-send -t 0 -r 9998 \
    "group mode" \
    "t toggle    L lock
h/j/k/l move-in    u move-out
n/p cycle tab     , . reorder
esc/q exit"
