# agent of empires dashboard at https://worker-aoe.joels-netflix.com
# plus html pages agents write to /srv/pages, at https://worker-pages.joels-netflix.com
# plus codeg (trial, alongside aoe) at https://worker-codeg.joels-netflix.com
# plus openhands agent canvas (trial) at https://worker-canvas.joels-netflix.com
# plus paseo (trial) at https://worker-paseo.joels-netflix.com and cloudcli (trial) at https://worker-cloudcli.joels-netflix.com
# this box points its own DNS records at itself and gets its own certs, so nothing here depends on streaming-server
{ ... }:

let
  aoeHostName = "worker-aoe.joels-netflix.com";
  pagesHostName = "worker-pages.joels-netflix.com";
  codegHostName = "worker-codeg.joels-netflix.com";
  canvasHostName = "worker-canvas.joels-netflix.com";
  paseoHostName = "worker-paseo.joels-netflix.com";
  cloudcliHostName = "worker-cloudcli.joels-netflix.com";
  trajectoryHostName = "worker-trajectory.joels-netflix.com";
in {
  imports = [
    (import ../../modules/tailnet-caddy.nix { selfDnsNames = [ aoeHostName pagesHostName codegHostName canvasHostName paseoHostName cloudcliHostName trajectoryHostName ]; })
    (import ../../modules/aoe-dashboard.nix { hostName = aoeHostName; port = 8080; })
    (import ../../modules/pages.nix { hostName = pagesHostName; })
    # port from 9000 + crc32("codeg") % 900
    (import ../../modules/codeg.nix { hostName = codegHostName; port = 9788; })
    # port from 9000 + crc32("agent-canvas") % 900
    (import ../../modules/agent-canvas.nix { hostName = canvasHostName; port = 9056; })
    # port from 9000 + crc32("paseo") % 900
    (import ../../modules/paseo.nix { hostName = paseoHostName; port = 9810; })
    # port from 9000 + crc32("cloudcli") % 900
    (import ../../modules/cloudcli.nix { hostName = cloudcliHostName; port = 9378; })
  ];
}
