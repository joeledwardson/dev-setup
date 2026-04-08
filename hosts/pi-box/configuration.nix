{ pkgs, commonGroups, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

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
}
