# codeg web workspace, run as claude, at https://<hostName> (needs tailnet-caddy.nix for the cert)
# trial next to aoe: ACP chat for claude/codex plus HTML/PDF previews beside it
# login: paste the token from `sudo cat /run/agenix/codeg-env`
# env vars from https://docs.codeg.app/getting-started/configuration
{ hostName, port }:
{ pkgs, config, ... }:

let
  codeg = pkgs.callPackage ../pkgs/codeg.nix { };
in {
  # holds CODEG_TOKEN, the web login
  age.secrets.codeg-env.file = ../secrets/codeg-env.age;

  systemd.services.codeg = {
    description = "codeg web workspace";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    # agents launch from here (npx for claude-agent-acp, claude, git...), so give it the same tools a login shell gets
    path = [ "/run/current-system/sw" "/etc/profiles/per-user/claude" ];
    environment = {
      # localhost only, caddy does the https
      CODEG_HOST = "127.0.0.1";
      CODEG_PORT = toString port;
      CODEG_STATIC_DIR = "${codeg}/share/codeg/web";
    };
    serviceConfig = {
      User = "claude";
      ExecStart = "${codeg}/bin/codeg-server";
      EnvironmentFile = config.age.secrets.codeg-env.path;
      Restart = "on-failure";
    };
  };

  services.caddy.virtualHosts.${hostName}.extraConfig = "reverse_proxy localhost:${toString port}";
}
