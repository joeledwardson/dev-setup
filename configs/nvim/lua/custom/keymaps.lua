-- Treewalker "mode": hjkl walk the syntax tree until any other key is pressed.
vim.g.treewalker_mode = false
vim.keymap.set('n', '<Leader>w', function()
  vim.g.treewalker_mode = true
  while true do
    vim.api.nvim__redraw { flush = true, cursor = true, win = 0, statusline = true }
    local ok, key = pcall(vim.fn.getcharstr)
    if not ok then
      break
    end
    if key == 'k' then
      vim.cmd 'Treewalker Up'
    elseif key == 'j' then
      vim.cmd 'Treewalker Down'
    elseif key == 'h' then
      vim.cmd 'Treewalker Left'
    elseif key == 'l' then
      vim.cmd 'Treewalker Right'
    else
      break
    end
  end
  vim.g.treewalker_mode = false
  vim.api.nvim__redraw { flush = true, cursor = true, win = 0, statusline = true }
end, { desc = 'treewalker mode' })
