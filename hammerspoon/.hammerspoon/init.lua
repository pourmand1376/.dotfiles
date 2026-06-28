---@diagnostic disable: undefined-global

-- instant movement for built-in window management
hs.window.animationDuration = 0

hs.loadSpoon("Hammerflow")

-- Set the UI format BEFORE loading the toml config.
-- 🐱 Catppuccin Mocha inspired theme
-- palette: base #1e1e2e · mauve #cba6f7 · text #cdd6f4 · lavender #b4befe
spoon.Hammerflow.registerFormat({
	atScreenEdge = 2,
	fillColor = { alpha = 0.95, hex = "1e1e2e" },   -- base
	padding = 18,
	radius = 12,
	strokeColor = { alpha = 0.95, hex = "cba6f7" },  -- mauve
	textColor = { alpha = 1, hex = "cdd6f4" },       -- text
	textStyle = {
		paragraphStyle = { lineSpacing = 6 },
		shadow = { offset = { h = -1, w = 1 }, blurRadius = 10, color = { alpha = 0.50, white = 0 } },
	},
	strokeWidth = 6,
	textFont = "Monaco",
	textSize = 18,
})

spoon.Hammerflow.loadFirstValidTomlFile({
	"home.toml",
	"work.toml",
	"Spoons/Hammerflow.spoon/sample.toml",
})

if spoon.Hammerflow.auto_reload then
	hs.loadSpoon("ReloadConfiguration")
	spoon.ReloadConfiguration:start()
end
