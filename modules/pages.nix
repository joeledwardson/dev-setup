# self-contained html pages agents write to /srv/pages, served by caddy at https://<hostName>
# `browse` makes caddy list the folder when there's no index.html (https://caddyserver.com/docs/caddyfile/directives/file_server)
# needs tailnet-caddy.nix for the cert. no login, so anything put here is readable by whoever can reach 443
{ hostName }:
{ ... }:

{
  # outside /home because home is 0700 and caddy can't read it
  systemd.tmpfiles.rules = [ "d /srv/pages 0755 claude users -" ];

  services.caddy.virtualHosts.${hostName}.extraConfig = ''
    root * /srv/pages
    file_server browse
  '';

  # claude.md reads this to build the link it hands back, so each box links to its own pages
  environment.variables.PAGES_URL = "https://${hostName}";
}
