{ config, ... }:

let
  domain = "joels-netflix.com";

  # checked through caddy, so a broken cert or proxy shows up too, not just a dead app
  httpCheck = { name, group, path }: {
    inherit name group;
    url = "https://${name}.${domain}${path}";
    interval = "1m";
    conditions = [ "[STATUS] == 200" ];
  };
in {
  # gatus fills in ${VAR} from this file at startup, so secrets stay out of the nix store
  age.secrets.gatus-env.file = ../../secrets/gatus-env.age;

  services.gatus = {
    enable = true;
    environmentFile = config.age.secrets.gatus-env.path;
    settings = {
      # 8080 is taken by mautrix-telegram
      web.port = 8099;
      ui.title = "streaming-server status";
      storage = {
        type = "sqlite";
        path = "/var/lib/gatus/data.db";
      };

      # see secrets.nix for how to get both values (see https://gatus.io/docs/alerting-telegram)
      alerting.telegram = {
        token = "\${TELEGRAM_BOT_TOKEN}";
        id = "\${TELEGRAM_CHAT_ID}";
      };

      # no alerts on these, add `alerts = [ { type = "telegram"; } ];` to one if it should page
      endpoints = [
        (httpCheck { name = "sparky"; group = "apps"; path = "/api/health"; })
        (httpCheck { name = "matrix"; group = "apps"; path = "/health"; })
        (httpCheck { name = "litellm"; group = "apps"; path = "/health/liveliness"; })
        (httpCheck { name = "jellyfin"; group = "media"; path = "/health"; })
        (httpCheck { name = "seerr"; group = "media"; path = "/api/v1/status"; })
        (httpCheck { name = "sonarr"; group = "media"; path = "/ping"; })
        (httpCheck { name = "radarr"; group = "media"; path = "/ping"; })
        (httpCheck { name = "lidarr"; group = "media"; path = "/ping"; })
        (httpCheck { name = "prowlarr"; group = "media"; path = "/ping"; })
        # the web root redirects to a login page, this one answers without auth
        (httpCheck { name = "sabnzbd"; group = "media"; path = "/api?mode=version"; })
        (httpCheck { name = "beszel"; group = "infra"; path = "/api/health"; })
      ];

      # jobs push results here, the push URL key is "<group>_<name>" (backups_sparkyfitness)
      external-endpoints = [
        {
          name = "sparkyfitness";
          group = "backups";
          token = "\${GATUS_BACKUP_TOKEN}";
          # pi-box pulls once a day, so silence for longer than this means it didn't run
          heartbeat.interval = "26h";
          alerts = [
            {
              type = "telegram";
              # one failed run is enough, there's no flapping to smooth over
              failure-threshold = 1;
              success-threshold = 1;
              send-on-resolved = true;
            }
          ];
        }
      ];
    };
  };
}
