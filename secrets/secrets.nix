let
  # host public keys (from /etc/ssh/ssh_host_ed25519_key.pub on each machine)
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
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICilkEBxxHmJo/7B0oVZEQh1vFCz3we1G0tgdh3ivJgM root@nixos";

  trustedHosts = [ desktop-work jollof-home degen-work degen-home ];
  allHosts = trustedHosts ++ [ streaming-server degen-bot pi-box ];
in {
  "llm-gemini-key.age".publicKeys = allHosts;
  "ntfy-token.age".publicKeys = allHosts;
}
