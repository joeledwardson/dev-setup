# Local coding-agent session viewer at https://worker-trajectory.joels-netflix.com/viewer/
{ pkgs, lib, ... }:

let
  trajectory = pkgs.callPackage ../../pkgs/trajectory.nix { };
  hostName = "worker-trajectory.joels-netflix.com";
  port = 8888;
  user = "claude";
  home = "/home/${user}";

  # `trajectory setup` is the supported way to install each agent's capture
  # integration: the Claude Code plugin marketplace, the Codex hook plugin and
  # MCP entry, and the OpenCode plugin. It is idempotent, so run it on every
  # boot instead of checking in all the files it generates.
  clients = [ "cc" "codex" "opencode" ];

  setup = pkgs.writeShellScript "trajectory-client-setup" ''
    set -eu
    export HOME=${home}

    ${trajectory}/bin/trajectory setup \
      --clients ${lib.concatStringsSep "," clients} \
      --non-interactive --no-client-shims --quiet

    # Setup resolves the binary and plugin to absolute paths and stores them
    # in opencode.json, which dotbot symlinks into this repo. Put the stable
    # equivalents back so a rebuild does not leave the checkout dirty.
    json=${home}/.config/opencode/opencode.json
    if [ -f "$json" ]; then
      ${pkgs.jq}/bin/jq '
        .mcp.trajectory.command = ["trajectory", "mcp"]
        | .mcp.trajectory.enabled = true
        | .mcp.trajectory.type = "local"
        | del(.mcp.trajectory.environment)
        | .plugin = ["~/.config/opencode/plugins/trajectory"]
      ' "$json" > "$json.tmp"
      # Write through the dotbot symlink instead of replacing it with a file.
      cat "$json.tmp" > "$json"
      rm -f "$json.tmp"
    fi
  '';
in {
  environment.systemPackages = [ trajectory ];

  # The viewer only binds to loopback. Keep it ready for the homepage link.
  systemd.services.trajectory-local-ui = {
    description = "Trajectory local session viewer";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      User = user;
      ExecStart = "${trajectory}/bin/trajectory local-ui --port ${toString port} --no-open";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  # Wire Claude Code, Codex and OpenCode to Trajectory. The agents start
  # `trajectory serve` themselves when a session begins, so this only has to
  # refresh the integrations after a rebuild replaces the Nix store path.
  systemd.services.trajectory-client-setup = {
    description = "Install Trajectory capture integrations for coding agents";
    wantedBy = [ "multi-user.target" ];
    before = [ "paseo.service" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    path = [
      trajectory
      pkgs.jq
      pkgs.nodejs_22
      "/run/current-system/sw"
    ];
    serviceConfig = {
      Type = "oneshot";
      User = user;
      RemainAfterExit = true;
      ExecStart = setup;
    };
  };

  # Trajectory accepts only localhost Host and Origin headers. Caddy supplies
  # those after limiting access to tailnet peers.
  services.caddy.virtualHosts.${hostName}.extraConfig = ''
    @tailnet remote_ip 100.64.0.0/10 fd7a:115c:a1e0::/48
    handle @tailnet {
      redir / /viewer/ 302
      reverse_proxy 127.0.0.1:${toString port} {
        header_up Host localhost:${toString port}
        header_up Origin http://localhost:${toString port}
      }
    }
    handle {
      respond 403
    }
  '';
}
