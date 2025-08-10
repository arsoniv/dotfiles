local waywall = require("waywall")
local priv = require("priv")
local util = require("util")

local function new_chat(channel, x, y, rows, cols, size, lifespan)
	local CHAT = {}

	CHAT.username = "arsoniv"
	CHAT.token = priv.twitch_oauth
	CHAT.channel = channel
	CHAT.ip = "irc.chat.twitch.tv"
	CHAT.port = 6667

	CHAT.messages = {}
	CHAT.chat_text = nil
	CHAT.chat_x = x
	CHAT.chat_y = y
	CHAT.chat_rows = rows
	CHAT.text_height = size
	CHAT.max_cols = cols
	CHAT.has_connected = false
	CHAT.has_joined = false
	CHAT.client = nil
	CHAT.message_lifespan = lifespan

	function CHAT:send(msg)
		if self.client and self.has_connected then
			print("Sending message: " .. msg)
			self.client:send("PRIVMSG #" .. self.channel .. " :" .. msg .. "\r\n")
		else
			print("Client not connected yet!")
		end
	end

	local function draw_chat()
		if CHAT.chat_text ~= nil then
			CHAT.chat_text:close()
			CHAT.chat_text = nil
		end

		local text_buf = ""

		for i = 1, #CHAT.messages do
			local message = CHAT.messages[i]
			text_buf = text_buf
				.. "<"
				.. message.color
				.. "FF>"
				.. message.user
				.. ": <#FFFFFFFF>"
				.. string.sub(message.text, 0, CHAT.max_cols)
				.. "\n"
		end

		CHAT.chat_text = waywall.text(text_buf, CHAT.chat_x, CHAT.chat_y, CHAT.text_height)
	end

	local function callback(line)
		-- uncomment below to see every event (useful for seeing the format and debugging)
		-- print("\n" .. line .. "\n")

		local user = line:match("display%-name=([^;]+)")
		local msg = line:match("PRIVMSG #[^ ]+ :(.+)$")
		local color = line:match("color=([^;]+)")
		local id = line:match("id=([^;]+)")

		if color == nil then
			color = "#FFFFFF"
		end

		if line:find("CLEARCHAT") then -- Handle CLEARCHAT
			local msg_id = line:match("target%-msg%-id=([^; ]+)")
			local user = line:match("CLEARCHAT #[^ ]+ :([^ ]+)")

			if msg_id then
				for i = #CHAT.messages, 1, -1 do
					if CHAT.messages[i].id == msg_id then
						table.remove(CHAT.messages, i)
						break
					end
				end
			elseif user then -- delete all messages
				for i = #CHAT.messages, 1, -1 do
					if CHAT.messages[i].user == user then
						table.remove(CHAT.messages, i)
					end
				end
			end

			draw_chat()
		elseif line:find("CLEARMSG") then -- Handle CLEARMSG
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
		elseif user and msg then -- Handle Message
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
			print("starting client")
			self.client = waywall.irc_client_create(self.ip, self.port, self.username, self.token, callback)
			self.has_connected = true

			waywall.sleep(3000)
			self.client:send("CAP REQ :twitch.tv/tags twitch.tv/commands\r\n")
			self.client:send("JOIN #" .. self.channel .. "\r\n")
		end
	end

	return CHAT
end

return new_chat
