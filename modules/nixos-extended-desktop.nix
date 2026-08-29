# Extended desktop: additional GUI apps, extra terminals, productivity tools
{ pkgs, pkgs-unstable, inputs, ... }: {
  environment.systemPackages = with pkgs; [
    ### printing (GTK front-end; CUPS web UI also at http://localhost:631)
    system-config-printer

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
    cinny-desktop
    # iamb is terminal but its chunky to build from cargo...
    inputs.iamb.packages.${pkgs.system}.default

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

    ### work (rarely used so don't put in base)
    terraform
    cloud-init
    vault

  ];

  # use gnome keywring in remmina
  services.gnome.gnome-keyring.enable = true;
  # enable gnome keywring on login
  security.pam.services.greetd.enableGnomeKeyring = true;

  # having a local postgres database to play around with is IMMENSELY helpful for trying stuff out
  # to connect just use postgres use with `psql --username=postgres`
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
  # postgresql.target is WantedBy=multi-user.target by default, putting it on
  # the graphical.target critical chain. Adding After=multi-user.target keeps
  # auto-start but means it starts after the desktop sequence, not before.
  systemd.targets.postgresql.after = [ "multi-user.target" ];
  # keyboard settings
  services.udev.packages = [ pkgs.via ];

  # VM/spice support
  services.spice-vdagentd.enable = true;

  # printing
  services.printing.enable = true;
  # Driver pool for non-driverless printers (each queue picks its own PPD). The
  # Samsung C460 is actually driverless (IPP Everywhere), so it uses none of these
  # -- they're just a fallback for other/older printers you might add via the
  # system dialog. Printers themselves are added imperatively (CUPS state in
  # /var/lib/cups) so they stay per-machine and don't break on other networks.
  services.printing.drivers = with pkgs; [
    samsung-unified-linux-driver
    gutenprint # huge generic set (Epson, Canon, many others)
    hplip # HP
  ];

  # mDNS/DNS-SD so network printers (and scanners) are auto-discovered.
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # keyboard building config
  hardware.keyboard.qmk.enable = true;

  # =======================================
  # Greeter Configuration
  # =======================================
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
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
    StandardError = "journal";
    TTYReset = true;
    TTYVHangup = true;
    TTYVTDisallocate = true;
  };
}
