#!/usr/bin/env bash
#
# Move Remmina profiles between this repo and ~/.local/share/remmina.
#
# Not a dotbot symlink because Remmina rewrites the whole profile on every save,
# with the keys in a different order and the window size included, so every
# session left the repo dirty.
#
set -eu

repo=$(cd "$(dirname "$0")/../configs/remmina" && pwd)
live=$HOME/.local/share/remmina

if [ -L "$live" ]; then
    echo "$live is still the old dotbot symlink — rm it first" >&2
    exit 1
fi

# Print one profile in a fixed shape: no window size, keys in alphabetical order.
# Two profiles printed this way differ only when a setting really differs.
tidy() {
    local profile=$1

    # The [remmina] header is dropped and reprinted because sorting would move it.
    echo "[remmina]"
    grep -v '^\[remmina\]' "$profile" | grep -v '^window_' | LC_ALL=C sort
}

copy_profiles() {
    local from=$1
    local to=$2
    local profile

    mkdir -p "$to"
    for profile in "$from"/*.remmina; do
        # An empty directory leaves the *.remmina glob unexpanded.
        if [ -e "$profile" ]; then
            tidy "$profile" > "$to/$(basename "$profile")"
        fi
    done
}

# Tidied copies of both sides, so diff below compares settings and nothing else.
tidied=$(mktemp -d)
trap 'rm -rf "$tidied"' EXIT
copy_profiles "$repo" "$tidied/repo"
copy_profiles "$live" "$tidied/live"

# So diff labels its output "repo/x.remmina" instead of the temp directory path.
cd "$tidied"

case ${1:-} in
    diff)
        if diff -ru repo live; then
            echo "repo and $live agree"
        fi
        ;;
    pull)
        copy_profiles "$live" "$repo"
        echo "pulled into $repo — check git diff"
        ;;
    push)
        # "Files a and b differ" means a profile exists on both sides and was
        # edited here. "Only in repo" lines are profiles this machine has never
        # seen, which push is meant to add.
        edited_here=$(diff -rq repo live | grep '^Files ' || true)
        if [ -n "$edited_here" ] && [ "${FORCE:-0}" != 1 ]; then
            echo "$edited_here" >&2
            echo "changed on this machine — 'task remmina:pull' to keep, FORCE=1 to discard" >&2
            exit 1
        fi
        copy_profiles "$repo" "$live"
        echo "pushed to $live"
        ;;
    *)
        echo "usage: $(basename "$0") diff|pull|push" >&2
        exit 2
        ;;
esac
