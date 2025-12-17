-- JOLLOF SPECIFIC CONFIGURATIONS
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.ignorecase = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.number = true
-- alt shift H is used by tmux for window switching
vim.keymap.set('n', '<M-H>', '<Nop>', { noremap = true })
-- vim.api.nvim_set_keymap('i', '<C-b>', 'cmp#complete()', { noremap = true, expr = true })
-- folds
-- vim.opt.foldmethod = 'expr'
-- vim.opt.foldexpr = 'nvim_treesitter#foldexpr()'
-- vim.opt.foldenable = true
-- vim.opt.foldlevel = 99 -- start with all folds open
-- vim.opt.foldlevelstart = 99 -- start with all folds open
-- vim.keymap.set('n', 'zO', 'zxzczA', { desc = 'Open fold and enter insert' })

-- vim.o.foldmethod = 'expr'
-- vim.o.foldexpr = 'v:lua.vim.lsp.foldexpr()'

-- Window focus highlighting (NC = Non-Current/inactive windows)
-- vim.api.nvim_create_autocmd({ 'WinEnter', 'BufEnter' }, {
--   callback = function()
--     vim.api.nvim_set_hl(0, 'NormalNC', { bg = '#302b10' }) -- inactive windows
--     vim.api.nvim_set_hl(0, 'Normal', { bg = 'NONE' }) -- active window stays default
--   end,
-- })
--
-- -- Command mode highlighting (keeping your original)
-- vim.api.nvim_create_autocmd('CmdlineEnter', {
--   callback = function()
--     -- vim.api.nvim_set_hl(0, 'Normal', { bg = '#302b10' }) end,
-- })
--
-- vim.api.nvim_create_autocmd('CmdlineLeave', {
--   callback = function()
--     -- vim.api.nvim_set_hl(0, 'Normal', { fg = 'NONE', bg = 'NONE' })
--   end,
-- })

-- vim.keymap.set({ 'n' }, '<C-k>', function()
--   require('lsp_signature').toggle_float_win()
-- end, { silent = true, noremap = true, desc = 'toggle signature' })

vim.keymap.set({ 'n' }, '<Leader>k', function()
  vim.lsp.buf.signature_help()
end, { silent = true, noremap = true, desc = 'toggle signature' })

-- vim.keymap.set('n', 'z', 'zxz')

vim.keymap.set('n', ']r', ':cnext<CR>zz', { desc = 'Next reference' })
vim.keymap.set('n', '[r', ':cprev<CR>zz', { desc = 'Previous reference' })

vim.keymap.set('n', '<Esc>', function()
  vim.cmd 'nohlsearch' -- Clear search highlighting
  require('notify').dismiss()
end, { desc = 'dismiss notify popup and clear hlsearch' })

vim.keymap.set('n', '<leader>e', function()
  vim.diagnostic.open_float { focusable = true, focus = true }
end, { desc = 'open diagnostic' })

-- remap space, newline chars in normal mode to add (see :h i_CTRL-G_u)
vim.keymap.set('i', '<Space>', '<C-G>u<Space>', { noremap = true, silent = true })
-- same for newline
vim.keymap.set('i', '<CR>', '<C-G>u<CR>', { noremap = true, silent = true })

-- vim.api.nvim_create_autocmd({ 'BufEnter' }, {
--   callback = function(event)
--     local fileext = vim.fn.expand '%:e'
--     local filename = vim.fn.expand '%:t:r'
--
--     vim.print('got a buf name: ', vim.api.nvim_buf_get_name(event.buf))
--   end,
-- })

-- Automatically set filetype and start LSP for specific systemd unit file patterns
vim.api.nvim_create_autocmd('BufEnter', {
  pattern = { '*.service', '*.mount', '*.device', '*.nspawn', '*.target', '*.timer' },
  callback = function()
    vim.bo.filetype = 'systemd'
    vim.lsp.start {
      name = 'systemd_ls',
      cmd = { 'systemd-lsp' }, -- Update this path to your systemd-lsp binary
      root_dir = vim.fn.getcwd(),
    }
  end,
})

-- TODO

-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
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
    'kevinhwang91/nvim-ufo',
    dependencies = { 'kevinhwang91/promise-async' },
    lazy = false,
    config = function()
      -- Option 3: treesitter as a main provider instead
      -- (Note: the `nvim-treesitter` plugin is *not* needed.)
      -- ufo uses the same query files for folding (queries/<lang>/folds.scm)
      -- performance and stability are better than `foldmethod=nvim_treesitter#foldexpr()`
      require('ufo').setup {
        provider_selector = function(bufnr, filetype, buftype)
          return { 'treesitter', 'indent' }
        end,
      }
      vim.o.foldcolumn = '1' -- '0' is not bad
      vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
      vim.o.foldlevelstart = 99
      vim.o.foldenable = true

      -- Using ufo provider need remap `zR` and `zM`. If Neovim is 0.6.1, remap yourself
      vim.keymap.set('n', 'zR', require('ufo').openAllFolds)
      vim.keymap.set('n', 'zM', require('ufo').closeAllFolds)
    end,
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
        default = { 'lsp', 'path', 'snippets', 'buffer' },
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
    'lewis6991/satellite.nvim',
    config = function()
      require('satellite').setup {
        current_only = false,
        winblend = 50,
        zindex = 40,
        excluded_filetypes = {},
        width = 2,
        handlers = {
          cursor = {
            enable = true,
            -- Supports any number of symbols
            symbols = { '⎺', '⎻', '⎼', '⎽' },
            -- symbols = { '⎻', '⎼' }
            -- Highlights:
            -- - SatelliteCursor (default links to NonText
          },
          search = {
            enable = true,
            -- Highlights:
            -- - SatelliteSearch (default links to Search)
            -- - SatelliteSearchCurrent (default links to SearchCurrent)
          },
          diagnostic = {
            enable = true,
            signs = { '-', '=', '≡' },
            min_severity = vim.diagnostic.severity.HINT,
            -- Highlights:
            -- - SatelliteDiagnosticError (default links to DiagnosticError)
            -- - SatelliteDiagnosticWarn (default links to DiagnosticWarn)
            -- - SatelliteDiagnosticInfo (default links to DiagnosticInfo)
            -- - SatelliteDiagnosticHint (default links to DiagnosticHint)
          },
          gitsigns = {
            enable = true,
            signs = { -- can only be a single character (multibyte is okay)
              add = '│',
              change = '│',
              delete = '-',
            },
            -- Highlights:
            -- SatelliteGitSignsAdd (default links to GitSignsAdd)
            -- SatelliteGitSignsChange (default links to GitSignsChange)
            -- SatelliteGitSignsDelete (default links to GitSignsDelete)
          },
          marks = {
            enable = true,
            show_builtins = false, -- shows the builtin marks like [ ] < >
            key = 'm',
            -- Highlights:
            -- SatelliteMark (default links to Normal)
          },
          quickfix = {
            signs = { '-', '=', '≡' },
            -- Highlights:
            -- SatelliteQuickfix (default links to WarningMsg)
          },
        },
      }
    end,
  },
  {
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.nvim' }, -- if you use the mini.nvim suite
    -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.icons' },        -- if you use standalone mini plugins
    -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' }, -- if you prefer nvim-web-devicons
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = {},
    ft = 'markdown',
    config = function()
      require('render-markdown').setup { enabled = false }
    end,
    keys = { {
      '<leader>tm',
      function()
        require('render-markdown').toggle()
      end,
      desc = 'toggle markdown render',
    } },
  },
  {
    'folke/todo-comments.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    event = 'VimEnter',
    opts = {},
  },
  -- install without yarn or npm
  {
    'iamcco/markdown-preview.nvim',
    lazy = false,
    cmd = { 'MarkdownPreviewToggle', 'MarkdownPreview', 'MarkdownPreviewStop' },
    ft = { 'markdown' },
    build = function()
      vim.fn['mkdp#util#install']()
    end,
    init = function()
      vim.cmd [[
        function! OpenMarkdownPreview(url)
          " Default to the original URL (fallback)
          let l:final_url = a:url
          
          try
            " 1. Try to fetch the preferred source IP
            let l:cmd = "ip -j route get 1.1.1.1 | jq -r '.[0].prefsrc'"
            let l:ip = trim(system(l:cmd))

            " 2. Validate: If command failed (exit code != 0) or IP is empty, abort
            if v:shell_error != 0 || empty(l:ip)
              throw "IP detection command returned error or empty"
            endif

            " 3. Success: Swap localhost for the real IP
            let l:final_url = substitute(a:url, 'localhost\|127.0.0.1', l:ip, 'g')

          catch
            " 4. Failure: Log the error but keep l:final_url as localhost
            echomsg "Warning: IP detection failed (" . v:exception . "). Using localhost."
          endtry

          " 5. Set Register + Manual OSC52 Trigger
          let @+ = l:final_url
          lua require('osc52').copy_register('+')

          " 6. Feedback
          redraw!
          echomsg "Preview URL Copied: " . l:final_url
        endfunction


        " open to all ips
        let g:mkdp_open_to_the_world = 1
        " Tell the plugin to use this function
        let g:mkdp_browserfunc = 'OpenMarkdownPreview'
      ]]
    end,
    keys = { { '<leader>tp', ':MarkdownPreviewToggle<CR>', desc = 'toggle markdown preview' } },
  },
  {
    'Bekaboo/dropbar.nvim',
    lazy = false,
    -- optional, but required for fuzzy finder support
    dependencies = {
      'nvim-telescope/telescope-fzf-native.nvim',
      build = 'make',
    },
    config = function()
      local dropbar_api = require 'dropbar.api'
      vim.keymap.set('n', '<Leader>;', dropbar_api.pick, { desc = 'Pick symbols in winbar' })
      vim.keymap.set('n', '[;', dropbar_api.goto_context_start, { desc = 'Go to start of current context' })
      vim.keymap.set('n', '];', dropbar_api.select_next_context, { desc = 'Select next context' })
    end,
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
  {
    'grafana/vim-alloy',
  },

  -- in case not using noice
  {
    'rcarriga/nvim-notify',
  },
}
