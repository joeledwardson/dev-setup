
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
