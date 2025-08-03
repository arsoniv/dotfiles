local NB_OVERLAY = {}

local waywall = require("waywall")
local json = require("dkjson")
local util = require("util")

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
			local certainty = prediction.certainty
			local blockX = prediction.chunkX * 2
			local blockZ = prediction.chunkZ * 2
			local nether_dist = math.floor(prediction.overworldDistance / 8)
			local angle = util.angle_to_destination(
				data.playerPosition.xInOverworld,
				data.playerPosition.zInOverworld,
				16 * prediction.chunkX + 4,
				16 * prediction.chunkZ + 4
			)
			display_string = "x "
				.. blockX
				.. ", z "
				.. blockZ
				.. ", "
				.. util.round(certainty * 100)
				.. "%\n"
				.. nether_dist
				.. ", a "
				.. util.round(util.angle_difference(data.playerPosition.horizontalAngle, angle))
		else
			display_string = data.boatState
		end

		if text then
			text:close()
		end
		text = nil

		text = waywall.text(display_string, 10, 1115, "#FFFFFF", 38)
	end
end

-- function used by the keybind to make the request.
NB_OVERLAY.make_req = function()
	-- make requests with a 150ms delay
	waywall.http_request("http://localhost:52533/api/v1/stronghold", 150)
	waywall.http_request("http://localhost:52533/api/v1/boat", 150)
	return false
end

waywall.listen("http", function(response_string)
	local parsed = json.decode(response_string)
	-- combine the new data with the current data
	for k, v in pairs(parsed) do
		data[k] = v
	end

	display_overlay()
end)

return NB_OVERLAY
