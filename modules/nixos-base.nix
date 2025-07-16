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

  services.udisks2.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    ### --- Core system utilities ---
    libnotify # send notifications to daemon
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
    parted

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
    pomodoro-gtk
    pinta

    # nix specific tools
    nix-tree
    nix-du

    # Wayland desktop core packages
    wlr-randr
    wl-clipboard # Command-line copy/paste utilities
    grim # Screenshot utility (TODO, remove?)
    slurp # Region selection tool (TODO, remove?)
    wofi # launcher (TODO, remove?)
    fuzzel # new launcher to replace wofi
    xdg-utils # For xdg-open and similar commands
    # xwayland # For X11 app compatibility
    swww # Wallpaper manager with transitions
    wev # debug hyprland key events (equivalent of xev on X11)
    swaynotificationcenter # notifications

    ### more desktop packages (not specifically hyprland)
    xdg-utils # for "open with..." integrations
    udiskie # for status bar disks
    grimblast # screenshotting tools

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
    usql # univeral cli for dbs (TODO - remove?)
    harlequin # another database TUI (TODO - no schema intellisense?)
    pgcli
    rabbitmq-server
    postgresql_17

    ### terminals
    fish

    ### TUI style tools
    lazygit
    aichat
    lazydocker
    graphviz # required for madge npm package
    claude-code
    ranger # file browser (TODO - can be removed?)
    lf # modern version of ranger (TODO - can be removed)?
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
    gnumake
    fd
    delta
    jq
    kbd # has showkey

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

  programs.thunar.enable = true; # file managed used in hyprland
  programs.zsh.enable = true;
  # set default shell to zsh
  users.defaultUserShell = pkgs.zsh;

  environment.sessionVariables = {
    # prefer specific directory for configuration rather than cluttering home dir
    XDG_CONFIG_HOME = "$HOME/.config";
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

