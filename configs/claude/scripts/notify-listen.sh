#!/bin/bash
# Host-side listener for Docker container notifications via socat unix socket.
# Usage: ./notify-listen.sh
# Mount into container: -v /tmp/notify-forward:/tmp/notify-forward

NOTIFY_DIR="/tmp/notify-forward"
NOTIFY_SOCKET="$NOTIFY_DIR/notify.sock"

mkdir -p "$NOTIFY_DIR"

# only remove if it's a socket (not a dir or file)
if [ -S "$NOTIFY_SOCKET" ]; then
    rm -f "$NOTIFY_SOCKET"
elif [ -e "$NOTIFY_SOCKET" ]; then
    echo "Error: $NOTIFY_SOCKET exists but is not a socket" >&2
    exit 1
fi

# clean up socket on exit (ctrl-c, kill, etc)
cleanup() { rm -f "$NOTIFY_SOCKET"; }
trap cleanup EXIT

echo "Listening for notifications on $NOTIFY_SOCKET"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
socat -d UNIX-LISTEN:"$NOTIFY_SOCKET",fork,reuseaddr EXEC:"$SCRIPT_DIR/notify-handler.sh"
