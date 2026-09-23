---@diagnostic disable: undefined-global

-- Focus guard:
--   1. Telegram opens only after a short countdown (friction, not a lock).
--   2. Distracting sites in Chrome / Edge / Safari get redirected to reading.
-- Watchers and timers are globals so they aren't garbage-collected.

-- ── settings ────────────────────────────────────────────────
local TELEGRAM = "ru.keepcoder.Telegram"
local TELEGRAM_DELAY = 15   -- seconds of waiting before Telegram shows
local UNLOCK_MINUTES = 10   -- after waiting once, free access for this long

local BLOCKED_HOSTS = {
	"youtube.com", "youtu.be",
	"web.telegram.org",
	"x.com", "twitter.com",
	"instagram.com",
}
-- { url, weight }: higher weight = picked more often
local REDIRECTS = {
	{ "https://motamem.org", 45 },
	{ "https://substack.com/home", 45 },
	{ "https://app.raindrop.io/my/58953882", 10 },
}

-- bundle id → AppleScript name of the current tab
local BROWSERS = {
	["com.google.Chrome"] = "active tab",
	["com.microsoft.edgemac"] = "active tab",
	["com.apple.Safari"] = "current tab",
}

math.randomseed(os.time())

-- ── Telegram friction ───────────────────────────────────────
local unlockedUntil = 0
local countdown = nil  -- timer while waiting
local escKey = nil
local alertId = nil

local function showAlert(text)
	if alertId then hs.alert.closeSpecific(alertId) end
	alertId = hs.alert.show(text, 1.5)
end

local function stopCountdown()
	if countdown then countdown:stop(); countdown = nil end
	if escKey then escKey:delete(); escKey = nil end
	if alertId then hs.alert.closeSpecific(alertId); alertId = nil end
end

local function hideTelegram(app)
	app = app or hs.application.get(TELEGRAM)
	if app then app:hide() end
end

local function startCountdown()
	local left = TELEGRAM_DELAY
	showAlert("Telegram in " .. left .. "s  ·  Esc to give up")
	escKey = hs.hotkey.bind({}, "escape", function()
		stopCountdown()
		hideTelegram()
		hs.alert.show("Good call.", 1)
	end)
	countdown = hs.timer.doEvery(1, function()
		left = left - 1
		if left > 0 then
			showAlert("Telegram in " .. left .. "s  ·  Esc to give up")
			return
		end
		stopCountdown()
		unlockedUntil = os.time() + UNLOCK_MINUTES * 60
		hs.application.launchOrFocusByBundleID(TELEGRAM)
	end)
end

focusTelegramWatcher = hs.application.watcher.new(function(_, event, app)
	if event ~= hs.application.watcher.launched
		and event ~= hs.application.watcher.activated then
		return
	end
	if not app or app:bundleID() ~= TELEGRAM then return end
	if os.time() < unlockedUntil then return end

	hideTelegram(app)
	if not countdown then startCountdown() end
end)
focusTelegramWatcher:start()

-- ── site redirect ───────────────────────────────────────────
local function pickRedirect()
	local total = 0
	for _, r in ipairs(REDIRECTS) do total = total + r[2] end
	local roll = math.random() * total
	for _, r in ipairs(REDIRECTS) do
		roll = roll - r[2]
		if roll <= 0 then return r[1] end
	end
	return REDIRECTS[#REDIRECTS][1]
end

local function isBlocked(host)
	for _, blocked in ipairs(BLOCKED_HOSTS) do
		if host == blocked or host:sub(-(#blocked + 1)) == "." .. blocked then
			return blocked
		end
	end
	return nil
end

local function checkBrowser()
	local front = hs.application.frontmostApplication()
	if not front then return end
	local bid = front:bundleID()
	local tab = BROWSERS[bid]
	if not tab then return end

	local target = 'tell application id "' .. bid .. '" to '
	local ok, url = hs.osascript.applescript(target .. "get URL of " .. tab .. " of front window")
	if not ok or type(url) ~= "string" then return end

	local host = url:match("^%a[%w+.-]*://([^/:?#]+)")
	local blocked = host and isBlocked(host:lower())
	if not blocked then return end

	local dest = pickRedirect()
	hs.osascript.applescript(target .. "set URL of " .. tab .. ' of front window to "' .. dest .. '"')
	hs.alert.show(blocked .. "  →  " .. dest:match("://([^/]+)"), 2)
end

focusBrowserTimer = hs.timer.doEvery(2, checkBrowser)
