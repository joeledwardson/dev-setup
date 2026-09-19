require('oil').setup {
  keymaps = {
    ['<C-l>'] = false, -- disable refresh; frees <C-l> for zellij-nav
  },
}
vim.keymap.set('n', '<leader>o', function()
  require('oil').open()
end, { desc = 'Open Oil' })
vim.keymap.set('n', '<leader>O', function()
  require('oil').open(nil, { preview = { vertical = true } })
end, { desc = 'Open Oil --preview' })
