# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, commonGroups, ... }:

{
  imports = [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
    (import ../../modules/nixos-secrets.nix { owner = "joelyboy"; })
  ];

  # pstore: on kernel panic, writes ring buffer to EFI memory before dying.
  # Survives reboot — read at /sys/fs/pstore/ afterwards.
  # Only fires on actual panics, not silent hard hangs (use netconsole for those).
  boot.kernelParams = [
    "pstore.backend=efi"

    # DIAGNOSTIC: Ryzen 5800X can hang silently at maximum idle depth (CC6 C-state) —
    # symptoms are exactly the overnight freezes: no SSH, no SysRq, journal stops cold.
    # This limits the CPU to C-state 1 (light sleep only) to test that theory.
    # Costs some idle power. Remove once confirmed not the cause, or fix properly in
    # BIOS: Global C-State Control → disabled, Power Supply Idle Control → Typical Current Idle.
    "processor.max_cstate=1"
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

  programs.obs-studio = {
    enable = true;

    # optional Nvidia hardware acceleration
    package = (pkgs.obs-studio.override { cudaSupport = true; });
  };

  # add VM support
  environment.systemPackages = with pkgs; [ vagrant ];
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
  # Ollama (local LLMs)
  # =======================================
  # force the CUDA module up at boot, not lazily on first use
  boot.kernelModules = [ "nvidia_uvm" ];

  # don't start Ollama until the NVIDIA driver is initialised
  # previously I got total_vram="0 B" in the logs on startup? indicating it couldn't see the VRAM?
  systemd.services.ollama = {
    after = [ "nvidia-persistenced.service" ];
    wants = [ "nvidia-persistenced.service" ];
  };

  services.ollama = {
    enable = true;
    loadModels = [ "gpt-oss:20b" ];
    host = "0.0.0.0";
    package = pkgs.ollama-cuda;
    environmentVariables = {
      OLLAMA_FLASH_ATTENTION =
        "1"; # my card (RTX 3060) is modern enough for this
      OLLAMA_KV_CACHE_TYPE = "q8_0"; # free up some VRAM
    };

  };
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 11434 ];

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

    # Keeps the driver resident in memory so the GPU doesn't drop to P8 between
    # frames — prevents the P8→active transition stutter on Wayland compositing.
    nvidiaPersistenced = true;

    # Disabled: nvidia-powerd is a documented contributor to hard Wayland freezes
    # on driver 580.x–595.x. See mdx-docs/docs/dev-log/2026-05.md — NixOS boot investigation.
    powerManagement.enable = false;
    powerManagement.finegrained = false;
  };

  # NOTE: NVreg_PreserveVideoMemoryAllocations=1 was removed.
  # It requires powerManagement.enable=true to provide the procfs suspend interface.
  # With powerManagement.enable=false, it causes suspend to fail (error -5), leaving
  # the NVIDIA driver in a corrupted state that causes full system hangs hours later.

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
}
