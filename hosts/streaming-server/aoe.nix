# agent of empires dashboard at https://streaming-aoe.joels-netflix.com
# plus html pages agents write to /srv/pages, at https://streaming-pages.joels-netflix.com
# the *.joels-netflix.com wildcard record and cert already point here, so these only add vhosts to caddy.nix's caddy
{ ... }:

{
  imports = [
    # 8080-8082 are taken (mautrix bridges, homepage)
    (import ../../modules/aoe-dashboard.nix { hostName = "streaming-aoe.joels-netflix.com"; port = 8083; })
    (import ../../modules/pages.nix { hostName = "streaming-pages.joels-netflix.com"; })
  ];
}
