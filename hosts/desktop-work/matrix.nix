# Minimal self-hosted Matrix homeserver + Telegram bridge
# See ADR-009 for full setup steps
{ config, ... }:

let
  # Your Matrix identity becomes  @jollof:${serverName}
  serverName = "jollof.chat";
in {
  # nixos doesnt like libolm "insecure" apparently... ignore!! 🤣
  nixpkgs.config.permittedInsecurePackages = [ "olm-3.2.16" ];

  services.matrix-synapse = {
    enable = true;
    settings = {
      server_name = serverName;
      public_baseurl = "http://localhost:8008/";

      # synapse to read secret env at runtime so not exposed to nix store
      registration_shared_secret_path =
        config.age.secrets.matrix-registration.path;

      # testing db - use sqlite
      database.name = "sqlite3";

      # One plain-http listener, localhost only. Nothing reachable off this box.
      listeners = [{
        port = 8008;
        bind_addresses = [ "127.0.0.1" ];
        type = "http";
        tls = false;
        x_forwarded = false;
        resources = [{
          names = [ "client" ];
          compress = false;
        }];
      }];
    };
  };

  services.mautrix-telegram = {
    enable = true; # this enables registerToSynapse  option

    # grab telegram API secrets from agenix secret
    environmentFile = config.age.secrets.mautrix-telegram-env.path;

    settings = {
      homeserver = {
        address = "http://localhost:8008";
        domain = serverName;
      };
      # Real values arrive via environmentFile above; these placeholders just satisfy the schema.
      telegram = {
        api_id = 0;
        api_hash = "";
      };
      # Only you may use the bridge, as admin.
      bridge.permissions = { "@jollof:${serverName}" = "admin"; };
    };
  };

  # whatsapp bridge
  services.mautrix-whatsapp = {

    enable =
      true; # this enables the registerToSynapse option (auto registers with synapse so i dont have to do it)
    settings = {
      homeserver = {
        # MUST override: module default is :8448, but our Synapse listens on 8008.
        address = "http://localhost:8008";
        domain = serverName;
      };
      # NB: this module wants `bridge.permissions` (the bridge errors "bridge.permissions not
      # configured" otherwise) — same key as the telegram block above. You = admin.
      bridge.permissions = { "@jollof:${serverName}" = "admin"; };
    };
  };

  # signal bridge
  services.mautrix-signal = {
    enable = true;
    settings = {
      homeserver = {
        # MUST override: module default is :8448, our Synapse listens on 8008.
        address = "http://localhost:8008";
        domain = serverName;
      };
      bridge.permissions = { "@jollof:${serverName}" = "admin"; };
    };
  };

  # meta bridge - requires a different configuration to others (an instance)
  services.mautrix-meta.instances.facebook = {
    enable = true;
    # registerToSynapse defaults true -> registration auto-wired into Synapse.
    settings = {
      homeserver = {
        # MUST set: this module's default address is "" (asserted non-empty) — no :8448 fallback.
        address = "http://localhost:8008";
        domain = serverName;
      };
      # Same key as the other bridges (module asserts bridge.permissions != {}). You = admin.
      bridge.permissions = { "@jollof:${serverName}" = "admin"; };
      # mautrix-meta REQUIRES E2EE by default and DROPS unencrypted commands - tell it unsecured to stop complaining
      encryption = {
        allow = false;
        default = false;
        require = false;
      };
    };
  };

  # --- agenix secrets (same pattern as hosts/pi-box/sparkyfitness.nix) ---
  # owner must match the service user so each service can read its own secret.
  age.secrets.matrix-registration = {
    file = ../../secrets/matrix-registration.age;
    owner = "matrix-synapse";
  };
  age.secrets.mautrix-telegram-env = {
    file = ../../secrets/mautrix-telegram-env.age;
    owner = "mautrix-telegram";
  };
}
