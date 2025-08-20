choice=$(echo -e "area\nwindow\noutput" | fuzzel --prompt="select your screenshot option" --dmenu)
if [[ -z "$choice" ]]; then
    notify-send "screenshot cancelled"
    exit
fi

# Small delay to let the menu close and blur to clear
sleep 0.2

if [[ "$choice" == "area" ]]; then
    hyprshot -m region --clipboard-only
else
    hyprshot -m active -m "$choice" --clipboard-only
fi

