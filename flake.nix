{
  description = "Home Manager configuration of joel";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in {

      homeConfigurations = {
        "joelyboy" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;

          # Specify your home configuration modules here, for example,
          # the path to your home.nix.
          modules = [ ./modules/common.nix ];

          # Optionally use extraSpecialArgs
          # to pass through arguments to home.nix
        };

        "nixos@jollof-degen-wsl" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;

          # Specify your home configuration modules here, for example,
          # the path to your home.nix.
          modules = [
            ./modules/common.nix
            {
              home = {
                username = "nixos";
                homeDirectory = "/home/nixos";
              };
            }
          ];
          # Optionally use extraSpecialArgs
          # to pass through arguments to home.nix
        };

        "joel" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;

          # Specify your home configuration modules here, for example,
          # the path to your home.nix.
          modules = [
            ./modules/common.nix
            {
              home = {
                username = "joel";
                homeDirectory = "/home/joel";
              };
            }
          ];
          # Optionally use extraSpecialArgs
          # to pass through arguments to home.nix
        };
      };
    };
}
