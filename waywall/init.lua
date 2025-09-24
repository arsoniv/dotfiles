local waywall = require("waywall")
local helpers = require("waywall.helpers")
local chat = require("chat")
local emote_downloader = require("fetch_emotes")

local read_file = function(name)
	local file = io.open("/home/arsoniv/.config/waywall/" .. name, "r")
	local data = file:read("*a")
	file:close()

	return data
end

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
		ninb_opacity = 1,
		font_path = "/usr/share/fonts/TTF/JetBrainsMono-Medium.ttf",
		font_size = 25,
	},
	shaders = {
		["rainbow_text"] = {
			vertex = read_file("rainbow.vert"),
			fragment = read_file("rainbow.frag"),
		},
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

-- pre pie numbers
helpers.res_mirror({
	src = { x = 0, y = 980, w = 40, h = 48 },
	dst = { x = 1050, y = 650, w = 240, h = 252 },
	color_key = {
		input = "#e96d4d",
		output = "#844444",
	},
}, 100, 1200)
helpers.res_mirror({
	src = { x = 0, y = 980, w = 40, h = 48 },
	dst = { x = 1050, y = 650, w = 240, h = 252 },
	color_key = {
		input = "#45cb65",
		output = "#448444",
	},
}, 100, 1200)

local resolutions = {
	thin = helpers.toggle_res(380, 900),
	tall = helpers.toggle_res(320, 16384),
	wide = helpers.toggle_res(1920, 300),
	pre = helpers.toggle_res(100, 1200),
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
		print("STARTING PACEMAN")
		waywall.exec("java -jar /home/arsoniv/paceman-tracker-0.7.0.jar --nogui")
		noPaceman = false
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
--local paceman_stats_overlay = require("paceman_session_overlay")
local chat1 = chat("Arsoniv", 10, 10, 16)

config.actions = {
	["*-f2"] = function()
		waywall.exec("razer-cli --dpi 3200")
		resolutions.thin()
		eyeMode = false
	end,
	["*-p"] = toggleEye,
	["*-y"] = function()
		waywall.exec("razer-cli --dpi 3200")
		resolutions.wide()
		eyeMode = false
	end,
	["*-4"] = function()
		waywall.exec("razer-cli --dpi 3200")
		resolutions.pre()
		eyeMode = false
	end,
	["shift-1"] = function()
		waywall.exec("razer-cli --dpi 3200")
		resolutions.tall()
		eyeMode = false
	end,

	["*-n"] = helpers.toggle_floating,
	["ctrl-n"] = exec_ninb,
	["ctrl-b"] = exec_pm,

	["ctrl-k"] = function()
		chat1:open()
	end,
	["ctrl-m"] = function()
		chat1:send("meow im a ranked gleeb born in 1528 while doing a femboyDancy playing ranked a lot")
	end,

	["ctrl-alt-l"] = function()
		emote_downloader.Fetch("01K5JRCYEH0YCV255WGKD5AAB2")
	end,
}

return config
