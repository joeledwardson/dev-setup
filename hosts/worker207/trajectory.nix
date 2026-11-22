# Local coding-agent session viewer at https://worker-trajectory.joels-netflix.com/viewer/
{ pkgs, ... }:

let
  trajectory = pkgs.callPackage ../../pkgs/trajectory.nix { };
  hostName = "worker-trajectory.joels-netflix.com";
  port = 8888;
in {
  environment.systemPackages = [ trajectory ];

  # The viewer only binds to loopback. Keep it ready for the homepage link.
  systemd.services.trajectory-local-ui = {
    description = "Trajectory local session viewer";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      User = "claude";
      ExecStart = "${trajectory}/bin/trajectory local-ui --port ${toString port} --no-open";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  # Trajectory accepts only localhost Host and Origin headers. Caddy supplies
  # those after limiting access to tailnet peers.
  services.caddy.virtualHosts.${hostName}.extraConfig = ''
    @tailnet remote_ip 100.64.0.0/10 fd7a:115c:a1e0::/48
    handle @tailnet {
      redir / /viewer/ 302
      reverse_proxy 127.0.0.1:${toString port} {
        header_up Host localhost:${toString port}
        header_up Origin http://localhost:${toString port}
      }
    }
    handle {
      respond 403
    }
  '';
}
