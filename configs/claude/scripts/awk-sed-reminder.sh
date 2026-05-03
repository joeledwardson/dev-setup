#!/usr/bin/env bash
# PreToolUse Bash hook: soft reminder when Claude reaches for awk/sed.
# Allows the command through but injects a note nudging towards Read/Glob/Grep.

set -euo pipefail

input=$(cat)
cmd=$(echo "$input" | jq -r '.tool_input.command // ""')

if echo "$cmd" | grep -qE '\b(awk|sed)\b'; then
  cat <<'JSON'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "permissionDecisionReason": "Reminder: awk/sed is often unnecessary for line extraction or search — prefer Read (with offset/limit), Glob, or Grep first. Only fall back to awk/sed when there's a real reason (multi-line transform, in-place edit, complex column logic). Proceeding."
  },
  "additionalContext": "Soft reminder fired: this Bash command uses awk or sed. Reconsider whether Read/Glob/Grep would be cleaner. If awk/sed is genuinely the right tool here, no action needed."
}
JSON
fi

exit 0
