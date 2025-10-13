return {
  'ojroques/nvim-osc52', -- no lazy for this, want clipboard to be always loaded
  lazy = false,
  config = function()
    require('osc52').setup {
      max_length = 0, -- Maximum length of selection (0 for no limit)
      silent = false, -- Disable message on successful copy
      trim = false, -- Trim text before copy
    }

    -- Copy to OSC52 on every yank operation
    local function copy()
      if vim.v.event.operator == 'y' then
        require('osc52').copy(vim.fn.getreg '"')
      end
    end

    vim.api.nvim_create_autocmd('TextYankPost', { callback = copy })
  end,
}
