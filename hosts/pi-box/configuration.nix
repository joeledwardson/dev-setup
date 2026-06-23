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

    # SparkyFitness production stack (Podman / oci-containers + Tailscale Serve)
    ./sparkyfitness.nix
  ];

  # Root lives on a USB-attached SSD in a UASP caddy, so the initrd needs the
  # USB-storage drivers to find the root filesystem at boot.
  boot.initrd.availableKernelModules = [ "xhci_pci" "usbhid" "usb_storage" "uas" ];

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
  services.syncthing.user = "jollof";

  systemd.tmpfiles.rules = [ "d /var/lib/syncthing 0770 jollof users -" ];
}
