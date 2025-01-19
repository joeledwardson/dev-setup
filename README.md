# Development setup
Before anything can be run, ansible must be installed
# NixOS Setup
If not using a Nix based OS, need to install NixOS (use `--daemon` as its nice to be able to view and restart it using `systemctl`)
See instructions [here](https://nixos.org/download/)

***TODO***
- gcloud completion
- ctrl g without prefix once in copy mode - ctrl G for previous
- ignore fnm
- learn zsh nav (not vim)
- sort out authentication with gh overwritten by nix
- try out xremap?
- tmux/xfce indicator for caps/alt/fn keys 

***Done***
- zsh tmux titles not working (new pane doesn't sync with custom title)
- fzf finder with eza (ls replacement, forgot what its called)


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
# Firefox tridactly
Firefox tridactly extension find has some... interesting defaults.

Custom tridcactyl firefox bindings, can be easily applied below in tridactl by typing `:` then pasting the below:
```
source --url https://raw.githubusercontent.com/joeledwardson/dev-setup/refs/heads/main/configs/tridactyl.config
```

# install pipx and ansible
```bash
# install pipx: https://github.com/pypa/pipx?tab=readme-ov-file#on-linux
sudo apt update
sudo apt install pipx
pipx ensurepath
sudo pipx ensurepath --global # optional to allow pipx actions with --global argument

# install ansible: https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html
pipx install --include-deps ansible
```

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

