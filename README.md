# Development setup
# NixOS Setup
If not using a Nix based OS, need to install NixOS (use `--daemon` as its nice to be able to view and restart it using `systemctl`)
See instructions [here](https://nixos.org/download/)

***TODO***
- gcloud completion
- ctrl g without prefix once in copy mode - ctrl G for previous
- learn zsh nav (not vim)
- tmux/xfce indicator for caps/alt/fn keys 

***Done***
- zsh tmux titles not working (new pane doesn't sync with custom title)
- fzf finder with eza (ls replacement, forgot what its called)
- sort out authentication with gh overwritten by nix
- ignore fnm


```bash
$ sh <(curl -L https://nixos.org/nix/install) --daemon
```
the experimental nix and flakes added (see [docs](https://nixos.wiki/wiki/Flakes))
```bash
echo "experimental-features = nix-command flakes" | sudo tee -a /etc/nix/nix.conf
```

then the daemon must be restarted 
```bash
sudo systemctl restart nix-daemon
```

and finally home manager installed (nix command shoulw work now)
```bash
nix run home-manager/release-24.11 -- switch --flake .
```

and the nixGL channel and default added (for OpenGL apps, dont work with linked nix opengl)
```bash
nix-channel --add https://github.com/nix-community/nixGL/archive/main.tar.gz nixgl && nix-channel --update
nix-env -iA nixgl.auto.nixGLDefault   # or replace `nixGLDefault` with your desired wrapper
```

# Git credentials
for gh its as simple as (hopefully this can be absolved into the symlinks in the future)
- gh auth setup-git

for glab apparently this works?:
- git config --global credential.https://gitlab.com.helper '!glab auth git-credential'

no idea how this actually works, but an example of it working from claude is:
```
echo -e "protocol=https\nhost=gitlab.com" | glab auth git-credential get
```

apparently it reads from stdin?

`zshrc` creates a function for cursor, assuming an appimage is in `.local/cursor.AppImage`


# setup AI chat
configuration is version controlled, but API keys are not.

To add API keys (check they exist first, otherwise ignore):

```bash
RUN_SETUP=true
if [ -z "$OPENAI_API_KEY" ]; then
    echo "OPENAI_API_KEY is not set"
    echo "Please set OPENAI_API_KEY and try again"
    RUN_SETUP=false
fi

if [ -z "$CLAUDE_API_KEY" ]; then
    echo "CLAUDE_API_KEY is not set"
    echo "Please set CLAUDE_API_KEY and try again"
    RUN_SETUP=false
fi

if [ "$RUN_SETUP" = true ]; then
    echo "OPENAI_API_KEY=$OPENAI_API_KEY" >> ~/.config/aichat/.env
    echo "CLAUDE_API_KEY=$CLAUDE_API_KEY" >> ~/.config/aichat/.env
fi
```

# Configuration
The `.zshrc` provides a debugging variable which uses `zprof` to log the load times when specified.

To use it, set:
```bash
export ZSH_DEBUGRC=true
```

# summary of custom keybindings

Window Management (Super + key):
- `Super + m` - Maximize window
- `Super + Up/Down/Left/Right` - Tile window in that direction
- `Super + u` - Tile window up-left
- `Super + i` - Tile window up-right
- `Super + j` - Tile window down-left
- `Super + k` - Tile window down-right

Moving Windows Between Monitors (Super + Shift + key):
- `Super + Shift + Up/Down/Left/Right` - Move window to monitor in that direction

Applications:
- `Super + l` - Lock screen
- `Super + v` - Show CopyQ (clipboard manager)
- `Super + x` - App finder
- `Super + e` - Open Thunar (file manager)
- `Super + r` - App finder (collapsed)
- `Shift + Super + s` - Screenshot (region select)
- `Ctrl + Alt + t` - Open Ghostty terminal

Window Switching:
- `Alt + grave` (backtick) - Switch windows
- `Alt + Tab` - Cycle windows
- `Alt + Shift + Tab` - Cycle windows (reverse)


# xfce-config-helper
install xfce config helper
```bash
git clone https://github.com/felipec/xfce-config-helper.git && \
cd xfce-config-helper && \
gem install ruby-dbus && \
make install && \
cd .. && \
rm -rf xfce-config-helper
```

# 60% keyboard notes
what keys will i miss in a 60% keyboard?

up/down/left/right
- solution: caps and jkl;

fn keys
- solution: fn and numbres?

surface pro key has alt, fn and windows on left of space bar
- solution: right cmd not that useful. win useful, alt useful fn useful, ctrl manatory
(could) have fn to right, but i dont like that very much
(could) map caps to fn key, then everything else is still accessible?
also up/down/left/right from jkl; are v acessible

home, end, insert, delete, page up. pade down
- fn u/o for page up/down are easy with caps as fn
- fn plus easy for insert with caps
- fn backspace not so bad 
- could just use fn(caps) h/e for home end

# Non nix packages
These packages require openGL or GPU stuff and i can't find an (easy) workaround yet on home manager, simpler just to install via `dnf`,`apt` whatever OS PC is running on 
- kitty
- ulauncher
