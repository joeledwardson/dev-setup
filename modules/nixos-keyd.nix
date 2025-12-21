# setup keyd daemon with my custom keyboard configuration, for a specific set of keyboard IDs
#
# to check the name of a key (for escape, control etc), run `sudo keyd monitor`

{ keyboardIds }: {
  services.keyd = {
    enable = true;
    keyboards = {
      # The name is just the name of the configuration file, it does not really matter
      default = {
        # keyboard IDs passed as an argument to this function
        ids = keyboardIds;
        # Everything but the ID section:
        settings = {
          # The main layer, if you choose to declare it in Nix
          main = {
            # remap caps to combination of ctrl and escape
            capslock = "overload(control, esc)";
            # remap space to custom layer function
            rightalt = "overload(custom, rightalt)";
          };
          # my custom layer, used with space bar
          custom = {
            q = "home";
            e = "end";

            a = "left";
            s = "down";
            w = "up";
            d = "right";

            k = "pageup";
            j = "pagedown";

            x = "delete";
            i = "insert";
          };
        };
        extraConfig = ''
          # put here any extra-config, e.g. you can copy/paste here directly a configuration, just remove the ids part
        '';
      };
    };
  };
}

