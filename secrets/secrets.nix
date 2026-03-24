let
  # host public keys (from /etc/ssh/ssh_host_ed25519_key.pub on each machine)
  desktop-work =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINOUujKLUo4lCJuepHQ7KGfsy1xQFjkfWNazCq6wTmxy root@desktop-work";

  # add more hosts here as needed, e.g.
  # degen-home = "ssh-ed25519 AAAA... root@degen-home";

  # group all hosts that should access all secrets
  allHosts = [ desktop-work ];
in { "llm-gemini-key.age".publicKeys = [ desktop-work ]; }
