---@diagnostic disable: undefined-global

-- Focus guard:
--   1. Telegram is hidden until you pick how long to open it for.
--   2. Distracting sites in Chrome / Edge / Safari get redirected to reading,
--      then a menu asks how long to unlock them. Esc / "Forget it" keeps
--      the reading page.
-- Watchers and timers are globals so they aren't garbage-collected.

-- ── settings ────────────────────────────────────────────────
local TELEGRAM = "ru.keepcoder.Telegram"
-- "how long?" menus: { label, minutes }; no minutes = give up
local DEFAULT_MENU = {
	{ "Forget it" },
	{ "5 minutes", 5 },
	{ "15 minutes", 15 },
	{ "30 minutes", 30 },
	{ "1 hour", 60 },
}
-- per-target overrides (anything not listed uses DEFAULT_MENU)
local MENUS = {
	["youtube.com"] = {
		{ "Forget it" },
		{ "10 minutes", 10 },
		{ "30 minutes", 30 },
		{ "1 hour", 60 },
	},
}
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

-- ── "how long?" menu (shared by Telegram and sites) ────────
local menu = nil  -- chooser while it's open; one menu at a time

local function askMinutes(name, onPick, onGiveUp)
	local choices = {}
	for i, o in ipairs(MENUS[name] or DEFAULT_MENU) do
		choices[i] = { text = o[1], minutes = o[2] }
	end
	menu = hs.chooser.new(function(choice)
		menu = nil
		if choice and choice.minutes then return onPick(choice.minutes) end
		if onGiveUp then onGiveUp() end
		hs.alert.show("Good call.", 1)
	end)
	menu:placeholderText(name .. "  ·  how long?")
	menu:choices(choices)
	menu:show()
end

-- ── Telegram friction ───────────────────────────────────────
local unlockedUntil = 0

local function hideTelegram(app)
	app = app or hs.application.get(TELEGRAM)
	if app then app:hide() end
end

focusTelegramWatcher = hs.application.watcher.new(function(_, event, app)
	if event ~= hs.application.watcher.launched
		and event ~= hs.application.watcher.activated then
		return
	end
	if not app or app:bundleID() ~= TELEGRAM then return end
	if os.time() < unlockedUntil then return end

	hideTelegram(app)
	if menu then return end
	askMinutes("Telegram", function(minutes)
		unlockedUntil = os.time() + minutes * 60
		hs.application.launchOrFocusByBundleID(TELEGRAM)
	end, hideTelegram)
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
	if menu then
		hs.alert.show(blocked .. "  →  " .. dest:match("://([^/]+)"), 2)
		return
	end
	local function unlock(minutes)
		siteUnlockedUntil[blocked] = os.time() + minutes * 60
		hs.urlevent.openURLWithBundle(url, bid)
	end
	askMinutes(blocked, unlock)
end

focusBrowserTimer = hs.timer.doEvery(2, checkBrowser)
