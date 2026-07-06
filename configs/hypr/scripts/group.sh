# if not in group or solo - toggle and exit
if [[ $(hyprctl activewindow -j | jq -r '.grouped | length') -le 1 ]]; then
    hyprctl dispatch 'hl.dsp.group.toggle()'
    exit 0
fi

# double check want to ungroup - pain in the ass re-grouping everything if done on accident
choice=$(echo -e "yes\nno" | fuzzel --prompt "are you sure you want to ungroup?" --dmenu)

if [[ "$choice" == "yes" ]]; then
    hyprctl dispatch 'hl.dsp.group.toggle()'
else
    notify-send "cancelled"
fi

exit 0
