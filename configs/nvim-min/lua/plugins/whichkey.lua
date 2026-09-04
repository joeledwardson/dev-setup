require('which-key').setup {
  icons = { mappings = vim.g.have_nerd_font },
  spec = {
    { '<leader>c', group = '[C]ode', mode = { 'n', 'x' } },
    { '<leader>d', group = '[d]ocument' },
    { '<leader>D', group = '[D]atabase' },
    { '<leader>r', group = '[R]ename' },
    { '<leader>s', group = '[S]earch' },
    { '<leader>w', group = '[W]orkspace' },
    { '<leader>t', group = '[T]oggle' },
    { '<leader>p', group = '[p]ossesson' },
    { '<leader>k', group = '[k]eys' },
    { '<leader>l', group = '[l]ua console' },
    { '<leader>x', group = '[x] trouble' },
    { '<leader>m', group = '[m]arks' },
  },
}
