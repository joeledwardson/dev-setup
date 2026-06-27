# SparkyFitness on pi-box: a systemd unit clones the repo (if missing) + runs `docker compose up`
# in the foreground so systemd owns it (journal logs, crash restart). docker comes from nixos-base.
# secrets via agenix --env-file; AI + food-provider keys are manual web-UI steps (see bottom).
{ pkgs, config, ... }:

let
  stateDir = "/var/lib/sparkyfitness";
  repoUrl = "https://github.com/CodeWithCJ/SparkyFitness";
  repoDir = "${stateDir}/repo";
  composeDir = "${repoDir}/docker";
  secretsEnv = config.age.secrets.sparkyfitness-env.path;

  # layered onto the upstream prod compose. the :latest server image needs SPARKY_FITNESS_MCP_URL +
  # the MCP sidecar over http for SparkyAI chat (its bundled stdio MCP is broken). /etc, no secrets.
  overrideFile = "/etc/sparkyfitness/docker-compose.override.yml";

  # docker-compose v2. absolute -f paths (clone dir doesnt exist till first clone). secrets via --env-file.
  compose = "${pkgs.docker-compose}/bin/docker-compose -p sparkyfitness"
    + " -f ${composeDir}/docker-compose.prod.yml -f ${overrideFile} --env-file ${secretsEnv}";

  # frontend nginx is published on 3004 by upstream compose (3004:80)
  frontendPort = 3004;

  # tailnet name this box is served at (domain shared via modules/tailnet.nix).
  fqdn = (import ../../modules/tailnet.nix).fqdnFor config.networking.hostName;
in {
  # sparky's OWN root-only env-file (db passwords, auth secret, master encryption key). named
  # sparkyfitness-* so it doesnt collide with the shared group-readable nixos-secrets set.
  age.secrets.sparkyfitness-env.file = ../../secrets/sparkyfitness-secrets.age;

  # MCP sidecar + server wiring, merged onto the upstream compose. `''${VAR}` = a literal ${VAR} for
  # compose to interpolate (from the environment below + --env-file), NOT nix interpolation.
  environment.etc."sparkyfitness/docker-compose.override.yml".text = ''
    services:
      sparkyfitness-server:
        environment:
          SPARKY_FITNESS_MCP_URL: http://sparkyfitness-mcp:3001
          # forwarded to MCP as x-api-key so non-browser callers (telegram bot, n8n) work without a cookie. see ADR-003
          SPARKY_FITNESS_API_KEY: ''${SPARKY_FITNESS_API_KEY}
      sparkyfitness-mcp:
        image: codewithcj/sparkyfitness_mcp:latest
        container_name: sparkyfitness-mcp
        restart: always
        depends_on:
          - sparkyfitness-db
        networks:
          - sparkyfitness-network
        environment:
          SPARKY_FITNESS_DB_USER: ''${SPARKY_FITNESS_DB_USER:-sparky}
          SPARKY_FITNESS_DB_HOST: ''${SPARKY_FITNESS_DB_HOST:-sparkyfitness-db}
          SPARKY_FITNESS_DB_NAME: ''${SPARKY_FITNESS_DB_NAME}
          SPARKY_FITNESS_DB_PASSWORD: ''${SPARKY_FITNESS_DB_PASSWORD}
          SPARKY_FITNESS_APP_DB_USER: ''${SPARKY_FITNESS_APP_DB_USER:-sparkyapp}
          SPARKY_FITNESS_APP_DB_PASSWORD: ''${SPARKY_FITNESS_APP_DB_PASSWORD}
          SPARKY_FITNESS_DB_PORT: 5432
          BETTER_AUTH_SECRET: ''${BETTER_AUTH_SECRET}
          MCP_TRANSPORT: "http"
          SPARKY_FITNESS_SERVER_HOST: sparkyfitness-server
          SPARKY_FITNESS_SERVER_PORT: 3010
          SPARKY_FITNESS_FRONTEND_URL: ''${SPARKY_FITNESS_FRONTEND_URL}
          ALLOW_PRIVATE_NETWORK_CORS: ''${ALLOW_PRIVATE_NETWORK_CORS:-false}
  '';

  systemd.services.sparkyfitness = {
    description = "SparkyFitness — clone-if-missing + docker compose up";
    # start after network + docker are up; hard-dep on docker so we die with it
    after = [ "network-online.target" "docker.service" ];
    requires = [ "docker.service" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    # git for the clone, docker/compose for the daemon calls
    path = [ pkgs.git pkgs.docker pkgs.docker-compose ];

    # non-secret config (merged with the --env-file secrets). data paths live OUTSIDE the clone so a
    # re-clone never touches the db.
    environment = {
      SPARKY_FITNESS_DB_NAME = "sparkyfitness";
      SPARKY_FITNESS_DB_USER = "sparky";
      SPARKY_FITNESS_FRONTEND_URL = "https://${fqdn}";
      DB_PATH = "${stateDir}/postgresql";
      SERVER_BACKUP_PATH = "${stateDir}/backup";
      SERVER_UPLOADS_PATH = "${stateDir}/uploads";
    };

    # clone on first boot only (idempotent). nuke a partial/interrupted clone first so the retry
    # isnt wedged by "destination already exists and is not empty".
    preStart = ''
      if [ ! -e "${repoDir}/.git" ]; then
        rm -rf "${repoDir}"
        git clone --depth=1 ${repoUrl} "${repoDir}"
      fi
    '';

    serviceConfig = {
      Type = "simple"; # compose up (no -d) stays foreground -> systemd manages it
      StateDirectory = "sparkyfitness"; # creates/owns /var/lib/sparkyfitness
      WorkingDirectory = stateDir; # always exists (StateDirectory)
      ExecStart = "${compose} up";
      ExecStop = "${compose} down";
      Restart = "on-failure";
      RestartSec = 10;
      # first run clones + pulls multi-arch images on a pi = slow; dont let the timeout kill it
      TimeoutStartSec = "infinity";
    };
  };

  # tailscale serve, foreground so systemd owns it (stop unit -> serve removed). HTTPS :443 -> frontend.
  # one-time manual: node authed + HTTPS certs enabled in the tailscale admin console.
  systemd.services.tailscale-serve = {
    description = "Tailscale Serve → SparkyFitness frontend";
    after = [ "tailscaled.service" "sparkyfitness.service" ];
    wants = [ "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart =
        "${pkgs.tailscale}/bin/tailscale serve --https=443 http://localhost:${
          toString frontendPort
        }";
      Restart = "on-failure";
      RestartSec = 10;
    };
  };

  # ── manual setup (one-time, via the web UI) ──
  # sparky stores AI + provider keys as encrypted db rows (no env knob), so these are NOT declarative:
  #   SparkyAI (gemini): Settings -> AI Service -> Google / gemini-2.5-flash, key from
  #                      `sudo cat /run/agenix/llm-gemini-key` (needs the MCP sidecar above)
  #   USDA:              Settings -> Integrations -> USDA, `sudo cat /run/agenix/usda`
  #   FatSecret:         Settings -> Integrations -> FatSecret, `…/fatsecret-client-id` + `…-fatsecret-client-secret`
  #
  # FatSecret gotcha: rejects non-allowlisted IPs (err 21). whitelist the box's IPv4
  # (`curl -4 https://api.ipify.org`) in FatSecret console -> IP Restrictions. free tier = single IP,
  # re-add if your ISP rotates it.
}
