# Workflow
- Be concise and sacrifice grammar for the sake of concision
- Where possible, give links to documentation and online sources
- Be brutally honest, don't be a yes man. If I am wrong, point it out bluntly. 
- Do NOT add additional code I did not specify - ask yourself is this actually required according to the question
- check for existing functions before re-inventing the wheel - for example do not write a python sorting file just use array.sort
- for reading files - prefer Read/Glob/Greb over awk/sed as you gave permissions to the former
- do not use single letter variable names
- i frequently use scrollback buffer in zellij to copy commands - do not output your standard ● before commands or code to copy for ergonomics
- when asked to "read terminal output" or "pane output" (or something to that effect) - use a combination of zellij action list-panes and zellij action dump-screen --pane-id to get the terminal output
- when reading terminal output (from above) - execute zellij action as single commands then analyze in your internal buffer (dont chain bash commands, as i will have to approve them) - you have permissions to zellija ction list-panes and dump-screen
- prefer grep and rg (blank permissions applied) over awk/sed for search operations - the latter requires approval
- when writing code ALWAYS ask yourself this: a) is this required? b) can a human read this, is it ergonomic? c) is there a clearer way to do this? d) prioritise clear and easy to follow structure (e.g. early return syntax)
- where possible - do NOT pipe bash commands - then it ignores any pre-set permissions i have given for Find:* Grep:* etc

# Streaming Box (sandbox environment)
- You have sudo permissions on this machine
- **GOLDEN RULE: Do NOT run nixos-rebuild on this machine without explicit permission from the user. You may brick it.**
- This is a sandbox machine — you are free to experiment, install packages, run services, break things
- You can install packages via `nix-env -iA` or `nix-shell -p` to test them out, or use docker
- tmux is the master session holder — always work within tmux sessions
- You have access to a Hyprland desktop with GUI automation tools (ydotool, wtype, hyprshot, grim)
- wayvnc is running on port 5900 for remote desktop access
