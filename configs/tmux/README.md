# Local and remote tmux picker

`configs/bin/tmux-switcher` is a standalone Python script. Dotbot links it as
`~/.local/bin/tmux-switcher`; no root install or fixed home directory is needed.
The dev image copies the executable to the same location and includes Python.
Requirements: Python 3, tmux, fzf and an SSH client.

Run `dotbot -c install.conf.yaml` from the repo to install the link, then reload
tmux with `task tmux:reload`. You can also run `tmux-switcher` outside tmux.

Put SSH hostnames or aliases in `~/.tmux_remote_hosts`, one per line:

```text
worker-one
user@worker-two
```

Missing or empty file means local only. SSH must already work without a password
prompt, using keys or an agent. The last visited host is listed first, with panes
grouped by session/window name. Agent state and update times come from the pane
options `@agent_name`, `@agent_state`, and `@agent_updated`, if present.

| Where | Key | Action |
| --- | --- | --- |
| tmux | Ctrl+a, then capital S | Open/return to picker |
| tmux | Ctrl+a, then capital O | Go directly to previous host |
| tmux | Ctrl+a, then Space | Cycle layouts |
| picker | Enter | Attach to the selected pane |
| picker | Escape | Return to the current host |
| picker | Ctrl+o | Attach to the previous host |
| picker | Ctrl+r | Reload hosts and panes |
| picker | Ctrl+q | Exit, leaving sessions running |

Escape and previous-host navigation store only hostnames in
`/tmp/tmux-current-hostname` and `/tmp/tmux-previous-hostname`. tmux chooses the
session on reattachment, preferring the most recently used unattached session.
These files are shared by controllers, not separate per terminal.

The controller runs on your starting machine. Attaching runs local tmux or SSH
and waits for detach. The S/O bindings call the script after detaching: inside a
controller-managed client, `open` exits normally and `previous` exits with code
10. SSH carries that exit code back to the controller, which switches hosts.
A directly attached local client starts a controller instead. The environment
marker prevents nested controllers; no daemon or remote-to-local connection is
needed.

On remotes without this script installed, these two bindings are sufficient
when connecting through the picker:

```tmux
bind-key S detach-client
bind-key O detach-client -E 'exit 10'
```

To test the existing Docker trial, run outside tmux:

```sh
docker exec -it --detach-keys=ctrl-] -e TERM=xterm-256color \
  try-switcher-home /root/.local/bin/tmux-switcher
```

`--detach-keys` prevents Docker from buffering Ctrl+p. Changes to the running
controller require quitting and relaunching it; Ctrl+r only reloads the list.
