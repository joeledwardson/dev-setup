# OpenKnowledge docs workspace at https://worker-openknowledge.joels-netflix.com
# this box points its own DNS records at itself and gets its own certs, so nothing here depends on streaming-server
{ pkgs, ... }:

let
  pagesHostName = "worker-pages.joels-netflix.com";
  paseoHostName = "worker-paseo.joels-netflix.com";
  usageHostName = "worker-usage.joels-netflix.com";
  dashboard = pkgs.callPackage ../../pkgs/opencode-dashboard.nix { };
  wispHostName = "worker-wisp.joels-netflix.com";
  openKnowledgeHostName = "worker-openknowledge.joels-netflix.com";
  # the docs folder openknowledge treats as its project
  docsDir = "/home/claude/docs-editor-trial";
in {
  imports = [
    (import ../../modules/tailnet-caddy.nix { selfDnsNames = [ pagesHostName paseoHostName usageHostName wispHostName openKnowledgeHostName ]; })
    (import ../../modules/pages.nix { hostName = pagesHostName; })
    # port from 9000 + crc32("paseo") % 900
    (import ../../modules/paseo.nix { hostName = paseoHostName; port = 9810; user = "claude"; })
    (import ../../modules/runwisp.nix { hostName = wispHostName; port = 9477; user = "claude"; })
    # port from 9000 + crc32("open-knowledge") % 900
    (import ../../modules/open-knowledge.nix { hostName = openKnowledgeHostName; port = 9573; vaultDir = docsDir; })
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
