# Minimal NixOS base: everything needed to boot, SSH in, and run nixos-install.
# Imported by nixos-base.nix (workstation) and hosts/installer.
{ pkgs, ... }: {

  boot.supportedFilesystems = [ "ntfs" ];

  networking.networkmanager = {
    enable = true;
    dns    = "systemd-resolved";
  };

  services.resolved = {
    enable      = true;
    domains     = [ "~." ];
    fallbackDns = [ "1.1.1.1" "1.0.0.1" ]; # Cloudflare
  };

  services.automatic-timezoned.enable = true;

  i18n.defaultLocale = "en_GB.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS        = "en_GB.UTF-8";
    LC_IDENTIFICATION = "en_GB.UTF-8";
    LC_MEASUREMENT    = "en_GB.UTF-8";
    LC_MONETARY       = "en_GB.UTF-8";
    LC_NAME           = "en_GB.UTF-8";
    LC_NUMERIC        = "en_GB.UTF-8";
    LC_PAPER          = "en_GB.UTF-8";
    LC_TELEPHONE      = "en_GB.UTF-8";
    LC_TIME           = "en_GB.UTF-8";
  };
  console.keyMap = "uk";

  # magic symlinks in /bin so shebangs like #!/bin/bash don't break on NixOS
  services.envfs.enable = true;

  services.openssh = {
    enable   = true;
    settings.StreamLocalBindUnlink = "yes";
  };

  services.tailscale.enable = true;

  programs.zsh.enable    = true;
  users.defaultUserShell = pkgs.zsh;

  environment.variables.EDITOR = "nvim";
  environment.sessionVariables = {
    XDG_CACHE_HOME  = "$HOME/.cache";
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_DATA_HOME   = "$HOME/.local/share";
    XDG_STATE_HOME  = "$HOME/.local/state";
    ZDOTDIR         = "$HOME/.config/zsh";
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree          = true;

  services.dbus.enable = true;

  environment.systemPackages = with pkgs; [
    ### core
    git
    vim-full # full vim so clipboard works
    neovim
    curl
    wget
    unzip
    file

    ### search / navigation
    ripgrep
    fd
    fzf
    jq
    yq-go
    bat
    eza
    delta
    zoxide
    tree-sitter

    ### shell + dotfiles bootstrap
    tmux
    sheldon
    dotbot

    ### github + docs
    gh
    tldr

    ### disk (needed during install)
    parted
    lsof

    ### hardware inspection
    pciutils
    usbutils
    lshw
    hwinfo
    dmidecode
    inxi

    ### network diag
    nettools # ifconfig, netstat
    dig      # nslookup

    ### nix tooling
    nix-search-cli
    nix-tree
    nix-du
    nix-index

    ### monitoring
    htop
    btop
  ];

  system.stateVersion = "25.05";
}
