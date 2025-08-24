-- Pull in the wezterm API
---@type Wezterm
local wezterm = require("wezterm")

-- Debug: print when config loads
wezterm.log_info("Loading WezTerm config from dev-setup")

-- This will hold the configuration.
---@type Config
local config = wezterm.config_builder()

-- This is where you actually apply your config choices.

-- For example, changing the initial geometry for new windows:
config.initial_cols = 120
config.initial_rows = 28

-- or, changing the font size and color scheme.
config.font = wezterm.font("SpaceMonoNF")
-- config.color_scheme = "AdventureTime"

-- Pane focus indication - make inactive panes much more obvious
config.inactive_pane_hsb = {
	saturation = 0.2, -- Much less color for inactive panes
	brightness = 0.1, -- Much darker inactive panes
}

-- Define colors including split lines
config.colors = {
	-- split = "#00ff00", -- Bright green split lines for visibility
	tab_bar = {
		inactive_tab = {
			bg_color = "#1b1032",
			fg_color = "#808080",
		},
	},
}

config.window_background_opacity = 0.8

local MOD_KEY = "ALT"
local act = wezterm.action

config.keys = {
	{
		key = "v",
		mods = MOD_KEY,
		action = act.SplitVertical({}),
	},
	{
		key = "s",
		mods = MOD_KEY,
		action = act.SplitHorizontal({}),
	},
	{
		key = "j",
		mods = MOD_KEY,
		action = act.ActivatePaneDirection("Down"),
	},
	{ key = "k", mods = MOD_KEY, action = act.ActivatePaneDirection("Up") },
	{
		key = "h",
		mods = MOD_KEY,
		action = act.ActivatePaneDirection("Left"),
	},
	{ key = "l", mods = MOD_KEY, action = act.ActivatePaneDirection("Right") },
	{ key = "q", mods = MOD_KEY, action = act.CloseCurrentPane({ confirm = false }) },
	{ key = "]", mods = MOD_KEY, action = act.ActivateTabRelative(1) },
	{ key = "[", mods = MOD_KEY, action = act.ActivateTabRelative(-1) },
	{ key = "t", mods = MOD_KEY, action = act.SpawnTab("CurrentPaneDomain") },
	-- { key = "c", mods = "CTRL", action = act.CopyMode("Close") },
	{ key = "f", mods = MOD_KEY, action = act.Search({ CaseInSensitiveString = "" }) },
	{ key = "c", mods = MOD_KEY, action = act.ActivateCopyMode },
}

-- config.key_tables = {
-- 	copy_mode = {
-- 		-- {
-- 		-- 	key = "Escape",
-- 		-- 	mods = "NONE",
-- 		-- 	action = act.Multiple({
-- 		-- 		act.ClearSelection,
-- 		-- 		-- clear the selection mode, but remain in copy mode
-- 		-- 	}),
-- 		-- },
-- 	},
-- 	search_mode = {
-- 		{ key = "u", mods = "CTRL", action = act.CopyMode("ClearPattern") },
-- 	},
-- }

-- Finally, return the configuration to wezterm:
return config
