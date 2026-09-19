-- Keymaps that do not belong to a plugin. Plugin keymaps live next to their setup in lua/core/.

vim.keymap.set('n', '<Esc>', '<cmd>noh<cr><esc>', { desc = 'Clear hlsearch' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Diagnostics to location list' })
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

vim.keymap.set('n', '<leader>[', ':tabprevious<CR>', { desc = 'previous tab' })
vim.keymap.set('n', '<leader>]', ':tabnext<CR>', { desc = 'next tab' })

-- Keep visual selection after shifting.
vim.keymap.set('v', '>', '>gv', { noremap = true })
vim.keymap.set('v', '<', '<gv', { noremap = true })
vim.keymap.set('n', '<M-H>', '<Nop>', { noremap = true })

-- Undo break points while typing.
vim.keymap.set('i', '<Space>', '<C-G>u<Space>', { noremap = true, silent = true })
vim.keymap.set('i', '<CR>', '<C-G>u<CR>', { noremap = true, silent = true })

vim.keymap.set({ 'v' }, 'Y', "y']", { desc = 'Yank and move to end ' })
vim.keymap.set({ 'n', 'v' }, 'D', '"_d', { desc = 'delete to null buffer' })
vim.keymap.set('n', '<leader>Y', function()
  vim.fn.setreg('+', vim.fn.expand '%:p')
end, { desc = 'yank current file path to clipboard register' })

-- Normal-mode counterpart to core's <C-S>, which only covers insert and select mode.
vim.keymap.set({ 'n' }, '<Leader>ts', function()
  vim.lsp.buf.signature_help()
end, { silent = true, noremap = true, desc = 'show signature help' })
vim.keymap.set('n', '<leader>se', function()
  vim.diagnostic.open_float { focusable = true, focus = true }
end, { desc = 'open diagnostic' })

vim.keymap.set('n', 'zX', function()
  local lineNumber = vim.fn.line '.'
  local foldClosedLine = vim.fn.foldclosed(lineNumber)
  if foldClosedLine ~= -1 then
    vim.cmd 'normal! zO'
    return
  end
  vim.cmd 'normal! zczO'
end, { desc = 'jollof recursive fold opener' })

local url_pattern = [[https:\S\+]]
-- [l / ]l are Neovim's location-list navigation mappings.
vim.keymap.set('n', ']u', function()
  vim.fn.setreg('/', url_pattern)
  vim.opt.hlsearch = true
  vim.fn.search(url_pattern, 'W')
end, { desc = 'Next URL' })
vim.keymap.set('n', '[u', function()
  vim.fn.setreg('/', url_pattern)
  vim.opt.hlsearch = true
  vim.fn.search(url_pattern, 'bW')
end, { desc = 'Previous URL' })

-- Window resize "mode": + - < > resize until any other key is pressed.
vim.g.resize_mode = false
vim.keymap.set('n', '<C-w>r', function()
  vim.g.resize_mode = true
  while true do
    vim.api.nvim__redraw { flush = true, cursor = true, win = 0, statusline = true }
    local ok, key = pcall(vim.fn.getcharstr)
    if not ok then
      break
    end
    if key == '+' or key == '=' then
      vim.cmd 'resize +5'
    elseif key == '-' then
      vim.cmd 'resize -5'
    elseif key == '>' then
      vim.cmd 'vertical resize +5'
    elseif key == '<' then
      vim.cmd 'vertical resize -5'
    else
      break
    end
  end
  vim.g.resize_mode = false
  vim.api.nvim__redraw { flush = true, cursor = true, win = 0, statusline = true }
end, { desc = 'window resize mode' })

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('python-run-keymap', { clear = true }),
  pattern = 'python',
  callback = function(event)
    -- Keep <F5> for DAP, including after visiting a Python buffer.
    vim.keymap.set('n', '<leader>rp', function()
      local file_path = vim.fn.expand '%:p'
      vim.cmd('split | terminal PYTHONPATH=. python ' .. vim.fn.shellescape(file_path))
    end, { buffer = event.buf, desc = 'Run Python file' })
  end,
})
