return {
  'folke/noice.nvim',
  dependencies = {
    'MunifTanjim/nui.nvim',
    'rcarriga/nvim-notify',
  },
  config = function()
    require('noice').setup {
      lsp = {
        hover = {
          enabled = true,
          silent = false,
          view = 'hover', -- Options: hover, popup, split
        },
        signature = {
          enabled = true,
          auto_open = {
            enabled = false, -- Disable auto-popup
            trigger = false, -- Disable triggering
            luasnip = false, -- Disable for luasnip
          },
          view = 'hover',
        },
      },
    }
  end,
}
