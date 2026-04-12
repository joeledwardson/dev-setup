return {
  'stevearc/oil.nvim',
  ---@module 'oil'
  ---@type oil.SetupOpts
  opts = {
    keymaps = {
      ['<C-l>'] = false, -- disable refresh; frees <C-l> for zellij-nav
    },
  },
  keys = {
    { '<leader>o', function() require('oil').open() end, desc = 'Open Oil' },
    { '<leader>O', function() require('oil').open(nil, { preview = { vertical = true } }) end, desc = 'Open Oil --preview' },
  },
  -- Optional dependencies
  dependencies = { { 'echasnovski/mini.icons', opts = {} } },
  -- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if you prefer nvim-web-devicons
  -- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
  lazy = false,
}
