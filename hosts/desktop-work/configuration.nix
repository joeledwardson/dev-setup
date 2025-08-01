# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports = [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  boot.loader = {
    grub = {
      enable = true;
      devices = [ "nodev" ];
      efiSupport = true;
      useOSProber = true;
      configurationLimit = 5;
      gfxmodeEfi = "1024x768";
    };
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
  };

  # mount windows from other partition
  fileSystems."/mnt/joelyboy/windows" = {
    device = "/dev/disk/by-label/Windows";
    fsType = "ntfs3";
    options = [
      "nofail" # prevent system failure if i typed something wrong
      "rw"
      "uid=1000"
      "gid=100"
      "dmask=022"
      "fmask=133"
    ];

  };

  # mount old linux mint partition (from pre NixOS)
  fileSystems."/mnt/joelyboy/minty" = {
    device = "/dev/disk/by-label/Minty";
    fsType = "ext4";
    options = [
      "users" # allows any user to mount and unmount
      "nofail" # prevent system failure if i typed something wrong
    ];
  };

  networking.hostName = "desktop-work"; # Define your hostname.

  # use CUDA for ollama
  services.ollama.acceleration = "cuda";

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
  users.users.joelyboy = {
    isNormalUser = true;
    description = "joelyboy";
    initialPassword = "password";
    extraGroups = [ "networkmanager" "wheel" "video" ];
    packages = with pkgs;
      [
        #  thunderbird
      ];
  };

}
