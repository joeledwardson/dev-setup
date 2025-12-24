return {
  'yarospace/lua-console.nvim',
  lazy = true,
  keys = {
    { '`', desc = 'Lua-console - toggle' },
    -- { '<Leader>`', desc = 'Lua-console - attach to buffer' },
  },
  opts = {},
  config = function()
    require('lua-console').setup {
      mappings = {
        toggle = '`', -- toggle console
        attach = '<Leader>l`', -- attach console to a buffer
        quit = 'q', -- close console
        eval = '<CR>', -- evaluate code
        eval_buffer = '<S-CR>', -- evaluate whole buffer
        kill_ps = '<Leader>lK', -- kill evaluation process
        open = 'gf', -- open link
        messages = 'M', -- load Neovim messages
        save = 'S', -- save session
        load = 'L', -- load session
        resize_up = '<C-Up>', -- resize up
        resize_down = '<C-Down>', -- resize down
        help = '?', -- help
      },
    }
    vim.api.nvim_create_autocmd('BufEnter', {
      callback = function(args)
        -- set sign column for console buffer otherwise it flickers on landing on a line with the lightbulb thing
        local buf_name = vim.api.nvim_buf_get_name(args.buf)
        local end_string = 'lua[-]console[.]nvim/console'
        local pos = buf_name:find(end_string)
        if pos == nil then
          return
        end
        vim.schedule(function()
          vim.opt.signcolumn = 'yes'
        end)
      end,
    })
  end,
}
