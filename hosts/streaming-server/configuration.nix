# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ pkgs, pkgs-unstable, config, commonGroups, inputs, ... }:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix

    # add the nixarr module (consumed directly from flake inputs)
    inputs.nixarr.nixosModules.default

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
      useOSProber = true;
      configurationLimit = 10;
      gfxmodeEfi = "1024x768";
    };
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
  };

  # =======================================
  # Media server 
  # =======================================

  nixarr = {
    enable = true;
    mediaDir = "/data/media";
    stateDir = "/data/media/.state/nixarr";

    sabnzbd.enable = true;
    prowlarr.enable = true;
    sonarr.enable = true;
    radarr.enable = true;
    plex.enable = true;

    # Optional: VPN for downloads
    # vpn.enable = true;
    # sabnzbd.vpn.enable = true;
  };

  # =======================================
  # Cross-build for the Pi (aarch64)
  # =======================================
  # streaming-server is x86_64; building the pi-box aarch64 image needs QEMU
  # user-mode emulation so the aarch64 build/image-assembly steps can run here.
  # Adds qemu + binfmt only — does not rebuild this host's apps.
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  # =======================================
  # Networking Configuration
  # =======================================
  # Define your hostname.
  networking.hostName = "streaming-server";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users = {
    claude = {
      isNormalUser = true;
      description = "claude-code";
      initialPassword = "password";
      extraGroups = commonGroups;
    };
    streamer = {
      isNormalUser = true;
      description = "jollof";
      initialPassword = "password";
      extraGroups = commonGroups;
    };
  };
  # this stops devenv complaing every time we enter into a shell
  nix.settings.trusted-users = [ "root" "streamer" "claude" ];

  services.tailscale.extraUpFlags = [ "--advertise-tags=tag:sandbox" ];

  # wayvnc remote desktop
  networking.firewall.allowedTCPPorts = [ 5900 ];

  # kitty terminal support for SSH
  environment.systemPackages = with pkgs; [
    kitty.terminfo
    ydotool # Wayland mouse/keyboard simulation
    wtype # Wayland text input
    wayvnc # Wayland VNC server for remote check-ins
  ];

  # ydotool daemon (required for ydotool to work)
  programs.ydotool.enable = true;

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
  services.syncthing = {
    user = "claude";
    group = "users";
    dataDir = "/home/claude/syncthing";
    configDir = "/home/claude/.config/syncthing";
  };

}
