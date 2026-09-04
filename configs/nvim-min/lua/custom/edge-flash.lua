-- Flash the current window when C-hjkl can't move further.
--
-- Subsequent presses while a flash is already running are no-ops — one flash
-- per "burst" is enough confirmation of the edge. That removes the race that
-- would otherwise leave the window stuck red after rapid mashing.

local M = {}

local FLASH_MS = 150
local FLASH_HL = 'EdgeFlash'

vim.api.nvim_set_hl(0, FLASH_HL, { bg = '#3a1414', default = true })

-- per-window: stores the original winhighlight while a flash is in flight.
local flashing = {}

local function flash(win)
  if not vim.api.nvim_win_is_valid(win) or flashing[win] then return end

  flashing[win] = vim.wo[win].winhighlight
  vim.wo[win].winhighlight = 'Normal:' .. FLASH_HL .. ',NormalNC:' .. FLASH_HL

  vim.defer_fn(function()
    if vim.api.nvim_win_is_valid(win) then
      vim.wo[win].winhighlight = flashing[win] or ''
    end
    flashing[win] = nil
  end, FLASH_MS)
end

function M.move(direction)
  local before = vim.api.nvim_get_current_win()
  vim.cmd('wincmd ' .. direction)
  if before == vim.api.nvim_get_current_win() then
    flash(before)
  end
end

function M.setup()
  for _, dir in ipairs({ 'h', 'j', 'k', 'l' }) do
    vim.keymap.set('n', '<C-' .. dir .. '>', function() M.move(dir) end, { desc = 'wincmd ' .. dir .. ' (flash on edge)' })
  end
end

return M
