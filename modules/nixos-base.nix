# Base NixOS configuration shared by all hosts
{ config, pkgs, lib, ... }:

{

  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable =
    true; # Easiest to use and most distros use this by default.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable network manager applet
  programs.nm-applet.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/London";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_GB.UTF-8";

  # enable spice vd agent for virtualisation copy pasting
  services.spice-vdagentd.enable = true;

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

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  fonts = {
    packages = with pkgs; [ nerd-fonts.space-mono ];
    fontconfig = { defaultFonts = { monospace = [ "SpaceMono Nerd Font" ]; }; };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    ### --- Core system utilities ---
    libnotify # send notifications to daemon (for dunst, mako etc)
    spice-vdagent # frontend to spice vdagent (clipboard)

    ### core terminal utilities
    git
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    killall # useful for waybar scripts when restarting services
    nix-search-cli # helpful nix-search command
    pciutils # check pci utils
    curl
    unzip

    ### terminal emulators
    alacritty
    kitty
    wezterm

    ### graphical applications
    networkmanagerapplet # includes nm-applet (used in polybar)
    pavucontrol # pulse audio GTK application (used in polybar)
    firefox
    (google-chrome.override {
      commandLineArgs = [
        "--enable-features=UseOzonePlatform"
        "--ozone-platform=wayland"
        "--enable-wayland-ime"
      ];
    })
    slack
    copyq # copy paste manager
    vlc
    pomodoro-gtk
    thunar # file managed used in hyprland

    # nix specific tools
    nix-tree
    nix-du

    # Wayland desktop core packages
    wlr-randr
    wl-clipboard # Command-line copy/paste utilities
    mako # Notification daemon
    grim # Screenshot utility
    slurp # Region selection tool (used with grim)
    wofi # Application launcher for Wayland
    xdg-utils # For xdg-open and similar commands
    # xdg-desktop-portal # Desktop integration portals
    # xdg-desktop-portal-wlr # Wayland desktop portal
    # xwayland # For X11 app compatibility
    swww # Wallpaper manager with transitions
    wev # debug hyprland key events (equivalent of xev on X11)

    ### more desktop packages (not specifically hyprland)
    xdg-utils

    ### languages
    clojure # for metabase
    gcc # for nvim kickstart
    volta
    deno
    poetry
    uv
    pipx
    go
    nixd

    ### Database tools
    ruby
    lazysql
    usql # univeral cli for dbs
    visidata
    harlequin
    dblab
    rainfrog
    pgcli
    rabbitmq-server
    postgresql_17

    ### terminals
    zsh
    fish

    ### CLI tools
    tldr
    bat
    lazygit
    aichat
    gh
    glab
    tmux
    fzf
    dotbot # required for dotfiles configuration
    google-cloud-sdk
    bitwarden-cli
    eza
    gnumake
    ranger
    delta
    jq
    kbd # has showkey
    lazydocker
    graphviz # required for madge npm package
    claude-code

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

    ### themes
    oh-my-posh
    oh-my-fish
  ];

  # set default shell to zsh
  users.defaultUserShell = pkgs.zsh;

  environment.sessionVariables = {
    XDG_CONFIG_HOME = "$HOME/.config";
    ZDOTDIR =
      "$HOME/.config/zsh"; # custom directory as per dotbot configuration
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
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd hyprland";
        user = "greeter";
      };
    };
  };

  programs.waybar = { enable = true; };
  programs.hyprland.enable = true;

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

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

}

