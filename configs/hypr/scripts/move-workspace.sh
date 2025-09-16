#!/bin/bash

# get address of active window
current_address=$(hyprctl activeworkspace -j | jq -r ".id")

# move focus to first argv
hyprctl dispatch workspace $1

# give time fo address to update and query it again
sleep 0.1

# temporary change colour to red if focus didn't change, then revert back (to second argv)
new_address=$(hyprctl activeworkspace -j | jq -r ".id")
if [ "$current_address" == "$new_address" ]; then 
    echo "setting red colour..."
    hyprctl keyword general:col.active_border "rgba(d10240ff)"
    sleep 0.4
    echo "setting back to default colour: $2 ..."
    hyprctl keyword general:col.active_border "$2"
fi

