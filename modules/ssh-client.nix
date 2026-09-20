# NixOS client config, using the hosts and users already declared in the flake.
{
  config,
  lib,
  inputs,
  ...
}:
let
  renderHost = import ../lib/render-ssh-host.nix;
  nixosConfigurations = inputs.self.nixosConfigurations;
  # The live installer isn't an SSH destination.
  hosts = lib.remove "installer" (builtins.attrNames nixosConfigurations);
  # map each config into an ssh hostname + username block
  configs = map (
    name:
    let
      cfg = nixosConfigurations.${name}.config;
    in
    {
      host = cfg.networking.hostName;
      user = cfg.my.ssh.defaultUser;
    }
  ) hosts;
  # add mac block to the list
  mac = inputs.self.darwinConfigurations.joels-mac-mini.config;
  hostBlocks = configs ++ [
    {
      host = mac.networking.hostName;
      user = mac.system.primaryUser;
    }
  ];
in
{

  # make an option for each configuration to fill in with the default user to go into the ssh config
  options.my.ssh.defaultUser = lib.mkOption {
    type = lib.types.str;
    description = "Default SSH login when connecting to this host.";
  };

  config = {
    # check the configuration has our deafult user option specified
    assertions = [
      {
        assertion = builtins.hasAttr config.my.ssh.defaultUser config.users.users;
        message = "my.ssh.defaultUser must name a declared user on ${config.networking.hostName}.";
      }
    ];

    # write the SSH host blockto debug then write to ssh configuration file
    environment.etc."ssh/nix-hosts.conf".text =
      builtins.trace "SSH host configs: ${builtins.toJSON hostBlocks}"
        (lib.concatMapStringsSep "\n" renderHost hostBlocks);
  };
}
