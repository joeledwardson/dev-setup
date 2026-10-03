#!/usr/bin/env bash
# Stash a verification code from an incoming notification.
set -uo pipefail

codefile="${XDG_RUNTIME_DIR:-/tmp}/last-code"

# first standalone run of 4-8 digits: catches "00001111 is your code" and
# "G-123456", skips phone numbers (too long) and counts like "2 new messages"
code=$(printf '%s' "${SWAYNC_BODY:-}" | grep -oE '\b[0-9]{4,8}\b' | head -1)
if [ -z "$code" ]; then
    exit 0
fi

printf '%s' "$code" > "$codefile"
chmod 600 "$codefile"
