-- User commands, autocmds and helpers that do not belong to a plugin.

vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

vim.api.nvim_create_autocmd('FileChangedShellPost', {
  pattern = '*',
  callback = function()
    vim.notify('File changed on disk. Buffer reloaded.', vim.log.levels.WARN)
  end,
})

vim.api.nvim_create_user_command('PrintServerCapabilities', function()
  local currentbuf = vim.api.nvim_get_current_buf()
  local clients = vim.lsp.get_clients { bufnr = currentbuf }
  local lines = {}
  for i, client in ipairs(clients) do
    table.insert(lines, 'client ' .. i .. ': ' .. client.name)
    local server_caps = client.server_capabilities
    local formatted = vim.inspect(server_caps)
    for _, line in ipairs(vim.split(formatted, '\n')) do
      table.insert(lines, line)
    end
    table.insert(lines, '------------------------------------')
  end
  local newbuf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_text(newbuf, 0, 0, 0, 0, lines)
  vim.api.nvim_win_set_buf(0, newbuf)
  vim.bo.filetype = 'lua'
end, {})

vim.api.nvim_create_user_command('Bufferize', function(opts)
  local lines = {}
  local out = vim.fn.execute(opts.fargs)
  for _, line in ipairs(vim.split(out, '\n')) do
    table.insert(lines, line)
  end
  vim.cmd.tabnew()
  local newbuf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(0, newbuf)
  vim.api.nvim_buf_set_text(newbuf, 0, 0, 0, 0, lines)
end, { nargs = '+', complete = 'command' })

vim.api.nvim_create_user_command('PrintFoldLevel', function()
  local line = vim.fn.line '.'
  local level = vim.fn.foldlevel(line)
  vim.api.nvim_echo({ { 'Fold level on line ' .. line .. ' is ' .. level } }, true, {})
end, {})

vim.api.nvim_create_autocmd('BufEnter', {
  pattern = { '*.service', '*.socket', '*.mount', '*.device', '*.nspawn', '*.target', '*.timer' },
  callback = function()
    vim.bo.filetype = 'systemd'
    vim.lsp.start {
      name = 'systemd_ls',
      cmd = { 'systemd-lsp' },
      root_dir = vim.fn.getcwd(),
    }
  end,
})

-- foo.yaml.j2 -> filetype yaml
vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
  pattern = '*.j2',
  callback = function()
    local inner = vim.fn.expand('%:r'):match '%.([^.]+)$'
    if inner then
      vim.bo.filetype = inner
    end
  end,
})

vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
  pattern = { '/tmp/*.dump', '/tmp/tmux-scrollback*' },
  callback = function()
    vim.bo.filetype = 'bash'
  end,
})

function PrintBufs(log)
  log = log or print
  local current_buf = vim.api.nvim_get_current_buf()
  local pages = vim.api.nvim_list_tabpages()
  for pageindex, pageid in ipairs(pages) do
    log('--- page ' .. pageindex .. ' (ID ' .. pageid .. ') ---')
    local pagewins = vim.api.nvim_tabpage_list_wins(pageid)
    for win_index, win_id in ipairs(pagewins) do
      log('  window #' .. win_index .. ', ID: ' .. win_id)
      log(vim.api.nvim_win_get_config(win_id))
      log('  win_type: ' .. vim.fn.win_gettype(win_id))
      local buf_id = vim.api.nvim_win_get_buf(win_id)
      local bo = vim.bo[buf_id]
      log {
        buf_id = buf_id,
        valid = vim.api.nvim_buf_is_valid(buf_id),
        ft = bo.filetype,
        bt = bo.buftype,
        name = vim.api.nvim_buf_get_name(buf_id),
        listed = bo.buflisted,
        active = current_buf == buf_id,
      }
    end
  end
end
