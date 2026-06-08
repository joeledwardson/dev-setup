# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, inputs, commonGroups, ... }:

{
  imports = [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
    (import ../../modules/nixos-secrets.nix { owner = "joelyboy"; })
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

  # mount spare disk
  fileSystems."/mnt/joelyboy/spare" = {
    device = "/dev/disk/by-label/SPARE-DISK";
    fsType = "ext4";
    options = [
      "nofail" # prevent system failure if disk is missing/broken
      "rw"
    ];
  };

  networking.hostName = "desktop-work"; # Define your hostname.
  services.tailscale.enable = true;
  programs.obs-studio = {
    enable = true;

    # optional Nvidia hardware acceleration
    package = (pkgs.obs-studio.override { cudaSupport = true; });
  };

  # add VM support
  environment.systemPackages = with pkgs; [
    vagrant
    inputs.agenix.packages.${pkgs.system}.default # agenix CLI
  ];
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
  # Bluetooth Configuration
  # =======================================
  hardware.bluetooth = {
    enable = true; # enables support for Bluetooth
    powerOnBoot = true; # powers up the default Bluetooth controller on boot
  };

  # bluetooth GUI service
  services.blueman.enable = true;

  # =======================================
  # NVIDIA Configuration
  # =======================================
  hardware.graphics = { enable = true; };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    # Disabled: nvidia-powerd is a documented contributor to hard Wayland freezes
    # on driver 580.x–595.x. See docs/dev-log/2026-05.md — NixOS boot investigation.
    powerManagement.enable = false;
    powerManagement.finegrained = false;
  };

  # Mitigations for NVIDIA 595.x Wayland hard-freeze regression.
  # PreserveVideoMemoryAllocations reduces DMA buffer errors on Wayland.
  boot.kernelParams = [ "nvidia.NVreg_PreserveVideoMemoryAllocations=1" ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.joelyboy = {
    isNormalUser = true;
    description = "joelyboy";
    initialPassword = "password";
    # add libvrtd groups (see https://wiki.nixos.org/wiki/Virt-manager)
    extraGroups = commonGroups ++ [ "libvirtd" ];
    packages = with pkgs; [ drawio ];
  };
  # this stops devenv complaing every time we enter into a shell
  nix.settings.trusted-users = [ "root" "joelyboy" ];
  services.syncthing.user = "joelyboy";
}
