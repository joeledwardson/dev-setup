{ pkgs, config, ... }:

let
  domain = "joels-netflix.com";
in {
  # Cloudflare has a DNS-only wildcard `*` record pointing at this box's tailscale IP,
  # so these names only resolve to something reachable from inside the tailnet.
  # Let's Encrypt can't reach a 100.x address, so certs come via the DNS-01 challenge,
  # which needs the cloudflare plugin compiled in and an API token to write TXT records.
  services.caddy = {
    enable = true;
    package = pkgs.caddy.withPlugins {
      plugins = [ "github.com/caddy-dns/cloudflare@v0.2.4" ];
      hash = "sha256-bzMqxWTqrJ1skZmRTXyEMCKStXpljbqe5r0Ve2cnBfM=";
    };

    # holds CF_API_TOKEN. systemd reads it as root, so caddy doesn't need to own it
    environmentFile = config.age.secrets.caddy-cloudflare-env.path;

    # nixflix's nginx already listens on :80, so don't let caddy grab it for
    # http -> https redirects. everything here is https only anyway.
    globalConfig = ''
      auto_https disable_redirects
    '';

    # this vhost only exists to get the wildcard cert. since caddy 2.10 the
    # subdomain vhosts below reuse it instead of each asking for their own cert
    virtualHosts."*.${domain}".extraConfig = ''
      tls {
        dns cloudflare {env.CF_API_TOKEN}
      }
      respond 404
    '';

    virtualHosts."jellyfin.${domain}".extraConfig =
      "reverse_proxy localhost:${toString config.nixflix.jellyfin.network.internalHttpPort}";
    virtualHosts."sonarr.${domain}".extraConfig =
      "reverse_proxy localhost:${toString config.nixflix.sonarr.config.hostConfig.port}";
    virtualHosts."radarr.${domain}".extraConfig =
      "reverse_proxy localhost:${toString config.nixflix.radarr.config.hostConfig.port}";
    virtualHosts."lidarr.${domain}".extraConfig =
      "reverse_proxy localhost:${toString config.nixflix.lidarr.config.hostConfig.port}";
    virtualHosts."prowlarr.${domain}".extraConfig =
      "reverse_proxy localhost:${toString config.nixflix.prowlarr.config.hostConfig.port}";
    virtualHosts."sabnzbd.${domain}".extraConfig =
      "reverse_proxy localhost:${toString config.nixflix.usenetClients.sabnzbd.settings.misc.port}";
    virtualHosts."seerr.${domain}".extraConfig =
      "reverse_proxy localhost:${toString config.nixflix.seerr.port}";
    virtualHosts."litellm.${domain}".extraConfig =
      "reverse_proxy localhost:${toString config.services.litellm.port}";
    virtualHosts."matrix.${domain}".extraConfig =
      "reverse_proxy localhost:8008";
    virtualHosts."beszel.${domain}".extraConfig =
      "reverse_proxy localhost:${toString config.services.beszel.hub.port}";
    # sparkyfitness uses port 3004
    virtualHosts."sparky.${domain}".extraConfig =
      "reverse_proxy localhost:3004";
  };

  age.secrets.caddy-cloudflare-env.file = ../../secrets/caddy-cloudflare-env.age;
}
