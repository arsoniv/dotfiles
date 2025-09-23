local function round_angle(n)
	return math.floor(n * 100 + 0.5) / 100
end

local function angle_difference(a1, a2)
	local diff = a2 - a1
	diff = (diff + 180) % 360 - 180
	return diff
end

local function angle_to_destination(x_pos, z_pos, x_dest, z_dest)
	local dx = x_dest - x_pos
	local dz = z_dest - z_pos

	local angle_rad = math.atan2(-dx, dz)
	local angle_deg = math.deg(angle_rad)

	angle_deg = ((angle_deg + 180) % 360) - 180

	return angle_deg
end

local NB_OVERLAY = {}
local waywall = require("waywall")
local json = require("dkjson")

-- the waywall text object
local text = nil

-- the combine key-value table for ninbot data
local data = {}

local function display_overlay()
	-- funtion to display the overlay using the data

	if data.resultType and data.boatState then
		local display_string = ""

		if data.predictions and data.predictions[1] then
			local prediction = data.predictions[1]
			local blockX = prediction.chunkX * 2
			local blockZ = prediction.chunkZ * 2
			local nether_dist = math.floor(prediction.overworldDistance / 8)
			local angle = angle_to_destination(
				data.playerPosition.xInOverworld,
				data.playerPosition.zInOverworld,
				16 * prediction.chunkX + 4,
				16 * prediction.chunkZ + 4
			)
			display_string = blockX
				.. ", "
				.. blockZ
				.. "\n"
				.. nether_dist
				.. " blocks, "
				.. round_angle(angle_difference(data.playerPosition.horizontalAngle, angle))
				.. " deg"
		else
			display_string = data.boatState
		end

		if text then
			text:close()
		end
		text = nil

		text = waywall.text(display_string, 10, 1100, "#FFFFFFFF")
	end
end

local sh_req_index = 0
local boat_req_index = 0

-- function used by the keybind to make the request.
NB_OVERLAY.make_req = function()
	-- make requests with a 150ms delay
	sh_req_index = waywall.http_request("http://localhost:52533/api/v1/stronghold", 150)
	boat_req_index = waywall.http_request("http://localhost:52533/api/v1/boat", 150)
	return false
end

waywall.listen("http", function(response_string, index)
	print("recieved response")
	if index == sh_req_index or index == boat_req_index then
		local parsed = json.decode(response_string)
		-- combine the new data with the current data
		for k, v in pairs(parsed) do
			data[k] = v
		end

		display_overlay()
	end
end)

return NB_OVERLAY
