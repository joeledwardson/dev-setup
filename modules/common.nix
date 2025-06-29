# home.nix
{ config, pkgs, lib, ... }:

let
in {
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  # home.username = builtins.trace "Using username: " (config.home.username);
  # home.homeDirectory = builtins.trace "Using home directory" (config.home.homeDirectory);

  nixpkgs.config.allowUnfree = true;

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.11"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    # pkgs.hello

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')

    ### languages
    clojure # for metabase
    gcc # for nvim kickstart
    pipx
    nix-search-cli
    volta
    # fnm
    deno
    poetry
    uv
    # pyenv
    pipx
    go
    nixd
    ### Database tools
    ruby
    lazysql
    usql
    visidata
    harlequin
    dblab
    rainfrog
    pgcli
    rabbitmq-server
    postgresql_17
    ### terminals
    zsh
    fish
    ### CLI tools
    git
    vim
    curl
    tldr
    bat
    lazygit
    aichat
    gh
    glab
    tmux
    fzf
    dotbot
    google-cloud-sdk
    bitwarden-cli
    eza
    gnumake
    ranger
    delta
    wget
    jq
    xdg-utils
    kbd # has showkey
    lazydocker
    graphviz # required for madge npm package
    claude-code
    unzip
    ### neovim
    neovim
    ripgrep
    prettierd
    stylua
    nixfmt-classic
    ### dependencies for neovim
    tree-sitter
    readline
    libedit
    ### X11 specific utilities
    xclip
    xsel
    xorg.xdpyinfo
    ### themes
    starship
    oh-my-posh
    oh-my-fish
    qogir-theme
    qogir-icon-theme
    librsvg # for cursors and icons in xfce, see https://wiki.xfce.org/howto/install_new_themes
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';

    ".themes/Qogir".source = "${pkgs.qogir-theme}/share/themes/Qogir";
    ".icons/Qogir".source = "${pkgs.qogir-icon-theme}/share/icons/Qogir";

  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/joel/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    XDG_CONFIG_HOME = "${config.home.homeDirectory}/.config";
    ZDOTDIR = "${config.home.homeDirectory}/.config/zsh";
    LANG = "en_GB.UTF-8";
    LC_ALL = "en_GB.UTF-8";
  };

  # Alternatively, this cleaner version also works
  _module.args = builtins.trace
    "Using username: ${config.home.username} and home dir ${config.home.homeDirectory}"
    { };

  # this creates the ~/.profile link and ensures session variables above are sourced
  programs.bash.enable = true;
  programs.home-manager.enable = true;
}
