return {
  'hedyhli/outline.nvim',
  config = function()
    -- Example mapping to toggle outline
    vim.keymap.set('n', '<leader>o', '<cmd>Outline<CR>', { desc = 'Toggle Outline' })
    require('outline').setup {
      providers = {
        priority = { 'lsp', 'coc', 'markdown', 'norg', 'treesitter', 'man' },
      },
    }
    local utils = require 'joels-lua-utils'
    vim.api.nvim_create_autocmd('QuitPre', {
      desc = 'close outline window automatically',
      callback = function(ev)
        -- get the tab page ID for current window
        local active_win_id = vim.api.nvim_get_current_win()
        local active_page_id = vim.api.nvim_win_get_tabpage(active_win_id)

        -- get windows from active page
        local page_wins = vim.api.nvim_tabpage_list_wins(active_page_id)
        -- print 'closing?'

        -- get outline window from tag page
        local outline_win_id = utils.find(page_wins, function(win_id)
          local buf_id = vim.api.nvim_win_get_buf(win_id)
          return vim.bo[buf_id].filetype == 'Outline'
        end)
        -- print('outline id is ' .. outline_win_id)

        -- get remaining "standard" windows
        local filtered = utils.filter(page_wins, function(win_id)
          local win_type = vim.fn.win_gettype(win_id)
          local win_config = vim.api.nvim_win_get_config(win_id)
          -- print('got win type ', win_type)
          -- print('got win relative ', win_config.relative)
          -- print('not active ', win_id ~= active_win_id)
          -- print(win_type == '', win_config.relative == '', win_id ~= active_win_id, win_id ~= outline_win_id)
          -- window type is set to 'popup' (and non blank) for notifications and other non-standard windows
          -- "relative" property (see `nvim_win_get_config` func def) is non blank for non-standard windows
          return win_type == '' and win_config.relative == '' and win_id ~= active_win_id and win_id ~= outline_win_id
        end)

        -- print('filtered from ', #page_wins, ' to ', #filtered)

        -- close outline if no "standard" windows left and outline exists
        if #filtered == 0 and outline_win_id ~= nil then
          local out = require 'outline'
          -- vim.api.nvim_set_current_win(outline_win_id)
          -- print 'closing outline...'
          out.close_outline()
          -- vim.api.nvim_set_current_win(active_win_id)
        end
      end,
    })
    vim.api.nvim_create_autocmd('BufWinEnter', {
      desc = 'attach outline to new help and man pages',
      callback = function(ev)
        -- firstly check if man page or help
        local bufopts = vim.bo[ev.buf]
        local matches = bufopts.filetype == 'man' or bufopts.filetype == 'help'
        if not matches then
          return
        end

        -- get window count on current page
        local current_win = vim.api.nvim_get_current_win()
        local page_id = vim.api.nvim_win_get_tabpage(current_win)
        local win_count = #(vim.api.nvim_tabpage_list_wins(page_id))

        -- move to new page if is split (hopefully)
        if win_count > 1 then
          vim.cmd 'wincmd T'
        end

        -- open outline
        local out = require 'outline'
        out.open_outline()
        out.focus_code()
      end,
    })
  end,
  event = 'VeryLazy',
  dependencies = {
    'epheien/outline-treesitter-provider.nvim',
    'joeledwardson/joels-lua-utils',
  },
}
