{
  description = "NixOS configuration of joel";

  inputs = { nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable"; };

  outputs = { nixpkgs, ... }:
    let
    in {
      nixosConfigurations = {
        "degen-work" = nixpkgs.lib.nixosSystem {
          modules =
            [ ./modules/nixos-base.nix ./hosts/degen-work/configuration.nix ];
        };

        "jollof-home" = nixpkgs.lib.nixosSystem {
          modules =
            [ ./modules/nixos-base.nix ./hosts/jollof-home/configuration.nix ];
        };

      };

    };

}
