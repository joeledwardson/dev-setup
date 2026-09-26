# Core desktop: minimum packages for a functional Hyprland desktop
{ pkgs, inputs, ... }: {

  # block list for vimium sites (handled at the brave level NOT at the vimium extension config level)
  environment.etc."brave/policies/managed/vimium.json".text =
    builtins.toJSON {
      ExtensionSettings."dbepggeogbaibhgnhhndojpepiihcmeb" = {
        runtime_blocked_hosts = [
          "*://mail.google.com"
          "*://pikvm.lcasino.work"
        ];
      };
    };

  environment.systemPackages = with pkgs; [
    ### terminal + browser
    kitty
    brave

    ### desktop core (referenced by hyprland.conf)
    networkmanagerapplet # nm-applet tray icon
    pavucontrol # pulse audio GTK volume control
    cliphist # wayland-native clipboard history manager
    fuzzel # new launcher to replace rofi/wofi
    hyprpaper # hyprland wallpaper
    hyprshot # screenshotting tool
    grim # Screenshot utility
    slurp # Region selection tool
    wl-clipboard # Command-line copy/paste utilities
    brightnessctl # backlight control (used in hyprland.conf keybinds)
    swayosd # OSD popups for volume/brightness/caps (used in hyprland.conf keybinds)
    playerctl # MPRIS media control (XF86AudioPlay/Pause/Next/Prev keybinds → Brave/Chromium etc.)
    hyprsunset # blue light filter
    wev # debug hyprland key events (equivalent of xev on X11)
    swaynotificationcenter # notifications
    libnotify # send notifications to daemon
    swaylock # lock screen
    xdg-utils # for "open with..." integrations
    rofimoji # emoji picker
    dragon-drop # drag and drop utility

    ### theming (set in hyprland.conf dconf exec-once)
    tokyonight-gtk-theme
    flat-remix-icon-theme

    ### ntfy subscriber CLI (systemd user unit below pipes to notify-send)
    ntfy-sh

  ];

  systemd.user.services.hyprpaper = {
    description = "Hyprland wallpaper daemon";
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.hyprpaper}/bin/hyprpaper";
      Restart = "on-failure";
    };
  };

  systemd.user.services.swayosd-server = {
    description = "SwayOSD — OSD popups for volume/brightness";
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.swayosd}/bin/swayosd-server";
      Restart = "on-failure";
    };
  };

  systemd.user.services.udiskie = {
    description = "udiskie automount tray daemon";
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    path = [ pkgs.xdg-utils ];
    serviceConfig = {
      ExecStart = "${pkgs.udiskie}/bin/udiskie --tray --notify";
      Restart = "on-failure";
    };
  };

  systemd.user.services.cliphist = {
    description = "Clipboard history daemon";
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart =
        "${pkgs.bash}/bin/bash -c '${pkgs.wl-clipboard}/bin/wl-paste --watch ${pkgs.cliphist}/bin/cliphist store'";
      Restart = "on-failure";
    };
  };

  # wayland bins off clipboard afterr app closes, this keeps it
  systemd.user.services.wl-clip-persist = {
    description = "Keep clipboard contents alive after the source app exits";
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart =
        "${pkgs.wl-clip-persist}/bin/wl-clip-persist --clipboard regular --ignore-event-on-error --disable-timestamps";
      Restart = "on-failure";
    };
  };


  # subscribe ntfy channel for claude focus events and notify them to desktop
  systemd.user.services.ntfy-claude-subscribe = {
    description =
      "ntfy subscriber → notify-send bridge for jollof-claude topic";
    after = [ "default.target" ];
    wantedBy = [ "default.target" ];
    enable = true;
    path = [
      pkgs.bash
      pkgs.libnotify
    ]; # ntfy spawns a shell; needs /bin/sh + notify-send on PATH
    serviceConfig = {
      Type = "simple";
      Restart = "on-failure";
      RestartSec = 5;
      ExecStart = pkgs.writeShellScript "ntfy-claude-subscribe" ''
        if [ ! -r /run/agenix/ntfy-token ]; then
          echo "ntfy-token not readable, exiting" >&2
          exit 1
        fi
        TOKEN=$(cat /run/agenix/ntfy-token)
        exec ${pkgs.ntfy-sh}/bin/ntfy subscribe \
          -u ":$TOKEN" \
          jollof-claude \
          'notify-send "$NTFY_TITLE" "$NTFY_MESSAGE"'
      '';
    };
  };

  # Fonts only matter on hosts that actually draw glyphs, so they live here
  # rather than in nixos-base.nix (pi-box and degen-bot are headless).
  # symbols-only carries every Nerd Font icon glyph; fontconfig falls back to it
  # for codepoints the text font lacks, so tmux/eza/yazi icons survive whichever
  # monospace is picked below — including an unpatched font.
  # To audition the others live: restart kitty, then `kitten choose-fonts`.
  fonts = {
    packages = with pkgs; [
      nerd-fonts.hack
      nerd-fonts.symbols-only
      nerd-fonts.geist-mono
      nerd-fonts.roboto-mono
      nerd-fonts.jetbrains-mono
      nerd-fonts.commit-mono
    ];
    fontconfig = {
      defaultFonts = {
        monospace = [ "Hack Nerd Font" ];
        sansSerif = [ "DejaVu Sans" ];
        serif = [ "DejaVu Serif" ];
      };
    };
  };

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
  # Boot behaviour
  # =======================================
  # NM-wait-online blocks graphical.target for 35s+ while waiting for DHCP.
  # Docker depends on network-online.target (upstream default), so it drags
  # the entire graphical.target chain behind it. On a desktop we don't need
  # the network fully online before the session starts.
  # See: mdx-docs/docs/dev-log/2026-05.md — NixOS boot investigation
  systemd.services.NetworkManager-wait-online.enable = false;

  # Add memtest86+ to GRUB menu — useful for diagnosing RAM/hardware faults
  boot.loader.grub.memtest86.enable = true;

  # =======================================
  # Wayland Configuration
  # =======================================
  programs.nm-applet.enable = true;
  # ydotool: Wayland input simulation. Runs ydotoold (root UID but sandboxed to
  # /dev/uinput only) and gates the client socket behind the `ydotool` group.
  programs.ydotool.enable = true;
  programs.waybar = { enable = true; };
  programs.hyprland = {
    enable = true;
    withUWSM = true;
  };
  # swaylock needs a PAM entry to authenticate — without this passwords won't work
  security.pam.services.swaylock = { };

  # XDG Portal for desktop integration
  # NOTE: programs.hyprland.enable already adds xdg-desktop-portal-hyprland
  # Do NOT enable wlr - it conflicts with hyprland's portal (which is a fork of wlr)
  # See: https://wiki.hypr.land/Hypr-Ecosystem/xdg-desktop-portal-hyprland/
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
    ]; # needed for file picker (XDPH doesn't implement one)
  };

  # wayland variable (should) make chromium/electron apps run better, see here
  # https://nixos.wiki/wiki/Wayland
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
}
