# home.nix
{ config, pkgs, lib, username, ... }: 
let
  # catppucin plugin doesnt render properly when using nixos package so build myself
  catppuccin-tmux = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "catppuccin";
    version = "unstable-2024-01-03";  # or whatever date you're building at
    src = pkgs.fetchFromGitHub {
      owner = "catppuccin";
      repo = "tmux";
      rev = "ba9bd88c98c81f25060f051ed983e40f82fdd3ba"; # Using the newer commit
      sha256 = "sha256-HegD89d0HUJ7dHKWPkiJCIApPY/yqgYusn7e1LDYS6c=";
      };
    };

  cpu-tmux = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "cpu";
    version = "unstable-2024-01-03";  # or whatever date you're building at
    src = pkgs.fetchFromGitHub {
      owner = "tmux-plugins";
      repo = "tmux-cpu";
      rev = "bcb110d754ab2417de824c464730c412a3eb2769"; # Using the newer commit
      sha256 = "sha256-OrQAPVJHM9ZACyN36tlUDO7l213tX2a5lewDon8lauc=";

      };
    };
  in
  {
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = builtins.trace "Setting username to:" (lib.mkDefault "joelyboy");
  home.homeDirectory = builtins.trace "Username from config is: ${config.home.username}" (
    lib.mkDefault "/home/${config.home.username}"
  );
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
    direnv
    fnm
    clojure # for metabase
    lazysql
    usql
    slack
    git
    google-chrome
    copyq
    vim
    pipx
    curl
    tldr
    bat
    xclip
    xsel
    lazygit
    fnm
    aichat
    gh     # this is github cli
    glab   # this is gitlab cli
    neovim
    visidata
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
    ".config/nvim".source = configs/nvim;
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
    # EDITOR = "emacs";
  };

  programs.fish.enable = true;
  programs.tmux = {
    enable = true;
    baseIndex = 1;
    prefix = "C-Space";

    plugins = [
      {
        plugin = pkgs.tmuxPlugins.sensible;
      }
      {
        plugin = catppuccin-tmux;
        extraConfig = ''
          set -g @catppuccin_flavor "mocha"
          set -g @catppuccin_window_status_style "rounded"
          '';
      }
      {
        plugin = pkgs.tmuxPlugins.battery;
        extraConfig = ''
          set -g status-left-length 100
          set -g status-left ""
          set -g status-right "#{E:@catppuccin_status_application}"
          set -agF status-right "#{E:@catppuccin_status_cpu}"
          set -ag status-right "#{E:@catppuccin_status_session}"
          set -ag status-right "#{E:@catppuccin_status_uptime}"
          # TESTIE 1
        '';
      }
      {
        plugin =cpu-tmux;
      }
    ];
    extraConfig = builtins.readFile ./configs/tmux;
  };
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Some of these might be better configured using their dedicated modules:
  programs.zsh = {
    enable = true;
    envExtra = builtins.readFile ./configs/zshrc;
  };

   # Configure Git using programs.git
  programs.git = {
    enable = true;

    # Explicitly set userName and userEmail
    userName = "joel";
    userEmail = "joel.edwardson1@gmail.com";

      delta = {
        enable = true;
	options = {

        navigate = true;        # Use n and N to move between diff sections
        light = false;          # Set to true if using a light terminal background
        "syntax-theme" = "Dracula";
	};
      };

    # Use structured extraConfig for other settings
    extraConfig = {
      core = {
        editor = "vim";
      };
      merge = {
        conflictStyle = "diff3";
      };
    };

    # Add ignore entries
    ignores = [
      "**/*.swp"
      "**/*.swo"
      ".vscode"
    ];

    # Add include paths
    includes = [ 
      { path = "~/.gitconfig.local" ; }
    ];
  };

}
