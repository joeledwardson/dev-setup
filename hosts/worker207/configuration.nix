{ pkgs, commonGroups, ... }:

{
  imports = [
    ./hardware-configuration.nix
    (import ../../modules/nixos-secrets.nix { owner = "claude"; })
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
  # Graphics — AMD Radeon RX 6600 (open-source amdgpu + Mesa)
  # =======================================
  # Mesa is already pulled in implicitly by programs.hyprland (nixos-core-desktop);
  # this makes it explicit, and loads amdgpu in the initrd so the display is
  # driven by the real driver from early boot (useful when watching via PiKVM)
  hardware.graphics.enable = true;
  hardware.amdgpu.initrd.enable = true;

  # =======================================
  # Networking Configuration
  # =======================================
  networking.hostName = "worker207";

  # wayvnc remote desktop
  networking.firewall.allowedTCPPorts = [ 5900 ];

  # =======================================
  # Users
  # =======================================
  users.users.claude = {
    isNormalUser = true;
    description = "claude-code";
    initialPassword = "password";
    extraGroups = commonGroups;
  };
  # this stops devenv complaing every time we enter into a shell
  nix.settings.trusted-users = [ "root" "claude" ];

  services.tailscale.extraUpFlags = [ "--advertise-tags=tag:sandbox" ];
  services.tailscale.permitCertUid = "claude";
  # Delegate `tailscale serve` to the claude user so it runs without sudo
  services.tailscale.extraSetFlags = [ "--operator=claude" ];

  # kitty terminal support for SSH
  environment.systemPackages = with pkgs; [
    kitty.terminfo
    wtype # Wayland text input
    wayvnc # Wayland VNC server for remote check-ins
  ];

  # auto-start wayvnc when Hyprland is running
  systemd.user.services.wayvnc = {
    description = "wayvnc VNC server";
    after = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.wayvnc}/bin/wayvnc 0.0.0.0";
      Restart = "on-failure";
      RestartSec = 3;
    };
  };

  # auto-login claude and launch Hyprland via UWSM (activates graphical-session.target)
  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        command = "uwsm start hyprland-uwsm.desktop";
        user = "claude";
      };
      default_session = {
        command = "uwsm start hyprland-uwsm.desktop";
        user = "claude";
      };
    };
  };

}
