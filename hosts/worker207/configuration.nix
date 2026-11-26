# Configures worker207's hardware, networking and desktop services.
{ config, pkgs, lib, inputs, commonGroups, ... }:
let
  ssh-keys = import ../../secrets/host-keys.nix;
  user-keys = import ../../secrets/user-keys.nix;
in
{
  imports = [
    ./hardware-configuration.nix
    ./web.nix
    ./trajectory.nix
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

  # receive joel-desktop-work's kernel log (netconsole) into this journal, timestamped per line
  networking.firewall.allowedUDPPorts = [ 6666 ];
  systemd.services.netconsole-receiver = {
    description = "netconsole kernel log from joel-desktop-work";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.socat}/bin/socat -u UDP-RECV:6666 STDOUT";
      DynamicUser = true;
      Restart = "always";
    };
  };

  # =======================================
  # Users
  # =======================================
  # sandboxes can only ssh to other sandboxes (see tailscale/acl.hujson)
  programs.ssh.knownHosts = ssh-keys.sandboxKnownHosts;

  users.users.claude = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = ssh-keys.allKeys ++ user-keys.allKeys;
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

  services.windmill = {
    enable = true;
    serverPort = 8765;
    baseUrl = "https://worker207.rove-lydian.ts.net:8447";
    # This nixpkgs pin includes the fixes missing from the system package.
    package = inputs.windmill-nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system}.windmill;
  };

  # This host deliberately starts postgresql.target after multi-user.target.
  # Windmill only needs the database and roles provisioned by the setup unit.
  systemd.services.windmill-initdb = {
    requires = lib.mkForce [ "postgresql-setup.service" ];
    after = lib.mkForce [ "postgresql-setup.service" ];
  };

  systemd.services.windmill-server.environment = {
    SERVER_BIND_ADDR = "127.0.0.1";
    BASE_URL = config.services.windmill.baseUrl;
  };

  # kitty terminal support for SSH
  environment.systemPackages = with pkgs; [
    cdrkit # Builds the cloud-init seed ISO used by local Packer images.
    kitty.terminfo
    qemu_kvm # Runs the local Packer image build with KVM acceleration.
    wtype # Wayland text input
    wayvnc # Wayland VNC server for remote check-ins
  ];

  # zed remote dev: zed looks for ~/.zed_server/zed-remote-server-stable-<version> and otherwise downloads
  # a prebuilt one that won't run on NixOS, so link the nixpkgs build. client must be the same nixpkgs zed-editor
  # https://zed.dev/docs/remote-development
  systemd.tmpfiles.rules = [
    "d /home/claude/.zed_server 0755 claude users -"
    "L+ /home/claude/.zed_server/zed-remote-server-stable-${pkgs.zed-editor.version}+stable - - - - ${pkgs.zed-editor.remote_server}/bin/zed-remote-server-stable-${pkgs.zed-editor.version}+stable"
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

  # target box with autologin → keyring can never unlock at login; only the client needs it (remmina)
  services.gnome.gnome-keyring.enable = lib.mkForce false;
  security.pam.services.greetd.enableGnomeKeyring = lib.mkForce false; # else PAM auto_starts the daemon anyway

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
