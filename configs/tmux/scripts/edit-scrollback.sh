#!/usr/bin/env bash
# Capture the current tmux pane's scrollback into a temp file and open it in
# $EDITOR in a new window. Mirrors zellij's "edit pane scrollback" feature.
set -euo pipefail

[ -z "${TMUX:-}" ] && {
  echo "Not inside tmux"
  exit 1
}

tmpfile=$(mktemp -t tmux-scrollback.XXXXXX)

# -p prints to stdout, -S - starts at the top of the scrollback history
tmux capture-pane -pS - >"$tmpfile"

# `+` jumps the editor to the last line (most recent output)
tmux new-window -n scrollback "nvim + '$tmpfile'"
