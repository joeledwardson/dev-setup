-- The daily-driver config, on Neovim 0.12 idioms.
--   * vim.pack instead of lazy.nvim (plugins load eagerly; lockfile is nvim-pack-lock.json)
--   * vim.lsp.enable + nvim-lspconfig definitions instead of Mason (servers come from modules/nixos-base.nix)
--   * nvim-treesitter `main` instead of `master` (the API change that broke 0.12 last time)
--
-- Layout: options here, keymaps/commands in lua/custom/, one file per plugin group in
-- lua/plugins/. `nvim` is a wrapper (modules/nixos-base.nix) that puts the servers on PATH.

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.g.have_nerd_font = true

-- Options ------------------------------------------------------------------
vim.o.number = true
vim.o.relativenumber = true
vim.o.mouse = 'a'
vim.o.showmode = false
vim.o.breakindent = true
vim.o.undofile = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.signcolumn = 'yes'
vim.o.updatetime = 250
vim.o.timeoutlen = 300
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
vim.o.inccommand = 'split'
vim.o.cursorline = true
vim.o.scrolloff = 10
vim.o.completeopt = 'menuone,noselect,popup,fuzzy' -- popup = documentation window next to the menu
vim.o.autoindent = true
vim.o.smartindent = true
vim.o.expandtab = true
vim.o.shiftwidth = 2
vim.o.tabstop = 2
vim.o.termsync = false
vim.o.autoread = true
vim.o.swapfile = false
vim.opt.iskeyword:append '-'

-- Clipboard: system clipboard when a display is present, OSC52 over SSH.
local function has_system_clipboard()
  return (vim.fn.executable 'wl-copy' == 1 and vim.env.WAYLAND_DISPLAY ~= nil)
    or ((vim.fn.executable 'xclip' == 1 or vim.fn.executable 'xsel' == 1) and vim.env.DISPLAY ~= nil)
    or vim.fn.executable 'pbcopy' == 1
end
if has_system_clipboard() then
  vim.o.clipboard = 'unnamedplus'
end
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    require('vim.ui.clipboard.osc52').copy '+'(vim.v.event.regcontents)
  end,
})

-- Plugins -------------------------------------------------------------------
-- Build steps that lazy.nvim used to run via `build = ...`.
vim.api.nvim_create_autocmd('PackChanged', {
  callback = function(event)
    local name, kind = event.data.spec.name, event.data.kind
    if kind ~= 'install' and kind ~= 'update' then
      return
    end
    if name == 'telescope-fzf-native.nvim' then
      vim.system({ 'make' }, { cwd = event.data.path }):wait()
    end
    if name == 'nvim-treesitter' and kind == 'update' then
      vim.cmd 'TSUpdate'
    end
  end,
})

-- Order matters only for dependencies: a plugin is listed after what it requires.
-- confirm = false: install without prompting so a headless first run works.
vim.pack.add({
  'https://github.com/olimorris/onedarkpro.nvim',
  'https://github.com/nvim-lua/plenary.nvim',
  'https://github.com/nvim-mini/mini.nvim',
  'https://github.com/tpope/vim-sleuth',
  'https://github.com/lewis6991/gitsigns.nvim',
  'https://github.com/folke/which-key.nvim',
  { src = 'https://github.com/nvim-telescope/telescope.nvim', version = '0.1.x' },
  'https://github.com/nvim-telescope/telescope-fzf-native.nvim',
  'https://github.com/nvim-telescope/telescope-ui-select.nvim',
  'https://github.com/nvim-telescope/telescope-live-grep-args.nvim',
  'https://github.com/neovim/nvim-lspconfig', -- server definitions only (lsp/*.lua); the client is built in
  'https://github.com/j-hui/fidget.nvim',
  'https://github.com/b0o/schemastore.nvim',
  'https://github.com/stevearc/conform.nvim',
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter', version = 'main' },
  'https://github.com/nvim-treesitter/nvim-treesitter-context',
  'https://github.com/DariusCorvus/tree-sitter-language-injection.nvim',
  'https://github.com/fionn/nvim-hujson',
  'https://github.com/kevalin/mermaid.nvim',
  'https://github.com/mfussenegger/nvim-dap',
  'https://github.com/nvim-neotest/nvim-nio',
  'https://github.com/rcarriga/nvim-dap-ui',
  'https://github.com/folke/todo-comments.nvim',
  'https://github.com/grafana/vim-alloy',
  'https://github.com/mfussenegger/nvim-ansible',
  'https://github.com/gbprod/yanky.nvim',
  'https://github.com/sQVe/sort.nvim',
  'https://github.com/aaronik/treewalker.nvim',
  'https://github.com/chentoast/marks.nvim',
  { src = 'https://github.com/ThePrimeagen/harpoon', version = 'harpoon2' },
  'https://github.com/kevinhwang91/nvim-bqf',
  'https://github.com/kevinhwang91/promise-async',
  'https://github.com/kevinhwang91/nvim-ufo',
  'https://github.com/MeanderingProgrammer/render-markdown.nvim',
  'https://github.com/MagicDuck/grug-far.nvim',
  'https://github.com/tpope/vim-dotenv',
  'https://github.com/tpope/vim-dadbod',
  'https://github.com/kristijanhusak/vim-dadbod-completion',
  'https://github.com/kristijanhusak/vim-dadbod-ui',
  'https://github.com/sindrets/diffview.nvim',
  'https://github.com/tpope/vim-fugitive',
  'https://github.com/yarospace/lua-console.nvim',
  'https://github.com/stevearc/oil.nvim',
  'https://github.com/joeledwardson/joels-lua-utils',
  'https://github.com/epheien/outline-treesitter-provider.nvim',
  'https://github.com/hedyhli/outline.nvim',
  'https://github.com/Shatur/neovim-session-manager',
  'https://github.com/folke/trouble.nvim',
}, { confirm = false })

require 'plugins.theme'
require 'plugins.whichkey'
require 'plugins.mini' -- before telescope: mini.icons stands in for nvim-web-devicons
require 'plugins.telescope'
require 'plugins.lsp'
require 'plugins.conform'
require 'plugins.treesitter'
require 'plugins.gitsigns'
require 'plugins.dap'
require 'plugins.harpoon'
require 'plugins.ufo'
require 'plugins.dadbod'
require 'plugins.diffview'
require 'plugins.oil'
require 'plugins.outline'
require 'plugins.session'
require 'plugins.trouble'
require 'plugins.lua-console'
require 'plugins.misc'

require 'custom.keymaps'
require 'custom.commands'
require('custom.edge-flash').setup()
require('custom.mdx').setup()

vim.o.exrc = true
