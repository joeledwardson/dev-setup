# Configures worker207's hardware, networking and desktop services.
{ pkgs, lib, commonGroups, ... }:
let
  ssh-keys = import ../../secrets/host-keys.nix;
in
{
  imports = [
    ./hardware-configuration.nix
    (import ../../modules/nixos-secrets.nix { owner = "claude"; })
  ];

  # Beszel agent connects to streaming-server over Tailscale, with SMART monitoring.
  services.beszel.agent.smartmon.enable = true;

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
  my.ssh.defaultUser = "claude";

  # Keep the Intel Wi-Fi adapter continuously active for interactive SSH.
  boot.extraModprobeConfig = ''
    options iwlmvm power_scheme=1
  '';

  # wayvnc remote desktop
  networking.firewall.allowedTCPPorts = [ 5900 ];

  # =======================================
  # Users
  # =======================================
  # sandboxes can only ssh to other sandboxes (see tailscale/acl.hujson)
  programs.ssh.knownHosts = ssh-keys.sandboxKnownHosts;

  users.users.claude = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = ssh-keys.allKeys;
    description = "claude-code";
    initialPassword = "password";
    extraGroups = commonGroups;
  };
  # this stops devenv complaing every time we enter into a shell
  nix.settings.trusted-users = [
    "root"
    "claude"
  ];

  services.tailscale.extraUpFlags = [ "--advertise-tags=tag:sandbox" ];
  services.tailscale.permitCertUid = "claude";
  # Delegate `tailscale serve` to the claude user so it runs without sudo
  services.tailscale.extraSetFlags = [ "--operator=claude" ];

  # kitty terminal support for SSH
  environment.systemPackages = with pkgs; [
    cdrkit # Builds the cloud-init seed ISO used by local Packer images.
    kitty.terminfo
    qemu_kvm # Runs the local Packer image build with KVM acceleration.
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
      # mkForce: override nixos-extended-desktop's tuigreet prompt, this box has no one at the keyboard
      default_session = lib.mkForce {
        command = "uwsm start hyprland-uwsm.desktop";
        user = "claude";
      };
    };
  };

}
