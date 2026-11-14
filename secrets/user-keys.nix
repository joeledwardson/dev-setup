# public ssh keys of the login user on each machine (~/.ssh/id_ed25519.pub)
rec {
  trustedUsers = {
    joel-desktop-work = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAIm7/77CZ8q2Z2sJWfVsq4eHw8hl4NIrKoQuO/yZu1i JOLLOF-MINTY-TANK";
    jollof-home = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHr7NSDwOlroPwUmg8ybDLhFkMCaRBadhRU6RycfA9bD jollof@jollof-home";
    degen-work = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPjI2wsG7L8Qombz/26A8Ep+63Tf2Z6ojksByP2TzXfk jollof@degen-work";
    degen-home = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILIQKcFkU6/dc1+vQ6NqqWqVMLVSKTJLJhX/3d3fO+Di jollof@degen-home";
    # joels-mac-mini: jollof has no keypair
  };

  sandboxUsers = {
    streaming-server = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJPES2xNIK4PmEmJueDngkuDkpcb62P4c2ZTQSfuvKur claude@streaming-server";
    pi-box = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGhsvk7qq3t8CjBCqvzb9QaQsuHo4Rsm+w6P3P0V2LiF claude@pi-box";
    worker207 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGuqpUMI0yT0jLtuDz4lbyqtmVbMkq9IK6RqaUlQRWhZ claude@worker207";
    # degen-bot: not collected yet (unreachable)
  };

  # mirrors tailscale/acl.hujson: trusted -> anywhere, sandbox -> sandbox only
  trustedKeys = builtins.attrValues trustedUsers;
  allKeys = builtins.attrValues (trustedUsers // sandboxUsers);
}
