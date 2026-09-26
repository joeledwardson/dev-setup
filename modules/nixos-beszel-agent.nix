# Outbound monitoring over Tailscale. Import alongside nixos-secrets.nix.
{ config, ... }:
{
  services.beszel.agent = {
    enable = true;
    environment = {
      HUB_URL = "http://streaming-server:8090";
      DISABLE_SSH = "true";
      DATA_DIR = "/var/lib/beszel-agent";
    };
    environmentFile = config.age.secrets.beszel-agent-env.path;
  };
  systemd.services.beszel-agent.serviceConfig.StateDirectory = "beszel-agent";
}
