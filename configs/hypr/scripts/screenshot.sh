choice=$(echo -e "area\nwindow\noutput" | fuzzel --prompt="select your screenshot option" --dmenu)
if [[ -z "$choice" ]]; then
    notify-send "screenshot cancelled"
    exit
fi

to_file=$(echo -e "no\nyes" | fuzzel --prompt="would you like to save to a file?" --dmenu)

if [[ -z "$to_file" ]]; then
    notify-send "screenshot cancelled"
    exit
fi

hyprshot_args=()

if [[ "$to_file" != 'yes' ]]; then
    hyprshot_args+=("--wclipboard-only")
else
    filename="$(date -Ins).png"
    filepath="$HOME/Downloads/$filename"
    hyprshot_args+=("-o" "$HOME/Downloads" "-f" "$filename")
    notify-send "writing to downloads: $filename"
fi

if [[ "$choice" == "area" ]]; then
    hyprshot_args+=("-m" "region")
else
    # pick active monitor/window
    hyprshot_args+=("-m" "$choice" "-m" "active")
fi

# Prints all elements (for debugging)
echo "${hyprshot_args[@]}"

# Small delay to let the menu close and blur to clear
sleep 0.2

hyprshot "${hyprshot_args[@]}"
# TODO: hyprshot package is broken and always returns non-zero:
if [[ "$to_file" != "yes" ]]; then
    exit
fi

if [[ ! -f "$filepath" ]]; then
    notify-send "hyprshot failed: file not created"
    exit
fi

echo -n "$filepath" | wl-copy
notify-send "path copied to clipboard"
