# Self-hosted Matrix homeserver + bridges — pi-box PROD cut.
# Same as the desktop-work test cut, just reachable off-box via tailscale (HTTPS).
# Still SQLite: it's just me, one user, no federation — sqlite is plenty, and it dodges
# coupling everything to the global host postgres. See ADR-009.
{ pkgs, config, ... }:

let
  serverName = "jollof.chat";
  # this node's tailnet name = the url clients point at. sparkyfitness already owns :443,
  # so matrix gets :8448 (the usual matrix port). tailnet domain lives in modules/tailnet.nix.
  fqdn = (import ../../modules/tailnet.nix).fqdnFor config.networking.hostName;
  matrixPort = 8448;
in {
  # nixos doesnt like libolm "insecure" apparently... ignore!! 🤣
  nixpkgs.config.permittedInsecurePackages = [ "olm-3.2.16" ];

  services.matrix-synapse = {
    enable = true;
    settings = {
      server_name = serverName;
      # the url clients actually hit (tailscale serve terminates TLS, see below)
      public_baseurl = "https://${fqdn}:${toString matrixPort}/";
      registration_shared_secret_path =
        config.age.secrets.matrix-registration.path;
      # double-puppet appservice (ADR-011): lets the bridges write MY read receipts.
      # Merges with the entries each bridge adds via registerToSynapse.
      app_service_config_files =
        [ config.age.secrets.matrix-doublepuppet.path ];
      database.name = "sqlite3";
      # localhost listener; tailscale serve does TLS + proxies to it. x_forwarded as we're now
      # behind that proxy.
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
    enable = true; # this enables registerToSynapse option
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
      # ADR-011 double puppeting: Telegram is the PYTHON bridge — different schema, and it
      # already uses environmentFile. So no settings change here; add this to the EXISTING
      # mautrix-telegram-env.age (alongside api_id/api_hash):
      #   MAUTRIX_TELEGRAM_BRIDGE_LOGIN_SHARED_SECRET_MAP=json::{"jollof.chat":"as_token:<token>"}
    };
  };

  # whatsapp bridge
  services.mautrix-whatsapp = {
    enable = true;
    environmentFile =
      config.age.secrets.matrix-doublepuppet-env.path; # ADR-011: DOUBLEPUPPET_AS_TOKEN
    settings = {
      homeserver = {
        address = "http://localhost:8008";
        domain = serverName;
      };
      bridge.permissions = { "@jollof:${serverName}" = "admin"; };
      # ADR-011: bridge acts as @jollof to sync read receipts. $VAR is envsubst'd at start.
      double_puppet.secrets.${serverName} = "as_token:$DOUBLEPUPPET_AS_TOKEN";
    };
  };

  # signal bridge
  services.mautrix-signal = {
    enable = true;
    environmentFile = config.age.secrets.matrix-doublepuppet-env.path; # ADR-011
    settings = {
      homeserver = {
        address = "http://localhost:8008";
        domain = serverName;
      };
      bridge.permissions = { "@jollof:${serverName}" = "admin"; };
      double_puppet.secrets.${serverName} = "as_token:$DOUBLEPUPPET_AS_TOKEN";
    };
  };

  # meta bridge - an instance, not a flat service like the others
  services.mautrix-meta.instances.facebook = {
    enable = true;
    environmentFile = config.age.secrets.matrix-doublepuppet-env.path; # ADR-011
    settings = {
      homeserver = {
        address = "http://localhost:8008";
        domain = serverName;
      };
      bridge.permissions = { "@jollof:${serverName}" = "admin"; };
      # meta demands E2EE + drops plain commands otherwise - turn it off
      encryption = {
        allow = false;
        default = false;
        require = false;
      };
      double_puppet.secrets.${serverName} = "as_token:$DOUBLEPUPPET_AS_TOKEN";
    };
  };

  # tailscale serve: tailnet HTTPS :8448 -> synapse on localhost
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

  # agenix secrets - same .age files as desktop-work (encrypted to allHosts, pi-box can decrypt)
  age.secrets.matrix-registration = {
    file = ../../secrets/matrix-registration.age;
    owner = "matrix-synapse";
  };
  age.secrets.mautrix-telegram-env = {
    file = ../../secrets/mautrix-telegram-env.age;
    owner = "mautrix-telegram";
  };
  # ADR-011 double puppeting.
  age.secrets.matrix-doublepuppet = {
    file =
      ../../secrets/matrix-doublepuppet.age; # doublepuppet.yaml registration
    owner = "matrix-synapse"; # synapse reads it directly
  };
  # DOUBLEPUPPET_AS_TOKEN for the Go bridges. Read by systemd (root) as EnvironmentFile,
  # so default owner (root) is fine — the bridge users don't need read access.
  age.secrets.matrix-doublepuppet-env.file =
    ../../secrets/matrix-doublepuppet-env.age;

  # reload synapse when the registration/token changes (source .age hash changes on edit)
  systemd.services.matrix-synapse.restartTriggers =
    [ ../../secrets/matrix-doublepuppet.age ];
}
