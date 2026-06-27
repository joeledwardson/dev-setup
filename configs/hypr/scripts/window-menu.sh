#!/usr/bin/env bash
# window-menu.sh — make the active window fill the screen height (expand-upwards)
# or width (expand-across), pushing every other window onto the opposite half.
#
# In:  $1 (optional) "expand-upwards" | "expand-across"; falls back to a fuzzel
#        menu so the SUPER+ALT+m keybinding keeps working.
# Out: active window becomes one half of the dwindle root split, on the axis asked
#        for; all other windows reflow into the other half.
#
# `movetoroot` is a native dwindle command that promotes the active window to one
# half of the root split (Hyprland does all the tree surgery). It fills whichever
# axis the root split currently runs along; `togglesplit` flips that axis when it
# filled the wrong one. (This Hyprland parses dispatch strings as Lua, hence hl.dsp.)

set -euo pipefail

choice="${1:-$(printf 'expand-upwards\nexpand-across' | fuzzel --prompt='what do you want to do?' --dmenu)}"
[[ -z "$choice" ]] && exit 0

layout() { hyprctl dispatch "hl.dsp.layout('$1')" >/dev/null; }

layout movetoroot
read -r width height < <(hyprctl activewindow -j | jq -r '"\(.size[0]) \(.size[1])"')
case "$choice" in
    expand-upwards) (( width  > height )) && layout togglesplit ;;  # want it tall
    expand-across)  (( height > width  )) && layout togglesplit ;;  # want it wide
    *) notify-send "expand" "unknown choice: $choice"; exit 1 ;;
esac
