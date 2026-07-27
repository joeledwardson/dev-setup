# Extended desktop: additional GUI apps, extra terminals, productivity tools
{ pkgs, pkgs-unstable, ... }:
let
  # iamb 0.0.11 repaints every room as unread on each launch (ulyssa/iamb#564): it tracks
  # unreads itself instead of reading the SDK's persisted receipts/notification counts, so on
  # cold start it has no receipts loaded and defaults everything to unread. PR #579
  # ("Hopefully finally fix unreads") switches to matrix-sdk's unread tracking. Not merged yet,
  # so build from the PR branch. Cargo.lock is vendored so the dep set is pinned (no git deps).
  # TODO: drop this override once #579 lands and nixpkgs bumps iamb past 0.0.11.
  iamb-unreads = pkgs.iamb.overrideAttrs (_old: {
    version = "0.0.11-unreads-pr579";
    src = pkgs.fetchFromGitHub {
      owner = "VAWVAW";
      repo = "iamb";
      rev =
        "01a7732875f8e5a1ce141e3912799c6c67b27e1b"; # branch: unreads-sdk-functions
      hash = "sha256-kvlKxPARbfyqcBhAP1d64oPw1unau/QDxuUzBpQ6QY8=";
    };
    cargoDeps = pkgs.rustPlatform.importCargoLock {
      lockFile = ./iamb-unreads-Cargo.lock;
    };
  });
in {
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
    iamb
    cinny-desktop

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
