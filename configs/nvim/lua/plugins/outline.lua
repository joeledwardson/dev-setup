vim.keymap.set('n', '<leader>tl', '<cmd>Outline<CR>', { desc = 'Toggle Outline' })
require('outline').setup {
  auto_jump = true,
  providers = {
    priority = { 'lsp', 'coc', 'markdown', 'norg', 'treesitter', 'man' },
  },
  lsp = {
    blacklist_clients = { 'postgres_lsp' },
  },
  treesitter = {
    filetypes = { 'sql' }, -- ensure treesitter only activates for sql filetype
  },
}

local utils = require 'joels-lua-utils'

vim.api.nvim_create_autocmd('QuitPre', {
  desc = 'close outline window automatically',
  callback = function()
    local active_win_id = vim.api.nvim_get_current_win()
    local active_page_id = vim.api.nvim_win_get_tabpage(active_win_id)
    local page_wins = vim.api.nvim_tabpage_list_wins(active_page_id)
    local outline_win_id = utils.find(page_wins, function(win_id)
      local buf_id = vim.api.nvim_win_get_buf(win_id)
      return vim.bo[buf_id].filetype == 'Outline'
    end)
    local filtered = utils.filter(page_wins, function(win_id)
      local win_type = vim.fn.win_gettype(win_id)
      local win_config = vim.api.nvim_win_get_config(win_id)
      return win_type == '' and win_config.relative == '' and win_id ~= active_win_id and win_id ~= outline_win_id
    end)
    if #filtered == 0 and outline_win_id ~= nil then
      require('outline').close_outline()
    end
  end,
})

vim.api.nvim_create_autocmd('BufWinEnter', {
  desc = 'attach outline to new help and man pages',
  callback = function(ev)
    local bufopts = vim.bo[ev.buf]
    local matches = bufopts.filetype == 'man' or bufopts.filetype == 'help'
    if not matches then
      return
    end
    local current_win = vim.api.nvim_get_current_win()
    local page_id = vim.api.nvim_win_get_tabpage(current_win)
    vim.schedule(function()
      local win_count = #(
        utils.filter(vim.api.nvim_tabpage_list_wins(page_id), function(win_id)
          local win_type = vim.fn.win_gettype(win_id)
          local win_config = vim.api.nvim_win_get_config(win_id)
          local buf_id = vim.api.nvim_win_get_buf(win_id)
          return win_type == '' and win_config.relative == '' and vim.bo[buf_id].filetype ~= 'Outline'
        end)
      )
      if win_count > 1 then
        vim.cmd 'wincmd T'
      end
      local out = require 'outline'
      out.open_outline()
      out.focus_code()
    end)
  end,
})
