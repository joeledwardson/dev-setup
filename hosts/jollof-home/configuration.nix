# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ pkgs, inputs, config, commonGroups, ... }:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    (import ../../modules/nixos-secrets.nix { owner = "jollof"; })
    ../../modules/nixos-dictation.nix # local voice dictation (hyprwhspr-rs)
    ../../modules/nixos-netbird.nix # netbird mesh VPN client (wt0) — manual connect/disconnect
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
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  environment.systemPackages = with pkgs; [
    vagrant
    inputs.agenix.packages.${pkgs.system}.default # agenix CLI
    trayscale # Tailscale tray GUI — coloured connected/disconnected icon
  ];

  # =======================================
  # Virtualisation Configuration
  # =======================================
  # add VM support (vagrant) and test out stremio for streaming server
  virtualisation = {
    libvirtd = {
      enable = true;
      qemu.swtpm.enable = true; # TPM support
      onBoot = "ignore"; # Don't auto-start VMs on boot
    };
    spiceUSBRedirection.enable = true;
  };
  programs.virt-manager.enable = true;

  # =======================================
  # Mount Configuration
  # =======================================

  # # mount windows from other partition
  # fileSystems."/mnt/jollof/windows" = {
  #   device = "/dev/disk/by-label/windows";
  #   fsType = "ntfs3";
  #   options = [
  #     "nofail" # prevent system failure if i typed something wrong
  #     "rw"
  #     "uid=1002"
  #     "gid=100"
  #     "dmask=022"
  #     "fmask=133"
  #   ];
  # };

  # =======================================
  # Networking Configuration
  # =======================================
  # Define your hostname.
  networking.hostName = "jollof-home";

  # Tailscale tray: tailscale itself is enabled in nixos-base.nix. Here we let
  # `jollof` drive tailscaled without sudo (operator — same pattern as the
  # claude operator on streaming-server), and autostart trayscale as a user
  # service so its coloured connected/disconnected icon shows in Waybar on
  # login. `--hide-window` starts it minimised to the tray.
  services.tailscale.extraSetFlags = [ "--operator=jollof" ];
  systemd.user.services.trayscale = {
    description = "Trayscale (Tailscale tray UI)";
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "/run/current-system/sw/bin/trayscale --hide-window";
      Restart = "on-failure";
      RestartSec = 3;
    };
  };

  # =======================================
  # NVIDIA Configuration
  # =======================================

  hardware.graphics = { enable = true; };

  # Load NVIDIA driver for Xorg and Wayland
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    # Modesetting is required for most Wayland compositors
    modesetting.enable = true;

    # Use the NVidia open source kernel module (for Turing and newer GPUs)
    # RTX 4070 is Ada Lovelace, so this should work well
    open = false; # Set to true if you want to try the open source module

    # Enable the Nvidia settings menu
    nvidiaSettings = true;

    # Optionally, you may select a specific driver version
    package =
      config.boot.kernelPackages.nvidiaPackages.stable; # or .stable or .beta

    # Enable power management (can cause sleep/suspend issues on some laptops)
    powerManagement.enable = true;
    powerManagement.finegrained = false;
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.jollof = {
    isNormalUser = true;
    description = "jollof";
    initialPassword = "password";
    extraGroups = commonGroups;
    packages = [ pkgs.recyclarr ];
  };
  # this stops devenv complaing every time we enter into a shell
  nix.settings.trusted-users = [ "root" "jollof" ];
  services.syncthing.user = "jollof";

  # =======================================
  # Additional Configuration
  # =======================================
  programs.obs-studio = {
    enable = true;

    # optional Nvidia hardware acceleration
    package = (pkgs.obs-studio.override { cudaSupport = true; });
  };
}
