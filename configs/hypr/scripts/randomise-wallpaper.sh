# shamelessy stolen from hyperland wiki here: https://wiki.hypr.land/Hypr-Ecosystem/hyprpaper/

WALLPAPER_DIR="$XDG_CONFIG_HOME/hypr/wallpapers/"
if [[ ! -d $WALLPAPER_DIR ]]; then
    echo "wallpaper failed no directory!"
    notify-send -i error "Wallpaper Failed" "Directory does not exist"
    exit 1
fi


# get active wallpaper
CURRENT_WALL=$(hyprctl hyprpaper listloaded)
echo "got current wallpaper to be: $CURRENT_WALL"


# Get a random wallpaper that is not the current one
WALLPAPER=$(find "$WALLPAPER_DIR" -type f ! -name "$(basename "$CURRENT_WALL")" | shuf -n 1)
echo "found  a random wallpaper: $WALLPAPER"

# Apply the selected wallpaper
hyprctl hyprpaper reload ,"$WALLPAPER"
