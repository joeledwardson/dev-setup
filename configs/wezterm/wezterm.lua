-- Pull in the wezterm API (see https://github.com/DrKJeff16/wezterm-types)
---@type Wezterm
local wezterm = require("wezterm")
local global_key_table = ""

local tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")
-- tabline.setup({})
tabline.setup({
	options = {
		icons_enabled = true,
		theme = "Catppuccin Mocha",
		tabs_enabled = true,
		theme_overrides = {},
		section_separators = {
			left = wezterm.nerdfonts.pl_left_hard_divider,
			right = wezterm.nerdfonts.pl_right_hard_divider,
		},
		component_separators = {
			left = wezterm.nerdfonts.pl_left_soft_divider,
			right = wezterm.nerdfonts.pl_right_soft_divider,
		},
		tab_separators = {
			left = wezterm.nerdfonts.pl_left_hard_divider,
			right = wezterm.nerdfonts.pl_right_hard_divider,
		},
	},
	sections = {
		tabline_a = { "mode" },
		tabline_b = { "workspace" },
		tabline_c = { " " },
		tab_active = {
			"index",
			{ "parent", padding = 0 },
			"/",
			{ "cwd", padding = { left = 0, right = 1 } },
			{ "zoomed", padding = 0 },
		},
		tab_inactive = { "index", { "process", padding = { left = 0, right = 1 } } },
		tabline_x = {},
		tabline_y = {},
		tabline_z = { "domain" },
	},
	extensions = {},
})

-- Debug: print when config loads
wezterm.log_info("Loading WezTerm config from dev-setup")

-- This will hold the configuration.
---@type Config
local config = wezterm.config_builder()

-- This is where you actually apply your config choices.
-- For example, changing the initial geometry for new windows: (no idea where this came from)
-- config.initial_cols = 120
-- config.initial_rows = 28

-- or, changing the font size and color scheme.
config.font = wezterm.font("SpaceMonoNF")
-- config.color_scheme = "AdventureTime"

-- Pane focus indication - make inactive panes much more obvious
config.inactive_pane_hsb = {
	saturation = 0.1, -- Much less color for inactive panes
	brightness = 0.15, -- Much darker inactive panes
}

-- Define colors including split lines
config.colors = {
	compose_cursor = "orange",
	tab_bar = {
		inactive_tab = {
			bg_color = "#1b1032",
			fg_color = "#808080",
		},
	},
}

-- config.window_background_opacity = 0.8

local MOD_KEY = "ALT"
local act = wezterm.action

-- ---@param window Window
-- ---@param key_table string|nil
-- --- set background to a distinct colour if in copy/search mode
-- local function update_copy_colours(window, key_table)
-- 	local overrides = window:get_config_overrides() or {}
-- 	overrides.colors = overrides.colors or {}
-- 	local colours = overrides.colors
-- 	if key_table == nil then
-- 		-- get the copy mode state directly
-- 		key_table = window:active_key_table()
-- 	end
--
-- 	-- Store the current background to avoid unnecessary updates
-- 	local current_bg = colours.background
-- 	local new_bg = "black"
--
-- 	-- set copy mode background distinct colour
-- 	if key_table == "copy_mode" then
-- 		new_bg = "#332811"
-- 	elseif key_table == "search_mode" then
-- 		new_bg = "#331126"
-- 	end
--
-- 	-- Only update if the color actually changed
-- 	if current_bg ~= new_bg then
-- 		-- colours.background = new_bg
-- 		-- window:set_config_overrides(overrides)
-- 	end
-- end
--
-- --- Wrap an action to update colors after execution
-- --- @param action any The wezterm action to perform
-- --- @param target_key_table string|nil Optional key table to set (if nil, will auto-detect)
-- local function with_color_update(action, target_key_table)
-- 	return wezterm.action_callback(function(window, pane)
-- 		window:perform_action(action, pane)
-- 		update_copy_colours(window, target_key_table)
-- 	end)
-- end

--- check pane is available in direction beofre moving, show warning if not
---@param window Window
---@param pane Pane
---@param direction PaneDirection
local function move_pane(window, pane, direction)
	local tab = window:active_tab()
	local new_pane = tab:get_pane_direction(direction)
	if new_pane == nil then
		local overrides = window:get_config_overrides() or {}
		overrides.colors = overrides.colors or {}
		local colours = overrides.colors
		colours.background = "rgb(115,5,5)"
		window:set_config_overrides(overrides)
		wezterm.time.call_after(0.2, function()
			local post_overrides = window:get_config_overrides() or {}
			post_overrides.colors = { background = nil }
			window:set_config_overrides(post_overrides)
		end)
	else
		window:perform_action(act.ActivatePaneDirection(direction), pane)
	end
end

config.keys = {
	--
	-- pane splits
	--
	{
		key = "v",
		mods = MOD_KEY,
		-- action = with_color_update(act.SplitVertical({})),
		action = act.SplitVertical({}),
	},
	{
		key = "s",
		mods = MOD_KEY,
		-- action = with_color_update(act.SplitHorizontal({})),
		action = (act.SplitHorizontal({})),
	},

	--
	-- pane navigation
	--
	{
		key = "j",
		mods = MOD_KEY,
		action = wezterm.action_callback(function(window, pane)
			move_pane(window, pane, "Down")
		end),
	},
	{
		key = "k",
		mods = MOD_KEY,
		action = wezterm.action_callback(function(window, pane)
			move_pane(window, pane, "Up")
		end),
	},
	{
		key = "h",
		mods = MOD_KEY,
		action = wezterm.action_callback(function(window, pane)
			move_pane(window, pane, "Left")
		end),
	},
	{
		key = "l",
		mods = MOD_KEY,
		action = wezterm.action_callback(function(window, pane)
			move_pane(window, pane, "Right")
		end),
	},
	{ key = "q", mods = MOD_KEY, action = act.CloseCurrentPane({ confirm = true }) },

	--
	-- tab navigation
	--
	{ key = "]", mods = MOD_KEY, action = act.ActivateTabRelative(1) },
	{ key = "[", mods = MOD_KEY, action = act.ActivateTabRelative(-1) },
	{ key = "t", mods = MOD_KEY, action = act.SpawnTab("CurrentPaneDomain") },
	{ key = "z", mods = MOD_KEY, action = act.TogglePaneZoomState },
	{
		key = ",",
		mods = MOD_KEY,
		action = act.PromptInputLine({
			description = "Enter new title for tab",
			action = wezterm.action_callback(function(window, pane, line)
				if line then
					print("setting title: ", line)
					window:active_tab():set_title(line)
				end
			end),
		}),
	},

	--
	-- entering search & copy mode
	--
	{
		key = "/",
		mods = MOD_KEY,
		-- action = with_color_update(act.Search({ CaseInSensitiveString = "" }), "search_mode"),
		action = act.Search({ CaseInSensitiveString = "" }),
	},
	{
		key = "c",
		mods = MOD_KEY,
		-- action = with_color_update(act.ActivateCopyMode, "copy_mode"),
		action = act.ActivateCopyMode,
	},

	--
	-- zoom
	--
	{ key = "+", mods = "CTRL", action = act.IncreaseFontSize },
	{ key = "-", mods = "CTRL", action = act.DecreaseFontSize },

	--
	-- misc
	--
	{
		key = "u",
		mods = MOD_KEY,
		action = act.QuickSelect,
	},
	{
		key = ":",
		mods = "ALT|SHIFT",
		action = act.ActivateCommandPalette,
	},
}
-- format table title using [Z] if zoomed and show copy mode status
-- > took inspiration from format-window-title https://wezterm.org/config/lua/window-events/format-window-title.html
wezterm.on("format-tab-title", function(tab, pane, tabs, panes, config)
	-- start with index of tab
	local formatted = tostring(tab.tab_index + 1) .. ": "

	-- add the user defined tab title (if exists) otherwise use pane title
	if tab.tab_title and tab.tab_title:len() > 0 then
		formatted = formatted .. tab.tab_title
	else
		formatted = formatted .. (tab.active_pane.title or "")
	end

	-- add a zoomed indicator
	if tab.active_pane.is_zoomed then
		formatted = formatted .. " [Z]"
	end

	if global_key_table == "copy_mode" then
		formatted = "[COPY MODE] " .. formatted
	end

	print("FORMATTED TAB TITLE TO BE: ", formatted)
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

local county = 0

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

config.key_tables = {
	copy_mode = {
		{
			key = "p",
			mods = "ALT",
			action = act.Multiple({
				act.CopyMode("MoveBackwardSemanticZone"),
			}),
		},
		{
			key = "n",
			mods = "ALT",
			action = act.Multiple({
				act.CopyMode("MoveForwardSemanticZone"),
			}),
		},
		--
		-- page up/down navigators (including vim style bindings)
		-- I added in Ctrl-e and Ctrl-y for 1/4 page movements from wezterm
		--
		{
			key = "u",
			mods = "CTRL",
			action = act.CopyMode({ MoveByPage = -0.5 }),
		},
		{
			key = "d",
			mods = "CTRL",
			action = act.CopyMode({ MoveByPage = 0.5 }),
		},
		{
			key = "y",
			mods = "CTRL",
			action = act.CopyMode({ MoveByPage = -0.25 }),
		},
		{
			key = "e",
			mods = "CTRL",
			action = act.CopyMode({ MoveByPage = 0.25 }),
		},
		{ key = "f", mods = "CTRL", action = act.CopyMode("PageDown") },
		{ key = "b", mods = "CTRL", action = act.CopyMode("PageUp") },
		{ key = "PageUp", mods = "NONE", action = act.CopyMode("PageUp") },
		{ key = "PageDown", mods = "NONE", action = act.CopyMode("PageDown") },

		--
		-- terminal style keys
		--
		{ key = "w", mods = "CTRL", action = act.CopyMode("ClearPattern") },
		--
		-- tmux style keys
		--
		{
			key = "Enter",
			mods = "NONE",
			action = act.Multiple({
				{ CopyTo = "ClipboardAndPrimarySelection" },
				{ CopyMode = "ClearPattern" },
				{ CopyMode = "ClearSelectionMode" },
			}),
		},

		--
		-- selection mode changes
		--
		{
			key = "v",
			mods = "NONE",
			action = act.CopyMode({ SetSelectionMode = "Cell" }),
		},
		{
			key = "v",
			mods = "CTRL",
			action = act.CopyMode({ SetSelectionMode = "Block" }),
		},
		{
			key = "V",
			mods = "NONE",
			action = act.CopyMode({ SetSelectionMode = "Line" }),
		},
		{
			key = "V",
			mods = "SHIFT",
			action = act.CopyMode({ SetSelectionMode = "Line" }),
		},
		{
			key = "Space",
			mods = "NONE",
			action = act.CopyMode({ SetSelectionMode = "Cell" }),
		},

		--
		-- exit keys
		--
		-- mimic tmux behaviour, clear active selection otherwise quit
		{
			key = "Escape",
			mods = "NONE",
			action = wezterm.action_callback(function(window, pane)
				local selected_text = window:get_selection_text_for_pane(pane)
				local is_empty = not (selected_text and selected_text:len() > 0)
				if is_empty then
					window:perform_action(act.CopyMode("MoveToScrollbackBottom"), pane)
					window:perform_action(act.CopyMode("Close"), pane)
					-- update_copy_colours(window)
					return
				end
				window:perform_action(act.CopyMode("ClearSelectionMode"), pane)
			end),
		},
		-- control-c and q just exits regardless of state with copy/search
		{
			key = "c",
			mods = "CTRL",
			-- action = with_color_update(act.Multiple({
			-- 	{ CopyMode = "MoveToScrollbackBottom" },
			-- 	{ CopyMode = "Close" },
			-- })),
			action = (act.Multiple({
				{ CopyMode = "MoveToScrollbackBottom" },
				{ CopyMode = "Close" },
			})),
		},
		{
			key = "q",
			mods = "NONE",
			action = (act.Multiple({
				{ CopyMode = "MoveToScrollbackBottom" },
				{ CopyMode = "Close" },
			})),
			-- action = with_color_update(act.Multiple({
			-- 	{ CopyMode = "MoveToScrollbackBottom" },
			-- 	{ CopyMode = "Close" },
			-- })),
		},

		--
		-- vim style navigation keys
		--
		{
			key = "$",
			mods = "NONE",
			action = act.CopyMode("MoveToEndOfLineContent"),
		},
		{
			key = "$",
			mods = "SHIFT",
			action = act.CopyMode("MoveToEndOfLineContent"),
		},
		{ key = ",", mods = "NONE", action = act.CopyMode("JumpReverse") },
		{ key = "0", mods = "NONE", action = act.CopyMode("MoveToStartOfLine") },
		{ key = ";", mods = "NONE", action = act.CopyMode("JumpAgain") },
		{
			key = "F",
			mods = "NONE",
			action = act.CopyMode({ JumpBackward = { prev_char = false } }),
		},
		{
			key = "F",
			mods = "SHIFT",
			action = act.CopyMode({ JumpBackward = { prev_char = false } }),
		},
		{
			key = "G",
			mods = "NONE",
			action = act.CopyMode("MoveToScrollbackBottom"),
		},
		{
			key = "G",
			mods = "SHIFT",
			action = act.CopyMode("MoveToScrollbackBottom"),
		},
		{ key = "H", mods = "NONE", action = act.CopyMode("MoveToViewportTop") },
		{
			key = "H",
			mods = "SHIFT",
			action = act.CopyMode("MoveToViewportTop"),
		},
		{
			key = "L",
			mods = "NONE",
			action = act.CopyMode("MoveToViewportBottom"),
		},
		{
			key = "L",
			mods = "SHIFT",
			action = act.CopyMode("MoveToViewportBottom"),
		},
		{
			key = "M",
			mods = "NONE",
			action = act.CopyMode("MoveToViewportMiddle"),
		},
		{
			key = "M",
			mods = "SHIFT",
			action = act.CopyMode("MoveToViewportMiddle"),
		},
		{
			key = "O",
			mods = "NONE",
			action = act.CopyMode("MoveToSelectionOtherEndHoriz"),
		},
		{
			key = "O",
			mods = "SHIFT",
			action = act.CopyMode("MoveToSelectionOtherEndHoriz"),
		},
		{
			key = "T",
			mods = "NONE",
			action = act.CopyMode({ JumpBackward = { prev_char = true } }),
		},
		{
			key = "T",
			mods = "SHIFT",
			action = act.CopyMode({ JumpBackward = { prev_char = true } }),
		},
		{
			key = "^",
			mods = "NONE",
			action = act.CopyMode("MoveToStartOfLineContent"),
		},
		{
			key = "^",
			mods = "SHIFT",
			action = act.CopyMode("MoveToStartOfLineContent"),
		},
		{ key = "b", mods = "NONE", action = act.CopyMode("MoveBackwardWord") },
		{
			key = "e",
			mods = "NONE",
			action = act.CopyMode("MoveForwardWordEnd"),
		},
		{
			key = "f",
			mods = "NONE",
			action = act.CopyMode({ JumpForward = { prev_char = false } }),
		},
		{
			key = "g",
			mods = "NONE",
			action = act.CopyMode("MoveToScrollbackTop"),
		},
		{ key = "h", mods = "NONE", action = act.CopyMode("MoveLeft") },
		{ key = "j", mods = "NONE", action = act.CopyMode("MoveDown") },
		{ key = "k", mods = "NONE", action = act.CopyMode("MoveUp") },
		{ key = "l", mods = "NONE", action = act.CopyMode("MoveRight") },
		{
			key = "o",
			mods = "NONE",
			action = act.CopyMode("MoveToSelectionOtherEnd"),
		},
		{
			key = "t",
			mods = "NONE",
			action = act.CopyMode({ JumpForward = { prev_char = true } }),
		},
		{ key = "w", mods = "NONE", action = act.CopyMode("MoveForwardWord") },
		{ key = "W", mods = "SHIFT", action = act.CopyMode("MoveForwardSemanticZone") },
		{ key = "W", mods = "NONE", action = act.CopyMode("MoveForwardSemanticZone") },
		{
			key = "y",
			mods = "NONE",
			action = act.Multiple({
				{ CopyTo = "ClipboardAndPrimarySelection" },
				{ CopyMode = "ClearPattern" },
				{ CopyMode = "ClearSelectionMode" },
			}),
		},
		{
			key = "End",
			mods = "NONE",
			action = act.CopyMode("MoveToEndOfLineContent"),
		},
		{
			key = "Home",
			mods = "NONE",
			action = act.CopyMode("MoveToStartOfLine"),
		},
		{ key = "LeftArrow", mods = "NONE", action = act.CopyMode("MoveLeft") },
		{
			key = "RightArrow",
			mods = "NONE",
			action = act.CopyMode("MoveRight"),
		},
		{ key = "UpArrow", mods = "NONE", action = act.CopyMode("MoveUp") },
		{ key = "DownArrow", mods = "NONE", action = act.CopyMode("MoveDown") },
	},
	search_mode = {
		{ key = "Enter", mods = "NONE", action = act.CopyMode("PriorMatch") },
		{ key = "Enter", mods = "SHIFT", action = act.CopyMode("NextMatch") },
		{ key = "Escape", mods = "NONE", action = act.Multiple({
			act.ActivateCopyMode,
		}) },
		{ key = "c", mods = "CTRL", action = act.CopyMode("Close") },
		{ key = "n", mods = "CTRL", action = act.CopyMode("NextMatch") },
		{ key = "p", mods = "CTRL", action = act.CopyMode("PriorMatch") },
		{ key = "r", mods = "CTRL", action = act.CopyMode("CycleMatchType") },
		{ key = "u", mods = "CTRL", action = act.CopyMode("ClearPattern") },
		{ key = "w", mods = "CTRL", action = act.CopyMode("ClearPattern") },
		{ key = "PageUp", mods = "NONE", action = act.CopyMode("PriorMatchPage") },
		{ key = "PageDown", mods = "NONE", action = act.CopyMode("NextMatchPage") },
		{ key = "UpArrow", mods = "NONE", action = act.CopyMode("PriorMatch") },
		{ key = "DownArrow", mods = "NONE", action = act.CopyMode("NextMatch") },
	},
}

wezterm.on("update-status", function(window, pane)
	local old_key_table = global_key_table
	global_key_table = window:active_key_table()
	if old_key_table ~= global_key_table then
		print("status of key table updated to: ", global_key_table)
	end
end)

-- Finally, return the configuration to wezterm:
return config
