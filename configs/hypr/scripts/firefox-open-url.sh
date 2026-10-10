#!/usr/bin/env bash
# Default browser handler: open a link as a new tab in the Firefox window you used last.
#
# Brave runs all profiles in one process, so links land in the last-used window for free.
# Firefox runs one process per profile, so we have to name the profile: running
# `firefox --profile <dir> <url>` while that profile is already open hands the url to the
# running instance as a new tab. Plain `firefox <url>` would start a second instance instead.
#
# Linked onto PATH as ~/.local/bin/firefox-open-url (install.conf.yaml) because xdg-open
# can't parse quoted `sh -c` Exec lines in .desktop files.

url="$1"
fallback_profile="$HOME/.mozilla/firefox/personal-profile"

# focusHistoryID 0 = focused now, higher = focused longer ago
pid=$(hyprctl clients -j | jq -r '[.[] | select(.class == "firefox")] | sort_by(.focusHistoryID) | .[0].pid // empty')

if [ -z "$pid" ]; then
  echo "no firefox window open, using fallback profile $fallback_profile"
  exec firefox --profile "$fallback_profile" "$url"
fi

# the value after --profile in that process's command line (args are null-separated)
profile=$(tr '\0' '\n' <"/proc/$pid/cmdline" | grep -A1 -x -- '--profile' | tail -n1)

if [ -z "$profile" ]; then
  echo "last firefox window (pid $pid) has no --profile, opening in default profile"
  exec firefox "$url"
fi

echo "opening in profile $profile (pid $pid)"
exec firefox --profile "$profile" "$url"
