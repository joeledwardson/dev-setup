-- Pull in the wezterm API (see https://github.com/DrKJeff16/wezterm-types)
---@type Wezterm
local wezterm = require 'wezterm'

--- track "global" status of whether we are in norma/copy or search mode
local global_key_table = ''

-- Debug: print when config loads
wezterm.log_info 'Loading WezTerm config from dev-setup'

wezterm.warn_about_missing_glyphs = false

-- This will hold the configuration.
---@type Config
local config = wezterm.config_builder()
config.disable_default_key_bindings = true
config.font = wezterm.font 'SpaceMonoNF'

-- Pane focus indication - make inactive panes much more obvious
config.inactive_pane_hsb = {
  saturation = 0.1, -- Much less color for inactive panes
  brightness = 0.15, -- Much darker inactive panes
}

-- Define colors including split lines
config.colors = {
  compose_cursor = 'orange',
  tab_bar = {
    background = '#1a202c',
    active_tab = {
      bg_color = '#805ad5', -- purple for active tab (default)
      fg_color = '#ffffff',
    },
    inactive_tab = {
      bg_color = '#1b1032',
      fg_color = '#808080',
    },
    inactive_tab_hover = {
      bg_color = '#2d3748',
      fg_color = '#a0aec0',
    },
  },
}

local MOD_KEY = 'ALT'
local act = wezterm.action

--- make pane background red as a warning briefly
local function pane_warning(window)
  local overrides = window:get_config_overrides() or {}
  overrides.colors = overrides.colors or {}
  local colours = overrides.colors
  colours.background = 'rgb(115,5,5)'
  window:set_config_overrides(overrides)
  wezterm.time.call_after(0.2, function()
    local post_overrides = window:get_config_overrides() or {}
    post_overrides.colors = { background = nil }
    window:set_config_overrides(post_overrides)
  end)
end

--- check pane is available in direction beofre moving, show warning if not
---@param window Window
---@param pane Pane
---@param direction PaneDirection
local function move_pane(window, pane, direction)
  local tab = window:active_tab()
  local new_pane = tab:get_pane_direction(direction)
  if new_pane == nil then
    pane_warning(window)
  else
    window:perform_action(act.ActivatePaneDirection(direction), pane)
  end
end

--- get 1 based index of active tab (0) if not found
---@param window  Window
local function get_tab_index(window)
  local tabs = window:mux_window():tabs()
  local active_id = window:active_tab():tab_id()

  for i = 1, #tabs do
    local tab_id = tabs[i]:tab_id()
    if tab_id == active_id then
      return i
    end
  end
  return 0
end

--- same as `ActivateTabRelative` but flashes error if at end rather than wrapping around
---@param window  Window
---@param pane Pane
---@param direction 'left' | 'right'
local function focus_relative_tab(window, pane, direction)
  print('hi!, moving ', direction)
  local pos = get_tab_index(window)
  local last_index = #window:mux_window():tabs()
  print('pos: ', pos, ', tabs: ', last_index, ', direction: ', direction)

  if not pos or (pos == 1 and direction == 'left') or (pos == last_index and direction == 'right') then
    pane_warning(window)
  else
    window:perform_action(act.ActivateTabRelative(direction == 'right' and 1 or -1), pane)
  end
end

--- same as `MoveTabRelative` but flashes error if at end rather than wrapping around
---@param window  Window
---@param pane Pane
---@param direction 'left' | 'right'
local function move_relative_tab(window, pane, direction)
  print 'hi there pls!'
  local current_index = get_tab_index(window)
  window:perform_action(act.MoveTabRelative(direction == 'left' and -1 or 1), pane)
  local new_index = get_tab_index(window)
  if current_index == new_index then
    pane_warning(window)
  end
end

-- Add the plugin
-- doesnt work?
-- TODO
-- local pivot_panes = wezterm.plugin.require("https://github.com/chrisgve/pivot_panes.wezterm")

config.keys = {
  --
  -- joels custom commands
  --
  -- go into copy mode and copy back to last command
  {
    key = 'p',
    mods = 'ALT|SHIFT',
    action = wezterm.action_callback(function(window, pane)
      window:perform_action(act.ActivateCopyMode, pane)
      local selected_text = window:get_selection_text_for_pane(pane)
      if selected_text == '' then
        -- empty text, reset copy mode and enable it
        window:perform_action(act.CopyMode 'ClearSelectionMode', pane)
        window:perform_action(act.CopyMode { SetSelectionMode = 'Line' }, pane)
      end
      window:perform_action(
        act.Multiple {
          act.CopyMode 'MoveBackwardSemanticZone',
          act.CopyMode 'MoveUp',
        },
        pane
      )
    end),
  },
  {
    key = 'y',
    mods = 'ALT|SHIFT',
    action = act.SwitchToWorkspace {
      name = 'default',
    },
  }, -- Switch to a monitoring workspace, which will have `top` launched into it
  {
    key = 'u',
    mods = 'ALT|SHIFT',
    action = act.SwitchToWorkspace {
      name = 'monitoring',
      spawn = {
        args = { 'top' },
      },
    },
  },
  -- Create a new workspace with a random name and switch to it
  { key = 'i', mods = 'ALT|SHIFT', action = act.SwitchToWorkspace },
  -- Show the launcher in fuzzy selection mode and have it list all workspaces
  -- and allow activating one.
  {
    key = 's',
    mods = 'ALT|SHIFT',
    action = act.ShowLauncherArgs {
      flags = 'FUZZY|WORKSPACES',
    },
  },
  --
  -- JOELS TESTING
  --
  {
    key = 'o',
    mods = MOD_KEY,
    action = wezterm.action_callback(function(window, pane)
      print('printing current working dir: ', pane:get_current_working_dir())
    end),
  },
  {
    key = '\\',
    mods = MOD_KEY,
    action = act.CharSelect {},
  },

  -- pane splits
  --
  {
    key = 's',
    mods = MOD_KEY,
    action = act.SplitVertical {},
  },

  {
    key = 'v',
    mods = MOD_KEY,
    action = act.SplitHorizontal {},
  },
  -- plugin doesnt work
  -- { key = "i", mods = MOD_KEY, action = wezterm.action_callback(pivot_panes.toggle_orientation_callback) },

  --
  -- pane navigation
  --
  {
    key = 'j',
    mods = MOD_KEY,
    action = wezterm.action_callback(function(window, pane)
      move_pane(window, pane, 'Down')
    end),
  },
  {
    key = 'k',
    mods = MOD_KEY,
    action = wezterm.action_callback(function(window, pane)
      move_pane(window, pane, 'Up')
    end),
  },
  {
    key = 'h',
    mods = MOD_KEY,
    action = wezterm.action_callback(function(window, pane)
      move_pane(window, pane, 'Left')
    end),
  },
  {
    key = 'l',
    mods = MOD_KEY,
    action = wezterm.action_callback(function(window, pane)
      move_pane(window, pane, 'Right')
    end),
  },
  { key = 'q', mods = MOD_KEY, action = act.CloseCurrentPane { confirm = true } },

  --
  -- tab navigation
  --
  {
    key = ']',
    mods = MOD_KEY,
    action = wezterm.action_callback(function(window, pane, ...)
      focus_relative_tab(window, pane, 'right')
    end),
  },
  {
    key = '[',
    mods = MOD_KEY,
    action = wezterm.action_callback(function(window, pane, ...)
      focus_relative_tab(window, pane, 'left')
    end),
  },
  {
    key = '{',
    mods = 'SHIFT|ALT',
    action = wezterm.action_callback(function(window, pane, ...)
      move_relative_tab(window, pane, 'left')
    end),
  },
  {
    key = '}',
    mods = 'SHIFT|ALT',
    action = wezterm.action_callback(function(window, pane, ...)
      move_relative_tab(window, pane, 'right')
    end),
  },
  { key = 't', mods = MOD_KEY, action = act.SpawnTab 'CurrentPaneDomain' },
  { key = 'z', mods = MOD_KEY, action = act.TogglePaneZoomState },
  {
    key = ',',
    mods = MOD_KEY,
    action = act.PromptInputLine {
      description = 'Enter new title for tab',
      action = wezterm.action_callback(function(window, pane, line)
        if line then
          print('setting title: ', line)
          window:active_tab():set_title(line)
        end
      end),
    },
  },

  --
  -- entering search & copy mode
  --
  {
    key = '/',
    mods = MOD_KEY,
    action = wezterm.action_callback(function(window, pane)
      -- go into search mode first (if string is blank it preserves the old one)
      window:perform_action(act.Search { CaseInSensitiveString = '' }, pane)
      -- now in copy mode, clear the search pattern (doesnt work otherwise)
      window:perform_action(act.CopyMode 'ClearPattern', pane)
    end),
  },
  {
    key = 'c',
    mods = MOD_KEY,
    action = wezterm.action_callback(function(window, pane)
      print 'hello!'
      -- go into search mode first (if string is blank it preserves the old one)
      window:perform_action(act.ActivateCopyMode, pane)
      -- now in copy mode, clear the search pattern (doesnt work otherwise)
      window:perform_action(act.CopyMode 'ClearPattern', pane)
      -- now go to default selection mode to exit search mode
      window:perform_action(act.CopyMode 'ClearSelectionMode', pane)
    end),
  },

  --
  -- zoom
  --
  { key = '+', mods = 'CTRL', action = act.IncreaseFontSize },
  { key = '-', mods = 'CTRL', action = act.DecreaseFontSize },
  { key = '+', mods = 'CTRL|SHIFT', action = act.IncreaseFontSize },
  { key = '-', mods = 'CTRL|SHIFT', action = act.DecreaseFontSize },

  --
  -- misc
  --
  {
    key = 'u',
    mods = MOD_KEY,
    action = act.QuickSelect,
  },
  {
    key = ':',
    mods = 'ALT|SHIFT',
    action = act.ActivateCommandPalette,
  },
  { key = 'l', mods = 'CTRL|SHIFT', action = act.ShowDebugOverlay },
  { key = 'v', mods = 'CTRL|SHIFT', action = act.PasteFrom 'Clipboard' },
  { key = 'Insert', mods = 'SHIFT', action = act.PasteFrom 'Clipboard' },
}

-- format table title using [Z] if zoomed and show copy mode status
-- > took inspiration from format-window-title https://wezterm.org/config/lua/window-events/format-window-title.html
wezterm.on('format-tab-title', function(tab, pane, tabs, panes, config)
  -- start with index of tab
  local formatted = tostring(tab.tab_index + 1) .. ': '

  -- add the user defined tab title (if exists) otherwise use pane title
  if tab.tab_title and tab.tab_title:len() > 0 then
    formatted = formatted .. tab.tab_title
  else
    formatted = formatted .. (tab.active_pane.title or '')
  end

  -- add a zoomed indicator
  if tab.active_pane.is_zoomed then
    formatted = formatted .. ' [Z]'
  end

  -- this doesnt work as it will do it for every tab!
  -- i.e. every tab will have its title appended as we are not distinguishing key tables between tabs
  -- so if tab 1 in copy mode, tab2,3,4 not, then all 4 tabs will say [COPY MODE] zsh or whatever...
  -- if global_key_table == "copy_mode" then
  -- 	formatted = "[COPY MODE] " .. formatted
  -- end

  return formatted
end)

-- use alt-1..9 to navigate to tabs
for i = 1, 9 do
  table.insert(config.keys, {
    key = tostring(i),
    mods = MOD_KEY,
    action = act.ActivateTab(i - 1), -- 0 based index
  })
end

-- key tables are a strange beast in wezterm...
-- can see all key key tables by using wezterm show-keys (and with --lua to get the actual LUA code!)
-- see here https://wezterm.org/cli/show-keys.html#synopsis

-- also, can see deafult key tables
-- see https://wezterm.org/config/lua/wezterm.gui/default_key_tables.html
-- AND, from the debug buffer can get them!

-- but then, copy and search mode are in key tables (but are not mentioned in the docs on key tables here?)
-- https://wezterm.org/config/key-tables.html
-- instead, copy mode (and search mode?) is detailed in the link below (which combines both keybindings to go to copy mode and the key table?)
-- https://wezterm.org/copymode.html
-- importantly to note though, in the docs when they describe overriding key_tables = { copy_mode = .... }, we are overwriding ALL key tables (not just copy mode)! i.e. it will wipe search mode

--
-- i copied this and modified it to suit my needs from the copy mode docs page
-- somewhat confusingly the act.CopyMode is not in
-- https://wezterm.org/config/lua/keyassignment/index.html
-- but actually here
-- https://wezterm.org/config/lua/keyassignment/CopyMode/index.html
--
-- > NOTE capitals or bindings requiring shift to use are duplicated
-- It seems wezterm will pick up F as F with the 'SHIFT' modifier, not just F alone
-- But, F with 'NONE' modifier is also added to catch somewhow when 'F' is dispatched without SHIFT
--

-- store relative motion counter (i.e. the 5 pressed for 5j to go down 5 lines)
local relative_motion_counter = 0

-- store latest position of cursor
local latest_position = { x = 0, y = 0 }

---comment
---@param distance number
---@param pane Pane
local function update_motion_counter(distance, pane)
  local current_position = pane:get_cursor_position()

  -- reset motion counter if moved
  -- e.g. if someone pressed 4 then control-u and moved up we would want to discard that 4 after movement
  -- its a less complete way of wrapping every action in a reset of latest position
  if current_position.x ~= latest_position.x or current_position.y ~= latest_position.y then
    print('cursor moved from ', latest_position.x, ',', latest_position.y, ' to ', current_position.x, ',', current_position.y)
    latest_position = { x = current_position.x, y = current_position.y }
    print('resetting relative motion counter from ', relative_motion_counter, ' to 0')
    relative_motion_counter = 0
  end

  -- cap relative at max 1000 (actions are repeated on a loop, dont want to crash my pc...)
  relative_motion_counter = math.min(1000, (relative_motion_counter * 10) + distance)
end

---perform the function passed number of times specified by relative motion counter
---fallback to 1 if relative motion counter not set
---@param motion function
local function perform_relative_motion(motion)
  local count = relative_motion_counter > 0 and relative_motion_counter or 1
  print('performing relative motion by ', count, ' counts')
  for _ = 1, count do
    motion()
  end
  relative_motion_counter = 0
end

--- Wraps a CopyMode action to support relative motion counts
---@param action any The CopyMode action to wrap
---@return any The wrapped action callback
local function with_relative_motion(action)
  return wezterm.action_callback(function(window, pane)
    perform_relative_motion(function()
      window:perform_action(action, pane)
    end)
  end)
end

---@param window Window
---@param pane Pane
---@param direction "up"|"down"
local function move_paragaph(window, pane, direction)
  -- Get initial newline count
  local selection = window:get_selection_text_for_pane(pane)
  local _, initial_count = selection:gsub('\n', '')
  -- if string blank then maybe no selection, maybe not in selection mode? either way clear and re-enter
  -- otherwise entering line mode (if already in line selection mode) will clear it!
  if selection == '' then
    window:perform_action(act.CopyMode 'ClearSelectionMode', pane)
    window:perform_action(act.CopyMode { SetSelectionMode = 'Line' }, pane)
  end
  print('got initial count as: ', initial_count)

  -- count of lines ONCE we encounter some new non-blank content
  local latest_count = nil

  for i = 1, 500 do
    print('processing row: ', i)
    window:perform_action(act.CopyMode(direction == 'up' and 'MoveUp' or 'MoveDown'), pane)
    local new_selection = window:get_selection_text_for_pane(pane)
    local _, new_count = new_selection:gsub('\n', '')

    -- check we have gone past a new paragrph of non-blank lines (latest count not nil)
    -- AND if the count of lines we just got matches the latest one then we must have a blank line!
    if latest_count ~= nil and new_count == latest_count then
      break
    end

    -- set the latest of lines IF we've gone past a block of non-blank liens
    if new_count ~= initial_count then
      print('updating count, got some new data!: ', new_count)
      latest_count = new_count
    end
  end
end

config.key_tables = {
  copy_mode = {
    --
    -- move to next/previous command
    --
    {
      key = 'p',
      mods = 'ALT',
      action = act.Multiple {
        act.CopyMode 'MoveBackwardSemanticZone',
      },
    },
    {
      key = 'n',
      mods = 'ALT',
      action = act.Multiple {
        act.CopyMode 'MoveForwardSemanticZone',
      },
    },
    --
    -- page up/down navigators (including vim style bindings)
    --
    {
      key = 'u',
      mods = 'CTRL',
      action = act.CopyMode { MoveByPage = -0.5 },
    },
    {
      key = 'd',
      mods = 'CTRL',
      action = act.CopyMode { MoveByPage = 0.5 },
    },
    {
      key = 'y',
      mods = 'CTRL',
      action = act.CopyMode { MoveByPage = -0.25 },
    },
    {
      key = 'e',
      mods = 'CTRL',
      action = act.CopyMode { MoveByPage = 0.25 },
    },
    { key = 'f', mods = 'CTRL', action = act.CopyMode 'PageDown' },
    { key = 'b', mods = 'CTRL', action = act.CopyMode 'PageUp' },
    { key = 'PageUp', mods = 'NONE', action = act.CopyMode 'PageUp' },
    { key = 'PageDown', mods = 'NONE', action = act.CopyMode 'PageDown' },

    --
    -- terminal style keys
    --
    { key = 'w', mods = 'CTRL', action = act.CopyMode 'ClearPattern' },

    --
    -- selection mode changes
    --
    {
      key = 'v',
      mods = 'NONE',
      action = act.CopyMode { SetSelectionMode = 'Cell' },
    },
    {
      key = 'v',
      mods = 'CTRL',
      action = act.CopyMode { SetSelectionMode = 'Block' },
    },
    {
      key = 'V',
      mods = 'NONE',
      action = act.CopyMode { SetSelectionMode = 'Line' },
    },
    {
      key = 'V',
      mods = 'SHIFT',
      action = act.CopyMode { SetSelectionMode = 'Line' },
    },
    {
      key = 'Space',
      mods = 'NONE',
      action = act.CopyMode { SetSelectionMode = 'Cell' },
    },

    --
    -- exit keys
    --
    -- mimic tmux behaviour, clear active selection otherwise quit
    {
      key = 'Escape',
      mods = 'NONE',
      action = wezterm.action_callback(function(window, pane)
        local selected_text = window:get_selection_text_for_pane(pane)
        local is_empty = not (selected_text and selected_text:len() > 0)
        if is_empty then
          print 'escape pressed and text empty, quiting copy mode...'
          window:perform_action(
            act.Multiple {
              act.ClearSelection,
              { CopyMode = 'ClearPattern' },
              { CopyMode = 'ClearSelectionMode' },
              { CopyMode = 'MoveToScrollbackBottom' },
              { CopyMode = 'Close' },
            },
            pane
          )
          return
        end
        print("esape pressed, selected text is '", selected_text, "', clearing...")
        window:perform_action(act.CopyMode 'ClearSelectionMode', pane)
      end),
    },
    -- control-c and q just exits regardless of state with copy/search
    {
      key = 'c',
      mods = 'CTRL',
      action = (act.Multiple {
        { CopyMode = 'MoveToScrollbackBottom' },
        { CopyMode = 'Close' },
      }),
    },
    {
      key = 'q',
      mods = 'NONE',
      action = (act.Multiple {
        { CopyMode = 'MoveToScrollbackBottom' },
        { CopyMode = 'Close' },
      }),
    },

    --
    -- vim style navigation keys
    --
    {
      key = '{',
      mods = 'SHIFT',
      action = wezterm.action_callback(function(window, pane)
        move_paragaph(window, pane, 'up')
      end),
    },
    {
      key = '}',
      mods = 'SHIFT',
      action = wezterm.action_callback(function(window, pane)
        move_paragaph(window, pane, 'down')
      end),
    },

    { key = 'h', mods = 'NONE', action = with_relative_motion(act.CopyMode 'MoveLeft') },
    { key = 'j', mods = 'NONE', action = with_relative_motion(act.CopyMode 'MoveDown') },
    { key = 'k', mods = 'NONE', action = with_relative_motion(act.CopyMode 'MoveUp') },
    { key = 'l', mods = 'NONE', action = with_relative_motion(act.CopyMode 'MoveRight') },
    {
      key = '$',
      mods = 'NONE',
      action = act.CopyMode 'MoveToEndOfLineContent',
    },
    {
      key = '$',
      mods = 'SHIFT',
      action = act.CopyMode 'MoveToEndOfLineContent',
    },
    { key = ',', mods = 'NONE', action = act.CopyMode 'JumpReverse' },
    { key = ';', mods = 'NONE', action = act.CopyMode 'JumpAgain' },
    {
      key = 'F',
      mods = 'NONE',
      action = act.CopyMode { JumpBackward = { prev_char = false } },
    },
    {
      key = 'F',
      mods = 'SHIFT',
      action = act.CopyMode { JumpBackward = { prev_char = false } },
    },
    {
      key = 'G',
      mods = 'NONE',
      action = act.CopyMode 'MoveToScrollbackBottom',
    },
    {
      key = 'G',
      mods = 'SHIFT',
      action = act.CopyMode 'MoveToScrollbackBottom',
    },
    { key = 'H', mods = 'NONE', action = act.CopyMode 'MoveToViewportTop' },
    {
      key = 'H',
      mods = 'SHIFT',
      action = act.CopyMode 'MoveToViewportTop',
    },
    {
      key = 'L',
      mods = 'NONE',
      action = act.CopyMode 'MoveToViewportBottom',
    },
    {
      key = 'L',
      mods = 'SHIFT',
      action = act.CopyMode 'MoveToViewportBottom',
    },
    {
      key = 'M',
      mods = 'NONE',
      action = act.CopyMode 'MoveToViewportMiddle',
    },
    {
      key = 'M',
      mods = 'SHIFT',
      action = act.CopyMode 'MoveToViewportMiddle',
    },
    {
      key = 'O',
      mods = 'NONE',
      action = act.CopyMode 'MoveToSelectionOtherEndHoriz',
    },
    {
      key = 'O',
      mods = 'SHIFT',
      action = act.CopyMode 'MoveToSelectionOtherEndHoriz',
    },
    {
      key = 'T',
      mods = 'NONE',
      action = act.CopyMode { JumpBackward = { prev_char = true } },
    },
    {
      key = 'T',
      mods = 'SHIFT',
      action = act.CopyMode { JumpBackward = { prev_char = true } },
    },
    {
      key = '^',
      mods = 'NONE',
      action = act.CopyMode 'MoveToStartOfLineContent',
    },
    {
      key = '^',
      mods = 'SHIFT',
      action = act.CopyMode 'MoveToStartOfLineContent',
    },
    { key = 'b', mods = 'NONE', action = with_relative_motion(act.CopyMode 'MoveBackwardWord') },
    { key = 'e', mods = 'NONE', action = with_relative_motion(act.CopyMode 'MoveForwardWordEnd') },
    {
      key = 'f',
      mods = 'NONE',
      action = act.CopyMode { JumpForward = { prev_char = false } },
    },
    {
      key = 'g',
      mods = 'NONE',
      action = act.CopyMode 'MoveToScrollbackTop',
    },
    {
      key = 'o',
      mods = 'NONE',
      action = act.CopyMode 'MoveToSelectionOtherEnd',
    },
    {
      key = 't',
      mods = 'NONE',
      action = act.CopyMode { JumpForward = { prev_char = true } },
    },
    { key = 'w', mods = 'NONE', action = with_relative_motion(act.CopyMode 'MoveForwardWord') },
    { key = 'W', mods = 'SHIFT', action = act.CopyMode 'MoveForwardSemanticZone' },
    { key = 'W', mods = 'NONE', action = act.CopyMode 'MoveForwardSemanticZone' },
    {
      key = 'End',
      mods = 'NONE',
      action = act.CopyMode 'MoveToEndOfLineContent',
    },
    {
      key = 'Home',
      mods = 'NONE',
      action = act.CopyMode 'MoveToStartOfLine',
    },
    {
      key = '/',
      modes = 'NONE',
      action = act.Search { CaseInSensitiveString = '' },
    },

    ---
    --- yank commands
    ---
    {
      key = 'y',
      mods = 'NONE',
      action = act.Multiple {
        { CopyTo = 'ClipboardAndPrimarySelection' },
        act.ClearSelection,
        { CopyMode = 'ClearPattern' },
        { CopyMode = 'ClearSelectionMode' },
      },
    },
    -- enter mimics tmux, yank then exit
    {
      key = 'Enter',
      mods = 'NONE',
      action = act.Multiple {
        { CopyTo = 'ClipboardAndPrimarySelection' },
        act.ClearSelection,
        { CopyMode = 'ClearPattern' },
        { CopyMode = 'ClearSelectionMode' },
        { CopyMode = 'MoveToScrollbackBottom' },
        { CopyMode = 'Close' },
      },
    },
  },
  search_mode = {
    { key = 'Enter', mods = 'NONE', action = act.CopyMode 'PriorMatch' },
    { key = 'Enter', mods = 'SHIFT', action = act.CopyMode 'NextMatch' },
    {
      key = 'Escape',
      mods = 'NONE',
      action = wezterm.action_callback(function(window, pane)
        -- firstly go from search to copy mode
        window:perform_action(act.ActivateCopyMode, pane)

        -- then, clear pattern, any selected areas
        window:perform_action(
          act.Multiple {
            act.CopyMode 'ClearPattern',
            act.ClearSelection,
            act.CopyMode 'ClearSelectionMode',
            -- normally cursor goes to end of word and we want to be at start!
            act.CopyMode 'MoveBackwardWord',
          },
          pane
        )
      end),
    },
    { key = 'c', mods = 'CTRL', action = act.CopyMode 'Close' },
    { key = 'n', mods = 'CTRL', action = act.CopyMode 'NextMatch' },
    { key = 'p', mods = 'CTRL', action = act.CopyMode 'PriorMatch' },
    { key = 'r', mods = 'CTRL', action = act.CopyMode 'CycleMatchType' },
    { key = 'u', mods = 'CTRL', action = act.CopyMode 'ClearPattern' },
    { key = 'w', mods = 'CTRL', action = act.CopyMode 'ClearPattern' },
    { key = 'PageUp', mods = 'NONE', action = act.CopyMode 'PriorMatchPage' },
    { key = 'PageDown', mods = 'NONE', action = act.CopyMode 'NextMatchPage' },
    { key = 'UpArrow', mods = 'NONE', action = act.CopyMode 'PriorMatch' },
    { key = 'DownArrow', mods = 'NONE', action = act.CopyMode 'NextMatch' },
  },
}

--
-- add number count updators
--
for i = 0, 9 do
  table.insert(config.key_tables.copy_mode, {
    key = tostring(i),
    mods = 'NONE',
    action = wezterm.action_callback(function(window, pane)
      if i == 0 and relative_motion_counter == 0 then
        window:perform_action(act.CopyMode 'MoveToStartOfLine', pane)
      else
        update_motion_counter(i, pane)
      end
    end),
  })
end

wezterm.on('update-status', function(window, pane)
  local old_key_table = global_key_table
  global_key_table = window:active_key_table()
  if old_key_table ~= global_key_table then
    print('status of key table updated to: ', global_key_table)
  end

  -- Create mode indicator with colors
  local mode_text = 'NORMAL'
  local bg_color = '#2d3748' -- dark gray
  local fg_color = '#a0aec0' -- light gray

  if global_key_table == 'copy_mode' then
    mode_text = 'COPY'
    bg_color = '#0066ff' -- much more striking bright blue
    fg_color = '#ffffff'
  elseif global_key_table == 'search_mode' then
    mode_text = 'SEARCH'
    bg_color = '#ffa500' -- bright orange/yellow
    fg_color = '#000000'
  end

  -- Update active tab colors based on mode
  local overrides = window:get_config_overrides() or {}
  overrides.colors = overrides.colors or {}
  overrides.colors.tab_bar = overrides.colors.tab_bar or {}

  if global_key_table == 'copy_mode' then
    overrides.colors.tab_bar.active_tab = {
      bg_color = '#0066ff', -- same striking blue
      fg_color = '#ffffff',
    }
  elseif global_key_table == 'search_mode' then
    overrides.colors.tab_bar.active_tab = {
      bg_color = '#ffa500', -- same bright orange
      fg_color = '#000000',
    }
  else
    overrides.colors.tab_bar.active_tab = {
      bg_color = '#805ad5', -- purple for normal mode
      fg_color = '#ffffff',
    }
  end

  -- Add cursor color based on mode
  if global_key_table == 'copy_mode' then
    overrides.colors.cursor_bg = '#0066ff'
    overrides.colors.cursor_fg = '#ffffff'
  elseif global_key_table == 'search_mode' then
    overrides.colors.cursor_bg = '#ffa500'
    overrides.colors.cursor_fg = '#000000'
  else
    overrides.colors.cursor_bg = '#805ad5'
    overrides.colors.cursor_fg = '#ffffff'
  end

  window:set_config_overrides(overrides)

  -- Set the left status with colored mode indicator
  window:set_left_status(wezterm.format {
    { Background = { Color = bg_color } },
    { Foreground = { Color = fg_color } },
    { Text = ' ' .. mode_text .. ' ' },
    { Background = { Color = 'none' } },
    { Foreground = { Color = bg_color } },
    { Text = '' }, -- powerline separator
    'ResetAttributes',
  })
end)
wezterm.on('update-right-status', function(window, pane)
  local domain = pane:get_domain_name()
  local active_workspace = window:active_workspace()

  print('updating right status: ', domain, active_workspace)
  if domain == 'local' then
    window:set_right_status(active_workspace)
  else
    window:set_right_status(wezterm.format {
      { Background = { Color = 'maroon' } },
      { Text = domain .. ': ' .. active_workspace },
    })
  end
end)
-- Keep sessions alive when GUI closes
config.exit_behavior = 'Hold'

config.ssh_domains = {
  {
    name = 'work',
    remote_address = 'joelrdp.lcasino.work',
    -- Optional: specify username separately
    username = 'joelyboy',
    -- remote_address = 'example.com',
  },
}

config.unix_domains = {
  {
    name = 'unix',
  },
}

-- This causes `wezterm` to act as though it was started as
-- `wezterm connect unix` by default, connecting to the unix
-- domain on startup.
-- If you prefer to connect manually, leave out this line.
-- config.default_gui_startup_args = { 'connect', 'unix' }

-- Finally, return the configuration to wezterm:
return config
