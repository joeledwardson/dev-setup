# ##
### To add a new secret:
### 1. add it to the list at the bottom of this file
### 2. cd into this `secrets` dir and run `agenix -e <SECRET_NAME>.age` to insert its value
### 3. run task secrets:update to re-key all secrets
### 4. add it to the list in ../modules/nixos-secrets.nix and add it to the list of names to be automatically added to each host
let
  inherit (import ./host-keys.nix) trustedKeys allKeys;
in
{
  # NOTE: these universal token + key must be be one-off grabbed from beszel dashboard, not possible to scaffold with nixos 😠
  "beszel-agent-env.age".publicKeys = allKeys;
  # gemini LLM API - grabbed from here https://aistudio.google.com/app/api-keys?project=heb7-287610
  "llm-gemini-key.age".publicKeys = allKeys;
  # env file for the litellm proxy - holds these secrets, as KEY=value lines:
  # 1. GEMINI_API_KEY - same value as llm-gemini-key, lets the proxy call Google
  # 2. LITELLM_MASTER_KEY - the key clients must send to use the proxy at all.
  #    make one with `openssl rand -hex 24` and put sk- on the front
  # 3. OPENROUTER_API_KEY - lets the proxy call hosted models (qwen3-coder).
  #    grab from https://openrouter.ai/keys (prepaid credits, one key = many models)
  "litellm-env.age".publicKeys = allKeys;
  # hermes-agent env file - MUST be KEY=value lines (systemd EnvironmentFile syntax),
  "hermes-env.age".publicKeys = allKeys;
  # my access token for `ntfy.sh` - grabbed from here https://ntfy.sh/account
  "ntfy-token.age".publicKeys = allKeys;

  # ENV file for sparkyfitness secrets deployment
  "sparkyfitness-secrets.age".publicKeys = allKeys;

  # gatus env file, KEY=value lines (systemd EnvironmentFile syntax):
  # 1. TELEGRAM_BOT_TOKEN - from @BotFather on telegram, /newbot
  # 2. TELEGRAM_CHAT_ID - message the bot, then read message.chat.id from https://api.telegram.org/bot<TOKEN>/getUpdates
  # 3. GATUS_BACKUP_TOKEN - `openssl rand -hex 24`, pi-box sends it with backup results
  "gatus-env.age".publicKeys = allKeys;

  # plain text file for sparkyfitness related secrets
  "sparkyfitness-manual.age".publicKeys = allKeys;

  # matrix registration secret key - just a generated random string
  "matrix-registration.age".publicKeys = allKeys;

  # telegram secrets - API ID + hash (from app) and "shared secret" (must match `as_token` from doublepuppet)
  # NOTE: telegram app must be created via https://my.telegram.org/apps
  "mautrix-telegram-env.age".publicKeys = allKeys;

  # the doublepuppet.yaml appservice registration (as_token + hs_token).
  "matrix-doublepuppet.age".publicKeys = allKeys;
  # DOUBLEPUPPET_AS_TOKEN=<same as_token> for the Go bridges.
  "matrix-doublepuppet-env.age".publicKeys = allKeys;

  # imessage bridge on macos, configured for bluebubbles (use same password as mac app) and dest => streaming-server
  # NOTE: if synapse host URL changes, must be changed in this file
  "mautrix-imessage-config.age".publicKeys = allKeys;
  # The registration URL points back to the Mac bridge, not the homeserver.
  "mautrix-imessage-registration.age".publicKeys = allKeys;

  # sandbox machine credentials (joels-claude-bot accounts)
  # tailscale auth key, tagged tag:sandbox - expires 2026-12-02
  "sandbox-tailscale-authkey.age".publicKeys = allKeys;
  # github classic API token for joels-claude-bot
  "sandbox-github-token.age".publicKeys = allKeys;
  # gitlab API (all access) token for joels-claude-bot - expires 21-05-2027
  "sandbox-gitlab-token.age".publicKeys = allKeys;

  # nixflix media server secrets (randomly generated keys for seeding)
  "nixflix-sonarr-apikey.age".publicKeys = allKeys;
  "nixflix-sonarr-password.age".publicKeys = allKeys;
  "nixflix-radarr-apikey.age".publicKeys = allKeys;
  "nixflix-radarr-password.age".publicKeys = allKeys;
  "nixflix-lidarr-apikey.age".publicKeys = allKeys;
  "nixflix-lidarr-password.age".publicKeys = allKeys;
  "nixflix-prowlarr-apikey.age".publicKeys = allKeys;
  "nixflix-prowlarr-password.age".publicKeys = allKeys;
  "nixflix-jellyfin-apikey.age".publicKeys = allKeys;
  "nixflix-jellyfin-admin-password.age".publicKeys = allKeys;
  "nixflix-seerr-apikey.age".publicKeys = allKeys;
  "nixflix-sabnzbd-apikey.age".publicKeys = allKeys;
  "nixflix-sabnzbd-nzbkey.age".publicKeys = allKeys;
  "nixflix-sabnzbd-username.age".publicKeys = allKeys;
  "nixflix-sabnzbd-password.age".publicKeys = allKeys;

  # nixflix media server secrets (real credentials from external services)
  "nixflix-usenet-eweka-username.age".publicKeys = allKeys;
  "nixflix-usenet-eweka-password.age".publicKeys = allKeys;
  "nixflix-indexer-nzbgeek.age".publicKeys = allKeys;

  # cloudflare token for caddy on streaming-server (DNS challenge)
  "caddy-cloudflare-env.age".publicKeys = allKeys;

  # client ID and secret for gcalcli, on my personal google account
  # Createdvia the GCP clients portal https://console.cloud.google.com/auth/clients
  # needs my personal email adding as "test user" in audience: https://console.cloud.google.com/auth/audience
  "gcal-client-id.age".publicKeys = trustedKeys;
  "gcal-client-secret.age".publicKeys = trustedKeys;

}
