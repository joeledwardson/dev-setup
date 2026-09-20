# Render one SSH client Host block. The destination defaults to the host name.
{ host, hostname ? host, user }: ''
  Host ${host}
      HostName ${hostname}
      User ${user}
''
