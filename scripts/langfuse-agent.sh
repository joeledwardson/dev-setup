#!/usr/bin/env bash
# Run a traced agent only for the Sparky repo, including its git worktrees.
# Usage: langfuse-agent <feature-id> <stage> <codex|claude> [agent arguments]
set -euo pipefail

if [ "$#" -lt 3 ]; then
  echo "usage: langfuse-agent <feature-id> <stage> <codex|claude> [agent arguments]" >&2
  exit 2
fi

feature_id=$1
stage=$2
agent=$3
shift 3

if [ -z "$feature_id" ] || [ -z "$stage" ]; then
  echo "feature and stage cannot be empty" >&2
  exit 2
fi

case "$feature_id:$stage" in
  *[!a-zA-Z0-9_:-]*) echo "feature and stage may contain only letters, numbers, underscore and hyphen" >&2; exit 2 ;;
esac

case "$agent" in
  codex|claude) ;;
  *) echo "agent must be codex or claude" >&2; exit 2 ;;
esac

repo_git=$(realpath "$(git rev-parse --git-common-dir)")
if [ "$repo_git" != /home/claude/sparky-fitness-ui/.git ]; then
  echo "tracing is currently scoped to sparky-fitness-ui" >&2
  exit 2
fi

set -a
# shellcheck disable=SC1091
. /run/agenix/langfuse-client-env
set +a

export TRACE_TO_LANGFUSE=true
export LANGFUSE_CODEX_TAGS="project:sparky-fitness-ui,feature:$feature_id,stage:$stage"
export CC_LANGFUSE_TRACE_TAGS="$LANGFUSE_CODEX_TAGS"
exec "$agent" "$@"
