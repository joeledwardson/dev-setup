rec {
  # my tailsacle domain
  domain = "rove-lydian.ts.net";
  # e.g. fqdnFor "pi-box" => "pi-box.rove-lydian.ts.net"
  fqdnFor = hostName: "${hostName}.${domain}";
}
