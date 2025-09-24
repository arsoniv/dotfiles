local waywall = require("waywall")
local priv = require("priv")
local utf8 = require("utf8")
local json = require("dkjson")

local INVISIBLE_CHARS = {
	[0x200B] = true, -- ZERO WIDTH SPACE
	[0x200C] = true, -- ZERO WIDTH NON-JOINER
	[0x200D] = true, -- ZERO WIDTH JOINER
	[0x034F] = true, -- COMBINING GRAPHEME JOINER
	[0xFE0F] = true, -- VARIATION SELECTOR
}

local function strip_invisible(s)
	local t = {}
	for _, c in utf8.codes(s) do
		if not INVISIBLE_CHARS[c] then
			table.insert(t, utf8.char(c))
		end
	end
	return table.concat(t)
end

local function read_raw_data(filename)
	local file = io.open(filename, "rb")
	if not file then
		error("Failed to open file: " .. filename)
	end
	local data = file:read("*a")
	file:close()
	return data
end

local function read_json(filename)
	local file = io.open(filename, "r")
	if not file then
		error("Failed to open file: " .. filename)
	end
	local content = file:read("*a")
	file:close()
	return json.decode(content)
end

local atlas_filename = "/home/arsoniv/.config/waywall/atlas.raw"
local emoteset_filename = "/home/arsoniv/.config/waywall/emoteset.json"

local function new_chat(channel, x, y, size)
	local CHAT = {}

	CHAT.username = "Arsoniv"
	CHAT.token = priv.twitch_oauth
	CHAT.channel = channel
	CHAT.ip = "irc.chat.twitch.tv"
	CHAT.port = 6667

	CHAT.messages = {}
	CHAT.chat_text = nil
	CHAT.chat_x = x
	CHAT.chat_y = y
	CHAT.chat_rows = 15
	CHAT.text_height = 16
	CHAT.max_cols = 100
	CHAT.has_joined = false
	CHAT.irc_client = nil
	CHAT.message_lifespan = 3000
	CHAT.size = size
	CHAT.self_id = 0
	CHAT.emote_set = {}
	CHAT.emote_atlas = nil
	CHAT.emote_images = {}
	CHAT.ls = 15 -- line gaps
	CHAT.emote_h = 16

	local function draw_chat()
		if CHAT.chat_text ~= nil then
			CHAT.chat_text:close()
			CHAT.chat_text = nil
		end

		for _, v in ipairs(CHAT.emote_images) do
			v:close()
		end
		CHAT.emote_images = {}

		local text_buf = ""
		local current_line = 0

		for i = 1, #CHAT.messages do
			local message = CHAT.messages[i]
			local s = string.sub(message.text, 1, CHAT.max_cols)

			local body = ""
			local message_prefix = "<" .. message.color .. "FF>" .. message.user .. "<#FFFFFFFF>: "

			for word in s:gmatch("%S+") do
				word = strip_invisible(word)

				local emote = CHAT.emote_set[word]
				if emote and CHAT.emote_atlas then
					local text_before_emote = text_buf .. message_prefix .. body
					local advance = waywall.text_advance(text_before_emote, CHAT.size)

					local emote_h = 32
					local aspect = emote.w / emote.h
					local emote_w = emote_h * aspect

					body = body .. "<+" .. emote_w .. "> "

					local line_height = CHAT.size + CHAT.ls
					local line_top = CHAT.chat_y + current_line * line_height - CHAT.size / 2
					local emote_y = line_top - (CHAT.emote_h - CHAT.size - CHAT.ls / 2) / 2

					local new_image = waywall.image_a({
						src = { x = emote.x, y = emote.y, w = emote.w, h = emote.h },
						dst = {
							x = advance.x + CHAT.chat_x,
							y = emote_y,
							w = emote_w,
							h = emote_h,
						},
						atlas = CHAT.emote_atlas,
					})

					table.insert(CHAT.emote_images, new_image)
				else
					body = body .. word .. " "
				end
			end

			text_buf = text_buf .. message_prefix .. body .. "\n"
			current_line = current_line + 1
		end

		CHAT.chat_text = waywall.text(text_buf, {
			x = CHAT.chat_x,
			y = CHAT.chat_y + CHAT.size,
			size = CHAT.size,
			ls = CHAT.ls,
		})
		print(text_buf)
	end

	function CHAT:send(msg)
		if self.irc_client then
			local new_id = CHAT.self_id + 1
			CHAT.self_id = new_id
			print("Sending message: " .. msg)
			self.irc_client:send("PRIVMSG #" .. self.channel .. " :" .. msg .. "\r\n")
			table.insert(CHAT.messages, {
				user = CHAT.username,
				text = strip_invisible(msg),
				color = "#FFFFFF",
				id = CHAT.self_id,
			})

			if #CHAT.messages > CHAT.chat_rows then
				while #CHAT.messages > CHAT.chat_rows do
					table.remove(CHAT.messages, 1)
				end
			end

			draw_chat()

			if CHAT.message_lifespan then
				waywall.sleep(CHAT.message_lifespan)

				for i = #CHAT.messages, 1, -1 do
					if CHAT.messages[i].id == new_id then
						table.remove(CHAT.messages, i)
						break
					end
				end
				draw_chat()
			end
		else
			print("Client not connected yet!")
		end
	end

	local function irc_callback(line)
		print(line)
		local user = line:match("display%-name=([^;]+)")
		local msg = line:match("PRIVMSG #[^ ]+ :(.+)$")
		local color = line:match("color=([^;]+)")
		local id = line:match("id=([^;]+)")

		if color == nil then
			color = "#FFFFFF"
		end

		if line:find("CLEARCHAT") then
			local msg_id = line:match("target%-msg%-id=([^; ]+)")
			local user = line:match("CLEARCHAT #[^ ]+ :([^ ]+)")

			if msg_id then
				for i = #CHAT.messages, 1, -1 do
					if CHAT.messages[i].id == msg_id then
						table.remove(CHAT.messages, i)
						break
					end
				end
			elseif user then
				for i = #CHAT.messages, 1, -1 do
					if CHAT.messages[i].user == user then
						table.remove(CHAT.messages, i)
					end
				end
			end

			draw_chat()
		elseif line:find("USERNOTICE") then
			local msg_id = line:match("msg%-id=([^;]+)")
			table.insert(CHAT.messages, {
				user = msg_id .. " from",
				text = user,
				color = "#FFFFFF",
				id = id,
			})

			if #CHAT.messages > CHAT.chat_rows then
				while #CHAT.messages > CHAT.chat_rows do
					table.remove(CHAT.messages, 1)
				end
			end

			draw_chat()

			if CHAT.message_lifespan then
				waywall.sleep(CHAT.message_lifespan)

				for i = #CHAT.messages, 1, -1 do
					if CHAT.messages[i].id == id then
						table.remove(CHAT.messages, i)
						break
					end
				end
				draw_chat()
			end
			return
		elseif line:find("CLEARMSG") then
			local msg_id = line:match("target%-msg%-id=([^; ]+)")

			if msg_id then
				for i = #CHAT.messages, 1, -1 do
					if CHAT.messages[i].id == msg_id then
						table.remove(CHAT.messages, i)
						break
					end
				end
				draw_chat()
			end
			return
		elseif user and msg then
			print("inserting message with id: " .. id)
			table.insert(CHAT.messages, {
				user = user,
				text = msg,
				color = color,
				id = id,
			})

			if #CHAT.messages > CHAT.chat_rows then
				while #CHAT.messages > CHAT.chat_rows do
					table.remove(CHAT.messages, 1)
				end
			end

			draw_chat()

			if CHAT.message_lifespan then
				waywall.sleep(CHAT.message_lifespan)

				for i = #CHAT.messages, 1, -1 do
					if CHAT.messages[i].id == id then
						table.remove(CHAT.messages, i)
						break
					end
				end
				draw_chat()
			end
		end
	end

	function CHAT:open()
		if not self.has_connected then
			print("Starting Chat...")

			print("Loading emote atlas from: " .. atlas_filename)
			print("Loading emote set from: " .. emoteset_filename)

			CHAT.emote_set = read_json(emoteset_filename)

			local atlas_data = read_raw_data(atlas_filename)
			CHAT.emote_atlas = waywall.atlas(0, atlas_data)

			local emote_count = 0
			for _ in pairs(CHAT.emote_set) do
				emote_count = emote_count + 1
			end
			print("Loaded emote atlas and " .. tostring(emote_count) .. " emotes")

			-- create irc client
			self.irc_client = waywall.irc_client_create(self.ip, self.port, self.username, self.token, irc_callback)

			-- create emote texture atlas if not already loaded
			if not self.emote_atlas then
				self.emote_atlas = waywall.atlas(2048)
			end

			-- sleep to allow irc client to connect
			waywall.sleep(3000)

			-- cap request for more info and join channel
			self.irc_client:send("CAP REQ :twitch.tv/tags twitch.tv/commands\r\n")
			self.irc_client:send("JOIN #" .. self.channel .. "\r\n")
		end
	end

	return CHAT
end

return new_chat
