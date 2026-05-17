{ pkgs, commonGroups, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # =======================================
  # Disk Layout (disko)
  # =======================================
  disko.devices.disk.main = {
    device = "/dev/nvme0n1";
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "512M";
          type = "EF00";
          content = { type = "filesystem"; format = "vfat"; mountpoint = "/boot"; };
        };
        root = {
          size = "100%";
          content = { type = "filesystem"; format = "ext4"; mountpoint = "/"; };
        };
      };
    };
  };

  # =======================================
  # Boot Configuration
  # =======================================
  boot.loader = {
    grub = {
      enable = true;
      devices = [ "nodev" ];
      efiSupport = true;
      configurationLimit = 10;
    };
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
  };

  # =======================================
  # Networking Configuration
  # =======================================
  networking.hostName = "degen-bot";

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
