#!/bin/bash
set -euo pipefail

sudo dnf install -y \
  git zsh tmux findutils curl ca-certificates

# UV installer
curl -LsSf https://astral.sh/uv/install.sh | sh

# zshrc calls `fastfetch` unguarded on login
sudo dnf install -y https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-amd64.rpm

# sheldon install (copied from docs)
curl --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh |
  bash -s -- --repo rossmacarthur/sheldon --to ~/.local/bin

# tmux tpm package manager
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# install fzf
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install

# easiest way for dotbot is via uv
uv tool install dotbot

# === 4. dev-setup dotfiles via dotbot ===
cd "$HOME"
[ -d dev-setup ] || git clone https://github.com/joeledwardson/dev-setup.git dev-setup
cd dev-setup

# dotfiles
dotbot -c install.conf.yaml -v

# set default shell (amazon linux doesnt have chsh)
sudo usermod -s "$(which zsh)" "$USER"

# clone plugins now (check it works)
sheldon lock

echo ""
echo "=== DONE — log out and back in (zsh takes effect on next login) ==="
