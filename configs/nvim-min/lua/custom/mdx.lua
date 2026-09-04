local M = {}

local mdx_highlights = [[
; inherits: markdown

((inline) @_inline
  (#lua-match? @_inline "^%s*import")) @nospell

((inline) @_inline
  (#lua-match? @_inline "^%s*export")) @nospell
]]

local mdx_injections = [[
(fenced_code_block
  (info_string
    (language) @_lang)
  (code_fence_content) @injection.content
  (#set-lang-from-info-string! @_lang))

((minus_metadata) @injection.content
  (#set! injection.language "yaml")
  (#offset! @injection.content 1 0 -1 0)
  (#set! injection.include-children))

((plus_metadata) @injection.content
  (#set! injection.language "toml")
  (#offset! @injection.content 1 0 -1 0)
  (#set! injection.include-children))

([
  (inline)
  (pipe_table_cell)
] @injection.content
  (#set! injection.language "markdown_inline"))

((inline) @injection.content
  (#lua-match? @injection.content "^%s*import")
  (#set! injection.language "typescript"))

((inline) @injection.content
  (#lua-match? @injection.content "^%s*export")
  (#set! injection.language "typescriptreact"))

((inline) @injection.content
  (#lua-match? @injection.content "^%s*<")
  (#set! injection.language "typescriptreact"))

((indented_code_block) @injection.content
  (#lua-match? @injection.content "^%s*<")
  (#set! injection.language "typescriptreact")
  (#set! injection.include-children))

((html_block) @injection.content
  (#set! injection.language "typescriptreact")
  (#set! injection.include-children))
]]

local mdx_textobjects = [[
(fenced_code_block) @codeblock.outer
(fenced_code_block
  (code_fence_content) @codeblock.inner)
]]

local function configure_lsp()
  vim.lsp.config('mdx_analyzer', {
    init_options = {
      typescript = {
        enabled = true,
      },
    },
  })
end

local function configure_treesitter(bufnr)
  local parser_path = vim.api.nvim_get_runtime_file('parser/markdown.so', false)[1]
  if not parser_path then
    return
  end

  vim.treesitter.language.add('mdx', { path = parser_path, symbol_name = 'markdown' })
  vim.treesitter.query.set('mdx', 'highlights', mdx_highlights)
  vim.treesitter.query.set('mdx', 'injections', mdx_injections)
  vim.treesitter.query.set('mdx', 'textobjects', mdx_textobjects)
  vim.treesitter.start(bufnr, 'mdx')
end

function M.setup()
  vim.filetype.add {
    extension = {
      mdx = 'mdx',
    },
  }

  configure_lsp()

  vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('custom-mdx', { clear = true }),
    pattern = 'mdx',
    callback = function(args)
      configure_treesitter(args.buf)
    end,
  })
end

return M
