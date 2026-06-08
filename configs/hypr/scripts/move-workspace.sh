#!/usr/bin/env bash
# get workspace name
workspacename=$(hyprctl activewindow -j | jq -r '.workspace.name')

# if in magic then shouldn't be changing workspace
# its 99% a mistake - changes workspace underneath special but not special itself
if [ "$workspacename" == "special:magic" ]; then
    "$(dirname "$0")/flash-red.sh"
    exit 1
fi

# get address of active window
current_address=$(hyprctl activeworkspace -j | jq -r ".id")
echo "got current address to be: $current_address"

# move focus to first argv
hyprctl dispatch "hl.dsp.focus({workspace=\"$1\"})"

# give time fo address to update and query it again
sleep 0.1

# flash red if focus didn't change
new_address=$(hyprctl activeworkspace -j | jq -r ".id")
echo "new addres is $new_address"
if [ "$current_address" == "$new_address" ]; then
    "$(dirname "$0")/flash-red.sh"
    exit 1
fi
