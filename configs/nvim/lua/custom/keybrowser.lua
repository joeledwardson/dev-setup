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

        -- "mode pattern" filter: first word must match first column exactly
        local filter, pattern = prompt:match('^(%S+)%s+(.+)$')
        if filter and pattern then
          local first = line:match('^(%S+)')
          if first == filter then
            local rest = line:sub(#first + 2):lower()
            local ok, hit = pcall(string.match, rest, pattern:lower())
            return (ok and hit) and 0 or -1
          end
        end

        -- plain substring fallback (handles "alt shift", multi-word searches, etc.)
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

-- Zellij keybindings, parsed from config.kdl using treesitter
-- Config: $ZELLIJ_CONFIG_FILE or ~/.config/zellij/config.kdl
--
-- KDL example:
--   keybinds {              ← top-level, we find this by name
--     resize {              ← mode block (e.g. resize, pane, session, shared_except)
--       bind "h" "Left" {   ← bind: quoted strings are the keys
--         Resize "Left";    ← action: name + quoted args
--       }
--     }
--   }
--
-- In the treesitter tree, everything is a "node" with an "identifier".
-- The helpers below navigate this uniform structure:
--   kdl_name(node)     → the identifier text ("keybinds", "resize", "bind", "Resize")
--   kdl_str_args(node) → the quoted string arguments ("h", "Left")
--   kdl_body(node)     → the child nodes inside its { } block
function M.open_zellij()
  local config_path = vim.env.ZELLIJ_CONFIG_FILE or vim.fn.expand('~/.config/zellij/config.kdl')
  local source = table.concat(vim.fn.readfile(config_path), '\n')
  local tree = vim.treesitter.get_string_parser(source, 'kdl'):parse()[1]

  local function txt(node) return vim.treesitter.get_node_text(node, source) end

  local function kdl_name(node)
    for child in node:iter_children() do
      if child:type() == 'identifier' then return txt(child) end
    end
  end

  local function kdl_str_args(node)
    local result = {}
    for field in node:iter_children() do
      if field:type() == 'node_field' then
        for val in field:iter_children() do
          if val:type() == 'value' then
            result[#result + 1] = txt(val):gsub('^"', ''):gsub('"$', '')
          end
        end
      end
    end
    return result
  end

  local function kdl_body(node)
    local result = {}
    for child in node:iter_children() do
      if child:type() == 'node_children' then
        for inner in child:iter_children() do
          if inner:type() == 'node' then result[#result + 1] = inner end
        end
      end
    end
    return result
  end

  local function describe_bind(bind_node)
    local parts = {}
    for _, action in ipairs(kdl_body(bind_node)) do
      local action_name = kdl_name(action)
      if not action_name then goto next end
      local action_args = kdl_str_args(action)
      if #action_args > 0 then action_name = action_name .. ' ' .. table.concat(action_args, ' ') end
      parts[#parts + 1] = action_name
      ::next::
    end
    return table.concat(parts, '; ')
  end

  -- find the keybinds block at the top level, then walk mode → bind
  local entries = {}
  for top in tree:root():iter_children() do
    if top:type() ~= 'node' or kdl_name(top) ~= 'keybinds' then goto next_top end

    for _, mode in ipairs(kdl_body(top)) do
      local mode_name = kdl_name(mode)
      for _, bind in ipairs(kdl_body(mode)) do
        if kdl_name(bind) ~= 'bind' then goto next_bind end
        local description = describe_bind(bind)
        for _, key in ipairs(kdl_str_args(bind)) do
          entries[#entries + 1] = { mode_name, key, description }
        end
        ::next_bind::
      end
    end

    ::next_top::
  end

  pick('Zellij Keybindings (e.g. "session detach")', entries, { fmt = '%-16s %-20s %s' })
end

-- pgcli keybindings, parsed from installed key_bindings.py (found via `which pgcli`)
local function pgcli_friendly_key(key)
  if key:match('^c%-') then return 'Ctrl-' .. key:sub(3):upper() end
  if key:match('^f%d+$') then return key:upper() end
  return key:sub(1, 1):upper() .. key:sub(2)
end

function M.open_pgcli()
  local pgcli_bin = vim.fn.exepath('pgcli')
  if pgcli_bin == '' then
    vim.notify('pgcli not found in PATH', vim.log.levels.WARN)
    return
  end
  local base = vim.fn.resolve(pgcli_bin):match('(.+)/bin/')
  local kb_path = base and vim.fn.glob(base .. '/lib/*/site-packages/pgcli/key_bindings.py') or ''
  if kb_path == '' then
    vim.notify('pgcli: key_bindings.py not found', vim.log.levels.WARN)
    return
  end

  local lines = vim.fn.readfile(kb_path)
  local entries = {}
  local buf, depth, current_keys = '', 0, nil

  for _, line in ipairs(lines) do
    -- accumulate @kb.add(...) across lines, tracking paren depth
    if line:match('@kb%.add%(') then
      buf, depth = line, 0
      for ch in buf:gmatch('.') do
        if ch == '(' then depth = depth + 1 elseif ch == ')' then depth = depth - 1 end
      end
    elseif depth > 0 then
      buf = buf .. ' ' .. line
      for ch in line:gmatch('.') do
        if ch == '(' then depth = depth + 1 elseif ch == ')' then depth = depth - 1 end
      end
    end

    -- decorator closed: extract quoted key names
    if buf ~= '' and depth <= 0 then
      local keys = {}
      for key in buf:gmatch('"([^"]+)"') do
        keys[#keys + 1] = pgcli_friendly_key(key)
      end
      if #keys > 0 then current_keys = table.concat(keys, ' + ') end
      buf, depth = '', 0
    end

    -- capture first line of docstring after the decorated function
    if current_keys and depth == 0 then
      local doc = line:match('^%s+"""(.-)"""') or line:match('^%s+"""(.+)$')
      if doc and vim.trim(doc) ~= '' then
        entries[#entries + 1] = { current_keys, vim.trim(doc) }
        current_keys = nil
      end
    end
  end

  pick('pgcli Keybindings', entries, { fmt = '%-25s %s' })
end

return M
