local telescope = require 'telescope'
local actions = require 'telescope.actions'
local lga_actions = require 'telescope-live-grep-args.actions'

telescope.setup {
  defaults = {
    sorting_strategy = 'ascending',
    layout_config = {
      prompt_position = 'top',
    },
    file_ignore_patterns = { '%.git/' }, -- never show .git/ contents
    mappings = {
      i = {
        ['<C-l>'] = actions.cycle_history_next,
        ['<C-h>'] = actions.cycle_history_prev,
        ['<Esc>'] = actions.close,
      },
    },
  },
  pickers = {
    buffers = {
      sort_mru = true,
      ignore_current_buffer = true,
    },
    find_files = {
      hidden = true, -- show dotfiles (.github/, .gitignore, etc.)
    },
  },
  extensions = {
    ['ui-select'] = {
      require('telescope.themes').get_dropdown(),
    },
    live_grep_args = {
      auto_quoting = true,
      mappings = {
        i = {
          ['<C-k>'] = lga_actions.quote_prompt(),
          ['<C-f>'] = lga_actions.quote_prompt { postfix = ' --iglob ' },
          ['<C-space>'] = lga_actions.to_fuzzy_refine,
        },
      },
    },
  },
}
telescope.load_extension 'fzf'
telescope.load_extension 'ui-select'
telescope.load_extension 'live_grep_args'

local builtin = require 'telescope.builtin'
vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
vim.keymap.set('n', '<leader>kk', builtin.keymaps, { desc = 'nvim [k]eymaps' })
vim.keymap.set('n', '<leader>kv', function()
  require('custom.keybrowser').open()
end, { desc = 'built-in [v]im keys' })
vim.keymap.set('n', '<leader>kz', function()
  require('custom.keybrowser').open_zsh()
end, { desc = '[z]sh keybindings' })
vim.keymap.set('n', '<leader>kt', function()
  require('custom.keybrowser').open_telescope()
end, { desc = '[t]elescope keybindings' })
vim.keymap.set('n', '<leader>kj', function()
  require('custom.keybrowser').open_zellij()
end, { desc = 'zelli[j] keybindings' })
vim.keymap.set('n', '<leader>kp', function()
  require('custom.keybrowser').open_pgcli()
end, { desc = '[p]gcli keybindings' })
vim.keymap.set('n', '<leader>kb', function()
  require('custom.keybrowser').open_brave()
end, { desc = '[b]rave keybindings' })
vim.keymap.set('n', '<leader>kB', function()
  require('custom.keybrowser').open_brave_extensions()
end, { desc = '[B]rave extensions' })
vim.keymap.set('n', '<leader>f', builtin.find_files, { desc = '[f]iles search' })
vim.keymap.set('n', '<leader>sF', function()
  builtin.find_files {
    no_ignore = true,
    hidden = true,
  }
end, { desc = '[S]earch [F]iles (including hidden)' })
vim.keymap.set('n', '<leader>sm', builtin.marks, { desc = '[S]earch [M]arks' })
vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
vim.keymap.set('n', '<leader>g', function()
  telescope.extensions.live_grep_args.live_grep_args {
    attach_mappings = function(_, map)
      map('i', '<C-e>', function(prompt_bufnr)
        local state = require 'telescope.actions.state'
        local current = state.get_current_line()
        state.get_current_picker(prompt_bufnr):set_prompt(current:gsub(' ', '.*'))
      end)
      return true
    end,
  }
end, { desc = '[S]earch by [g]rep, <C-e> replaces spaces with .*' })
vim.keymap.set('n', '<leader>sG', function()
  builtin.live_grep { additional_args = { '--no-ignore', '--hidden' } }
end, { desc = '[S]earch by [G]rep, show hidden' })
vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
vim.keymap.set('n', '<leader><leader>', function()
  builtin.buffers { sort_lastused = true }
end, { desc = '[ ] Find existing buffers' })
vim.keymap.set('n', '<leader>/', function()
  builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
    winblend = 10,
    previewer = false,
  })
end, { desc = '[/] Fuzzily search in current buffer' })
vim.keymap.set('n', '<leader>s/', function()
  builtin.live_grep {
    grep_open_files = true,
    prompt_title = 'Live Grep in Open Files',
  }
end, { desc = '[S]earch [/] in Open Files' })
vim.keymap.set('n', '<leader>sn', function()
  builtin.find_files { cwd = vim.fn.stdpath 'config' }
end, { desc = '[S]earch [N]eovim files' })
