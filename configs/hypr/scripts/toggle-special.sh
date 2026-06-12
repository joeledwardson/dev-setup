#!/bin/sh

# get workspace name
workspacename=$(hyprctl activewindow -j | jq -r '.workspace.name')

if [ "$workspacename" != "special:magic" ]; then
    # not in special workspace, send there
    echo "got workspace name as $workspacename, sending to special..."
    hyprctl dispatch "hl.dsp.window.move({workspace='special:magic'})"
    exit 0
fi

# in special workspace
# note: monitors' .activeWorkspace stays the NORMAL workspace while a special
# workspace is overlaid (special lives in .specialWorkspace), so this correctly
# retrieves the workspace to send the window back to — verified on 0.55
workspaceid=$(hyprctl monitors -j | jq -r '.[] | select(.focused==true) | .activeWorkspace.id')
if [ $? -ne 0 ]; then
    echo "failed to get workspace ID!"
    exit 1
fi

if [ -z "$workspaceid" ]; then
    echo "retrieved workspace ID is blank!"
    exit 1
fi

echo "sending back to retrieved workspace $workspaceid"
hyprctl dispatch "hl.dsp.window.move({workspace=$workspaceid})"
