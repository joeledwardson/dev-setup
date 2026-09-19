require('diffview').setup {
  hooks = {
    -- Diffview sets `foldmethod=diff` on its windows, which folds everything
    -- outside `diffopt` context and leaks a stuck `foldmethod=diff` into any
    -- window split off the diff window. Use manual folds so ufo/treesitter
    -- folds the diff by function instead.
    diff_buf_win_enter = function(_, winid)
      vim.wo[winid].foldmethod = 'manual'
      vim.wo[winid].foldlevel = 99
    end,
  },
}

vim.keymap.set('n', '<leader>tv', function()
  local lib = require 'diffview.lib'
  if lib.get_current_view() then
    vim.cmd 'DiffviewClose'
  else
    vim.cmd 'DiffviewOpen'
  end
end, { desc = 'Toggle diff view' })
vim.keymap.set('n', '<leader>tg', function()
  local lib = require 'diffview.lib'
  if lib.get_current_view() then
    vim.cmd 'DiffviewClose'
  else
    vim.cmd 'DiffviewFileHistory %'
  end
end, { desc = 'Toggle diff file history' })
vim.keymap.set('n', '<leader>tG', function()
  local lib = require 'diffview.lib'
  if lib.get_current_view() then
    vim.cmd 'DiffviewClose'
  else
    vim.cmd 'DiffviewFileHistory'
  end
end, { desc = 'Toggle diff global history' })
