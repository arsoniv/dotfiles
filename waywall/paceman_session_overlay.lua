local waywall = require("waywall")
local json = require("dkjson")
local util = require("util")

-- NPH AND OTHER STATS
local last_index = 0
local text = nil
local saved_data = nil

--MOST RECENT RUN
local last_index2 = 0
local text2 = nil
local saved_data2 = nil

local last_request_unix_time = 0

local exclude_keys = {
	id = true,
	time = true,
	updatedTime = true,
	realUpdated = true,
	lootBastion = true,
	obtainObsidian = true,
	obtainCryingObsidian = true,
}

local key_order = {
	"nether",
	"bastion",
	"fortress",
	"first_portal",
	"stronghold",
	"end",
	"finish",
	"lootBastion",
	"obtainObsidian",
	"obtainCryingObsidian",
	"obtainRod",
	"time",
	"updatedTime",
	"realUpdated",
}

local function display_overlay()
	if saved_data ~= nil then
		local display_string = "Count: "
			.. tostring(saved_data.count)
			.. "\nPer Hour: "
			.. tostring(saved_data.rnph)
			.. "\nAverage: "
			.. util.ms_to_min_sec(saved_data.avg)

		if text then
			text:close()
			text = nil
		end

		local state = waywall.state()
		if state.screen == "wall" then
			text = waywall.text(display_string, 25, 1020, "#FFFFFF", 38)
		end
	end
end

local function display_overlay2()
	if saved_data2 ~= nil then
		local display_string = "Last Nether: \n"
		if saved_data2[1] ~= nil then
			local entry = saved_data2[1]

			for _, key in ipairs(key_order) do
				local value = entry[key]
				if value ~= nil and not exclude_keys[key] then
					display_string = display_string .. key .. ": " .. tostring(util.ms_to_min_sec(value)) .. "\n"
				end
			end
		end

		if text2 then
			text2:close()
			text2 = nil
		end

		local state = waywall.state()
		if state.screen == "wall" then
			text2 = waywall.text(display_string, 1120, 815, "#FFFFFF", 28)
		end
	end
end

local make_request = function()
	local response = waywall.http_request("https://paceman.gg/stats/api/getNPH/?name=arsoniv&hours=2&hoursBetween=2", 0)
	if response ~= nil then
		last_index = response
	end
	local response2 =
		waywall.http_request("https://paceman.gg/stats/api/getRecentRuns/?name=arsoniv&hours=24&limit=1", 100)
	if response2 ~= nil then
		last_index2 = response2
	end
end

waywall.listen("http", function(string, i)
	print(string)
	if i == last_index then
		saved_data = json.decode(string, 1, nil)
		display_overlay()
	end
	if i == last_index2 then
		saved_data2 = json.decode(string, 1, nil)
		display_overlay2()
	end
end)

waywall.listen("state", function()
	display_overlay()
	display_overlay2()

	local state = waywall.state()
	if state.screen == "wall" then
		local now = waywall.current_time()
		if now > last_request_unix_time + 20000 then
			make_request()
			last_request_unix_time = now
		end
	end
end)
