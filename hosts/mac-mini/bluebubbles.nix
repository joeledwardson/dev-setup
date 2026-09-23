{ config, lib, pkgs, ... }:

let
  user = config.system.primaryUser;
  cfg = config.local.bluebubbles;
in
{
  options.local.bluebubbles.startAtLogin = lib.mkEnableOption
    "BlueBubbles startup after configuring app permissions, password and Private API";

  config = {
    environment.systemPackages = [
      (pkgs.callPackage ../../pkgs/bluebubbles.nix { })
    ];

    # Install now, opt into startup after permissions, password, Private API
    # and network access have been configured. Never change SIP via activation.
    launchd.user.agents.bluebubbles = lib.mkIf cfg.startAtLogin {
      serviceConfig = {
        ProgramArguments = [
          "/Applications/Nix Apps/BlueBubbles.app/Contents/MacOS/BlueBubbles"
        ];
        LimitLoadToSessionType = "Aqua";
        RunAtLoad = true;
        KeepAlive = true;
        ThrottleInterval = 10;
        StandardOutPath = "/Users/${user}/Library/Logs/bluebubbles/stdout.log";
        StandardErrorPath = "/Users/${user}/Library/Logs/bluebubbles/stderr.log";
        EnvironmentVariables.HOME = "/Users/${user}";
      };
    };

    system.activationScripts.postActivation.text = lib.mkAfter ''
      install -d -m 700 -o ${user} -g staff \
        /Users/${user}/Library/Logs/bluebubbles
    '';
  };
}
