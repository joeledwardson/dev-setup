choice=$(echo -e "yes\nno" | fuzzel --prompt="are you sure you want to exit?" --dmenu)
if [ "$choice" = "yes" ]; then
    hyprctl dispatch exit
else
    notify-send "cancelled exit"
fi
