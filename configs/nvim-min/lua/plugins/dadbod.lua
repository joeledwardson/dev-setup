vim.g.db_ui_use_nerd_fonts = 1
vim.g.db_ui_winwidth = 30
vim.g.db_ui_show_help = 0
vim.g.db_ui_use_nvim_notify = 1
vim.g.db_ui_win_position = 'left'

vim.keymap.set('n', '<leader>Df', '<cmd>DBUIFindBuffer<cr>', { desc = '[D]B [f]ind buffer' })
vim.keymap.set('n', '<leader>Dl', '<cmd>DBUILastQueryInfo<cr>', { desc = '[D]B [l]ast query infos' })
vim.keymap.set('n', '<leader>Dr', '<cmd>DBUIRenameBuffer<cr>', { desc = '[D]B [r]ename buffer' })
vim.keymap.set('n', '<leader>Du', '<cmd>DBUIToggle<cr>', { desc = '[D]B [t]oggle' })
vim.keymap.set('n', '<leader>Ds', '<Plug>(DBUI_SaveQuery)', { desc = '[D]B [S]ave query permanently' })
vim.keymap.set('n', '<leader>Dv', '<Plug>(DBUI_SelectLineVsplit)', { desc = '[t]oggle [D]adbod UI' })
