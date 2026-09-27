{ pkgs, config, ... }:

let
  stateDir = "/var/lib/sparkyfitness";
  repoUrl = "https://github.com/CodeWithCJ/SparkyFitness";
  version = "v1.6.0";
  repoDir = "${stateDir}/repo";
  composeDir = "${repoDir}/docker";
  secretsEnv = config.age.secrets.sparkyfitness-env.path;

  overrideFile = "/etc/sparkyfitness/docker-compose.override.yml";

  # Use absolute paths because the repository is cloned at service startup.
  compose = "${pkgs.docker-compose}/bin/docker-compose -p sparkyfitness"
    + " -f ${composeDir}/docker-compose.prod.yml -f ${overrideFile} --env-file ${secretsEnv}";

  # Upstream Compose publishes the frontend on host port 3004.
  frontendPort = 3004;

  fqdn = (import ../../modules/tailnet.nix).fqdnFor config.networking.hostName;
in {
  # Root-only copy of the shared database, auth and encryption secrets.
  age.secrets.sparkyfitness-env.file = ../../secrets/sparkyfitness-secrets.age;

  # Pin the application images; upstream Compose uses latest.
  environment.etc."sparkyfitness/docker-compose.override.yml".text = ''
    services:
      sparkyfitness-server:
        image: codewithcj/sparkyfitness_server:${version}
      sparkyfitness-frontend:
        image: codewithcj/sparkyfitness:${version}
  '';

  systemd.services.sparkyfitness = {
    description = "SparkyFitness — clone-if-missing + docker compose up";
    after = [ "network-online.target" "docker.service" ];
    requires = [ "docker.service" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    path = [ pkgs.git pkgs.docker pkgs.docker-compose ];

    # Keep persistent data outside the repository so recloning preserves it.
    environment = {
      SPARKY_FITNESS_DB_NAME = "sparkyfitness";
      SPARKY_FITNESS_DB_USER = "sparky";
      SPARKY_FITNESS_FRONTEND_URL = "https://${fqdn}";
      DB_PATH = "${stateDir}/postgresql";
      SERVER_BACKUP_PATH = "${stateDir}/backup";
      SERVER_UPLOADS_PATH = "${stateDir}/uploads";
    };

    # Fetch tags and check out the pinned release before starting Compose.
    preStart = ''
      set -e
      if [ ! -e "${repoDir}/.git" ]; then
        echo "cloning directory ${repoDir}..."
        rm -rf "${repoDir}"
        git clone ${repoUrl} "${repoDir}"
      fi
      echo "going to dir... ${repoDir}"
      cd "${repoDir}"
      echo "getting tags..."
      git fetch --all || exit 1
      echo "checking out tag ${version}"
      git checkout "tags/${version}" || exit 1
    '';

    serviceConfig = {
      Type =
        "simple"; # Keep Compose in the foreground for systemd.
      StateDirectory = "sparkyfitness"; # creates/owns /var/lib/sparkyfitness
      WorkingDirectory = stateDir;
      ExecStart = "${compose} up";
      ExecStop = "${compose} down";
      Restart = "on-failure";
      RestartSec = 10;
      # Allow time for the initial clone and image downloads.
      TimeoutStartSec = "infinity";
    };
  };

  # Requires Tailscale HTTPS certificates to be enabled in the admin console.
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

}
