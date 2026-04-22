# Core desktop: minimum packages for a functional Hyprland desktop
{ pkgs, inputs, ... }: {

  environment.systemPackages = with pkgs; [
    ### terminal + browser
    kitty
    brave

    ### desktop core (referenced by hyprland.conf)
    networkmanagerapplet # nm-applet tray icon
    pavucontrol # pulse audio GTK volume control
    copyq # copy paste manager
    kdePackages.dolphin # default GUI file manager
    kdePackages.qtsvg # svg icons for dolphin
    fuzzel # new launcher to replace rofi/wofi
    hyprpaper # hyprland wallpaper
    hyprshot # screenshotting tool
    grim # Screenshot utility
    slurp # Region selection tool
    wl-clipboard # Command-line copy/paste utilities
    brightnessctl # backlight control (used in hyprland.conf keybinds)
    swayosd # OSD popups for volume/brightness/caps (used in hyprland.conf keybinds)
    hyprsunset # blue light filter
    wev # debug hyprland key events (equivalent of xev on X11)
    swaynotificationcenter # notifications
    libnotify # send notifications to daemon
    xdg-utils # for "open with..." integrations
    rofimoji # emoji picker
    dragon-drop # drag and drop utility

    ### theming (set in hyprland.conf dconf exec-once)
    tokyonight-gtk-theme
    flat-remix-icon-theme

    ### ntfy subscriber CLI (systemd user unit below pipes to notify-send)
    ntfy-sh

  ];

  # Subscribe to the jollof-claude ntfy topic on login and bridge incoming
  # messages into desktop notifications via notify-send → swaync. Token lives
  # in /run/agenix/ntfy-token (provisioned per-host in configuration.nix).
  systemd.user.services.ntfy-claude-subscribe = {
    description = "ntfy subscriber → notify-send bridge for jollof-claude topic";
    after = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    path = [ pkgs.bash pkgs.libnotify ]; # ntfy spawns a shell; needs /bin/sh + notify-send on PATH
    serviceConfig = {
      Type = "simple";
      Restart = "on-failure";
      RestartSec = 5;
      ExecStart = pkgs.writeShellScript "ntfy-claude-subscribe" ''
        if [ ! -r /run/agenix/ntfy-token ]; then
          echo "ntfy-token not readable, exiting" >&2
          exit 0
        fi
        TOKEN=$(cat /run/agenix/ntfy-token)
        exec ${pkgs.ntfy-sh}/bin/ntfy subscribe \
          -u ":$TOKEN" \
          jollof-claude \
          'notify-send "$NTFY_TITLE" "$NTFY_MESSAGE"'
      '';
    };
  };

  # keyboard settings
  services.udev.packages = [ pkgs.via ];

  # TODO: upower is it needed? battery status etc
  services.upower = { enable = true; };

  # enable thunar while i decide if its better than dolpin for me
  programs.thunar = {
    enable = true;
    plugins = with pkgs.xfce; [ thunar-archive-plugin thunar-volman ];
  };

  # thunar dependencies
  programs.xfconf.enable = true; # save thunar preferences
  services.gvfs.enable = true; # mount, trash, and other functionalities
  services.tumbler.enable = true; # thumbnail support for images

  # add qt styling
  qt = {
    enable = true;
    platformTheme = "gtk2"; # or "gnome", "gtk3", "qt5ct"
    style = "adwaita-dark"; # or "breeze", "fusion", etc.
  };

  # =======================================
  # Wayland Configuration
  # =======================================
  programs.nm-applet.enable = true;
  programs.waybar = { enable = true; };
  programs.hyprland = { enable = true; };
  programs.hyprlock.enable = true;

  # XDG Portal for desktop integration
  # NOTE: programs.hyprland.enable already adds xdg-desktop-portal-hyprland
  # Do NOT enable wlr - it conflicts with hyprland's portal (which is a fork of wlr)
  # See: https://wiki.hypr.land/Hypr-Ecosystem/xdg-desktop-portal-hyprland/
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ]; # needed for file picker (XDPH doesn't implement one)
  };

  # wayland variable (should) make chromium/electron apps run better, see here
  # https://nixos.wiki/wiki/Wayland
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
}
