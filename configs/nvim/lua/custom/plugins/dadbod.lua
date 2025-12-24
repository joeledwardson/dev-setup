return {
  {
    'kristijanhusak/vim-dadbod-ui',
    dependencies = {
      { 'tpope/vim-dotenv', lazy = true },
      { 'tpope/vim-dadbod', lazy = true },
      { 'kristijanhusak/vim-dadbod-completion', lazy = true },
    },
    cmd = {
      'DBUI',
      'DBUIToggle',
      'DBUIAddConnection',
      'DBUIFindBuffer',
    },
    init = function()
      vim.g.db_ui_use_nerd_fonts = 1
      vim.g.db_ui_winwidth = 30
      vim.g.db_ui_show_help = 0
      vim.g.db_ui_use_nvim_notify = 1
      vim.g.db_ui_win_position = 'left'

      vim.keymap.set('n', '<leader>Df', '<cmd>DBUIFindBuffer<cr>', { desc = '[D]B [f]ind buffer' })
      vim.keymap.set('n', '<leader>Dl', '<cmd>DBUILastQueryInfo<cr>', { desc = '[D]B [l]ast query infos' })
      vim.keymap.set('n', '<leader>Dr', '<cmd>DBUIRenameBuffer<cr>', { desc = '[D]B [r]ename buffer' })
      vim.keymap.set('n', '<leader>Du', '<cmd>DBUIToggle<cr>', { desc = '[D]B [t]oggle' })
      -- }
      --
      -- Save query keybinding (works in sql buffers)
      vim.keymap.set('n', '<leader>Ds', '<Plug>(DBUI_SaveQuery)', { desc = '[D]B [S]ave query permanently' })
    end,
    config = function()
      -- Setup completion only for dadbod UI buffers
      vim.api.nvim_create_autocmd('FileType', {
        pattern = { 'sql', 'mysql', 'plsql' },
        callback = function()
          -- Only enable completion if this is a dadbod buffer
          if vim.b.db or vim.b.dbui then
            require('cmp').setup.buffer { sources = { { name = 'vim-dadbod-completion' } } }
          end
        end,
      })
    end,
  },
}
