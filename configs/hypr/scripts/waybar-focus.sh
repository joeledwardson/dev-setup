#!/bin/bash
# Outputs JSON for waybar custom module — sets class "active" or "inactive"
# based on whether this bar's monitor is the currently focused one.
# Waybar sets WAYBAR_OUTPUT_NAME to the monitor this bar instance is on.

SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

filepath="/tmp/hypr-$(date +%s)"
echo "$(date -u) got it: $WAYBAR_OUTPUT_NAME" >"$filepath"

emit() {
  monitors_json=$(hyprctl monitors -j)
  mon_count=$(echo "$monitors_json" | jq -r '. | length')
  if [ "$mon_count" = '1' ]; then
    return
  fi
  active=$(hyprctl activeworkspace -j | jq -r '.monitor')
  if [ "$active" = "$WAYBAR_OUTPUT_NAME" ]; then
    special=$(echo "$monitors_json" | jq -r --arg mon "$WAYBAR_OUTPUT_NAME" '.[] | select(.name == $mon) | .specialWorkspace.name')
    if [ "$special" = "special:magic" ]; then
      echo "$(date -u) outputting active-magic for monitor $active and output $WAYBAR_OUTPUT_NAME!" >>"$filepath"
      echo '{"text": " ", "class": "monitor-active-magic"}'
    else
      echo "$(date -u) outputting active for monitor $active and output $WAYBAR_OUTPUT_NAME!" >>"$filepath"
      echo '{"text": " ", "class": "monitor-active"}'
    fi
  else
    echo '{"text": " ", "class": "monitor-inactive"}'
    echo "$(date -u) not active for monitor $active and output $WAYBAR_OUTPUT_NAME!" >>"$filepath"
  fi
}

# emit once on startup
emit

valid_events=(
  activewindow
  openwindow
  closewindow
  movewindow
  floating
  changefloatingmode
  activespecial
  activemonitorv2
)

socat -U - UNIX-CONNECT:"$SOCKET" | while IFS= read -r line; do
  event="${line%%>>*}"
  for name in "${valid_events[@]}"; do
    if [[ "$event" == "$name" ]]; then
      echo "$(date -u) emitting for event $name" >>"$filepath"
      emit
      break
    fi
  done
done
