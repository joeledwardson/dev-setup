# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports = [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ../../modules/nixos-base.nix
  ];

  # boot configuration
  boot.loader = {
    grub = {
      enable = true;
      devices = [ "nodev" ];
      efiSupport = true;
      useOSProber = true;
      configurationLimit = 5;
    };
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
  };

  # Define your hostname.
  networking.hostName = "degen-work";

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
    extraGroups = [ "networkmanager" "wheel" "video" ];
    packages = with pkgs;
      [
        #  thunderbird
      ];
  };
}
