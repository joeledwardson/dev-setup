-- JOLLOF SPECIFIC CONFIGURATIONS
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.ignorecase = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.number = true

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

vim.keymap.set('n', ']r', ':cnext<CR>zz', { desc = 'Next reference' })
vim.keymap.set('n', '[r', ':cprev<CR>zz', { desc = 'Previous reference' })

vim.keymap.set('n', '<Esc>', function()
  vim.cmd 'nohlsearch' -- Clear search highlighting
  require('notify').dismiss { pending = true, silent = true }
end, { desc = 'dismiss notify popup and clear hlsearch' })

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
        -- FROM DADBOD COMPLETION: see https://github.com/kristijanhusak/vim-dadbod-completion
        per_filetype = {
          sql = { 'snippets', 'dadbod', 'buffer' },
        },
        -- add vim-dadbod-completion to your completion providers
        providers = {
          dadbod = { name = 'Dadbod', module = 'vim_dadbod_completion.blink' },
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

          " then open
          let l:open_cmd = printf("xdg-open %s", l:final_url)
          let l:result = system(l:open_cmd)
          if v:shell_error != 0
            echohl ErrorMsg | echomsg "xdg-open failed: " . l:result | echohl None
          endif

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
  -- ansiblels requires file type 'yaml.ansible' (see config here: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#ansiblels), this plugin sets that up (plus other things i dont use)
  {
    'mfussenegger/nvim-ansible',
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
    config = function()
      require('sort').setup {
        -- Optional configuration overrides.
      }
    end,
  },
}
