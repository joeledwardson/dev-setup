{ pkgs-unstable, ... }:

{
  services.immich = {
    enable = true;

    # use latest package
    package = pkgs-unstable.immich;

    mediaLocation = "/mnt/big-hdd/immich";

    # the n100 igpu, for the machine-learning pass over the library.
    accelerationDevices = [ "/dev/dri/renderD128" ];
  };

  # accelerationDevices only permits the device through the cgroup.
  users.users.immich.extraGroups = [ "render" ];

  # the module's own tmpfiles rule is an "e" entry, so it adjusts a directory that
  # already exists rather than creating one.
  systemd.tmpfiles.settings.immich-media."/mnt/big-hdd/immich".d = {
    user = "immich";
    group = "immich";
    mode = "0700";
  };

  # annoying, but dont want it to start writing GB of photos and blow up HDD if drive not mounted
  systemd.services.immich-server.unitConfig.RequiresMountsFor = [ "/mnt/big-hdd" ];
}
