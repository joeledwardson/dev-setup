# Extended desktop: additional GUI apps, extra terminals, productivity tools
{ pkgs, pkgs-unstable, ... }:
{
  environment.systemPackages = with pkgs; [
    ### extra terminal emulators
    alacritty
    wezterm
    foot
    ghostty

    ### browsers
    firefox
    google-chrome

    ### communication
    slack
    signal-desktop

    ### productivity
    libreoffice
    postman
    remmina # RDP tool
    gparted # for when im lazy and dont want to use terminal

    ### coding editors
    vscode
    code-cursor

    ### media
    mpv # new video player
    bc # software calculator? required for mpv cutter script
    spotify
    shotcut # video editing
    gimp
    lazpaint
    pinta
    guvcview # simple video/image capture

    ### utilities
    scrcpy # android screen copy tool
    nomachine-client
    wifi-qr

    ### dictation (experimental)
    pkgs-unstable.hyprwhspr-rs
    sox
  ];

  # =======================================
  # Greeter Configuration
  # =======================================
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        # hyprland-uwsm.desktop is defined in the wiki (has uwsm) - see docs with nixos here https://wiki.hypr.land/Useful-Utilities/Systemd-start/#uwsm
        # command =
        #   "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd 'uwsm start hyprland-uwsm.desktop'";
        command =
          "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd Hyprland";
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
    StandardError = "journal";
    TTYReset = true;
    TTYVHangup = true;
    TTYVTDisallocate = true;
  };
}
