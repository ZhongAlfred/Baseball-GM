json = require("json");
utils = require("utils");
storyboard = require("storyboard")
local performance = require('performance')

storyboard.purgeOnSceneChange = true;

-- Turn off status bar.
display.setStatusBar(display.HiddenStatusBar);


-- Initial startup info.
os.execute("cls");
utils:log("main", "Baseball GM STARTING...");
utils:log("main", "Environment: " .. system.getInfo("environment"));
utils:log("main", "Model: " .. system.getInfo("model"));
utils:log("main", "Device ID: " .. system.getInfo("deviceID"));
utils:log("main", "Platform Name: " .. system.getInfo("platformName"));
utils:log("main", "Platform Version: " .. system.getInfo("version"));
utils:log("main", "Corona Version: " .. system.getInfo("version"));
utils:log("main", "Corona Build: " .. system.getInfo("build"));
utils:log("main", "display.contentWidth: " .. display.contentWidth);
utils:log("main", "display.contentHeight: " .. display.contentHeight);
utils:log("main", "display.fps: " .. display.fps);
utils:log("main", "audio.totalChannels: " .. audio.totalChannels);

--Start fps and and memory usage monitor (Displayed on screen);
--utils:showFPSAndMem();
--performance:newPerformanceMeter();


-- Seed random number generator.
math.randomseed(os.time());

--Universal code to
--Handle database closing (only applies to variable 'db')
--No need to add this code segment to the rest of the project
local function onSystemEvent( event )
	if( event.type == "applicationExit" ) then    
		if (db and db:isopen()) then
		db:close()
		else
			print("no db available");
		end
	end
end
Runtime:addEventListener( "system", onSystemEvent )

--Cover up edges with black bounding (So we can't see menu when it is off to the left)
--Semi-transparent black background that covers whole screen and blocks touches
local black = display.newImage("Images/black.png", -200, 0);
black.width, black.height = 200, display.contentHeight
black.anchorX, black.anchorY = 0,0
black.alpha = 1;

local function blockTouches(event)
	return true; --Block the propagation of any touches or taps
end
black:addEventListener("tap", blockTouches);
black:addEventListener("touch", blockTouches);
black:toFront()



--Initiate Sound Effects
globalSounds = {
	tap = audio.loadSound("Sounds/tap.wav"),
	alert = audio.loadSound("Sounds/alert.wav"),
}

--Initiate analytics (global variable so all scenes can use it)
analytics = require( "analytics" )
analytics.init( "CJMZ88Y9YMC4T5MB7Y5F" )


storyboard.gotoScene("mainMenuScene", "fade", 500);