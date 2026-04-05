-- Telescope pickers for browsing keybindings (vim, zsh, telescope)
local M = {}

-- Shared picker with "mode pattern" filtering.
-- First word filters the first column exactly, rest is a lua pattern on the remainder.
-- e.g. "n p" shows normal-mode entries matching "p"
local function pick(title, entries, columns)
  local sorters = require('telescope.sorters')

  require('telescope.pickers').new({}, {
    prompt_title = title,
    finder = require('telescope.finders').new_table {
      results = entries,
      entry_maker = function(item)
        return {
          value = item,
          ordinal = table.concat(item, ' '),
          display = string.format(columns.fmt, unpack(item)),
        }
      end,
    },
    sorter = sorters.Sorter:new {
      discard = false,
      highlighter = function() return {} end,
      scoring_function = function(_, prompt, line)
        if not prompt or prompt == '' then return 1 end

        local filter, pattern = prompt:match('^(%S+)%s+(.+)$')
        if filter and pattern then
          local first = line:match('^(%S+)')
          if first ~= filter then return -1 end
          local rest = line:sub(#first + 2):lower()
          local ok, hit = pcall(string.match, rest, pattern:lower())
          return (ok and hit) and 0 or -1
        end

        return line:lower():find(prompt:lower(), 1, true) and 1 or -1
      end,
    },
    attach_mappings = columns.on_select and function(buf)
      require('telescope.actions').select_default:replace(function()
        require('telescope.actions').close(buf)
        columns.on_select(require('telescope.actions.state').get_selected_entry())
      end)
      return true
    end or nil,
  }):find()
end

-- Vim built-in keys from $VIMRUNTIME/doc/index.txt
function M.open()
  local lines = vim.fn.readfile(vim.env.VIMRUNTIME .. '/doc/index.txt')
  local entries = {}
  local mode

  for _, line in ipairs(lines) do
    if line:match '%*insert%-index%*' then mode = 'i'
    elseif line:match '%*normal%-index%*' then mode = 'n'
    elseif line:match '%*objects%*' then mode = 'o/v'
    elseif line:match '%*CTRL%-W%*' then mode = 'n'
    elseif line:match '%*operator%-pending%-index%*' then mode = 'o'
    elseif line:match '%*visual%-index%*' then mode = 'x'
    end

    if mode then
      local tag, rest = line:match('^|([^|]+)|%s+(.*)')
      if tag then
        local key, desc = rest:match('^(.-)%s%s+(.+)')
        if key and key ~= '' then
          desc = desc:gsub('^[0-9,]+%s+', '')
          if not desc:match('^not used') then
            entries[#entries + 1] = { mode, key, desc, tag = tag }
          end
        end
      end
    end
  end

  pick('Vim Built-in Keys (e.g. "n p")', entries, {
    fmt = '%-5s %-25s %s',
    on_select = function(sel)
      if sel and sel.value.tag then pcall(vim.cmd, 'help ' .. sel.value.tag) end
    end,
  })
end

-- Zsh keybindings via `bindkey -M <keymap>`
local friendly_keys = {
  ['^[OA'] = 'Up (SS3)', ['^[OB'] = 'Down (SS3)', ['^[OC'] = 'Right (SS3)', ['^[OD'] = 'Left (SS3)',
  ['^[[A'] = 'Up', ['^[[B'] = 'Down', ['^[[C'] = 'Right', ['^[[D'] = 'Left',
  ['^[[H'] = 'Home', ['^[[F'] = 'End', ['^[[200~'] = 'BracketedPaste',
  ['^[[3~'] = 'Delete', ['^[[2~'] = 'Insert', ['^[[5~'] = 'PageUp', ['^[[6~'] = 'PageDown',
  ['^['] = 'Esc', ['^?'] = 'Backspace', ['^I'] = 'Tab',
  ['^J'] = 'Enter (LF)', ['^M'] = 'Enter (CR)', ['^H'] = 'Ctrl-H (BS)', [' '] = 'Space',
}

local function friendly_key(raw)
  if friendly_keys[raw] then return friendly_keys[raw] end
  if raw:match('^%^%[(.+)$') then return 'Alt-' .. friendly_key(raw:match('^%^%[(.+)$')) end
  if raw:match('^%^(.)$') then return 'Ctrl-' .. raw:match('^%^(.)$'):upper() end
  return raw
end

function M.open_zsh()
  local entries = {}
  for _, keymap in ipairs({ 'vicmd', 'viins', 'visual', 'emacs', 'isearch', 'command', 'viopp' }) do
    local output = vim.fn.system('zsh -c "bindkey -M ' .. keymap .. '" 2>/dev/null')
    for line in output:gmatch('[^\n]+') do
      local key, widget = line:match('^"(.-)"%s+(.+)$')
      if not key then
        local rs, re, w = line:match('^"(.-)"-"(.-)"%s+(.+)$')
        if rs then key, widget = rs .. '-' .. re, w end
      end
      if key and widget ~= 'self-insert' and widget ~= 'undefined-key' then
        entries[#entries + 1] = { keymap, friendly_key(key), widget }
      end
    end
  end
  pick('Zsh Keybindings (e.g. "vicmd kill")', entries, { fmt = '%-8s %-25s %s' })
end

-- Telescope's own keybindings, queried from runtime config
function M.open_telescope()
  local defaults = require('telescope.mappings').default_mappings or {}
  local user = require('telescope.config').values.mappings or {}
  local seen = {}

  -- user maps override defaults
  for _, source in ipairs({ defaults, user }) do
    for mode, maps in pairs(source) do
      for key, action in pairs(maps) do
        if action == false then
          seen[mode .. key] = nil
        else
          -- extract readable name from action objects
          local name
          if type(action) == 'table' then
            local parts = {}
            for _, v in ipairs(action) do
              if type(v) == 'string' then parts[#parts + 1] = v end
            end
            name = #parts > 0 and table.concat(parts, ' + ') or tostring(action)
          else
            name = tostring(action)
          end
          seen[mode .. key] = { mode, key, name }
        end
      end
    end
  end

  local entries = vim.tbl_values(seen)
  table.sort(entries, function(a, b)
    return a[1] .. a[2] < b[1] .. b[2]
  end)
  pick('Telescope Keybindings (e.g. "i close")', entries, { fmt = '%-4s %-15s %s' })
end

return M
