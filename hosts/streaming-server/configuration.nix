# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ pkgs, pkgs-unstable, config, commonGroups, inputs, ... }:

let liteLLMPort = 9177; # generated port (just one i made up)

in {
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

  services.ollama = {
    enable = true;

    # Declaratively pull models when the service starts
    loadModels = [ "qwen2.5vl:3b" ];
  };

  # =======================================
  # LiteLLM proxy
  # =======================================
  services.litellm = {
    enable = true;
    host = "127.0.0.1"; # localhost only; must use tailscale to access outside
    port = liteLLMPort;
    environmentFile = config.age.secrets."litellm-env".path;
    # API key for clients to use (see secrets.nix)
    # `os.environ` syntax is litellm specific (see https://docs.litellm.ai/docs/proxy/config_settings#general_settings---reference)
    settings.general_settings.master_key = "os.environ/LITELLM_MASTER_KEY";
    settings.model_list = [
      {
        model_name = "gemini-flash";
        litellm_params = {
          model =
            "gemini/gemini-2.5-flash"; # Google AI Studio (API-key) provider
          api_key = "os.environ/GEMINI_API_KEY";
        };
      }
      {
        # server local model hosted by ollama (see above)
        model_name = "qwen-vl";
        litellm_params = {
          model = "ollama/qwen2.5vl:3b";
          api_base = "http://127.0.0.1:11434";
        };
      }
      {
        # hosted Qwen3-Coder-30B-A3B (MoE) via OpenRouter, so we can trial a
        # bigger agentic-coder model before buying the GPU to run it locally.
        # OpenRouter is the live host; DeepInfra deprecated this exact model.
        model_name = "qwen3-coder";
        litellm_params = {
          model = "openrouter/qwen/qwen3-coder-30b-a3b-instruct";
          api_key = "os.environ/OPENROUTER_API_KEY";
        };
      }
      {
        # hosted Qwen3-VL-32B (vision) via OpenRouter — the tier-2 vision
        # candidate from ADR-0005. Same 32B weights a used RTX 3090 (24GB)
        # would run locally, so we can judge image->text quality here before
        # spending on the GPU. Local `qwen-vl` above is the tier-1 3060 model.
        model_name = "qwen3-vl";
        litellm_params = {
          model = "openrouter/qwen/qwen3-vl-32b-instruct";
          api_key = "os.environ/OPENROUTER_API_KEY";
        };
      }
    ];
  };

  # tailscale server tailnet HTTPS -> port litellm proxy
  systemd.services.litellm-tailscale-serve = {
    description = "tailscale serve -> litellm proxy ${toString liteLLMPort}";
    after = [ "tailscaled.service" "litellm.service" ];
    wants = [ "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.tailscale}/bin/tailscale serve http://localhost:${
          toString liteLLMPort
        }";
      Restart = "on-failure";
      RestartSec = 10;
    };
  };

}
