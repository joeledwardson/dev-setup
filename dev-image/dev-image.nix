# Base NixOS configuration shared by all hosts
{ pkgs, pkgs-unstable, ... }:

{

  networking.networkmanager = {
    enable = true;
    dns = "systemd-resolved";
  };

  services.resolved = {
    enable = true;
    domains = [ "~." ];
    fallbackDns = [ "1.1.1.1" "1.0.0.1" ]; # Cloudflare
  };

  programs.nm-applet.enable = true;
  services.automatic-timezoned.enable = true;
  i18n.defaultLocale = "en_GB.UTF-8";

  # enable spice vd agent for virtualisation copy pasting
  # TODO: needed on VM side?
  services.spice-vdagentd.enable = true;

  # creates magic symlinks in /bin so that shebangs like #!/bin/bash dont break on nixos
  services.envfs.enable = true;

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_GB.UTF-8";
    LC_IDENTIFICATION = "en_GB.UTF-8";
    LC_MEASUREMENT = "en_GB.UTF-8";
    LC_MONETARY = "en_GB.UTF-8";
    LC_NAME = "en_GB.UTF-8";
    LC_NUMERIC = "en_GB.UTF-8";
    LC_PAPER = "en_GB.UTF-8";
    LC_TELEPHONE = "en_GB.UTF-8";
    LC_TIME = "en_GB.UTF-8";
  };

  # Configure console keymap
  console.keyMap = "uk";

  # enable libinput (so can run commands like libinput list-devices)
  services.libinput.enable = true;

  fonts = {
    packages = with pkgs; [ nerd-fonts.space-mono ];
    fontconfig = { defaultFonts = { monospace = [ "SpaceMono Nerd Font" ]; }; };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # udisks service is required for udiskie to run properly in hyprland tray
  services.udisks2.enable = true;

  environment.systemPackages = with pkgs; [
    ### core terminal utilities
    git
    vim-full # use full vim so that clipboard is supported, nano also installed by default apparently
    wget
    nix-search-cli # helpful nix-search command
    pciutils # check pci utils
    curl
    unzip
    parted
    nettools # ifconfig, netstat etc
    keyd # allows calling keyd manually (useful for keyd monitor etc..)
    file # get file type
    dig # has nslookup
    busybox # has lsof, fuser, killall
    lsof # better than busybox one (otherwise even lsof -h help isnt available!)
    socat # socket utility
    sheldon # shell plugins
    openssl
    man-pages # otherwise dont have man 5 resolv.conf etc?
    audit # give auditctl
    tcpdump
    nmap
    httpie # nice terminal alternative to postman

    ### hardware tools
    lm_sensors # temperature monitoring
    libinput # input device management tool
    usbutils # usb utilities (like lsusb)
    lshw
    hwinfo
    dmidecode
    fastfetch
    smartmontools
    inxi # get CPU & storage stats

    ### nix specific tools
    nix-tree
    nix-du
    devenv
    nix-index
    nix-inspect

    ### disk management
    udiskie # for status bar disks
    ntfs3g # in case of running `ntfslabel` to re-label windows partition
    exfat # in case of running `exfatlabel` to re-label SD cards etc

    ### languages
    clojure # for metabase
    gcc # for nvim kickstart
    uv
    pipx # use this for poetry so can use shell plugin
    go
    nixd
    nodejs_22 # add nodejs global just for claude code
    lua
    glib # contains gio, useful for viewing all mounts (including SMB etc)
    ruff

    ### TUI style tools
    lazygit
    duf
    gdu # replacement for ncdu
    dust # another replacement for du
    tabiew # CSV terminal viewer (tw is program)

    ### CLI tools
    tldr
    bat
    gh
    gh-markdown-preview
    glab
    tmux
    fzf
    dotbot # required for dotfiles configuration
    google-cloud-sdk
    bitwarden-cli
    eza
    gnumake # provides `make` command
    fd # alternative to find
    delta # fancy syntax highlighting and pager for git
    jq
    yq-go
    kbd # has showkey
    doctoc # for updating my README toc!
    btop # fancy version of top
    navi
    go-task # has taskfile
    zoxide

    ### video processing
    ffmpeg

    ### neovim
    neovim
    ### neovim dependencies
    ripgrep
    prettierd
    stylua
    nixfmt-classic
    tree-sitter
    readline
    libedit
    imagemagick # for image.nvim
    luajitPackages.magick # lua bindings for imagemagick
    sql-formatter
    sqls
    mermaid-cli
    marksman
    shellcheck
    shfmt
    sqlfluff
    systemd-lsp

    ### yazi deps
    ouch
    rich-cli
    exiftool
    mediainfo
    poppler-utils # pdftoppm required

    ### unstable packages
    pkgs-unstable.yazi # mediainfo plugin doesnt work with 25.05
    pkgs-unstable.claude-code # always want latest claude code
    pkgs-unstable.zellij # v0.44.0 currently only available on unstable

    ### terminal emulators
    kitty

    ### graphical applications
    networkmanagerapplet # includes nm-applet (used in polybar)
    brave
    mpv # new video player
    bc # software calculator? required for mpv cutter script
    pinta
    gparted # for when im lazy and dont want to use terminal

    ### desktop core packages
    wlr-randr
    wl-clipboard # Command-line copy/paste utilities
    grim # Screenshot utility
    slurp # Region selection tool
    fuzzel # new launcher to replace rofi/wofi
    xdg-utils # For xdg-open and similar commands
    hyprpaper # hyprland wallpaper
    wev # debug hyprland key events (equivalent of xev on X11)
    swaynotificationcenter # notifications
    wtype
    libnotify # send notifications to daemon
    spice-vdagent # frontend to spice vdagent (clipboard)

    ### more desktop packages
    xdg-utils # for "open with..." integrations
    hyprshot # screenshotting tool
    dragon-drop # dray and drop utility
    tokyonight-gtk-theme # gtk theme
    flat-remix-icon-theme # icons theme
    rofimoji

  ];

  # this is needed for stuff like markdown-preview extension in neovim with random binaries
  programs.nix-ld.enable = true;
  programs.direnv = { enable = true; };

  # enable save preferences in thunar
  programs.xfconf.enable = true;

  programs.zsh.enable = true;
  # set default shell to zsh
  users.defaultUserShell = pkgs.zsh;

  environment.variables = {
    # set default editor to vim
    EDITOR = "vim";
  };

  environment.sessionVariables = {
    # use XDG base directory spec
    XDG_CACHE_HOME = "$HOME/.cache";
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_DATA_HOME = "$HOME/.local/share";
    XDG_STATE_HOME = "$HOME/.local/state";
    # custom directory as per dotbot configuration
    ZDOTDIR = "$HOME/.config/zsh";
    # add npm global to path for global nodejs installation
    PATH = [ "$HOME/.npm-global/bin" ];
    # disable some weird setting from .net, otherwise marksman fails complaining about icu?
    DOTNET_SYSTEM_GLOBALIZATION_INVARIANT = "1";
  };

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = { StreamLocalBindUnlink = "yes"; };
  };

  # Add ~/.local/bin to PATH for xdg-open wrapper
  environment.localBinInPath = true;

  # enable flakes and nix command
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # D-Bus is required for many Wayland applications (and probably good to have it in general tbh...)
  services.dbus.enable = true;

  # =======================================
  # System version
  # =======================================
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

}

