#!/bin/bash
# ensure a service is running, otherwise start it
# Usage: ensure-service.sh <grep_keyword> <command_to_start>
#   $1 - keyword to search to see if process is running
#   #2 - command to start process in background
if [ -z "$1" ]; then
    echo "grep string is empty!";
    exit 1
fi

if [ -z "$2" ]; then
    echo "command is empty!";
    exit 1
fi

if ! pgrep "$1"; then
    echo "starting process with command: $2"
    sh -c "$2 &"
else
    echo "found process(es) with grep: $1"
fi
