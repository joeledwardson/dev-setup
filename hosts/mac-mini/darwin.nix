{
  config,
  pkgs,
  pkgs-unstable,
  ...
}:

let
  user = "jollof";
  mautrix-imessage = pkgs.callPackage ../../pkgs/mautrix-imessage.nix { };
in
{
  imports = [ ./bluebubbles.nix ];

  # App permissions, password and Private API have been configured manually.
  # The actual backend is selected in mautrix-imessage-config.age.
  local.bluebubbles.startAtLogin = true;

  # This is still macOS. nix-darwin only manages the declared settings and
  # services on top of it.
  nixpkgs.hostPlatform = "aarch64-darwin";
  # mautrix-imessage still links libolm.
  nixpkgs.config.permittedInsecurePackages = [ "olm-3.2.16" ];
  networking.hostName = "joels-mac-mini";
  system.primaryUser = user;

  # Keep Nix builds isolated from the rest of the machine.
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  # Both services are managed as native macOS launchd jobs.
  services.openssh.enable = true;
  services.tailscale.enable = true;
  # nix-darwin has no extraSetFlags option. Retry until tailscaled is ready.
  launchd.daemons.tailscale-ssh = {
    command = "${config.services.tailscale.package}/bin/tailscale set --ssh";
    serviceConfig = {
      RunAtLoad = true;
      KeepAlive.SuccessfulExit = false;
      ThrottleInterval = 30;
    };
  };

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

  # Keep the bridge in jollof's session and retain its state across backend
  # changes. Both backends use the same upstream bridge executable.
  launchd.user.agents.mautrix-imessage = {
    # --no-update: the bridge rewrites its config on startup via a temp file in
    # the config's own directory, and /run/agenix is root-owned so that always
    # fails. Safe here because the config has no `generate` placeholder values.
    command = "${mautrix-imessage}/bin/mautrix-imessage -c ${config.age.secrets.mautrix-imessage-config.path} --no-update";
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

  # dont let it sleep!
  power.sleep.computer = "never";
  power.sleep.harddisk = "never";
  power.sleep.display = "never";
  power.restartAfterPowerFailure = true;
  power.restartAfterFreeze = true;

  programs.zsh.enable = true;
  environment.variables = {
    EDITOR = "nvim";
    LANG = "en_GB.UTF-8";
  };

  environment.systemPackages = with pkgs; [
    # minimal packages to make my shell useable
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
    tree-sitter

    # packages for mautrix imessage service
    mautrix-imessage

    # use latest claude code
    pkgs-unstable.claude-code
  ];

  homebrew = {
    enable = true;
    enableZshIntegration = true;
    taps = [ "steipete/tap" ];
    brews = [ "steipete/tap/remindctl" ];
  };

  # Compatibility version for nix-darwin's stateful defaults. Do not change
  # this during routine upgrades.
  system.stateVersion = 6;

  ## --- setup steps ---
  # these have already been completed, but for reference
  # 1. use the mautrix-imessage-registration from the template (https://github.com/mautrix/imessage/blob/master/example-registration.yaml)
  # 2. generate random strings for `as_token` and `hs_token` and save the secret
  # 3. generate the mautrix-imessage-config from the template (https://mau.dev/mautrix/gmessages/-/blob/v0.4.3/example-config.yaml)
  # 4. replace the `as_token` and `hs_token` with the values used earlier
  # 5. replace the `login_shared_secret` with the value "appservice" (see here: https://github.com/mautrix/imessage/issues/224#issuecomment-3076655899)

  ## --- manual steps ---
  # still a few steps in setting up the mac mini that must be done on the device can't be done remotely.
  # 1. un-set natural scrolling in settings => mouse (inverted scrolling is incredibly annoying)
  # 2. set the keyboard in settings => keyboard to `british pc`, otherwise the british one switches " and @
  # 3. install homebrew
  # 4. go to settings => general => sharing => screen sharing => tick "vnc viewers may control..."
  # 5. (then can run `task os:build`)
  # 6. search for "full disk access" in mac settings and enable it for mautrix-imessage
  # 7. run bluebubbles app, then grant permissions and set server password to the value, found in `mautrix-imessage-config.age` where it says `bluebubbles_password`
  # 8. enable Private API; use Nix for startup and disable the app's own launch-at-login option
  # 9. after changing backend or Private API settings, wait for BlueBubbles to be ready, then run:
  #    launchctl kickstart -k gui/$(id -u)/org.nixos.mautrix-imessage

}
