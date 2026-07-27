# SparkyFitness on pi-box: a systemd unit clones the repo (if missing) + runs `docker compose up`
# in the foreground so systemd owns it (journal logs, crash restart). docker comes from nixos-base.
# secrets via agenix --env-file; AI + food-provider keys are manual web-UI steps (see bottom).
{ pkgs, config, ... }:

let
  stateDir = "/var/lib/sparkyfitness";
  repoUrl = "https://github.com/CodeWithCJ/SparkyFitness";
  # pin repo + images to a release tag (GitHub + Docker Hub tags carry the `v` prefix).
  version = "v1.6.0";
  repoDir = "${stateDir}/repo";
  composeDir = "${repoDir}/docker";
  secretsEnv = config.age.secrets.sparkyfitness-env.path;

  # layered onto the upstream prod compose purely to pin the image tags off :latest. /etc, no secrets.
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

  # override only pins the images off upstream :latest (prod compose hardcodes latest, no version env var).
  # the standalone MCP sidecar was decommissioned in v1.x — MCP is now the server's built-in /mcp endpoint,
  # so no sidecar service or MCP env wiring is needed (see v1.6.0 release notes).
  environment.etc."sparkyfitness/docker-compose.override.yml".text = ''
    services:
      sparkyfitness-server:
        image: codewithcj/sparkyfitness_server:${version}
      sparkyfitness-frontend:
        image: codewithcj/sparkyfitness:${version}
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

    # clone-if-missing (full clone, so all tags are local) then checkout the pinned `version` tag every
    # start. a shallow --depth=1 clone would fetch 0 tags and the checkout would fail. data lives in
    # stateDir, outside the clone, so this never touches the db.
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
        "simple"; # compose up (no -d) stays foreground -> systemd manages it
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

  # ── manual setup, once via UI
  # grab the plain text secrets from sparkyfitness-manual.age.
  # 1. fatsecret: 
  #      - see dash here: https://platform.fatsecret.com/my-account/dashboard
  #      - creds are in bitwarden to login to their platform
  #      - go to sparkyfitness integrations and add fatsecret from the web UI
  #      - should be a client ID/client secret in the nix age file
  # 2.USDA:
  #     - API key is a one time sign up here: https://fdc.nal.usda.gov/api-key-signup
  #     - again go to sparkyfitness web UI and add USDA key there
  # 3. Withings:
  #     - developer portal is here: https://developer.withings.com/dashboard/
  #     - credentials are on bitwarden to login
  #     - requires creation of an app 
  #     - go to sparkyfitness web UI and add withings integration - should be client id / secret in the age file
  # 4. SparkyAI:
  #      - go to sparkyfitness web UI and add gemini API key to sparkyfitness there
  #      - gemini Key is held in llm-gemini-key.age
  #
  # ------------ IMPORTANT!!!!!!! ------------------------------------
  # fatsecret requires IP whitelisting
  # - I have done this for my home IP of pi-box
  # - at some point will get errors from fatsecret and will have to update said IP on rotation
}
