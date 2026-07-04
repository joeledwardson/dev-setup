#!/bin/bash
set -eo pipefail

# tracks the server id of the notificiation that is pinned during recording
NOTIF_ID_FILE=/tmp/hyprwhspr-recording-notif-id

# tracks the playerctl status
PLAYERCTL_ID_FILE=/tmp/hyprwhspr-playerctl-status

# if we're already recording, just stop — clear the pinned notification and bail
if [[ "$(hyprwhspr-rs record status)" == "recording" ]]; then

    # close existing notification (if exists)
    if [[ -f "$NOTIF_ID_FILE" ]]; then
        id=$(<"$NOTIF_ID_FILE")
        # replace existing notif with blank (and 1ms expire time) to kill it
        notify-send "" --replace-id="$id" --expire-time=1
        # remove ID store file
        rm -f "$NOTIF_ID_FILE"
    fi

    # restore playerctl status (if exists)
    if [[ -f "$PLAYERCTL_ID_FILE" ]]; then
        status=$(cat "$PLAYERCTL_ID_FILE")
        if [[ "$status" == "Playing" ]]; then
            playerctl play || notify-send "failed to resume player"
        fi
        # remove store file
        rm -f "$PLAYERCTL_ID_FILE"
    fi

    hyprwhspr-rs record toggle
    exit 0
fi

# record short test clip (3200 samples with 16000frames/s is 0.2s total length)
if ! arecord -q -f S16_LE -r 16000 -c1 --samples=3200 /tmp/test.wav; then
    notify-send "failed to do test recording"
    exit 1
fi

# NOTE: sox writes 'stat' output to stderr, so we must capture with 2>&1
if ! result="$(sox /tmp/test.wav -n stat 2>&1)"; then
    notify-send "failed to analyze test file with sox"
    exit 1
fi

# pull out the max amplitude line, e.g. "Maximum amplitude:     0.045898"
amplitude=$(sed -n 's/^Maximum amplitude:[[:space:]]*//p' <<<"$result")
if [[ -z "$amplitude" ]]; then
    notify-send "could not get max amplitude from sox"
    exit 1
fi

# reduce to just the digits, e.g. "0.045898" -> "0045898"
digits=${amplitude//[^0-9]/}
if [[ -z "$digits" ]]; then
    notify-send "no numbers found in max amplitude"
    exit 1
fi

# if every digit is a zero the mic sent pure silence -> it's muted at the hardware level
if [[ -z "${digits//0/}" ]]; then
    notify-send "mic is muted" "tap the top of the mic to unmute"
    exit 0
fi

# pause player (if playing)
if [[ "$(playerctl status)" == "Playing" ]]; then
    echo "Playing" >$PLAYERCTL_ID_FILE
    playerctl pause || notify-send "failed to pause player"
fi

# start recording session
hyprwhspr-rs record toggle
notif_id=$(notify-send -p -t 0 -u critical "🔴 recording…" "super+alt+r to stop")
printf '%s\n' "$notif_id" >"$NOTIF_ID_FILE"
