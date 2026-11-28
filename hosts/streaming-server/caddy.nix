{ config, ... }:

let
  domain = "joels-netflix.com";
in {
  # Cloudflare has a DNS-only wildcard `*` record pointing at this box's tailscale IP,
  # so these names only resolve to something reachable from inside the tailnet.
  # caddy package, token and DNS-01 come from tailnet-caddy.nix. no selfDnsNames: the wildcard already covers this box
  imports = [ (import ../../modules/tailnet-caddy.nix { }) ];

  services.caddy = {
    # nixflix's nginx already listens on :80, so don't let caddy grab it for
    # http -> https redirects. everything here is https only anyway.
    globalConfig = ''
      auto_https disable_redirects
    '';

    # this vhost only exists to get the wildcard cert. since caddy 2.10 the
    # subdomain vhosts below reuse it instead of each asking for their own cert
    virtualHosts."*.${domain}".extraConfig = "respond 404";

    # a `*.${domain}` cert doesn't cover the apex, so caddy gets a second cert for this one
    virtualHosts.${domain}.extraConfig =
      "reverse_proxy localhost:${toString config.services.homepage-dashboard.listenPort}";
    virtualHosts."home.${domain}".extraConfig =
      "reverse_proxy localhost:${toString config.services.homepage-dashboard.listenPort}";
    virtualHosts."news.${domain}".extraConfig =
      "reverse_proxy localhost:${toString config.services.glance.settings.server.port}";
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
    virtualHosts."gatus.${domain}".extraConfig =
      "reverse_proxy localhost:${toString config.services.gatus.settings.web.port}";
    virtualHosts."beszel.${domain}".extraConfig =
      "reverse_proxy localhost:${toString config.services.beszel.hub.port}";
    # sparkyfitness uses port 3004
    virtualHosts."sparky.${domain}".extraConfig =
      "reverse_proxy localhost:3004";
    # exercise history UI for sparkyfitness, see sparky-fitness-ui.nix
    virtualHosts."exercises.${domain}".extraConfig =
      "reverse_proxy localhost:3005";
    # the immich iphone app needs a publicly-trusted cert to back up in the background
    virtualHosts."photos.${domain}".extraConfig =
      "reverse_proxy localhost:${toString config.services.immich.port}";  };
}
