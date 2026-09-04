-- Sessions are per directory. Skip entirely when editing scratch files under /tmp.
for _, arg in ipairs(vim.fn.argv()) do
  if arg:match '^/tmp/' then
    return
  end
end

local Path = require 'plenary.path'
require('session_manager').setup {
  autoload_mode = require('session_manager.config').AutoloadMode.CurrentDir,
  sessions_dir = Path:new(vim.fn.stdpath 'data', 'sessions'),
  autosave_last_session = true,
  autosave_ignore_not_normal = false,
  autosave_ignore_dirs = { '/tmp' },
  autosave_ignore_filetypes = {
    'gitcommit',
    'gitrebase',
  },
  autosave_ignore_buftypes = {},
  autosave_only_in_session = false,
  max_path_length = 80,
}

vim.keymap.set('n', '<leader>pl', '<cmd>SessionManager load_session<CR>', { desc = '📌 Load session' })
vim.keymap.set('n', '<leader>ps', '<cmd>SessionManager save_current_session<CR>', { desc = '📌 Save session' })
vim.keymap.set('n', '<leader>pd', '<cmd>SessionManager delete_session<CR>', { desc = '📌 Delete session' })
vim.keymap.set('n', '<leader>px', '<cmd>SessionManager delete_current_dir_session<CR>', { desc = '📌 Delete current session' })
