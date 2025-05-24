return {
  'kdheepak/lazygit.nvim',
  -- optional for floating window border decoration
  dependencies = {
    'nvim-lua/plenary.nvim',
  },
  config = function()
    -- Setup keymaps for lazygit
    vim.keymap.set('n', '<leader>gg', ':LazyGit<CR>', { silent = true, desc = 'Open LazyGit' })
    vim.keymap.set('n', '<leader>gf', ':LazyGitFilter<CR>', { silent = true, desc = 'LazyGit file history' })
    vim.keymap.set('n', '<leader>gc', ':LazyGitConfig<CR>', { silent = true, desc = 'LazyGit config' })

    -- Configure lazygit float window appearance
    vim.g.lazygit_floating_window_winblend = 0 -- transparency of floating window
    vim.g.lazygit_floating_window_scaling_factor = 0.9 -- scaling factor for floating window
    vim.g.lazygit_floating_window_border_chars = { '╭', '─', '╮', '│', '╯', '─', '╰', '│' } -- customize border chars
    vim.g.lazygit_floating_window_use_plenary = 1 -- use plenary.nvim to manage floating window
    vim.g.lazygit_use_neovim_remote = 0 -- enable opening commits with neovim remote
    vim.g.lazygit_use_custom_config_file_path = 0 -- config file path is evaluated if this value is 1
    -- vim.g.lazygit_config_file_path = '' -- custom config file path

    -- Terminal configuration for lazygit
    -- This sets up how the terminal buffer appears
    vim.api.nvim_create_autocmd({ 'BufEnter' }, {
      pattern = '*lazygit*',
      callback = function()
        -- Set local buffer options for lazygit terminal
        vim.opt_local.number = false
        vim.opt_local.relativenumber = false
        vim.opt_local.signcolumn = 'no'
        vim.cmd 'startinsert'
      end,
    })
  end,
}

