{
  # Neovim 0.12 config ("nvim-min") that lives alongside the daily-driver
  # ~/.config/nvim. One binary bundles nvim + every language server, formatter
  # and debug adapter the config references, plus the tools nvim-treesitter
  # needs to compile parsers. Nothing is installed system-wide (no Mason) and
  # nothing leaks into the old config.
  #
  #   nix build ./configs/nvim-min      -> ./configs/nvim-min/result/bin/nvim-min
  #
  # NVIM_APPNAME=nvim-min makes nvim read ~/.config/nvim-min and keep its
  # plugins/state under ~/.local/{share,state}/nvim-min (see :h NVIM_APPNAME).
  description = "nvim-min: Neovim 0.12 config with bundled language tooling";

  # Same rev as nixpkgs-unstable in the repo root flake.lock, so store paths are shared.
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/3ed67ec0a4d3c7ab4ae1f04f8ee8df07bfa506a2";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      languageServers = with pkgs; [
        nixd
        basedpyright
        ruff
        vtsls # typescript / javascript (bundles its own tsserver)
        svelte-language-server
        biome # repo-local node_modules/.bin/biome wins when present
        tailwindcss-language-server
        lua-language-server
        marksman
        postgres-language-server
        vscode-langservers-extracted # jsonls, cssls
        yaml-language-server
        bash-language-server
        just-lsp
        mdx-language-server
        atlas
        terraform-ls
        systemd-lsp
        gopls
        ansible-language-server
      ];

      formatters = with pkgs; [
        stylua
        prettier # repo-local node_modules/.bin/prettier wins when present
        shfmt
        shellcheck
        sql-formatter
        nixfmt
      ];

      debugAdapters = with pkgs; [
        vscode-js-debug # provides `js-debug`
      ];

      # nvim-treesitter (main) compiles parsers from source; telescope-fzf-native runs make.
      buildTools = with pkgs; [ tree-sitter gcc gnumake gnutar curl ripgrep fd ];

      nvimMin = pkgs.writeShellScriptBin "nvim-min" ''
        export NVIM_APPNAME=nvim-min
        export PATH=${pkgs.lib.makeBinPath (languageServers ++ formatters ++ debugAdapters ++ buildTools)}:$PATH
        exec ${pkgs.neovim}/bin/nvim "$@"
      '';
    in {
      packages.${system}.default = nvimMin;
    };
}
