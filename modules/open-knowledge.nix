# openknowledge (inkeep/open-knowledge), a markdown knowledge base editor with an MCP endpoint, run as claude, at https://<hostName>
# trial next to collabmd, both editing the same folder (needs tailnet-caddy.nix for the cert)
# no login of its own: anyone on the tailnet can edit. agents connect to https://<hostName>/mcp
# options from https://github.com/inkeep/open-knowledge/tree/main/docs/content (remote-control/methods/cli.mdx, reference/configuration.mdx)
# not in nixpkgs, so npx fetches the pinned version on first start
{ hostName, port, vaultDir }:
{ pkgs, pkgs-unstable, ... }:

let
  version = "0.89.13";
  # open-knowledge needs node >= 24 and the system node is 22
  nodejs = pkgs-unstable.nodejs_24;
in {
  systemd.services.open-knowledge = {
    description = "openknowledge editor";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    # the server refuses to boot without git; npx runs packages through `sh`
    path = [ nodejs pkgs.git pkgs.bash ];
    environment = {
      PORT = toString port;
      # caddy's forwarding headers get a 403 unless both are set; it still only listens on 127.0.0.1 (the default bind)
      OK_EXTERNAL_URL = "https://${hostName}";
      OK_ALLOW_EXTERNAL = "1";
    };
    # first start only: turn the folder into a project, like the docker entrypoint in the docs.
    # --no-mcp --no-skills so it doesn't touch claude's editor configs; stdin closed so it never waits on a prompt
    script = ''
      if [ ! -d .ok ]; then
        npx -y @inkeep/open-knowledge@${version} init --no-mcp --no-skills < /dev/null
      fi
      exec npx -y @inkeep/open-knowledge@${version} start
    '';
    serviceConfig = {
      User = "claude";
      WorkingDirectory = vaultDir;
      Restart = "on-failure";
    };
  };

  services.caddy.virtualHosts.${hostName}.extraConfig = "reverse_proxy localhost:${toString port}";
}
