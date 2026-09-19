local tabby = require 'tabby'
tabby.setup { preset = 'tab_only' }

vim.o.showtabline = 2
-- Tabby's documented session support; session-manager already uses :mksession.
vim.opt.sessionoptions:append { 'tabpages', 'globals' }

vim.keymap.set('n', '<leader>Tr', function()
  vim.ui.input({ prompt = 'Tab name (empty resets): ' }, function(name)
    if name ~= nil then
      tabby.tab_rename(name)
    end
  end)
end, { desc = 'Rename tab' })
vim.keymap.set('n', '<leader>Tp', function()
  local tab_name = require 'tabby.feature.tab_name'
  local tabs = vim.tbl_map(function(tab)
    return { id = tab, label = string.format('%d: %s', vim.api.nvim_tabpage_get_number(tab), tab_name.get(tab)) }
  end, vim.api.nvim_list_tabpages())
  -- The existing telescope-ui-select extension supplies the searchable popup.
  vim.ui.select(tabs, {
    prompt = 'Tabs',
    format_item = function(tab)
      return tab.label
    end,
  }, function(tab)
    if tab and vim.api.nvim_tabpage_is_valid(tab.id) then
      vim.api.nvim_set_current_tabpage(tab.id)
    end
  end)
end, { desc = 'Search tabs' })
vim.keymap.set('n', '<leader>Tn', '<cmd>tabnew<CR>', { desc = 'New tab' })
vim.keymap.set('n', '<leader>Tc', '<cmd>tabclose<CR>', { desc = 'Close tab' })
