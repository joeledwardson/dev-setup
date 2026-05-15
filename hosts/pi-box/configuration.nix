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

  # auto-login claude and launch Hyprland on boot (same as streaming-server)
  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        command = "Hyprland";
        user = "claude";
      };
      default_session = {
        command = "Hyprland";
        user = "claude";
      };
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

  systemd.tmpfiles.rules = [ "d /var/lib/syncthing 0770 jollof users -" ];
}
