-- Full setup extends the same core entry point used by the dev container.
dofile(vim.fn.stdpath('config') .. '/init_core.lua')

vim.pack.add({
  'https://github.com/tpope/vim-sleuth',
  'https://github.com/lewis6991/gitsigns.nvim',
  -- Snippet bodies for blink's `snippets` source. Blink itself is built by Nix, but it
  -- picks this up by scanning the runtimepath, so it only has to be present, not configured.
  'https://github.com/rafamadriz/friendly-snippets',
  'https://github.com/neovim/nvim-lspconfig', -- server definitions only (lsp/*.lua); the client is built in
  'https://github.com/b0o/schemastore.nvim',
  'https://github.com/stevearc/conform.nvim',
  'https://github.com/DariusCorvus/tree-sitter-language-injection.nvim',
  'https://github.com/fionn/nvim-hujson',
  'https://github.com/kevalin/mermaid.nvim',
  'https://github.com/mfussenegger/nvim-dap',
  'https://github.com/nvim-neotest/nvim-nio',
  'https://github.com/rcarriga/nvim-dap-ui',
  'https://github.com/folke/todo-comments.nvim',
  'https://github.com/grafana/vim-alloy',
  'https://github.com/mfussenegger/nvim-ansible',
  'https://github.com/aaronik/treewalker.nvim',
  'https://github.com/chentoast/marks.nvim',
  { src = 'https://github.com/ThePrimeagen/harpoon', version = 'harpoon2' },
  'https://github.com/kevinhwang91/nvim-bqf',
  'https://github.com/MeanderingProgrammer/render-markdown.nvim',
  'https://github.com/tpope/vim-dadbod',
  'https://github.com/kristijanhusak/vim-dadbod-completion',
  'https://github.com/kristijanhusak/vim-dadbod-ui',
  'https://github.com/yarospace/lua-console.nvim',
  'https://github.com/joeledwardson/joels-lua-utils',
  'https://github.com/epheien/outline-treesitter-provider.nvim',
  'https://github.com/hedyhli/outline.nvim',
  'https://github.com/Shatur/neovim-session-manager',
  'https://github.com/folke/trouble.nvim',
}, { confirm = false })

require('todo-comments').setup {}
require('treewalker').setup {}
require('marks').setup {}
require('bqf').setup {}

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

-- Native sorter is supplied by the desktop Nix wrapper.
require('telescope').load_extension 'fzf'
require('which-key').add {
  { '<leader>D', group = '[D]atabase' },
  { '<leader>p', group = 'Sessions' },
  { '<leader>l', group = '[l]ua console' },
  { '<leader>x', group = '[x] trouble' },
}
require 'plugins.completion' -- before LSP servers start so they receive Blink's capabilities
require 'plugins.lsp'
require 'plugins.conform'
require 'plugins.treesitter'
require 'plugins.gitsigns'
require 'plugins.dap'
require 'plugins.harpoon'
require 'plugins.dadbod'
require 'plugins.outline'
require 'plugins.session'
require 'plugins.trouble'
require 'plugins.lua-console'

require 'custom.keymaps'
require 'custom.commands'
require('custom.mdx').setup()
