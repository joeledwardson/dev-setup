require('onedarkpro').setup {
  options = {
    highlight_inactive_windows = true,
  },
}
vim.cmd 'colorscheme onedark'
vim.api.nvim_set_hl(0, 'MiniStatuslineFilename', { bg = '#2c323c' })
vim.api.nvim_set_hl(0, 'MiniStatuslineDevinfo', { bg = '#2c323c' })
vim.api.nvim_set_hl(0, 'diffAdded', { fg = '#98c379', bg = '#2a3325' })
vim.api.nvim_set_hl(0, 'diffRemoved', { fg = '#e06c75', bg = '#332328' })
vim.api.nvim_set_hl(0, 'diffLine', { fg = '#5c6370' })
vim.api.nvim_set_hl(0, 'RenderMarkdownH1Bg', { bg = '#2e3440' })
vim.api.nvim_set_hl(0, 'RenderMarkdownH2Bg', { bg = '#2a2f38' })
