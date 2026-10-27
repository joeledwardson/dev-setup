-- Neovim has no mdx filetype or parser: detect .mdx and parse it as markdown.
vim.filetype.add { extension = { mdx = 'mdx' } }
vim.treesitter.language.register('markdown', 'mdx')

-- Use available parsers and queries (the desktop gets additional languages from Nix).
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('treesitter-highlight', { clear = true }),
  desc = 'Enable Tree-sitter highlighting when a parser and highlight query exist',
  callback = function(event)
    local parser = vim.treesitter.get_parser(event.buf)
    if parser and vim.treesitter.query.get(parser:lang(), 'highlights') then
      vim.treesitter.start(event.buf)
    end
  end,
})

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
