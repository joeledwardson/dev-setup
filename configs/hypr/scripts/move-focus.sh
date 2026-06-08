#!/usr/bin/env bash
# Move focus in Hyprland and flash border if focus fails
#
# Usage: move-focus.sh <direction>
#   $1 - Focus direction (l/r/u/d)

# check if (currently) in fullscreen
fullscreen=$(hyprctl activewindow -j | jq -r '.fullscreen')

# get address of active window
current_address=$(hyprctl activewindow -j | jq -r ".address")

# move focus to first argv
hyprctl dispatch "hl.dsp.focus({direction=\"$1\"})"

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
    hyprctl dispatch "hl.dsp.focus({monitor=\"$1\"})"
    sleep 0.1
fi

# check agian if changed
new_address=$(hyprctl activewindow -j | jq -r ".address")
if [ "$current_address" != "$new_address" ]; then
    exit 0
fi

# if we are in fullscreen and focus didnt change monitor then log a warning (cant see flash red)
if [ "$fullscreen" -ne "0" ]; then
    notify-send "PLEB" "cannot change window in fullscreen"
else
    "$(dirname "$0")/flash-red.sh"
fi
exit 1
