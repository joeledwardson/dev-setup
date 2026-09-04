-- Telescope Tutorial: step-by-step from bare minimum to custom pickers
-- Run :Example1 through :Example9 in order. Each builds on the last.
-- Reload after edits:  :luafile %

local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local sorters = require('telescope.sorters')
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')

-------------------------------------------------------------------------------
-- EXAMPLE 1: Bare minimum picker
-- A static list of strings + the built-in fuzzy sorter. That's it.
-- Try typing to fuzzy-filter the list.
-------------------------------------------------------------------------------
vim.api.nvim_create_user_command('Example1', function()
  pickers.new({}, {
    prompt_title = 'Ex1: Bare Minimum',
    finder = finders.new_table { results = { 'apple', 'banana', 'cherry', 'date', 'elderberry' } },
    sorter = sorters.get_generic_fuzzy_sorter(),
  }):find()
end, {})

-------------------------------------------------------------------------------
-- EXAMPLE 2: Entry maker
-- When your data isn't plain strings, entry_maker converts each item into:
--   ordinal → the string telescope sorts/filters on
--   display → what the user sees
--   value   → the raw data (available on selection)
-------------------------------------------------------------------------------
vim.api.nvim_create_user_command('Example2', function()
  local fruits = {
    { name = 'Apple', color = 'red', calories = 95 },
    { name = 'Banana', color = 'yellow', calories = 105 },
    { name = 'Blueberry', color = 'blue', calories = 84 },
    { name = 'Cherry', color = 'red', calories = 77 },
  }

  pickers.new({}, {
    prompt_title = 'Ex2: Entry Maker',
    finder = finders.new_table {
      results = fruits,
      entry_maker = function(fruit)
        return {
          value = fruit,                                     -- raw data, untouched
          ordinal = fruit.name .. ' ' .. fruit.color,        -- searchable text
          display = fruit.name .. ' (' .. fruit.color .. ')', -- visible text
        }
      end,
    },
    sorter = sorters.get_generic_fuzzy_sorter(),
  }):find()
end, {})

-------------------------------------------------------------------------------
-- EXAMPLE 3: Multi-column display
-- Use string.format in entry_maker for tabular layout.
-- Each item is a table (array): { col1, col2, col3 }.
-------------------------------------------------------------------------------
vim.api.nvim_create_user_command('Example3', function()
  local entries = {
    { 'GET', '/api/users', '200 OK' },
    { 'POST', '/api/users', '201 Created' },
    { 'DELETE', '/api/users/1', '204 No Content' },
    { 'GET', '/api/posts', '200 OK' },
    { 'PUT', '/api/posts/5', '404 Not Found' },
  }

  pickers.new({}, {
    prompt_title = 'Ex3: Multi-Column (try typing "GET" or "404")',
    finder = finders.new_table {
      results = entries,
      entry_maker = function(item)
        return {
          value = item,
          ordinal = table.concat(item, ' '),                  -- all columns searchable
          display = string.format('%-8s %-20s %s', unpack(item)), -- aligned columns
        }
      end,
    },
    sorter = sorters.get_generic_fuzzy_sorter(),
  }):find()
end, {})

-------------------------------------------------------------------------------
-- EXAMPLE 4: Custom sorter basics
-- Sorter:new lets you define scoring_function(self, prompt, line).
-- The `line` argument is the entry's `display` string.
--
-- Return values:
--   -1  → FILTERED (hidden from results)
--    0  → best match (shown first)
--    1  → normal match
--    2+ → worse match (shown later)
--
-- This example: only shows entries containing the exact prompt substring.
-- (No fuzzy matching — much simpler to reason about.)
-------------------------------------------------------------------------------
vim.api.nvim_create_user_command('Example4', function()
  pickers.new({}, {
    prompt_title = 'Ex4: Custom Sorter (exact substring, try "error")',
    finder = finders.new_table {
      results = {
        '[INFO]  server started on :8080',
        '[ERROR] connection refused',
        '[WARN]  disk usage at 90%',
        '[ERROR] out of memory',
        '[INFO]  request handled in 23ms',
        '[DEBUG] query: SELECT * FROM users',
      },
    },
    sorter = sorters.Sorter:new {
      scoring_function = function(_, prompt, line)
        if prompt == '' then return 1 end -- empty prompt → show everything

        if line:lower():find(prompt:lower(), 1, true) then
          return 0 -- match → show it
        end
        return -1   -- no match → filter out
      end,
      highlighter = function() return {} end, -- no highlights (keep it simple)
    },
  }):find()
end, {})

-------------------------------------------------------------------------------
-- EXAMPLE 5: Scoring priorities
-- Same as Ex4, but now we RANK results: exact matches score better.
-- Lower score = shown higher in results.
--
-- Try typing "error" — the [ERROR] lines appear above others.
-------------------------------------------------------------------------------
vim.api.nvim_create_user_command('Example5', function()
  pickers.new({}, {
    prompt_title = 'Ex5: Scoring Priorities (try "error")',
    finder = finders.new_table {
      results = {
        '[INFO]  no errors today',
        '[ERROR] connection refused',
        '[WARN]  error rate increasing',
        '[ERROR] out of memory',
        '[DEBUG] error_handler registered',
      },
    },
    sorter = sorters.Sorter:new {
      scoring_function = function(_, prompt, line)
        if prompt == '' then return 1 end
        local lower_line = line:lower()
        local lower_prompt = prompt:lower()

        if not lower_line:find(lower_prompt, 1, true) then return -1 end -- no match

        -- Exact start of a word → best score
        if lower_line:find('%f[%w]' .. lower_prompt) then return 0 end

        -- Substring match → ok score
        return 1
      end,
      highlighter = function() return {} end,
    },
  }):find()
end, {})

-------------------------------------------------------------------------------
-- EXAMPLE 6: Two-level "mode pattern" filtering
-- This is the technique from keybrowser.lua.
-- First word = exact filter on column 1 (the "mode").
-- Rest = substring match on the remaining columns.
-- If no mode matches, fall back to plain substring on everything.
--
-- Try: "GET api"  → only GET requests matching "api"
--      "404"      → any row containing "404"
--      "POST"     → only POST (mode filter, no pattern needed)
-------------------------------------------------------------------------------
vim.api.nvim_create_user_command('Example6', function()
  local entries = {
    { 'GET', '/api/users', '200 OK' },
    { 'POST', '/api/users', '201 Created' },
    { 'DELETE', '/api/users/1', '204 No Content' },
    { 'GET', '/api/posts', '200 OK' },
    { 'GET', '/health', '200 OK' },
    { 'PUT', '/api/posts/5', '404 Not Found' },
  }

  pickers.new({}, {
    prompt_title = 'Ex6: Mode+Pattern (try "GET api" or "404")',
    finder = finders.new_table {
      results = entries,
      entry_maker = function(item)
        return {
          value = item,
          ordinal = table.concat(item, ' '),
          display = string.format('%-8s %-20s %s', unpack(item)),
        }
      end,
    },
    sorter = sorters.Sorter:new {
      discard = false,
      highlighter = function() return {} end,
      scoring_function = function(_, prompt, line)
        if prompt == '' then return 1 end

        local filter, pattern = prompt:match('^(%S+)%s+(.+)$')
        if filter and pattern then
          local first = line:match('^(%S+)')
          if first == filter then
            -- mode matched → check rest of line for pattern
            local rest = line:sub(#first + 2):lower()
            return rest:find(pattern:lower(), 1, true) and 0 or -1
          end
          -- first word didn't match a mode → fall through to substring
        end

        return line:lower():find(prompt:lower(), 1, true) and 1 or -1
      end,
    },
  }):find()
end, {})

-------------------------------------------------------------------------------
-- EXAMPLE 7: Custom action on selection
-- attach_mappings lets you override what <CR> does.
--
-- Pattern:
--   1. Get the selected entry via action_state.get_selected_entry()
--   2. Close the picker via actions.close(buf)
--   3. Do something with entry.value
-------------------------------------------------------------------------------
vim.api.nvim_create_user_command('Example7', function()
  local commands = {
    { key = 'gd', action = 'Go to definition', cmd = 'lua vim.lsp.buf.definition()' },
    { key = 'gr', action = 'Find references', cmd = 'lua vim.lsp.buf.references()' },
    { key = 'K', action = 'Hover docs', cmd = 'lua vim.lsp.buf.hover()' },
  }

  pickers.new({}, {
    prompt_title = 'Ex7: Custom Action (press <CR> to run)',
    finder = finders.new_table {
      results = commands,
      entry_maker = function(item)
        return {
          value = item,
          ordinal = item.key .. ' ' .. item.action,
          display = string.format('%-6s %s', item.key, item.action),
        }
      end,
    },
    sorter = sorters.get_generic_fuzzy_sorter(),

    -- This is the key part: override what Enter does
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local entry = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if entry then
          vim.notify('Would run: ' .. entry.value.cmd, vim.log.levels.INFO)
        end
      end)
      return true -- keep default mappings for everything else
    end,
  }):find()
end, {})

-------------------------------------------------------------------------------
-- EXAMPLE 8: Shell command as data source
-- new_oneshot_job runs a command and uses each output line as an entry.
-- Great for: git log, find, ls, rg, any CLI tool.
-------------------------------------------------------------------------------
vim.api.nvim_create_user_command('Example8', function()
  pickers.new({}, {
    prompt_title = 'Ex8: Shell Command (ls -la output)',
    finder = finders.new_oneshot_job(
      { 'ls', '-la', vim.fn.expand('~') },
      { entry_maker = function(line)
          return { value = line, ordinal = line, display = line }
        end,
      }
    ),
    sorter = sorters.get_generic_fuzzy_sorter(),
  }):find()
end, {})

-------------------------------------------------------------------------------
-- EXAMPLE 9: Putting it all together
-- Mini keybrowser: multi-column, mode filtering, custom action.
-- Combines entry_maker + custom sorter + attach_mappings.
-------------------------------------------------------------------------------
vim.api.nvim_create_user_command('Example9', function()
  -- Static data simulating keybindings from different modes
  local bindings = {
    { 'normal', 'dd', 'Delete line' },
    { 'normal', 'yy', 'Yank line' },
    { 'normal', 'p', 'Paste after cursor' },
    { 'normal', 'u', 'Undo' },
    { 'insert', '<C-w>', 'Delete word before cursor' },
    { 'insert', '<C-u>', 'Delete to start of line' },
    { 'insert', '<Esc>', 'Exit insert mode' },
    { 'visual', 'd', 'Delete selection' },
    { 'visual', 'y', 'Yank selection' },
    { 'visual', '>', 'Indent selection' },
  }

  pickers.new({}, {
    prompt_title = 'Ex9: Mini Keybrowser (try "normal yank" or "delete")',
    finder = finders.new_table {
      results = bindings,

      -- STEP A: entry_maker turns each row into a telescope entry
      entry_maker = function(item)
        return {
          value = item,
          ordinal = table.concat(item, ' '),
          display = string.format('%-8s %-12s %s', item[1], item[2], item[3]),
        }
      end,
    },

    -- STEP B: custom sorter with mode+pattern filtering
    sorter = sorters.Sorter:new {
      discard = false,
      highlighter = function() return {} end,
      scoring_function = function(_, prompt, line)
        if prompt == '' then return 1 end

        local filter, pattern = prompt:match('^(%S+)%s+(.+)$')
        if filter and pattern then
          local first = line:match('^(%S+)')
          if first == filter then
            local rest = line:sub(#first + 2):lower()
            return rest:find(pattern:lower(), 1, true) and 0 or -1
          end
        end

        return line:lower():find(prompt:lower(), 1, true) and 1 or -1
      end,
    },

    -- STEP C: custom action on Enter
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local entry = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if entry then
          local row = entry.value
          vim.notify(row[1] .. ' mode: ' .. row[2] .. ' → ' .. row[3])
        end
      end)
      return true
    end,
  }):find()
end, {})
