-- JOLLOF SPECIFIC CONFIGURATIONS
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.ignorecase = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.number = true
-- alt shift H is used by tmux for window switching
vim.keymap.set('n', '<M-H>', '<Nop>', { noremap = true })
-- vim.api.nvim_set_keymap('i', '<C-b>', 'cmp#complete()', { noremap = true, expr = true })
-- folds
vim.opt.foldmethod = 'expr'
vim.opt.foldexpr = 'nvim_treesitter#foldexpr()'
vim.opt.foldenable = true
vim.opt.foldlevel = 99 -- start with all folds open
vim.opt.foldlevelstart = 99 -- start with all folds open
vim.keymap.set('n', 'zO', 'zxzczA', { desc = 'Open fold and enter insert' })

-- Window focus highlighting (NC = Non-Current/inactive windows)
vim.api.nvim_create_autocmd({ 'WinEnter', 'BufEnter' }, {
  callback = function()
    vim.api.nvim_set_hl(0, 'NormalNC', { bg = '#302b10' }) -- inactive windows
    vim.api.nvim_set_hl(0, 'Normal', { bg = 'NONE' }) -- active window stays default
  end,
})

-- Command mode highlighting (keeping your original)
vim.api.nvim_create_autocmd('CmdlineEnter', {
  callback = function()
    -- vim.api.nvim_set_hl(0, 'Normal', { bg = '#302b10' })
  end,
})

vim.api.nvim_create_autocmd('CmdlineLeave', {
  callback = function()
    -- vim.api.nvim_set_hl(0, 'Normal', { fg = 'NONE', bg = 'NONE' })
  end,
})

-- vim.keymap.set({ 'n' }, '<C-k>', function()
--   require('lsp_signature').toggle_float_win()
-- end, { silent = true, noremap = true, desc = 'toggle signature' })

vim.keymap.set({ 'n' }, '<Leader>k', function()
  vim.lsp.buf.signature_help()
end, { silent = true, noremap = true, desc = 'toggle signature' })

vim.keymap.set('n', ']r', ':cnext<CR>zz', { desc = 'Next reference' })
vim.keymap.set('n', '[r', ':cprev<CR>zz', { desc = 'Previous reference' })

-- use poetry executable as python path (if exists)
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client == nil or client.name == nil or client.name ~= 'pyright' then
      return
    end

    local venv = vim.env.VIRTUAL_ENV
    if not venv or venv == '' then
      return
    end

    local executable = vim.fn.system({ 'poetry', 'env', 'info', '--executable' }):gsub('%s+$', '')
    print 'got python executable'
    if not executable or executable == '' then
      return
    end

    if vim.fn.filereadable(executable) ~= 1 then
      print('executable is not a valid file? ', executable)
      return
    end

    -- Update Pyright config using the LSP protocol directly
    client.config.settings = client.config.settings or {}
    client.config.settings.python = client.config.settings.python or {}
    client.config.settings.python.pythonPath = executable

    -- Notify the server about the updated configuration
    client.notify('workspace/didChangeConfiguration', {
      settings = client.config.settings,
    })
  end,
})

vim.keymap.set('n', '<Esc>', function()
  vim.cmd 'nohlsearch' -- Clear search highlighting
  require('notify').dismiss()
end, { desc = 'dismiss notify popup and clear hlsearch' })

vim.keymap.set('n', '<leader>e', function()
  vim.diagnostic.open_float { focusable = true, focus = true }
end, { desc = 'open diagnostic' })

-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return {
  {
    'y3owk1n/undo-glow.nvim',
    version = '*', -- remove this if you want to use the `main` branch
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    },
  },
}
