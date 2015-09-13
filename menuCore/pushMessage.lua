local widget = require("widget");
--**************************
--[[IMPORTANT NOTE

The pushMessage module was separated from the menuScene module so it can be
called from both menuScene AND seasonSimulator. Previously, it could only be
called from the menuScene module

]]--
--***************************

--Handles message that pops up from the bottom of the screen
local pushMessage = {
	message = {
		elements = {}
	},
}

function pushMessage:newMessage(from, messageText)


	local black = display.newImage("Images/black.png", 0, 0);
	black.width, black.height = display.contentWidth, display.contentHeight
	black.anchorX, black.anchorY = 0,0
	black.alpha = .9;
	
	local function blockTouches(event)
		return true; --Block the propagation of any touches or taps
	end
	black:addEventListener("tap", blockTouches);
	black:addEventListener("touch", blockTouches);
	pushMessage.message.elements[#pushMessage.message.elements+1] = black
	
	local message = display.newGroup()
	message.anchorX, message.anchorY = 0,0
	message.x, message.y = 0, 0
	message.anchorChildren = true
	
	local bg = display.newImage("Images/popup.png", 0, 0);
	bg.width, bg.height = display.contentWidth, display.contentHeight/2
	bg.anchorX, bg.anchorY = 0,0
	bg.alpha = .9;
	
	local mail = display.newImage("Images/mail.png", 0, 0);
	mail.xScale, mail.yScale = .3, .3
	mail.anchorX, mail.anchorY = 0,0
	mail.y = mail.y - (mail.height*mail.yScale)/2
	
	local fromLabel = display.newText(from, mail.x + mail.width*mail.xScale + 10, mail.y + mail.height*mail.yScale/2, 
		native.systemFontBold, 28);
	fromLabel.anchorX, fromLabel.anchorY = 0, .5;
	
	local messageLabel = display.newText(messageText, bg.width/2, bg.height/2, native.systemFont, 20);
	messageLabel.anchorX, messageLabel.anchorY = .5, .5;
	
	local function destroy(event)
		if (event.phase == "ended") then pushMessage:closeMessage(message); end
	end
	--Exit button
	local exit = widget.newButton
	{
		x = display.contentWidth,
		y = mail.y + mail.height*mail.yScale/2,
		defaultFile = "Images/x.png",
		onEvent = destroy
	}
	exit.anchorX, exit.anchorY = 1, .5; 
	
	message:insert(bg)
	message:insert(mail)
	message:insert(fromLabel)
	message:insert(messageLabel)
	message:insert(exit)
	
	--Hide message underneath screen (calling showMessage will reveal it)
	message.y = display.contentHeight + message.height
	
	pushMessage.message.elements[#pushMessage.message.elements+1] = message;
	
	return message
	
end

function pushMessage:showMessage(message)
	transition.to(message, {y = display.contentHeight/2, time = 400})
end

function pushMessage:closeMessage(message)
	local function destroy() pushMessage:destroyMessage() end
	transition.to(message, {y = display.contentHeight + message.height, time = 400, onComplete = destroy})
end

function pushMessage:destroyMessage()
	for i = 1, #pushMessage.message.elements do
		if (pushMessage.message.elements[i] ~= nil) then
			pushMessage.message.elements[i]:removeSelf();
			pushMessage.message.elements[i] = nil;
		end
	end
	pushMessage.message.elements = {};
	
end

return pushMessage