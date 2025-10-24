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
      mySystem = "x86_64-linux";
      pkgs-unstable = import nixpkgs-unstable {
        system = mySystem;
        config.allowUnfree = true;
        overlays = [ nur.overlay ];
      };
      commonGroups = [
        "networkmanager" # give user access to network manager (see https://wiki.nixos.org/wiki/NetworkManager)
        "wheel" # give access to sudo commands, not sure if required tbh (see https://unix.stackexchange.com/questions/152442/what-is-the-significance-of-the-wheel-group)
        "video" # legacy? not sure if needed for capture devices (https://wiki.archlinux.org/title/Users_and_groups#Pre-systemd_groups)
        "plugdev" # this is required (I think) for udiskie
        "docker" # non root access to docker
      ];
    in {
      nixosConfigurations = {
        # work laptop
        "degen-work" = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit pkgs-unstable;
            commonGroups = commonGroups;
          };
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
          specialArgs = {
            inherit pkgs-unstable;
            commonGroups = commonGroups;
          };

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
          specialArgs = {
            inherit pkgs-unstable;
            commonGroups = commonGroups;
          };

          modules = [
            ./modules/nixos-base.nix
            ./modules/nixos-desktop.nix
            ./hosts/jollof-home/configuration.nix
          ];
        };

        # desktop work PC
        "desktop-work" = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit pkgs-unstable;
            commonGroups = commonGroups;
          };

          modules = [
            ./modules/nixos-base.nix
            ./modules/nixos-desktop.nix
            ./hosts/desktop-work/configuration.nix
          ];
        };
      };

    };

}
