{ pkgs, ... }:

let
  user = "jollof";
  mautrix-imessage = pkgs.callPackage ../../pkgs/mautrix-imessage.nix { };
in {
  # This is still macOS. nix-darwin only manages the declared settings and
  # services on top of it.
  nixpkgs.hostPlatform = "aarch64-darwin";
  # mautrix-imessage still links libolm.
  nixpkgs.config.permittedInsecurePackages = [ "olm-3.2.16" ];
  networking.hostName = "joels-mac-mini";
  system.primaryUser = user;

  # Keep Nix builds isolated from the rest of the machine.
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
  };

  # Both services are managed as native macOS launchd jobs.
  services.openssh.enable = true;
  services.tailscale.enable = true;

  # RustDesk must live in /Applications so macOS can attach Screen Recording
  # and Accessibility permissions to a stable app bundle. nixpkgs marks its
  # Darwin package broken, so let nix-darwin manage the Homebrew cask.
  homebrew = {
    enable = true;
    casks = [ "rustdesk" ];
    onActivation = {
      autoUpdate = false;
      cleanup = "none";
      upgrade = false;
    };
  };

  # Small terminal environment. Language servers and desktop applications can
  # be added later when this host actually needs them.
  programs.zsh.enable = true;
  environment.variables.EDITOR = "nvim";
  environment.systemPackages = with pkgs; [
    bat
    delta
    direnv
    dotbot
    eza
    fd
    fzf
    git
    gnumake
    go
    jq
    mautrix-imessage
    mediainfo
    neovim
    ouch
    rich-cli
    ripgrep
    sheldon
    tmux
    yazi
    zoxide
  ];

  # Compatibility version for nix-darwin's stateful defaults. Do not change
  # this during routine upgrades.
  system.stateVersion = 6;

  ## --- manual steps ---
  # still a few steps in setting up the mac mini that must be done on the device can't be done remotely.
  # 1. un-set natural scrolling in settings => mouse (inverted scrolling is incredibly annoying)
  # 2. set the keyboard in settings => keyboard to `british pc`, otherwise the british one switches " and @
}
