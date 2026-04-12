# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

args@{ pkgs, pkgs-unstable, config, commonGroups, ... }:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix

    # add the nixarr module
    args.nixarr_flake.nixosModules.default
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

  # kitty terminal support for SSH
  environment.systemPackages = with pkgs; [
    kitty.terminfo
    ydotool # Wayland mouse/keyboard simulation
    wtype # Wayland text input
    wayvnc # Wayland VNC server for remote check-ins
  ];

  # ydotool daemon (required for ydotool to work)
  programs.ydotool.enable = true;

  # auto-login streamer and launch Hyprland on boot (headless box)
  services.greetd = {
    enable = true;
    settings.initial_session = {
      command = "Hyprland";
      user = "streamer";
    };
  };
  services.syncthing = {
    user = "streamer";
    group = "users";
    dataDir = "/home/streamer/syncthing";
    configDir = "/home/streamer/.config/syncthing";
  };

}
