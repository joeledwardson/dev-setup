#!/bin/bash
choice=$(echo -e "expand-upwards\nexpand-across" | fuzzel --prompt="what do you want to do?" --dmenu)
if [[ -z "$choice" ]]; then
    notify-send "cancelled"
    exit
fi


# get active window address
active_address=$(hyprctl activewindow -j | jq -r '.address')

# get coords
start_x=$(hyprctl activewindow -j | jq -r '.at[0]')
end_x=$(hyprctl activewindow -j | jq -r '.at[0] + .size[0]')
start_y=$(hyprctl activewindow -j | jq -r '.at[1]')
end_y=$(hyprctl activewindow -j | jq -r '.at[1] + .size[1]')

# get workspace address
workspace_id=$(hyprctl activewindow -j | jq -r '.workspace.id')
if [[ -z "$workspace_id" || -z "$active_address" ]]; then
    notify-send "could not get workspace ID/active window address"
    exit 1
fi

echo "got workspace ID to be: $workspace_id, address to be $active_address"
echo "got x: $start_x => $end_x, y: $start_y => $end_y"


# create jq conditions to get other windows that overlap with the active window's x position
conditions=$(printf '.address != "%s" and .workspace.id == %s' "$active_address" "$workspace_id")

if [[ "$choice" == "expand-upwards" ]]; then
    # for vertical, filter to windows that overlap with x coordinates
    conditions+=" and (.at[0] < $end_x and (.at[0] + .size[0]) > $start_x)"
else
    # horizontal is with overlapping y
    conditions+=" and (.at[1] < $end_y and (.at[1] + .size[1]) > $start_y)"
fi


echo "got conditions: $conditions"

# push windwos to special workspace and back again (SHOULD) mean the desired active window swallows up the wanted space
echo "processing windows...."
for window_address in $(hyprctl clients -j | jq -r ".[] | select($conditions) | .address"); do
    echo "handling window $window_address ....."
    # Send window to special workspace temporarily
    hyprctl dispatch focuswindow "address:$window_address"
    hyprctl dispatch movetoworkspace special:magic
    # Bring it back to current workspace
    hyprctl dispatch movetoworkspace $workspace_id
done
echo "done processing windows...."

echo "going back to address: $active_address"
hyprctl dispatch focuswindow "address:$active_address"

