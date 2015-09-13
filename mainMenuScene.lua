-- Create a scene object to tie functions to.
local scene = storyboard.newScene();
local widget = require("widget");
local json = require("json");
local sg = require("simulatorCore.scheduleGenerator");
local pg = require("simulatorCore.playerGenerator");
local ss = require("simulatorCore.seasonSimulator");
local sqlite3 = require "sqlite3"
local pMsg = require("menuCore.pushMessage")

local mainMenuScene = {

	button1,
	button2,
	button3,
	button4,
	popup = {
		customRoster = false,
		elements = {},
		teamStepper, --Lets you choose teams
		teamDisplay, --Display team currently chosen
		teamCounter = 1,
		rosters = {
		"Randomly Generated",
		"MLB 2015",
		},
		teams = {
		"Arizona Desert",
		"Atlanta Lightning",
		"Baltimore Birds",
		"Boston Waves",
		"Chicago Cows",
		"Cincinnati Rolls",
		"Cleveland Kings",
		"Colorado Mountains",
		"Detroit Combustors",
		"Houston Stars",
		"Kansas City Plains",
		"Los Angeles Tremors",
		"London Brigadiers",
		"Miami Bandwagons",
		"Milwaukee Knights",
		"Minnesota Mammoths",
		"New York Revolutions",
		"Oakland Otters",
		"Philadelphia Pineapples",
		"Pittsburgh Miners",
		"San Diego Surfers",
		"San Francisco Tides",
		"Seattle Settlers",
		"Shanghai Shenanigans",
		"St. Louis Warriors",
		"Tampa Bay Sages",
		"Texas Cowboys",
		"Toronto Borders",
		"Tokyo Titans",
		"Washington Presidents"
		},
		teamsMLB = {
		"Arizona Diamondbacks",
		"Atlanta Braves",
		"Baltimore Orioles",
		"Boston Red Sox",
		"Chicago Cubs",
		"Chicago White Sox",
		"Cincinnati Reds",
		"Cleveland Indians",
		"Colorado Rockies",
		"Detroit Tigers",
		"Houston Astros",
		"Kansas City Royals",
		"Los Angeles Angels",
		"Los Angeles Dodgers",
		"Miami Marlins",
		"Milwaukee Brewers",
		"Minnesota Twins",
		"New York Mets",
		"New York Yankees",
		"Oakland Athletics",
		"Philadelphia Phillies",
		"Pittsburgh Pirates",
		"San Diego Padres",
		"San Francisco Giants",
		"Seattle Mariners",
		"St. Louis Cardinals",
		"Tampa Bay Rays",
		"Texas Rangers",
		"Toronto Blue Jays",
		"Washington Nationals"
		},
	},
}

-- ============================================================================
-- Called when the scene's view does not exist.
-- ============================================================================
function scene:createScene(inEvent)
	
	print("SQLite version: " .. sqlite3.version())
	utils:log("gameScene", "createScene()");
	
	--Load background
	local bg = display.newImage("Images/Grass.png", 0 , 0);
	bg.anchorX, bg.anchorY = 0, 0;
	self.view:insert(bg);
	
	
	--Load menu
	local options = {
		width = 250,
		height = 80,
		numFrames = 8,
		sheetContentWidth = 500,
		sheetContentHeight = 320
	}
	local buttonSheet = graphics.newImageSheet( "Images/main_menu_sheet.png", options )


	local function handleButtonEvent( event )
		local button = event.target.id;
		local phase = event.phase

		if ( phase == "ended" ) then
			audio.play( globalSounds["tap"] )
			if (button == "new") then
				scene:showPopup();
			elseif (button == "continue") then
				local path = system.pathForFile("data.db", system.DocumentsDirectory)
				local fhd = io.open( path )
				if (fhd) then
					fhd:close()
					--File exists, may continue
					storyboard.gotoScene("menuScene", "fade", 500);
				end
				
			elseif (button == "tutorial") then
				local options = {
					effect = "fade",
					time = 500,
					params = { isTutorial = true }
				}
				storyboard.gotoScene( "menuScene", options )
				--storyboard.gotoScene("tutorialScene", "fade", 500);
			elseif (button == "exit") then
				native:requestExit();
			end
		end
		return true
	end

	mainMenuScene.button1 = widget.newButton
	{
		id = "new",
		sheet = buttonSheet,
		defaultFrame = 1,
		overFrame = 2,
		onEvent = handleButtonEvent
	}
	mainMenuScene.button2 = widget.newButton
	{
		id = "continue",
		sheet = buttonSheet,
		defaultFrame = 3,
		overFrame = 4,
		onEvent = handleButtonEvent
	}
	mainMenuScene.button3 = widget.newButton
	{
		id = "tutorial",
		sheet = buttonSheet,
		defaultFrame = 5,
		overFrame = 6,
		onEvent = handleButtonEvent
	}
	mainMenuScene.button4 = widget.newButton
	{
		id = "exit",
		sheet = buttonSheet,
		defaultFrame = 7,
		overFrame = 8,
		onEvent = handleButtonEvent
	}

	local table_buttons = {mainMenuScene.button1, mainMenuScene.button2, mainMenuScene.button3, mainMenuScene.button4};

	for i = 1, #table_buttons do
		table_buttons[i].anchorX, table_buttons[i].anchorY = .5,0;
		table_buttons[i].x = display.contentCenterX;
		table_buttons[i].y = 90 * (i);
		self.view:insert(table_buttons[i]);
	end
	  
	  
	--Version number label
	local version = display.newText( "v 1.0.0", 5, 5, native.systemFont, 22 )
	version.anchorX,  version.anchorY = 0, 0;
	self.view:insert(version)
	
	--Message label
	local bugs = display.newText( "", display.contentWidth - 5, 5, native.systemFont, 22 )
	bugs.anchorX,  bugs.anchorY = 1, 0;
	bugs:setFillColor(.8,.8,.8)
	self.view:insert(bugs)
	
		
	--Custom message
	local function networkListener( event )
        if ( event.isError ) then
			--Bad internet connection
			print("Bad connection")
        else
			--Conjugating Algorithm
			local code = event.response;
			--print(code)
			local beginIndex = string.find(code, [[<meta property="og:description" content="]]);
			local endIndex = string.find(code, [["/>]], beginIndex);
			local message = string.sub(code,beginIndex+string.len([[<meta property="og:description" content="]]),endIndex-1);
			--print("Begin: " .. beginIndex .. "   End: " .. endIndex);
			bugs.text = message;
        end
	end
	local site = "http://textuploader.com/xmuq";
	network.request( site, "GET", networkListener )
	
	--Custom link for message
	local function networkListener2( event )
        if ( event.isError ) then
			--Bad internet connection
			print("Bad connection")
        else
			--Conjugating Algorithm
			local code = event.response;
			--print(code)
			local beginIndex = string.find(code, [[<meta property="og:description" content="]]);
			local endIndex = string.find(code, [["/>]], beginIndex);
			local message = string.sub(code,beginIndex+string.len([[<meta property="og:description" content="]]),endIndex-1);
			
			local function openSite()
				-- log --analytics events
				analytics.logEvent( "Opened reddit baseball gm page" )
				system.openURL(message)
			end
			bugs:addEventListener("tap", openSite);
        end
	end
	local site2 = "http://textuploader.com/a687t";
	network.request( site2, "GET", networkListener2 )
	
	

	
end -- End createScene().


-- ============================================================================
-- Called BEFORE scene has moved on screen.
-- ============================================================================
function scene:willEnterScene(inEvent)

  utils:log("gameScene", "willEnterScene()");

end -- End willEnterScene().


-- ============================================================================
-- Called AFTER scene has moved on screen.
-- ============================================================================
function scene:enterScene(inEvent)

  utils:log("gameScene", "enterScene()");

end -- End enterScene().


-- ============================================================================
-- Called BEFORE scene moves off screen.
-- ============================================================================
function scene:exitScene(inEvent)

  utils:log("gameScene", "exitScene()");


end -- End exitScene().


-- ============================================================================
-- Called AFTER scene has moved off screen.
-- ============================================================================
function scene:didExitScene(inEvent)
	
  storyboard.removeScene("mainMenuScene")	
  utils:log("gameScene", "didExitScene()");

end -- End didExitScene().


-- ============================================================================
-- Called prior to the removal of scene's "view" (display group).
-- ============================================================================
function scene:destroyScene(inEvent)

  utils:log("gameScene", "destroyScene()");


end -- End destroyScene().


-- ****************************************************************************
-- ****************************************************************************
-- **********                 EXECUTION BEGINS HERE.                 **********
-- ****************************************************************************
-- ****************************************************************************


--Select team popup
function scene:showPopup()
	
	--Disable all of the main menu buttons
	mainMenuScene.button1:setEnabled(false);
	mainMenuScene.button2:setEnabled(false);
	mainMenuScene.button3:setEnabled(false);
	mainMenuScene.button4:setEnabled(false);
	
	--Popup Background
	local function handleTouch(event)
		return true; --Stop touch propagation from going to buttons under popup
	end
	
	local bg = display.newImage("Images/popup.png", display.contentCenterX , display.contentCenterY);
	bg.alpha = 1;
	bg:addEventListener("touch", handleTouch);
	mainMenuScene.popup.elements[#mainMenuScene.popup.elements+1] = bg;
	self.view:insert(bg);
	
	--Create appropriate popup labels
	local function tap(event)
		audio.play( globalSounds["tap"] )
		if (event.target.text == "Cancel") then
			scene:destroyPopup();
		elseif (event.target.text == "Go") then
			local roster = mainMenuScene.popup.teamDisplay.text
			scene:destroyPopup();
			scene:showPopup2(roster);
		end
	end
	
	
	local choose = display.newText( "Choose Roster:", display.contentCenterX, display.contentCenterY - 100 + 15, native.systemFont, 24 )
	choose.anchorX,  choose.anchorY = 0.5, 0;
	mainMenuScene.popup.elements[#mainMenuScene.popup.elements+1] = choose;
	
	local cancel = display.newText( "Cancel", display.contentCenterX - 200 + 15, display.contentCenterY + 100 - 15, native.systemFont, 24 )
	cancel.anchorX,  cancel.anchorY = 0, 1;
	cancel:addEventListener("tap", tap);
	mainMenuScene.popup.elements[#mainMenuScene.popup.elements+1] = cancel;
	
	local go = display.newText( "Go", display.contentCenterX + 200 - 15, display.contentCenterY + 100 - 15, native.systemFont, 24 )
	go.anchorX,  go.anchorY = 1, 1;
	go:addEventListener("tap", tap);
	mainMenuScene.popup.elements[#mainMenuScene.popup.elements+1] = go;
	
	
	--Team Stepper
	-- Handle stepper events
	mainMenuScene.popup.teamDisplay = display.newText( mainMenuScene.popup.rosters[mainMenuScene.popup.teamCounter], display.contentCenterX -30, display.contentCenterY, native.systemFont, 20 )
	mainMenuScene.popup.teamDisplay.anchorX,  mainMenuScene.popup.teamDisplay.anchorY = 0, .5;
	mainMenuScene.popup.teamDisplay:setFillColor(1,1,1); 
	self.view:insert(mainMenuScene.popup.teamDisplay);
	
	local function onStepperPress( event )
	
		mainMenuScene.popup.teamStepper:setValue(1); --Ignore the built in corona stepper counter, it messes things up
		if ( "increment" == event.phase ) then
			mainMenuScene.popup.teamCounter = mainMenuScene.popup.teamCounter + 1
			if (mainMenuScene.popup.teamCounter > #mainMenuScene.popup.rosters) then --Loop to the start
				mainMenuScene.popup.teamCounter = 1
			end
		elseif ( "decrement" == event.phase ) then
			mainMenuScene.popup.teamCounter = mainMenuScene.popup.teamCounter - 1
			if (mainMenuScene.popup.teamCounter < 1) then --Loop to the end
				mainMenuScene.popup.teamCounter = #mainMenuScene.popup.rosters
			end
		end
		--print("Counter: " .. mainMenuScene.popup.teamCounter);
		mainMenuScene.popup.teamDisplay.text  = mainMenuScene.popup.rosters[mainMenuScene.popup.teamCounter];
	end

	-- Image sheet options and declaration
	local options = {
		width = 100,
		height = 50,
		numFrames = 5,
		sheetContentWidth = 100,
		sheetContentHeight = 250
	}
	local stepperSheet = graphics.newImageSheet( "Images/stepper.png", options )

	-- Create the widget
	mainMenuScene.popup.teamStepper = widget.newStepper
	{
		initialValue = 10,
		x = display.contentCenterX - 40,
		y = display.contentCenterY,
		width = 100,
		height = 50,
		sheet = stepperSheet,
		defaultFrame = 1,
		noMinusFrame = 2,
		noPlusFrame = 3,
		minusActiveFrame = 4,
		plusActiveFrame = 5,
		onPress = onStepperPress
	}
	mainMenuScene.popup.teamStepper.anchorX, mainMenuScene.popup.teamStepper.anchorY = 1, 0.5;
	self.view:insert(mainMenuScene.popup.teamStepper);
	


end

function scene:showPopup2(roster)
	
	local list
	
	if (roster == "Randomly Generated") then list = mainMenuScene.popup.teams
	else list = mainMenuScene.popup.teamsMLB end
	
	--Disable all of the main menu buttons
	mainMenuScene.button1:setEnabled(false);
	mainMenuScene.button2:setEnabled(false);
	mainMenuScene.button3:setEnabled(false);
	mainMenuScene.button4:setEnabled(false);
	
	--Popup Background
	local function handleTouch(event)
		return true; --Stop touch propagation from going to buttons under popup
	end
	
	local bg = display.newImage("Images/popup.png", display.contentCenterX , display.contentCenterY);
	bg.alpha = 1;
	bg:addEventListener("touch", handleTouch);
	mainMenuScene.popup.elements[#mainMenuScene.popup.elements+1] = bg;
	self.view:insert(bg);
	
	--Create appropriate popup labels
	local function tap(event)
		audio.play( globalSounds["tap"] )
		if (event.target.text == "Cancel") then
			scene:destroyPopup();
		elseif (event.target.text == "Go") then
			analytics.logEvent("New Game", {team = list[mainMenuScene.popup.teamCounter]} )
			scene:newGame(mainMenuScene.popup.teamCounter, roster);
			
			--Initial message shown to player
			local path = system.pathForFile("data.db", system.DocumentsDirectory)
			db = sqlite3.open( path )  
			ss:generateSeasonGoals(mainMenuScene.popup.teamCounter)
			db:close()
			
			scene:destroyPopup();
			storyboard.gotoScene("menuScene", "fade", 500);
			
		end
	end
	
	
	local choose = display.newText( "Choose Team:", display.contentCenterX, display.contentCenterY - 100 + 15, native.systemFont, 24 )
	choose.anchorX,  choose.anchorY = 0.5, 0;
	mainMenuScene.popup.elements[#mainMenuScene.popup.elements+1] = choose;
	
	local cancel = display.newText( "Cancel", display.contentCenterX - 200 + 15, display.contentCenterY + 100 - 15, native.systemFont, 24 )
	cancel.anchorX,  cancel.anchorY = 0, 1;
	cancel:addEventListener("tap", tap);
	mainMenuScene.popup.elements[#mainMenuScene.popup.elements+1] = cancel;
	
	local go = display.newText( "Go", display.contentCenterX + 200 - 15, display.contentCenterY + 100 - 15, native.systemFont, 24 )
	go.anchorX,  go.anchorY = 1, 1;
	go:addEventListener("tap", tap);
	mainMenuScene.popup.elements[#mainMenuScene.popup.elements+1] = go;
	
	
	--Team Stepper
	-- Handle stepper events
	mainMenuScene.popup.teamDisplay = display.newText( list[mainMenuScene.popup.teamCounter], display.contentCenterX -30, display.contentCenterY, native.systemFont, 20 )
	mainMenuScene.popup.teamDisplay.anchorX,  mainMenuScene.popup.teamDisplay.anchorY = 0, .5;
	mainMenuScene.popup.teamDisplay:setFillColor(1,1,1); 
	self.view:insert(mainMenuScene.popup.teamDisplay);
	
	local function onStepperPress( event )
	
		mainMenuScene.popup.teamStepper:setValue(1); --Ignore the built in corona stepper counter, it messes things up
		if ( "increment" == event.phase ) then
			mainMenuScene.popup.teamCounter = mainMenuScene.popup.teamCounter + 1
			if (mainMenuScene.popup.teamCounter > #list) then --Loop to the start
				mainMenuScene.popup.teamCounter = 1
			end
		elseif ( "decrement" == event.phase ) then
			mainMenuScene.popup.teamCounter = mainMenuScene.popup.teamCounter - 1
			if (mainMenuScene.popup.teamCounter < 1) then --Loop to the end
				mainMenuScene.popup.teamCounter = #list
			end
		end
		--print("Counter: " .. mainMenuScene.popup.teamCounter);
		mainMenuScene.popup.teamDisplay.text  = list[mainMenuScene.popup.teamCounter];
	end

	-- Image sheet options and declaration
	local options = {
		width = 100,
		height = 50,
		numFrames = 5,
		sheetContentWidth = 100,
		sheetContentHeight = 250
	}
	local stepperSheet = graphics.newImageSheet( "Images/stepper.png", options )

	-- Create the widget
	mainMenuScene.popup.teamStepper = widget.newStepper
	{
		initialValue = 10,
		x = display.contentCenterX - 40,
		y = display.contentCenterY,
		width = 100,
		height = 50,
		sheet = stepperSheet,
		defaultFrame = 1,
		noMinusFrame = 2,
		noPlusFrame = 3,
		minusActiveFrame = 4,
		plusActiveFrame = 5,
		onPress = onStepperPress
	}
	mainMenuScene.popup.teamStepper.anchorX, mainMenuScene.popup.teamStepper.anchorY = 1, 0.5;
	self.view:insert(mainMenuScene.popup.teamStepper);
	


end

function scene:destroyPopup()
	
	for i = 1, #mainMenuScene.popup.elements do
		if (mainMenuScene.popup.elements[i] ~= nil) then
			mainMenuScene.popup.elements[i]:removeSelf();
			mainMenuScene.popup.elements[i] = nil;
		end
	end
	mainMenuScene.popup.elements = {};
	
	if (mainMenuScene.popup.teamStepper ~= nil) then
		mainMenuScene.popup.teamStepper:removeSelf()
		mainMenuScene.popup.teamStepper = nil;
	end
	
	if (mainMenuScene.popup.teamDisplay ~= nil) then
		mainMenuScene.popup.teamDisplay:removeSelf()
		mainMenuScene.popup.teamDisplay = nil;
	end
	
	mainMenuScene.popup.teamCounter = 1;
	
	--Enable all main menu buttons
	mainMenuScene.button1:setEnabled(true);
	mainMenuScene.button2:setEnabled(true);
	mainMenuScene.button3:setEnabled(true);
	mainMenuScene.button4:setEnabled(true);

end


--Starting new game - Generate teams, players etc
function scene:newGame(teamid, roster)
	
	local path = system.pathForFile("data.db", system.DocumentsDirectory)
	local path2 = system.pathForFile("previousPlayerStats.db", system.DocumentsDirectory)
	local path3 = system.pathForFile("retiredPlayers.db", system.DocumentsDirectory)
	local fhd = io.open( path )
	
	if (db and db:isopen()) then
		db:close()
	end
	
	if (fhd) then
		--File already exists, must delete it to start a new game
		io.close(fhd)
		local results, reason = os.remove(path);
		os.remove(path2);
		os.remove(path3);
		
		if results then
		print( "file removed" )
		else
		print( "file does not exist", reason )
		end
	end
	
	--Create data (main game data) database
	db = sqlite3.open( path )
	
	--Generate the myteam, the team that the player chose to play for and any custom lineups
	db:exec[[CREATE TABLE myteam (teamid INTEGER, customLineup TEXT, goals TEXT);]]
	db:exec([[INSERT INTO myteam VALUES (]] .. teamid .. [[, null, null);]]);

	
	--Generate league, which includes the schedule and the day#
	db:exec[[CREATE TABLE league (year TEXT, schedule TEXT, day INTEGER, mode TEXT, playoffs_info TEXT, playoffs_schedule TEXT, recent_signings TEXT, history TEXT);]]
	local sched = json.encode(sg:generateSchedule2());

	local stmt= db:prepare[[ INSERT INTO league (year, schedule, day, mode) VALUES( 2015, ?, ?, "Season")]];
	stmt:bind_values( sched, 1) 
	stmt:step();

	 --This table stores all the games played in a season
	db:exec[[CREATE TABLE games (id INTEGER UNIQUE ON CONFLICT REPLACE, team1_id INTEGER, team2_id INTEGER, info TEXT);]]
	 --This table stores all awards in history of the league
	db:exec[[CREATE TABLE awards (id INTEGER PRIMARY KEY, year INTEGER, type TEXT, award TEXT, playerid INTEGER, teamid INTEGER);]]
	 --This table stores all players generated in preparation for the draft
	db:exec[[CREATE TABLE draft_players (id INTEGER PRIMARY KEY, posType TEXT, name TEXT, hand TEXT, age INTEGER, 
	contact INTEGER, power INTEGER, eye INTEGER, velocity INTEGER, nastiness INTEGER, control INTEGER, 
	stamina INTEGER, speed INTEGER, defense INTEGER, durability INTEGER, iq INTEGER, overall INTEGER, potential INTEGER, 
	evalOverall TEXT, evalPotential TEXT, draftProjection TEXT,
	teamid INTEGER, draftPos INTEGER, player_id INTEGER);]]
	 --This table stores information needed for the draft
	db:exec[[CREATE TABLE draft (draft_selections TEXT, money_spent TEXT, scout_eval TEXT, big_boards TEXT);]]
	db:exec([[INSERT INTO draft VALUES (null,null,null,null);]]);
	--This table stores other various settings
	db:exec[[CREATE TABLE settings (autoSign INTEGER);]]
	db:exec([[INSERT INTO settings VALUES (1);]]);
	db:close();
	
	--Create previous stats database (offset sluggish simulation)
	db = sqlite3.open( path2 )
	db:exec[[CREATE TABLE history (id INTEGER PRIMARY KEY, previous_stats TEXT);]]
	db:close();
	
	--Create retired players database (offset sluggish simulation)
	db = sqlite3.open( path3 )
	db:exec[[CREATE TABLE players (id INTEGER PRIMARY KEY,
		posType TEXT, name TEXT, age INTEGER, awards TEXT, draft_position TEXT);]]
	db:close();
	
	if (roster == "MLB 2015") then
		--Import custom roster
		pg:customRosters("2015Rosters.db");
	else
		--Generate random roster
		pg:generatePlayers();
	end
end



utils:log("gameScene", "Beginning execution");

-- Add scene lifecycle event handlers.
scene:addEventListener("createScene", scene);
scene:addEventListener("willEnterScene", scene);
scene:addEventListener("enterScene", scene);
scene:addEventListener("exitScene", scene);
scene:addEventListener("didExitScene", scene);
scene:addEventListener("destroyScene", scene);

return scene;