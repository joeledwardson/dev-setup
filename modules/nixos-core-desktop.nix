# Core desktop: minimum packages for a functional Hyprland desktop
{ pkgs, inputs, ... }: {

  environment.systemPackages = with pkgs; [
    ### terminal + browser
    kitty
    brave

    ### desktop core (referenced by hyprland.conf)
    networkmanagerapplet # includes nm-applet (used in polybar)
    pavucontrol # pulse audio GTK application (used in polybar)
    copyq # copy paste manager
    kdePackages.dolphin # default GUI file manager
    kdePackages.qtsvg # svg icons for dolphin
    fuzzel # new launcher to replace rofi/wofi
    hyprpaper # hyprland wallpaper
    hyprshot # screenshotting tool
    grim # Screenshot utility
    slurp # Region selection tool
    wl-clipboard # Command-line copy/paste utilities
    wev # debug hyprland key events (equivalent of xev on X11)
    swaynotificationcenter # notifications
    libnotify # send notifications to daemon
    spice-vdagent # frontend to spice vdagent (clipboard)
    xdg-utils # for "open with..." integrations
    rofimoji # emoji picker
    dragon-drop # drag and drop utility

    ### theming (set in hyprland.conf dconf exec-once)
    tokyonight-gtk-theme
    flat-remix-icon-theme

  ];

  # keyboard settings
  services.udev.packages = [ pkgs.via ];

  # TODO: upower is it needed? battery status etc
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
  # Wayland Configuration
  # =======================================
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

  # wayland variable (should) make chromium/electron apps run better, see here
  # https://nixos.wiki/wiki/Wayland
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
}
