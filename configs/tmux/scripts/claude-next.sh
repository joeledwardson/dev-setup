#!/usr/bin/env bash
# Jump to the next tmux window flagged with a pending Claude session (@claude_pending), across
# all sessions, wrapping around. Bound to a key in tmux.conf — your "take me to what needs me".
set -u

cur=$(tmux display-message -p '#{session_name}:#{window_index}')
# "session:index" for each flagged window, in tmux's order; grep . drops the unflagged (empty) lines.
mapfile -t marked < <(
    tmux list-windows -a -F '#{?#{@claude_pending},#{session_name}:#{window_index},}' | grep .
)

if [ "${#marked[@]}" -eq 0 ]; then
    tmux display-message "no pending CLAUDE! windows"
    exit 0
fi

# Default to the first; if we're sitting on a flagged one, step to the next (wrap).
target=${marked[0]}
for i in "${!marked[@]}"; do
    if [ "${marked[$i]}" = "$cur" ]; then
        target=${marked[$(((i + 1) % ${#marked[@]}))]}
        break
    fi
done

tmux switch-client -t "${target%%:*}" 2>/dev/null || true
tmux select-window -t "$target"
