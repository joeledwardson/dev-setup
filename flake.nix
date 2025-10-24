{
  description = "NixOS configuration of joel";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  outputs = { nixpkgs, nixpkgs-unstable, nur, ... }:
    let
      my-system = "x86_64-linux";
      pkgs-unstable = import nixpkgs-unstable {
        system = my-system;
        config.allowUnfree = true;
        overlays = [ nur.overlay ];
      };
    in {
      nixosConfigurations = {
        # work laptop
        "degen-work" = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit pkgs-unstable; };
          modules = [
            ./modules/nixos-base.nix
            ./modules/nixos-desktop.nix
            ./hosts/degen-work/configuration.nix
            # laptop keyboard
            (import ./modules/nixos-keyd.nix {
              keyboardIds = [ "0001:0001:a33e860f" ];
            })
          ];
        };

        # work (WFH) laptop
        "degen-home" = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit pkgs-unstable; };
          modules = [
            ./modules/nixos-base.nix
            ./modules/nixos-desktop.nix
            ./hosts/degen-home/configuration.nix
            # laptop keyboard
            (import ./modules/nixos-keyd.nix {
              keyboardIds = [ "0001:0001:70533846" ];
            })
          ];
        };

        # desktop home PC
        "jollof-home" = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit pkgs-unstable; };
          modules = [
            ./modules/nixos-base.nix
            ./modules/nixos-desktop.nix
            ./hosts/jollof-home/configuration.nix
          ];
        };

        # desktop work PC
        "desktop-work" = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit pkgs-unstable; };
          modules = [
            ./modules/nixos-base.nix
            ./modules/nixos-desktop.nix
            ./hosts/desktop-work/configuration.nix
          ];
        };
      };

    };

}
