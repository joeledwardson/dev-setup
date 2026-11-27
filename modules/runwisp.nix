# RunWisp dashboard and scheduler for the worker207 agent alert jobs.
{ hostName, port ? 9477, user ? "claude", configDir ? ../applications/agent-alerts }:
{ pkgs, ... }:

let
  runwisp = pkgs.callPackage ../pkgs/runwisp.nix { };
  home = "/home/${user}";
in {
  environment.systemPackages = [ runwisp ];

  systemd.services.runwisp = {
    description = "RunWisp scheduled jobs";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    # The jobs execute OpenCode and jq/curl from the system profile.
    path = [
      "/run/current-system/sw"
      pkgs.bash
      pkgs.coreutils
      pkgs.curl
      pkgs.jq
    ];

    environment = {
      HOME = home;
      RUNWISP_CONFIG = "${configDir}/runwisp.toml";
      RUNWISP_DATA = "/var/lib/runwisp";
      RUNWISP_HOST = "127.0.0.1";
      RUNWISP_PORT = toString port;
      # Caddy limits this vhost to tailnet clients.
      RUNWISP_AUTH = "off";
      AGENT_ALERTS_STATE_DIR = "/var/lib/runwisp/agent-alerts";
    };

    serviceConfig = {
      User = user;
      StateDirectory = "runwisp";
      StateDirectoryMode = "0700";
      ExecStart = "${runwisp}/bin/runwisp daemon";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  services.caddy.virtualHosts.${hostName}.extraConfig = ''
    @tailnet remote_ip 100.64.0.0/10 fd7a:115c:a1e0::/48
    handle @tailnet {
      reverse_proxy 127.0.0.1:${toString port}
    }
    handle {
      respond 403
    }
  '';
}
