#!/usr/bin/env bash
# Copy the last verification code stashed by configs/swaync/stash-code.sh
# to the clipboard.
#
# Bound to SUPER+SHIFT+C in configs/hypr/hyprland.lua.

set -uo pipefail

codefile="${XDG_RUNTIME_DIR:-/tmp}/last-code"

if [ ! -s "$codefile" ]; then
    notify-send -a verification-code "No code stashed" "Nothing matched since login"
    exit 0
fi

wl-copy < "$codefile"
# code goes in the summary, not the body: a body with digits would re-trigger
# the swaync hook that wrote it
notify-send -a verification-code "Copied $(cat "$codefile")"
