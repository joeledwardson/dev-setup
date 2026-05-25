# Extended desktop: additional GUI apps, extra terminals, productivity tools
{ pkgs, pkgs-unstable, ... }: {
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

    ### virtualisation
    spice-vdagent # frontend to spice vdagent (clipboard sharing in VMs)

    ### keyboards
    qmk

    ### utilities
    scrcpy # android screen copy tool
    nomachine-client
    wifi-qr

    ### dictation (experimental)
    pkgs-unstable.hyprwhspr-rs
    sox
  ];

  # use gnome keywring in remmina
  services.gnome.gnome-keyring.enable = true;
  # enable gnome keywring on login
  security.pam.services.greetd.enableGnomeKeyring = true;

  # having a local postgres database to play around with is IMMENSELY helpful for trying stuff out
  services.postgresql = {
    enable = true;
    ensureDatabases = [ "mydatabase" ];
    extensions = ps: [ ps.plpgsql_check ];
    authentication = pkgs.lib.mkOverride 10 ''
      #type  database  DBuser  origin          auth-method
      local  all       all                     trust
      host   all       all     127.0.0.1/32    trust
      host   all       all     ::1/128         trust
    '';
  };
  # keyboard settings
  services.udev.packages = [ pkgs.via ];

  # VM/spice support
  services.spice-vdagentd.enable = true;

  # printing
  services.printing.enable = true;

  # keyboard building config
  hardware.keyboard.qmk.enable = true;

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
        # command =
        #   "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd Hyprland";
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
