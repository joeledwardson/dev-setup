{ pkgs, lib, commonGroups, modulesPath, ... }:

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
}
