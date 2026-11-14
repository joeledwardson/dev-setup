# agent of empires dashboard at https://aoe-streaming.joels-netflix.com
# the *.joels-netflix.com wildcard record and cert already point here, so this only adds a vhost to caddy.nix's caddy
{ ... }:

let
  hostName = "aoe-streaming.joels-netflix.com";
  # 8080-8082 are taken (mautrix bridges, homepage)
  aoePort = 8083;
in {
  imports = [ (import ../../modules/aoe-dashboard.nix { inherit hostName; port = aoePort; }) ];

  services.caddy.virtualHosts.${hostName}.extraConfig = "reverse_proxy localhost:${toString aoePort}";
}
