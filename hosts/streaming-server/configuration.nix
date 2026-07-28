# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ pkgs, pkgs-unstable, config, commonGroups, inputs, ... }:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix

    # add the nixarr module (consumed directly from flake inputs)
    inputs.nixarr.nixosModules.default

    (import ../../modules/nixos-secrets.nix { owner = "claude"; })
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
  # Media server 
  # =======================================

  nixarr = {
    enable = true;
    mediaDir = "/data/media";
    stateDir = "/data/media/.state/nixarr";

    sabnzbd.enable = true;
    prowlarr.enable = true;
    sonarr.enable = true;
    radarr.enable = true;
    plex.enable = true;

    # Optional: VPN for downloads
    # vpn.enable = true;
    # sabnzbd.vpn.enable = true;
  };

  # =======================================
  # Cross-build for the Pi (aarch64)
  # =======================================
  # streaming-server is x86_64; building the pi-box aarch64 image needs QEMU
  # user-mode emulation so the aarch64 build/image-assembly steps can run here.
  # Adds qemu + binfmt only — does not rebuild this host's apps.
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  # =======================================
  # Networking Configuration
  # =======================================
  # Define your hostname.
  networking.hostName = "streaming-server";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users = {
    claude = {
      isNormalUser = true;
      description = "claude-code";
      initialPassword = "password";
      extraGroups = commonGroups;
    };
    streamer = {
      isNormalUser = true;
      description = "jollof";
      initialPassword = "password";
      extraGroups = commonGroups;
    };
  };
  # this stops devenv complaing every time we enter into a shell
  nix.settings.trusted-users = [ "root" "streamer" "claude" ];

  services.tailscale.extraUpFlags = [ "--advertise-tags=tag:sandbox" ];
  services.tailscale.permitCertUid = "claude";
  # Delegate `tailscale serve` to the claude user so it runs without sudo
  # (pairs with permitCertUid above for sudo-free HTTPS serve).
  services.tailscale.extraSetFlags = [ "--operator=claude" ];

  # wayvnc remote desktop
  networking.firewall.allowedTCPPorts = [ 5900 ];

  # kitty terminal support for SSH
  environment.systemPackages = with pkgs; [
    kitty.terminfo
    wtype # Wayland text input
    wayvnc # Wayland VNC server for remote check-ins
  ];

  # auto-start wayvnc when Hyprland is running
  systemd.user.services.wayvnc = {
    description = "wayvnc VNC server";
    after = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.wayvnc}/bin/wayvnc 0.0.0.0";
      Restart = "on-failure";
      RestartSec = 3;
    };
  };

  # auto-login claude and launch Hyprland via UWSM (activates graphical-session.target)
  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        command = "uwsm start hyprland-uwsm.desktop";
        user = "claude";
      };
      default_session = {
        command = "uwsm start hyprland-uwsm.desktop";
        user = "claude";
      };
    };
  };
  services.syncthing = {
    user = "claude";
    group = "users";
    dataDir = "/home/claude/syncthing";
    configDir = "/home/claude/.config/syncthing";
  };

  services.ollama = {
    enable = true;

    # Declaratively pull models when the service starts
    loadModels = [ "qwen2.5vl:3b" ];
  };

  # =======================================
  # LiteLLM proxy
  # =======================================
  # One OpenAI-compatible endpoint (http://127.0.0.1:9177/v1) sitting in front of
  # a few model providers. Clients pick which one by the model_name below.
  #
  # The keys don't live in this config - the Nix store is world-readable, so
  # they'd leak. Instead we point at os.environ/NAME here and let systemd feed
  # them in from the litellm-env secret. secrets/secrets.nix says what's in it.
  services.litellm = {
    enable = true;
    host = "127.0.0.1"; # localhost only; use `tailscale serve` to expose on the tailnet
    port = 9177; # deterministic: 9000 + crc32("litellm") % 900
    environmentFile = config.age.secrets."litellm-env".path;
    # Clients have to send this as `Authorization: Bearer <key>`, or the proxy
    # turns them away. Leave it out and anyone who can reach the port can spend
    # our Gemini quota - the only reason that's fine today is we bind to
    # localhost. A single static key like this needs no database.
    settings.general_settings.master_key = "os.environ/LITELLM_MASTER_KEY";
    settings.model_list = [
      {
        model_name = "gemini-flash";
        litellm_params = {
          model = "gemini/gemini-2.5-flash"; # Google AI Studio (API-key) provider
          api_key = "os.environ/GEMINI_API_KEY";
        };
      }
      {
        # local model already pulled by services.ollama above (default port 11434)
        model_name = "qwen-vl";
        litellm_params = {
          model = "ollama/qwen2.5vl:3b";
          api_base = "http://127.0.0.1:11434";
        };
      }
    ];
  };

}
