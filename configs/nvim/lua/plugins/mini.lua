require('mini.icons').setup()
MiniIcons.mock_nvim_web_devicons() -- telescope asks for nvim-web-devicons; answer with mini.icons
require('mini.ai').setup { n_lines = 500 }
require('mini.surround').setup()

local statusline = require 'mini.statusline'
statusline.setup { use_icons = vim.g.have_nerd_font }
local original_section_mode = statusline.section_mode
statusline.section_mode = function(args)
  if vim.g.resize_mode then
    return 'RESIZE', 'MiniStatuslineModeOther'
  end
  if vim.g.treewalker_mode then
    return 'TREEWALKER', 'MiniStatuslineModeOther'
  end
  return original_section_mode(args)
end
statusline.section_location = function()
  return '%2l:%-2v'
end

local mini_files = require 'mini.files'
mini_files.setup {
  windows = { preview = true, width_focus = 28, width_preview = 50 },
}
vim.api.nvim_create_autocmd('User', {
  pattern = 'MiniFilesBufferCreate',
  callback = function(event)
    vim.keymap.set('n', '<CR>', function()
      mini_files.go_in { close_on_file = true }
    end, { buffer = event.data.buf_id, desc = 'open entry (close explorer on file)' })
  end,
})
vim.keymap.set('n', '<leader>E', function()
  local current = vim.api.nvim_buf_get_name(0)
  mini_files.open(current ~= '' and current or nil)
end, { desc = 'mini.files explorer (miller columns)' })
