# agent of empires dashboard at https://worker-aoe.joels-netflix.com
# plus html pages agents write to /srv/pages, at https://worker-pages.joels-netflix.com
# plus codeg (trial, alongside aoe) at https://worker-codeg.joels-netflix.com
# this box points its own DNS records at itself and gets its own certs, so nothing here depends on streaming-server
{ ... }:

let
  aoeHostName = "worker-aoe.joels-netflix.com";
  pagesHostName = "worker-pages.joels-netflix.com";
  codegHostName = "worker-codeg.joels-netflix.com";
in {
  imports = [
    (import ../../modules/tailnet-caddy.nix { selfDnsNames = [ aoeHostName pagesHostName codegHostName ]; })
    (import ../../modules/aoe-dashboard.nix { hostName = aoeHostName; port = 8080; })
    (import ../../modules/pages.nix { hostName = pagesHostName; })
    # port from 9000 + crc32("codeg") % 900
    (import ../../modules/codeg.nix { hostName = codegHostName; port = 9788; })
  ];
}
