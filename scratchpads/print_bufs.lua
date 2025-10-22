---@generic T
---@param tbl T[]
---@param func fun(item: T): boolean
---@return T | nil
local find = function(tbl, func)
  for _, item in ipairs(tbl) do
    if func(item) then
      return item
    end
  end
  return nil
end

---@generic T
---@param tbl T[]
---@param func fun(item: T): boolean
---@return T[]
local filter = function(tbl, func)
  local filtered = {}
  for _, item in ipairs(tbl) do
    if func(item) then
      table.insert(filtered, item)
    end
  end
  return filtered
end

local current_buf = vim.api.nvim_get_current_buf()

local not_string = function(value)
  return not value and ' NOT ' or ' '
end

local pages = vim.api.nvim_list_tabpages()
for pageindex, pageid in ipairs(pages) do
  print('\n\n\npage ' .. pageindex .. ' with ID ' .. pageid)
  local pagewins = vim.api.nvim_tabpage_list_wins(pageid)
  for win_index, win_id in ipairs(pagewins) do
    print('\nprocessing window #' .. win_index .. ', ID: ' .. win_id)

    local win_config = vim.api.nvim_win_get_config(win_id)
    print('window config is: ', vim.inspect(win_config))
    print('window type is: ', vim.fn.win_gettype(win_id))

    local buf_id = vim.api.nvim_win_get_buf(win_id)
    print('window buffer id is ' .. buf_id)
    local bo = vim.bo[buf_id]
    print('buffer is ', vim.api.nvim_buf_is_valid(buf_id) and 'valid' or 'NOT VALID')

    print('buffer file type is ' .. bo.filetype)
    print('buffer  BUF type is ' .. bo.buftype)
    print('buffer name is ' .. vim.api.nvim_buf_get_name(buf_id))
    print('buffer is' .. (not bo.buflisted and ' NOT ' or ' ') .. 'listed')

    if current_buf == buf_id then
      print 'is active buffer!'
    end
  end
end
