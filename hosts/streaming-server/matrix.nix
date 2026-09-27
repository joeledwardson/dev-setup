{ pkgs, config, ... }:

let
  serverName = "jollof.chat";
  fqdn = (import ../../modules/tailnet.nix).fqdnFor config.networking.hostName;
  # SparkyFitness uses HTTPS port 443.
  matrixPort = 8448;
in {
  # The bridges still depend on libolm.
  nixpkgs.config.permittedInsecurePackages = [ "olm-3.2.16" ];

  services.matrix-synapse = {
    enable = true;
    settings = {
      server_name = serverName;
      public_baseurl = "https://${fqdn}:${toString matrixPort}/";
      registration_shared_secret_path =
        config.age.secrets.matrix-registration.path;
      # Double puppeting syncs read receipts as @jollof; see ADR-011.
      app_service_config_files =
        [
          config.age.secrets.matrix-doublepuppet.path
          config.age.secrets.mautrix-imessage-registration.path
        ];
      database.name = "sqlite3";
      # Tailscale Serve terminates HTTPS and proxies to this listener.
      listeners = [{
        port = 8008;
        bind_addresses = [ "127.0.0.1" ];
        type = "http";
        tls = false;
        x_forwarded = true;
        resources = [{
          names = [ "client" ];
          compress = false;
        }];
      }];
    };
  };

  services.mautrix-telegram = {
    enable = true;
    # Telegram credentials and double-puppet login settings come from this env file.
    environmentFile = config.age.secrets.mautrix-telegram-env.path;
    settings = {
      homeserver = {
        address = "http://localhost:8008";
        domain = serverName;
      };
      telegram = {
        api_id = 0;
        api_hash = "";
      }; # real values via environmentFile
      bridge.permissions = { "@jollof:${serverName}" = "admin"; };
    };
  };

  services.mautrix-whatsapp = {
    enable = true;
    environmentFile =
      config.age.secrets.matrix-doublepuppet-env.path;
    settings = {
      homeserver = {
        address = "http://localhost:8008";
        domain = serverName;
      };
      bridge.permissions = { "@jollof:${serverName}" = "admin"; };
      double_puppet.secrets.${serverName} = "as_token:$DOUBLEPUPPET_AS_TOKEN";
    };
  };

  services.mautrix-signal = {
    enable = true;
    environmentFile = config.age.secrets.matrix-doublepuppet-env.path;
    settings = {
      homeserver = {
        address = "http://localhost:8008";
        domain = serverName;
      };
      bridge.permissions = { "@jollof:${serverName}" = "admin"; };
      double_puppet.secrets.${serverName} = "as_token:$DOUBLEPUPPET_AS_TOKEN";
    };
  };

  # TODO: Remove this override when nixpkgs includes the Facebook fix in 26.08.1.
  services.mautrix-meta.package = pkgs.mautrix-meta.overrideAttrs (old: {
    version = "26.08.1";
    src = pkgs.fetchFromGitHub {
      owner = "mautrix";
      repo = "meta";
      tag = "v0.2608.1";
      hash = "sha256-xTfbLtQ1lo6ukWlGjNwjxYaLMod6hljhQEcwdSgoBcQ=";
    };
    vendorHash = "sha256-CCGF13D0QO2GAE+kN/7xl924rSloqikDoGPr00clofI=";
    # Override the embedded version tag along with the source.
    ldflags = [ "-s" "-w" "-X" "main.Tag=v0.2608.1" ];
  });

  services.mautrix-meta.instances.facebook = {
    enable = true;
    environmentFile = config.age.secrets.matrix-doublepuppet-env.path;
    settings = {
      homeserver = {
        address = "http://localhost:8008";
        domain = serverName;
      };
      bridge.permissions = { "@jollof:${serverName}" = "admin"; };
      # Allow plain commands to the Facebook bridge.
      encryption = {
        allow = false;
        default = false;
        require = false;
      };
      double_puppet.secrets.${serverName} = "as_token:$DOUBLEPUPPET_AS_TOKEN";
      # Catch up on messages received during downtime.
      backfill = {
        enabled = true;
        max_initial_messages = 50;
        max_catchup_messages = 500;
        unread_hours_threshold = 720;
        threads.max_initial_messages = 50;
      };
    };
  };

  systemd.services.matrix-tailscale-serve = {
    description = "tailscale serve -> synapse :8448";
    after = [ "tailscaled.service" "matrix-synapse.service" ];
    wants = [ "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.tailscale}/bin/tailscale serve --https=${
          toString matrixPort
        } http://localhost:8008";
      Restart = "on-failure";
      RestartSec = 10;
    };
  };

  age.secrets.matrix-registration = {
    file = ../../secrets/matrix-registration.age;
    owner = "matrix-synapse";
  };
  age.secrets.mautrix-telegram-env = {
    file = ../../secrets/mautrix-telegram-env.age;
    owner = "mautrix-telegram";
  };
  age.secrets.matrix-doublepuppet = {
    file =
      ../../secrets/matrix-doublepuppet.age;
    owner = "matrix-synapse";
  };
  # Systemd reads this env file as root; bridge users do not need access.
  age.secrets.matrix-doublepuppet-env.file =
    ../../secrets/matrix-doublepuppet-env.age;
  age.secrets.mautrix-imessage-registration = {
    file = ../../secrets/mautrix-imessage-registration.age;
    owner = "matrix-synapse";
  };

  # Restart Synapse when appservice registrations change.
  systemd.services.matrix-synapse.restartTriggers =
    [
      ../../secrets/matrix-doublepuppet.age
      ../../secrets/mautrix-imessage-registration.age
    ];
}
