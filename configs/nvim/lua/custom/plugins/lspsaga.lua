return {
  'nvimdev/lspsaga.nvim',
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    'nvim-tree/nvim-web-devicons',
  },
  config = function()
    require('lspsaga').setup {
      hover = {
        open_link = 'gx',
        open_browser = '!chrome',
      },
    }
    -- Then update your mapping
    vim.keymap.set('n', 'K', '<cmd>Lspsaga hover_doc<CR>')
  end,
}
