-- Pull in the wezterm API
local wezterm = require("wezterm")

-- Debug: print when config loads
wezterm.log_info("Loading WezTerm config from dev-setup")

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices.

-- For example, changing the initial geometry for new windows:
config.initial_cols = 120
config.initial_rows = 28

-- or, changing the font size and color scheme.
config.font = wezterm.font("SpaceMono Nerd Font")
config.font_size = 10
config.color_scheme = "AdventureTime"

-- Pane focus indication - make inactive panes much more obvious
config.inactive_pane_hsb = {
	saturation = 0.2, -- Much less color for inactive panes
	brightness = 0.1, -- Much darker inactive panes
}

-- Define colors including split lines
config.colors = {
	split = "#00ff00", -- Bright green split lines for visibility
}

-- Finally, return the configuration to wezterm:
return config
