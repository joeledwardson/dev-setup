# Shared public host-key inventory for agenix recipients and SSH access.
# These are public keys only; private host keys stay on their owning machines.
rec {
  # host public keys (from /etc/ssh/ssh_host_ed25519_key.pub on each machine)
  desktop-work = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINOUujKLUo4lCJuepHQ7KGfsy1xQFjkfWNazCq6wTmxy root@desktop-work";

  jollof-home = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP3UaYy3igve5yJdZ+rZpvHairlg94nrIPcDraHkTS6s root@jollof-home";

  degen-work = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA1sMqmmvFD78J7V7UmviGuAz16jhmv8ZC6QAd+gQ2Ey root@degen-work";

  streaming-server = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMUkogBNkR3QnTAxF4zKoCjdp1G0mp1rcD6e9X1H+BtD root@streaming-server";

  degen-home = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEXl8q4NTmgWA0lJax2zg9HbXWFkOzGoOQx15SGA782w root@degen-home";

  degen-bot = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM7SSAY8M48OOXk8KBD50YSHqDzrCB1EEv4mBxR2yCXY root@degen-bot";

  pi-box = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF57D+XGQUT/kBI5fGdpL3fo9SPCfmc4XXk/1NiLiZjI root@pi-box";

  worker207 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII7r/NHO2TiSXW5LHA3S/VQVUmOeNtS2WNdKr6sH7ZO8 root@worker207";

  mac-mini = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOjWfjNa/8vfdLCJTnnaYnaLxOlJfLyu4PEk0VzQApQj";

  # Personal devices allowed to decrypt the Google Calendar credentials.
  trustedHosts = [
    desktop-work
    jollof-home
    degen-work
    degen-home
    mac-mini
  ];
  # Every managed device, including the personal devices above.
  # Used for shared secrets and fallback SSH login to sandbox machines.
  allHosts = [
    desktop-work
    jollof-home
    degen-work
    degen-home
    mac-mini
    streaming-server
    degen-bot
    pi-box
    worker207
  ];
}
