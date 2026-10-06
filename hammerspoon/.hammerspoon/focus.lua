---@diagnostic disable: undefined-global

-- Focus guard:
--   1. Telegram opens only after a short countdown (friction, not a lock).
--   2. Distracting sites in Chrome / Edge / Safari get redirected to reading,
--      then a countdown starts: wait it out and the site comes back, unlocked
--      for a while. Esc gives up and keeps the reading page.
-- Watchers and timers are globals so they aren't garbage-collected.

-- ── settings ────────────────────────────────────────────────
local TELEGRAM = "ru.keepcoder.Telegram"
local TELEGRAM_DELAY = 15   -- seconds of waiting before Telegram shows
local UNLOCK_MINUTES = 10   -- after waiting once, free access for this long
local SITE_DELAY = 30       -- seconds of waiting before a blocked site comes back
local SITE_UNLOCK_MINUTES = 20
-- per-site override of SITE_UNLOCK_MINUTES
local SITE_UNLOCK_OVERRIDE = { ["youtube.com"] = 30 }
-- hosts that share one unlock (a youtu.be link shouldn't re-ask mid-session)
local SITE_ALIAS = { ["youtu.be"] = "youtube.com" }

local BLOCKED_HOSTS = {
	"youtube.com", "youtu.be",
	"web.telegram.org",
	"x.com", "twitter.com",
	"instagram.com",
}
-- { url, weight }: higher weight = picked more often
local REDIRECTS = {
	{ "https://motamem.org", 40 },
	{ "https://substack.com/home", 40 },
	{ "https://app.raindrop.io/my/58953882", 10 },
	{ "https://fidibo.com/library/book/all", 10 },
}

-- bundle id → AppleScript name of the current tab
local BROWSERS = {
	["com.google.Chrome"] = "active tab",
	["com.microsoft.edgemac"] = "active tab",
	["com.apple.Safari"] = "current tab",
}

math.randomseed(os.time())

-- ── countdown (shared by Telegram and sites) ────────────────
local countdown = nil  -- timer while waiting; one countdown at a time
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

local function startCountdown(label, delay, onDone, onGiveUp)
	local left = delay
	local function tick() showAlert(label .. " in " .. left .. "s  ·  Esc to give up") end
	tick()
	escKey = hs.hotkey.bind({}, "escape", function()
		stopCountdown()
		if onGiveUp then onGiveUp() end
		hs.alert.show("Good call.", 1)
	end)
	countdown = hs.timer.doEvery(1, function()
		left = left - 1
		if left > 0 then return tick() end
		stopCountdown()
		onDone()
	end)
end

-- ── Telegram friction ───────────────────────────────────────
local unlockedUntil = 0

local function hideTelegram(app)
	app = app or hs.application.get(TELEGRAM)
	if app then app:hide() end
end

local function startTelegramCountdown()
	startCountdown("Telegram", TELEGRAM_DELAY, function()
		unlockedUntil = os.time() + UNLOCK_MINUTES * 60
		hs.application.launchOrFocusByBundleID(TELEGRAM)
	end, hideTelegram)
end

focusTelegramWatcher = hs.application.watcher.new(function(_, event, app)
	if event ~= hs.application.watcher.launched
		and event ~= hs.application.watcher.activated then
		return
	end
	if not app or app:bundleID() ~= TELEGRAM then return end
	if os.time() < unlockedUntil then return end

	hideTelegram(app)
	if not countdown then startTelegramCountdown() end
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
			return SITE_ALIAS[blocked] or blocked
		end
	end
	return nil
end

local siteUnlockedUntil = {}  -- blocked host → os.time() it stays open until

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
	if os.time() < (siteUnlockedUntil[blocked] or 0) then return end

	local dest = pickRedirect()
	hs.osascript.applescript(target .. "set URL of " .. tab .. ' of front window to "' .. dest .. '"')
	if countdown then
		hs.alert.show(blocked .. "  →  " .. dest:match("://([^/]+)"), 2)
		return
	end
	startCountdown(blocked, SITE_DELAY, function()
		local minutes = SITE_UNLOCK_OVERRIDE[blocked] or SITE_UNLOCK_MINUTES
		siteUnlockedUntil[blocked] = os.time() + minutes * 60
		hs.urlevent.openURLWithBundle(url, bid)
	end)
end

focusBrowserTimer = hs.timer.doEvery(2, checkBrowser)
