-- JOLLOF SPECIFIC CONFIGURATIONS
-- subtle heading backgrounds for render-markdown (onedark base is ~#282c34)
vim.api.nvim_set_hl(0, 'RenderMarkdownH1Bg', { bg = '#2e3440' })
vim.api.nvim_set_hl(0, 'RenderMarkdownH2Bg', { bg = '#2a2f38' })
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.ignorecase = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.number = true
vim.o.termsync = false
vim.opt.autoread = true

-- notify when file changes
vim.api.nvim_create_autocmd('FileChangedShellPost', {
  pattern = '*',
  callback = function()
    vim.notify('File changed on disk. Buffer reloaded.', vim.log.levels.WARN)
  end,
})

-- retain selection when shifting
vim.keymap.set('v', '>', '>gv', { noremap = true })
vim.keymap.set('v', '<', '<gv', { noremap = true })

-- alt shift H is used by tmux (and zellij) for window switching
vim.keymap.set('n', '<M-H>', '<Nop>', { noremap = true })

-- treewalker mode: <leader>w enters loop, hjkl navigate tree, any other key exits
vim.g.treewalker_mode = false
vim.keymap.set('n', '<Leader>w', function()
  vim.g.treewalker_mode = true
  while true do
    vim.api.nvim__redraw { flush = true, cursor = true, win = 0, statusline = true }
    local ok, key = pcall(vim.fn.getcharstr)
    if not ok then
      break
    end
    if key == 'k' then
      vim.cmd 'Treewalker Up'
    elseif key == 'j' then
      vim.cmd 'Treewalker Down'
    elseif key == 'h' then
      vim.cmd 'Treewalker Left'
    elseif key == 'l' then
      vim.cmd 'Treewalker Right'
    else
      break
    end
  end
  vim.g.treewalker_mode = false
  vim.api.nvim__redraw { flush = true, cursor = true, win = 0, statusline = true }
end, { desc = 'treewalker mode' })

-- window resize mode: C-w r enters loop, + - < > resize by 5, any other key exits
vim.g.resize_mode = false
vim.keymap.set('n', '<C-w>r', function()
  vim.g.resize_mode = true
  while true do
    vim.api.nvim__redraw { flush = true, cursor = true, win = 0, statusline = true }
    local ok, key = pcall(vim.fn.getcharstr)
    if not ok then
      break
    end
    if key == '+' or key == '=' then
      vim.cmd 'resize +5'
    elseif key == '-' then
      vim.cmd 'resize -5'
    elseif key == '>' then
      vim.cmd 'vertical resize +5'
    elseif key == '<' then
      vim.cmd 'vertical resize -5'
    else
      break
    end
  end
  vim.g.resize_mode = false
  vim.api.nvim__redraw { flush = true, cursor = true, win = 0, statusline = true }
end, { desc = 'window resize mode' })
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
local url_pattern = [[https:\S\+]]
vim.keymap.set('n', ']l', function()
  vim.fn.setreg('/', url_pattern)
  vim.opt.hlsearch = true
  vim.fn.search(url_pattern, 'W')
end, { desc = 'Next URL' })
vim.keymap.set('n', '[l', function()
  vim.fn.setreg('/', url_pattern)
  vim.opt.hlsearch = true
  vim.fn.search(url_pattern, 'bW')
end, { desc = 'Previous URL' })

-- Treat zellij scrollback dump files as bash (they normally are)
vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
  pattern = '/tmp/*.dump',
  callback = function()
    vim.bo.filetype = 'bash'
  end,
})

-- debug: print all buffers/windows per tab
-- use `log` param when calling from lua-console: PrintBufs(print)
function PrintBufs(log)
  log = log or print
  local current_buf = vim.api.nvim_get_current_buf()
  local pages = vim.api.nvim_list_tabpages()
  for pageindex, pageid in ipairs(pages) do
    log('--- page ' .. pageindex .. ' (ID ' .. pageid .. ') ---')
    local pagewins = vim.api.nvim_tabpage_list_wins(pageid)
    for win_index, win_id in ipairs(pagewins) do
      log('  window #' .. win_index .. ', ID: ' .. win_id)
      log(vim.api.nvim_win_get_config(win_id))
      log('  win_type: ' .. vim.fn.win_gettype(win_id))
      local buf_id = vim.api.nvim_win_get_buf(win_id)
      local bo = vim.bo[buf_id]
      log {
        buf_id = buf_id,
        valid = vim.api.nvim_buf_is_valid(buf_id),
        ft = bo.filetype,
        bt = bo.buftype,
        name = vim.api.nvim_buf_get_name(buf_id),
        listed = bo.buflisted,
        active = current_buf == buf_id,
      }
    end
  end
end

-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
---@type LazyPluginSpec[]
return {
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
      backend = 'kitty',
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

  -- see treewalker_mode above
  {
    'aaronik/treewalker.nvim',
    opts = {},
    cmd = { 'Treewalker' },
  },
  -- TODO: still needed?
  {
    'chentoast/marks.nvim',
    event = 'VeryLazy',
    opts = {},
  },
  -- still getting used to this
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
  -- ok this is actually really useful to automatically select provider where treesitter isn't available fallback
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
  -- going to try this again but tune down the aggressive rendering defaults to something a bit saner
  {
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.nvim' },
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    ft = 'markdown',
    opts = {
      heading = {
        -- heading icons are annoying
        icons = { '', '', '', '', '', '' },
        -- less agressive background colours
        backgrounds = { 'RenderMarkdownH1Bg', 'RenderMarkdownH2Bg', '', '', '', '' },
        border = false,
        position = 'inline',
        sign = false,
      },
      bullet = {
        icons = { ' ◉  ', '  ◦  ', '   ▪  ', '    ▫  ' },
      },
    },
    keys = { {
      '<leader>tm',
      function()
        require('render-markdown').toggle()
      end,
      desc = 'toggle markdown render',
    } },
  },
  -- helpful for tailscale hujson LSP files
  {
    'fionn/nvim-hujson',
  },
}
