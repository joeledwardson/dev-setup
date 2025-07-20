{
  description = "NixOS configuration of joel";

  inputs = { nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable"; };

  outputs = { nixpkgs, ... }:
    let
    in {
      nixosConfigurations = {
        "degen-work" = nixpkgs.lib.nixosSystem {
          modules = [
            ./modules/nixos-base.nix
            ./modules/nixos-keyd.nix
            ./hosts/degen-work/configuration.nix
            {
              myKeyd.keyboardIds = [ "0414:8005" ];
            }
          ];
        };

        "jollof-home" = nixpkgs.lib.nixosSystem {
          modules =
            [ ./modules/nixos-base.nix ./hosts/jollof-home/configuration.nix ];
        };

        "desktop-work" = nixpkgs.lib.nixosSystem {
          modules =
            [ ./modules/nixos-base.nix ./hosts/desktop-work/configuration.nix ];
        };
      };

    };

}
