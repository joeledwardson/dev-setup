return {
  {
    'nvim-tree/nvim-tree.lua',
    version = '*',
    lazy = false,
    dependencies = {
      'nvim-tree/nvim-web-devicons',
      'nvim-lua/plenary.nvim',
      'MunifTanjim/nui.nvim',
    },
    opts = {
      reload_on_bufenter = true,
      hijack_cursor = true,
      hijack_netrw = true,
      sync_root_with_cwd = true,
      -- hijack_unnamed_buffer_when_opening = true,
      auto_reload_on_write = true,
      diagnostics = {
        enable = false,
      },
      hijack_directories = {
        enable = true,
        auto_open = true,
      },
      actions = {
        open_file = {
          resize_window = true,
          quit_on_open = true,
        },
      },
      update_focused_file = {
        enable = true,
      },
      view = {
        number = true,
        relativenumber = true,
        centralize_selection = true,
        adaptive_size = false,
        side = 'right',
        preserve_window_proportions = true,
        width = 40,
      },
      renderer = {
        full_name = false,
        indent_markers = {
          enable = false,
        },
        root_folder_label = ':t',
        highlight_git = true,
      },
      filters = {
        dotfiles = false,
        git_ignored = false,
        git_clean = false,
        no_buffer = false,
      },
      git = {
        enable = true,
        ignore = false,
        timeout = 400,
      },
    },
    config = function(_, opts)
      local nvimtree = require 'nvim-tree'

      local function keybindings(bufnr)
        local api = require 'nvim-tree.api'

        local function ops(desc)
          return {
            desc = 'nvim-tree: ' .. desc,
            buffer = bufnr,
            noremap = true,
            silent = true,
            nowait = true,
          }
        end

        -- default mappings
        api.config.mappings.default_on_attach(bufnr)

        -- custom mappings
        -- 👿
        vim.keymap.set('n', 's', api.node.open.vertical_no_picker, ops 'Open Horizontal')
        vim.keymap.set('n', 'S', api.node.open.horizontal_no_picker, ops 'Open Vertical')
      end

      opts.on_attach = keybindings

      nvimtree.setup(opts)

      vim.keymap.set('n', '<C-n>', ':NvimTreeToggle<CR>', { silent = true })
      vim.keymap.set('n', '<leader>nf', ':NvimTreeFindFile<CR>', { silent = true, desc = 'Find current file in tree' })
    end,
  },
  {
    'antosha417/nvim-lsp-file-operations',
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
    config = true,
  },
}
