#!/usr/bin/env bash
# PermissionRequest hook (Bash): fires ONLY when a command is about to prompt the user.
# Allowlisted and sandbox-cleared commands never reach here, so no false positives.
#
# Unjustified commands are denied and bounced back to Claude to split or replace.
# Appending "# needed: <reason>" falls through to a normal prompt with the reason
# attached, so every prompt the user actually sees carries a justification.
#
# Subsumes the old awk-sed-reminder.sh: awk/sed aren't allowlisted, so they land here.

set -euo pipefail

input=$(cat)
command=$(jq -r '.tool_input.command // ""' <<<"$input")

if grep -qF '# needed:' <<<"$command"; then
  exit 0
fi

reason='STOP — this Bash command is about to interrupt the user with a permission prompt. Do not re-issue it as-is. Work through these in order:

1. READING OR SEARCHING FILES? Use Read (with offset/limit), Glob, or Grep instead of cat / head / tail / find / awk / sed. Those tools are pre-approved and never prompt. This is the single most common cause of an avoidable prompt. Only fall back to awk/sed for a genuine multi-line transform, in-place edit, or complex column logic.

2. CHAINED OR PIPED? (; && || |) Split it into separate tool calls — one command per call. A chain forces the user to review several commands in one opaque blob, and can smuggle a privileged sub-command in behind harmless-looking ones. Independent calls can be issued in parallel in a single message, so this costs nothing.

3. GENUINELY NECESSARY? Re-issue the same command with a trailing justification: `<command>  # needed: <short reason>`. That shows the user a prompt with your reason attached.

Prefer 1 and 2. Only reach for 3 when the command has no non-Bash equivalent — a real state change, a network call, or a tool with no Read/Glob/Grep equivalent.'

jq -n --arg reason "$reason" '{
  hookSpecificOutput: {
    hookEventName: "PermissionRequest",
    decision: "deny",
    reason: $reason
  }
}'
