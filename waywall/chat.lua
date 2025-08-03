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

	local function draw_chat()
		for i = 1, #CHAT.chat_texts do
			CHAT.chat_texts[i]:close()
			CHAT.chat_texts[i] = nil
		end

		local chat_y = CHAT.chat_y

		for i = math.max(#CHAT.messages - CHAT.chat_rows + 1, 1), #CHAT.messages do
			local m = CHAT.messages[i]
			local display_text = m.user .. ": " .. m.text
			if #display_text > CHAT.max_cols then
				display_text = display_text:sub(1, CHAT.max_cols - 3) .. "..."
			end
			local new_text_obj = waywall.text(display_text, CHAT.chat_x, chat_y, m.color .. "FF", CHAT.text_height)
			chat_y = chat_y + CHAT.text_height
			table.insert(CHAT.chat_texts, new_text_obj)
		end
	end

	local function callback(line)
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

			waywall.sleep(1000)
			self.client:send("CAP REQ :twitch.tv/tags twitch.tv/commands\r\n")
			waywall.sleep(1000)
			self.client:send("JOIN #" .. self.channel .. "\r\n")
		end
	end

	return CHAT
end

return new_chat
