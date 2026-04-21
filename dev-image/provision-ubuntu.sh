#!/bin/bash
set -euo pipefail

# VIBE CODED TRASH
# ubuntu equivalent of my nixos setup to installed my packages and setup my dotfiles

# === 0a. CRITICAL: inotify fix (what killed the last box) ===
sudo tee /etc/sysctl.d/99-inotify.conf >/dev/null <<'EOF'
fs.inotify.max_user_watches=524288
fs.inotify.max_user_instances=8192
fs.inotify.max_queued_events=32768
EOF
sudo sysctl --system

# === 0b. Swap file (16GB — Ubuntu cloud images ship with none) ===
if [ ! -f /swapfile ]; then
  sudo fallocate -l 16G /swapfile
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile
  sudo swapon /swapfile
  echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
fi

# === 0c. Locale (UTF-8 — some cloud images don't set this) ===
sudo locale-gen en_GB.UTF-8
sudo update-locale LANG=en_GB.UTF-8

# === 0d. PATH: add ~/.local/bin for login shells (system-wide) ===
sudo tee /etc/profile.d/local-bin.sh >/dev/null <<'EOF'
if [ -d "$HOME/.local/bin" ] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  export PATH="$HOME/.local/bin:$PATH"
fi
EOF
sudo chmod 644 /etc/profile.d/local-bin.sh

# === 0e. Make zsh source /etc/profile on login (Ubuntu's default zprofile
#         doesn't always do this — without it, /etc/profile.d/* is ignored) ===
sudo tee /etc/zsh/zprofile >/dev/null <<'EOF'
emulate sh -c 'source /etc/profile'
EOF

# === 0f. ZDOTDIR — system-wide so zsh looks in ~/.config/zsh for config ===
sudo tee /etc/zsh/zshenv >/dev/null <<'EOF'
export ZDOTDIR="$HOME/.config/zsh"
EOF

# === 1. Base apt packages ===
sudo apt update
sudo apt install -y \
  openssh-client zsh fzf git man-db tmux direnv jq fd-find ripgrep \
  vim wget unzip net-tools file socat bat \
  build-essential nodejs npm python3 python3-pip python3-venv \
  libpq-dev lua5.4 curl ca-certificates gnupg \
  kitty-terminfo

# apt naming quirks — fd is fdfind, bat is batcat
sudo ln -sf /usr/bin/fdfind /usr/local/bin/fd
sudo ln -sf /usr/bin/batcat /usr/local/bin/bat

# === 2. GitHub CLI (official apt repo) ===
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg |
  sudo gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" |
  sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
sudo apt update && sudo apt install -y gh

# === 3. Tools not in apt (or Ubuntu versions too old) ===
mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"

# Neovim pinned to 0.11.7 (matches your Dockerfile)
NVIM_VERSION=v0.11.7
curl -fsSL "https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux-x86_64.tar.gz" |
  sudo tar -xz -C /opt
sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim

# Zellij
curl -fsSL "https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-unknown-linux-musl.tar.gz" |
  tar -xz -C "$HOME/.local/bin"

# Yazi
curl -fsSL -o /tmp/yazi.zip \
  "https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-musl.zip"
unzip -j -o /tmp/yazi.zip -d "$HOME/.local/bin/" '*/yazi' '*/ya'
chmod +x "$HOME/.local/bin/yazi" "$HOME/.local/bin/ya"

# eza
curl -fsSL "https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-musl.tar.gz" |
  tar -xz -C "$HOME/.local/bin"

# git-delta
DELTA_VERSION=0.18.2
curl -fsSL "https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/delta-${DELTA_VERSION}-x86_64-unknown-linux-musl.tar.gz" |
  tar -xz -C /tmp
sudo mv "/tmp/delta-${DELTA_VERSION}-x86_64-unknown-linux-musl/delta" /usr/local/bin/

# fastfetch
curl -fsSL -o /tmp/fastfetch.deb \
  "https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-amd64.deb"
sudo dpkg -i /tmp/fastfetch.deb || sudo apt-get -f install -y

# glab (GitLab CLI)
curl -fsSL -o /tmp/glab.deb \
  "https://gitlab.com/gitlab-org/cli/-/releases/permalink/latest/downloads/glab_amd64.deb"
sudo dpkg -i /tmp/glab.deb || sudo apt-get -f install -y

# go-task (direct tarball)
TASK_VERSION=v3.40.0
curl -fsSL "https://github.com/go-task/task/releases/download/${TASK_VERSION}/task_linux_amd64.tar.gz" |
  tar -xz -C "$HOME/.local/bin" task
chmod +x "$HOME/.local/bin/task"

# sheldon (using upstream installer — handles arch/version detection)
curl --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh |
  bash -s -- --repo rossmacarthur/sheldon --to "$HOME/.local/bin"

# uv (brings ruff + dotbot)
curl -LsSf https://astral.sh/uv/install.sh | sh
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
uv tool install ruff
uv tool install dotbot

# lua-language-server
LUALS_VERSION=3.13.9
sudo mkdir -p /opt/lua-language-server
curl -fsSL "https://github.com/LuaLS/lua-language-server/releases/download/${LUALS_VERSION}/lua-language-server-${LUALS_VERSION}-linux-x64.tar.gz" |
  sudo tar -xz -C /opt/lua-language-server
sudo ln -sf /opt/lua-language-server/bin/lua-language-server /usr/local/bin/lua-language-server

# typescript (for typescript-tools.nvim)
sudo npm install -g typescript

# Claude Code
curl -sSL https://claude.ai/install.sh | bash

# === 4. dev-setup dotfiles via dotbot ===
cd "$HOME"
if [ ! -d dev-setup ]; then
  git clone https://github.com/joeledwardson/dev-setup.git dev-setup
fi
cd dev-setup
git submodule update --init
~/.local/bin/dotbot -c install.conf.yaml -v

# === 5. zsh as default shell ===
sudo chsh -s "$(which zsh)" "$USER"

# === 6. Neovim: Lazy sync + Mason tools ===
nvim --headless "+Lazy! sync" +qa
nvim --headless "+MasonToolsInstallSync" +qa || echo "MasonToolsInstallSync not available — skipping"

# === 7. sheldon lock ===
cd "$HOME"
sheldon lock

# === 8. Box-local SSH key ===
[ -f ~/.ssh/id_ed25519 ] || ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N "" -q

echo ""
echo "=== DONE ==="
echo "Log out and back in (zsh + ZDOTDIR + PATH take effect on next login)"
echo ""
echo "Public key for adding to GitHub/GitLab:"
cat ~/.ssh/id_ed25519.pub
