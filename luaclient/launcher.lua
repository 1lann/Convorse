local theme = {
	background = colors.white,
	accent = colors.blue,
	text = colors.black,
	header = colors.white,
	input = colors.white,
	inputText = colors.gray,
	placeholder = colors.lightGray,
	err = colors.red,
}

if not term.isColor() then
	theme = {
		background = colors.white,
		accent = colors.black,
		text = colors.black,
		header = colors.white,
		input = colors.white,
		inputText = colors.black,
		placeholder = colors.black,
		err = colors.black,
	}
end

local t = {
	bg = term.setBackgroundColor,
	tc = term.setTextColor,
	p = term.setCursorPos,
	gp = term.getCursorPos,
	c = term.clear,
	cl = term.clearLine,
	w = term.write,
	nl = function(num)
		if not num then num = 1 end
		local x, y = term.getCursorPos()
		term.setCursorPos(1, y + num)
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

local function textField(startX, startY, length, startingText, placeholder,
		shouldHideText, eventCallback)
	local horizontalScroll = 1
	local cursorPosition = 1
	local data = startingText
	local eventCallbackResponse = nil
	local method = "enter"

	if not data then
		data = ""
	else
		cursorPosition = data:len() + 1
	end

	while true do
		term.setCursorBlink(true)
		term.setBackgroundColor(theme.background)
		term.setTextColor(theme.inputText)

		term.setCursorPos(startX, startY)
		term.write(string.rep(" ", length))
		term.setCursorPos(startX, startY)

		local text = data
		if shouldHideText then
			text = string.rep("*", #data)
		end
		term.write(text:sub(horizontalScroll, horizontalScroll + length - 1))

		if #data == 0 and placeholder then
			term.setTextColor(theme.placeholder)
			term.write(placeholder)
		end

		term.setCursorPos(startX + cursorPosition - horizontalScroll, startY)

		local event = {os.pullEvent()}
		if eventCallback then
			local shouldReturn, response = eventCallback(event)
			if shouldReturn then
				eventCallbackResponse = response
				method = "callback"
				break
			end
		end

		local isMouseEvent = event[1] == "mouse_click" or event[1] == "mouse_drag"

		if isMouseEvent then
			local inHorizontalBounds = event[3] >= startX and event[3] < startX + length
			local inVerticalBounds = event[4] == startY
			if inHorizontalBounds and inVerticalBounds then
				local previousX = term.getCursorPos()
				local position = cursorPosition - (previousX - event[3])
				cursorPosition = math.min(position, #data + 1)
			end
		elseif event[1] == "char" then
			if term.getCursorPos() >= startX + length - 1 then
				horizontalScroll = horizontalScroll + 1
			end

			cursorPosition = cursorPosition + 1
			local before = data:sub(1, cursorPosition - 1)
			local after = data:sub(cursorPosition, -1)
			data = before .. event[2] .. after
		elseif event[1] == "key" then
			if event[2] == keys.enter then
				break
			elseif event[2] == keys.left and cursorPosition > 1 then
				cursorPosition = cursorPosition - 1
				if cursorPosition <= horizontalScroll and horizontalScroll > 1 then
					local amount = ((horizontalScroll - cursorPosition) + 1)
					horizontalScroll = horizontalScroll - amount
				end
			elseif event[2] == keys.right and cursorPosition <= data:len() then
				cursorPosition = cursorPosition + 1
				if 1 >= length - (cursorPosition - horizontalScroll) + 1 then
					horizontalScroll = horizontalScroll + 1
				end
			elseif event[2] == keys.backspace and cursorPosition > 1 then
				data = data:sub(1, cursorPosition - 2) .. data:sub(cursorPosition, -1)
				cursorPosition = cursorPosition - 1
				if cursorPosition <= horizontalScroll and horizontalScroll > 1 then
					local amount = ((horizontalScroll - cursorPosition) + 1)
					horizontalScroll = horizontalScroll - amount
				end
			end
		end
	end

	term.setCursorBlink(false)
	return method, data, eventCallbackResponse
end

local centerField = function(width, placeholder)
	local x, y = t.gp()
	t.p(math.floor(w / 2 - width / 2) + 1, y)
	t.bg(theme.input)
	t.tc(theme.placeholder)
	t.w(placeholder .. string.rep(" ", width - #placeholder))
	t.p(1, y + 1)
	return {math.floor(w / 2 - width / 2) + 1, y}
end

local center = function(text)
	local x, y = t.gp()
	t.p(math.floor(w / 2 - text:len() / 2) + 1, y)
	t.w(text)
	t.p(1, y + 1)
	return {math.floor(w / 2 - text:len() / 2) + 1, y}
end

local centerButton = function(width, text)
	local x, y = t.gp()
	t.p(math.floor(w / 2 - width / 2) + 1, y)
	t.bg(theme.accent)
	t.tc(theme.header)
	t.w(string.rep(" ", width))
	center(text)
	return {math.floor(w / 2 - width / 2) + 1, y}
end

local usernameFieldStart, passwordFieldStart, buttonTopLeft, registerStart, backStart

local function drawHeader()
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

local function drawLogin(errorMessage, username)
	drawHeader()

	if errorMessage then
		t.bg(theme.err)
		t.tc(theme.header)
		t.db(3)
		t.nl()
		center(errorMessage)
		t.nl()
	end
	t.tc(theme.text)
	t.bg(theme.background)
	t.nl()
	center("Welcome Back")
	t.nl()
	usernameFieldStart = centerField(20, "Username")
	center("--------------------")
	passwordFieldStart = centerField(20, "Password")
	center("--------------------")
	t.nl()
	loginStart = centerButton(20, "Login")
	t.nl()
	t.tc(theme.accent)
	t.bg(theme.background)
	registerStart = center("Need an account?    ")
end

local function drawRegister()
	drawHeader()
	t.tc(theme.text)
	t.bg(theme.background)
	t.nl()
	center("You can register an   ")
	center("account online at     ")
	center("http://convorse.tk    ")
	t.nl()
	center("Registering in game   ")
	center("is currently not      ")
	center("supported             ")
	t.nl()
	t.tc(theme.accent)
	backStart = center("< Back                ")
end

local activeField = "username"
local username = ""
local password = ""
local errorMessage = nil

local loginFocusManager

local function register()
	drawRegister()
	while true do
		local event, mouse, x, y = os.pullEvent()
		if event == "mouse_click" then
			if y == backStart[2] and x >= backStart[1] and x <= backStart[1] + 5 then
				return
			end
		elseif event == "key" then
			return
		end
	end
end

local errorSubmitURL = "http://convorse.tk/api/error"

local function login()
	drawHeader()
	t.nl(5)
	t.tc(theme.accent)
	t.bg(theme.background)
	center("Logging in...")
	sleep(3)
	errorMessage = "Username required"
	return
end

-- local function textField(posX, posY, length, curData, placeholder, handler)

function loginFocusManager()
	local activeField = "username"

	while true do
		local function textHandler(events)
			if events[1] == "mouse_click" then
				if (events[4] == usernameFieldStart[2] or events[4] == usernameFieldStart[2] + 1) and
				events[3] >= usernameFieldStart[1] and
				events[3] <= usernameFieldStart[1] + 19 then
					if activeField ~= "username" then
						return true, {"username", unpack(events)}
					end
				elseif (events[4] == passwordFieldStart[2] or events[4] == passwordFieldStart[2] + 1) and
				events[3] >= passwordFieldStart[1] and
				events[3] <= passwordFieldStart[1] + 19 then
					if activeField ~= "password" then
						return true, {"password", unpack(events)}
					end
				elseif events[4] == loginStart[2] and
				events[3] >= loginStart[1] and events[3] <= loginStart[1] + 19 then
					return true, {"login", unpack(events)}
				elseif events[4] == registerStart[2] and events[3] >= registerStart[1] and events[3] <= registerStart[1] + 16 then
					return true, {"register", unpack(events)}
				else
					return true, {"nothing", unpack(events)}
				end
			end
		end

		if activeField == "nothing" then
			while true do
				local resp
				resp, callbackResponse = textHandler({os.pullEvent()})
				if resp then
					activeField = callbackResponse[1]
					break
				end
			end
		elseif activeField == "username" then
			local resp, data, callback = textField(usernameFieldStart[1], usernameFieldStart[2], 20, username, "Username", false, textHandler)

			if resp == "enter" then
				activeField = "password"
				username = data
			else
				activeField = callback[1]
				username = data
				os.queueEvent(callback[2], callback[3], callback[4], callback[5])
			end
		elseif activeField == "password" then
			local resp, data, callback = textField(passwordFieldStart[1], passwordFieldStart[2], 20, password, "Password", true, textHandler)

			if resp == "enter" then
				activeField = "nothing"
				password = data
				login()
			else
				activeField = callback[1]
				password = data
				os.queueEvent(callback[2], callback[3], callback[4], callback[5])
			end
		elseif activeField == "login" then
			login()
			drawLogin(errorMessage)
			password = ""
			activeField = "username"
		elseif activeField == "register" then
			register()
			drawLogin()
			password = ""
			activeField = "username"
		end
	end
end

drawLogin()
loginFocusManager()
