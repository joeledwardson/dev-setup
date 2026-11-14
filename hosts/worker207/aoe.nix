# agent of empires dashboard at https://worker-aoe.joels-netflix.com
# this box points its own DNS record at itself and gets its own cert, so nothing here depends on streaming-server
{ pkgs, config, ... }:

let
  zone = "joels-netflix.com";
  hostName = "worker-aoe.${zone}";
  aoePort = 8080;
  aoe = pkgs.callPackage ../../pkgs/aoe.nix { };
in {
  # holds CF_API_TOKEN (zone read + DNS edit), shared with streaming-server's caddy
  age.secrets.caddy-cloudflare-env.file = ../../secrets/caddy-cloudflare-env.age;

  # ---- dashboard ----
  # localhost only, caddy below does the https. --behind-proxy marks cookies Secure and trusts caddy's X-Forwarded-* headers
  # login: open the URL from `aoe serve --status` once, the token then becomes a cookie
  systemd.services.aoe = {
    description = "agent of empires dashboard";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    # agents (claude, claude-agent-acp, git...) launch from here, so give it the same tools a login shell gets
    path = [ "/run/current-system/sw" "/etc/profiles/per-user/claude" ];
    serviceConfig = {
      # unit settings from https://www.agent-of-empires.com/guides/web-dashboard/
      Type = "notify";
      User = "claude";
      ExecStart = "${aoe}/bin/aoe serve --host 127.0.0.1 --port ${toString aoePort} --behind-proxy --allowed-host ${hostName}";
      Restart = "on-failure";
      # agent tmux sessions survive a restart of the dashboard
      KillMode = "process";
    };
  };

  # ---- https ----
  services.caddy = {
    enable = true;
    package = pkgs.caddy.withPlugins {
      plugins = [ "github.com/caddy-dns/cloudflare@v0.2.4" ];
      hash = "sha256-bzMqxWTqrJ1skZmRTXyEMCKStXpljbqe5r0Ve2cnBfM=";
    };
    environmentFile = config.age.secrets.caddy-cloudflare-env.path;
    # dns-01, because let's encrypt can't reach a 100.x address
    virtualHosts.${hostName}.extraConfig = ''
      tls {
        dns cloudflare {env.CF_API_TOKEN}
      }
      reverse_proxy localhost:${toString aoePort}
    '';
  };
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 443 ];

  # ---- dns ----
  # points worker-aoe at this box's tailscale IP, overriding the *.joels-netflix.com wildcard (which points at streaming-server)
  # runs every boot, so it follows the IP if the box ever rejoins the tailnet
  systemd.services.self-dns = {
    description = "point ${hostName} at this machine's tailscale IP";
    wantedBy = [ "multi-user.target" ];
    after = [ "tailscaled.service" "network-online.target" ];
    wants = [ "network-online.target" ];
    path = [ config.services.tailscale.package pkgs.httpie pkgs.jq ];
    # https://developers.cloudflare.com/api/resources/dns/subresources/records/
    script = ''
      api="https://api.cloudflare.com/client/v4"
      auth="Authorization:Bearer $CF_API_TOKEN"

      # fails until tailscale is logged in, Restart below retries
      tailscaleIp=$(tailscale ip -4)

      zoneId=$(http --check-status --ignore-stdin GET "$api/zones" name==${zone} "$auth" | jq -r '.result[0].id')
      recordId=$(http --check-status --ignore-stdin GET "$api/zones/$zoneId/dns_records" type==A name==${hostName} "$auth" | jq -r '.result[0].id // empty')

      # proxied=false: cloudflare's proxy can't reach a 100.x address
      if [ -z "$recordId" ]; then
        http --check-status --ignore-stdin POST "$api/zones/$zoneId/dns_records" "$auth" \
          type=A name=${hostName} content="$tailscaleIp" ttl:=300 proxied:=false
      else
        http --check-status --ignore-stdin PUT "$api/zones/$zoneId/dns_records/$recordId" "$auth" \
          type=A name=${hostName} content="$tailscaleIp" ttl:=300 proxied:=false
      fi
    '';
    serviceConfig = {
      Type = "oneshot";
      EnvironmentFile = config.age.secrets.caddy-cloudflare-env.path;
      Restart = "on-failure";
      RestartSec = 30;
    };
  };
}
