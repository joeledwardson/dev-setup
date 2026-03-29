-- Telescope picker for built-in vim keys, parsed from $VIMRUNTIME/doc/index.txt
local M = {}

local function parse()
  local ok, lines = pcall(vim.fn.readfile, vim.env.VIMRUNTIME .. '/doc/index.txt')
  if not ok then return {} end

  local entries = {}
  local mode = nil

  for _, line in ipairs(lines) do
    -- detect which mode section we're in
    if line:match '%*insert%-index%*' then mode = 'i'
    elseif line:match '%*normal%-index%*' then mode = 'n'
    elseif line:match '%*objects%*' then mode = 'o/v'
    elseif line:match '%*CTRL%-W%*' then mode = 'n'
    elseif line:match '%*operator%-pending%-index%*' then mode = 'o'
    elseif line:match '%*visual%-index%*' then mode = 'x'
    end

    -- match lines like: |tag|  key  description
    if mode then
      local tag, rest = line:match '^|([^|]+)|%s+(.*)'
      if tag then
        local key, desc = rest:match '^(.-)%s%s+(.+)'
        if key and key ~= '' then
          desc = desc:gsub('^[0-9,]+%s+', '') -- strip note numbers
          if not desc:match '^not used' then
            entries[#entries + 1] = { mode = mode, lhs = key, desc = desc, tag = tag }
          end
        end
      end
    end
  end

  return entries
end

function M.open()
  require('telescope.pickers')
    .new({}, {
      prompt_title = 'Vim Built-in Keys',
      finder = require('telescope.finders').new_table {
        results = parse(),
        entry_maker = function(item)
          return {
            value = item,
            ordinal = item.mode .. ' ' .. item.lhs,
            display = string.format('%-5s %-25s %s', item.mode, item.lhs, item.desc),
          }
        end,
      },
      sorter = require('telescope.config').values.generic_sorter {},
      attach_mappings = function(prompt_bufnr)
        require('telescope.actions').select_default:replace(function()
          require('telescope.actions').close(prompt_bufnr)
          local sel = require('telescope.actions.state').get_selected_entry()
          if sel and sel.value.tag then pcall(vim.cmd, 'help ' .. sel.value.tag) end
        end)
        return true
      end,
    })
    :find()
end

return M
