return {
  {
    'sindrets/diffview.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      require('diffview').setup {
        -- Optional: Add any specific configuration here
      }
    end,
    lazy = false,
    keys = {
      {
        '<leader>tv',
        function()
          local lib = require 'diffview.lib'
          if lib.get_current_view() then
            vim.cmd 'DiffviewClose'
          else
            vim.cmd 'DiffviewOpen'
          end
        end,
        desc = 'Toggle diff view',
      },
    },
  },
}
