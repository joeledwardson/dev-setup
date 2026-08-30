{ config, pkgs, lib, commonGroups, modulesPath, ... }:

{
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
      # automount: mount lazily on first access (autofs) instead of at boot, so
      # boot never depends on the drive at all. Empty path until you plug it in.
      "x-systemd.automount"
      # idle-timeout: auto-unmount after 10 min idle for clean replug/remount
      # (drop this line if you'd rather it stay mounted once first accessed).
      "x-systemd.idle-timeout=600"
    ];
  };

  # =======================================
  # Networking Configuration
  # =======================================
  networking.hostName = "pi-box";

  # =======================================
  # Users
  # =======================================
  users.users = {
    jollof = {
      isNormalUser = true;
      description = "jollof";
      initialPassword = "password";
      extraGroups = commonGroups;
    };
    claude = {
      isNormalUser = true;
      description = "claude-code";
      initialPassword = "password";
      extraGroups = commonGroups;
    };
  };
  # this stops devenv complaing every time we enter into a shell
  nix.settings.trusted-users = [ "root" "jollof" "claude" ];

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
      config = {
        apiKey._secret = config.age.secrets."nixflix-sonarr-apikey".path;
        hostConfig.password._secret = config.age.secrets."nixflix-sonarr-password".path;
      };
    };

    radarr = {
      enable = true;
      config = {
        apiKey._secret = config.age.secrets."nixflix-radarr-apikey".path;
        hostConfig.password._secret = config.age.secrets."nixflix-radarr-password".path;
      };
    };

    recyclarr = {
      enable = true;
      cleanupUnmanagedProfiles = true;
    };

    lidarr = {
      enable = true;
      config = {
        apiKey._secret = config.age.secrets."nixflix-lidarr-apikey".path;
        hostConfig.password._secret = config.age.secrets."nixflix-lidarr-password".path;
      };
    };

    prowlarr = {
      enable = true;
      config = {
        apiKey._secret = config.age.secrets."nixflix-prowlarr-apikey".path;
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

    sabnzbd = {
      enable = true;

      settings = {
        misc = {
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
            retention = 3000;
          }
        ];
      };
    };

    jellyfin = {
      enable = true;
      apiKey._secret = config.age.secrets."nixflix-jellyfin-apikey".path;
      users = {
        admin = {
          mutable = false;
          policy.isAdministrator = true;
          password._secret = config.age.secrets."nixflix-jellyfin-admin-password".path;
        };
      };
    };

    seerr = {
      enable = true;
      apiKey._secret = config.age.secrets."nixflix-seerr-apikey".path;
    };

    # TODO(vpn): parked for now. We're usenet-only (SSL + pull-only, no seeding),
    # so a VPN is a privacy nice-to-have (hides usenet use from the ISP), not a
    # requirement. To enable later:
    #   1. re-add the "nixflix-wireguard-conf" secret to the age.secrets list
    #      above and to ../../secrets/secrets.nix, then `agenix -e
    #      nixflix-wireguard-conf.age` (paste the whole wg-quick .conf).
    #   2. uncomment this block; `enable` only BUILDS the isolated `wg` netns —
    #      nothing routes through it until a service opts in with
    #      `nixflix.<service>.vpn.enable = true` (candidates: sabnzbd, prowlarr).
    #   3. set accessibleFrom to THIS box's real LAN subnet (check with
    #      `ip addr` on the pi) — it's the inbound allowlist for reaching a
    #      confined service's web UI from your network.
    # vpn = {
    #   enable = true;
    #   wgConfFile = config.age.secrets."nixflix-wireguard-conf".path;
    #   accessibleFrom = [ "192.168.1.0/24" ];
    # };
  };

}
