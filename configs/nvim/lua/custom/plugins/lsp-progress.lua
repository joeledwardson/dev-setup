-- lua
return {
  'linrongbin16/lsp-progress.nvim',
  lazy = false,
  config = function()
    require('lsp-progress').setup()
  end,
}
