{ pkgs, lib, commonGroups, ... }:

{
  imports = [ ./hardware-configuration.nix ];

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
  # Boot Configuration
  # =======================================
  boot.loader = {
    grub.enable = false;
    generic-extlinux-compatible.enable = true;
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
  services.syncthing.user = "jollof";

  systemd.tmpfiles.rules = [ "d /var/lib/syncthing 0770 jollof users -" ];
}
