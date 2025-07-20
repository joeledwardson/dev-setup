# Base NixOS configuration shared by all hosts
{ config, pkgs, lib, ... }:

{
  options.myKeyd = {
    keyboardIds = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "*" ];
      description = "List of keyboard IDs to apply keyd configuration to";
    };
  };

  config = {
    services.keyd = {
      enable = true;
      keyboards = {
        # The name is just the name of the configuration file, it does not really matter
        default = {
          ids = config.myKeyd.keyboardIds; # what goes into the [id] section
          # Everything but the ID section:
          settings = {
            # The main layer, if you choose to declare it in Nix
            main = {
              # remap caps to combination of ctrl and escape
              capslock = "overload(control, sec)";
              # remap space to custom layer function
              space = "overload(custom, space)";
            };
            custom = {
              h = "left";
              j = "down";
              k = "up";
              l = "right";
              u = "pageup";
              d = "pagedown";
              x = "delete";
            };
          };
          extraConfig = ''
            # put here any extra-config, e.g. you can copy/paste here directly a configuration, just remove the ids part
          '';
        };
      };
    };
  };
}

