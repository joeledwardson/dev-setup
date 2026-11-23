# caddy for https on *.joels-netflix.com names that only resolve inside the tailnet
# let's encrypt can't reach a 100.x address, so every cert comes via the DNS-01 challenge,
# which needs the cloudflare plugin compiled in and an API token to write TXT records.
# hosts add their own `services.caddy.virtualHosts` (no tls block needed, acme_dns below covers them all)
#
# selfDnsNames: names to point at this box's tailscale IP. the `*` wildcard record already points at
# streaming-server, so streaming-server passes none and every other box lists its own names here
{ selfDnsNames ? [ ] }:
{ pkgs, lib, config, ... }:

let
  zone = "joels-netflix.com";
in {
  # holds CF_API_TOKEN (zone read + DNS edit). systemd reads it as root, so caddy doesn't need to own it
  age.secrets.caddy-cloudflare-env.file = ../secrets/caddy-cloudflare-env.age;

  services.caddy = {
    enable = true;
    package = pkgs.caddy.withPlugins {
      plugins = [ "github.com/caddy-dns/cloudflare@v0.2.4" ];
      hash = "sha256-tubXIDCJnO2mvdnPlZclwDhNGaeeYLSt7lnni3+pXDo=";
    };
    environmentFile = config.age.secrets.caddy-cloudflare-env.path;
    # https://caddyserver.com/docs/caddyfile/options#acme-dns
    globalConfig = ''
      acme_dns cloudflare {env.CF_API_TOKEN}
    '';
  };

  # overrides the wildcard for these names. runs every boot, so it follows the IP if the box ever rejoins the tailnet
  systemd.services.self-dns = lib.mkIf (selfDnsNames != [ ]) {
    description = "point ${lib.concatStringsSep " " selfDnsNames} at this machine's tailscale IP";
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

      for recordName in ${lib.concatStringsSep " " selfDnsNames}; do
        recordId=$(http --check-status --ignore-stdin GET "$api/zones/$zoneId/dns_records" type==A name==$recordName "$auth" | jq -r '.result[0].id // empty')

        # proxied=false: cloudflare's proxy can't reach a 100.x address
        if [ -z "$recordId" ]; then
          http --check-status --ignore-stdin POST "$api/zones/$zoneId/dns_records" "$auth" \
            type=A name=$recordName content="$tailscaleIp" ttl:=300 proxied:=false
        else
          http --check-status --ignore-stdin PUT "$api/zones/$zoneId/dns_records/$recordId" "$auth" \
            type=A name=$recordName content="$tailscaleIp" ttl:=300 proxied:=false
        fi
      done
    '';
    serviceConfig = {
      Type = "oneshot";
      EnvironmentFile = config.age.secrets.caddy-cloudflare-env.path;
      Restart = "on-failure";
      RestartSec = 30;
    };
  };
}
