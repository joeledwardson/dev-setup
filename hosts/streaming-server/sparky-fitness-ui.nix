{ config, pkgs, ... }:

# Exercise history UI for SparkyFitness.
# The source repo is private, so Nix can't fetch it without credentials. Instead this
# mirrors sparkyfitness.nix: clone once, then build in place whenever the pinned commit
# changes. The built app is served by caddy at https://exercises.joels-netflix.com.
let
  stateDir = "/var/lib/sparky-fitness-ui";
  repoDir = "${stateDir}/repo";
  repoUrl = "https://github.com/joels-claude-bot/sparky-fitness-ui";
  # bump this to deploy a new commit; the service rebuilds only when it changes
  rev = "02e2298099ae36418dd8493deac0b3ce18a2a6e5";

  port = 3005;
  nodejs = pkgs.nodejs_22;

  apiKeyFile = config.age.secrets.sparkyfitness-api-key.path;

  # Reads the key at launch so it never lands in the nix store.
  launcher = pkgs.writeShellScript "sparky-fitness-ui-launch" ''
    export SPARKY_API_KEY="$(cat ${apiKeyFile})"
    # same box, so skip caddy and talk to the SparkyFitness API directly
    export SPARKY_API_URL="http://127.0.0.1:3004"
    export PORT="${toString port}"
    export HOST="127.0.0.1"
    exec ${nodejs}/bin/node ${repoDir}/build/index.js
  '';

  # Clone/checkout the pinned commit, then install and build only when that commit changes.
  sync = pkgs.writeShellScript "sparky-fitness-ui-sync" ''
    set -euo pipefail
    # keep the normal home so git can use claude's gh credential helper
    export HOME="/home/claude"
    export npm_config_cache="${stateDir}/.npm"

    if [ ! -d "${repoDir}/.git" ]; then
      echo "cloning ${repoUrl}..."
      rm -rf "${repoDir}"
      git clone ${repoUrl} "${repoDir}"
    fi

    cd "${repoDir}"
    git fetch --all --tags
    git checkout --force ${rev}

    if [ "$(cat .built-rev 2>/dev/null || true)" != "${rev}" ]; then
      echo "building ${rev}..."
      ${nodejs}/bin/npm ci --no-audit --no-fund
      ${nodejs}/bin/npm run build
      echo "${rev}" > .built-rev
    fi
  '';
in {
  systemd.services.sparky-fitness-ui = {
    description = "SparkyFitness exercise history UI";
    after = [ "network-online.target" "sparkyfitness.service" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    path = [ pkgs.git nodejs pkgs.gh ];

    serviceConfig = {
      User = "claude";
      StateDirectory = "sparky-fitness-ui";
      WorkingDirectory = stateDir;
      ExecStartPre = sync;
      ExecStart = launcher;
      Restart = "on-failure";
      RestartSec = 10;
      # the first run downloads node_modules and builds the app
      TimeoutStartSec = "infinity";
    };
  };
}
