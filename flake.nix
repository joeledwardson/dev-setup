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
            (import ./modules/nixos-keyd.nix { keyboardIds = [ "0414:8005" ]; })
            ./hosts/degen-work/configuration.nix
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
