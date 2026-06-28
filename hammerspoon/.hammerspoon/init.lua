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

-- Make the leader key (f18) toggle the panel: pressing it while the menu is
-- already open closes the menu instead of re-showing the top layer.
-- We track the currently-entered modal (RecursiveBinder enters/exits a modal
-- per layer) and wrap only the top-level binding produced by recursiveBind.
do
	local RB = spoon.RecursiveBinder

	-- track the active modal so the leader handler knows the panel is open
	local activeModal = nil
	local origEnter = hs.hotkey.modal.enter
	local origExit = hs.hotkey.modal.exit
	function hs.hotkey.modal.enter(self, ...)
		activeModal = self
		return origEnter(self, ...)
	end
	function hs.hotkey.modal.exit(self, ...)
		if activeModal == self then activeModal = nil end
		return origExit(self, ...)
	end

	-- wrap recursiveBind; only the top-level call (no `modals` arg) becomes a toggle
	local origRecursiveBind = RB.recursiveBind
	function RB.recursiveBind(keymap, modals)
		local starter = origRecursiveBind(keymap, modals)
		if modals ~= nil or type(starter) ~= "function" then
			return starter
		end
		return function()
			if activeModal then
				activeModal:exit()      -- close the open layer
				hs.alert.closeAll()     -- dismiss the helper popup
			else
				starter()               -- open the menu
			end
		end
	end
end

spoon.Hammerflow.loadFirstValidTomlFile({
	"home.toml",
	"work.toml",
	"Spoons/Hammerflow.spoon/sample.toml",
})

if spoon.Hammerflow.auto_reload then
	hs.loadSpoon("ReloadConfiguration")
	spoon.ReloadConfiguration:start()
end
