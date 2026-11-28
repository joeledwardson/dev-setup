# silverbullet, a markdown notes/wiki web app over a plain folder, run as claude, at https://<hostName>
# trial next to collabmd and openknowledge, all three editing the same folder (needs tailnet-caddy.nix for the cert)
# login: user claude, password after the colon in `sudo cat /run/agenix/silverbullet-env`
# uses the nixos module; env vars from https://silverbullet.md/Install/Configuration
{ hostName, port, spaceDir }:
{ config, pkgs-unstable, ... }:

{
  # holds SB_USER=claude:<password>
  age.secrets.silverbullet-env.file = ../secrets/silverbullet-env.age;

  services.silverbullet = {
    enable = true;
    # stable nixpkgs is a few releases behind upstream
    package = pkgs-unstable.silverbullet;
    # localhost only, caddy does the https
    listenAddress = "127.0.0.1";
    listenPort = port;
    inherit spaceDir;
    # claude, so files it writes stay editable by claude and the other trials
    user = "claude";
    group = "users";
    envFile = config.age.secrets.silverbullet-env.path;
    # one space in this folder, not the multi-space setup wizard newer versions default to
    extraArgs = [ "--single" ];
  };

  services.caddy.virtualHosts.${hostName}.extraConfig = "reverse_proxy localhost:${toString port}";
}
