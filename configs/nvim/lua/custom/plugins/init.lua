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
    -- TODO: disable for now, is it causing redraw issues?
    enabled = false,
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
    -- TODO: re-enable this? not sure if causing rendering issues with zellij
    enabled = false,
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
  -- syntax highlighting for alloy files
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
  -- TODO: needed? could be useful for sorting text file lines sometimes, added a while ago
  {
    'sQVe/sort.nvim',
    config = function()
      require('sort').setup {
        -- Optional configuration overrides.
      }
    end,
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
    'chentoast/marks.nvim',
    event = 'VeryLazy',
    opts = {},
  },
  {
    'folke/flash.nvim',
    event = 'VeryLazy',
    ---@type Flash.Config
    opts = {
      -- labels = "abcdefghijklmnopqrstuvwxyz",
      labels = 'asdfghjklqwertyuiopzxcvbnm',
      search = {
        -- search/jump in all windows
        multi_window = true,
        -- search direction
        forward = true,
        -- when `false`, find only matches in the given direction
        wrap = true,
        ---@type Flash.Pattern.Mode
        -- Each mode will take ignorecase and smartcase into account.
        -- * exact: exact match
        -- * search: regular search
        -- * fuzzy: fuzzy search
        -- * fun(str): custom function that returns a pattern
        --   For example, to only match at the beginning of a word:
        --   mode = function(str)
        --     return "\\<" .. str
        --   end,
        mode = 'exact',
        -- behave like `incsearch`
        incremental = false,
        -- Excluded filetypes and custom window filters
        ---@type (string|fun(win:window))[]
        exclude = {
          'notify',
          'cmp_menu',
          'noice',
          'flash_prompt',
          function(win)
            -- exclude non-focusable windows
            return not vim.api.nvim_win_get_config(win).focusable
          end,
        },
        -- Optional trigger character that needs to be typed before
        -- a jump label can be used. It's NOT recommended to set this,
        -- unless you know what you're doing
        trigger = '',
        -- max pattern length. If the pattern length is equal to this
        -- labels will no longer be skipped. When it exceeds this length
        -- it will either end in a jump or terminate the search
        max_length = false, ---@type number|false
      },
      jump = {
        -- save location in the jumplist
        jumplist = true,
        -- jump position
        pos = 'start', ---@type "start" | "end" | "range"
        -- add pattern to search history
        history = false,
        -- add pattern to search register
        register = false,
        -- clear highlight after jump
        nohlsearch = false,
        -- automatically jump when there is only one match
        autojump = false,
        -- You can force inclusive/exclusive jumps by setting the
        -- `inclusive` option. By default it will be automatically
        -- set based on the mode.
        inclusive = nil, ---@type boolean?
        -- jump position offset. Not used for range jumps.
        -- 0: default
        -- 1: when pos == "end" and pos < current position
        offset = nil, ---@type number
      },
      label = {
        -- allow uppercase labels
        uppercase = true,
        -- add any labels with the correct case here, that you want to exclude
        exclude = '',
        -- add a label for the first match in the current window.
        -- you can always jump to the first match with `<CR>`
        current = true,
        -- show the label after the match
        after = true, ---@type boolean|number[]
        -- show the label before the match
        before = false, ---@type boolean|number[]
        -- position of the label extmark
        style = 'overlay', ---@type "eol" | "overlay" | "right_align" | "inline"
        -- flash tries to re-use labels that were already assigned to a position,
        -- when typing more characters. By default only lower-case labels are re-used.
        reuse = 'lowercase', ---@type "lowercase" | "all" | "none"
        -- for the current window, label targets closer to the cursor first
        distance = true,
        -- minimum pattern length to show labels
        -- Ignored for custom labelers.
        min_pattern_length = 0,
        -- Enable this to use rainbow colors to highlight labels
        -- Can be useful for visualizing Treesitter ranges.
        rainbow = {
          enabled = false,
          -- number between 1 and 9
          shade = 5,
        },
        -- With `format`, you can change how the label is rendered.
        -- Should return a list of `[text, highlight]` tuples.
        ---@class Flash.Format
        ---@field state Flash.State
        ---@field match Flash.Match
        ---@field hl_group string
        ---@field after boolean
        ---@type fun(opts:Flash.Format): string[][]
        format = function(opts)
          return { { opts.match.label, opts.hl_group } }
        end,
      },
      highlight = {
        -- show a backdrop with hl FlashBackdrop
        backdrop = true,
        -- Highlight the search matches
        matches = true,
        -- extmark priority
        priority = 5000,
        groups = {
          match = 'FlashMatch',
          current = 'FlashCurrent',
          backdrop = 'FlashBackdrop',
          label = 'FlashLabel',
        },
      },
      -- action to perform when picking a label.
      -- defaults to the jumping logic depending on the mode.
      ---@type fun(match:Flash.Match, state:Flash.State)|nil
      action = nil,
      -- initial pattern to use when opening flash
      pattern = '',
      -- When `true`, flash will try to continue the last search
      continue = false,
      -- Set config to a function to dynamically change the config
      config = nil, ---@type fun(opts:Flash.Config)|nil
      -- You can override the default options for a specific mode.
      -- Use it with `require("flash").jump({mode = "forward"})`
      ---@type table<string, Flash.Config>
      modes = {
        -- options used when flash is activated through
        -- a regular search with `/` or `?`
        search = {
          -- when `true`, flash will be activated during regular search by default.
          -- You can always toggle when searching with `require("flash").toggle()`
          enabled = false,
          highlight = { backdrop = false },
          jump = { history = true, register = true, nohlsearch = true },
          search = {
            -- `forward` will be automatically set to the search direction
            -- `mode` is always set to `search`
            -- `incremental` is set to `true` when `incsearch` is enabled
          },
        },
        -- options used when flash is activated through
        -- `f`, `F`, `t`, `T`, `;` and `,` motions
        char = {
          enabled = true,
          -- dynamic configuration for ftFT motions
          config = function(opts)
            -- autohide flash when in operator-pending mode
            opts.autohide = opts.autohide or (vim.fn.mode(true):find 'no' and vim.v.operator == 'y')

            -- disable jump labels when not enabled, when using a count,
            -- or when recording/executing registers
            opts.jump_labels = opts.jump_labels and vim.v.count == 0 and vim.fn.reg_executing() == '' and vim.fn.reg_recording() == ''

            -- Show jump labels only in operator-pending mode
            -- opts.jump_labels = vim.v.count == 0 and vim.fn.mode(true):find("o")
          end,
          -- hide after jump when not using jump labels
          autohide = false,
          -- show jump labels
          jump_labels = false,
          -- set to `false` to use the current line only
          multi_line = true,
          -- When using jump labels, don't use these keys
          -- This allows using those keys directly after the motion
          label = { exclude = 'hjkliardc' },
          -- by default all keymaps are enabled, but you can disable some of them,
          -- by removing them from the list.
          -- If you rather use another key, you can map them
          -- to something else, e.g., { [";"] = "L", [","] = H }
          keys = { 'f', 'F', 't', 'T', ';', ',' },
          ---@alias Flash.CharActions table<string, "next" | "prev" | "right" | "left">
          -- The direction for `prev` and `next` is determined by the motion.
          -- `left` and `right` are always left and right.
          char_actions = function(motion)
            return {
              [';'] = 'next', -- set to `right` to always go right
              [','] = 'prev', -- set to `left` to always go left
              -- clever-f style
              [motion:lower()] = 'next',
              [motion:upper()] = 'prev',
              -- jump2d style: same case goes next, opposite case goes prev
              -- [motion] = "next",
              -- [motion:match("%l") and motion:upper() or motion:lower()] = "prev",
            }
          end,
          search = { wrap = false },
          highlight = { backdrop = true },
          jump = {
            register = false,
            -- when using jump labels, set to 'true' to automatically jump
            -- or execute a motion when there is only one match
            autojump = false,
          },
        },
        -- options used for treesitter selections
        -- `require("flash").treesitter()`
        treesitter = {
          labels = 'abcdefghijklmnopqrstuvwxyz',
          jump = { pos = 'start', autojump = true },
          search = { incremental = false },
          label = { before = true, after = true, style = 'inline' },
          highlight = {
            backdrop = false,
            matches = false,
          },
        },
        treesitter_search = {
          jump = { pos = 'range' },
          search = { multi_window = true, wrap = true, incremental = false },
          remote_op = { restore = true },
          label = { before = true, after = true, style = 'inline' },
        },
        -- options used for remote flash
        remote = {
          remote_op = { restore = true, motion = true },
        },
      },
      -- options for the floating window that shows the prompt,
      -- for regular jumps
      -- `require("flash").prompt()` is always available to get the prompt text
      prompt = {
        enabled = true,
        prefix = { { '⚡', 'FlashPromptIcon' } },
        win_config = {
          relative = 'editor',
          border = 'none',
          width = 1, -- when <=1 it's a percentage of the editor width
          height = 1,
          row = -1, -- when negative it's an offset from the bottom
          col = 0, -- when negative it's an offset from the right
          zindex = 1000,
        },
      },
      -- options for remote operator pending mode
      remote_op = {
        -- restore window views and cursor position
        -- after doing a remote operation
        restore = false,
        -- For `jump.pos = "range"`, this setting is ignored.
        -- `true`: always enter a new motion when doing a remote operation
        -- `false`: use the window's cursor position and jump target
        -- `nil`: act as `true` for remote windows, `false` for the current window
        motion = false,
      },
    },
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
}
