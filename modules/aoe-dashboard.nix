# agent of empires dashboard, run as claude. the host puts https in front of it (caddy -> localhost:port)
# login: open the URL from `aoe serve --status` once, the token then becomes a cookie
{ hostName, port }:
{ pkgs, pkgs-unstable, ... }:

let
  aoe = pkgs.callPackage ../pkgs/aoe.nix { };
in {
  environment.systemPackages = [
    aoe
    pkgs-unstable.claude-agent-acp # lets aoe's structured view drive claude
  ];

  # localhost only. --behind-proxy marks cookies Secure and trusts caddy's X-Forwarded-* headers
  systemd.services.aoe = {
    description = "agent of empires dashboard";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    # agents (claude, claude-agent-acp, git...) launch from here, so give it the same tools a login shell gets
    path = [ "/run/current-system/sw" "/etc/profiles/per-user/claude" ];
    serviceConfig = {
      # unit settings from https://www.agent-of-empires.com/guides/web-dashboard/
      Type = "notify";
      User = "claude";
      ExecStart = "${aoe}/bin/aoe serve --host 127.0.0.1 --port ${toString port} --behind-proxy --allowed-host ${hostName}";
      Restart = "on-failure";
      # agent tmux sessions survive a restart of the dashboard
      KillMode = "process";
    };
  };
}
