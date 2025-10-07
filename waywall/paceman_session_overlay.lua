-- paceman overlay
local waywall = require("waywall")
local json = require("dkjson")

local function ms_to_min_sec(ms)
	if not ms then
		return "0:00"
	end
	local total_seconds = math.floor(ms / 1000)
	local minutes = math.floor(total_seconds / 60)
	local seconds = total_seconds % 60
	return string.format("%d:%02d", minutes, seconds)
end

local EXCLUDE_KEYS = {
	id = true,
	time = true,
	updatedTime = true,
	realUpdated = true,
	lootBastion = true,
	obtainObsidian = true,
	obtainCryingObsidian = true,
}

local KEY_ORDER = {
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

local function new_paceman(username, x_stats, y_stats, x_runs, y_runs, size_stats, size_runs)
	local PACEMAN = {}

	PACEMAN.username = username
	PACEMAN.x_stats = x_stats or 25
	PACEMAN.y_stats = y_stats or 1060
	PACEMAN.x_runs = x_runs or 1125
	PACEMAN.y_runs = y_runs or 795
	PACEMAN.size_stats = size_stats or 25
	PACEMAN.size_runs = size_runs or 38
	PACEMAN.update_interval = 20000 -- 20 seconds

	PACEMAN.stats_data = nil
	PACEMAN.runs_data = nil
	PACEMAN.stats_text = nil
	PACEMAN.runs_text = nil
	PACEMAN.last_request_time = 0
	PACEMAN.http_client = nil
	PACEMAN.has_connected = false

	local function draw_stats()
		if PACEMAN.stats_text then
			PACEMAN.stats_text:close()
			PACEMAN.stats_text = nil
		end

		if PACEMAN.stats_data then
			local display_string = "Count: "
				.. tostring(PACEMAN.stats_data.count)
				.. "\nPer Hour: "
				.. tostring(PACEMAN.stats_data.rnph)
				.. "\nAverage: "
				.. ms_to_min_sec(PACEMAN.stats_data.avg)

			local state = waywall.state()
			if state.screen == "wall" then
				PACEMAN.stats_text = waywall.text("<#000000FF>" .. display_string, {
					x = PACEMAN.x_stats,
					y = PACEMAN.y_stats,
					size = PACEMAN.size_stats,
					shader = "rainbow_text",
				})
			end
		end
	end

	local function draw_runs()
		if PACEMAN.runs_text then
			PACEMAN.runs_text:close()
			PACEMAN.runs_text = nil
		end

		if PACEMAN.runs_data and PACEMAN.runs_data[1] then
			local display_string = "Last Nether: \n"
			local entry = PACEMAN.runs_data[1]

			for _, key in ipairs(KEY_ORDER) do
				local value = entry[key]
				if value and not EXCLUDE_KEYS[key] then
					display_string = display_string .. key .. ": " .. ms_to_min_sec(value) .. "\n"
				end
			end

			local state = waywall.state()
			if state.screen == "wall" then
				PACEMAN.runs_text = waywall.text("<#000000FF>" .. display_string, {
					x = PACEMAN.x_runs,
					y = PACEMAN.y_runs,
					size = PACEMAN.size_runs,
					shader = "rainbow_text",
				})
			end
		end
	end

	local function http_callback(response_string, url)
		print("HTTP Response from: " .. url)
		print(response_string)

		if url:find("getNPH") then
			PACEMAN.stats_data = json.decode(response_string, 1, nil)
			draw_stats()
		elseif url:find("getRecentRuns") then
			PACEMAN.runs_data = json.decode(response_string, 1, nil)
			draw_runs()
		end
	end

	local function make_requests()
		if not PACEMAN.http_client then
			return
		end

		local stats_url =
			string.format("https://paceman.gg/stats/api/getNPH/?name=%s&hours=2&hoursBetween=2", PACEMAN.username)
		local runs_url =
			string.format("https://paceman.gg/stats/api/getRecentRuns/?name=%s&hours=24&limit=1", PACEMAN.username)

		PACEMAN.http_client:get(stats_url)
		PACEMAN.http_client:get(runs_url)
	end

	local function state_callback()
		draw_stats()
		draw_runs()

		local state = waywall.state()
		if state.screen == "wall" then
			local now = waywall.current_time()
			if now > PACEMAN.last_request_time + PACEMAN.update_interval then
				make_requests()
				PACEMAN.last_request_time = now
			end
		end
	end

	function PACEMAN:open()
		if not self.has_connected then
			print("Starting Paceman overlay for " .. self.username)

			-- Create HTTP client with callback
			self.http_client = waywall.http_client_create(http_callback)

			-- Register state callback
			waywall.listen("state", state_callback)

			-- Make initial request
			make_requests()

			self.has_connected = true
		end
	end

	function PACEMAN:close()
		if self.stats_text then
			self.stats_text:close()
			self.stats_text = nil
		end
		if self.runs_text then
			self.runs_text:close()
			self.runs_text = nil
		end
		if self.http_client then
			self.http_client:close()
			self.http_client = nil
		end
	end

	function PACEMAN:set_update_interval(ms)
		self.update_interval = ms
	end

	return PACEMAN
end

return new_paceman
