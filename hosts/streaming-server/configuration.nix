{ pkgs, config, commonGroups, ... }:

let
  ssh-keys = import ../../secrets/host-keys.nix;
  liteLLMPort = 9177;
  liteLLMHttpsPort = 8443; # SparkyFitness owns :443; Matrix owns :8448.

in {
  imports = [
    ./hardware-configuration.nix

    ./matrix.nix
    ./sparkyfitness.nix
    ./nixflix.nix

    (import ../../modules/nixos-secrets.nix { owner = "claude"; })
  ];

  fileSystems."/mnt/big-hdd" = {
    device = "/dev/disk/by-uuid/115e7867-fda1-4601-94b5-61c1a3b2cfd5";
    fsType = "ext4";
    # Allow boot without the external HDD.
    options = [ "nofail" "x-systemd.device-timeout=10s" ];
  };

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

  # Beszel hub: http://streaming-server:8090; state in /var/lib/beszel-hub.
  services.beszel.hub = {
    enable = true;
    host = "0.0.0.0";
    port = 8090;
  };

  # QEMU support for building pi-box images on this x86 host.
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  networking.hostName = "streaming-server";
  my.ssh.defaultUser = "claude";

  users.users = {
    claude = {
      isNormalUser = true;
      openssh.authorizedKeys.keys = ssh-keys.allHosts;
      description = "claude-code";
      initialPassword = "password";
      extraGroups = commonGroups;
    };
  };
  # Allow these users to configure Nix builds through devenv.
  nix.settings.trusted-users = [ "root" "claude" ];

  # Advertised tags are configured through tailscale up, not tailscale set.
  services.tailscale.extraUpFlags = [ "--advertise-tags=tag:sandbox" ];
  services.tailscale.permitCertUid = "claude";
  services.tailscale.extraSetFlags = [ "--operator=claude" ];

  # Install terminal definitions for Kitty SSH sessions.
  environment.systemPackages = [ pkgs.kitty.terminfo ];

  services.ollama = {
    enable = true;

    loadModels = [ "qwen2.5vl:3b" ];
  };

  services.litellm = {
    enable = true;
    host = "127.0.0.1"; # Remote access uses Tailscale Serve.
    port = liteLLMPort;
    environmentFile = config.age.secrets."litellm-env".path;
    # LiteLLM resolves this key from its environment file.
    settings.general_settings.master_key = "os.environ/LITELLM_MASTER_KEY";
    # Edit this file and restart LiteLLM to add models without rebuilding NixOS.
    settings.include = [ "/var/lib/litellm/models.yaml" ];
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
        model_name = "qwen-vl";
        litellm_params = {
          model = "ollama/qwen2.5vl:3b";
          api_base = "http://127.0.0.1:11434";
        };
      }
      {
        model_name = "qwen3-coder";
        litellm_params = {
          model = "openrouter/qwen/qwen3-coder-30b-a3b-instruct";
          api_key = "os.environ/OPENROUTER_API_KEY";
        };
      }
      {
        model_name = "qwen3-vl";
        litellm_params = {
          model = "openrouter/qwen/qwen3-vl-32b-instruct";
          api_key = "os.environ/OPENROUTER_API_KEY";
        };
      }
    ];
  };

  # Create the required include file as the service’s DynamicUser.
  systemd.services.litellm.serviceConfig.ExecStartPre = [
    (pkgs.writeShellScript "litellm-seed-models-yaml" ''
      if [ ! -e /var/lib/litellm/models.yaml ]; then
        echo "model_list: []" > /var/lib/litellm/models.yaml
      fi
    '')
  ];

  # Remote clients use HTTPS port 8443; the local API stays on 9177.
  systemd.services.litellm-tailscale-serve = {
    description = "tailscale serve :${toString liteLLMHttpsPort} -> litellm proxy";
    after = [ "tailscaled.service" "litellm.service" ];
    wants = [ "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.tailscale}/bin/tailscale serve --https=${toString liteLLMHttpsPort} http://localhost:${
          toString liteLLMPort
        }";
      Restart = "on-failure";
      RestartSec = 10;
    };
  };

}
