# shamelessy stolen from hyperland wiki here: https://wiki.hypr.land/Hypr-Ecosystem/hyprpaper/

WALLPAPER_DIR="$XDG_CONFIG_HOME/hypr/wallpapers/"
if [[ ! -d $WALLPAPER_DIR ]]; then
    echo "wallpaper failed no directory!"
    notify-send -i error "Wallpaper Failed" "Directory does not exist"
    exit 1
fi


# Get a random wallpaper
# (hyprpaper 0.8 removed `listloaded`, so we can no longer exclude the current one)
WALLPAPER=$(find "$WALLPAPER_DIR" -type f | shuf -n 1)
echo "found  a random wallpaper: $WALLPAPER"

# Apply the selected wallpaper to all monitors (hyprpaper 0.8 removed `reload`; `wallpaper` replaces it)
hyprctl hyprpaper wallpaper ",$WALLPAPER"
