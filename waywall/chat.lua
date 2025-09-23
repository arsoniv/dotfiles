local waywall = require("waywall")
local json = require("dkjson")
local priv = require("priv")
local utf8 = require("utf8")

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
	CHAT.has_connected = false
	CHAT.has_joined = false
	CHAT.irc_client = nil
	CHAT.http_emoteset = nil
	CHAT.http_clients = {}
	CHAT.http_index = 1
	CHAT.message_lifespan = 10000 -- 10 seconds
	CHAT.size = size
	CHAT.self_id = 0
	CHAT.emote_set = {}
	CHAT.emote_atlas = nil
	CHAT.emotes = {}
	CHAT.emote_images = {}

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
				if emote then
					local text_before_emote = text_buf .. message_prefix .. body
					local advance = waywall.text_advance(text_before_emote, CHAT.size)

					body = body .. "   "

					local aspect = emote.w / emote.h
					local emote_h = CHAT.size
					local emote_w = CHAT.size * aspect
					local line_height = CHAT.size + 6

					local line_number = current_line

					local line_top = CHAT.chat_y + line_number * line_height

					local emote_y = line_top + (line_height - emote_h) / 2

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
			ls = 6,
		})
	end

	function CHAT:send(msg)
		if self.irc_client and self.has_connected then
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

	local function http_callback(data)
		data = json.decode(data)

		for _, emote in ipairs(data.emotes) do
			local width = emote.data.width or 32
			local height = emote.data.height or 32
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

			-- distribute evenly across http_clients
			CHAT.http_clients[CHAT.http_index]:get(url)
			CHAT.http_index = CHAT.http_index % #CHAT.http_clients + 1
		end
	end

	CHAT.current_atlas_x = 0
	CHAT.current_atlas_y = 0

	local function http_callback2(data, url)
		local name = url:match("[?&]n=([^&]+)")
		local width = tonumber(url:match("[?&]w=(%d+)")) or 32
		local height = tonumber(url:match("[?&]h=(%d+)")) or 32
		if not name then
			return
		end

		CHAT.emote_atlas:insert_raw(data, CHAT.current_atlas_x, CHAT.current_atlas_y)

		CHAT.emote_set[name] = {
			x = CHAT.current_atlas_x,
			y = CHAT.current_atlas_y,
			w = width,
			h = height,
		}

		CHAT.current_atlas_x = CHAT.current_atlas_x + width
		if CHAT.current_atlas_x >= 2048 - width then
			CHAT.current_atlas_x = 0
			CHAT.current_atlas_y = CHAT.current_atlas_y + height
			if CHAT.current_atlas_y >= 2048 - height then
				CHAT.current_atlas_x = 0
				CHAT.current_atlas_y = 0
				print("No more room in atlas, overwriting")
			end
		end

		print(("Added emote: %s (%dx%d)"):format(name, width, height))
	end

	function CHAT:open()
		if not self.has_connected then
			print("starting client")
			-- create irc client
			self.irc_client = waywall.irc_client_create(self.ip, self.port, self.username, self.token, irc_callback)

			-- create 4 http clients
			self.http_clients = {
				waywall.http_client_create(http_callback2),
				waywall.http_client_create(http_callback2),
				waywall.http_client_create(http_callback2),
				waywall.http_client_create(http_callback2),
				waywall.http_client_create(http_callback2),
				waywall.http_client_create(http_callback2),
				waywall.http_client_create(http_callback2),
			}
			self.http_emoteset = waywall.http_client_create(http_callback)
			self.has_connected = true

			-- create emote texture atlas
			self.emote_atlas = waywall.atlas(2048)

			-- fetch emotes
			self.http_emoteset:get("http://7tv.io/v3/emote-sets/01GK85Q2KR0004CEXMKS14YZJV")

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
