#!/bin/bash
# Called by notify-listen.sh via socat — receives notification on stdin
read line
title="${line%%|*}"
body="${line#*|}"
echo "[$(date +%H:%M:%S)] $title: $body"
notify-send "$title" "$body"
