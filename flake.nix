{
  description = "NixOS configuration of joel";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-nvim.url = "github:NixOS/nixpkgs/nixos-25.11"; # nvim 0.11.7 — latest stable before 0.12 broke plugin APIs
    nixarr.url = "github:rasmus-kirk/nixarr";
    agenix.url = "github:ryantm/agenix";

  };

  # inputs are resolved to flakes. 
  outputs = inputs@{ nixpkgs, nixpkgs-unstable, ... }:
    let
      x86System = "x86_64-linux";
      archSystem = "aarch64-linux";
      mkPkgs = sys:
        import nixpkgs-unstable {
          system = sys;
          config = {
            allowUnfree = true;
            # this is required for stremio (some nixos nonsense IDK)
            permittedInsecurePackages = [ "qtwebengine-5.15.19" ];
          };
        };
      commonGroups = [
        "networkmanager" # give user access to network manager (see https://wiki.nixos.org/wiki/NetworkManager)
        "wheel" # give access to sudo commands, not sure if required tbh (see https://unix.stackexchange.com/questions/152442/what-is-the-significance-of-the-wheel-group)
        "video" # legacy? not sure if needed for capture devices (https://wiki.archlinux.org/title/Users_and_groups#Pre-systemd_groups)
        "plugdev" # this is required (I think) for udiskie
        "docker" # non root access to docker
      ];
      mkArgs = sys: {
        pkgs-unstable = mkPkgs sys;
        pkgs-nvim = import inputs.nixpkgs-nvim { system = sys; config.allowUnfree = true; };
        inherit inputs commonGroups;
      };
    in {
      nixosConfigurations = {
        # work laptop
        "degen-work" = nixpkgs.lib.nixosSystem {
          system = x86System;
          specialArgs = mkArgs x86System;
          modules = [
            inputs.agenix.nixosModules.default
            ./modules/nixos-base.nix
            ./modules/nixos-core-desktop.nix
            ./modules/nixos-extended-desktop.nix
            ./hosts/degen-work/configuration.nix
            # laptop keyboard
            (import ./modules/nixos-keyd.nix {
              keyboardIds = [ "0001:0001:a33e860f" ];
            })
          ];
        };

        # work (WFH) laptop
        "degen-home" = nixpkgs.lib.nixosSystem {
          system = x86System;
          specialArgs = mkArgs x86System;
          modules = [
            ./modules/nixos-base.nix
            ./modules/nixos-core-desktop.nix
            ./modules/nixos-extended-desktop.nix
            ./hosts/degen-home/configuration.nix
            # laptop keyboard
            (import ./modules/nixos-keyd.nix {
              keyboardIds = [
                # built in keyboard 
                "0001:0001:70533846"
                # home external keyboard from Tim's bedroom
                "1c4f:0002:3c76615e"
              ];
            })
          ];
        };

        # desktop home PC
        "jollof-home" = nixpkgs.lib.nixosSystem {
          system = x86System;
          specialArgs = mkArgs x86System;
          modules = [
            inputs.agenix.nixosModules.default
            ./modules/nixos-base.nix
            ./modules/nixos-core-desktop.nix
            ./modules/nixos-extended-desktop.nix
            ./hosts/jollof-home/configuration.nix
          ];
        };

        # desktop work PC
        "desktop-work" = nixpkgs.lib.nixosSystem {
          system = x86System;
          specialArgs = mkArgs x86System;
          modules = [
            inputs.agenix.nixosModules.default
            ./modules/nixos-base.nix
            ./modules/nixos-core-desktop.nix
            ./modules/nixos-extended-desktop.nix
            ./hosts/desktop-work/configuration.nix
          ];
        };

        # pi box (aarch64) — headless, no desktop
        "pi-box" = nixpkgs.lib.nixosSystem {
          system = archSystem;
          specialArgs = mkArgs archSystem;
          modules = [
            ./modules/nixos-base.nix
            ./modules/nixos-sandbox.nix
            ./hosts/pi-box/configuration.nix
          ];
        };

        # streaming box
        "streaming-server" = nixpkgs.lib.nixosSystem {
          system = x86System;
          specialArgs = mkArgs x86System;
          modules = [
            inputs.agenix.nixosModules.default
            ./modules/nixos-base.nix
            ./modules/nixos-core-desktop.nix
            ./modules/nixos-sandbox.nix
            ./hosts/streaming-server/configuration.nix
          ];
        };

        # degen laptop (sandbox/claude bot machine)
        "degen-bot" = nixpkgs.lib.nixosSystem {
          system = x86System;
          specialArgs = mkArgs x86System;
          modules = [
            inputs.agenix.nixosModules.default
            ./modules/nixos-base.nix
            ./modules/nixos-sandbox.nix
            ./hosts/degen-bot/configuration.nix
          ];
        };

        # live installer ISO — build with:
        "installer" = nixpkgs.lib.nixosSystem {
          system = x86System;
          specialArgs = mkArgs x86System;
          modules = [ ./hosts/installer ];
        };

      };

    };

}
