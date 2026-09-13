#!/usr/bin/env bash
#
# Sync Remmina profiles between this repo and ~/.local/share/remmina.
#
#   diff  Compare saved settings, ignoring window size and key order.
#   pull  Copy local profiles into the repo.
#   push  Copy repo profiles locally; FORCE=1 allows overwriting local changes.
#
# Not a dotbot symlink because Remmina rewrites the whole profile on every save,
# with the keys in a different order and the window size included, so every
# session left the repo dirty.
#
set -eu

repo_dir=$(cd "$(dirname "$0")/../configs/remmina" && pwd)
local_dir=$HOME/.local/share/remmina

if [ -L "$local_dir" ]; then
    echo "$local_dir is still the old dotbot symlink — rm it first" >&2
    exit 1
fi

# Print settings in a consistent order, without window size.
normalize_profile() {
    local profile=$1

    # The [remmina] header is dropped and reprinted because sorting would move it.
    echo "[remmina]"
    grep -v '^\[remmina\]' "$profile" | grep -v '^window_' | LC_ALL=C sort
}

copy_normalized_profiles() {
    local source_dir=$1
    local destination_dir=$2
    local profile

    mkdir -p "$destination_dir"
    for profile in "$source_dir"/*.remmina; do
        # An empty directory leaves the *.remmina glob unexpanded.
        if [ ! -e "$profile" ]; then
            continue
        fi

        normalize_profile "$profile" > "$destination_dir/$(basename "$profile")"
    done
}

# Normalize both sides so comparisons only show differences in saved settings.
comparison_dir=$(mktemp -d)
trap 'rm -rf "$comparison_dir"' EXIT
copy_normalized_profiles "$repo_dir" "$comparison_dir/repo"
copy_normalized_profiles "$local_dir" "$comparison_dir/live"

# Use relative paths to keep diff output readable (e.g. "repo/x.remmina").
cd "$comparison_dir"

case ${1:-} in
    diff)
        if diff -ru repo live; then
            echo "repo and $local_dir agree"
        fi
        ;;
    pull)
        copy_normalized_profiles "$local_dir" "$repo_dir"
        echo "pulled into $repo_dir — check git diff"
        ;;
    push)
        # Protect profiles that exist on both sides but have different settings.
        # Ignore "Only in" lines: new repo profiles can be added safely, and
        # profiles that exist only locally are left in place.
        conflicting_profiles=$(diff -rq repo live | grep '^Files ' || true)
        if [ -n "$conflicting_profiles" ] && [ "${FORCE:-0}" != 1 ]; then
            echo "$conflicting_profiles" >&2
            echo "changed on this machine — 'task remmina:pull' to keep, FORCE=1 to discard" >&2
            exit 1
        fi
        copy_normalized_profiles "$repo_dir" "$local_dir"
        echo "pushed to $local_dir"
        ;;
    *)
        echo "usage: $(basename "$0") diff|pull|push" >&2
        exit 2
        ;;
esac
