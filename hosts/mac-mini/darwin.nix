{ config, pkgs, ... }:

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

  age.secrets.mautrix-imessage-config = {
    file = ../../secrets/mautrix-imessage-config.age;
    owner = user;
  };

  # create working and logs directory under user
  system.activationScripts.postActivation.text = ''
    install -d -o ${user} -g staff \
      /Users/${user}/.local/share/mautrix-imessage \
      /Users/${user}/Library/Logs/mautrix-imessage
  '';

  # This must be a user agent: the bridge reads jollof's Messages database and
  # drives Messages.app in the logged-in GUI session.
  launchd.user.agents.mautrix-imessage = {
    command = "${mautrix-imessage}/bin/mautrix-imessage -c ${config.age.secrets.mautrix-imessage-config.path}";
    environment.HOME = "/Users/${user}";
    serviceConfig = {
      RunAtLoad = true;
      KeepAlive = true;
      ThrottleInterval = 10;
      WorkingDirectory = "/Users/${user}/.local/share/mautrix-imessage";
      StandardOutPath = "/Users/${user}/Library/Logs/mautrix-imessage/stdout.log";
      StandardErrorPath = "/Users/${user}/Library/Logs/mautrix-imessage/stderr.log";
    };
  };

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
    go-task
  ];

  # Compatibility version for nix-darwin's stateful defaults. Do not change
  # this during routine upgrades.
  system.stateVersion = 6;

  ## --- manual steps ---
  # still a few steps in setting up the mac mini that must be done on the device can't be done remotely.
  # 1. un-set natural scrolling in settings => mouse (inverted scrolling is incredibly annoying)
  # 2. set the keyboard in settings => keyboard to `british pc`, otherwise the british one switches " and @
  # 3. install homebrew
}
