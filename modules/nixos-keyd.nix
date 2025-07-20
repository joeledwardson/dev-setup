# Base NixOS configuration shared by all hosts
{ keyboardIds }:

{
  services.keyd = {
    enable = true;
    keyboards = {
      # The name is just the name of the configuration file, it does not really matter
      default = {
        ids = keyboardIds; # what goes into the [id] section
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
}

