{
  description = "NixOS configuration of joel";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-claude.url = "github:NixOS/nixpkgs/99b135bc06";
    nixarr.url = "github:rasmus-kirk/nixarr";
    agenix.url = "github:ryantm/agenix";

  };

  # inputs are resolved to flakes. 
  outputs = inputs@{ nixpkgs, nixpkgs-unstable, ... }:
    let
      mySystem = "x86_64-linux";
      pkgs-unstable = import nixpkgs-unstable {
        system = mySystem;
        config = {
          allowUnfree = true;
          # this is required for stremio (some nixos nonsense IDK)
          permittedInsecurePackages = [ "qtwebengine-5.15.19" ];
        };
      };
      pkgs-claude = import inputs.nixpkgs-claude {
        system = mySystem;
        config.allowUnfree = true;
      };
      pkgs = import nixpkgs {
        system = mySystem;
        config.allowUnfree = true;
      };
      commonGroups = [
        "networkmanager" # give user access to network manager (see https://wiki.nixos.org/wiki/NetworkManager)
        "wheel" # give access to sudo commands, not sure if required tbh (see https://unix.stackexchange.com/questions/152442/what-is-the-significance-of-the-wheel-group)
        "video" # legacy? not sure if needed for capture devices (https://wiki.archlinux.org/title/Users_and_groups#Pre-systemd_groups)
        "plugdev" # this is required (I think) for udiskie
        "docker" # non root access to docker
      ];
      commonSpecialArgs = {
        nixarr_flake = inputs.nixarr;
        inherit inputs commonGroups pkgs-unstable pkgs-claude;
      };
    in {
      # Base docker image for dev container — thin Dockerfile in dev-image/ layers
      # the imperative bootstrap (dotbot, nvim Lazy sync, ssh-keygen) on top.
      # Build flow:
      #   nix build .#dev-image-base
      #   docker load < result
      #   docker build -t dev-image:latest -f dev-image/Dockerfile .
      packages.${mySystem}.dev-image-base = pkgs.dockerTools.buildLayeredImage {
        name = "dev-image-base";
        tag = "latest";
        contents = (import ./modules/packages-dev-min.nix {
          inherit pkgs pkgs-unstable pkgs-claude;
        }) ++ (with pkgs; [
          # container essentials (not in the shared list since NixOS provides them)
          bashInteractive
          zsh
          coreutils
          gnused
          gawk
          gnugrep
          findutils
          diffutils
          which
          less
          gzip
          gnutar
          cacert
          iana-etc # /etc/protocols, /etc/services
          tzdata
          glibcLocales
        ]);
        config = {
          Cmd = [ "/bin/zsh" ];
          WorkingDir = "/root";
          Env = [
            "HOME=/root"
            "USER=root"
            "SHELL=/bin/zsh"
            "EDITOR=vim"
            "ZDOTDIR=/root/.config/zsh"
            "XDG_CACHE_HOME=/root/.cache"
            "XDG_CONFIG_HOME=/root/.config"
            "XDG_DATA_HOME=/root/.local/share"
            "XDG_STATE_HOME=/root/.local/state"
            "PATH=/root/.npm-global/bin:/root/.local/bin:/bin:/usr/bin"
            "LANG=en_GB.UTF-8"
            "LC_ALL=en_GB.UTF-8"
            "LOCALE_ARCHIVE=${pkgs.glibcLocales}/lib/locale/locale-archive"
            "SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt"
            "NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt"
            "TZ=Europe/London"
            # marksman fails without this: https://github.com/dotnet/runtime/issues/27956
            "DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1"
          ];
        };
        enableFakechroot = true;
        fakeRootCommands = ''
          mkdir -p /root/.ssh /root/.claude /root/.config/zsh \
                   /root/.local/bin /root/.local/share /root/.local/state \
                   /root/.cache /root/.npm-global /tmp
          chmod 1777 /tmp
          chmod 700 /root/.ssh

          cat > /etc/passwd <<EOF
          root:x:0:0:root:/root:/bin/zsh
          nobody:x:65534:65534:nobody:/var/empty:/bin/false
          EOF
          cat > /etc/group <<EOF
          root:x:0:
          nobody:x:65534:
          EOF
          cat > /etc/shells <<EOF
          /bin/bash
          /bin/zsh
          EOF
        '';
      };

      nixosConfigurations = {
        # work laptop
        "degen-work" = nixpkgs.lib.nixosSystem {
          specialArgs = commonSpecialArgs;
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
          specialArgs = commonSpecialArgs;
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
          specialArgs = commonSpecialArgs;
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

          specialArgs = commonSpecialArgs;

          modules = [
            inputs.agenix.nixosModules.default
            ./modules/nixos-base.nix
            ./modules/nixos-core-desktop.nix
            ./modules/nixos-extended-desktop.nix
            ./hosts/desktop-work/configuration.nix
          ];
        };

        # pi box
        "pi-box" = nixpkgs.lib.nixosSystem {
          specialArgs = commonSpecialArgs;
          modules = [
            ./modules/nixos-base.nix
            ./modules/nixos-core-desktop.nix
            ./hosts/pi-box/configuration.nix
          ];
        };

        # streaming box
        "streaming-server" = nixpkgs.lib.nixosSystem {
          specialArgs = commonSpecialArgs;
          modules = [
            inputs.agenix.nixosModules.default
            ./modules/nixos-base.nix
            ./modules/nixos-core-desktop.nix
            ./hosts/streaming-server/configuration.nix
          ];
        };

      };

    };

}
