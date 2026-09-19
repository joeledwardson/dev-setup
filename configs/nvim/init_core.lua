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
-- dont save ufo folds in sessions or it breaks
vim.opt.sessionoptions:remove 'folds'

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
  'https://github.com/folke/which-key.nvim',
  -- 0.2.x uses core vim.treesitter instead of nvim-treesitter's removed ft_to_lang.
  { src = 'https://github.com/nvim-telescope/telescope.nvim', version = vim.version.range '0.2' },
  'https://github.com/nvim-telescope/telescope-ui-select.nvim',
  'https://github.com/nvim-telescope/telescope-live-grep-args.nvim',
  'https://github.com/j-hui/fidget.nvim',
  'https://github.com/nvim-treesitter/nvim-treesitter-context',
  'https://github.com/kevinhwang91/promise-async',
  'https://github.com/kevinhwang91/nvim-ufo',
  'https://github.com/sindrets/diffview.nvim',
  'https://github.com/tpope/vim-fugitive',
  'https://github.com/stevearc/oil.nvim',
}, { confirm = false })

require 'core.theme'
require 'core.whichkey'
require 'core.mini' -- before Telescope: mini.icons provides nvim-web-devicons
require 'core.telescope'
require('fidget').setup { notification = { override_vim_notify = true } }
require 'core.treesitter'
require 'core.ufo'
require 'core.diffview'
require 'core.oil'
require 'core.keymaps'
require 'core.commands'
require('core.edge-flash').setup()

vim.o.exrc = true
