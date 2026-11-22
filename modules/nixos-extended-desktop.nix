# Extended desktop: additional GUI apps, extra terminals, productivity tools
{
  pkgs,
  pkgs-unstable,
  inputs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    ### printing (GTK front-end; CUPS web UI also at http://localhost:631)
    system-config-printer

    ### extra terminal emulators
    alacritty
    foot
    ghostty

    ### browsers
    google-chrome

    ### communication
    slack
    cinny-desktop
    pkgs-unstable.iamb
    gcalcli
    aerc

    ### productivity
    libreoffice
    postman
    remmina # RDP tool
    gparted # for when im lazy and dont want to use terminal
    mise

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
    # TODO: nomachine currently broken on nixos, hash mismatch
    # nomachine-client
    wifi-qr

    ### work (rarely used so don't put in base)
    terraform
    cloud-init
    vault

  ];

  # firefox with right sidebar
  programs.firefox = {
    enable = true;
    # unstable for 159+, which fixes ChatGPT tabs eating all RAM on AMD graphics
    package = pkgs-unstable.firefox;
    preferences = {
      "browser.quitShortcut.disabled" = true; # Ctrl+Q no longer quits, so aoe's live-mode exit key works
      "sidebar.verticalTabs" = true;
      "sidebar.position_start" = false;
      "sidebar.visibility" = "always-show"; # old profiles keep "hide-sidebar" → vertical tabs invisible
      "sidebar.verticalTabs.dragToPinPromo.dismissed" = true; # hide "drag important tabs here" promo
    };
    preferencesStatus = "user";
    # auto-install extensions into every profile (policies apply to all profiles, can't target one)
    # "normal_installed" = installed on launch but can still be disabled per profile
    # keys are extension IDs - look one up with https://addons.mozilla.org/api/v5/addons/addon/<slug>/ (field "guid")
    # extension keyboard shortcuts aren't a policy - see `task firefox:shortcuts`
    policies.ExtensionSettings = {
      # Bitwarden Password Manager
      "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
        installation_mode = "normal_installed";
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
      };
      # uBlock Origin - ad blocker
      "uBlock0@raymondhill.net" = {
        installation_mode = "normal_installed";
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
      };
      # Vimium C - vim-style keyboard navigation (settings sync via firefox account)
      "vimium-c@gdh1995.cn" = {
        installation_mode = "normal_installed";
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/vimium-c/latest.xpi";
      };
      # Dark Reader - dark mode for every site
      "addon@darkreader.org" = {
        installation_mode = "normal_installed";
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/darkreader/latest.xpi";
      };
      # Privacy Badger - tracker blocker
      "jid1-MnnxcxisBPnSXQ@jetpack" = {
        installation_mode = "normal_installed";
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/privacy-badger17/latest.xpi";
      };
      # I don't care about cookies - hides cookie banners
      "jid1-KKzOGWgsW3Ao4Q@jetpack" = {
        installation_mode = "normal_installed";
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/i-dont-care-about-cookies/latest.xpi";
      };
      # Focus Finder - highlights the focused element
      "{a2d591da-352b-4a8b-8a47-071542f81a62}" = {
        installation_mode = "normal_installed";
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/focus-finder/latest.xpi";
      };
      # Focus input element - shortcut to jump to the next input field
      "{8221b638-0d82-43e0-a040-0e19dc0397d7}" = {
        installation_mode = "normal_installed";
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/focus-input-element/latest.xpi";
      };
      # WASD Navigator - virtual cursor / link hopping with WASD
      "wasd@thepreviousone" = {
        installation_mode = "normal_installed";
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/wasd-navigator/latest.xpi";
      };
    };
  };

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

  # VM/spice support
  services.spice-vdagentd.enable = true;

  # printing
  services.printing.enable = true;
  services.printing.drivers = with pkgs; [
    samsung-unified-linux-driver # this (shouldnt) be needed as Samsung C460 uses universal driver (mum and dads printer)
    gutenprint # huge generic set (Epson, Canon, many others)
    hplip # HP
  ];

  # mDNS/DNS-SD so network printers (and scanners) are auto-discovered.
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # keyboards
  hardware.keyboard.qmk.enable = true;
  services.udev.packages = [ pkgs.via ];

  # =======================================
  # Greeter Configuration
  # =======================================
  services.greetd = {
    enable = true;
    # stops systemd boot messages drawing over tuigreet
    useTextGreeter = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd 'uwsm start hyprland-uwsm.desktop'";
        user = "greeter";
      };
    };
  };
}
