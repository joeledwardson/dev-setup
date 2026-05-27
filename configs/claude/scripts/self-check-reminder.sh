#!/usr/bin/env bash
jq -n '{
  hookSpecificOutput: {
    hookEventName: "PostToolUse",
    additionalContext: "[self-check] If in unattended mode: do modified docs pass documentation skill rules 1-6? Do modified Go files pass vibe coding rules?"
  }
}'
