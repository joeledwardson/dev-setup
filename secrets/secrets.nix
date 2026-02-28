let
  # TODO: replace with actual key from:
  #   ssh streaming-server "cat /etc/ssh/ssh_host_ed25519_key.pub"
  streaming-server = "ssh-ed25519 AAAA_REPLACE_WITH_STREAMING_SERVER_HOST_KEY";
in {
  "realdebrid-token.age".publicKeys = [ streaming-server ];
}
