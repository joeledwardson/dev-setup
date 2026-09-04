# nvim-min

The daily-driver `configs/nvim` ported to Neovim 0.12. Same keymaps and feature set,
built on what 0.12 provides natively. The old config stays on 0.11 and is never touched.

## Run

```sh
nix build ~/dev-setup/configs/nvim-min          # -> configs/nvim-min/result/bin/nvim-min
ln -sf ~/dev-setup/configs/nvim-min/result/bin/nvim-min ~/.local/bin/nvim-min
nvim-min
```

The wrapper sets `NVIM_APPNAME=nvim-min`, so nvim reads `~/.config/nvim-min` (a dotbot
link to this dir) and keeps plugins and state under `~/.local/{share,state}/nvim-min`.
Every language server, formatter and debug adapter is on the wrapper's `PATH`, so there
is no Mason and nothing is installed system-wide. Kill switch: stop running `nvim-min`.

## What changed from the old config

| Area | Old (0.11) | New (0.12) |
| --- | --- | --- |
| Plugin manager | lazy.nvim, lazy-loaded specs | `vim.pack` (built in), plugins load eagerly, lockfile `nvim-pack-lock.json` |
| Language server install | Mason + mason-lspconfig + mason-tool-installer | nix packages in `flake.nix` |
| Server config | lspconfig + Mason auto-enable | `vim.lsp.config` / `vim.lsp.enable` (definitions still from nvim-lspconfig) |
| Treesitter | nvim-treesitter `master`, `configs.setup` | nvim-treesitter `main`, `FileType` autocmd calls `vim.treesitter.start` |
| TypeScript | typescript-tools.nvim | vtsls |
| Python | pyright | basedpyright |
| Completion | blink.cmp + friendly-snippets | built in: `vim.lsp.completion` autotrigger on every word character, docs via `completeopt=popup`, LSP snippets via `vim.snippet`, `<Tab>` accepts |
| Signature help | lsp_signature.nvim | built in: `<C-s>` in insert mode |
| Lua types (nvim API, `vim.uv`, plugins) | lazydev + luvit-meta | explicit `workspace.library` list in lua_ls settings: VIMRUNTIME, `${3rd}/luv/library`, the pack dir |
| File icons | nvim-web-devicons + mini.icons | mini.icons with `mock_nvim_web_devicons()` |
| html/css formatting | html_beautify (Ruby gem via Mason, not in nixpkgs) | prettier |
| JS debug adapter | Mason `js-debug-adapter` | nixpkgs `vscode-js-debug` (`js-debug`) |
| Build steps | lazy `build = 'make'` / `:TSUpdate` | `PackChanged` autocmd in init.lua |

Dropped: lazy.nvim, lazydev, luvit-meta, mason x3, mason-nvim-dap, nvim-dap-vscode-js
(adapter is defined directly), image.nvim (was already disabled), blink.cmp,
friendly-snippets, lsp_signature, lsp-progress, nvim-web-devicons, telescope-file-browser,
telescope-undo. Formatters that were configured but never installed (tombi, goimports,
terraform_fmt) and the unconfigured delve adapter were removed rather than bundled.

nvim-lspconfig stays: the LSP *client* is built in, but the per-server definitions
(command, filetypes, root markers) are not, and lspconfig is a 400-file collection of
exactly those. Nothing from its Lua API is called.

## Layout

- `init.lua`: options, `vim.pack.add` list, requires.
- `lua/plugins/*.lua`: one file per plugin group, setup and its keymaps together.
- `lua/custom/keymaps.lua`, `lua/custom/commands.lua`: non-plugin keymaps, commands, autocmds.
- `lua/custom/{edge-flash,keybrowser,mdx,telescope-tutorial}.lua`, `after/`: copied verbatim.
- `flake.nix`: the wrapper and every external tool the config references.

## Benchmark

```sh
nvim-min --headless -c 'luafile ~/.config/nvim-min/bench.lua'
```

Opens a file in dev-setup (nix), blackjack-auto (typescript), decision-server (python)
and octane-tools (svelte + biome), and checks treesitter highlighting, server attach,
go-to-definition, document symbols and workspace symbols. Exit code 1 on any failure.

## Big or minified files

A 6.6 MB single-line JSON costs 635 ms per edit: after every change treesitter
re-highlights the whole visible line and jsonls re-validates the document. There is no
config for this on purpose. Either give the file lines first (`jq . in.json > out.json`)
or open it with nothing loaded: `nvim-min --clean file.json`.

## Completion keys

| Key | What |
| --- | --- |
| typing | LSP menu opens, documentation in a side popup |
| `<Tab>` | accept highlighted item (first item if none highlighted), or next snippet field |
| `<S-Tab>` | previous snippet field |
| `<C-n>` / `<C-p>` | move in the menu, or buffer-word completion when closed |
| `<C-e>` | dismiss |
| `<C-x><C-f>` | file paths |
| `<C-x><C-o>` | omnifunc, e.g. dadbod completion in sql |
| `<C-s>` | signature help |

## Updating plugins

`:lua vim.pack.update()` shows a diff buffer; `:write` to accept. Commit `nvim-pack-lock.json`.
