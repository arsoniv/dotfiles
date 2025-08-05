local waywall = require("waywall")
local priv = require("priv")

local function new_chat(channel, x, y, rows, cols, size)
	local CHAT = {}

	CHAT.username = "arsoniv"
	CHAT.token = priv.twitch_oauth
	CHAT.channel = channel
	CHAT.ip = "irc.chat.twitch.tv"
	CHAT.port = 6667

	CHAT.messages = {}
	CHAT.chat_texts = {}
	CHAT.chat_x = x
	CHAT.chat_y = y
	CHAT.chat_rows = rows
	CHAT.text_height = size
	CHAT.max_cols = cols
	CHAT.has_connected = false
	CHAT.has_joined = false
	CHAT.client = nil

	function CHAT:send_hi()
		if self.client and self.has_connected then
			print("Sending 'hi' message.")
			self.client:send("PRIVMSG #" .. self.channel .. " :hi\r\n")
		else
			print("Client not connected yet!")
		end
	end

	local function draw_chat()
		-- Clear previous texts
		for i = 1, #CHAT.chat_texts do
			CHAT.chat_texts[i]:close()
			CHAT.chat_texts[i] = nil
		end

		local chat_y = CHAT.chat_y

		for i = math.max(#CHAT.messages - CHAT.chat_rows + 1, 1), #CHAT.messages do
			local m = CHAT.messages[i]
			local name_text = m.user
			local body_text = ": " .. m.text

			-- Truncate full message if too long for max cols (optional)
			local full_text = name_text .. body_text
			if #full_text > CHAT.max_cols then
				body_text = body_text:sub(1, CHAT.max_cols - #name_text - 3) .. "..."
			end

			-- Create name text object
			local name_obj = waywall.text(name_text, CHAT.chat_x, chat_y, m.color .. "FF", CHAT.text_height)
			-- Position body text just after name using advance
			local name_advance = name_obj:advance()

			local body_x = CHAT.chat_x + name_advance
			local body_obj = waywall.text(body_text, body_x, chat_y, "FFFFFFFF", CHAT.text_height)

			-- Insert both into chat_texts for later cleanup
			table.insert(CHAT.chat_texts, name_obj)
			table.insert(CHAT.chat_texts, body_obj)

			chat_y = chat_y + CHAT.text_height
		end
	end

	local function callback(line)
		-- uncomment below to see every event (useful for seeing the format and debugging)
		print("\n" .. line .. "\n")
		local user = line:match("display%-name=([^;]+)")
		local msg = line:match("PRIVMSG #[^ ]+ :(.+)$")
		local color = line:match("color=([^;]+)")

		if color == nil then
			color = "#FFFFFF"
		end

		if user and msg then
			table.insert(CHAT.messages, {
				user = user,
				text = msg,
				color = color,
			})
			if #CHAT.messages > CHAT.chat_rows then
				local excess = #CHAT.messages - CHAT.chat_rows
				for i = 1, excess do
					table.remove(CHAT.messages, 1)
				end
			end
			draw_chat()
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
