-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

config.color_scheme = "Catppuccin Mocha"
config.font = wezterm.font("JetBrainsMono Nerd Font Mono")
config.font_size = 17
-- This is where you actually apply your config choices.
config.enable_tab_bar = false
config.window_decorations = "RESIZE"

-- Finally, return the configuration to wezterm:
return config
