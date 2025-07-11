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
        # work desktop
        "joelyboy@MINTY-RDP" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./modules/common.nix (getHome "joelyboy") ];
        };
        # work (degen) laptop WSL
        "nixos@jollof-degen-wsl" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./modules/common.nix (getHome "nixos") ];
        };
        # work (degen) laptop NixOS
        "jollof@degen-work" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules =
            [ ./modules/common.nix ./modules/desktop.nix (getHome "jollof") ];
        };
      };

      nixosConfigurations = {
        "degen-work" = nixpkgs.lib.nixosSystem {
          modules = [ ./hosts/degen-work/configuration.nix ];
        };

        "jollof-home" = nixpkgs.lib.nixosSystem {
          modules = [ ./hosts/jollof-home/configuration.nix ];
        };

      };

    };

}
