{ pkgs, config, ... }:

let
  composeFile = "/etc/langfuse/compose.yml";
  overrideFile = "/etc/langfuse/override.yml";
  compose = "${pkgs.docker-compose}/bin/docker-compose -p langfuse"
    + " -f ${composeFile} -f ${overrideFile}"
    + " --env-file ${config.age.secrets.langfuse-server-env.path}";
in
{
  age.secrets.langfuse-server-env = {
    file = ../../secrets/langfuse-server-env.age;
    owner = "root";
    mode = "0400";
  };

  environment.etc."langfuse/compose.yml".source = ../../services/langfuse/compose.yml;
  environment.etc."langfuse/override.yml".source = ../../services/langfuse/override.yml;

  # Compose manages six containers and persistent named volumes. The gateway is
  # deliberately outside this service; tracing does not need to proxy LLM calls.
  systemd.services.langfuse = {
    description = "Langfuse coding-agent trace viewer";
    wantedBy = [ "multi-user.target" ];
    requires = [ "docker.service" ];
    after = [ "docker.service" "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${compose} up -d langfuse-web langfuse-worker";
      ExecStop = "${compose} stop";
      TimeoutStartSec = "infinity";
    };
  };

  services.caddy.virtualHosts."worker-langfuse.joels-netflix.com".extraConfig = ''
    @tailnet remote_ip 100.64.0.0/10 fd7a:115c:a1e0::/48
    handle @tailnet {
      reverse_proxy 127.0.0.1:9394
    }
    handle {
      respond 403
    }
  '';
  # Langfuse returns signed MinIO URLs to the browser for images and exports.
  services.caddy.virtualHosts."worker-langfuse-media.joels-netflix.com".extraConfig = ''
    @tailnet remote_ip 100.64.0.0/10 fd7a:115c:a1e0::/48
    handle @tailnet {
      reverse_proxy 127.0.0.1:9395
    }
    handle {
      respond 403
    }
  '';
}
