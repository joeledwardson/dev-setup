# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports = [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  boot = {
    loader = {
      efi = { canTouchEfiVariables = true; };
      systemd-boot = {
        enable = true;
        configurationLimit = 5;
        extraEntries = {
          "windows.conf" = ''
            title Windows Boot Manager
            efi /EFI/Microsoft-Copy/Boot/bootmgfw.efi
          '';
        };
      };
    };
  };

  networking.hostName = "jollof-home"; # Define your hostname.
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.jollof = {
    isNormalUser = true;
    description = "jollof";
    initialPassword = "password";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs;
      [
        #  thunderbird
      ];
  };

}
