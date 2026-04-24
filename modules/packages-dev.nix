# Shared headless dev-tool package list — imported by both:
#   - modules/nixos-base.nix (host NixOS systems)
#   - flake.nix dev-image-base output (Docker image built with dockerTools)
#
# Everything here must work in a headless container: no audio, hardware probes,
# disk management, MTP, desktop-only tools. Host-only extras live in nixos-base.nix.
{ pkgs, pkgs-unstable, pkgs-claude }:

with pkgs; [
  ### core terminal utilities
  git
  vim-full
  wget
  nix-search-cli
  curl
  unzip
  nettools
  file
  dig
  busybox
  lsof
  socat
  sheldon
  openssl
  man-pages
  tcpdump
  nmap
  httpie
  fastfetch
  openssh

  ### nix specific tools
  nix-tree
  nix-du
  devenv
  nix-index
  nix-inspect

  ### languages
  clojure
  gcc
  uv
  pipx
  go
  nixd
  nodejs_22
  lua
  ruff
  ruby
  typescript # provides tsserver for typescript-tools.nvim

  ### Database tools
  lazysql
  pgcli
  postgresql_17

  ### TUI style tools
  lazygit
  lazydocker
  graphviz
  tomato-c
  duf
  gdu
  dust
  tabiew

  ### CLI tools
  tldr
  bat
  gh
  glab
  tmux
  fzf
  dotbot
  google-cloud-sdk
  bitwarden-cli
  eza
  gnumake
  fd
  delta
  jq
  yq-go
  doctoc
  btop
  navi
  terraform
  skopeo
  awscli2
  ssm-session-manager-plugin
  grafana-loki
  ansible
  ansible-lint
  go-task
  zoxide
  vault

  ### video processing
  ffmpeg

  ### neovim
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
  sql-formatter
  sqls
  marksman
  shellcheck
  shfmt
  sqlfluff
  systemd-lsp
  ueberzug

  # diagrams
  mermaid-cli
  d2
  librsvg # provides rsvg-convert

  # other editors
  helix

  ### yazi deps
  ouch
  rich-cli
  exiftool
  mediainfo
  poppler-utils

  ### unstable packages
  pkgs-unstable.postgres-language-server
  pkgs-unstable.yazi
  pkgs-unstable.zellij
  pkgs-claude.claude-code

  (pkgs-unstable.llm.withPlugins { llm-gemini = true; })
]
