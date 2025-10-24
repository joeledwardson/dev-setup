# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, commonGroups, ... }:

{
  imports = [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # boot configuration
  boot.loader = {
    grub = {
      enable = true;
      devices = [ "nodev" ];
      gfxmodeEfi = "1024x768";
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
  networking.hostName = "degen-home";

  # for windows support
  boot.supportedFilesystems = [ "ntfs" ];

  # =======================================
  # Bluetooth Configuration
  # =======================================
  hardware.bluetooth = {
    enable = true; # enables support for Bluetooth
    powerOnBoot = true; # powers up the default Bluetooth controller on boot
  };

  # bluetooth GUI service
  services.blueman.enable = true;

  # =======================================
  # MTP Support for Android/Camera devices
  # =======================================
  services.gvfs.enable = true;
  services.udisks2.enable = true;

  # MTP filesystem tools for mounting devices
  environment.systemPackages = with pkgs; [ libmtp jmtpfs go-mtpfs ];

  # =======================================
  # Accounts Configuration
  # =======================================
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

  # =======================================
  # Graphics
  # =======================================
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
}
