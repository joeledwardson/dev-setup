# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  config,
  pkgs,
  commonGroups,
  ...
}:
let
  ssh-keys = import ../../secrets/host-keys.nix;
in
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    (import ../../modules/nixos-secrets.nix {
      owner = "jollof";
      enableGcal = true;
    })
  ];

  # boot configuration
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

  # Force real S3 suspend-to-RAM ("deep") instead of the firmware default
  # "s2idle" (modern standby). s2idle keeps the platform in a light sleep that
  # drains ~10%/hr, flattening the battery overnight; deep drops to ~1%/hr.
  # The nvidia powerManagement services below handle dGPU state across S3.
  boot.kernelParams = [ "mem_sleep_default=deep" ];

  # Define your hostname.
  networking.hostName = "degen-work";
  my.ssh.defaultUser = "jollof";

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
  # Accounts Configuration
  # =======================================
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.jollof = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = ssh-keys.trustedHosts;
    description = "jollof";
    initialPassword = "password";
    extraGroups = commonGroups;
    packages = [ ];
  };
  # this stops devenv complaing every time we enter into a shell
  nix.settings.trusted-users = [
    "root"
    "jollof"
  ];

  # =======================================
  # NVIDIA Configuration (hybrid graphics)
  # =======================================
  # MSI Cyborg 15 A13UDX: Intel UHD (iGPU) + NVIDIA RTX 3050 6GB Laptop (dGPU).
  # PRIME render offload: iGPU drives the desktop, dGPU powers down until an app
  # is launched with `nvidia-offload <cmd>`.

  hardware.graphics.enable = true;

  # Load NVIDIA driver for Xorg and Wayland
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    # Modesetting is required for most Wayland compositors (Hyprland)
    modesetting.enable = true;

    # RTX 3050 is Ampere; the open kernel module is recommended for Turing+
    open = true;

    # Enable the nvidia-settings menu
    nvidiaSettings = true;

    package = config.boot.kernelPackages.nvidiaPackages.stable;

    # Fine-grained power management lets the dGPU turn off completely when idle
    # (supported on Turing+ laptops). Saves battery in offload mode.
    powerManagement.enable = true;
    powerManagement.finegrained = true;

    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true; # provides the `nvidia-offload` wrapper
      };
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

}
