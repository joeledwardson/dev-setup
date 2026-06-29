{
  services.netbird.clients.wt0 = {
    port = 51821;

    # GUI tray app — gives you Mullvad-like connect/disconnect buttons
    ui.enable = true;

    openFirewall = true;
    openInternalFirewall = true;

    # NO `login` block — that's what forces auto-connect on boot.
  };

  # system tray service to run the netbird binary 
  systemd.user.services.netbird-tray = {
    description = "NetBird tray UI";
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "/run/current-system/sw/bin/netbird-ui-wt0";
      Restart = "on-failure";
      RestartSec = 3;
    };
  };

}
