# ##
### To add a new secret:
### 1. add it to the list at the bottom of this file
### 2. cd into this `secrets` dir and run `agenix -e <SECRET_NAME>.age` to insert its value
### 3. run task secrets:update to re-key all secrets
### 4. add it to the list in ../modules/nixos-secrets.nix and add it to the list of names to be automatically added to each host
let
  # host public keys (from /etc/ssh/ssh_host_ed25519_key.pub on each machine)
  # editing secrets after build is a right faff - juse use `edit-secret` zsh function (from within secrets dir)
  desktop-work = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINOUujKLUo4lCJuepHQ7KGfsy1xQFjkfWNazCq6wTmxy root@desktop-work";

  jollof-home = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP3UaYy3igve5yJdZ+rZpvHairlg94nrIPcDraHkTS6s root@jollof-home";

  degen-work = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA1sMqmmvFD78J7V7UmviGuAz16jhmv8ZC6QAd+gQ2Ey root@degen-work";

  streaming-server = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMUkogBNkR3QnTAxF4zKoCjdp1G0mp1rcD6e9X1H+BtD root@streaming-server";

  degen-home = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEXl8q4NTmgWA0lJax2zg9HbXWFkOzGoOQx15SGA782w root@degen-home";

  degen-bot = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM7SSAY8M48OOXk8KBD50YSHqDzrCB1EEv4mBxR2yCXY root@degen-bot";

  pi-box = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF57D+XGQUT/kBI5fGdpL3fo9SPCfmc4XXk/1NiLiZjI root@pi-box";

  worker207 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII7r/NHO2TiSXW5LHA3S/VQVUmOeNtS2WNdKr6sH7ZO8 root@worker207";

  trustedHosts = [
    desktop-work
    jollof-home
    degen-work
    degen-home
  ];
  allHosts = trustedHosts ++ [
    streaming-server
    degen-bot
    pi-box
    worker207
  ];
in
{
  # gemini LLM API - grabbed from here https://aistudio.google.com/app/api-keys?project=heb7-287610
  "llm-gemini-key.age".publicKeys = allHosts;
  # env file for the litellm proxy - holds these secrets, as KEY=value lines:
  # 1. GEMINI_API_KEY - same value as llm-gemini-key, lets the proxy call Google
  # 2. LITELLM_MASTER_KEY - the key clients must send to use the proxy at all.
  #    make one with `openssl rand -hex 24` and put sk- on the front
  # 3. OPENROUTER_API_KEY - lets the proxy call hosted models (qwen3-coder).
  #    grab from https://openrouter.ai/keys (prepaid credits, one key = many models)
  "litellm-env.age".publicKeys = allHosts;
  # hermes-agent env file - MUST be KEY=value lines (systemd EnvironmentFile syntax),
  "hermes-env.age".publicKeys = allHosts;
  # my access token for `ntfy.sh` - grabbed from here https://ntfy.sh/account
  "ntfy-token.age".publicKeys = allHosts;

  # ENV file for sparkyfitness secrets deployment
  "sparkyfitness-secrets.age".publicKeys = allHosts;

  # plain text file for sparkyfitness related secrets
  "sparkyfitness-manual.age".publicKeys = allHosts;

  # matrix registration secret key - just a generated random string
  "matrix-registration.age".publicKeys = allHosts;
  # telegram app secrets
  # 1. telegram app must be created via https://my.telegram.org/apps
  # 2. review docs of nixos - secret file MUST match the env specification in services.mautrix-telegram.environmentFile
  # 3. currently the format is `MAUTRIX_TELEGRAM_TELEGRAM_API_ID` and `MAUTRIX_TELEGRAM_TELEGRAM_API_HASH` keys
  "mautrix-telegram-env.age".publicKeys = allHosts;

  # 1. matrix-doublepuppet.age = the doublepuppet.yaml appservice registration (as_token + hs_token).
  # 2. matrix-doublepuppet-env.age = DOUBLEPUPPET_AS_TOKEN=<same as_token> for the Go bridges.
  #    (Telegram's token goes in mautrix-telegram-env.age as LOGIN_SHARED_SECRET_MAP instead.)
  "matrix-doublepuppet.age".publicKeys = allHosts;
  "matrix-doublepuppet-env.age".publicKeys = allHosts;

  # nixflix media server secrets
  # 1. the following are randomly generated keys for seeding
  "nixflix-sonarr-apikey.age".publicKeys = allHosts;
  "nixflix-sonarr-password.age".publicKeys = allHosts;
  "nixflix-radarr-apikey.age".publicKeys = allHosts;
  "nixflix-radarr-password.age".publicKeys = allHosts;
  "nixflix-lidarr-apikey.age".publicKeys = allHosts;
  "nixflix-lidarr-password.age".publicKeys = allHosts;
  "nixflix-prowlarr-apikey.age".publicKeys = allHosts;
  "nixflix-prowlarr-password.age".publicKeys = allHosts;
  "nixflix-jellyfin-apikey.age".publicKeys = allHosts;
  "nixflix-jellyfin-admin-password.age".publicKeys = allHosts;
  "nixflix-seerr-apikey.age".publicKeys = allHosts;
  "nixflix-sabnzbd-apikey.age".publicKeys = allHosts;
  "nixflix-sabnzbd-nzbkey.age".publicKeys = allHosts;
  "nixflix-sabnzbd-username.age".publicKeys = allHosts;
  "nixflix-sabnzbd-password.age".publicKeys = allHosts;

  # 2. the following are real credentials from external services
  "nixflix-usenet-eweka-username.age".publicKeys = allHosts;
  "nixflix-usenet-eweka-password.age".publicKeys = allHosts;
  "nixflix-indexer-nzbgeek.age".publicKeys = allHosts;
  # TODO(vpn): "nixflix-wireguard-conf.age".publicKeys = allHosts;
}
