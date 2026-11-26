#!/usr/bin/env bash
# Move the cursor to the centre of the active window and left-click

centre_x=$(hyprctl activewindow -j | jq '.at[0] + .size[0] / 2 | floor')
centre_y=$(hyprctl activewindow -j | jq '.at[1] + .size[1] / 2 | floor')

hyprctl dispatch "hl.dsp.cursor.move({ x = $centre_x, y = $centre_y })"

# 0xC0 = left button down + up
ydotool click 0xC0
