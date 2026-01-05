# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, commonGroups, ... }:

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
      "users" # allows any user to mount and unmount
      "nofail" # prevent system failure if i typed something wrong
      "rw"
      "uid=1000"
      "gid=100"
      "dmask=022"
      "fmask=133"
    ];

  };

  networking.hostName = "desktop-work"; # Define your hostname.

  # add timescale to postgres extensions
  # services.postgresql.settings = { shared_preload_libraries = "timescaledb"; };
  # services.postgresql.extensions = ps: [
  #   ps.plpgsql_check
  #   ps.timescaledb
  #   ps.timescaledb_toolkit
  # ];

  # add VM support
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
    # add libvrtd groups (see https://wiki.nixos.org/wiki/Virt-manager)
    extraGroups = commonGroups ++ [ "libvirtd" ];
    packages = [ ];
  };
  # this stops devenv complaing every time we enter into a shell
  nix.settings.trusted-users = [ "root" "joelyboy" ];
  services.syncthing.user = "joelyboy";
}
