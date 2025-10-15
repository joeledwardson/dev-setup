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

# get new ID
new_address=$(hyprctl activewindow -j | jq -r ".address")
# if ID different then we have moved, success!
if [ "$current_address" != "$new_address" ]; then 
    exit 0
fi

if [ "$1" == "l" ] || [ "$1" == "r" ]; then
    # try changing monitor if fullscreen
    hyprctl dispatch focusmonitor $1
    sleep 0.1
fi

# check agian if changed
new_address=$(hyprctl activewindow -j | jq -r ".address")
if [ "$current_address" != "$new_address" ]; then 
    exit 0
fi

# temporary change colour to red if focus didn't change, then revert back (to second argv)
notify-send "already at end!"
hyprctl keyword general:col.active_border "rgba(ff0000ff)"
sleep 0.4
hyprctl keyword general:col.active_border "$2"
exit 1
