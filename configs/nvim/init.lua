-- simplified configuration for neovim 0.12

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
-- ahh this is the chars that appear in place of hidden characters
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
vim.o.inccommand = 'split'
vim.o.cursorline = true
vim.o.scrolloff = 10
-- fuck knows, some thing to stop nvim poppuping up with random menus
vim.o.completeopt = 'menuone,noselect,popup,fuzzy'
vim.o.autoindent = true
-- removed the 'smartindent' option as it breaks on nixos (# comments get moved to start col)
vim.o.expandtab = true
vim.o.shiftwidth = 2
vim.o.tabstop = 2
vim.o.termsync = false
vim.o.autoread = true
vim.o.swapfile = false
vim.opt.iskeyword:append '-'
vim.opt.diffopt:append 'context:3'

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
-- Order matters only for dependencies: a plugin is listed after what it requires.
-- confirm = false: install without prompting so a headless first run works.
vim.pack.add({
  'https://github.com/olimorris/onedarkpro.nvim',
  'https://github.com/nvim-lua/plenary.nvim',
  'https://github.com/nvim-mini/mini.nvim',
  'https://github.com/tpope/vim-sleuth',
  'https://github.com/lewis6991/gitsigns.nvim',
  'https://github.com/folke/which-key.nvim',
  -- 0.1.x calls nvim-treesitter's removed `parsers.ft_to_lang`; 0.2.x uses core vim.treesitter.
  -- A version *range* must be vim.version.range(); a bare string is read as a branch/tag/commit.
  { src = 'https://github.com/nvim-telescope/telescope.nvim', version = vim.version.range '0.2' },
  'https://github.com/nvim-telescope/telescope-ui-select.nvim',
  'https://github.com/nvim-telescope/telescope-live-grep-args.nvim',
  -- Snippet bodies for blink's `snippets` source. Blink itself is built by Nix, but it
  -- picks this up by scanning the runtimepath, so it only has to be present, not configured.
  'https://github.com/rafamadriz/friendly-snippets',
  'https://github.com/neovim/nvim-lspconfig', -- server definitions only (lsp/*.lua); the client is built in
  'https://github.com/j-hui/fidget.nvim',
  'https://github.com/b0o/schemastore.nvim',
  'https://github.com/stevearc/conform.nvim',
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
  'https://github.com/aaronik/treewalker.nvim',
  'https://github.com/chentoast/marks.nvim',
  { src = 'https://github.com/ThePrimeagen/harpoon', version = 'harpoon2' },
  'https://github.com/kevinhwang91/nvim-bqf',
  'https://github.com/kevinhwang91/promise-async',
  'https://github.com/kevinhwang91/nvim-ufo',
  'https://github.com/MeanderingProgrammer/render-markdown.nvim',
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

require('todo-comments').setup {}
require('treewalker').setup {}
require('marks').setup {}
require('bqf').setup {}

require('render-markdown').setup {
  file_types = { 'markdown', 'mdx' },
  heading = {
    icons = { '', '', '', '', '', '' },
    backgrounds = { 'RenderMarkdownH1Bg', 'RenderMarkdownH2Bg', '', '', '', '' },
    border = false,
    position = 'inline',
    sign = false,
  },
  bullet = {
    icons = { ' ◉  ', '  ◦  ', '   ▪  ', '    ▫  ' },
  },
}
vim.keymap.set('n', '<leader>tm', function()
  require('render-markdown').toggle()
end, { desc = 'toggle markdown render' })

require 'plugins.theme'
require 'plugins.whichkey'
require 'plugins.mini' -- before telescope: mini.icons stands in for nvim-web-devicons
require 'plugins.completion' -- before LSP servers start so they receive Blink's capabilities
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

require 'custom.keymaps'
require 'custom.commands'
require('custom.edge-flash').setup()
require('custom.mdx').setup()

vim.o.exrc = true
