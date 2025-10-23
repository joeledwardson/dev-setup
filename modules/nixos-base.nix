# Base NixOS configuration shared by all hosts
{ pkgs, lib, pkgs-unstable, ... }:

{

  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager = {
    enable = true;
    plugins = with pkgs; [ networkmanager-openvpn ];
    dns = "systemd-resolved";
  };

  services.resolved = {
    enable = true;
    domains = [ "~." ];
    fallbackDns = [ "1.1.1.1" "1.0.0.1" ]; # Cloudflare
  };

  # having a local postgres database to play around with is IMMENSELY helpful for trying stuff out
  services.postgresql = {
    enable = true;
    ensureDatabases = [ "mydatabase" ];
    authentication = pkgs.lib.mkOverride 10 ''
      #type database  DBuser  auth-method
      local all       all     trust
    '';
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

  # Enable swap (8GB universal size for all systems)
  swapDevices = [{
    device = "/var/lib/swapfile";
    size = 32 * 1024; # 32 GiB
  }];

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

      # hardware tools
      lm_sensors # temperature monitoring
      libinput # input device management tool
      usbutils # usb utilities (like lsusb)
      lshw
      hwinfo
      dmidecode
      fastfetch
      smartmontools
      inxi

      ### nix specific tools
      nix-tree
      nix-du
      devenv

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
      btop # fancy version of top

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
      sql-formatter
      sqls
      mermaid-cli
      marksman

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
        # mediainfo plugin doesnt work with 25.05
        yazi
        # withPlugins not available on 25.05
        (llm.withPlugins {
          llm-anthropic = true;
          llm-ollama = true;
          llm-openai-plugin = true;
        })
      ]);

  # enable docker
  virtualisation.docker.enable = true;

  # this is needed for stuff like markdown-preview extension in neovim with random binaries
  programs.nix-ld.enable = true;
  programs.direnv = { enable = true; };

  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-curses;
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

  networking.firewall = {
    enable = true;
    allowedTCPPortRanges = [
      {
        from = 3000;
        to = 3099;
      } # nodejs apps
      {
        from = 8000;
        to = 9000;
      } # other application ports
    ];
    allowedTCPPorts = [
      # SSH
      22
      # http 
      80
      # https
      443
    ];
  };

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
    # add npm global to path for global nodejs installation
    PATH = [ "$HOME/.npm-global/bin" ];
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

