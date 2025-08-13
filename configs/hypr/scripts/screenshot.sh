choice=$(echo -e "area\nwindow\noutput" | fuzzel --prompt="select your screenshot option" --dmenu)
if [[ -z "$choice" ]]; then
    notify-send "screenshot cancelled"
    exit
fi
if [[ "$choice" == "area" ]]; then
    hyprshot -m region --clipboard-only
else
    hyprshot -m active -m "$choice" --clipboard-only
fi

