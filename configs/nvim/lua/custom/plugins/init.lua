-- JOLLOF SPECIFIC CONFIGURATIONS
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.ignorecase = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.number = true
vim.o.termsync = false

-- use treesitter for folding: see https://neovim.io/doc/user/treesitter.html
-- vim.o.foldmethod = 'expr'
-- vim.o.foldexpr = 'v:lua.vim.lsp.foldexpr()'
vim.opt.foldmethod = 'expr'
vim.opt.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
vim.opt.foldlevelstart = 99

-- retain selection when shifting
vim.keymap.set('v', '>', '>gv', { noremap = true })
vim.keymap.set('v', '<', '<gv', { noremap = true })

-- alt shift H is used by tmux (and zellij) for window switching
vim.keymap.set('n', '<M-H>', '<Nop>', { noremap = true })
vim.keymap.set({ 'n' }, '<Leader>ts', function()
  vim.lsp.buf.signature_help()
end, { silent = true, noremap = true, desc = 'toggle signature' })

-- vim.keymap.set('n', '<Esc>', function()
--   vim.cmd 'nohlsearch' -- Clear search highlighting
--   require('notify').dismiss { pending = true, silent = true }
-- end, { desc = 'dismiss notify popup and clear hlsearch' })
vim.keymap.set('n', '<leader>e', function()
  vim.diagnostic.open_float { focusable = true, focus = true }
end, { desc = 'open diagnostic' })

-- remap space, newline chars in normal mode to add (see :h i_CTRL-G_u)
vim.keymap.set('i', '<Space>', '<C-G>u<Space>', { noremap = true, silent = true })
-- same for newline
vim.keymap.set('i', '<CR>', '<C-G>u<CR>', { noremap = true, silent = true })

-- remap capital Y to yank and then move cursor to end (helpful when yanking big blocks of text)
vim.keymap.set({ 'v' }, 'Y', "y']", { desc = 'Yank and move to end ' })
-- remap D to delete to null buffer
vim.keymap.set({ 'n', 'v' }, 'D', '"_d', { desc = 'delete to null buffer' })
vim.api.nvim_create_user_command('PrintServerCapabilities', function()
  local currentbuf = vim.api.nvim_get_current_buf()
  local capabilities = vim.lsp.get_clients({ bufnr = currentbuf })[1].server_capabilities
  local newbuf = vim.api.nvim_create_buf(false, true)
  local formatted = vim.inspect(capabilities)
  local lines = vim.split(formatted, '\n')
  vim.api.nvim_buf_set_text(newbuf, 0, 0, 0, 0, lines)
  vim.api.nvim_win_set_buf(0, newbuf)
  vim.bo.filetype = 'lua'
end, {})

vim.api.nvim_create_user_command('PrintFoldLevel', function()
  local line = vim.fn.line '.'
  local level = vim.fn.foldlevel(line)
  vim.api.nvim_echo({ { 'Fold level on line ' .. line .. ' is ' .. level } }, true, {})
end, {})

-- --- close all child folds under cursor (inverse of zC which closes upward)
-- vim.keymap.set('n', 'zx', function()
--   local line = vim.fn.line '.'
--   local level = vim.fn.foldlevel(line)
--   if level == 0 then
--     vim.notify('not on a fold', vim.log.levels.WARN)
--     return
--   end
--
--   -- find range of current fold at this level
--   local last = vim.fn.line '$'
--   local fold_end = line
--   for i = line + 1, last do
--     if vim.fn.foldlevel(i) < level then
--       break
--     end
--     fold_end = i
--   end
--   local fold_start = line
--   for i = line - 1, 1, -1 do
--     if vim.fn.foldlevel(i) < level then
--       break
--     end
--     fold_start = i
--   end
--
--   -- close all folds in range recursively, then reopen just this level
--   local pos = vim.fn.getcurpos()
--   pcall(vim.cmd, fold_start .. ',' .. fold_end .. 'foldclose!')
--   vim.fn.setpos('.', pos)
--   pcall(vim.cmd, 'normal! zo')
-- end, { desc = 'close all child folds under cursor' })

--- remap custom fold
vim.keymap.set('n', 'zX', function()
  -- get current line number
  local lineNumber = vim.fn.line '.'
  -- if above a closed fold then just open, works fine
  local foldClosedLine = vim.fn.foldclosed(lineNumber)
  if foldClosedLine ~= -1 then
    vim.cmd 'normal! zO'
    return
  end
  vim.cmd 'normal! zczO'
end, { desc = 'jollof recursive fold opener' })

-- Automatically set filetype and start LSP for specific systemd unit file patterns
vim.api.nvim_create_autocmd('BufEnter', {
  pattern = { '*.service', '*.socket', '*.mount', '*.device', '*.nspawn', '*.target', '*.timer' },
  callback = function()
    vim.bo.filetype = 'systemd'
    vim.lsp.start {
      name = 'systemd_ls',
      cmd = { 'systemd-lsp' }, -- Update this path to your systemd-lsp binary
      root_dir = vim.fn.getcwd(),
    }
  end,
})

-- replace jinja template file types with original ft
vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
  pattern = '*.j2',
  callback = function()
    local inner = vim.fn.expand('%:r'):match '%.([^.]+)$'
    if inner then
      vim.bo.filetype = inner
    end
  end,
})

-- Jump to next/previous URL
vim.keymap.set('n', ']l', '/https:\\/\\/<CR>', { desc = 'Next URL' })
vim.keymap.set('n', '[l', '?https:\\/\\/<CR>', { desc = 'Previous URL' })

-- Treat zellij scrollback dump files as bash (they normally are)
vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
  pattern = '/tmp/*.dump',
  callback = function()
    vim.bo.filetype = 'bash'
  end,
})

-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
---@type LazyPluginSpec[]
return {
  -- {
  --   'y3owk1n/undo-glow.nvim',
  --   version = '*', -- remove this if you want to use the `main` branch
  --   opts = {
  --     -- your configuration comes here
  --     -- or leave it empty to use the default settings
  --     -- refer to the configuration section below
  --   },
  --   },

  {
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      library = {
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
      },
    },
  },
  {
    'saghen/blink.cmp',
    -- optional: provides snippets for the snippet source
    dependencies = { 'rafamadriz/friendly-snippets' },

    -- use a release tag to download pre-built binaries
    version = '1.*',
    -- AND/OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
    -- build = 'cargo build --release',
    -- If you use nix, you can build from source using latest nightly rust with:
    -- build = 'nix run .#build-plugin',

    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      -- 'default' (recommended) for mappings similar to built-in completions (C-y to accept)
      -- 'super-tab' for mappings similar to vscode (tab to accept)
      -- 'enter' for enter to accept
      -- 'none' for no mappings
      --
      -- All presets have the following mappings:
      -- C-space: Open menu or open docs if already open
      -- C-n/C-p or Up/Down: Select next/previous item
      -- C-e: Hide menu
      -- C-k: Toggle signature help (if signature.enabled = true)
      --
      -- See :h blink-cmp-config-keymap for defining your own keymap
      keymap = {
        preset = 'default',

        ['<Tab>'] = { 'select_and_accept', 'fallback' },
      },

      appearance = {
        -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
        -- Adjusts spacing to ensure icons are aligned
        nerd_font_variant = 'mono',
      },

      -- (Default) Only show the documentation popup when manually triggered
      completion = { documentation = { auto_show = false } },

      -- Default list of enabled providers defined so that you can extend it
      -- elsewhere in your config, without redefining it, due to `opts_extend`
      sources = {
        default = { 'lazydev', 'lsp', 'path', 'snippets', 'buffer' },
        -- FROM DADBOD COMPLETION: see https://github.com/kristijanhusak/vim-dadbod-completion
        per_filetype = {
          sql = { 'snippets', 'dadbod', 'buffer' },
        },
        providers = {
          dadbod = { name = 'Dadbod', module = 'vim_dadbod_completion.blink' },
          lazydev = { name = 'LazyDev', module = 'lazydev.integrations.blink', score_offset = 100 },
        },
        -- END DADBOD COMPLETION
      },

      cmdline = {
        keymap = { preset = 'inherit' },
        completion = { menu = { auto_show = true } },
      },

      -- (Default) Rust fuzzy matcher for typo resistance and significantly better performance
      -- You may use a lua implementation instead by using `implementation = "lua"` or fallback to the lua implementation,
      -- when the Rust fuzzy matcher is not available, by using `implementation = "prefer_rust"`
      --
      -- See the fuzzy documentation for more information
      fuzzy = { implementation = 'prefer_rust_with_warning' },
    },
    opts_extend = { 'sources.default' },
  },

  {
    'folke/todo-comments.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    event = 'VimEnter',
    opts = {},
  },
  {
    'ojroques/nvim-osc52',
    lazy = false,
    config = function()
      require('osc52').setup {
        max_length = 0, -- Maximum length of selection (0 for no limit)
        silent = false, -- Disable message on successful copy
        trim = false, -- Trim surrounding whitespaces before copy
        tmux_passthrough = false, -- Use tmux passthrough (requires tmux: set -g allow-passthrough on)
      }
      local function copy()
        local event = vim.v.event
        if event.operator == 'y' and (event.regname == '+' or event.regname == '') then
          require('osc52').copy_register '+'
        end
      end
      vim.api.nvim_create_autocmd('TextYankPost', { callback = copy })
    end,
  },
  -- syntax highlighting for alloy files
  {
    'grafana/vim-alloy',
    ft = 'alloy',
  },
  {
    'mfussenegger/nvim-ansible',
    ft = { 'yaml', 'yaml.ansible' },
  },
  {
    '3rd/image.nvim',
    event = 'BufRead *.png,*.jpg,*.jpeg,*.gif,*.webp,*.bmp,*.svg',
    build = false,
    opts = {
      backend = 'ueberzug',
      processor = 'magick_cli',
      max_width_window_percentage = 80,
      max_height_window_percentage = 60,
    },
  },
  {
    'gbprod/yanky.nvim',
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    },
    keys = {
      { '<leader>y', '<cmd>YankyRingHistory<cr>', mode = { 'n', 'x' }, desc = 'Open Yank History' },
    },
  },
  {
    'sQVe/sort.nvim',
    cmd = 'Sort',
    opts = {},
  },
  {
    'swaits/zellij-nav.nvim',
    lazy = true,
    event = 'VeryLazy',
    keys = {
      { '<c-h>', '<cmd>ZellijNavigateLeft<cr>', { silent = true, desc = 'navigate left' } },
      { '<c-j>', '<cmd>ZellijNavigateDown<cr>', { silent = true, desc = 'navigate down' } },
      { '<c-k>', '<cmd>ZellijNavigateUp<cr>', { silent = true, desc = 'navigate up' } },
      { '<c-l>', '<cmd>ZellijNavigateRight<cr>', { silent = true, desc = 'navigate right' } },
    },
    opts = {},
  },
  {
    'aaronik/treewalker.nvim',
    opts = {},
    keys = {
      { '<C-S-k>', '<cmd>Treewalker Up<cr>', mode = { 'n', 'v' }, desc = 'Treewalker Up' },
      { '<C-S-j>', '<cmd>Treewalker Down<cr>', mode = { 'n', 'v' }, desc = 'Treewalker Down' },
      { '<C-S-h>', '<cmd>Treewalker Left<cr>', mode = { 'n', 'v' }, desc = 'Treewalker Left' },
      { '<C-S-l>', '<cmd>Treewalker Right<cr>', mode = { 'n', 'v' }, desc = 'Treewalker Right' },
    },
  },
  {
    'chentoast/marks.nvim',
    event = 'VeryLazy',
    opts = {},
  },
  {
    'folke/flash.nvim',
    event = 'VeryLazy',
    keys = {
      {
        's',
        mode = { 'n', 'x', 'o' },
        function()
          require('flash').jump()
        end,
        desc = 'Flash',
      },
      {
        'S',
        mode = { 'n', 'x', 'o' },
        function()
          require('flash').treesitter {}
        end,
        desc = 'Flash Treesitter',
      },
      {
        'r',
        mode = 'o',
        function()
          require('flash').remote()
        end,
        desc = 'Remote Flash',
      },
      {
        '<leader>NR',
        mode = { 'o', 'x' },
        function()
          require('flash').treesitter_search()
        end,
        desc = 'Treesitter Search',
      },
      {
        '<c-s>',
        mode = { 'c' },
        function()
          require('flash').toggle()
        end,
        desc = 'Toggle Flash Search',
      },
    },
  },
  -- really useful to see lsp loading for big projects and a percentage
  {
    'linrongbin16/lsp-progress.nvim',
    config = function()
      require('lsp-progress').setup()
    end,
  },
}
