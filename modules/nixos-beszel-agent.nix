# Outbound monitoring over Tailscale. Import alongside nixos-secrets.nix.
{ config, pkgs, ... }:
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
}
