{ ... }:

let
  domain = "joels-netflix.com";

  # every tile is just a link, so name + icon is all a service needs. tiles can also
  # carry a `widget` block that polls the app's own api for live stats (queue depth,
  # who's streaming), but that needs each app's api key, so none of these have one.
  link = { name, icon, description }: {
    ${name} = {
      href = "https://${name}.${domain}";
      inherit icon description;
    };
  };
in {
  services.homepage-dashboard = {
    enable = true;

    # 8080 and 8081 are taken by the mautrix bridges, 8082 is free
    listenPort = 8082;

    # homepage rejects requests whose Host header isn't listed here, so the caddy
    # vhost name has to appear or every page comes back blank
    allowedHosts = "home.${domain}";

    settings = {
      title = "joels-netflix";
      theme = "dark";
      # groups render in this order; anything not named here gets appended
      layout = {
        Media = { style = "row"; columns = 4; };
        Apps = { style = "row"; columns = 3; };
        Infra = { style = "row"; columns = 3; };
      };
    };

    # groups match the ones in gatus.nix so both dashboards sort things the same way.
    # icon names come from https://github.com/homarr-labs/dashboard-icons
    services = [
      {
        Media = [
          (link { name = "jellyfin"; icon = "jellyfin.svg"; description = "watch"; })
          (link { name = "seerr"; icon = "jellyseerr.svg"; description = "request"; })
          (link { name = "sonarr"; icon = "sonarr.svg"; description = "tv"; })
          (link { name = "radarr"; icon = "radarr.svg"; description = "films"; })
          (link { name = "lidarr"; icon = "lidarr.svg"; description = "music"; })
          (link { name = "prowlarr"; icon = "prowlarr.svg"; description = "indexers"; })
          (link { name = "sabnzbd"; icon = "sabnzbd.svg"; description = "downloads"; })
        ];
      }
      {
        Apps = [
          (link { name = "sparky"; icon = "sparky-fitness.png"; description = "food log"; })
          # there's no litellm icon upstream, so fall back to a material design icon
          (link { name = "litellm"; icon = "mdi-robot"; description = "llm proxy"; })
          # synapse's client api, not a web ui — the browser just gets json back
          (link { name = "matrix"; icon = "matrix-synapse.svg"; description = "homeserver api"; })
        ];
      }
      {
        Infra = [
          (link { name = "gatus"; icon = "gatus.svg"; description = "uptime"; })
          (link { name = "beszel"; icon = "beszel.svg"; description = "host metrics"; })
        ];
      }
    ];
  };
}
