choice=$(echo -e "poweroff\nreboot" | fuzzel --prompt="what do you want to do?" --dmenu)
if [[ -z "$choice" ]]; then
    notify-send "restart cancelled"
    exit
fi

systemctl $choice

