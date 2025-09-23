local waywall = require("waywall")
local json = require("dkjson")

local M = {
	instances = {}, -- keep multiple fetch runs alive if needed
}

local function write_raw_data(filename, data)
	local file = io.open(filename, "wb")
	if not file then
		error("Failed to open file: " .. filename)
	end
	file:write(data)
	file:close()
end

function M.Fetch(id)
	local state = {
		atlas_filename = "/home/arsoniv/.config/waywall/atlas.raw",
		emoteset_filename = "/home/arsoniv/.config/waywall/emoteset.json",
		target_len = 0,
		clen = 0,
		emote_atlas = nil,
		http_emoteset = nil,
		emote_set = {},
		http_index = 1,
		http_clients = {},
		current_atlas_x = 0,
		current_atlas_y = 0,
		max_row_height = 0,
	}

	-- export must close over state
	local function export_data()
		print("Exporting atlas and emote set...")

		local atlas_data = state.emote_atlas:get_dump()
		write_raw_data(state.atlas_filename, atlas_data)
		print("Atlas exported to: " .. state.atlas_filename)

		local emote_json = json.encode(state.emote_set, { indent = true })
		local file = io.open(state.emoteset_filename, "w")
		if not file then
			error("Failed to open emote set file: " .. state.emoteset_filename)
		end
		file:write(emote_json)
		file:close()
		print("Emote set exported to: " .. state.emoteset_filename)

		local emote_count = 0
		for _ in pairs(state.emote_set) do
			emote_count = emote_count + 1
		end
		print(string.format("Export complete! %d emotes saved.", emote_count))
	end

	local function http_callback(data)
		data = json.decode(data)
		state.target_len = #data.emotes
		print(string.format("Found %d emotes to download", state.target_len))

		for _, emote in ipairs(data.emotes) do
			local width = emote.data.host.files[1].width or 32
			local height = emote.data.host.files[1].height or 32
			local url
			if emote.data.animated then
				url = ("https://cdn.7tv.app/emote/%s/1x_static.png?n=%s&w=%d&h=%d"):format(
					emote.id,
					emote.name,
					width,
					height
				)
			else
				url = ("https://cdn.7tv.app/emote/%s/1x.png?n=%s&w=%d&h=%d"):format(emote.id, emote.name, width, height)
			end
			state.http_clients[state.http_index]:get(url)
			state.http_index = state.http_index % #state.http_clients + 1
		end
	end

	local function http_callback2(data, url)
		local name = url:match("[?&]n=([^&]+)")
		local width = tonumber(url:match("[?&]w=(%d+)")) or 32
		local height = tonumber(url:match("[?&]h=(%d+)")) or 32
		if not name then
			return
		end

		if state.current_atlas_x + width > 2048 then
			state.current_atlas_x = 0
			state.current_atlas_y = state.current_atlas_y + state.max_row_height
			state.max_row_height = 0

			if state.current_atlas_y + height > 2048 then
				print("WARNING: Atlas full! Overwriting from top.")
				state.current_atlas_x = 0
				state.current_atlas_y = 0
				state.max_row_height = 0
			end
		end

		state.emote_atlas:insert_raw(data, state.current_atlas_x, state.current_atlas_y)
		state.clen = state.clen + 1
		state.emote_set[name] = {
			x = state.current_atlas_x,
			y = state.current_atlas_y,
			w = width,
			h = height,
		}

		state.current_atlas_x = state.current_atlas_x + width
		state.max_row_height = math.max(state.max_row_height, height)

		print(
			string.format(
				"Added emote: %s (%dx%d) at (%d,%d) [%d/%d]",
				name,
				width,
				height,
				state.current_atlas_x - width,
				state.current_atlas_y,
				state.clen,
				state.target_len
			)
		)

		if state.clen >= state.target_len then
			print("All emotes have been fetched!")
			export_data()
		end
	end

	local function download_emotes()
		print("Downloading emotes for set ID: " .. id)
		state.http_clients = {
			waywall.http_client_create(http_callback2),
			waywall.http_client_create(http_callback2),
			waywall.http_client_create(http_callback2),
			waywall.http_client_create(http_callback2),
		}
		state.http_emoteset = waywall.http_client_create(http_callback)
		state.emote_atlas = waywall.atlas(2048)
		state.http_emoteset:get("http://7tv.io/v3/emote-sets/" .. id)
	end

	download_emotes()

	-- keep the whole state table in M so GC won't collect
	M.instances[id] = state
end

return M
