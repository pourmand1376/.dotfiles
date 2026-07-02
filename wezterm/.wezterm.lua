-- for notifcations test these two
-- printf '\a'
-- printf '\e]9;Hello from WezTerm\a'
-- one should sound a bell and one should show a mac notification.
-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

config.color_scheme = "Catppuccin Mocha"
config.font = wezterm.font("JetBrainsMono Nerd Font Mono")
config.font_size = 17
-- This is where you actually apply your config choices.
config.window_decorations = "RESIZE"

config.hide_tab_bar_if_only_one_tab = true

-- Finally, return the configuration to wezterm:
return config
