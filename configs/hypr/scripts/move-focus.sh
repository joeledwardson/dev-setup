#!/bin/bash
# Move focus in Hyprland and flash border if focus fails
#
# Usage: move-focus.sh <direction> <original_border_color>
#   $1 - Focus direction (l/r/u/d)
#   $2 - Original border color to restore after flash (e.g., "rgba(33ccffee)")

# get address of active window
current_address=$(hyprctl activewindow -j | jq -r ".address")

# move focus to first argv
hyprctl dispatch movefocus $1

# give time fo address to update and query it again
sleep 0.1

# temporary change colour to red if focus didn't change, then revert back (to second argv)
new_address=$(hyprctl activewindow -j | jq -r ".address")
if [ "$current_address" == "$new_address" ]; then 
    hyprctl keyword general:col.active_border "rgba(ff0000ff)"
    sleep 0.4
    hyprctl keyword general:col.active_border "$2"
fi

