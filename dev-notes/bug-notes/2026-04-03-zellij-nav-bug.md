# Task for claude
Your task is as follows
## Bug
I have configured (see symlinks) zellij and neovim to work together via vim-zellij-navigator  and zellij-nav.nvim.

However, on the zellij side (no nvim) thisworks absolutely fine UNTIL I a) open a session and create 2 splits to the right. b) open another session, and use the session manager in second zellij to connect to the first session. c) disconnect/close 2nd zellij client. d) using part a, from the left pane execute c-l to go right. you shoiuld see it jumps all the way to the right rather than to the middle pane. another bu is if claude is in the riht pane and there is text in the prompt - the text will be clared on navigation to it

Your first task is to re-produce this

## Solution
Your task is to find a solution - you may wish to validate the big is from the mentioned plugin but when i remove     vim-zellij-nav location="https://github.com/hiasr/vim-zellij-navigator/releases/download/0.3.0/vim-zellij-navigator.wasm" and said bindings the problem mysteriously disappears - my instinct is you will need to clone this repo and dig into exactly how it works and there will be some code that causes duplication but it is up to you how to solve the issue.

AFAIK this is the only plugin available - but your task is find a solution whereby we fix vim-zellij-navigator such that c-hjkl works seemlessly aagin without duplication when reconnecting and disconnecting to sessions - with a minimal amount of hacky code and custom implementations strongly NOT preferred - preferred solutions is to fix the existing plugin with minimal changes. BUT you are free to explore all solutions to the problem.


## Code
The dotfiles repo is in ~/dev-setup where i store my configs (all changes should go in here) - i have already symlinked zellij configs from here to dotfiles

## Development
You are running in a sandbox environment and install whatever packages you wish.

You are running in a tmux pane on the left - the pane to the right is your "test" pane where you can send commands and read the output to inspect the state.

Given that the key sending / state inspection is from tmux (as a wrapper parent layer) - you can restart zellij as much as you like upon any changes you are making to its configuration. you also have a "real" terminal to play with so you do not have to use headless mode of zellij.

## Testing
Again, you have a tmux real pane to play with - you can restart zellij and validate with your changes having re-produced the error that it has gone

## Finalisation
Report your investigation, replication, approach, attempts and only report back once you have a credible report of attempted fixes and why they worked or did not work. 

You should not stop either:
- bug is fixed: ENSURE you have completed an end-to-end test to validate before reporting this back
- you are unable to fix the bug: list the possible solutions and why each one doesnt work - or if this requires some kind of change at a core level of zellij? I expect you to exhaust all solutions before reporting this back
