{
  description = "NixOS configuration of joel";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { nixpkgs, nixpkgs-unstable, ... }:
    let
      pkgs-unstable = import nixpkgs-unstable {
        system = "x86_64-linux";
        config.allowUnfree = true;
      };
    in {
      nixosConfigurations = {
        "degen-work" = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit pkgs-unstable; };
          modules = [
            ./modules/nixos-base.nix
            # lapyop keyboard
            (import ./modules/nixos-keyd.nix { keyboardIds = [ "0414:8005" ]; })
            ./hosts/degen-work/configuration.nix
          ];
        };

        "degen-home" = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit pkgs-unstable; };
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
          specialArgs = { inherit pkgs-unstable; };
          modules =
            [ ./modules/nixos-base.nix ./hosts/jollof-home/configuration.nix ];
        };

        "desktop-work" = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit pkgs-unstable; };
          modules =
            [ ./modules/nixos-base.nix ./hosts/desktop-work/configuration.nix ];
        };
      };

    };

}
