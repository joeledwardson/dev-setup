-- Small plugins that need one setup call and at most one keymap.

require('todo-comments').setup {}
require('sort').setup {}
require('treewalker').setup {}
require('marks').setup {}
require('bqf').setup {}
require('grug-far').setup {}

require('yanky').setup {}
vim.keymap.set({ 'n', 'x' }, '<leader>y', '<cmd>YankyRingHistory<cr>', { desc = 'Open Yank History' })

require('render-markdown').setup {
  file_types = { 'markdown', 'mdx' },
  heading = {
    icons = { '', '', '', '', '', '' },
    backgrounds = { 'RenderMarkdownH1Bg', 'RenderMarkdownH2Bg', '', '', '', '' },
    border = false,
    position = 'inline',
    sign = false,
  },
  bullet = {
    icons = { ' ◉  ', '  ◦  ', '   ▪  ', '    ▫  ' },
  },
}
vim.keymap.set('n', '<leader>tm', function()
  require('render-markdown').toggle()
end, { desc = 'toggle markdown render' })
