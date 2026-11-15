# openhands agent canvas, run as claude, at https://<hostName> (needs tailnet-caddy.nix for the cert)
# trial next to aoe and codeg: web UI for the openhands agent plus ACP agents (claude, codex...)
# login: paste the key from `sudo cat /run/agenix/agent-canvas-env`
# options from https://docs.openhands.dev/openhands/usage/agent-canvas/setup.md
# not in nixpkgs, so npx fetches the pinned version on first start; agent-server and automation come from PyPI via uvx
# it also listens on 127.0.0.1:18000 (agent-server) and 127.0.0.1:18001 (automation), fixed by agent-canvas
{ hostName, port }:
{ pkgs, pkgs-unstable, config, ... }:

let
  version = "1.40.0";
in {
  # holds LOCAL_BACKEND_API_KEY, the web login (--public makes the UI ask for it instead of embedding it)
  age.secrets.agent-canvas-env.file = ../secrets/agent-canvas-env.age;

  systemd.services.agent-canvas = {
    description = "openhands agent canvas";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    # node 24 first: agent-canvas needs >= 24 and the system node is 22
    # agents (codex-acp, claude, git...) launch from here, so give it the same tools a login shell gets
    path = [ pkgs-unstable.nodejs_24 "/run/current-system/sw" "/etc/profiles/per-user/claude" ];
    serviceConfig = {
      User = "claude";
      # localhost only, caddy does the https
      ExecStart = "${pkgs-unstable.nodejs_24}/bin/npx -y @openhands/agent-canvas@${version} --public --host 127.0.0.1 --port ${toString port}";
      EnvironmentFile = config.age.secrets.agent-canvas-env.path;
      Restart = "on-failure";
    };
  };

  services.caddy.virtualHosts.${hostName}.extraConfig = "reverse_proxy localhost:${toString port}";
}
