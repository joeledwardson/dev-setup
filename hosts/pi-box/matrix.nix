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
      registration_shared_secret_path = config.age.secrets.matrix-registration.path;
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
      telegram = { api_id = 0; api_hash = ""; }; # real values via environmentFile
      bridge.permissions = { "@jollof:${serverName}" = "admin"; };
    };
  };

  # whatsapp bridge
  services.mautrix-whatsapp = {
    enable = true;
    settings = {
      homeserver = {
        address = "http://localhost:8008";
        domain = serverName;
      };
      bridge.permissions = { "@jollof:${serverName}" = "admin"; };
    };
  };

  # signal bridge
  services.mautrix-signal = {
    enable = true;
    settings = {
      homeserver = {
        address = "http://localhost:8008";
        domain = serverName;
      };
      bridge.permissions = { "@jollof:${serverName}" = "admin"; };
    };
  };

  # meta bridge - an instance, not a flat service like the others
  services.mautrix-meta.instances.facebook = {
    enable = true;
    settings = {
      homeserver = {
        address = "http://localhost:8008";
        domain = serverName;
      };
      bridge.permissions = { "@jollof:${serverName}" = "admin"; };
      # meta demands E2EE + drops plain commands otherwise - turn it off
      encryption = { allow = false; default = false; require = false; };
    };
  };

  # tailscale serve: tailnet HTTPS :8448 -> synapse on localhost. foreground so systemd owns it
  # (same pattern as sparkyfitness.nix). separate port from sparky's :443 so both coexist.
  # one-time manual prereq: node authed + HTTPS certs enabled in the tailscale admin console.
  systemd.services.matrix-tailscale-serve = {
    description = "tailscale serve -> synapse :8448";
    after = [ "tailscaled.service" "matrix-synapse.service" ];
    wants = [ "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.tailscale}/bin/tailscale serve --https=${toString matrixPort} http://localhost:8008";
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
}
