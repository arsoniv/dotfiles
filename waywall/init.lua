local waywall = require("waywall")
local helpers = require("waywall.helpers")
local Chat = require("chat")

local config = {
	input = {
		layout = "",
		repeat_rate = 50,
		repeat_delay = 200,

		sensitivity = 1,
		confine_pointer = false,
	},
	theme = {
		background = "#222222ff",
		ninb_anchor = "bottomleft",
		ninb_opacity = 0.7,
		font_path = "/usr/share/fonts/minecraft/MinecraftDefault-Regular.ttf",
	},
	experimental = {
		jit = true,
		tearing = false,
		debug = false,
	},
}

--measureing
helpers.res_mirror({
	src = { x = 145, y = 7902, w = 30, h = 580 },
	dst = { x = 0, y = 315, w = 800, h = 450 },
}, 320, 16384)
helpers.res_image("/home/arsoniv/Downloads/overlay.png", {
	dst = { x = 0, y = 315, w = 1600, h = 450 },
}, 320, 16384)

--thin e counter
helpers.res_mirror({
	src = { x = 12, y = 36, w = 38, h = 11 },
	dst = { x = 525, y = 160, w = 180, h = 55 },
	color_key = {
		input = "#dddddd",
		output = "#dddddd",
	},
}, 380, 900)

-- tall pie numbers
helpers.res_mirror({
	src = { x = 227, y = 16163, w = 35, h = 42 },
	dst = { x = 1130, y = 650, w = 240, h = 252 },
	color_key = {
		input = "#e96d4d",
		output = "#844444",
	},
}, 320, 16384)
helpers.res_mirror({
	src = { x = 227, y = 16163, w = 35, h = 42 },
	dst = { x = 1130, y = 650, w = 240, h = 252 },
	color_key = {
		input = "#45cb65",
		output = "#448444",
	},
}, 320, 16384)

-- thin pie numbers
helpers.res_mirror({
	src = { x = 280, y = 679, w = 40, h = 42 },
	dst = { x = 1150, y = 650, w = 240, h = 252 },
	color_key = {
		input = "#e96d4d",
		output = "#844444",
	},
}, 380, 900)
helpers.res_mirror({
	src = { x = 280, y = 679, w = 40, h = 42 },
	dst = { x = 1150, y = 650, w = 240, h = 252 },
	color_key = {
		input = "#45cb65",
		output = "#448444",
	},
}, 380, 900)

local resolutions = {
	thin = helpers.toggle_res(380, 900),
	tall = helpers.toggle_res(320, 16384),
	wide = helpers.toggle_res(1650, 280),
}

--ninbot
local noNinB = true
local exec_ninb = function()
	if noNinB then
		waywall.exec("java -jar /home/arsoniv/Ninjabrain-Bot-1.5.1.jar")
		noNinB = false
	end
end

--paceman
local noPaceman = true
local exec_pm = function()
	if noPaceman then
		waywall.exec("java -jar /home/arsoniv/paceman-tracker-0.7.0.jar --nogui")
		local pm_text = waywall.text("Paceman Started...", 2, 2, "#00FF00CC", 30)
		noPaceman = false
		waywall.sleep(1500)
		pm_text:close()
	end
end

-- dpi change for eye throws
local eyeMode = false
local toggleEye = function()
	if eyeMode then
		resolutions.tall()
		waywall.exec("razer-cli --dpi 3200")
		eyeMode = false
	else
		resolutions.tall()
		waywall.exec("razer-cli --dpi 200")
		eyeMode = true
	end
end

--local nin_bot_overlay = require("nin_bot")
local paceman_stats_overlay = require("paceman_session_overlay")
local chat1 = Chat("nyachloe", 2, 2, 10, 48, 22)

local timer = nil
local function open_timer()
	if not timer then
		timer = waywall.timer(10, 10, "#FFFFFFFF", 40, 3)
	else
		timer:close()
		timer = nil
	end
end
local function pause()
	if timer then
		timer:pause()
	end
end
local function reset()
	if timer then
		timer:reset()
	end
end

local function draw_utf8_text()
	local text = waywall.text("l", 10, 10, "#FFFFFFFF", 50)
	print(text:advance())
end

config.actions = {
	["*-f2"] = function()
		waywall.exec("razer-cli --dpi 3200")
		resolutions.thin()
	end,
	["*-p"] = toggleEye,
	["*-y"] = function()
		waywall.exec("razer-cli --dpi 3200")
		resolutions.wide()
	end,

	["shift-1"] = function()
		waywall.exec("razer-cli --dpi 3200")
		resolutions.tall()
	end,

	["*-n"] = helpers.toggle_floating,
	["ctrl-n"] = exec_ninb,
	["ctrl-b"] = exec_pm,

	--[[ timer
	["ctrl-8"] = open_timer,
	["ctrl-9"] = pause,
	["ctrl-0"] = reset,
	]]
	--

	--test text
	--["ctrl-g"] = draw_utf8_text,

	["ctrl-k"] = function()
		chat1:open()
	end,
	["ctrl-j"] = function()
		chat1.client:close()
	end,
}

return config
