-- nvim-treesitter `main`: it only installs parsers and queries. Highlighting, folding
-- and indentation are switched on per buffer below (see :h treesitter-highlight).

-- c, lua, markdown, markdown_inline, query, vim, vimdoc ship with nvim itself.
local treesitter_languages = {
  'bash', 'css', 'diff', 'dockerfile', 'go', 'hcl', 'html', 'javascript', 'json', 'luadoc',
  'nix', 'python', 'regex', 'scss', 'sql', 'svelte', 'terraform', 'toml', 'tsx', 'typescript', 'yaml',
}
require('nvim-treesitter').install(treesitter_languages) -- async, no-op once installed

vim.api.nvim_create_autocmd('FileType', {
  desc = 'Enable treesitter highlighting and indentation when a parser exists',
  callback = function(event)
    local language = vim.treesitter.language.get_lang(event.match)
    if language == nil or not vim.treesitter.language.add(language) then
      return
    end
    vim.treesitter.start(event.buf, language)
    vim.bo[event.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})

vim.keymap.set('n', '<leader>tt', ':InspectTree<CR>', { desc = 'Toggle treesitter' })

-- Node navigation (the old ts_utils.get_node_at_cursor is now built in as vim.treesitter.get_node).
local function get_current_ts_node()
  local bufnr = vim.api.nvim_get_current_buf()
  local parser_ok, parser = pcall(vim.treesitter.get_parser, bufnr)
  if not parser_ok or not parser then
    vim.notify('Treesitter parser not active for this buffer', vim.log.levels.INFO)
    return nil
  end
  return vim.treesitter.get_node()
end

local function jump_to_node(node)
  if not node then
    return
  end
  vim.notify 'going to node!'
  local row, col = node:range()
  vim.api.nvim_win_set_cursor(0, { row + 1, col })
end

vim.keymap.set('n', ']j', function()
  local cur_node = get_current_ts_node()
  if not cur_node then
    print 'no current node!'
    return
  end
  local next_node = cur_node:next_named_sibling()
  if not next_node then
    print 'no next node!'
    return
  end
  print 'got next node'
  jump_to_node(next_node)
end, { desc = 'Treesitter: Next sibling node' })
vim.keymap.set('n', '[j', function()
  jump_to_node(get_current_ts_node():prev_named_sibling())
end, { desc = 'Treesitter: Previous sibling node' })
vim.keymap.set('n', ']t', function()
  jump_to_node(get_current_ts_node():named_child(0))
end, { desc = 'Treesitter: Enter first child node' })
vim.keymap.set('n', '[t', function()
  local node = get_current_ts_node()
  if not node then
    return
  end
  local cursor_row, cursor_col = unpack(vim.api.nvim_win_get_cursor(0))
  cursor_row = cursor_row - 1 -- convert to 0-indexed
  local parent = node:parent()
  while parent do
    local row, col = parent:range()
    if row ~= cursor_row or col ~= cursor_col then
      jump_to_node(parent)
      return
    end
    parent = parent:parent()
  end
end, { desc = 'Treesitter: Go to parent node' })

-- sticky context header
require('treesitter-context').setup {
  enable = true,
  max_lines = 5,
  multiline_threshold = 20,
  trim_scope = 'outer',
  mode = 'cursor',
  on_attach = function()
    vim.api.nvim_set_hl(0, 'TreesitterContext', { bg = 'NONE' })
    vim.api.nvim_set_hl(0, 'TreesitterContextLineNumber', { bg = 'NONE' })
    vim.api.nvim_set_hl(0, 'TreesitterContextBottom', { sp = 'NONE' })
  end,
}
vim.api.nvim_create_autocmd('ColorScheme', {
  callback = function()
    vim.api.nvim_set_hl(0, 'TreesitterContext', { bg = 'NONE' })
    vim.api.nvim_set_hl(0, 'TreesitterContextLineNumber', { bg = 'NONE' })
  end,
})

require('tree-sitter-language-injection').setup {}
require('mermaid').setup()
