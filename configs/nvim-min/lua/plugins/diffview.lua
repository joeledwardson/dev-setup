require('diffview').setup {}

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
