# Native macOS agent, connecting out to the hub over Tailscale.
{ config, lib, pkgs, ... }:
let
  user = config.system.primaryUser;
  dataDir = "/Users/${user}/Library/Application Support/beszel-agent";
in
{
  age.secrets.beszel-agent-env = {
    file = ../secrets/beszel-agent-env.age;
    owner = user;
  };

  # A daemon starts at boot, without requiring an interactive login.
  # launchd has no EnvironmentFile option; load the agenix file at runtime.
  launchd.daemons.beszel-agent = {
    script = ''
      set -eu
      set -a
      . ${lib.escapeShellArg config.age.secrets.beszel-agent-env.path}
      set +a
      mkdir -p "$DATA_DIR"
      exec ${pkgs.beszel}/bin/beszel-agent >> "$DATA_DIR/agent.log" 2>&1
    '';
    environment = {
      HOME = "/Users/${user}";
      HUB_URL = "http://streaming-server:8090";
      DISABLE_SSH = "true";
      DATA_DIR = dataDir;
    };
    serviceConfig = {
      UserName = user;
      RunAtLoad = true;
      KeepAlive = true;
      ThrottleInterval = 30;
    };
  };
}
