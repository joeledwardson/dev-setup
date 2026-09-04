vim.g.disable_autoformat = true

-- Prefer Biome for JS/TS/JSON when the project ships a biome config; otherwise
-- fall back to Prettier. Both are picked up from the repo's node_modules/.bin
-- when present. Biome doesn't fully format .svelte, so Svelte stays on Prettier.
local function web_formatter(bufnr)
  local dir = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ':h')
  if #vim.fs.find({ 'biome.json', 'biome.jsonc' }, { upward = true, path = dir }) > 0 then
    return { 'biome' }
  end
  return { 'prettier' }
end

require('conform').setup {
  log_level = vim.log.levels.DEBUG,
  notify_on_error = false,
  format_on_save = function(bufnr)
    if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
      return
    end
    local disable_filetypes = { c = true, cpp = true }
    local lsp_format_opt
    if disable_filetypes[vim.bo[bufnr].filetype] then
      lsp_format_opt = 'never'
    else
      lsp_format_opt = 'fallback'
    end
    return {
      timeout_ms = 5000,
      lsp_format = lsp_format_opt,
    }
  end,
  formatters_by_ft = {
    sql = { 'sql_formatter' },
    nix = { 'nixfmt' },
    lua = { 'stylua' },
    -- html_beautify (a Ruby gem Mason installed) is not in nixpkgs; prettier handles both.
    html = { 'prettier', stop_after_first = true },
    css = { 'prettier', stop_after_first = true },
    json = web_formatter,
    javascript = web_formatter,
    typescript = web_formatter,
    javascriptreact = web_formatter,
    typescriptreact = web_formatter,
    svelte = { 'prettier', stop_after_first = true },
    bash = { 'shfmt', 'shellcheck' },
    zsh = { 'shfmt', 'shellcheck' },
    sh = { 'shfmt', 'shellcheck' },
    python = { 'ruff_format' },
  },
  formatters = {
    sql_formatter = {
      prepend_args = { '--language', 'postgresql' },
    },
    prettier = {
      env = {
        FORCE_COLOR = '0',
      },
    },
    prettier_sql = {
      command = 'prettier',
      args = { '--language', 'postgresql', '--stdin-filepath', '$FILENAME' },
      stdin = true,
      env = {
        FORCE_COLOR = '0',
      },
    },
  },
}

vim.api.nvim_create_user_command('FormatDisable', function(args)
  if args.bang then
    vim.b.disable_autoformat = true
  else
    vim.g.disable_autoformat = true
  end
end, {
  desc = 'Disable autoformat-on-save',
  bang = true, -- allows the ! variant
})
vim.api.nvim_create_user_command('FormatEnable', function()
  vim.b.disable_autoformat = false
  vim.g.disable_autoformat = false
end, {
  desc = 'Re-enable autoformat-on-save',
})

vim.keymap.set('', '<leader>F', function()
  require('conform').format({ async = true, lsp_format = 'fallback' }, function(err, did_edit)
    if err then
      vim.notify('oh dear, conform is not happy!', 'error')
      vim.notify(err, 'error')
    end
    if not err and not did_edit then
      print 'no changes to format'
    end
  end)
end, { desc = '[F]ormat buffer' })
vim.keymap.set('n', '<leader>tf', function()
  if vim.b.disable_autoformat then
    vim.cmd 'FormatEnable'
    vim.notify 'Enabled autoformat for current buffer'
  else
    vim.cmd 'FormatDisable!'
    vim.notify 'Disabled autoformat for current buffer'
  end
end, { desc = 'Toggle autoformat for current buffer' })
vim.keymap.set('n', '<leader>tF', function()
  if vim.g.disable_autoformat then
    vim.cmd 'FormatEnable'
    vim.notify 'Enabled autoformat globally'
  else
    vim.cmd 'FormatDisable'
    vim.notify 'Disabled autoformat globally'
  end
end, { desc = 'Toggle autoformat globally' })
