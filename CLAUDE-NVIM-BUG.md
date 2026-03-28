your task is to figure out why my neovim breaks why screen size changes

- active pane name is called neovim
- you will notice if you full screen the pane (use the zellij  action fullscreen or wahtever its called with --pane id)
- after full screen move up and down the cursor with j and k you will notice some lines start repeating and the drawing system appears to break
- if you quit neovim and restart it the probme is resolved
- all the nvim configs are symlinked and are in this repo - you may tweak as necessary - report your findings to DEV-LOG.md
