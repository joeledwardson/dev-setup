{ lib, pkgs-unstable, ... }:

{
  services.immich = {
    enable = true;

    # use latest package
    package = pkgs-unstable.immich;

    mediaLocation = "/mnt/big-hdd/immich";

    settings.storageTemplate = {
      enabled = true;
      template = "{{y}}/{{y}}-{{MM}}-{{dd}}/{{filename}}";
    };

    # the n100 igpu, for the machine-learning pass over the library.
    accelerationDevices = [ "/dev/dri/renderD128" ];
  };

  # accelerationDevices only permits the device through the cgroup.
  users.users.immich.extraGroups = [ "render" ];

  # Immich owns the media directory. Members of the immich group can read it.
  systemd.tmpfiles.settings.immich-media."/mnt/big-hdd/immich".d = {
    user = "immich";
    group = "immich";
    mode = "0750";
  };

  # Override the Immich module's owner-only mode for this directory.
  systemd.tmpfiles.settings.immich."/mnt/big-hdd/immich".e.mode = lib.mkForce "0750";

  # New directories are 0750 and new files are 0640, so the immich group can
  # read them while only the immich user can modify them.
  systemd.services.immich-server.serviceConfig.UMask = lib.mkForce "0027";

  # annoying, but dont want it to start writing GB of photos and blow up HDD if drive not mounted
  systemd.services.immich-server.unitConfig.RequiresMountsFor = [ "/mnt/big-hdd" ];
}
