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
   # ✅ Helper function
    getHome = user: {
      home.username = user;
      home.homeDirectory = "/home/${user}";
    };
    in {

      homeConfigurations = {
        "nixos@jollof-degen-wsl" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;

          modules = [
            ./modules/common.nix
            (getHome "nixos")
          ];
        };

        "nixos@SURFACE-BRO-NIX" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;

          modules = [
            ./modules/common.nix
            (getHome "nixos")
          ];
          # Optionally use extraSpecialArgs
          # to pass through arguments to home.nix
        };
      };
    };
}
