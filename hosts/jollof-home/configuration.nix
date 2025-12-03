# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, commonGroups, ... }:

{
  imports = [ # Include the results of the hardware scan.
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
  # Keyboard Building Configuration
  # =======================================
  hardware.keyboard.qmk.enable = true;
  environment.systemPackages = with pkgs; [ via qmk ];
  services.udev.packages = [ pkgs.via ];

  # =======================================
  # Mount Configuration
  # =======================================
  # for windows support
  boot.supportedFilesystems = [ "ntfs" ];

  # # mount windows from other partition
  # fileSystems."/mnt/jollof/windows" = {
  #   device = "/dev/disk/by-label/windows";
  #   fsType = "ntfs3";
  #   options = [
  #     "nofail" # prevent system failure if i typed something wrong
  #     "rw"
  #     "uid=1000"
  #     "gid=100"
  #     "dmask=022"
  #     "fmask=133"
  #   ];
  #
  # };

  # mount old ubuntu partition
  fileSystems."/mnt/jollof/minty" = {
    device = "/dev/disk/by-label/ubuntu";
    fsType = "ext4";
    options = [
      "users" # allows any user to mount and unmount
      "nofail" # prevent system failure if i typed something wrong
    ];
  };

  # =======================================
  # Networking Configuration
  # =======================================
  # Define your hostname.
  networking.hostName = "jollof-home";

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
    packages = [ ];
  };
  # this stops devenv complaing every time we enter into a shell
  nix.settings.trusted-users = [ "root" "jollof" ];
  services.syncthing.user = "jollof";

}
