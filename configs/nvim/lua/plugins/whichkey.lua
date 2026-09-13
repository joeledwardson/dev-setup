require('which-key').setup {
  icons = { mappings = vim.g.have_nerd_font },
  -- Only prefixes that actually have children belong here. <leader>w in particular is a
  -- mapping in its own right (treewalker mode), so labelling it a group misrepresents it.
  spec = {
    { '<leader>D', group = '[D]atabase' },
    { '<leader>s', group = '[S]earch' },
    { '<leader>t', group = '[T]oggle' },
    { '<leader>p', group = '[p]ossesson' },
    { '<leader>k', group = '[k]eys' },
    { '<leader>l', group = '[l]ua console' },
    { '<leader>x', group = '[x] trouble' },
  },
}
