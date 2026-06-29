{
  services.netbird.clients.wt0 = {
    port = 51821;

    # GUI tray app — gives you Mullvad-like connect/disconnect buttons
    ui.enable = true;

    openFirewall = true;
    openInternalFirewall = true;

    # Daemon still runs at boot (so the tray can connect/disconnect), but it
    # won't connect automatically. This writes `DisableAutoConnect = true` into
    # config.json on every start, overriding any stored auto-connect state.
    # (The `login` block only automates setup-key login — it never controlled
    # daemon auto-connect, which is why removing it had no effect.)
    autoStart = false;
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
