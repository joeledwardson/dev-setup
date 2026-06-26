# ##
### To add a new secret:
### 1. add it to the list at the bottom of this file
### 2. cd into this `secrets` dir and run `agenix -e <SECRET_NAME>.age` to insert its value
### 3. run task secrets:update to re-key all secrets
### 4. add it to the list in ../modules/nixos-secrets.nix and add it to the list of names to be automatically added to each host
let
  # host public keys (from /etc/ssh/ssh_host_ed25519_key.pub on each machine)
  # editing secrets after build is a right faff - juse use `edit-secret` zsh function (from within secrets dir)
  desktop-work =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINOUujKLUo4lCJuepHQ7KGfsy1xQFjkfWNazCq6wTmxy root@desktop-work";

  jollof-home =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP3UaYy3igve5yJdZ+rZpvHairlg94nrIPcDraHkTS6s root@jollof-home";

  degen-work =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMBqhsbwRCHSyhBKOlXh11A9F+hyUXlA6gPBSwoBUbiI root@degen-work";

  streaming-server =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMUkogBNkR3QnTAxF4zKoCjdp1G0mp1rcD6e9X1H+BtD root@streaming-server";

  degen-home =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEXl8q4NTmgWA0lJax2zg9HbXWFkOzGoOQx15SGA782w root@degen-home";

  degen-bot =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM7SSAY8M48OOXk8KBD50YSHqDzrCB1EEv4mBxR2yCXY root@degen-bot";

  pi-box =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF57D+XGQUT/kBI5fGdpL3fo9SPCfmc4XXk/1NiLiZjI root@pi-box";

  trustedHosts = [ desktop-work jollof-home degen-work degen-home ];
  allHosts = trustedHosts ++ [ streaming-server degen-bot pi-box ];
in {
  # gemini LLM API - grabbed from here https://aistudio.google.com/app/api-keys?project=heb7-287610
  "llm-gemini-key.age".publicKeys = allHosts;
  # my access token for `ntfy.sh` - grabbed from here https://ntfy.sh/account
  "ntfy-token.age".publicKeys = allHosts;
  # USDA food central API key - grabbed from here https://fdc.nal.usda.gov/api-key-signup/
  "usda.age".publicKeys = allHosts;

  "fatsecret-client-id.age".publicKeys = allHosts;
  "fatsecret-client-secret.age".publicKeys = allHosts;
  "sparkyfitness-secrets.age".publicKeys = allHosts;

  # matrix registration secret key - just a generated random string
  "matrix-registration.age".publicKeys = allHosts;
  # telegram app secrets
  # 1. telegram app must be created via https://my.telegram.org/apps
  # 2. review docs of nixos - secret file MUST match the env specification in services.mautrix-telegram.environmentFile
  # 3. currently the format is `MAUTRIX_TELEGRAM_TELEGRAM_API_ID` and `MAUTRIX_TELEGRAM_TELEGRAM_API_HASH` keys
  "mautrix-telegram-env.age".publicKeys = allHosts;
}
