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

-- Window focus highlighting (NC = Non-Current/inactive windows)
vim.api.nvim_create_autocmd({ 'WinEnter', 'BufEnter' }, {
  callback = function()
    vim.api.nvim_set_hl(0, 'NormalNC', { bg = '#302b10' }) -- inactive windows
    vim.api.nvim_set_hl(0, 'Normal', { bg = 'NONE' }) -- active window stays default
  end,
})

-- Command mode highlighting (keeping your original)
vim.api.nvim_create_autocmd('CmdlineEnter', {
  callback = function()
    -- vim.api.nvim_set_hl(0, 'Normal', { bg = '#302b10' })
  end,
})

vim.api.nvim_create_autocmd('CmdlineLeave', {
  callback = function()
    -- vim.api.nvim_set_hl(0, 'Normal', { fg = 'NONE', bg = 'NONE' })
  end,
})

-- vim.keymap.set({ 'n' }, '<C-k>', function()
--   require('lsp_signature').toggle_float_win()
-- end, { silent = true, noremap = true, desc = 'toggle signature' })

vim.keymap.set({ 'n' }, '<Leader>k', function()
  vim.lsp.buf.signature_help()
end, { silent = true, noremap = true, desc = 'toggle signature' })

vim.keymap.set('n', ']r', ':cnext<CR>zz', { desc = 'Next reference' })
vim.keymap.set('n', '[r', ':cprev<CR>zz', { desc = 'Previous reference' })

-- use poetry executable as python path (if exists)
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client == nil or client.name == nil or client.name ~= 'pyright' then
      return
    end

    local venv = vim.env.VIRTUAL_ENV
    if not venv or venv == '' then
      return
    end

    local executable = vim.fn.system({ 'poetry', 'env', 'info', '--executable' }):gsub('%s+$', '')
    print 'got python executable'
    if not executable or executable == '' then
      return
    end

    if vim.fn.filereadable(executable) ~= 1 then
      print('executable is not a valid file? ', executable)
      return
    end

    -- Update Pyright config using the LSP protocol directly
    client.config.settings = client.config.settings or {}
    client.config.settings.python = client.config.settings.python or {}
    client.config.settings.python.pythonPath = executable

    -- Notify the server about the updated configuration
    client.notify('workspace/didChangeConfiguration', {
      settings = client.config.settings,
    })
  end,
})

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
    'chrisgrieser/nvim-origami',
    event = 'VeryLazy',
    opts = {}, -- needed even when using default config

    -- recommended: disable vim's auto-folding
    init = function()
      vim.opt.foldlevel = 99
      vim.opt.foldlevelstart = 99
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

      -- (Default) Rust fuzzy matcher for typo resistance and significantly better performance
      -- You may use a lua implementation instead by using `implementation = "lua"` or fallback to the lua implementation,
      -- when the Rust fuzzy matcher is not available, by using `implementation = "prefer_rust"`
      --
      -- See the fuzzy documentation for more information
      fuzzy = { implementation = 'prefer_rust_with_warning' },
    },
    opts_extend = { 'sources.default' },
  },
}
