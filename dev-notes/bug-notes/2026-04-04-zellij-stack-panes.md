# Task for claude
Your task is as follows
## Feature
I would like to have the most ergonomic way of stacking 2 panes together. 

Intuitively - this would be a) prompting a stack command and then pressing a key to select the direction in which we stack from and take said pane from a vim based direction hjkl. or b) less ergonomic- marking 2 panes and then running a command to stack

This should prioritise a) ergonomics - the easiest way for me (the user) to stack panes with minmal friction and b) minimal complexity - i.e. if a keybinding can be zellij config natively this is ideal (if possible) - manual script (sh) is preferred less (but not off the table) and a rust based wasm plugin would be bottom priority.

That being said - you are free to explore all options and pick the best

## Code
The dotfiles repo is in ~/dev-setup where i store my configs (all changes should go in here) - i have already symlinked zellij configs from here to dotfiles

## Development
You are running in a sandbox environment and install whatever packages you wish.

You are running in a tmux pane on the left - the pane to the right is your "test" pane where you can send commands and read the output to inspect the state.

Given that the key sending / state inspection is from tmux (as a wrapper parent layer) - you can restart zellij as much as you like upon any changes you are making to its configuration. you also have a "real" terminal to play with so you do not have to use headless mode of zellij.

## Testing
Again, you have a tmux real pane to play with - you can restart zellij and validate with your changes having re-produced the error that it has gone

## Task 1: Investigation
Research the task I have provided and possible solutions or existing solutions.

Report back onces you have researched the landscape and understand the existing solutions available, gaps and how they relate the task, or alternative bespoke solutions.

You should also consider approaches I have not considered or tried to guide you down - purely based off the feature specification.

> A good example is a feature I asked for in zellij for a plugin to enter a mode where you press hjkl to select a direction to a pane to stack - turns out I was not aware of the grouping feature which HAS stack functionality built in - no additional code required. This is the time to report back these kind of solutions

## Task 2: Finalisation
Report your investigation, replication, approach, attempts and only report back once you have a credible report of attempted fixes and why they worked or did not work. 

You should not stop either:
- you have found a solution: ENSURE you have completed an end-to-end test to validate before reporting this back
- you are unable to fix the bug: list the possible solutions and why each one doesnt work - or if this requires some kind of change at a core level of zellij? I expect you to exhaust all solutions before reporting this back
