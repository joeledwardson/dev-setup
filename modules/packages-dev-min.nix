# Minimal headless dev-tool list for the docker dev-image.
#
# Scope: what you actually need inside a `docker run -it` container for
# claude-code + nvim work on a cloned repo. No heavy infra tooling
# (ansible, gcloud, vault, awscli, terraform), no media processing,
# no alternative editors, no DB servers.
#
# Host NixOS systems still use packages-dev.nix — this file is only
# consumed by flake.nix's dev-image-base output.
{ pkgs, pkgs-unstable, pkgs-claude }:

with pkgs; [
  ### shell + core
  git
  curl
  wget
  openssl
  unzip
  file
  busybox
  lsof
  sheldon
  openssh
  dotbot
  gnumake
  less

  ### CLI essentials
  tldr
  bat
  gh
  fzf
  eza
  fd
  jq
  yq-go
  delta
  btop
  ouch
  tmux
  zoxide
  httpie
  go-task
  lazygit
  lazydocker
  navi

  ### nvim editor stack
  neovim
  ripgrep
  prettierd
  stylua
  nixfmt-classic
  tree-sitter
  readline
  libedit
  imagemagick
  luajitPackages.magick
  marksman
  shellcheck
  shfmt
  typescript # tsserver for typescript-tools.nvim

  ### build + languages (minimum for mason + nvim treesitter)
  gcc
  nodejs_22
  lua
  uv # ephemeral python envs

  ### nix
  nixd
  nix-index
  nix-search-cli

  ### diagrams (claude frequently generates these)
  mermaid-cli
  d2
  librsvg

  ### yazi + minimal deps
  pkgs-unstable.yazi
  exiftool
  mediainfo
  poppler-utils

  ### unstable essentials
  pkgs-unstable.zellij
  pkgs-claude.claude-code
]
