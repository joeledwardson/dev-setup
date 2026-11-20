# cloudcli (siteboon/claudecodeui), a web UI over claude code and codex, run as claude, at https://<hostName>
# trial next to aoe, codeg, agent canvas and paseo (needs tailnet-caddy.nix for the cert)
# login: cloudcli keeps its own single-user account db; username and password from `sudo cat /run/agenix/cloudcli-login`
# options from `cloudcli --help` and https://github.com/siteboon/claudecodeui
# not in nixpkgs, so npx fetches the pinned version on first start
{ hostName, port }:
{ pkgs, config, ... }:

let
  version = "1.37.9";
  # node-pty and better-sqlite3 are compiled for the node that installs them, so install and run with the same one
  nodejs = pkgs.nodejs_22;
in {
  # not used by the service, only decrypted so the login can be looked up
  age.secrets.cloudcli-login.file = ../secrets/cloudcli-login.age;

  systemd.services.cloudcli = {
    description = "cloudcli web UI";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    # agents (claude, codex, git...) launch from here, so give it the same tools a login shell gets
    path = [ nodejs "/run/current-system/sw" "/etc/profiles/per-user/claude" ];
    # localhost only, caddy does the https
    environment.HOST = "127.0.0.1";
    serviceConfig = {
      User = "claude";
      ExecStart = "${nodejs}/bin/npx -y @cloudcli-ai/cloudcli@${version} start --port ${toString port}";
      Restart = "on-failure";
    };
  };

  services.caddy.virtualHosts.${hostName}.extraConfig = "reverse_proxy localhost:${toString port}";
}
