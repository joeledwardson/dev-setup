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
