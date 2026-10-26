-- for notifcations test these two
-- printf '\a'
-- printf '\e]9;Hello from WezTerm\a'
-- one should sound a bell and one should show a mac notification.
-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

-- follow macOS light/dark mode: Latte in light, Mocha in dark.
local function is_dark()
	return wezterm.gui and wezterm.gui.get_appearance():find("Dark") ~= nil
end
local dark = is_dark()
config.color_scheme = dark and "Catppuccin Mocha" or "Catppuccin Latte"
config.font = wezterm.font("JetBrainsMono Nerd Font Mono")
config.font_size = 17
config.line_height = 1.1

-- breathing room around the text
config.window_padding = { left = 14, right = 14, top = 10, bottom = 8 }

-- thin blinking bar cursor with a smooth fade instead of a hard blink
config.default_cursor_style = "BlinkingBar"
config.cursor_thickness = 2
config.cursor_blink_rate = 600
config.cursor_blink_ease_in = "EaseOut"
config.cursor_blink_ease_out = "EaseOut"

-- dim unfocused splits so the active one stands out
config.inactive_pane_hsb = { saturation = 0.85, brightness = 0.8 }
-- This is where you actually apply your config choices.
config.window_decorations = "RESIZE"

config.hide_tab_bar_if_only_one_tab = true

-- use the retro tab bar so it lives inside the terminal grid and inherits
-- the window transparency (the fancy tab bar renders as an opaque titlebar).
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false
config.colors = {
	tab_bar = {
		-- match the Catppuccin background (Mocha / Latte) so the bar blends in; the
		-- window opacity below then makes it transparent along with the rest.
		background = dark and "#1e1e2e" or "#eff1f5",
	},
}

-- transparent background
-- frosted glass: a bit more opaque + blur keeps text readable over busy windows
config.window_background_opacity = 0.9
config.macos_window_background_blur = 25

-- enable rtl support
config.bidi_enabled = true
config.bidi_direction = "AutoLeftToRight"

-- this is to resolve the problem of hanging after some time:
-- a window's OpenGL surface stops presenting frames (process stays healthy,
-- new windows work), so render through Metal instead of OpenGL
config.front_end = "WebGpu"
-- config.front_end = "Software"

config.keys = {
	-- Disable default Ctrl+Tab tab switching
	-- Send Ctrl+Tab as kitty-encoded CSI sequence to Zellij
	-- CSI 9;5u = Tab(9) with Ctrl modifier(5) in kitty keyboard protocol
	{
		key = "Tab",
		mods = "CTRL",
		action = wezterm.action.SendString("\x1b[9;5u"),
	},
}
-- fuzzy picker over all keybindings: https://github.com/abidibo/wezterm-cmdpicker
-- must run after config.keys is fully defined.
-- loaded from a local clone because wezterm 20240203's libgit2 fails on https URLs
-- ("unsupported URL protocol"). nix/apply.sh clones it; if it's missing, skip it
-- instead of breaking the whole config.
local ok, cmdpicker =
	pcall(wezterm.plugin.require, "file://" .. wezterm.home_dir .. "/.local/share/wezterm-plugins/wezterm-cmdpicker")
if ok then
	cmdpicker.apply_to_config(config, {
		key = "k",
		mods = "CMD|SHIFT",
		title = "Command Picker",
	})
else
	wezterm.log_warn("wezterm-cmdpicker not loaded (run nix/apply.sh): " .. tostring(cmdpicker))
end

-- Finally, return the configuration to wezterm:
return config
