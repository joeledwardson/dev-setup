{ config, pkgs, ... }:

# Telegram bot for SparkyFitness MCP
# NOTE: this needs to built with go first or this wont work - this just scaffolds the systemd service
let
  repoDir = "/home/claude/calories-app";
  binary = "${repoDir}/sparky-bot";
  secrets = config.age.secrets;

  # the bot only reads env vars - this turns the agenix secret files into env vars at launch
  launcher = pkgs.writeShellScript "sparky-bot-launch" ''
    export TELEGRAM_TOKEN="$(cat ${secrets.sparky-bot-telegram-token.path})"
    export ALLOWED_ID="$(cat ${secrets.sparky-bot-allowed-id.path})"
    export SF_API_KEY="$(cat ${secrets.sparkyfitness-api-key.path})"
    export OLLAMA_API_KEY="$(cat ${secrets.ollama-api-key.path})"
    exec ${binary}
  '';
in {
  # sparkyfitness-api-key + ollama-api-key come from modules/nixos-secrets.nix
  age.secrets = {
    sparky-bot-telegram-token = {
      file = ../../secrets/sparky-bot-telegram-token.age;
      owner = "claude";
    };
    sparky-bot-allowed-id = {
      file = ../../secrets/sparky-bot-allowed-id.age;
      owner = "claude";
    };
  };

  systemd.services.sparky-bot = {
    description = "SparkyFitness Telegram bot";
    after = [ "network-online.target" "sparkyfitness.service" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    # skipped (not failed) until the binary has been built, so a fresh machine still switches cleanly
    unitConfig.ConditionPathExists = binary;

    serviceConfig = {
      User = "claude";
      WorkingDirectory = repoDir;
      ExecStart = launcher;
      Restart = "on-failure";
      RestartSec = 10;
    };
  };
}
