# SparkyFitness on pi-box — the simple, boring approach: a systemd service that clones the
# upstream repo if missing and runs `docker compose up` in the FOREGROUND, so systemd owns the
# process (logs to the journal, restarts on crash). Docker is already enabled via nixos-base.
#
# Ordering (the fiddly bit): start only after the network is up AND the docker daemon is loaded.
#   after    = network-online.target + docker.service   (don't start before they're ready)
#   requires = docker.service                            (hard dep — stop us if docker dies)
#   wants    = network-online.target                     (pull it into the boot, soft)
#
# Secrets are declarative via agenix: the 4 real secrets live encrypted in
# secrets/sparkyfitness-secrets.age, decrypted at runtime to a root-only file that compose reads
# via `--env-file`. Non-secret config (DB name/user, data paths, public URL) stays visible in the
# Nix `environment` below — nothing sensitive touches the world-readable Nix store.
{ pkgs, config, ... }:

let
  stateDir = "/var/lib/sparkyfitness";
  repoUrl = "https://github.com/CodeWithCJ/SparkyFitness";
  repoDir = "${stateDir}/repo";
  composeDir = "${repoDir}/docker";
  secretsEnv = config.age.secrets.sparkyfitness-secrets.path;
  # docker-compose v2 (standalone binary). Absolute -f so it works regardless of WorkingDirectory
  # (the compose dir does not exist until the first clone, so we can't chdir into it). Pin the
  # prod compose file + the decrypted secrets file, and a stable project name.
  compose = "${pkgs.docker-compose}/bin/docker-compose -p sparkyfitness -f ${composeDir}/docker-compose.prod.yml --env-file ${secretsEnv}";
  # The frontend nginx is published on 3004 by the upstream compose (`3004:80`).
  frontendPort = 3004;
in
{
  # Decrypt the secrets blob at runtime (uses pi-box's SSH host key). Root-only.
  age.secrets.sparkyfitness-secrets.file = ../../secrets/sparkyfitness-secrets.age;

  systemd.services.sparkyfitness = {
    description = "SparkyFitness — clone-if-missing + docker compose up";
    after = [ "network-online.target" "docker.service" ];
    requires = [ "docker.service" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    # Tools the unit shells out to (git for the clone, docker for compose's daemon calls).
    path = [ pkgs.git pkgs.docker pkgs.docker-compose ];

    # Non-secret config — interpolated into the compose file alongside the secrets from --env-file.
    # Data paths point OUT of the git clone so a re-clone never touches the database.
    environment = {
      SPARKY_FITNESS_DB_NAME = "sparkyfitness";
      SPARKY_FITNESS_DB_USER = "sparky";
      SPARKY_FITNESS_FRONTEND_URL = "https://pi-box.rove-lydian.ts.net";
      DB_PATH = "/var/lib/sparkyfitness/postgresql";
      SERVER_BACKUP_PATH = "/var/lib/sparkyfitness/backup";
      SERVER_UPLOADS_PATH = "/var/lib/sparkyfitness/uploads";
    };

    # Clone on first boot only. Idempotent: skipped once the repo exists.
    preStart = ''
      if [ ! -e "${repoDir}/.git" ]; then
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
