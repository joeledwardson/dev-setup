return {
  'nvim-tree/nvim-tree.lua',
  version = '*',
  lazy = false,
  dependencies = {
    'nvim-tree/nvim-web-devicons',
  },
  config = function()
    require('nvim-tree').setup {
      sort_by = 'case_sensitive',
      view = {
        number = true,
        relativenumber = true,
        width = 30,
      },
      renderer = {
        group_empty = false,
        highlight_opened_files = 'all',
      },
      filters = {
        dotfiles = false,
      },
      update_focused_file = {
        enable = true,
        update_root = false,
        ignore_list = {},
      },
      sync_root_with_cwd = true,
      respect_buf_cwd = true,
      git = {
        enable = true,
        ignore = false,
      },
    }

    -- Key mappings
    vim.keymap.set('n', '<C-n>', ':NvimTreeToggle<CR>', { silent = true })
    vim.keymap.set('n', '<leader>nf', ':NvimTreeFindFile<CR>', { silent = true, desc = 'Find current file in tree' })
  end,
}
