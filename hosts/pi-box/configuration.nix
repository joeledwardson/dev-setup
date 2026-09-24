{ config, pkgs, lib, commonGroups, modulesPath, ... }:

let
  # tailnet name this box is served at (domain shared via modules/tailnet.nix).
  tailnetFqdn = (import ../../modules/tailnet.nix).fqdnFor "pi-box";
  ssh-keys = import ../../secrets/host-keys.nix;
in {
  imports = [
    # Build a bootable Raspberry Pi image: firmware partition (Pi firmware +
    # U-Boot) + an auto-expanding ext4 root, with the extlinux bootloader.
    # This replaces a hand-written hardware-configuration.nix — the module
    # defines the bootloader and filesystems itself. Flash the build output to
    # the USB SSD; the config is baked in (SSH + users), so no console/PiKVM is
    # needed on first boot. Build with:
    #   nix build .#nixosConfigurations.pi-box.config.system.build.sdImage
    "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"

    # Shared secrets, owned by `claude` + group `users` (0440) so the login user
    # can read them (e.g. `llm keys set`). SparkyFitness declares its OWN root-only
    # copies under different names (see sparkyfitness.nix) — these are the general,
    # queryable set, matching the other hosts.
    (import ../../modules/nixos-secrets.nix { owner = "claude"; })
  ];

  # Root lives on a USB-attached SSD in a UASP caddy, so the initrd needs the
  # USB-storage drivers to find the root filesystem at boot.
  boot.initrd.availableKernelModules =
    [ "xhci_pci" "usbhid" "usb_storage" "uas" ];

  # =======================================
  # Swap: zram instead of an SD-card swapfile
  # =======================================
  # nixos-base defines a 32GB swapfile at /var/lib/swapfile. On a Pi that lives
  # on the SD card, and swapping to SD card (terrible random I/O) is what makes
  # the box thrash and feel sluggish. Force it off and use compressed RAM swap
  # instead — no SD-card writes, no wear, no thrash.
  swapDevices = lib.mkForce [ ];
  zramSwap.enable = true;

  # =======================================
  # Big external HDD (bulk/media storage)
  # =======================================
  # ~7TB ext4 drive on USB, mounted at /mnt/big-hdd. The whole point of these
  # options is: IF THE DRIVE IS UNPLUGGED, THE BOX MUST STILL BOOT NORMALLY.
  # That's what took down degen-work — a mount without `nofail` is treated as
  # required-for-boot, so a missing device drops you into emergency mode.
  fileSystems."/mnt/big-hdd" = {
    # Match by filesystem UUID, NOT /dev/sdb1: USB enumeration order isn't
    # stable (sdb today can be sda tomorrow), but the UUID never moves.
    # From `lsblk -f`: sdb1 ext4.
    device = "/dev/disk/by-uuid/115e7867-fda1-4601-94b5-61c1a3b2cfd5";
    fsType = "ext4";
    options = [
      # nofail: a missing device is logged and skipped, not fatal to boot.
      # THIS is the one degen-work lacked.
      "nofail"
      # device-timeout: don't wait the default ~90s for an absent device.
      "x-systemd.device-timeout=10s"
      # Mount normally during boot; no autofs layer or idle unmounting.
    ];
  };

  # Require the real ext4 mount before creating directories. If the disk is
  # absent, NixFlix fails safely instead of creating state on the root disk.
  systemd.services.nixflix-setup-dirs.unitConfig.RequiresMountsFor =
    [ "/mnt/big-hdd" ];

  # =======================================
  # Networking Configuration
  # =======================================
  networking.hostName = "pi-box";
  my.ssh.defaultUser = "claude";
  # NOTE: the raspberry pi in the home wi-fi has a static IP address of 192.168.1.250 for the TV to connect to


  # =======================================
  # Users
  # =======================================
  users.users = {
    jollof = {
      isNormalUser = true;
      openssh.authorizedKeys.keys = ssh-keys.allHosts;
      description = "jollof";
      initialPassword = "password";
      extraGroups = commonGroups;
    };
    claude = {
      isNormalUser = true;
      openssh.authorizedKeys.keys = ssh-keys.allHosts;
      description = "claude-code";
      initialPassword = "password";
      extraGroups = commonGroups;
    };
  };
  # this stops devenv complaing every time we enter into a shell
  nix.settings.trusted-users = [ "root" "jollof" "claude" ];

  services.tailscale.extraUpFlags = [ "--advertise-tags=tag:sandbox" ];

  # kitty terminal support for SSH
  environment.systemPackages = [ pkgs.kitty.terminfo ];
  
  # =======================================
  # nixflix secrets (agenix)
  # =======================================
  # agenix stores ONE value per encrypted file — it cannot split sub-keys out of a
  # single file the way sops did, so every nixflix secret is its own .age file.
  # To provision each one:
  #   1. it is already declared for pi-box in ../../secrets/secrets.nix
  #   2. cd into ../../secrets and run `agenix -e <name>.age`, paste the raw value
  #   3. `task secrets:update` to re-key
  # Owner defaults to root:root 0400, which is what nixflix needs — it reads these
  # at activation (as root) to render each service's config.
  age.secrets = lib.genAttrs [
    "nixflix-sonarr-apikey"
    "nixflix-sonarr-password"
    "nixflix-radarr-apikey"
    "nixflix-radarr-password"
    "nixflix-lidarr-apikey"
    "nixflix-lidarr-password"
    "nixflix-prowlarr-apikey"
    "nixflix-prowlarr-password"
    "nixflix-indexer-nzbgeek"
    "nixflix-jellyfin-apikey"
    "nixflix-jellyfin-admin-password"
    "nixflix-seerr-apikey"
    "nixflix-sabnzbd-apikey"
    "nixflix-sabnzbd-nzbkey"
    "nixflix-sabnzbd-username"
    "nixflix-sabnzbd-password"
    "nixflix-usenet-eweka-username"
    "nixflix-usenet-eweka-password"
    # TODO(vpn): re-add "nixflix-wireguard-conf" when the VPN block is enabled.
  ] (name: { file = ../../secrets/${name}.age; });

  nixflix = {
    enable = true;
    # Bulk data lives on the big external HDD (see fileSystems."/mnt/big-hdd").
    mediaDir = "/mnt/big-hdd/nixflix/media";
    downloadsDir = "/mnt/big-hdd/nixflix/downloads";
    stateDir = "/mnt/big-hdd/nixflix/.state";
    mediaUsers = ["claude" "jollof"]; # was the "myuser" placeholder — set to a real user

    theme = {
      enable = true;
      name = "overseerr";
    };

    # Reverse proxy choose nginx or caddy, not both)
    nginx = {
      enable = true;
      addHostsEntries = true; # Disable this if you have your own DNS configuration
    };
    # caddy = {
    #   enable = true;
    #   addHostsEntries = true;
    # };

    postgres.enable = true;

    sonarr = {
      enable = true;
      openFirewall = true; # tcp 8989
      config = {
        apiKey._secret = config.age.secrets."nixflix-sonarr-apikey".path;
        # nixflix binds every service to 127.0.0.1 when a reverse proxy is on
        # (modules/arr-common/hostConfig.nix). We want http://pi-box:8989 from
        # the LAN and the tailnet, so bind all interfaces. nginx still reaches
        # it on 127.0.0.1, so the proxy keeps working.
        hostConfig.bindAddress = "0.0.0.0";
        hostConfig.password._secret = config.age.secrets."nixflix-sonarr-password".path;
      };
    };

    radarr = {
      enable = true;
      openFirewall = true; # tcp 7878
      config = {
        apiKey._secret = config.age.secrets."nixflix-radarr-apikey".path;
        hostConfig.bindAddress = "0.0.0.0";
        hostConfig.password._secret = config.age.secrets."nixflix-radarr-password".path;
      };
    };

    recyclarr = {
      enable = true;
      # Deletes any profile not named here, so this list must be updated in the
      # same commit as the quality_profiles below or the new profile gets reaped.
      cleanupUnmanagedProfiles = {
        enable = true;
        managedProfiles = [ "HD Bluray + WEB" "WEB-1080p (Alternative)" ];
      };

      # nixflix defaults Radarr to [SQP] SQP-1 (1080p), which gates on
      # minFormatScore 1000. That score comes almost entirely from a release
      # group allowlist, so public usenet indexers rarely clear it and nothing
      # gets grabbed (kiriwalawren/nixflix#305). HD Bluray + WEB uses 0, and its
      # Golden Rule HD group scores x265 HD releases at -10000 — which is also
      # exactly what we want, since no desktop browser direct-plays HEVC.
      # Sonarr is left alone: WEB-1080p (Alternative) already uses 0.
      config.radarr.radarr = {
        quality_definition.type = "movie";
        quality_profiles = [
          {
            trash_id = "d1d67249d3890e49bc12e275d989a7e9"; # HD Bluray + WEB
            reset_unmatched_scores.enabled = true;
          }
        ];
      };
    };

    lidarr = {
      enable = true;
      openFirewall = true; # tcp 8686
      config = {
        apiKey._secret = config.age.secrets."nixflix-lidarr-apikey".path;
        hostConfig.bindAddress = "0.0.0.0";
        hostConfig.password._secret = config.age.secrets."nixflix-lidarr-password".path;
      };
    };

    prowlarr = {
      enable = true;
      openFirewall = true; # tcp 9696
      config = {
        apiKey._secret = config.age.secrets."nixflix-prowlarr-apikey".path;
        hostConfig.bindAddress = "0.0.0.0";
        hostConfig.password._secret = config.age.secrets."nixflix-prowlarr-password".path;
        indexers = [
          {
            # must exactly match Prowlarr's indexer schema name ("NZBgeek",
            # lowercase geek) — nixflix looks the schema up by name via the API
            name = "NZBgeek";
            apiKey._secret = config.age.secrets."nixflix-indexer-nzbgeek".path;
          }
        ];
      };
    };

    usenetClients.sabnzbd = {
      enable = true;
      openFirewall = true; # tcp 8081

      settings = {
        misc = {
          # NOT 8080: mautrix-telegram's appservice defaults to it (nixpkgs
          # mautrix-telegram.nix:35) and wins the race on restarts. SABnzbd loses
          # SILENTLY — find_free_port in SABnzbd.py moves it to some other port
          # rather than failing — and then sabnzbd-categories talks to the bridge
          # and dies on a 404. Everything else (the *arrs' download client, the
          # nginx vhost, the firewall) derives from this one value.
          port = 8081;
          # same reverse-proxy-forces-localhost default as the *arrs
          host = "0.0.0.0";
          # SABnzbd refuses any request whose Host header isn't whitelisted.
          # nixflix only lists the nginx vhost, so add the names we actually
          # browse to. Comma-separated; keep the nginx one or the proxy breaks.
          host_whitelist = "sabnzbd.nixflix,pi-box,${tailnetFqdn}";
          api_key._secret = config.age.secrets."nixflix-sabnzbd-apikey".path;
          nzb_key._secret = config.age.secrets."nixflix-sabnzbd-nzbkey".path;
          username._secret = config.age.secrets."nixflix-sabnzbd-username".path;
          password._secret = config.age.secrets."nixflix-sabnzbd-password".path;
        };

        servers = [
          {
            name = "Eweka";
            host = "sslreader.eweka.nl";
            port = 563;
            username._secret = config.age.secrets."nixflix-usenet-eweka-username".path;
            password._secret = config.age.secrets."nixflix-usenet-eweka-password".path;
            connections = 20;
            ssl = true;
            priority = 0;
            # some stupid setting that caused sabnzbd to silently fail if a video is old?
            retention = 0;
          }
        ];
      };
    };

    jellyfin = {
      enable = true;
      # tcp 8096/8920 + udp 1900/7359 (the udp pair is DLNA/client discovery).
      openFirewall = true;
      # Same reverse-proxy-forces-localhost default as the *arrs, just spelled
      # differently: nixflix pins localNetworkAddresses to ["127.0.0.1"] when a
      # proxy is on (jellyfin/network/options.nix:156), so jellyfin only ever
      # bound to loopback and http://pi-box:8096 refused. Empty list = bind every
      # interface; nginx still reaches it on 127.0.0.1.
      network.localNetworkAddresses = [ ];
      apiKey._secret = config.age.secrets."nixflix-jellyfin-apikey".path;
      users = {
        admin = {
          mutable = false;
          policy = {
            isAdministrator = true;
            # This Pi has no hardware video encoder — /dev/video* doesn't exist,
            # and Jellyfin deprecated the Pi V4L2 path anyway. Software encoding
            # on the Cortex-A72 runs at roughly a third of realtime, so a
            # transcode is never watchable. Refusing playback is the honest
            # failure: you find out immediately that the file is wrong for the
            # client, instead of staring at a buffering spinner.
            enableVideoPlaybackTranscoding = false;
            enableAudioPlaybackTranscoding = false;
            # Remuxing only rewrites the container (mkv -> mp4), no re-encoding,
            # so it's nearly free even here. Leave it on.
            enablePlaybackRemuxing = true;
          };
          password._secret = config.age.secrets."nixflix-jellyfin-admin-password".path;
        };
      };

      # Trickplay generation decodes every video end to end to build the
      # thumbnail strip you see when dragging the seek bar. Chapter images are
      # the same idea. Both default to on AND to running inline with the library
      # scan (jellyfin/libaries/options.nix:144-153), which on a Pi 4 pins all
      # four cores for hours per import and blocks new media from appearing
      # behind it. Cost of turning them off: no seek-bar preview thumbnails.
      libraries = {
        Movies = {
          enableTrickplayImageExtraction = false;
          extractTrickplayImagesDuringLibraryScan = false;
          enableChapterImageExtraction = false;
          extractChapterImagesDuringLibraryScan = false;
        };
        Shows = {
          enableTrickplayImageExtraction = false;
          extractTrickplayImagesDuringLibraryScan = false;
          enableChapterImageExtraction = false;
          extractChapterImagesDuringLibraryScan = false;
        };
      };
    };

    seerr = {
      enable = true;
      openFirewall = true; # tcp 5055
      apiKey._secret = config.age.secrets."nixflix-seerr-apikey".path;
    };

    # TODO(vpn): parked for now. We're usenet-only (SSL + pull-only, no seeding),
    # so a VPN is a privacy nice-to-have (hides usenet use from the ISP), not a
    # requirement. To enable later:
    #   1. re-add the "nixflix-wireguard-conf" secret to the age.secrets list
    #      above and to ../../secrets/secrets.nix, then `agenix -e
    #      nixflix-wireguard-conf.age` (paste the whole wg-quick .conf).
    #   2. uncomment this block; `enable` builds the isolated `wg` netns. Most
    #      services' per-service `vpn.enable` DEFAULTS to the global value — so
    #      flipping this on confines sabnzbd etc. automatically; set
    #      `nixflix.<service>.vpn.enable = false` to exempt one.
    #   3. set accessibleFrom to THIS box's real LAN subnet (check with
    #      `ip addr` on the pi) — it's the inbound allowlist for reaching a
    #      confined service's web UI from your network.
    # vpn = {
    #   enable = true;
    #   wgConfFile = config.age.secrets."nixflix-wireguard-conf".path;
    #   accessibleFrom = [ "192.168.1.0/24" ];
    # };
  };

  # sabnzbd only creates dirs on first job - so create these now with the right permissions
  # there is an open issue about this for qbittorrent but not solved yet ofr sabnzbd https://github.com/kiriwalawren/nixflix/issues/135
  systemd.tmpfiles.settings."10-sabnzbd" =
    let
      completeDir = config.nixflix.usenetClients.sabnzbd.settings.misc.complete_dir;
      categoryDir = { d = { user = "sabnzbd"; group = "media"; mode = "0775"; }; };
    in {
      "${completeDir}/radarr" = categoryDir;
      "${completeDir}/sonarr" = categoryDir;
      "${completeDir}/lidarr" = categoryDir;
      "${completeDir}/prowlarr" = categoryDir;
    };

  # seer has no bindAddres so have to bind to all IPs via host var
  systemd.services.seerr.environment.HOST = lib.mkForce "0.0.0.0";

}
