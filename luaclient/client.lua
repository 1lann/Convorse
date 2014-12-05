local debugLog = {}

local function log(...)
	local receive = {...}

	for k,v in pairs(receive) do
		if type(v) == "table" then
			receive[k] = textutils.serialize(v)
		end
	end

	local insert = table.concat(receive, ", ")

	for line in insert:gmatch("[^\n]+") do
		table.insert(debugLog, line)
	end
end


local args = {...}

local username = "1lann"
local password = "awdaw"

local activeConversations = {
	{
		name = "2lann",
		id = "awdu892qe",
		lastUpdate = 123123,
		unread = true,
		selected = false,
		inTabBar = true,
		x = 0,
		y = 0,
		width = 0,
	},
	{
		name = "gravityscore",
		id = "awdawddw",
		lastUpdate = 123122,
		unread = false,
		selected = true,
		inTabBar = true,
		x = 0,
		y = 0,
		width = 0,
	}
}

local cachedMessages = {
	["awdu892qe"] = {
		lastUpdate = 123, -- In os.clock() time
		{
			origin = "2lann",
			message = "Hello! This is a reasonably long message to test out text wrapping!",
			humanTime = "4 hours ago",
			timestamp = 129,

		},
		{
			origin = "2lann",
			message = "aHello! This is a reasonably long message to test out text wrapping!",
			humanTime = "4 hours ago",
			timestamp = 128,

		},
		{
			origin = "2lann",
			message = "bHello! This is a reasonably long message to test out text wrapping!",
			humanTime = "4 hours ago",
			timestamp = 127,

			},
		{
			origin = "2lann",
			message = "fHello! This is a reasonably long message to test out text wrapping!",
			humanTime = "4 hours ago",
			timestamp = 126,

		},
		{
			origin = "2lann",
			message = "Hgello! This is a reasonably long message to test out text wrapping!",
			humanTime = "4 hours ago",
			timestamp = 125,

		},
		{
			origin = "1lann",
			message = "hih",
			humanTime = "5 hours ago",
			timestamp = 124,
		},

	}
}

local messagePostTracker = {}

---
--- User interface tools
---

local theme = {
	background = colors.white,
	accent = colors.blue,
	text = colors.black,
	header = colors.white,
	input = colors.white,
	inputText = colors.gray,
	placeholder = colors.lightGray,
	err = colors.red,
	subtle = colors.lightGray,
	selected = colors.blue,
	unfocusedText = colors.lightBlue,
	selfOrigin = colors.lightBlue,
	externalOrigin = colors.blue,
	new = colors.red,
	timestamp = colors.lightGray,
	message = colors.gray,
}

-- if not term.isColor() then
-- 	theme = {
-- 		background = colors.white,
-- 		accent = colors.black,
-- 		text = colors.black,
-- 		header = colors.white,
-- 		input = colors.white,
-- 		inputText = colors.black,
-- 		placeholder = colors.black,
-- 		err = colors.black,
-- 		subtle = colors.white,
-- 		selected = colors.white,
-- 		selectedText = colors.black,
-- 		newIndicator = colors.red
-- 	}
-- end

local t = {
	bg = term.setBackgroundColor,
	tc = term.setTextColor,
	p = term.setCursorPos,
	gp = term.getCursorPos,
	c = term.clear,
	cl = term.clearLine,
	w = function(text)
		local x, y = term.getCursorPos()
		term.write(text)
		return {x = x, y = y, width = #text}
	end,
	nl = function(num)
		if not num then num = 1 end
		local x, y = term.getCursorPos()
		term.setCursorPos(1, y + num)
	end,
	up = function()
		local x, y = term.getCursorPos()
		term.setCursorPos(1, y - 1)
	end,
	o = function() term.setCursorPos(1, 1) end,
	db = function(height)
		local x, y = term.getCursorPos()
		for i = 1, height do
			term.setCursorPos(1, y + i - 1)
			term.clearLine()
		end
		term.setCursorPos(x, y)
	end
}

local w, h = term.getSize()

local isPocket = false

if w < 40 then
	isPocket = true
end

local center = function(text, shift)
	if not shift then shift = 0 end
	local x, y = t.gp()
	t.p(math.ceil(w / 2 - text:len() / 2) + 1 + shift, y)
	t.w(text)
	t.p(1, y + 1)
	return {math.ceil(w / 2 - text:len() / 2) + 1 + shift, y}
end

local right = function(text)
	local x, y = t.gp()
	t.p(w - #text + 1, y)
	t.w(text)
	t.p(1, y + 1)
	return {x = w - #text, y = y, width = #text - 1}
end

---
--- HTTP API and Fetching
---

local lastUpdateUnix = 0

local updatedConversationEvent = "convorse_conversation_update"
local messagePostResponseEvent = "convorse_message_post"
local generalErrorEvent = "convorse_general_error"
local databaseErrorEvent = "convorse_database_error"
local authErrorEvent = "convorse_auth_error"

local apiURL = "http://convorse.tk/api/"
local patternURL = "http://convorse%.tk/api/"

local pollTimer
local pollStart = -40
local pollURL = apiURL .. "poll"

local function parseServerResponse(text)

end

local function getConversation(id)
	http.request(apiURL .. "conversation", {
		username = username,
		password = password,
		conversation = id
	})
end

local function getUnread()
	http.request(apiURL .. "unread", {
		username = username,
		password = password
	})
end

local function postMessage(conversation, message, callbackInfo)
	http.request(apiURL .. "post", {
		username = username,
		password = password,
		conversation = conversation,
		message = message,
		callback = callbackInfo,
	})
end

local function getConversationByUsername(user)
	http.request(apiURL .. "user-conversation", {
		username = username,
		password = password,
		user = user
	})
end

local function markAsRead(conversation)
	http.request(apiURL .. "mark-as-read", {
		username = username,
		password = password,
		user = user
	})
end

local function poll(force)
	if (os.clock() > pollStart + 10) or force then
		http.request(pollURL, {
			username = username,
			password = password,
			lastUpdate = lastUpdateUnix,
		})

		pollTimer = os.startTimer(35)
		pollStart = os.clock()
	end
end

local successHandlers = {
	["conversation"] = function(resp)
		local result = resp.readAll()
		if not result then
			os.queueEvent(generalErrorEvent, {"Empty response while", "fetching conv. data"})
		else
			local parseResult = parseServerResponse(result)
			if parseResult == "success" then
				os.queueEvent(updatedConversationEvent)
			elseif parseResult == "database" then
				os.queueEvent(databaseErrorEvent)
			elseif parseResult == "server-error" then
				os.queueEvent(generalErrorEvent, {"Server Error", "on conversation"})
			elseif parseResult == "auth-error" then
				os.queueEvent(authErrorEvent)
			else
				os.queueEvent(generalErrorEvent, {"Parse Error", "on conversation"})
			end
		end
	end,

	["user-conversation"] = function(resp)
		local result = resp.readAll()
		if not result then
			os.queueEvent(generalErrorEvent, {"Empty response while", "fetching user conv. data"})
		else
			local parseResult = parseServerResponse(result)
			if parseResult == "success" then
				os.queueEvent(updatedConversationEvent)
			elseif parseResult == "database" then
				os.queueEvent(databaseErrorEvent)
			elseif parseResult == "server-error" then
				os.queueEvent(generalErrorEvent, {"Server Error", "on user conversation"})
			elseif parseResult == "auth-error" then
				os.queueEvent(authErrorEvent)
			else
				os.queueEvent(generalErrorEvent, {"Parse Error", "on user conversation"})
			end
		end
	end,

	["unread"] = function(resp)
		local result = resp.readAll()
		if not result then
			os.queueEvent(generalErrorEvent, {"Empty response while", "fetching unread data"})
		else
			local parseResult = parseServerResponse(result)
			if parseResult == "success" then
				os.queueEvent(updatedConversationEvent)
			elseif parseResult == "database" then
				os.queueEvent(databaseErrorEvent)
			elseif parseResult == "server-error" then
				os.queueEvent(generalErrorEvent, {"Server Error", "on unread"})
			elseif parseResult == "auth-error" then
				os.queueEvent(authErrorEvent)
			else
				os.queueEvent(generalErrorEvent, {"Parse Error", "on unread"})
			end
		end
	end,

	["post"] = function(resp)
		local result = resp.readAll()
		if not result then
			os.queueEvent(messagePostResponseEvent, "failure")
		else
			local parseResult, callbackInfo = parseServerResponse(result)
			if parseResult == "success" then
				os.queueEvent(messagePostResponseEvent, "success", callbackInfo)
			elseif parseResult == "database" then
				os.queueEvent(databaseErrorEvent)
			elseif parseResult == "server-error" then
				os.queueEvent(generalErrorEvent, {"Server Error", "on message post"})
			elseif parseResult == "auth-error" then
				os.queueEvent(authErrorEvent)
			else
				os.queueEvent(generalErrorEvent, {"Parse Error", "on message post"})
			end
		end
	end,

	["poll"] = function(resp)
		local result = resp.readAll()
		if not result then
			-- Retry
			poll(true)
		else
			local parseResult = parseServerResponse(result)
			if parseResult == "success" then
				os.queueEvent(updatedConversationEvent, "poll")
				poll(true)
			elseif parseResult == "poll-timeout" then
				poll(true)
			elseif parseResult == "database" then
				os.queueEvent(databaseErrorEvent)
			elseif parseResult == "server-error" then
				os.queueEvent(generalErrorEvent, {"Server Error", "on polling"})
			elseif parseResult == "auth-error" then
				os.queueEvent(authErrorEvent)
			else
				os.queueEvent(generalErrorEvent, {"Parse Error", "on polling"})
			end
		end
	end,

	["mark-as-read"] = function()
		local result = resp.readAll()
		if result then
			local parseResult = parseServerResponse(result)
			if parseResult == "success" then

			elseif parseResult == "database" then
				os.queueEvent(databaseErrorEvent)
			elseif parseResult == "server-error" then
				os.queueEvent(generalErrorEvent, {"Server Error", "on reading message"})
			elseif parseResult == "auth-error" then
				os.queueEvent(authErrorEvent)
			end
		end
	end
}

local failureHandlers = {
	["conversation"] = function()
		os.queueEvent(generalErrorEvent, {"HTTP error while", "fetching conv. data"})
	end,

	["user-conversation"] = function()
		os.queueEvent(generalErrorEvent, {"HTTP error while", "fetching user-conv. data"})
	end,

	["unread"] = function()
		os.queueEvent(generalErrorEvent, {"HTTP error while", "fetching unread data"})
	end,

	["post"] = function()
		os.queueEvent(messagePostResponseEvent, "failure")
	end,

	["poll"] = function()
		poll()
	end,
}


local function fetchManager()
	while true do
		local event, url, resp = os.pullEvent()
		if event == "http_success" then
			if successHandlers[url:gsub(patternURL, "")] then
				successHandlers[url:gsub(patternURL, "")]()
			end
		elseif event == "http_failure" then
			if failureHandlers[url:gsub(patternURL, "")] then
				failureHandlers[url:gsub(patternURL, "")]()
			end
		elseif event == "timer" then
			if url == pollTimer then
				poll()
			end
		end
	end
end

---
--- Processing help
---

local function processConversation(conversationID)
	local conversationMessages = cachedMessages[conversationID]

	if not conversationMessages then return nil end

	local displaySim = {}

	table.sort(conversationMessages, function(a, b)
		return a.timestamp < b.timestamp
	end)

	for k,v in pairs(conversationMessages) do
		if type(v) == "table" then
			local selfOrigin = false
			if v.origin == username then
				selfOrigin = true
			end

			-- if not (k - 1 > 0 and conversationMessages[k - 1].origin == v.origin) then
				local displayName = ""

				if isPocket then
					if #v.origin > 12 then
						displayName = "<" .. v.origin:sub(1, 12) .. ">"
					else
						displayName = "<" .. v.origin .. ">"
					end
				else
					if #v.origin > 22 then
						displayName = "<" .. v.origin:sub(1, 22) .. ">"
					else
						displayName = "<" .. v.origin .. ">"
					end
				end

				-- table.insert(displaySim, {spacer = true})
				table.insert(displaySim, {block = true, selfOrigin = selfOrigin, username = true, content = displayName, humanTime = v.humanTime})
			-- end

			local message = v.message

			local availableWidth = w

			if not isPocket then
				availableWidth = 40
			end

			local textWrapper = {}
			local wrapLine = ""


			for word in message:gmatch("%S+") do
				if #(wrapLine .. word) > availableWidth then
					table.insert(textWrapper, wrapLine:sub(1, -2))
					wrapLine = ""
				end

				wrapLine = wrapLine .. word .. " "
			end

			table.insert(textWrapper, wrapLine)

			for k,v in pairs(textWrapper) do
				table.insert(displaySim, {block = true, selfOrigin = selfOrigin, content = v})
			end

			table.insert(displaySim, {spacer = true})
		end
	end

	return displaySim
end

---
--- Drawing the loading screen
---

local function drawLoadingHeader()
	t.bg(theme.background)
	t.c()

	t.o()
	t.tc(theme.header)
	t.bg(theme.accent)
	t.db(4)

	t.nl()
	center("- Convorse -")
	center("A web chat client")
	t.nl()
end

local function drawLoading()
	drawLoadingHeader()
	t.nl(5)
	t.tc(theme.accent)
	t.bg(theme.background)
	center("Logged in!")
	t.nl()
	t.tc(theme.placeholder)
	center("Loading...")
	sleep(3)
	return
end

-- drawLoading()

---
--- Draw the main interface
---

unreadInteractivity = {}

local function drawTopMenuBar()
	t.p(1, 1)
	t.bg(theme.accent)
	t.tc(theme.header)
	t.db(1)

	if not isPocket then
		t.w(" ")
	end

	if not isPocket then
		if #username > 15 then
			t.w("Convorse | " .. username:sub(1, 15))
		else
			t.w("Convorse | " .. username)
		end
	else
		if #username > 9 then
			t.w("Convorse|" .. username:sub(1,9))
		else
			t.w("Convorse|" .. username)
		end
	end

	t.tc(colors.lightBlue)

	if isPocket then
		right("Log Out")
	else
		right("Log Out ")
	end
end

local function drawTabMenuBar()
	t.bg(theme.accent)
	t.cl()

	if not isPocket then
		t.w(" ")
	end

	for k, conversation in pairs(activeConversations) do
		if conversation.inTabBar then
			local toWrite

			local maxLimit = 5

			if not isPocket then
				maxLimit = 8
			end

			if #conversation.name > maxLimit then
				toWrite = conversation.name:sub(1, maxLimit) .. " "
			else
				toWrite = conversation.name .. " "
			end

			local x, y = t.gp()

			if w - x + 1 < (#toWrite + 2) then
				conversation.x = nil
				conversation.y = nil
				conversation.width = nil
				break
			end

			conversation.x, conversation.y = x, y

			if conversation.unread then
				t.tc(theme.unfocusedText)
				t.w("*")
			end

			if conversation.selected then
				t.bg(theme.selected)
				t.tc(theme.header)
			else
				t.bg(theme.accent)
				t.tc(theme.unfocusedText)
			end

			if not conversation.unread then
				t.w(" ")
			end

			t.w(toWrite)
			conversation.width = #toWrite
		end
	end

	t.bg(theme.accent)
	t.tc(theme.header)
	t.w("+")
end

local function drawMenuBar()
	drawTopMenuBar()
	drawTabMenuBar()
end

local function clear()
	t.bg(theme.background)
	t.c()
	drawMenuBar()
end

local function drawChatArea(conversationID, scroll)
	if not scroll then
		scroll = 0
	end

	local conversation

	for k, v in pairs(activeConversations) do
		if v.id == conversationID then
			conversation = v
			v.selected = true
		else
			v.selected = false
		end
	end

	local conversationRender = processConversation(conversationID)

	t.bg(theme.background)
	for i = 3, h do
		t.p(1, i)
		t.cl()
	end

	if not conversation or not conversationRender then
		t.p(1,10)
		t.bg(theme.background)
		t.tc(theme.err)

		if not isPocket then
			center("Error loading conversation!")
		else
			center("Error loading")
			center("conversation!")
		end
		return
	end

	t.p(1, h)

	local screenIncrement = 3

	for i = #conversationRender - scroll - (h - 4), #conversationRender - scroll do
		if conversationRender[i] then
			-- log(conversationRender[i])

			if isPocket then
				t.p(1, screenIncrement)
			else
				t.p(6, screenIncrement)
			end

			if conversationRender[i].block then
				t.tc(theme.message)

				if conversationRender[i].selfOrigin then
					if conversationRender[i].username then
						t.tc(theme.selfOrigin)
					end
				else
					if conversationRender[i].username then
						t.tc(theme.externalOrigin)
					end
				end

				t.w(string.rep(" ", 40))
				if isPocket then
					t.p(1, screenIncrement)
				else
					t.p(6, screenIncrement)
				end
				t.w(conversationRender[i].content)

				if conversationRender[i].humanTime then
					t.bg(theme.background)
					t.tc(theme.timestamp)

					if isPocket then
						right(conversationRender[i].humanTime)
					else
						right(conversationRender[i].humanTime .. string.rep(" ", 6))
					end
				end
			end

			screenIncrement = screenIncrement + 1
		end
	end

end

local function drawHome()
	t.p(1,3)
	t.nl()
	t.bg(theme.background)
	t.tc(theme.text)
	center("Welcome, " .. username)
	t.nl()

	local unread = 0
	for k,v in pairs(activeConversations) do
		if v.unread then
			unread = unread + 1
		end
	end

	if unread <= 0 then
		if isPocket then
			center("You have no")
			center("unread conversations")
		else
			center("You have no unread conversations")
		end
	else
		if not isPocket then
			t.w(" ")
		end
		t.w("Unread conversations:")
		t.nl()
		t.tc(theme.accent)

		for k,v in pairs(activeConversations) do
			if v.unread then
				if not isPocket then
					t.w(" ")
				end
				table.insert(unreadInteractivity, t.w(v.name))
			end
		end
	end

	t.tc(theme.text)

	if isPocket then
		t.p(1, h - 3)
		center("Click on the   in the")
		t.tc(theme.header)
		t.bg(theme.accent)
		t.up()
		center("+", 3)
		t.tc(theme.text)
		t.bg(theme.background)
		center("tab bar to start")
		center("a new conversation")
	else
		t.p(1, h - 2)
		center("Click on the   in the tab bar to")
		t.tc(theme.header)
		t.bg(theme.accent)
		t.up()
		center("+", -2)
		t.tc(theme.text)
		t.bg(theme.background)
		center("start a new conversation")
	end
end

clear()

log("Program start")

local scroll = 0
while true do
	local event, amount = os.pullEvent()
	if event == "mouse_scroll" then
		scroll = scroll + amount
		drawChatArea("awdu892qe", scroll)
	elseif event == "key" and amount == 28 then
		break
	end
end

log("Program end")

log({"This is a table", "with string! :D"}, "\nMutli variable too!", 123)





os.pullEvent("key")
term.setBackgroundColor(colors.black)
term.setTextColor(colors.yellow)
term.setCursorPos(1,2)
term.clear()
print("Debugger - Events:")
term.setTextColor(colors.white)
for k,v in pairs(debugLog) do
	textutils.pagedPrint(v)
end
os.pullEvent("key")
return shell.run(shell.getRunningProgram())
