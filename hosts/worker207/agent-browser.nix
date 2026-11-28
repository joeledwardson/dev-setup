# Persistent hidden Brave instance for agent browser automation.
{ pkgs, ... }:

let
  script = ../../applications/agent-browser/agent-browser;
in {
  systemd.user.services.agent-browser = {
    description = "Persistent hidden browser for agent automation";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];

    # The script starts Brave in the background and exits, so keep the unit
    # active and stop the whole browser cgroup with it.
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      KillMode = "control-group";
      TimeoutStartSec = "60s";
      ExecStart = "${pkgs.bash}/bin/bash ${script} start";
      ExecStop = "${pkgs.bash}/bin/bash ${script} stop";
    };

    # Brave, curl, jq, pgrep, hyprctl and the other lifecycle tools come from
    # the system profile on worker207.
    path = [ "/run/current-system/sw" ];
  };

  # Visibility only, no browser lifecycle: these units run to completion and
  # stay inactive, so `systemctl --user start` works every time (unlike the main
  # unit, a oneshot with RemainAfterExit). Both verbs are idempotent.
  #
  #   systemctl --user start agent-browser-show    # bring into view
  #   systemctl --user start agent-browser-hide    # put away
  systemd.user.services.agent-browser-show = {
    description = "Reveal the agent-browser special workspace";
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash ${script} reveal";
    };
    path = [ "/run/current-system/sw" ];
  };

  systemd.user.services.agent-browser-hide = {
    description = "Hide the agent-browser special workspace";
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash ${script} conceal";
    };
    path = [ "/run/current-system/sw" ];
  };
}
