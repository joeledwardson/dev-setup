# Base NixOS configuration shared by all hosts
{ pkgs, inputs, ... }:
let
in {
  # import hyprdynamicmonitors module - this provides the systemd option (i think?)
  imports = [ inputs.hyprdynamicmonitors.nixosModules.default ];

  # hyprdynamicmonitors - auto monitor (for lid etc) - this enables the systemd service
  # there are more options! see https://hyprdynamicmonitors.filipmikina.com/docs/advanced/systemd/#nix
  services.hyprdynamicmonitors = {
    enable = true;
    # enable lid events for laptops
    extraFlags = [ "--enable-lid-events" ];
    configPath = "%h/.config/hyprdynamicmonitors/config.toml";
  };
  environment.systemPackages = with pkgs; [
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

    ### coding editors
    vscode
    code-cursor

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
    gimp
    lazpaint
    guvcview # simple video/image capture
    rofimoji
    nomachine-client
    wifi-qr
    zenity
    # hyprdynamicmonitors from custom github url
    inputs.hyprdynamicmonitors.packages.${pkgs.system}.default
  ];

  # upower required for hyprdynamicmonitors
  services.upower = { enable = true; };

  # enable thunar while i decide if its better than dolpin for me
  programs.thunar = {
    enable = true;
    plugins = with pkgs.xfce; [ thunar-archive-plugin thunar-volman ];
  };

  # add qt styling
  qt = {
    enable = true;
    platformTheme = "gtk2"; # or "gnome", "gtk3", "qt5ct"
    style = "adwaita-dark"; # or "breeze", "fusion", etc.
  };

  # =======================================
  # Greeter Configuration
  # =======================================
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        # hyprland-uwsm.desktop is defined in the wiki (has uwsm) - see docs with nixos here https://wiki.hypr.land/Useful-Utilities/Systemd-start/#uwsm
        command =
          "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd 'uwsm start hyprland-uwsm.desktop'";
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

  # =======================================
  # Wayland Configuration
  # =======================================
  programs.waybar = { enable = true; };
  programs.hyprland = {
    enable = true;
    # systemd graphical-session.target required for hyprdynamicmonitors
    withUWSM = true;
  };
  programs.hyprlock.enable = true;

  # Enable light for brightness control
  programs.light.enable = true;

  # XDG Portal for desktop integration
  xdg.portal = {
    enable = true;
    wlr.enable = true; # Wayland compositor support
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  # wayland variable (should) make chromium/electron apps run better, see here
  # https://nixos.wiki/wiki/Wayland
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
}
