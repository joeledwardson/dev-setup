{ config, lib, ... }:

let
  tailnetFqdn = (import ../../modules/tailnet.nix).fqdnFor config.networking.hostName;
in {
  # Require the HDD before starting media services; tmpfiles may still create empty directories.
  systemd.services.nixflix-setup-dirs.unitConfig.RequiresMountsFor =
    [ "/mnt/big-hdd" ];

  # Existing secrets include streaming-server as an agenix recipient.
  age.secrets = lib.genAttrs [
    "nixflix-sonarr-apikey"
    "nixflix-sonarr-password"
    "nixflix-radarr-apikey"
    "nixflix-radarr-password"
    "nixflix-lidarr-apikey"
    "nixflix-lidarr-password"
    "nixflix-prowlarr-apikey"
    "nixflix-prowlarr-password"
    "nixflix-indexer-nzbgeek"
    "nixflix-jellyfin-apikey"
    "nixflix-jellyfin-admin-password"
    "nixflix-seerr-apikey"
    "nixflix-sabnzbd-apikey"
    "nixflix-sabnzbd-nzbkey"
    "nixflix-sabnzbd-username"
    "nixflix-sabnzbd-password"
    "nixflix-usenet-eweka-username"
    "nixflix-usenet-eweka-password"
  ] (name: { file = ../../secrets/${name}.age; });

  nixflix = {
    enable = true;
    mediaDir = "/mnt/big-hdd/nixflix/media";
    downloadsDir = "/mnt/big-hdd/nixflix/downloads";
    stateDir = "/mnt/big-hdd/nixflix/.state";
    mediaUsers = [ "claude" ];

    theme = {
      enable = true;
      name = "overseerr";
    };

    nginx = {
      enable = true;
      addHostsEntries = true; # Resolve local proxy hostnames.
    };

    postgres.enable = true;

    sonarr = {
      enable = true;
      openFirewall = true; # tcp 8989
      config = {
        apiKey._secret = config.age.secrets."nixflix-sonarr-apikey".path;
        # Allow direct LAN/tailnet access alongside the nginx proxy.
        hostConfig.bindAddress = "0.0.0.0";
        hostConfig.password._secret = config.age.secrets."nixflix-sonarr-password".path;
      };
    };

    radarr = {
      enable = true;
      openFirewall = true; # tcp 7878
      config = {
        apiKey._secret = config.age.secrets."nixflix-radarr-apikey".path;
        hostConfig.bindAddress = "0.0.0.0";
        hostConfig.password._secret = config.age.secrets."nixflix-radarr-password".path;
      };
    };

    recyclarr = {
      enable = true;
      # Keep managedProfiles in sync with profile names below to prevent deletion.
      cleanupUnmanagedProfiles = {
        enable = true;
        managedProfiles = [ "HD Bluray + WEB" "WEB-1080p (Alternative)" ];
      };

      # Avoid the default SQP release-group score requirement; see nixflix#305.
      config.radarr.radarr = {
        quality_definition.type = "movie";
        quality_profiles = [
          {
            trash_id = "d1d67249d3890e49bc12e275d989a7e9"; # HD Bluray + WEB
            reset_unmatched_scores.enabled = true;
          }
        ];
      };
    };

    lidarr = {
      enable = true;
      openFirewall = true; # tcp 8686
      config = {
        apiKey._secret = config.age.secrets."nixflix-lidarr-apikey".path;
        hostConfig.bindAddress = "0.0.0.0";
        hostConfig.password._secret = config.age.secrets."nixflix-lidarr-password".path;
      };
    };

    prowlarr = {
      enable = true;
      openFirewall = true; # tcp 9696
      config = {
        apiKey._secret = config.age.secrets."nixflix-prowlarr-apikey".path;
        hostConfig.bindAddress = "0.0.0.0";
        hostConfig.password._secret = config.age.secrets."nixflix-prowlarr-password".path;
        indexers = [
          {
            # Must match Prowlarr’s case-sensitive indexer schema name.
            name = "NZBgeek";
            apiKey._secret = config.age.secrets."nixflix-indexer-nzbgeek".path;
          }
        ];
      };
    };

    usenetClients.sabnzbd = {
      enable = true;
      openFirewall = true; # tcp 8081

      settings = {
        misc = {
          # Port 8080 is used by mautrix-telegram.
          port = 8081;
          host = "0.0.0.0";
          # Accept requests using the proxy, LAN and tailnet hostnames.
          host_whitelist = "sabnzbd.nixflix,${config.networking.hostName},${tailnetFqdn}";
          api_key._secret = config.age.secrets."nixflix-sabnzbd-apikey".path;
          nzb_key._secret = config.age.secrets."nixflix-sabnzbd-nzbkey".path;
          username._secret = config.age.secrets."nixflix-sabnzbd-username".path;
          password._secret = config.age.secrets."nixflix-sabnzbd-password".path;
        };

        servers = [
          {
            name = "Eweka";
            host = "sslreader.eweka.nl";
            port = 563;
            username._secret = config.age.secrets."nixflix-usenet-eweka-username".path;
            password._secret = config.age.secrets."nixflix-usenet-eweka-password".path;
            connections = 20;
            ssl = true;
            priority = 0;
            retention = 3000;
          }
        ];
      };
    };

    jellyfin = {
      enable = true;
      openFirewall = true;
      # An empty list binds all interfaces, overriding the proxy’s loopback default.
      network.localNetworkAddresses = [ ];
      apiKey._secret = config.age.secrets."nixflix-jellyfin-apikey".path;
      users = {
        admin = {
          mutable = false;
          policy = {
            isAdministrator = true;
            # Keep direct play until hardware transcoding is configured.
            enableVideoPlaybackTranscoding = false;
            enableAudioPlaybackTranscoding = false;
            # Container remuxing does not re-encode the video.
            enablePlaybackRemuxing = true;
          };
          password._secret = config.age.secrets."nixflix-jellyfin-admin-password".path;
        };
      };

      # Skip preview generation during library scans.
      libraries = {
        Movies = {
          enableTrickplayImageExtraction = false;
          extractTrickplayImagesDuringLibraryScan = false;
          enableChapterImageExtraction = false;
          extractChapterImagesDuringLibraryScan = false;
        };
        Shows = {
          enableTrickplayImageExtraction = false;
          extractTrickplayImagesDuringLibraryScan = false;
          enableChapterImageExtraction = false;
          extractChapterImagesDuringLibraryScan = false;
        };
      };
    };

    seerr = {
      enable = true;
      openFirewall = true; # tcp 5055
      apiKey._secret = config.age.secrets."nixflix-seerr-apikey".path;
    };

  };

  # Create category directories before the first download; see nixflix#135.
  systemd.tmpfiles.settings."10-sabnzbd" =
    let
      completeDir = config.nixflix.usenetClients.sabnzbd.settings.misc.complete_dir;
      categoryDir = { d = { user = "sabnzbd"; group = "media"; mode = "0775"; }; };
    in {
      "${completeDir}/radarr" = categoryDir;
      "${completeDir}/sonarr" = categoryDir;
      "${completeDir}/lidarr" = categoryDir;
      "${completeDir}/prowlarr" = categoryDir;
    };

  # Seerr uses HOST to select its listening address.
  systemd.services.seerr.environment.HOST = lib.mkForce "0.0.0.0";

}
