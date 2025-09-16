#!/bin/bash
choice=$(echo -e "expand-horizontally\nexpand-vertically" | fuzzel --prompt="what do you want to do?" --dmenu)
if [[ -z "$choice" ]]; then
    notify-send "cancelled"
    exit
fi


# get active window address
active_address=$(hyprctl activewindow -j | jq -r '.address')

# get start and end x of window
active_x=$(hyprctl activewindow -j | jq -r '.at[0]')
end_x=$(hyprctl activewindow -j | jq -r '.at[0] + .size[0]')

# get workspace address
workspace_id=$(hyprctl activewindow -j | jq -r '.workspace.id')
if [[ -z "$workspace_id" || -z "$active_address" ]]; then
    notify-send "could not get workspace ID/active window address"
    exit 1
fi

echo "got workspace ID to be: $workspace_id, address to be $active_address and x: $active_x => $end_x"

if [[ "$choice" == 'expand-horizontally' ]]; then
    # get range x values for windows on same workspace
    min_x=$(hyprctl clients -j | jq -r ".[] | select(.workspace.id == $workspace_id) | .at[0]" | sort -n | head -n 1)
    max_x=$(hyprctl clients -j | jq -r ".[] | select(.workspace.id == $workspace_id) | .at[0]" | sort -n --reverse | head -n 1)
    echo "got min x: $min_x and max x: $max_x"

    # check values are valid
    if [[ -z "$min_x" || -z "$max_x" ]]; then
        notify-send "failed to get min/max x"
        exit 1
    fi

    # create jq conditions to get other windows that overlap with the active window's x position
    conditions=$(printf '.address != "%s" and .workspace.id == %s and (.at[0] < %s or (.at[0] + .size[0]) > %s)' \
        "$active_address" "$workspace_id" "$end_x" "$active_x")
    echo "got conditions: $conditions"
    
    # push windwos to special workspace and back again (SHOULD) mean the desired active window swallows up the wanted space
    for window_address in $(hyprctl clients -j | jq -r ".[] | select($conditions and .at[0] < $max_x) | .address"); do
        # Send window to special workspace temporarily
      hyprctl dispatch focuswindow "address:$window_address"
      hyprctl dispatch movetoworkspace special:magic
      # Bring it back to current workspace
      hyprctl dispatch movetoworkspace $workspace_id
    done

    echo "going back to address: $active_address"
    hyprctl dispatch focuswindow "address:$active_address"

fi
