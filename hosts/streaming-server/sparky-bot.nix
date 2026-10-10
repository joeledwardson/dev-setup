{ ... }:

# Telegram bot for SparkyFitness MCP
# NOTE: this needs to built with go first or this wont work - this just scaffolds the systemd service
let
  repoDir = "/home/claude/calories-app";
  binary = "${repoDir}/sparky-bot";
  # the bot reads each secret from a file in here (see readSecret in main.go)
  secretsDir = "/home/claude/.sparky-bot";
in {
  # agenix symlinks each secret to where the bot already looks for it
  age.secrets = {
    sparky-bot-telegram-token = {
      file = ../../secrets/sparky-bot-telegram-token.age;
      path = "${secretsDir}/telegram-token";
      owner = "claude";
    };
    sparky-bot-allowed-id = {
      file = ../../secrets/sparky-bot-allowed-id.age;
      path = "${secretsDir}/allowed-id";
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
      ExecStart = binary;
      # same log file as `task bot:logs` reads
      StandardOutput = "append:${secretsDir}/bot.log";
      StandardError = "append:${secretsDir}/bot.log";
      Restart = "on-failure";
      RestartSec = 10;
    };
  };
}
