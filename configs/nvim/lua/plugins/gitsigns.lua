require('gitsigns').setup {
  signs = {
    add = { text = '+' },
    change = { text = '~' },
    delete = { text = '_' },
    topdelete = { text = '‾' },
    changedelete = { text = '~' },
  },
}
vim.keymap.set('n', ']c', function()
  if vim.wo.diff then
    vim.cmd.normal { vim.v.count1 .. ']c', bang = true }
    return
  end
  require('gitsigns').nav_hunk 'next'
end, { desc = 'Jump to next git change' })
vim.keymap.set('n', '[c', function()
  if vim.wo.diff then
    vim.cmd.normal { vim.v.count1 .. '[c', bang = true }
    return
  end
  require('gitsigns').nav_hunk 'prev'
end, { desc = 'Jump to previous git change' })
