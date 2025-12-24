#!/bin/bash

# 1. Get all monitor names
MONITORS=$(hyprctl monitors -j | jq -r '.[].name')

for mon in $MONITORS; do
    echo "selecting monitor $mon"
    # 2. Tell SwayNC to switch its output to this specific monitor
    swaync-client --change-noti-monitor "$mon"

    # 3. Send the notification (using standard notify-send)
    notify-send "Monitor Identified" "Name: $mon" -t 5000

    # Small sleep to ensure SwayNC processes the monitor change
    sleep 1
done

# reset client
swaync-client --reload-config
