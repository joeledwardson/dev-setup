# HTML pages at https://worker-pages.joels-netflix.com
# Paseo at https://worker-paseo.joels-netflix.com
# Trajectory at https://worker-trajectory.joels-netflix.com
# RunWisp at https://worker-wisp.joels-netflix.com
# this box points its own DNS records at itself and gets its own certs, so nothing here depends on streaming-server
{ ... }:

let
  pagesHostName = "worker-pages.joels-netflix.com";
  paseoHostName = "worker-paseo.joels-netflix.com";
  trajectoryHostName = "worker-trajectory.joels-netflix.com";
  wispHostName = "worker-wisp.joels-netflix.com";
in {
  imports = [
    (import ../../modules/tailnet-caddy.nix { selfDnsNames = [ pagesHostName paseoHostName trajectoryHostName wispHostName ]; })
    (import ../../modules/pages.nix { hostName = pagesHostName; })
    # port from 9000 + crc32("paseo") % 900
    (import ../../modules/paseo.nix { hostName = paseoHostName; port = 9810; user = "claude"; })
    (import ../../modules/runwisp.nix { hostName = wispHostName; port = 9477; user = "claude"; })
  ];
}
