require('which-key').setup {
  icons = { mappings = vim.g.have_nerd_font },
  spec = {
    { '<leader>s', group = '[S]earch' },
    { '<leader>t', group = '[T]oggle' },
    { '<leader>T', group = '[T]abs' },
    { '<leader>k', group = '[k]eys' },
  },
}
