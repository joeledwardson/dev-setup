# paseo daemon and its web UI, run as <user>, at https://<hostName> via caddy (needs tailnet-caddy.nix for the cert)
# without caddy enabled the vhost is inert: use hostName "localhost" and open http://localhost:<port>
# login: add a direct connection to the web UI's own URL, password from `sudo cat /run/agenix/paseo-env`
# runs the daemon the same way paseo's docker image does: https://github.com/getpaseo/paseo/blob/main/docs/docker.md
# not in nixpkgs, and the server package has no bin for npx, so npm installs the pinned version into /var/lib/paseo
{ hostName, port, user }:
{ pkgs, config, ... }:

let
  version = "0.17.4";
  # node-pty is compiled for the node that installs it, so install and run with the same one
  nodejs = pkgs.nodejs_22;
in {
  # holds PASEO_PASSWORD, needed by every web, phone or CLI client
  age.secrets.paseo-env.file = ../secrets/paseo-env.age;

  systemd.services.paseo = {
    description = "paseo daemon and web UI";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    # agents (claude, codex, git...) launch from here, so give it the same tools a login shell gets
    path = [ nodejs "/run/current-system/sw" "/etc/profiles/per-user/${user}" ];
    environment = {
      # localhost only, caddy does the https
      PASEO_LISTEN = "127.0.0.1:${toString port}";
      PASEO_WEB_UI_ENABLED = "true";
      # the daemon answers 403 "Invalid Host header" to any hostname not listed here
      PASEO_HOSTNAMES = hostName;
    };
    serviceConfig = {
      User = user;
      StateDirectory = "paseo";
      # quick no-op once this version is installed
      ExecStartPre = "${nodejs}/bin/npm install --no-fund --no-audit --prefix /var/lib/paseo @getpaseo/cli@${version}";
      ExecStart = "${nodejs}/bin/node /var/lib/paseo/node_modules/@getpaseo/server/dist/scripts/supervisor-entrypoint.js";
      EnvironmentFile = config.age.secrets.paseo-env.path;
      Restart = "on-failure";
    };
  };

  services.caddy.virtualHosts.${hostName}.extraConfig = "reverse_proxy localhost:${toString port}";
}
