let
  # host public keys (from /etc/ssh/ssh_host_ed25519_key.pub on each machine)
  desktop-work =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINOUujKLUo4lCJuepHQ7KGfsy1xQFjkfWNazCq6wTmxy root@desktop-work";

  jollof-home =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP3UaYy3igve5yJdZ+rZpvHairlg94nrIPcDraHkTS6s root@jollof-home";

  # group all hosts that should access all secrets
  allHosts = [ desktop-work jollof-home ];
in { "llm-gemini-key.age".publicKeys = allHosts; }
