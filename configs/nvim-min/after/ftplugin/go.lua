-- Neovim 0.11 ships ftplugin/go.vim, which sets `keywordprg=:GoKeywordPrg`.
-- :GoKeywordPrg runs `go doc <cword>` in a horizontal terminal split. Until gopls
-- attaches (and the LspAttach autocmd maps K -> vim.lsp.buf.hover, a few seconds
-- after opening), K falls through to that split instead of the hover float — and
-- on a non-symbol like a package name it just prints "no symbol ..." in a new
-- window. Map K to LSP hover here so it is the float regardless of attach timing.
vim.keymap.set('n', 'K', vim.lsp.buf.hover, { buffer = true, desc = 'LSP: Hover Documentation' })
