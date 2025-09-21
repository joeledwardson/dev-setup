# Base NixOS configuration shared by all hosts
{ pkgs, lib, pkgs-unstable, ... }:

{

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

  environment.systemPackages = with pkgs;
    [
      ### core terminal utilities
      git
      vim-full # use full vim so that clipboard is supported, nano also installed by default apparently
      wget
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
      busybox # has lsof, fuser, killall
      lsof # better than busybox one (otherwise even lsof -h help isnt available!)
      socat # socket utility
      sheldon # shell plugins

      ### terminal emulators
      alacritty
      kitty
      wezterm

      ### graphical applications
      networkmanagerapplet # includes nm-applet (used in polybar)
      pavucontrol # pulse audio GTK application (used in polybar)
      firefox
      google-chrome
      brave
      slack
      copyq # copy paste manager
      mpv # new video player
      bc # software calculator? required for mpv cutter script
      pinta
      scrcpy # android screen copy tool
      remmina # RDP tool
      gparted # for when im lazy and dont want to use terminal
      libreoffice
      vscode

      ### nix specific tools
      nix-tree
      nix-du
      devenv

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
      kdePackages.dolphin # default GUI file manager
      kdePackages.qtsvg # svg icons for dolphin
      tokyonight-gtk-theme # gtk theme
      flat-remix-icon-theme # icons theme
      signal-desktop
      spotify

      ### disk management
      udiskie # for status bar disks
      ntfs3g # in case of running `ntfslabel` to re-label windows partition
      exfat # in case of running `exfatlabel` to re-label SD cards etc

      ### languages
      clojure # for metabase
      gcc # for nvim kickstart
      deno
      uv
      pipx # use this for poetry so can use shell plugin
      go
      nixd
      fnm
      lua
      glib # contains gio, useful for viewing all mounts (including SMB etc)

      ### Database tools
      ruby
      lazysql
      pgcli
      rabbitmq-server
      postgresql_17

      ### TUI style tools
      lazygit
      lazydocker
      graphviz # required for madge npm package
      tomato-c # pomodoro
      ncdu

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
      yq-go
      kbd # has showkey
      doctoc # for updating my README toc!

      ### video processing
      ffmpeg

      ### neovim
      neovim
      ### dependencies for neovim
      ripgrep
      prettierd
      stylua
      nixfmt-classic
      tree-sitter
      readline
      libedit
      imagemagick # for image.nvim
      luajitPackages.magick # lua bindings for imagemagick

      ### yazi deps
      ouch
      rich-cli
      exiftool
      mediainfo
      poppler-utils # pdftoppm required

      # for gvfs
      wsdd # needed for samba

      # mtp shite
      libmtp
      mtpfs
      simple-mtpfs
      jmtpfs
    ] ++ (
      # packages to be built from unstable nixpkgs
      with pkgs-unstable; [
        # get latest claude code, always releasing new cool stuff
        claude-code
        # mediainfo plugin doesnt work with 25.05
        yazi
        # withPlugins not available on 25.05
        (llm.withPlugins {
          llm-anthropic = true;
          llm-ollama = true;
          llm-openai-plugin = true;
        })
      ]);

  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-curses;
  };

  # enable thunar while i decide if its better than dolpin for me
  programs.thunar = {
    enable = true;
    plugins = with pkgs.xfce; [ thunar-archive-plugin thunar-volman ];
  };
  # enable save preferences in thunar
  programs.xfconf.enable = true;
  # other thunar services
  services.gvfs.enable = true; # Mount, trash, and other functionalities
  services.tumbler.enable = true; # Thumbnail support for images

  services.ollama = {
    enable = true;
    # Optional: preload models, see https://ollama.com/library
    loadModels = [ "deepseek-r1:1.5b" ];
  };

  # Example for /etc/nixos/configuration.nix
  services.syncthing = {
    enable = true;
    openDefaultPorts = true; # Open ports in the firewall for Syncthing
  };

  # see docs, mullvad requires resolved https://nixos.wiki/wiki/Mullvad_VPN
  # services.mullvad-vpn.enable = true;
  # services.resolved.enable = true;

  # services.openvpn.services = {
  #   officeVPN = { config = "config /var/lib/openvpn-work.conf "; };
  # };

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

  programs.fish.enable = true;
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

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # =======================================
  # Wayland Configuration
  # =======================================
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command =
          "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --cmd Hyprland";
        user = "greeter";
      };
    };
  };

  # this is a life saver.
  # literally no documentation about this anywhere.
  # might be good to write about this...
  # https://www.reddit.com/r/NixOS/comments/u0cdpi/tuigreet_with_xmonad_how/
  systemd.services.greetd.serviceConfig = {
    Type = "idle";
    StandardInput = "tty";
    StandardOutput = "tty";
    StandardError = "journal"; # Without this errors will spam on screen
    # Without these bootlogs will spam on screen
    TTYReset = true;
    TTYVHangup = true;
    TTYVTDisallocate = true;
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

