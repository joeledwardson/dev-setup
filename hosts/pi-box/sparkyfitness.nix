# SparkyFitness on pi-box — the simple, boring approach: a systemd service that clones the
# upstream repo if missing and runs `docker compose up` in the FOREGROUND, so systemd owns the
# process (logs to the journal, restarts on crash). Docker is already enabled via nixos-base.
#
# Ordering (the fiddly bit): start only after the network is up AND the docker daemon is loaded.
#   after    = network-online.target + docker.service   (don't start before they're ready)
#   requires = docker.service                            (hard dep — stop us if docker dies)
#   wants    = network-online.target                     (pull it into the boot, soft)
#
# Secrets are declarative via agenix: the 4 app secrets + the Gemini API key live encrypted in
# secrets/*.age, decrypted at runtime to root-only files. App secrets go to compose via
# `--env-file`; the Gemini key is used by the AI-seed unit below. Non-secret config (DB name/user,
# data paths, public URL) stays visible in the Nix `environment` — nothing sensitive in the store.
{ pkgs, config, ... }:

let
  stateDir = "/var/lib/sparkyfitness";
  repoUrl = "https://github.com/CodeWithCJ/SparkyFitness";
  repoDir = "${stateDir}/repo";
  composeDir = "${repoDir}/docker";
  secretsEnv = config.age.secrets.sparkyfitness-secrets.path;
  geminiKeyFile = config.age.secrets.llm-gemini-key.path;

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
in
{
  # Runtime-decrypted secrets (root-only). App secrets → compose; Gemini key → AI-seed unit.
  age.secrets.sparkyfitness-secrets.file = ../../secrets/sparkyfitness-secrets.age;
  age.secrets.llm-gemini-key.file = ../../secrets/llm-gemini-key.age;

  # MCP sidecar + server wiring (see overrideFile note above). docker compose merges this onto the
  # upstream prod compose. `''${VAR}` is an escaped literal `${VAR}` for compose interpolation
  # (resolved from the systemd `environment` below + the --env-file), NOT Nix interpolation.
  environment.etc."sparkyfitness/docker-compose.override.yml".text = ''
    services:
      sparkyfitness-server:
        environment:
          SPARKY_FITNESS_MCP_URL: http://sparkyfitness-mcp:3001
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
      Type = "simple"; # `compose up` (no -d) stays in the foreground → systemd manages it
      StateDirectory = "sparkyfitness"; # creates/owns /var/lib/sparkyfitness
      WorkingDirectory = stateDir; # always exists (StateDirectory); the clone lives under it
      ExecStart = "${compose} up";
      ExecStop = "${compose} down";
      Restart = "on-failure";
      RestartSec = 10;
      # First run clones the repo and pulls multi-arch images on a Pi — can take many minutes.
      # Don't let the start timeout kill the clone in ExecStartPre.
      TimeoutStartSec = "infinity";
    };
  };

  # Declaratively seed the GLOBAL Gemini AI service so SparkyAI works for every account out of the
  # box (a global is_public row, user_id NULL — no account needed). Idempotent reconcile: runs the
  # app's OWN encryption + upsert (via tsx in the server container) so the key is encrypted exactly
  # how the app expects; updates the existing google row or inserts one. Re-runs each boot, so
  # rotating the agenix key re-applies it.
  systemd.services.sparkyfitness-ai-seed = {
    description = "Seed global Gemini AI service config (idempotent)";
    after = [ "sparkyfitness.service" ];
    requires = [ "sparkyfitness.service" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.docker pkgs.curl pkgs.coreutils ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      set -euo pipefail
      # Wait for the server API to be healthy (DB migrated) before seeding — up to ~5 min.
      for _ in $(seq 1 60); do
        if curl -fsS "http://localhost:${toString frontendPort}/api/health" >/dev/null 2>&1; then break; fi
        sleep 5
      done
      container=$(docker ps --filter name=sparkyfitness-server --format '{{.Names}}' | head -1)
      if [ -z "$container" ]; then echo "ai-seed: server container not found"; exit 1; fi
      # Pipe the key in via stdin (NOT -e/argv) so it never shows up in host `ps` output.
      docker exec -i "$container" ./node_modules/.bin/tsx -e '
        let buf = "";
        process.stdin.on("data", (c) => { buf += c; });
        process.stdin.on("end", async () => {
          try {
            const key = buf.trim();
            const m = await import("./models/chatRepository.ts");
            const existing = (await m.getGlobalAiServiceSettings()).find((s) => s.service_type === "google");
            const cfg = { service_name: "Gemini (declarative)", service_type: "google", model_name: "gemini-2.5-flash", api_key: key, is_active: true };
            await m.upsertGlobalAiServiceSetting(existing ? { ...cfg, id: existing.id } : cfg);
            console.log(existing ? "ai-seed: updated global gemini" : "ai-seed: inserted global gemini");
            process.exit(0);
          } catch (e) { console.error("ai-seed ERR", e.message); process.exit(1); }
        });
      ' < ${geminiKeyFile}
    '';
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
      ExecStart = "${pkgs.tailscale}/bin/tailscale serve --https=443 http://localhost:${toString frontendPort}";
      Restart = "on-failure";
      RestartSec = 10;
    };
  };
}
