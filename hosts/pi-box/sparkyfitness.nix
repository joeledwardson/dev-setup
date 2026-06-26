# SparkyFitness on pi-box — the simple, boring approach: a systemd service that clones the
# upstream repo if missing and runs `docker compose up` in the FOREGROUND, so systemd owns the
# process (logs to the journal, restarts on crash). Docker is already enabled via nixos-base.
#
# Ordering (the fiddly bit): start only after the network is up AND the docker daemon is loaded.
#   after    = network-online.target + docker.service   (don't start before they're ready)
#   requires = docker.service                            (hard dep — stop us if docker dies)
#   wants    = network-online.target                     (pull it into the boot, soft)
#
# Secrets are declarative via agenix: the app secrets live encrypted in secrets/*.age, decrypted at
# runtime to a root-only file and passed to compose via `--env-file`. Non-secret config (DB
# name/user, data paths, public URL) stays visible in the Nix `environment` — nothing sensitive in
# the store.
#
# NOT declarative (manual, one-time, via the web UI): SparkyAI (the Gemini key) and the external
# food-data providers (USDA, FatSecret). SparkyFitness has no env/config knob for these — they are
# AES-GCM-encrypted DB rows set through Settings. See the "Manual setup" note at the bottom.
{ pkgs, config, ... }:

let
  stateDir = "/var/lib/sparkyfitness";
  repoUrl = "https://github.com/CodeWithCJ/SparkyFitness";
  repoDir = "${stateDir}/repo";
  composeDir = "${repoDir}/docker";
  secretsEnv = config.age.secrets.sparkyfitness-env.path;

  # Override layered on the upstream prod compose. The published :latest server image still uses
  # the MCP "stdio" transport (spawns a binary that isn't in the image) UNLESS
  # SPARKY_FITNESS_MCP_URL is set — and it has no in-process /mcp route — so SparkyAI chat needs
  # the MCP sidecar container + the server pointed at it over HTTP. (main has moved MCP in-process,
  # but the release hasn't caught up.) Lives in /etc (declarative, no secrets — only ${} refs).
  overrideFile = "/etc/sparkyfitness/docker-compose.override.yml";

  # docker-compose v2 (standalone). Absolute -f paths (the clone dir doesn't exist until first
  # clone, so we can't rely on WorkingDirectory). Stable project name; secrets via --env-file.
  compose = "${pkgs.docker-compose}/bin/docker-compose -p sparkyfitness"
    + " -f ${composeDir}/docker-compose.prod.yml -f ${overrideFile} --env-file ${secretsEnv}";

  # The frontend nginx is published on 3004 by the upstream compose (`3004:80`).
  frontendPort = 3004;
in {
  # SparkyFitness's OWN root-only copy of the compose env-file (DB passwords, BETTER_AUTH_SECRET,
  # the app's master encryption key). Declared under a sparkyfitness-* name (distinct from the
  # shared `nixos-secrets.nix` set this host also imports) so the two never collide: the shared
  # copies are group-readable for `llm`/querying, this one stays locked to root.
  age.secrets.sparkyfitness-env.file = ../../secrets/sparkyfitness-secrets.age;

  # MCP sidecar + server wiring (see overrideFile note above). docker compose merges this onto the
  # upstream prod compose. `''${VAR}` is an escaped literal `${VAR}` for compose interpolation
  # (resolved from the systemd `environment` below + the --env-file), NOT Nix interpolation.
  environment.etc."sparkyfitness/docker-compose.override.yml".text = ''
    services:
      sparkyfitness-server:
        environment:
          SPARKY_FITNESS_MCP_URL: http://sparkyfitness-mcp:3001
          # Server-level Better Auth API key. The chat→MCP internal call forwards THIS (as x-api-key)
          # to the MCP sidecar, so non-browser callers (the Telegram bot, n8n) can drive the agentic
          # tools without a session cookie. Value lives in the agenix --env-file. See ADR-003.
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
    after = [ "network-online.target" "docker.service" ];
    requires = [ "docker.service" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    # Tools the unit shells out to (git for the clone, docker for compose's daemon calls).
    path = [ pkgs.git pkgs.docker pkgs.docker-compose ];

    # Non-secret config — interpolated into the compose files alongside the secrets from --env-file.
    # Data paths point OUT of the git clone so a re-clone never touches the database.
    environment = {
      SPARKY_FITNESS_DB_NAME = "sparkyfitness";
      SPARKY_FITNESS_DB_USER = "sparky";
      SPARKY_FITNESS_FRONTEND_URL = "https://pi-box.rove-lydian.ts.net";
      DB_PATH = "${stateDir}/postgresql";
      SERVER_BACKUP_PATH = "${stateDir}/backup";
      SERVER_UPLOADS_PATH = "${stateDir}/uploads";
    };

    # Clone on first boot only. Idempotent: skipped once the repo exists. If a previous clone was
    # interrupted (dir exists but no .git), clear the partial dir first so the retry isn't wedged
    # by "destination already exists and is not empty".
    preStart = ''
      if [ ! -e "${repoDir}/.git" ]; then
        rm -rf "${repoDir}"
        git clone --depth=1 ${repoUrl} "${repoDir}"
      fi
    '';

    serviceConfig = {
      Type =
        "simple"; # `compose up` (no -d) stays in the foreground → systemd manages it
      StateDirectory = "sparkyfitness"; # creates/owns /var/lib/sparkyfitness
      WorkingDirectory =
        stateDir; # always exists (StateDirectory); the clone lives under it
      ExecStart = "${compose} up";
      ExecStop = "${compose} down";
      Restart = "on-failure";
      RestartSec = 10;
      # First run clones the repo and pulls multi-arch images on a Pi — can take many minutes.
      # Don't let the start timeout kill the clone in ExecStartPre.
      TimeoutStartSec = "infinity";
    };
  };

  # Tailscale Serve — FOREGROUND (no --bg) so systemd owns the process: journal logs + crash
  # restart, and the serve config is tied to this unit's lifecycle (stop unit → serve removed).
  # HTTPS :443 → the frontend. Requires the node to be authed + HTTPS certs enabled in the admin
  # console (one-time, manual).
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

  # ── Manual setup (one-time, via the web UI) ───────────────────────────────────────────────────
  # SparkyFitness stores AI + external-provider credentials only as AES-GCM-encrypted DB rows set
  # through Settings — there is no env/config knob (the only key-ish env var, the app's master
  # encryption key, lives in the --env-file above). So these are deliberately NOT declarative:
  #
  #   SparkyAI (Gemini):   Settings → AI Service → add Google / gemini-2.5-flash, paste the key from
  #                        `sudo cat /run/agenix/llm-gemini-key`. (Requires the MCP sidecar above.)
  #   USDA provider:       Settings → Integrations → USDA, paste `sudo cat /run/agenix/usda`.
  #   FatSecret provider:  Settings → Integrations → FatSecret, client id/secret from
  #                        `sudo cat /run/agenix/fatsecret-client-id` / `…-fatsecret-client-secret`.
  #
  # FatSecret extra step: its REST API rejects non-allowlisted IPs (error 21 "Invalid IP"). Whitelist
  # the box's *IPv4* (the Docker container egresses v4-only — your host IPv6 is irrelevant) in the
  # FatSecret console → IP Restrictions. Get it with `curl -4 https://api.ipify.org`; free tier =
  # specific IP, no CIDR; re-add if your ISP rotates the v4.
  #
  # The keys are decrypted on this host (agenix, group `users`) purely for convenient copy-paste.
  # Fuller reference (UI paths, provider coverage, FatSecret IP gotcha): calories-app docs →
  # "Manual Setup" (docs/manual-setup.md).
}
