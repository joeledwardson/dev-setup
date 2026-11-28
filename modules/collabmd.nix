# collabmd, a collaborative markdown/diagram editor over a plain folder, at https://<hostName>
# trial next to openknowledge, both editing the same folder (needs tailnet-caddy.nix for the cert)
# login: the AUTH_PASSWORD line from `sudo cat /run/agenix/collabmd-env`
# agents: after logging in, More actions -> Connect AI Agent gives an MCP token for https://<hostName>/mcp
# env vars from https://github.com/andes90/collabmd/blob/master/docs/configuration.md and docs/ai-agents.md
{ hostName, port, vaultDir }:
{ config, ... }:

let
  version = "v0.1.57";
in {
  # holds AUTH_PASSWORD and AUTH_SESSION_SECRET
  age.secrets.collabmd-env.file = ../secrets/collabmd-env.age;

  # oci-containers defaults to podman, docker is what nixos-base.nix already runs
  virtualisation.oci-containers.backend = "docker";

  virtualisation.oci-containers.containers.collabmd = {
    image = "ghcr.io/andes90/collabmd:${version}";
    # localhost only, caddy does the https. the app listens on 1234 inside the container
    ports = [ "127.0.0.1:${toString port}:1234" ];
    # the image runs as root; claude's uid:gid instead, so files it writes stay editable by claude
    user = "1000:100";
    volumes = [ "${vaultDir}:/data" ];
    environment = {
      AUTH_STRATEGY = "password";
      COLLABMD_AGENT_ACCESS_ENABLED = "true";
      # MCP requests arrive through caddy with this host name, only localhost is allowed by default
      COLLABMD_AGENT_ALLOWED_HOSTS = hostName;
    };
    environmentFiles = [ config.age.secrets.collabmd-env.path ];
  };

  services.caddy.virtualHosts.${hostName}.extraConfig = "reverse_proxy localhost:${toString port}";
}
