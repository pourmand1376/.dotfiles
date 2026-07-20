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

-- use the retro tab bar so it lives inside the terminal grid and inherits
-- the window transparency (the fancy tab bar renders as an opaque titlebar).
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false
config.colors = {
  tab_bar = {
    -- match the Catppuccin Mocha background so the bar blends in; the window
    -- opacity below then makes it transparent along with the rest.
    background = "#1e1e2e",
  },
}

-- transparent background
config.window_background_opacity = 0.80
config.macos_window_background_blur = 10

-- enable rtl support
config.bidi_enabled = true
config.bidi_direction = "AutoLeftToRight"

-- Finally, return the configuration to wezterm:
return config
