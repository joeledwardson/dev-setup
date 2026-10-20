# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  config,
  pkgs,
  pkgs-unstable,
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

  services.tailscale.extraUpFlags = [ "--advertise-tags=tag:trusted" ];

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
  my.ssh.defaultUser = "jollof";

  # mount windows from other partition
  fileSystems."/mnt/joelyboy/windows" = {
    device = "/dev/disk/by-label/OS";
    fsType = "ntfs3";
    options = [
      "users" # allows any user to mount and unmount
      "nofail" # prevent system failure if i typed something wrong
      "x-systemd.automount" # add this
      "x-systemd.idle-timeout=60" # optional: unmount after 60s idle
      "rw"
      "uid=1000"
      "gid=100"
      "dmask=022"
      "fmask=133"
    ];

  };

  # =======================================
  # Media server
  # =======================================
  services.sabnzbd = {
    enable = true;
  };
  services.nzbget = {
    enable = true;
  };
  services.sonarr = {
    enable = true;
  };
  services.radarr = {
    enable = true;
  };
  services.prowlarr = {
    enable = true;
  };

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
  environment.systemPackages = with pkgs; [
    libmtp
    jmtpfs
    go-mtpfs

    # rust things
    rustc
    rustc.doc  # has rust-docs
    cargo
    clippy # rust linter
    rustfmt # for neovim formatting
    rust-analyzer # for neovim LSP
    rustlings # rust beginner guide

    # rust wasm stuf... probably needs a trim
    trunk # wasm builder for trunk
    wasm-bindgen-cli # post wasm generator in rust....?
    cargo-leptos
    lld # wasm32 builds link via lld; rustc does not bundle a usable one
  ];

  # The doc output lands in the system path but nothing points a browser at it.
  environment.shellAliases.rust-docs =
    "xdg-open ${pkgs.rustc.doc}/share/doc/docs/html/index.html";

  # =======================================
  # Accounts Configuration
  # =======================================
  # trusted machines can ssh anywhere, so know every host's key
  programs.ssh.knownHosts = ssh-keys.allKnownHosts;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.jollof = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = ssh-keys.trustedKeys;
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
  # Ollama (local LLMs)
  # =======================================
  # The Radeon 880M (gfx1150) has no ROCm support, and the plain `ollama`
  # package resolves to `ollama-cpu` - which is why the logs showed
  # total_vram="0 B" and every model ran on the CPU. The vulkan variant drives
  # the iGPU through RADV and sets OLLAMA_VULKAN=1 via its wrapper.
  # It comes from unstable because 26.05 pins 0.24.0, which the registry
  # rejects current models against with "412: requires a newer version".
  services.ollama = {
    enable = true;
    package = pkgs-unstable.ollama-vulkan;
    # These are the models actually on disk. loadModels pulls on EVERY
    # activation and the loader runs them in PARALLEL via GNU parallel, so a
    # big model listed here means a multi-GB download starting unprompted on
    # whatever connection is to hand - mobile tether included. Only list what
    # is already pulled, and add new ones deliberately while on wifi.
    # gpt-oss:20b is 13GB and fits inside the 15.7GB the iGPU exposes, so it
    # runs entirely on the GPU. It is MoE with ~3.6B active params: on an iGPU
    # sharing system RAM, speed tracks active params, not the total.
    loadModels = [
      "qwen3:4b"
      "gpt-oss:20b"
    ];
    environmentVariables = {
      # 0.40.3 skips integrated GPUs unless this is set, so the Radeon 880M was
      # detected at startup but never used - models silently loaded onto the CPU
      # at ~11 tok/s. 0.24.0 had no such flag and offloaded without it.
      OLLAMA_IGPU_ENABLE = "1";
    };
  };

  # =======================================
  # Graphics
  # =======================================
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
}
