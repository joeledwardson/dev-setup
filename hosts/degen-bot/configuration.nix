{ pkgs, commonGroups, ... }:

{
  imports = [ ./hardware-configuration.nix ];

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
