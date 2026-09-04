local ufo = require 'ufo'
ufo.setup {
  provider_selector = function()
    return { 'treesitter', 'indent' }
  end,
}
vim.o.foldcolumn = '1'
vim.o.foldlevel = 99 -- ufo needs a large value
vim.o.foldlevelstart = 99
vim.o.foldenable = true
vim.keymap.set('n', 'zR', ufo.openAllFolds)
vim.keymap.set('n', 'zM', ufo.closeAllFolds)
