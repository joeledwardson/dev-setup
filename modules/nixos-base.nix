# Base NixOS configuration shared by all hosts
{ config, pkgs, lib, ... }:

let
in {

  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager = {
    enable = true;
    plugins = with pkgs; [ networkmanager-openvpn ];
  };

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable network manager applet
  programs.nm-applet.enable = true;

  # Set your time zone.
  # time.timeZone = "Europe/London";
  services.automatic-timezoned.enable = true;

  # Select internationalisation properties.
  i18n.defaultLocale = "en_GB.UTF-8";

  # enable spice vd agent for virtualisation copy pasting
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

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;
    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # enable libinput (so can run commands like libinput list-devices)
  services.libinput.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  fonts = {
    packages = with pkgs; [ nerd-fonts.space-mono ];
    fontconfig = { defaultFonts = { monospace = [ "SpaceMono Nerd Font" ]; }; };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # udisks service is required for udiskie to run properly in hyprland tray
  services.udisks2.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    ### --- Core system utilities ---
    libnotify # send notifications to daemon
    spice-vdagent # frontend to spice vdagent (clipboard)

    ### core terminal utilities
    git
    vim-full # use full vim so that clipboard is supported, nano also installed by default apparently
    wget
    killall # useful for waybar scripts when restarting services
    nix-search-cli # helpful nix-search command
    pciutils # check pci utils
    curl
    unzip
    parted
    libinput # input device management tool
    usbutils # usb utilities (like lsusb)
    nettools # ifconfig, netstat etc
    keyd # allows calling keyd manually (useful for keyd monitor etc..)
    file # get file type
    dig # has nslookup

    ### terminal emulators
    alacritty
    kitty
    wezterm

    ### graphical applications
    networkmanagerapplet # includes nm-applet (used in polybar)
    pavucontrol # pulse audio GTK application (used in polybar)
    firefox
    google-chrome
    slack
    copyq # copy paste manager
    vlc
    pinta
    scrcpy # android screen copy tool
    remmina # RDP tool

    ### nix specific tools
    nix-tree
    nix-du

    ### Wayland desktop core packages
    wlr-randr
    wl-clipboard # Command-line copy/paste utilities
    grim # Screenshot utility
    slurp # Region selection tool
    fuzzel # new launcher to replace rofi/wofi
    xdg-utils # For xdg-open and similar commands
    hyprpaper # hyprland wallpaper
    wev # debug hyprland key events (equivalent of xev on X11)
    swaynotificationcenter # notifications

    ### more desktop packages (not specifically hyprland)
    xdg-utils # for "open with..." integrations
    grimblast # screenshotting tools
    dragon-drop # dray and drop utility
    kdePackages.dolphin # default GUI file manager
    kdePackages.qtsvg # svg icons for dolphin
    tokyonight-gtk-theme # gtk theme
    flat-remix-icon-theme # icons theme
    signal-desktop

    ### disk management
    udiskie # for status bar disks
    ntfs3g # in case of running `ntfslabel` to re-label windows partition

    ### languages
    clojure # for metabase
    gcc # for nvim kickstart
    deno
    uv
    pipx # use this for poetry so can use shell plugin
    go
    nixd
    fnm

    ### Database tools
    ruby
    lazysql
    usql # univeral cli for dbs (TODO - remove?)
    harlequin # another database TUI (TODO - no schema intellisense?)
    pgcli
    rabbitmq-server
    postgresql_17

    ### terminals
    fish

    ### TUI style tools
    lazygit
    lazydocker
    graphviz # required for madge npm package
    claude-code
    yazi # as for now, will be my default file manager

    ### CLI tools
    tldr
    bat
    gh
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
    kbd # has showkey
    (llm.withPlugins {
      # LLM access to models by Anthropic, including the Claude series
      llm-anthropic = true;
      # LLM plugin providing access to Ollama models using HTTP API
      llm-ollama = true;
      # OpenAI plugin for LLM
      llm-openai-plugin = true;
    })

    ### video processing
    ffmpeg

    ### neovim
    neovim
    ripgrep
    prettierd
    stylua
    nixfmt-classic
    ### dependencies for neovim
    tree-sitter
    readline
    libedit

  ];

  services.ollama = {
    enable = true;
    # Optional: preload models, see https://ollama.com/library
    loadModels = [ "llama3.2:3b" "deepseek-r1:1.5b" ];
  };

  # add qt styling
  qt = {
    enable = true;
    platformTheme = "gtk2"; # or "gnome", "gtk3", "qt5ct"
    style = "adwaita-dark"; # or "breeze", "fusion", etc.
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      # SSH
      22
      # http 
      80
      # https
      443
      # custom application port (for bot)
      8282
    ];
  };

  # fnm uses dynamic linked executables which requires a hack to work
  # TODO move to nix flakes for node versions
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [ fnm ];

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
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # =======================================
  # Wayland Configuration
  # =======================================
  # Minimal setup that allows using a custom 
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command =
          "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --cmd hyprland";
        user = "greeter";
      };
    };
  };

  programs.waybar = { enable = true; };
  programs.hyprland = { enable = true; };
  programs.hyprlock.enable = true;

  # Enable light for brightness control
  programs.light.enable = true;

  # XDG Portal for desktop integration
  xdg.portal = {
    enable = true;
    wlr.enable = true; # Wayland compositor support
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  # D-Bus is required for many Wayland applications
  services.dbus.enable = true;

  # wayland variable (should) make chromium/electron apps run better, see here
  # https://nixos.wiki/wiki/Wayland
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

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

