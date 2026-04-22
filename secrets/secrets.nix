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

  trustedHosts = [ desktop-work jollof-home degen-work ];
  allHosts = trustedHosts ++ [ streaming-server ];
in {
  "llm-gemini-key.age".publicKeys = trustedHosts;
  "ntfy-token.age".publicKeys = allHosts;
}
