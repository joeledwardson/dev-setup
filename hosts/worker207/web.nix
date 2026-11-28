# HTML pages at https://worker-pages.joels-netflix.com
# Paseo at https://worker-paseo.joels-netflix.com
# Agent usage at https://worker-usage.joels-netflix.com
# RunWisp at https://worker-wisp.joels-netflix.com
# SilverBullet docs at https://worker-silverbullet.joels-netflix.com
# this box points its own DNS records at itself and gets its own certs, so nothing here depends on streaming-server
{ pkgs, ... }:

let
  pagesHostName = "worker-pages.joels-netflix.com";
  paseoHostName = "worker-paseo.joels-netflix.com";
  usageHostName = "worker-usage.joels-netflix.com";
  dashboard = pkgs.callPackage ../../pkgs/opencode-dashboard.nix { };
  wispHostName = "worker-wisp.joels-netflix.com";
  silverbulletHostName = "worker-silverbullet.joels-netflix.com";
in {
  imports = [
    (import ../../modules/tailnet-caddy.nix { selfDnsNames = [ pagesHostName paseoHostName usageHostName wispHostName silverbulletHostName ]; })
    (import ../../modules/pages.nix { hostName = pagesHostName; })
    # port from 9000 + crc32("paseo") % 900
    (import ../../modules/paseo.nix { hostName = paseoHostName; port = 9810; user = "claude"; })
    (import ../../modules/runwisp.nix { hostName = wispHostName; port = 9477; user = "claude"; })
    # port from 9000 + crc32("silverbullet") % 900
    (import ../../modules/silverbullet.nix { hostName = silverbulletHostName; port = 9764; spaceDir = "/home/claude/docs-editor-trial"; })
  ];

  # Read the session files written by the agents running as claude.
  systemd.services.opencode-dashboard = {
    description = "Coding agent sessions and tool calls";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      User = "claude";
      ExecStart = "${dashboard}/bin/opencode-dashboard web --host 127.0.0.1 --port 7450 --no-open --allowed-hosts ${usageHostName}";
      Restart = "on-failure";
    };
  };

  services.caddy.virtualHosts.${usageHostName}.extraConfig = ''
    @tailnet remote_ip 100.64.0.0/10 fd7a:115c:a1e0::/48
    handle @tailnet {
      # The dashboard compares Origin with the HTTP connection from Caddy.
      @dashboardOrigin header Origin https://${usageHostName}
      request_header @dashboardOrigin Origin http://${usageHostName}
      reverse_proxy 127.0.0.1:7450
    }
    handle {
      respond 403
    }
  '';
}
