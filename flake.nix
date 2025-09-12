{
  description = "NixOS configuration of joel";

  inputs = { nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05"; };

  outputs = { nixpkgs, ... }:
    let
    in {
      nixosConfigurations = {
        "degen-work" = nixpkgs.lib.nixosSystem {
          modules = [
            ./modules/nixos-base.nix
            # lapyop keyboard
            (import ./modules/nixos-keyd.nix { keyboardIds = [ "0414:8005" ]; })
            ./hosts/degen-work/configuration.nix
          ];
        };

        "degen-home" = nixpkgs.lib.nixosSystem {
          modules = [
            ./modules/nixos-base.nix
            # laptop keyboard
            (import ./modules/nixos-keyd.nix {
              keyboardIds = [ "0001:0001:70533846" ];
            })
            ./hosts/degen-home/configuration.nix
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
