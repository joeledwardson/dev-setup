# HTML pages agents write to /srv/pages, at https://streaming-pages.joels-netflix.com
# the *.joels-netflix.com wildcard record and cert already point here, so these only add vhosts to caddy.nix's caddy
{ ... }:

{
  imports = [
    (import ../../modules/pages.nix { hostName = "streaming-pages.joels-netflix.com"; })
  ];
}
