-- Create a scene object to tie functions to.
local scene = storyboard.newScene();
local widget = require("widget");
local json = require("json");
local lg = require("simulatorCore.lineupGenerator");
local gs = require("simulatorCore.gameSimulator");
local ss = require("simulatorCore.seasonSimulator");
local sqlite3 = require "sqlite3"
local at = require("simulatorCore.attendance");
local pd = require("simulatorCore.playerDevelopment");
local tv = require("simulatorCore.tv");
local tr = require("simulatorCore.trade");
local pg = require("simulatorCore.playerGenerator")
local ads = require( "ads" )
local pMsg = require("menuCore.pushMessage")

local menuScene = {
	
	isTutorial = false,
	menu_button,
	menuScrollView,
	
	scrollView, --This is the scroll view that contains the content in each of the modes
	mode = "Statistics",
	
	tutorial = {--Contains all the variables needed when going through a tutorial
		step = 1,
		elements = {},
		messages = {},
	},
	
	message = {
		elements = {}
	},
	
	statistics = { --Contains all the variables when showing player statistics
		stats = {},
		labels = {},
		leftArrow,
		rightArrow,
		top,
		bottom,
		
		
		limit = 5, --5 elements can be viewed at a time in the statistics table
		offset = 0,
		count = 0, --Total number of elements in the table, given the limiting SQL parameters
		
		sort = "name",
		sortOrder = "ASC",
		
		teamStepper, --Limit results to desired team
		teamDisplay, --Display team from stepper
		teamCounter = 1,
		teams = {},
		
		positionStepper, --Limit results to desired position
		positionDisplay,
		positionCounter = 1,
		positions = {"ALL", "BATTERS", "1B", "2B", "SS", "3B", "OF", "C", "PITCHERS", "SP", "RP"},
		
		modeStepper, --Show either stats or ratings
		modeDisplay,
		modeCounter = 1, --1 = RATINGS, 2 = STATISTICS BATTING, 3 = STATISTICS PITCHING
		modes = {"RATINGS", "STATS BATTING", "STATS PITCHING"}
	},
	
	extraFilter = {
		bg,
		exit,
		scrollView,
		switches = {},
		info = {"nil", "nil", "nil", "nil"}, --Contains info about extra filters
		elements = {},
	},
	
	teams = { --Contains all variables when showing team table
		stats = {},
		labels = {},
		sort = "name",
		sortOrder = "ASC";
	},
	
	teamCard = { --Contains all variables when showing team card
		elements = {},
	},
	
	playerPopup = {--Contains all variables when showing player card popup
		bg, --Background
		exit, --Exit button
		menuButtons = {},
		scrollView,
		elements = {} --Loop through this table for easy removal of player card elements
	
	},
	
	trade = {--Contains all variables when showing trade menu
		elements = {},
		
		scrollView1, --Players on team 1
		scrollView2, --Players on team 2
		
		teamStepper, --Limit results to desired team
		teamDisplay, --Display team from stepper
		teamCounter = 1,
		teams = {}
	
	},

	confirmTradePopup = {--Contains all variables when confirm trade card popup
		elements = {},
		scrollView,
		scrollView2
	},

	popup = {--Contains all variables of a generic message popup
		elements = {},
		scrollView
	},
	
	lineupPopup = { --Contains all variable of popup that displays the lineup
		elements = {},
		bg,
		scrollView,
		exit,
	},
	
	boxscorePopup = { --Contains all variable of popup that displays the boxscore
		elements = {},
		bg,
		scrollView,
		exit,
	},
	
	editLineupPopup = { --Contains all variable of popup that allows lineup editing
		elements = {},
		positionLabels = {}, --Label indicating each position required
		positionNames = {}, --Names of the players selected for each position
		positionSelected = 1, --Index that references which position label is selected
		battingOrderDisplays = {},
		
		availablePlayersElements = {},
		bg,
		scrollView,
		scrollView2,
		exit,
	
	},
	
	freeAgents = {
		elements = {}, --Other elements in free agents tab
		stats = {},
		labels = {},
		leftArrow,
		rightArrow,
		top,
		bottom,
		
		limit = 5, --5 elements can be viewed at a time in the statistics table
		offset = 0,
		count = 0, --Total number of elements in the table, given the limiting SQL parameters
		
		sort = "name",
		sortOrder = "ASC",

		positionStepper, --Limit results to desired position
		positionDisplay,
		positionCounter = 1,
		positions = {"ALL", "BATTERS", "1B", "2B", "SS", "3B", "OF", "C", "PITCHERS", "SP", "RP"},
	
	},
	
	negotiationPopup = {
		
		orig_num_years = 0,
		orig_num_salary = 0,
		cur_num_years = 0,
		cur_num_salary = 0,
		offer_num_years = 0,
		offer_num_salary = 0,
		mood = 0,
		bg, --Background
		exit, --Exit button
		scrollView,
		elements = {} --Loop through this table for easy removal of player card elements

	},
	
	prospectPopup = { 
		bg, --Background
		exit, --Exit button
		scrollView,
		elements = {} --Loop through this table for easy removal of player card elements
	
	},
	
	draftOrderPopup = { 
		bg, --Background
		exit, --Exit button
		scrollView,
		elements = {} --Loop through this table for easy removal of player card elements
	
	},
	
	teamHistoryPopup = {
		elements = {},
		bg,
		scrollview,
		exit,
	},
	
	teamOffersPopup = { --Contains all variables of popup that shows a team's offers to free agents
		elements = {},
		bg,
		scrollview,
		exit,
	},
	
	faOffersPopup = { --Contains all variables of popup that shows what offers free agent has
		elements = {},
		bg,
		scrollview,
		exit,
	},
	
	league = {
		elements = {}
	},
	
	leagueHistoryPopup = {
		elements = {},
		bg,
		scrollview,
		exit,
	},
	
	finance = {
		elements = {},
		teamStepper,
		teamStepperCounter = 1,
	},
	
	simulation = {
		elements = {},
		num_days = 1, --Number of days to simulate
		progress_elements = {}, --List of all elements used when showing simulation progress popup
		progress_indicator, --Indicates progress of simulation
		progress_info, --Underneath progress indicator, contains more info like (win loss record, current round in playoffs)
		draftSort2 = [[CASE draftProjection
			WHEN "Top 5" THEN 0
			WHEN "Top 10" THEN 1
			WHEN "Round 1" THEN 2
			WHEN "Round 2" THEN 3
			WHEN "Round 3" THEN 4
			WHEN "Undrafted" THEN 5
		END]], --What prospects are sorted by day 2
		draftSort3 = [[CASE draftProjection
			WHEN "Top 5" THEN 0
			WHEN "Top 10" THEN 1
			WHEN "Round 1" THEN 2
			WHEN "Round 2" THEN 3
			WHEN "Round 3" THEN 4
			WHEN "Undrafted" THEN 5
		END]], --What prospects are sorted by day 3
		draftSort4 = [[draftPos]], --What prospects are sorted by day 4
		draftSortOrder2 = "ASC",
		draftSortOrder3 = "ASC", 
		draftSortOrder4 = "ASC", 
	},

	adInfo = {
		-- The name of the ad provider.
		provider = "admob",
		-- Your application ID
		appID = "ca-app-pub-2195505829394880/3390416657",
		appIDInterstitial = "ca-app-pub-2195505829394880/3043836253",
	},

}

-- ============================================================================
-- Called when the scene's view does not exist.
-- ============================================================================
function scene:createScene(inEvent)
	
	--[[if (inEvent.params ~= null) then
	if (inEvent.params.isTutorial) then
		menuScene.isTutorial = true
		scene:initializeTutorial()
		print("This game has entered tutorial mode");
	end
	end]]--
	
	utils:log("gameScene", "createScene()");
	--Load background
	local bg = display.newImage("Images/Grass.png", 0 , 0);
	bg.anchorX, bg.anchorY = 0, 0;
	self.view:insert(bg);
	
	--Load general scroll view
	menuScene.scrollView = widget.newScrollView {
		backgroundColor = { 0, 1, 0, 0 },
		x = 0,
		y = 0,
		width = display.contentWidth,
		height = display.contentHeight,
		horizontalScrollDisabled = false,
		verticalScrollDisabled = false
	  }
	self.view:insert(menuScene.scrollView);
	menuScene.scrollView.anchorX, menuScene.scrollView.anchorY = 0,0;
	
	--Ghost element (need this so that scroll view doesn't accidentally cut content off)
	local topLabel = display.newText("", 0, 0, native.systemFont, 36);
	menuScene.scrollView:insert(topLabel);
	
	
	--Load sidebar menu
	local options = {
		width = 250,
		height = 80,
		numFrames = 18,
		sheetContentWidth = 500,
		sheetContentHeight = 720
	}
	local buttonSheet = graphics.newImageSheet( "Images/menu_sheet.png", options )

	menuScene.menuScrollView = widget.newScrollView {
		backgroundColor = { 0, 1, .2, .2 },
		x = -250,
		y = 0,
		width = 250,
		height = display.contentHeight,
		horizontalScrollDisabled = true,
		verticalScrollDisabled = false
	  }
	menuScene.menuScrollView.anchorX, menuScene.menuScrollView.anchorY = 0,0;
	
	local function tap(event) 
		return true; --Block tap events from passing scroll view and triggering labels
	end
	menuScene.menuScrollView:addEventListener("tap", tap);
	
	
	--Add buttons to side menu
	local function handleButtonEvent( event )
		local button = event.target.id;
		local phase = event.phase

		if ( phase == "moved" ) then
			local dy = math.abs( ( event.y - event.yStart ) )
			-- If the touch on the button has moved more than 10 pixels,
			-- pass focus back to the scroll view so it can continue scrolling
			if ( dy > 10 ) then
				menuScene.menuScrollView:takeFocus( event )
			end
		elseif (phase == "ended") then
			audio.play( globalSounds["tap"] )

			if (button == "exit") then
				storyboard.gotoScene("mainMenuScene", "fade", 500);
				scene:changeMode(""); --Empty parameter just destroys current page, thus freeing up memory
			elseif (button == "statistics") then
				scene:changeMode("Statistics");
			elseif (button == "teams") then
				scene:changeMode("Teams");
			elseif (button == "trade") then
				scene:changeMode("Trade");
			elseif (button == "simulate") then
				scene:changeMode("Simulation");
			elseif (button == "my team") then
				local myteamid;
				local path = system.pathForFile("data.db", system.DocumentsDirectory)
				db = sqlite3.open( path )   
				for row in db:nrows([[SELECT * FROM myteam]]) do
					myteamid = row.teamid
				end
				db:close();
				
				scene:changeMode("Team Card", myteamid);
			elseif (button == "free agents") then
				scene:changeMode("Free Agents");
			elseif (button == "league") then
				scene:changeMode("League");
			elseif (button == "finances") then
				local myteamid;
				local path = system.pathForFile("data.db", system.DocumentsDirectory)
				db = sqlite3.open( path )   
				for row in db:nrows([[SELECT * FROM myteam]]) do
					myteamid = row.teamid
				end
				db:close();
				
				scene:changeMode("Finances",myteamid);
			elseif (button == "save") then
				--Do testing here
			end
					
			--Auto close menu
			transition.to(menuScene.menu_button, {time = 1000, transition = easing.inOutQuad, x = 0});
			transition.to(menuScene.menuScrollView, {time = 1000, transition = easing.inOutQuad, x = -250});
		
		end
		return true
	end
	
	local buttonNames = {"simulate", "statistics", "teams",  "my team", "league", "trade", "free agents", "finances", "exit"}
	for i = 1, #buttonNames do
		local button = widget.newButton
		{
			id = buttonNames[i],
			sheet = buttonSheet,
			defaultFrame = (i*2)-1,
			overFrame = (i*2),
			onEvent = handleButtonEvent
		}
		button.anchorX, button.anchorY = 0,0;
		button.x = 0;
		button.y = 90 * (i - 1);
		menuScene.menuScrollView:insert(button);
	end
	self.view:insert(menuScene.menuScrollView);
	
	--Menu button
	local function menuButtonEvent( event )
		if ( "ended" == event.phase ) then
			if (menuScene.menu_button.x == 0) then
				transition.to(menuScene.menu_button, {time = 1000, transition = easing.inOutQuad, x = 250});
				transition.to(menuScene.menuScrollView, {time = 1000, transition = easing.inOutQuad, x = 0});
			else
				transition.to(menuScene.menu_button, {time = 1000, transition = easing.inOutQuad, x = 0});
				transition.to(menuScene.menuScrollView, {time = 1000, transition = easing.inOutQuad, x = -250});
			end
		end
	end
	menuScene.menu_button = widget.newButton
	{
		x = 0,
		y = 0,
		id = "menu",
		defaultFile = "Images/menu_button.png",
		onEvent = menuButtonEvent;
		
	}


	menuScene.menu_button.anchorX, menuScene.menu_button.anchorY = 0,0;
	self.view:insert(menuScene.menu_button);
	
	local myTeamid = 0
	local path = system.pathForFile("data.db", system.DocumentsDirectory)
	db = sqlite3.open( path )   
	
	for row in db:nrows([[SELECT * FROM myteam;]]) do 
		myTeamid = row.teamid;
	end
	db:close()
	
	 --Start on my team page
	scene:changeMode("Team Card", myTeamid);
	
	--Show Interstitial Ad (Full Screen) @ beginning of menu scene
	--[[local function adListener( event )
		-- The 'event' table includes:
		-- event.name: string value of "adsRequest"
		-- event.response: message from the ad provider about the status of this request
		-- event.phase: string value of "loaded", "shown", or "refresh"
		-- event.type: string value of "banner" or "interstitial"
		-- event.isError: boolean true or false

		local msg = event.response
		-- Quick debug message regarding the response from the library
		print( "Message from the ads library: ", msg )

		if ( event.isError ) then
			print( "Error, no ad received", msg )
			--scene:showPopup("Error, no ad received", 24)
		else
			print( "Ah ha! Got one!" )
			--scene:showPopup("Ah ha! Got one!" , 24)
		end
	end
	ads.init( menuScene.adInfo.provider, menuScene.adInfo.appIDInterstitial, adListener )
	ads.show( "interstitial", {appId=menuScene.adInfo.appIDInterstitial} )]]--
	
	
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

  storyboard.removeScene("menuScene")
  utils:log("gameScene", "didExitScene()");

end -- End didExitScene().


-- ============================================================================
-- Called prior to the removal of scene's "view" (display group).
-- ============================================================================
function scene:destroyScene(inEvent)

  utils:log("gameScene", "destroyScene()");

end -- End destroyScene().


--Player card popup (Covers the current mode)
function scene:showPlayerCardPopup(id)
	
	--Semi-transparent black background that covers whole screen and blocks touches
	local black = display.newImage("Images/black.png", 0, 0);
	black.width, black.height = display.contentWidth, display.contentHeight
	black.anchorX, black.anchorY = 0,0
	black.alpha = .9;
	
	
	local function blockTouches(event)
		return true; --Block the propagation of any touches or taps
	end
	black:addEventListener("tap", blockTouches);
	black:addEventListener("touch", blockTouches);
	menuScene.playerPopup.bg  = black;
	
	local function destroy(event)
		if (event.phase == "ended") then scene:destroyPlayerCardPopup(); end
	end
	--Exit button
	menuScene.playerPopup.exit = widget.newButton
	{
		x = display.contentWidth,
		y = display.contentHeight,
		defaultFile = "Images/x.png",
		onEvent = destroy
	}
	menuScene.playerPopup.exit.anchorX, menuScene.playerPopup.exit.anchorY = 1, 1; 

	
	--Rig popup scroll view - covers entire screen
	menuScene.playerPopup.scrollView = widget.newScrollView {
		backgroundColor = { 0, 1, .3, 0 },
		x = display.contentCenterX,
		y = 0,
		width = display.contentWidth,
		height = display.contentHeight-menuScene.playerPopup.exit.height, --Prevent exit button from obscuring content
		horizontalScrollDisabled = false,
		verticalScrollDisabled = false
	}
	menuScene.playerPopup.scrollView.anchorY = 0

	
	--Get player information from the database
	local league_info
	local team_info = {}
	local info;
	local prevStats_info;
	
	local path = system.pathForFile("data.db", system.DocumentsDirectory)
	db = sqlite3.open( path )   
	local path2 = system.pathForFile("previousPlayerStats.db", system.DocumentsDirectory)
	local prevStats_db = sqlite3.open( path2 );
	
	for row in db:nrows([[SELECT * FROM players WHERE id = ]] .. id .. [[;]]) do 
		info = row; --So we can call stuff like info.name, info.number
	end
	for row in prevStats_db:nrows([[SELECT * FROM history WHERE id = ]] .. id .. [[;]]) do 
		prevStats_info = row;
	end
	for row in db:nrows([[SELECT * FROM league;]]) do 
		league_info = row; --So we can call stuff like info.name, info.number
	end
	
	info.teamName = "Free Agent" --If player doesn't have a team, he is labeled as a free agent
	for row in db:nrows([[SELECT * FROM teams WHERE id = ]] .. info.teamid .. [[;]])do
		info.teamName = row.name;
	end
	for row in db:nrows([[SELECT * FROM teams;]])do
		team_info[#team_info+1] = row;
	end
	team_info[31] = {abv = "FA"}
	
	prevStats_db:close();
	db:close();
	
	
	local mode = "profile"
	local function refresh()
	
	--Clear player card first
	for i = 1, #menuScene.playerPopup.elements do
		if (menuScene.playerPopup.elements[i] ~= nil) then
			menuScene.playerPopup.elements[i]:removeSelf();
			menuScene.playerPopup.elements[i] = nil;
		end
	end
	menuScene.playerPopup.elements = {};
	
	--Ghost element
	local topLabel = display.newText("", 0, 0, native.systemFont, 36);
	menuScene.playerPopup.elements[#menuScene.playerPopup.elements+1] = topLabel;
	
	--Display player card
	local yPos = 10
	if (mode == "profile") then
		yPos = 10
		local nameLabel = display.newText( info.name .. " - " .. info.posType, 20, 10, native.systemFont, 30 )
		nameLabel.anchorX, nameLabel.anchorY = 0,0;
		menuScene.playerPopup.elements[#menuScene.playerPopup.elements+1] = nameLabel;
		
		local overallLabel = display.newText( "Ovr: " .. info.overall .. "   Pot: " .. info.potential, display.contentWidth - 10, 10, native.systemFont, 30 )
		overallLabel.anchorX, overallLabel.anchorY = 1,0;
		menuScene.playerPopup.elements[#menuScene.playerPopup.elements+1] = overallLabel;

		local ageLabel =  display.newText( "Age: " .. info.age .. "  Hand: " .. info.hand
				, 20, 75, native.systemFont, 24 )
		ageLabel.anchorX, ageLabel.anchorY = 0,0;
		menuScene.playerPopup.elements[#menuScene.playerPopup.elements+1] = ageLabel;
		
		local teamLabel =  display.newText( "Team: " .. info.teamName
				, 20, ageLabel.y + ageLabel.height + 25, native.systemFont, 24 )
		teamLabel.anchorX, teamLabel.anchorY = 0,0;
		menuScene.playerPopup.elements[#menuScene.playerPopup.elements+1] = teamLabel;
		
		if (info.teamName == "Free Agent") then
			--Show negotiation next to team name so user can sign player
			local function f()
				scene:showNegotiationPopup(info.id)
			end
			
			local nLabel =  display.newText( "[Negotiate]"
				, teamLabel.x + teamLabel.width + 10, teamLabel.y, native.systemFont, 24 )
			nLabel.anchorX, nLabel.anchorY = 0,0;
			nLabel:setFillColor(.6,.6,.6)
			nLabel:addEventListener("tap", f);
			menuScene.playerPopup.elements[#menuScene.playerPopup.elements+1] = nLabel;
		end
		
		local draftLabel =  display.newText( "Drafted: " .. info.draft_position
				, 20, teamLabel.y + teamLabel.height + 25, native.systemFont, 24 )
		draftLabel.anchorX, draftLabel.anchorY = 0,0;
		menuScene.playerPopup.elements[#menuScene.playerPopup.elements+1] = draftLabel;
		
		local contractLabel =  display.newText( "Contract: " .. info.years .. " yr / " ..  "$" .. scene:comma_value(info.salary)
				, 20, draftLabel.y + draftLabel.height + 25, native.systemFont, 24 )
		contractLabel.anchorX, contractLabel.anchorY = 0,0;
		menuScene.playerPopup.elements[#menuScene.playerPopup.elements+1] = contractLabel;
		
		local restLabel;
		if (info.posType == "SP" or info.posType == "RP") then --Show number of days rest (Need @ least 5 to start)
		
			restLabel =  display.newText( tostring(info.days_rest .. " days rest"), 20,contractLabel.y + contractLabel.height + 30,native.systemFont, 24 )
			restLabel.anchorX, restLabel.anchorY = 0,0;
			menuScene.playerPopup.elements[#menuScene.playerPopup.elements+1] = restLabel;
		
		end
		
		--If player is injured, show the injury label (picture & days left)
		
		
		if (info.injury > 0) then
		local yPos = contractLabel.y + contractLabel.height + 30
		if (restLabel ~= nil) then
			yPos = restLabel.y + restLabel.height + 30
		end
		local medic = display.newImage("Images/injury.png", 20 , yPos);
		medic.anchorX, medic.anchorY = 0,0.5;
		menuScene.playerPopup.elements[#menuScene.playerPopup.elements+1] = medic;
		
		local daysLabel =  display.newText(info.injury .. " days", medic.x + medic.width + 15, yPos, native.systemFont, 24 )
		daysLabel.anchorX, daysLabel.anchorY = 0,0;
		menuScene.playerPopup.elements[#menuScene.playerPopup.elements+1] = daysLabel;
		
		medic.y = daysLabel.y + daysLabel.height / 2;
		end
		
		--Attributes pentagon (background)
		local pentagon = display.newGroup()
		local pentagonCenter = {x = 590, y = 240}
		pentagon.x, pentagon.y = pentagonCenter.x, pentagonCenter.y
		pentagon.anchorChildren = true
		local pentagonRadius = 200; --Max length from center to vertice
		local minX, minY = pentagonCenter.x, pentagonCenter.y

			
		local overlay = display.newImage("Images/diamond2.png", pentagonCenter.x, pentagonCenter.y-200);
		overlay.anchorX, overlay.anchorY = .5,.0;
		pentagon:insert(overlay)	
			
		local polygonPoints = {} 
		if (info.posType == "SP" or info.posType == "RP") then --Show pitcher attributes overlay

			local tempInfo = {} --Any changes from 0 to 1 will not be kept
			
			--If any of the attributes equals 0, the polygon cannot be generated.
			--Therefore increase any attribute that is 0 to 1
			for k,v in pairs(info) do
				if (k == "velocity" or k == "nastiness" or k == "control" or k == "stamina" or k == "defense") then
					if (info[k] == 0) then tempInfo[k] = 1 
					else tempInfo[k] = info[k] end
				end
			end
			
			local values = {tempInfo.nastiness, tempInfo.velocity, tempInfo.control, tempInfo.defense,tempInfo.stamina}
			minX, minY = pentagonCenter.x, pentagonCenter.y
			for i = 1, 5 do
				--Populate polygon with points
				local theta = 18 + 72 * (i-1)
				local newX = pentagonCenter.x + values[i] * (pentagonRadius/100) * math.cos(math.rad(theta))
				local newY = pentagonCenter.y - values[i] * (pentagonRadius/100) * math.sin(math.rad(theta))
				polygonPoints[#polygonPoints+1] = newX
				polygonPoints[#polygonPoints+1] = newY
				
				if (newX < minX) then minX = newX end
				if (newY < minY) then minY = newY end
				
			end

			local shape = display.newPolygon(minX, minY, polygonPoints)
			shape.anchorX, shape.anchorY = 0,0
			shape.alpha = .8
			shape:setFillColor(1,1,0);
			
			local gradient = {
				type="gradient",
				color1={ 1, 0, 0 }, color2={ 0.8, 0.8, 0.8 }, direction="down"
			}
			shape:setFillColor(gradient);
			--menuScene.playerPopup.elements[#menuScene.playerPopup.elements+1] = shape;
			pentagon:insert(shape)
			
			local overlay = display.newImage("Images/diamond_pitcher_overlay.png", pentagonCenter.x, pentagonCenter.y-200);
			overlay.anchorX, overlay.anchorY = .5,0;
			--menuScene.playerPopup.elements[#menuScene.playerPopup.elements+1] = overlay;
			pentagon:insert(overlay)
			
		else --Show batter overlay
			
			local tempInfo = {} --Any changes from 0 to 1 will not be kept
			
			--If any of the attributes equals 0, the polygon cannot be generated.
			--Therefore increase any attribute that is 0 to 1
			for k,v in pairs(info) do
				if (k == "power" or k == "contact" or k == "speed" or k == "eye" or k == "defense") then
					if (info[k] == 0) then tempInfo[k] = 1 
					else tempInfo[k] = info[k] end
				end
			end
			
			local values = {tempInfo.contact, tempInfo.power, tempInfo.eye, tempInfo.defense, tempInfo.speed }
			minX, minY = pentagonCenter.x, pentagonCenter.y
			for i = 1, 5 do
				--Populate polygon with points
				local theta = 18 + 72 * (i-1)
				local newX = pentagonCenter.x + values[i] * (pentagonRadius/100) * math.cos(math.rad(theta))
				local newY = pentagonCenter.y - values[i] * (pentagonRadius/100) * math.sin(math.rad(theta))
				polygonPoints[#polygonPoints+1] = newX
				polygonPoints[#polygonPoints+1] = newY
				
				if (newX < minX) then minX = newX end
				if (newY < minY) then minY = newY end
				
			end

			local shape = display.newPolygon(minX, minY, polygonPoints)
			shape.anchorX, shape.anchorY = 0,0
			shape.alpha = .8
			shape:setFillColor(1,1,0);
			
			local gradient = {
				type="gradient",
				color1={ 1, 0, 0 }, color2={ 0.8, 0.8, 0.8 }, direction="down"
			}
			shape:setFillColor(gradient);
			--menuScene.playerPopup.elements[#menuScene.playerPopup.elements+1] = shape;
			pentagon:insert(shape)
			
			local overlay = display.newImage("Images/diamond_batter_overlay.png", pentagonCenter.x, pentagonCenter.y-200);
			overlay.anchorX, overlay.anchorY = .5,0;
			--menuScene.playerPopup.elements[#menuScene.playerPopup.elements+1] = overlay;
			pentagon:insert(overlay)
		end
		menuScene.playerPopup.elements[#menuScene.playerPopup.elements+1] = pentagon
		
		local mark = display.newImage("Images/mark.png", pentagonCenter.x, pentagonCenter.y);
		mark.anchorX, mark.anchorY = .5,.5;
		pentagon:insert(mark)
		
		
		
		--Portrait Profile (Back Side)
		local teamLogo
		if (info.teamid <= 30) then
			teamLogo = display.newImage("rosters/teams/" .. team_info[info.teamid].name .. ".png" 
				, -80, -50);
			if (teamLogo == nil) then
				teamLogo = display.newImage("rosters/teams/GENERIC.png", -80, -50);
			end
			teamLogo.xScale, teamLogo.yScale = .5, .5
			teamLogo.alpha = .5
		end
		
		local portrait = display.newImage("rosters/portraits/" .. info.portrait , 0, 0);
		if (portrait == nil) then --Use generic portrait instead
			portrait = display.newImage("rosters/portraits/A.Generic.png" , 0, 0);
		end
		portrait.xScale, portrait.alpha = 1, 1;
		
		local mask = graphics.newMask( "Images/portrait_mask.png" )
		portrait:setMask(mask)
		
		local profile = display.newGroup()
		profile.anchorChildren = true
		profile.x, profile.y = pentagonCenter.x, pentagonCenter.y
		profile.alpha = 0
		if (teamLogo ~= nil) then	profile:insert(teamLogo) end
		profile:insert(portrait)
		menuScene.playerPopup.elements[#menuScene.playerPopup.elements+1] = profile
		
		local animTime = 500
		local isAnimating = false
		local function revealPentagon()
			transition.to(pentagon, {time = animTime/2, xScale = 1, alpha = 1, onComplete = nil})
		end
		local function rotatePortrait()
			if (not isAnimating) then
				isAnimating = true
				local function finish()
					isAnimating = false
					profile.xScale = .0001
				end
				local function halfway()
					transition.to( profile, { time=animTime/2, xScale = -1, alpha = 0, onComplete = finish } )
					revealPentagon()
				end
				
				transition.to( profile, { time=animTime/2, xScale = .0001, alpha = .5, onComplete = halfway } )
			end
		end
		local function revealPortrait()
			transition.to(profile, {time = animTime/2, xScale = 1, alpha = 1, onComplete = nil})
		end
		local function rotatePentagon()
			if (not isAnimating) then
				isAnimating = true
				local function finish()
					isAnimating = false
					pentagon.xScale = .0001
				end
				local function halfway()
					transition.to( pentagon, { time=animTime/2, xScale = -1, alpha = 0, onComplete = finish } )
					revealPortrait()
				end
				
				transition.to( pentagon, { time=animTime/2, xScale = .0001, alpha = .5, onComplete = halfway } )
			end
		end

		pentagon:addEventListener("tap", rotatePentagon)
		profile:addEventListener("tap", rotatePortrait)
		
		profile.alpha = 1 --Show profile first
		pentagon.alpha = 0 --Don't show pentagon initially
	elseif (mode == "rating") then	
		yPos = 10
		local nameLabel = display.newText( info.name .. " - " .. info.posType, 20, yPos, native.systemFont, 30 )
		nameLabel.anchorX, nameLabel.anchorY = 0,0;
		menuScene.playerPopup.elements[#menuScene.playerPopup.elements+1] = nameLabel;
		
		local overallLabel = display.newText( "Ovr: " .. info.overall .. "   Pot: " .. info.potential, display.contentWidth - 10, yPos, native.systemFont, 30 )
		overallLabel.anchorX, overallLabel.anchorY = 1,0;
		menuScene.playerPopup.elements[#menuScene.playerPopup.elements+1] = overallLabel;
		
		yPos = yPos + 75
		--Show comprehensive ratings relevant to player's posType
		local labels, labelsInfo, labelsX
		if (info.posType == "RP" or info.posType == "SP") then
			labels = {"Vel", "Nst", "Ctl", "Stm", "Def", "IQ", "Dur"}
			labelsInfo = {info.velocity, info.nastiness, info.control, info.stamina, info.defense, info.iq, info.durability}
			labelsX = {30,120,210,300,390,480,570}
		else
			labels = {"Con", "Pow", "Eye", "Spe", "Def", "IQ", "Dur"}
			labelsInfo = {info.contact, info.power, info.eye, info.speed, info.defense, info.iq, info.durability}
			labelsX = {30,120,210,300,390,480,570}
		end
		
		for i =1, #labels do
			local num = #menuScene.playerPopup.elements+1;
			local num2 = num + 1;
			menuScene.playerPopup.elements[num] =  display.newText(labels[i], labelsX[i], yPos, native.systemFont, 24 )
			menuScene.playerPopup.elements[num].anchorX,  menuScene.playerPopup.elements[num].anchorY = 0, 0;
			menuScene.playerPopup.elements[num2] =  display.newText(labelsInfo[i], labelsX[i], yPos + 50, native.systemFont, 24 )
			menuScene.playerPopup.elements[num2].anchorX,  menuScene.playerPopup.elements[num2].anchorY = 0, 0;
		end
		
		--Previous Ratings
		if (prevStats_info.previous_stats ~= nil) then
		
			local previous_stats = json.decode(prevStats_info.previous_stats);
			--Show previous ratings if any
			if (#previous_stats.ratings > 0) then
			
			yPos = yPos + 140;
			local rsLabel =  display.newText( "Previous Ratings", 30, yPos, native.systemFont, 24 )
			rsLabel.anchorX, rsLabel.anchorY = 0,0;
			menuScene.playerPopup.elements[#menuScene.playerPopup.elements+1] = rsLabel;
			
			for i = 1, #previous_stats.ratings do
				local season = previous_stats.ratings[i]
				
				yPos = yPos + 50

				local teamAbv = "FA"
				if (season.teamid <= 30) then teamAbv = team_info[season.teamid].abv end
				
				
				if (info.posType == "SP" or info.posType == "RP") then
				labels = {"", "TM", "Ovr", "Pot", "Vel", "Nst", "Ctl", "Stm", "Def"}
				labelsInfo = {season.year, teamAbv , season.overall, season.potential,
					season.velocity, season.nastiness, season.control, season.stamina, season.defense, }
				else
				labels = {"", "TM", "Ovr", "Pot", "Con", "Pow", "Eye", "Spe", "Def"}
				labelsInfo = {season.year, teamAbv , season.overall, season.potential,
					season.contact, season.power, season.eye,  season.speed, season.defense,}
				end
				labelsX = {30,105,180,245,320,395,470,545,620}--,715,790,865,940}
				
				--Labels
				if (i ==1) then
					for i =1, #labels do
						local num = #menuScene.playerPopup.elements+1;
						menuScene.playerPopup.elements[num] =  display.newText(labels[i], labelsX[i], yPos, native.systemFont, 24 )
						menuScene.playerPopup.elements[num].anchorX,  menuScene.playerPopup.elements[num].anchorY = 0, 0;
					end
				end
				
				--Ratings
				for i =1, #labels do
					local num = #menuScene.playerPopup.elements+1;
					menuScene.playerPopup.elements[num] =  display.newText(labelsInfo[i], labelsX[i], yPos + 50, native.systemFont, 24 )
					menuScene.playerPopup.elements[num].anchorX,  menuScene.playerPopup.elements[num].anchorY = 0, 0;
				end
				
				


			end
			
			end
			
		end
		
	elseif (mode == "stats") then
		yPos = 10
		local nameLabel = display.newText( info.name .. " - " .. info.posType, 20, yPos, native.systemFont, 30 )
		nameLabel.anchorX, nameLabel.anchorY = 0,0;
		menuScene.playerPopup.elements[#menuScene.playerPopup.elements+1] = nameLabel;
		
		local overallLabel = display.newText( "Ovr: " .. info.overall .. "   Pot: " .. info.potential, display.contentWidth - 10, yPos, native.systemFont, 30 )
		overallLabel.anchorX, overallLabel.anchorY = 1,0;
		menuScene.playerPopup.elements[#menuScene.playerPopup.elements+1] = overallLabel;
		
		--Current Stats
		if (league_info.mode == "Season" or league_info.mode == "Playoffs" 
			or league_info.mode == "Season Awards" or league_info.mode == "Playoffs Awards") then
		yPos = yPos + 75;
		local mode = league_info.mode
		if (mode == "Season Awards") then mode = "Season" end
		if (mode == "Playoffs Awards") then mode = "Playoffs" end
		local str = league_info.year .. " " .. mode
		local yrLabel =  display.newText( str, 30, yPos, native.systemFont, 24 )
		yrLabel.anchorX, yrLabel.anchorY = 0,0;
		menuScene.playerPopup.elements[#menuScene.playerPopup.elements+1] = yrLabel;
		
		yPos = yPos + 50
		if (info.posType == "SP" or info.posType == "RP") then 
			--Show pitcher stats
			labels = {"GP", "GS", "IP", "H", "ER", "HR", "BB", "SO", "W", "L", "SV","DRS", "ERA", "WHIP"}
			labelsInfo = {info.P_GP, info.P_GS, info.P_IP, info.P_H, info.P_ER,info.P_HR,info.P_BB,info.P_SO, info.P_W
				,info.P_L, info.P_SV, info.DRS, info.P_ERA, info.P_WHIP}
			labelsX = {30,95,170,245,320,395,470,545,620,695,770,845,920,995,1095}
			for i =1, #labels do
				local num = #menuScene.playerPopup.elements+1;
				local num2 = num + 1;
				menuScene.playerPopup.elements[num] =  display.newText(labels[i], labelsX[i], yPos, native.systemFont, 24 )
				menuScene.playerPopup.elements[num].anchorX,  menuScene.playerPopup.elements[num].anchorY = 0, 0;
				menuScene.playerPopup.elements[num2] =  display.newText(labelsInfo[i], labelsX[i], yPos + 50, native.systemFont, 24 )
				menuScene.playerPopup.elements[num2].anchorX,  menuScene.playerPopup.elements[num2].anchorY = 0, 0;
			end
			
		
		else
			--Show batter stats
			labels = {"GP", "AB", "R", "H", "2B", "3B", "HR", "RBI", "BB","SO", "SB","CS","DRS", "AVG", "OBP", "SLG"}
			labelsInfo = {info.GP, info.AB, info.R, info.H, info.DOUBLES,  info.TRIPLES, info.HR, info.RBI, info.BB, info.SO,
				info.SB, info.CS, info.DRS, info.AVG, info.OBP, info.SLG}
			labelsX = {30,95,170,245,320,395,470,545,620,695,770,845,920,995,1095,1195}
			for i =1, #labels do
				local num = #menuScene.playerPopup.elements+1;
				local num2 = num + 1;
				menuScene.playerPopup.elements[num] =  display.newText(labels[i], labelsX[i], yPos, native.systemFont, 24 )
				menuScene.playerPopup.elements[num].anchorX,  menuScene.playerPopup.elements[num].anchorY = 0, 0;
				menuScene.playerPopup.elements[num2] =  display.newText(labelsInfo[i], labelsX[i], yPos + 50, native.systemFont, 24 )
				menuScene.playerPopup.elements[num2].anchorX,  menuScene.playerPopup.elements[num2].anchorY = 0, 0;
			end
			

		end
		yPos = yPos + 150;
		end
		
		--Previous Stats (Total Stats)
		if (prevStats_info.previous_stats ~= nil) then
		
		local previous_stats = json.decode(prevStats_info.previous_stats);
		
		--Include current stats into stats total
		if (league_info.mode == "Season" or league_info.mode == "Season Awards") then
			--Include current season stats in total stats
			info.year = league_info.year
			previous_stats.season[#previous_stats.season+1] = info
		elseif (league_info.mode == "Playoffs" or league_info.mode == "Playoffs Awards") then
			--Include current playoffs stats in total stats
			info.year = league_info.year
			previous_stats.playoffs[#previous_stats.playoffs+1] = info
		end
		
		--Show season stats if any
		if (#previous_stats.season > 0) then
		
		local str = "Regular Season Statistics"
		local rsLabel =  display.newText( str, 30, yPos, native.systemFont, 24 )
		rsLabel.anchorX, rsLabel.anchorY = 0,0;
		menuScene.playerPopup.elements[#menuScene.playerPopup.elements+1] = rsLabel;
		local totalPitcher = {"TOT", "", 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
		local totalBatter = {"TOT", "", 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
		
		for i = 1, #previous_stats.season do
			local season = previous_stats.season[i]
			
			yPos = yPos + 50
		if (info.posType == "SP" or info.posType == "RP") then 
			--Show pitcher stats
			labels = {"", "TM", "GP", "GS", "IP", "H", "ER", "HR", "BB", "SO", "W", "L", "SV", "DRS", "ERA", "WHIP"}
			labelsInfo = {season.year, team_info[season.teamid].abv, season.P_GP, season.P_GS, season.P_IP, season.P_H, season.P_ER,season.P_HR,season.P_BB,season.P_SO, season.P_W
				,season.P_L, season.P_SV, season.DRS, season.P_ERA, season.P_WHIP}
			labelsX = {30,105,180,245,320,395,470,545,620,695,770,845,920,995,1070,1145,1245}
			
			--Add stats to total (career) count
			for n = 3, #totalPitcher do
				if (n == 5) then --Adding innings is different
					totalPitcher[n] = gs:addInnings(totalPitcher[n], labelsInfo[n]);
				else
					totalPitcher[n] = totalPitcher[n] + labelsInfo[n]
				end
			end
			totalPitcher[15] = gs:calculateEra({P_IP = totalPitcher[5], P_ER = totalPitcher[7]}); --Career era
			totalPitcher[16] = gs:calculateWhip({P_IP = totalPitcher[5], P_H = totalPitcher[6], P_BB = totalPitcher[9]}); --Career whip
			
			
			--Labels
			if (i ==1) then
				for i =1, #labels do
					local num = #menuScene.playerPopup.elements+1;
					menuScene.playerPopup.elements[num] =  display.newText(labels[i], labelsX[i], yPos, native.systemFont, 24 )
					menuScene.playerPopup.elements[num].anchorX,  menuScene.playerPopup.elements[num].anchorY = 0, 0;
				end
			end
			
			--Stats
			for i =1, #labels do
				local num = #menuScene.playerPopup.elements+1;
				menuScene.playerPopup.elements[num] =  display.newText(labelsInfo[i], labelsX[i], yPos + 50, native.systemFont, 24 )
				menuScene.playerPopup.elements[num].anchorX,  menuScene.playerPopup.elements[num].anchorY = 0, 0;
			end
			
		
		else
			--Show batter stats
			labels = {"", "TM", "GP", "AB", "R", "H", "2B", "3B", "HR", "RBI", "BB","SO", "SB","CS","DRS", "AVG", "OBP", "SLG"}
			labelsInfo = {season.year, team_info[season.teamid].abv, season.GP, season.AB, season.R, season.H, season.DOUBLES,  season.TRIPLES, season.HR, season.RBI, season.BB, season.SO,
				season.SB, season.CS, season.DRS, season.AVG, season.OBP, season.SLG}
			labelsX = {30,105,180,245,320,395,470,545,620,695,770,845,920,995,1070,1145,1245,1345}
			
			--Add stats to total (career) count
			for n = 3, #totalBatter do
				totalBatter[n] = totalBatter[n] + labelsInfo[n]
			end
			totalBatter[16] = gs:calculateAvg({H = totalBatter[6], AB = totalBatter[4]}); --Career avg
			totalBatter[17] = gs:calculateObp({H = totalBatter[6], AB = totalBatter[4], BB = totalBatter[11]}); --Career obp
			totalBatter[18] = gs:calculateSlg({H = totalBatter[6], AB = totalBatter[4], DOUBLES = totalBatter[7], TRIPLES = totalBatter[8], HR = totalBatter[9]}); --Career slg
			
			--Labels
			if (i ==1) then
				for i =1, #labels do
					local num = #menuScene.playerPopup.elements+1;
					menuScene.playerPopup.elements[num] =  display.newText(labels[i], labelsX[i], yPos, native.systemFont, 24 )
					menuScene.playerPopup.elements[num].anchorX,  menuScene.playerPopup.elements[num].anchorY = 0, 0;
				end
			end
			
			--Stats
			for i =1, #labels do
				local num = #menuScene.playerPopup.elements+1;
				menuScene.playerPopup.elements[num] =  display.newText(labelsInfo[i], labelsX[i], yPos + 50, native.systemFont, 24 )
				menuScene.playerPopup.elements[num].anchorX,  menuScene.playerPopup.elements[num].anchorY = 0, 0;
			end
			

		end
			
		end
		
		--Show total career reg season stats
		yPos = yPos + 50
		menuScene.league.elements[#menuScene.league.elements+1] = line
		if (info.posType == "SP" or info.posType == "RP") then 
			labelsX = {30,105,180,245,320,395,470,545,620,695,770,845,920,995,1070,1145,1245}
			
			--Stats
			for i =1, #labels do
				local num = #menuScene.playerPopup.elements+1;
				menuScene.playerPopup.elements[num] =  display.newText(totalPitcher[i], labelsX[i], yPos + 50, native.systemFont, 24 )
				menuScene.playerPopup.elements[num].anchorX,  menuScene.playerPopup.elements[num].anchorY = 0, 0;
			end
			
		else
			labelsX = {30,105,180,245,320,395,470,545,620,695,770,845,920,995,1070,1145,1245,1345}
			--Stats
			for i =1, #labels do
				local num = #menuScene.playerPopup.elements+1;
				menuScene.playerPopup.elements[num] =  display.newText(totalBatter[i], labelsX[i], yPos + 50, native.systemFont, 24 )
				menuScene.playerPopup.elements[num].anchorX,  menuScene.playerPopup.elements[num].anchorY = 0, 0;
			end
		end
		
		end
		
		--Show playoffs stats if any
		if (#previous_stats.playoffs > 0) then
		yPos = yPos + 150;
		local str = "Playoffs Statistics"
		local rsLabel =  display.newText( str, 50, yPos, native.systemFont, 24 )
		rsLabel.anchorX, rsLabel.anchorY = 0,0;
		menuScene.playerPopup.elements[#menuScene.playerPopup.elements+1] = rsLabel;
		local totalPitcher = {"TOT", "", 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
		local totalBatter = {"TOT", "", 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
		
		for i = 1, #previous_stats.playoffs do
			local season = previous_stats.playoffs[i]
			
			yPos = yPos + 50
			if (info.posType == "SP" or info.posType == "RP") then 
			--Show pitcher stats
			labels = {"", "TM", "GP", "GS", "IP", "H", "ER", "HR", "BB", "SO", "W", "L", "SV", "DRS", "ERA", "WHIP"}
			labelsInfo = {season.year, team_info[season.teamid].abv, season.P_GP, season.P_GS, season.P_IP, season.P_H, season.P_ER,season.P_HR,season.P_BB,season.P_SO, season.P_W
				,season.P_L, season.P_SV, season.DRS, season.P_ERA, season.P_WHIP}
			labelsX = {30,105,180,245,320,395,470,545,620,695,770,845,920,995,1070,1145,1245}
			
			--Add stats to total (career) count
			for n = 3, #totalPitcher do
				if (n == 5) then --Adding innings is different
					totalPitcher[n] = gs:addInnings(totalPitcher[n], labelsInfo[n]);
				else
					totalPitcher[n] = totalPitcher[n] + labelsInfo[n]
				end
			end
			totalPitcher[15] = gs:calculateEra({P_IP = totalPitcher[5], P_ER = totalPitcher[7]}); --Career era
			totalPitcher[16] = gs:calculateWhip({P_IP = totalPitcher[5], P_H = totalPitcher[6], P_BB = totalPitcher[9]}); --Career whip
			
			
			--Labels
			if (i ==1) then
				for i =1, #labels do
					local num = #menuScene.playerPopup.elements+1;
					menuScene.playerPopup.elements[num] =  display.newText(labels[i], labelsX[i], yPos, native.systemFont, 24 )
					menuScene.playerPopup.elements[num].anchorX,  menuScene.playerPopup.elements[num].anchorY = 0, 0;
				end
			end
			
			--Stats
			for i =1, #labels do
				local num = #menuScene.playerPopup.elements+1;
				menuScene.playerPopup.elements[num] =  display.newText(labelsInfo[i], labelsX[i], yPos + 50, native.systemFont, 24 )
				menuScene.playerPopup.elements[num].anchorX,  menuScene.playerPopup.elements[num].anchorY = 0, 0;
			end
			
			
		
			else
			--Show batter stats
			labels = {"", "TM", "GP", "AB", "R", "H", "2B", "3B", "HR", "RBI", "BB","SO", "SB","CS","DRS", "AVG", "OBP", "SLG"}
			labelsInfo = {season.year, team_info[season.teamid].abv, season.GP, season.AB, season.R, season.H, season.DOUBLES,  season.TRIPLES, season.HR, season.RBI, season.BB, season.SO,
				season.SB, season.CS, season.DRS, season.AVG, season.OBP, season.SLG}
			labelsX = {30,105,180,245,320,395,470,545,620,695,770,845,920,995,1070,1145,1245,1345}
			
			--Add stats to total (career) count
			for n = 3, #totalBatter do
				totalBatter[n] = totalBatter[n] + labelsInfo[n]
			end
			totalBatter[16] = gs:calculateAvg({H = totalBatter[6], AB = totalBatter[4]}); --Career avg
			totalBatter[17] = gs:calculateObp({H = totalBatter[6], AB = totalBatter[4], BB = totalBatter[11]}); --Career obp
			totalBatter[18] = gs:calculateSlg({H = totalBatter[6], AB = totalBatter[4], DOUBLES = totalBatter[7], TRIPLES = totalBatter[8], HR = totalBatter[9]}); --Career slg
			
			
			--Labels
			if (i ==1) then
				for i =1, #labels do
					local num = #menuScene.playerPopup.elements+1;
					menuScene.playerPopup.elements[num] =  display.newText(labels[i], labelsX[i], yPos, native.systemFont, 24 )
					menuScene.playerPopup.elements[num].anchorX,  menuScene.playerPopup.elements[num].anchorY = 0, 0;
				end
			end
			
			--Stats
			for i =1, #labels do
				local num = #menuScene.playerPopup.elements+1;
				menuScene.playerPopup.elements[num] =  display.newText(labelsInfo[i], labelsX[i], yPos + 50, native.systemFont, 24 )
				menuScene.playerPopup.elements[num].anchorX,  menuScene.playerPopup.elements[num].anchorY = 0, 0;
			end
			
			

		end
		
		end
		

		--Show total career playoffs stats
		yPos = yPos + 50
		menuScene.league.elements[#menuScene.league.elements+1] = line
		if (info.posType == "SP" or info.posType == "RP") then 
			labelsX = {30,105,180,245,320,395,470,545,620,695,770,845,920,995,1070,1145,1245}
			
			--Stats
			for i =1, #labels do
				local num = #menuScene.playerPopup.elements+1;
				menuScene.playerPopup.elements[num] =  display.newText(totalPitcher[i], labelsX[i], yPos + 50, native.systemFont, 24 )
				menuScene.playerPopup.elements[num].anchorX,  menuScene.playerPopup.elements[num].anchorY = 0, 0;
			end
			
		else
			labelsX = {30,105,180,245,320,395,470,545,620,695,770,845,920,995,1070,1145,1245,1345}
			--Stats
			for i =1, #labels do
				local num = #menuScene.playerPopup.elements+1;
				menuScene.playerPopup.elements[num] =  display.newText(totalBatter[i], labelsX[i], yPos + 50, native.systemFont, 24 )
				menuScene.playerPopup.elements[num].anchorX,  menuScene.playerPopup.elements[num].anchorY = 0, 0;
			end
		end
		
		end
		
		end
		
	elseif (mode == "recent") then
		yPos = 10
		local nameLabel = display.newText( info.name .. " - " .. info.posType, 20, yPos, native.systemFont, 30 )
		nameLabel.anchorX, nameLabel.anchorY = 0,0;
		menuScene.playerPopup.elements[#menuScene.playerPopup.elements+1] = nameLabel;
		
		local overallLabel = display.newText( "Ovr: " .. info.overall .. "   Pot: " .. info.potential, display.contentWidth - 10, yPos, native.systemFont, 30 )
		overallLabel.anchorX, overallLabel.anchorY = 1,0;
		menuScene.playerPopup.elements[#menuScene.playerPopup.elements+1] = overallLabel;
		
		yPos = yPos + 75
		local rsLabel =  display.newText( "This feature will be added later.", 30, yPos, native.systemFont, 24 )
		rsLabel.anchorX, rsLabel.anchorY = 0,0;
		menuScene.playerPopup.elements[#menuScene.playerPopup.elements+1] = rsLabel;
	elseif (mode == "miscellaneous") then
		yPos = 10
		local nameLabel = display.newText( info.name .. " - " .. info.posType, 20, yPos, native.systemFont, 30 )
		nameLabel.anchorX, nameLabel.anchorY = 0,0;
		menuScene.playerPopup.elements[#menuScene.playerPopup.elements+1] = nameLabel;
		
		local overallLabel = display.newText( "Ovr: " .. info.overall .. "   Pot: " .. info.potential, display.contentWidth - 10, yPos, native.systemFont, 30 )
		overallLabel.anchorX, overallLabel.anchorY = 1,0;
		menuScene.playerPopup.elements[#menuScene.playerPopup.elements+1] = overallLabel;
		--Awards
		if (info.awards ~= nil) then
		
			local awards = json.decode(info.awards);
			
			yPos = yPos + 75;
			local str = "Awards"
			local rsLabel =  display.newText( str, 30, yPos, native.systemFont, 24 )
			rsLabel.anchorX, rsLabel.anchorY = 0,0;
			menuScene.playerPopup.elements[#menuScene.playerPopup.elements+1] = rsLabel;
			
			--Example, Sort by awards
			--["MVP"] = {2014, 2020, 2021}
			--["All Star"] = {2020}
			local awardsList = {};
			for i = 1, #awards do
				local award = awards[i]
				
				if (awardsList[award.award] == nil) then
					awardsList[award.award] = {}
				end
				local aaa = awardsList[award.award]
				aaa[#aaa+1] = award.year;
			end
			
			for k, v in pairs(awardsList) do
				yPos = yPos + 50
				local text = k .. ":  "
				
				for i = 1, #v do
					text = text .. " " .. v[i];
					if (i ~= #v) then text = text .. "," end
				end
				
				local awardLabel =  display.newText(text, 30, yPos, native.systemFont, 24 )
				awardLabel.anchorX,  awardLabel.anchorY = 0, 0;
				menuScene.playerPopup.elements[#menuScene.playerPopup.elements+1] = awardLabel
			end
		
		end
		--Transactions
		if (info.transactions ~= nil) then
			local transactions = json.decode(info.transactions);
			
			yPos = yPos + 75;
			local str = "Transactions"
			local rsLabel =  display.newText( str, 30, yPos, native.systemFont, 24 )
			rsLabel.anchorX, rsLabel.anchorY = 0,0;
			menuScene.playerPopup.elements[#menuScene.playerPopup.elements+1] = rsLabel;

			
			for i = 1, #transactions do
				yPos = yPos + 50
				local transactionLabel =  display.newText(transactions[i], 30, yPos, native.systemFont, 24 )
				transactionLabel.anchorX,  transactionLabel.anchorY = 0, 0;
				menuScene.playerPopup.elements[#menuScene.playerPopup.elements+1] = transactionLabel
			end
		
		end
	end	
	
	--Add all the elements to the scroll view
	for i = 1, #menuScene.playerPopup.elements do
		menuScene.playerPopup.scrollView:insert(menuScene.playerPopup.elements[i]);
	end
	
	--Scroll to top of scroll view
	menuScene.playerPopup.scrollView:scrollTo( "top", { time=0} )	
	
	end
	refresh()
	
	
	--Lineup menu buttons : profile, rating, stats, recent, miscellaneous
	local options = {
		width = 100,
		height = 40,
		numFrames = 10,
		sheetContentWidth = 200,
		sheetContentHeight = 200
	}
	local buttonSheet = graphics.newImageSheet( "Images/player_card.png", options )
	local buttons = {}
	
	local function handleButtonEvent(event)
		if (event.phase == "ended") then
			mode = event.target.id
			refresh()
		end
		return true
	end
	
	for i = 1, 5 do
		local buttonID = ""
		if (i == 1) then buttonID = "profile"
		elseif (i == 2) then buttonID = "rating"
		elseif (i == 3) then buttonID = "stats"
		elseif (i == 4) then buttonID = "recent"
		elseif (i == 5) then buttonID = "miscellaneous"
		end
		local button = widget.newButton
		{
			id = buttonID,
			sheet = buttonSheet,
			defaultFrame = 2*i-1,
			overFrame = 2*i,
			onEvent = handleButtonEvent
		}
		buttons[i] = button
		menuScene.playerPopup.menuButtons[#menuScene.playerPopup.menuButtons+1] = button;
	end
	
	local xPos = 0
	local buttonBuffer = 10 --Space between each button
	for i = 1, #buttons  do
		local button = buttons[i]
		button.anchorX, button.anchorY = 0, 1
		button.x, button.y = xPos+buttonBuffer, display.contentHeight - 5
		xPos = xPos + button.width
	end
	
	
	
	

end

function scene:destroyPlayerCardPopup()

	for i = 1, #menuScene.playerPopup.elements do
		if (menuScene.playerPopup.elements[i] ~= nil) then
			menuScene.playerPopup.elements[i]:removeSelf();
			menuScene.playerPopup.elements[i] = nil;
		end
	end
	menuScene.playerPopup.elements = {};
	
	for i = 1, #menuScene.playerPopup.menuButtons do
		if (menuScene.playerPopup.menuButtons[i] ~= nil) then
			menuScene.playerPopup.menuButtons[i]:removeSelf();
			menuScene.playerPopup.menuButtons[i] = nil;
		end
	end
	menuScene.playerPopup.menuButtons = {};
	
	if (menuScene.playerPopup.bg ~= nil) then
		menuScene.playerPopup.bg:removeSelf();
		menuScene.playerPopup.bg = nil
	end
	
	if (menuScene.playerPopup.exit ~= nil) then
		menuScene.playerPopup.exit:removeSelf();
		menuScene.playerPopup.exit = nil
	end
	
	if (menuScene.playerPopup.scrollView ~= nil) then
		menuScene.playerPopup.scrollView:removeSelf();
		menuScene.playerPopup.scrollView = nil
	end
	
end


--Prospect Card popup
function scene:showProspectCardPopup(id)
	
	--Semi-transparent black background that covers whole screen and blocks touches
	local black = display.newImage("Images/black.png", 0, 0);
	black.width, black.height = display.contentWidth, display.contentHeight
	black.anchorX, black.anchorY = 0,0
	black.alpha = .9;
	
	--Ghost element
	local topLabel = display.newText("", 0, 0, native.systemFont, 36);
	menuScene.prospectPopup.elements[#menuScene.prospectPopup.elements+1] = topLabel;
	
	
	local function blockTouches(event)
		return true; --Block the propagation of any touches or taps
	end
	black:addEventListener("tap", blockTouches);
	black:addEventListener("touch", blockTouches);
	menuScene.prospectPopup.bg  = black;
	

	
	--Rig popup scroll view - covers entire screen
	menuScene.prospectPopup.scrollView = widget.newScrollView {
		backgroundColor = { 0, 1, .3, 0 },
		x = display.contentCenterX,
		y = display.contentCenterY,
		width = display.contentWidth,
		height = display.contentHeight,
		horizontalScrollDisabled = false,
		verticalScrollDisabled = false
	  }

	  
	 local function destroy(event)
		if (event.phase == "ended") then scene:destroyProspectCardPopup(); end
	end
	--Exit button
	menuScene.prospectPopup.exit = widget.newButton
	{
		x = display.contentWidth,
		y = display.contentHeight,
		defaultFile = "Images/x.png",
		onEvent = destroy
	}
	menuScene.prospectPopup.exit.anchorX, menuScene.prospectPopup.exit.anchorY = 1, 1; 
	--menuScene.prospectPopup.scrollView:insert(menuScene.prospectPopup.exit);
	
	--Get prospect information from the database
	local prospect;
	local scout_eval; --Of the prospect

	local path = system.pathForFile("data.db", system.DocumentsDirectory)
	db = sqlite3.open( path )   
	for row in db:nrows([[SELECT * FROM draft_players WHERE id = ]] .. id .. [[;]]) do 
		prospect = row
	end
	for row in db:nrows([[SELECT * FROM draft]]) do 
		scout_eval = json.decode(row.scout_eval)
		scout_eval = scout_eval[id]
	end
	
	db:close();
	
	local yPos = 10
	local nameLabel = display.newText( prospect.name .. " - " .. prospect.posType, 60, yPos, native.systemFont, 30 )
	nameLabel.anchorX, nameLabel.anchorY = 0,0;
	menuScene.prospectPopup.elements[#menuScene.prospectPopup.elements+1] = nameLabel;
	
	
	local labels = {}
	local grades = {}
	
	local restLabel;
	if (prospect.posType == "SP" or prospect.posType == "RP") then
	
		labels = {"Age", "Overall", "Potential", "Nastiness", "Velocity", "Control", "Stamina", "Defense", "Durability",  "IQ"}
		grades = {prospect.age, scout_eval.overall, scout_eval.potential, scout_eval.nastiness,
			scout_eval.velocity, scout_eval.control, scout_eval.stamina, scout_eval.defense, scout_eval.durability, scout_eval.iq}
	else
		labels = {"Age", "Overall", "Potential", "Contact", "Power", "Eye", "Defense", "Speed", "Durability", "IQ"}
		grades = {prospect.age, scout_eval.overall, scout_eval.potential, scout_eval.contact,
			scout_eval.power, scout_eval.eye, scout_eval.defense, scout_eval.speed, scout_eval.durability, scout_eval.iq}
	end

	yPos = yPos+50
	for i = 1, #labels do
		yPos = yPos+75
		local infoLabel = display.newText( labels[i], 60, yPos, native.systemFont, 30 )
		infoLabel.anchorX, infoLabel.anchorY = 0,0;
		menuScene.prospectPopup.elements[#menuScene.prospectPopup.elements+1] = infoLabel;
		
		local gradeLabel = display.newText( grades[i], 300, yPos, native.systemFont, 30 )
		gradeLabel.anchorX, gradeLabel.anchorY = 0,0;
		menuScene.prospectPopup.elements[#menuScene.prospectPopup.elements+1] = gradeLabel;
		
	end

	
	--Add all the elements to a scroll view
	for i = 1, #menuScene.prospectPopup.elements do
		--print("Inserted item " .. i);
		menuScene.prospectPopup.scrollView:insert(menuScene.prospectPopup.elements[i]);
	end
	
	

end

function scene:destroyProspectCardPopup()

	for i = 1, #menuScene.prospectPopup.elements do
		if (menuScene.prospectPopup.elements[i] ~= nil) then
			menuScene.prospectPopup.elements[i]:removeSelf();
			menuScene.prospectPopup.elements[i] = nil;
		end
	end
	menuScene.prospectPopup.elements = {};
	
	if (menuScene.prospectPopup.bg ~= nil) then
		menuScene.prospectPopup.bg:removeSelf();
		menuScene.prospectPopup.bg = nil
	end
	
	if (menuScene.prospectPopup.exit ~= nil) then
		menuScene.prospectPopup.exit:removeSelf();
		menuScene.prospectPopup.exit = nil
	end
	
	if (menuScene.prospectPopup.scrollView ~= nil) then
		menuScene.prospectPopup.scrollView:removeSelf();
		menuScene.prospectPopup.scrollView = nil
	end
	
end


--All methods of the statistics tab
function scene:showPlayerStatsPage()

	
	
	 --Add arrows
	local function left(event)
		if (event.phase == "ended") then
			scene:removePlayerStats();
			menuScene.statistics.offset = menuScene.statistics.offset - menuScene.statistics.limit;
			if (menuScene.statistics.offset < 0) then menuScene.statistics.offset = 0; end
			scene:refreshPlayerStats();
		end
		return true
	end
	local function right(event)
		if (event.phase == "ended") then
		scene:removePlayerStats();
		menuScene.statistics.offset = menuScene.statistics.offset + menuScene.statistics.limit;
		
		local maxOffset = (math.ceil(menuScene.statistics.count / menuScene.statistics.limit)-1) * menuScene.statistics.limit;
		if (menuScene.statistics.offset > maxOffset) then
			menuScene.statistics.offset = maxOffset;
		end
		scene:refreshPlayerStats();
		end
		return true
	
	end
	
	--Left button
	menuScene.statistics.leftArrow = widget.newButton
	{
		x = 650,
		y = 400,
		defaultFile = "Images/left.png",
		onEvent = left
	}
	menuScene.statistics.leftArrow.anchorX, menuScene.statistics.leftArrow.anchorY = 0, 0; 
	self.view:insert(menuScene.statistics.leftArrow);
	
	--Right button
	menuScene.statistics.rightArrow = widget.newButton
	{
		x = 750,
		y = 400,
		defaultFile = "Images/right.png",
		onEvent = right
	}
	menuScene.statistics.rightArrow.anchorX, menuScene.statistics.rightArrow.anchorY = 0, 0; 
	self.view:insert(menuScene.statistics.rightArrow);
	
	--Add top, bottom buttons
	menuScene.statistics.top =  display.newText(  "Top", 500, 425, native.systemFont, 20 )
	menuScene.statistics.top.anchorX,  menuScene.statistics.top.anchorY = 0, .5;
	menuScene.statistics.top:setFillColor(1,1,1,.5); 
	self.view:insert(menuScene.statistics.top);
	function menuScene.statistics.top:tap( event )
		scene:removePlayerStats();
		menuScene.statistics.offset = 0;
		scene:refreshPlayerStats();
		return true
	end 
	menuScene.statistics.top:addEventListener( "tap", menuScene.statistics.top);
	
	menuScene.statistics.bottom =  display.newText(  "Bottom", 570, 425, native.systemFont, 20 )
	menuScene.statistics.bottom.anchorX,  menuScene.statistics.bottom.anchorY = 0, .5;
	menuScene.statistics.bottom:setFillColor(1,1,1,.5); 
	self.view:insert(menuScene.statistics.bottom);
	function menuScene.statistics.bottom:tap( event )
		scene:removePlayerStats();
		
		local maxOffset = (math.ceil(menuScene.statistics.count / menuScene.statistics.limit)-1) * menuScene.statistics.limit;
		menuScene.statistics.offset = maxOffset;
		
		scene:refreshPlayerStats();
		return true
	end 
	menuScene.statistics.bottom:addEventListener( "tap", menuScene.statistics.bottom);
	
	
	--Add team stepper (limit data shown to certain team)
	
	--Populate list that teamStepper rotates through using database info
	menuScene.statistics.teams[1] = "ALL";
	local path = system.pathForFile("data.db", system.DocumentsDirectory)
	db = sqlite3.open( path )   
	for row in db:nrows([[SELECT * FROM teams; ]]) do 
		menuScene.statistics.teams[#menuScene.statistics.teams+1] = row.abv;
	end
	db:close();
	
	
	-- Handle stepper events
	menuScene.statistics.teamDisplay = display.newText( menuScene.statistics.teams[menuScene.statistics.teamCounter], 170, 25, native.systemFont, 20 )
	menuScene.statistics.teamDisplay.anchorX,  menuScene.statistics.teamDisplay.anchorY = 0, .5;
	menuScene.statistics.teamDisplay:setFillColor(1,1,1); 
	menuScene.scrollView:insert(menuScene.statistics.teamDisplay);
	
	local function onStepperPress( event )
	
		menuScene.statistics.teamStepper:setValue(1); --Ignore the built in corona stepper counter, it messes things up
		if ( "increment" == event.phase ) then
			menuScene.statistics.teamCounter = menuScene.statistics.teamCounter + 1
			if (menuScene.statistics.teamCounter > #menuScene.statistics.teams) then --Loop to the start
				menuScene.statistics.teamCounter = 1
			end
		elseif ( "decrement" == event.phase ) then
			menuScene.statistics.teamCounter = menuScene.statistics.teamCounter - 1
			if (menuScene.statistics.teamCounter < 1) then --Loop to the end
				menuScene.statistics.teamCounter = #menuScene.statistics.teams
			end
		end
		--print("Counter: " .. menuScene.statistics.teamCounter);
		menuScene.statistics.teamDisplay.text  = menuScene.statistics.teams[menuScene.statistics.teamCounter];
		menuScene.statistics.offset = 0;
		scene:removePlayerStats();
		scene:refreshPlayerStats();
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
	menuScene.statistics.teamStepper = widget.newStepper
	{
		initialValue = 10,
		x = 65,
		y = 0,
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
	menuScene.statistics.teamStepper.anchorX, menuScene.statistics.teamStepper.anchorY = 0, 0;
	menuScene.scrollView:insert(menuScene.statistics.teamStepper);
	
	
	--Add position stepper (limit data shown to certain position)
	-- Handle stepper events
	menuScene.statistics.positionDisplay = display.newText( menuScene.statistics.positions[menuScene.statistics.positionCounter], 355, 25, native.systemFont, 20 )
	menuScene.statistics.positionDisplay.anchorX,  menuScene.statistics.positionDisplay.anchorY = 0, .5;
	menuScene.statistics.positionDisplay:setFillColor(1,1,1); 
	menuScene.scrollView:insert(menuScene.statistics.positionDisplay);
	
	local function onStepperPress2( event )
	
		menuScene.statistics.positionStepper:setValue(1); --Ignore the built in corona stepper counter, it messes things up
		if ( "increment" == event.phase ) then
			menuScene.statistics.positionCounter = menuScene.statistics.positionCounter + 1
			if (menuScene.statistics.positionCounter > #menuScene.statistics.positions) then --Loop to the start
				menuScene.statistics.positionCounter = 1
			end
		elseif ( "decrement" == event.phase ) then
			menuScene.statistics.positionCounter = menuScene.statistics.positionCounter - 1
			if (menuScene.statistics.positionCounter < 1) then --Loop to the end
				menuScene.statistics.positionCounter = #menuScene.statistics.positions
			end
		end
		--print("Counter: " .. menuScene.statistics.positionCounter);
		menuScene.statistics.positionDisplay.text  = menuScene.statistics.positions[menuScene.statistics.positionCounter];
		menuScene.statistics.offset = 0;
		scene:removePlayerStats();
		scene:refreshPlayerStats();
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
	menuScene.statistics.positionStepper = widget.newStepper
	{
		initialValue = 10,
		x = 250,
		y = 0,
		width = 100,
		height = 50,
		sheet = stepperSheet,
		defaultFrame = 1,
		noMinusFrame = 2,
		noPlusFrame = 3,
		minusActiveFrame = 4,
		plusActiveFrame = 5,
		onPress = onStepperPress2
	}
	menuScene.statistics.positionStepper.anchorX, menuScene.statistics.positionStepper.anchorY = 0, 0;
	menuScene.scrollView:insert(menuScene.statistics.positionStepper);
	
	
	--Add mode stepper (Switch between statistics and ratings
	menuScene.statistics.modeDisplay = display.newText(   menuScene.statistics.modes[menuScene.statistics.modeCounter], 565, 25, native.systemFont, 20 )
	menuScene.statistics.modeDisplay.anchorX,  menuScene.statistics.modeDisplay.anchorY = 0, .5;
	menuScene.statistics.modeDisplay:setFillColor(1,1,1); 
	menuScene.scrollView:insert(menuScene.statistics.modeDisplay);
	
	local function onStepperPress3( event )
	
		menuScene.statistics.modeStepper:setValue(1); --Ignore the built in corona stepper counter, it messes things up
		if ( "increment" == event.phase ) then
			menuScene.statistics.modeCounter = menuScene.statistics.modeCounter + 1
			if (menuScene.statistics.modeCounter > #menuScene.statistics.modes) then --Loop to the start
				menuScene.statistics.modeCounter = 1
			end
		elseif ( "decrement" == event.phase ) then
			menuScene.statistics.modeCounter = menuScene.statistics.modeCounter - 1
			if (menuScene.statistics.modeCounter < 1) then --Loop to the end
				menuScene.statistics.modeCounter = #menuScene.statistics.modes
			end
		end
		--print("Counter: " .. menuScene.statistics.modeCounter);
		menuScene.statistics.modeDisplay.text  = menuScene.statistics.modes[menuScene.statistics.modeCounter];
		scene:updateLabels();
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
	menuScene.statistics.modeStepper = widget.newStepper
	{
		initialValue = 10,
		x = 460,
		y = 0,
		width = 100,
		height = 50,
		sheet = stepperSheet,
		defaultFrame = 1,
		noMinusFrame = 2,
		noPlusFrame = 3,
		minusActiveFrame = 4,
		plusActiveFrame = 5,
		onPress = onStepperPress3
	}
	menuScene.statistics.modeStepper.anchorX, menuScene.statistics.modeStepper.anchorY = 0, 0;
	menuScene.scrollView:insert(menuScene.statistics.modeStepper);
	
	--Add extra filters button (ellipsis)
	local function showExtraFiltersPopup()
		scene:showExtraFilterPopup()
		return true
	end
	
	menuScene.statistics.ellipsis = widget.newButton
	{
		x = display.contentWidth - 8,
		y = 25,
		defaultFile = "Images/ellipsis.png",
		--onEvent = left
	}
	menuScene.statistics.ellipsis.anchorX, menuScene.statistics.ellipsis.anchorY = 1, .5;
	menuScene.statistics.ellipsis:addEventListener("tap", showExtraFiltersPopup);
	menuScene.scrollView:insert(menuScene.statistics.ellipsis);
		
	--Add data to the table
	scene:refreshPlayerStats();
	scene:updateLabels();
	
	
end

function scene:updateLabels()

	--Change labels depending on the mode
	
	--Remove all labels
	for i = 1, #menuScene.statistics.labels do
		if (menuScene.statistics.labels[i] ~= nil) then
			menuScene.statistics.labels[i]:removeSelf();
			menuScene.statistics.labels[i] = nil
		end
	end
	menuScene.statistics.labels={}
	
	--Add labels above the table
	local yPos =  100
	
	--Label touch listeners (When you touch the label, it sorts by the column);
	local function tap( event )
	
		audio.play( globalSounds["tap"] )
		
		if (event.target.text == "Tm") then 
		scene:sortBy([[(SELECT abv	FROM teams WHERE id = players.teamid)]]); --SQLite code that sorts by team name
		elseif (event.target.text == "Pos") then scene:sortBy("posType");
		elseif (event.target.text == "Name") then scene:sortBy("name");
		elseif (event.target.text == "Age") then scene:sortBy("age");
		elseif (event.target.text == "Con") then scene:sortBy("contact");
		elseif (event.target.text == "Pow") then scene:sortBy("power");
		elseif (event.target.text == "Eye") then scene:sortBy("eye");
		elseif (event.target.text == "Vel") then scene:sortBy("velocity");
		elseif (event.target.text == "Nst") then scene:sortBy("nastiness");
		elseif (event.target.text == "Ctl") then scene:sortBy("control");
		elseif (event.target.text == "Stm") then scene:sortBy("stamina");
		elseif (event.target.text == "Spe") then scene:sortBy("speed");
		elseif (event.target.text == "Def") then scene:sortBy("defense");
		elseif (event.target.text == "Dur") then scene:sortBy("durability");
		elseif (event.target.text == "Iq") then scene:sortBy("iq");
		elseif (event.target.text == "Sal") then scene:sortBy("salary");
		elseif (event.target.text == "Yrs") then scene:sortBy("years");
		elseif (event.target.text == "Dft") then 
		
		scene:sortBy(
		[[CAST(SUBSTR(draft_position, 1, 4) AS INT) ]] .. menuScene.statistics.sortOrder .. --Sort by year
		[[, CASE
			WHEN draft_position LIKE '%Round 1%' THEN 1
			WHEN draft_position LIKE '%Round 2%' THEN 2
			WHEN draft_position LIKE '%Round 3%' THEN 3
			WHEN draft_position LIKE '%Undrafted%' THEN 4
		END	]] .. menuScene.statistics.sortOrder .. --Sort by round
		[[, CASE
			WHEN draft_position LIKE '%Undrafted%' THEN 100
			WHEN draft_position LIKE '%Pick%' THEN 
				CAST(
				SUBSTR(draft_position, INSTR(draft_position, 'Pick')+5, 
					LENGTH(draft_position)-(INSTR(draft_position, 'Pick')+5)+1)
					AS INT)
		END	]] --Sort by pick
		
			
		);
		elseif (event.target.text == "Ovr") then scene:sortBy("overall");
		elseif (event.target.text == "Pot") then scene:sortBy("potential");
		
		elseif (event.target.text == "GP" and menuScene.statistics.modeCounter == 2) then scene:sortBy("GP");
		elseif (event.target.text == "AB" and menuScene.statistics.modeCounter == 2) then scene:sortBy("AB");
		elseif (event.target.text == "R" and menuScene.statistics.modeCounter == 2) then scene:sortBy("R");
		elseif (event.target.text == "H" and menuScene.statistics.modeCounter == 2) then scene:sortBy("H");
		elseif (event.target.text == "2B" and menuScene.statistics.modeCounter == 2) then scene:sortBy("DOUBLES");
		elseif (event.target.text == "3B" and menuScene.statistics.modeCounter == 2) then scene:sortBy("TRIPLES");
		elseif (event.target.text == "HR" and menuScene.statistics.modeCounter == 2) then scene:sortBy("HR");
		elseif (event.target.text == "RBI" and menuScene.statistics.modeCounter == 2) then scene:sortBy("RBI");
		elseif (event.target.text == "BB" and menuScene.statistics.modeCounter == 2) then scene:sortBy("BB");
		elseif (event.target.text == "SO" and menuScene.statistics.modeCounter == 2) then scene:sortBy("SO");
		elseif (event.target.text == "SB" and menuScene.statistics.modeCounter == 2) then scene:sortBy("SB");
		elseif (event.target.text == "CS" and menuScene.statistics.modeCounter == 2) then scene:sortBy("CS");
		elseif (event.target.text == "DRS" and menuScene.statistics.modeCounter == 2) then scene:sortBy("DRS");
		elseif (event.target.text == "AVG" and menuScene.statistics.modeCounter == 2) then scene:sortBy("AVG");
		elseif (event.target.text == "OBP" and menuScene.statistics.modeCounter == 2) then scene:sortBy("OBP");
		elseif (event.target.text == "SLG" and menuScene.statistics.modeCounter == 2) then scene:sortBy("SLG");
		
		elseif (event.target.text == "GP" and menuScene.statistics.modeCounter == 3) then scene:sortBy("P_GP");
		elseif (event.target.text == "GS" and menuScene.statistics.modeCounter == 3) then scene:sortBy("P_GS");
		elseif (event.target.text == "IP" and menuScene.statistics.modeCounter == 3) then scene:sortBy("P_IP");
		elseif (event.target.text == "H" and menuScene.statistics.modeCounter == 3) then scene:sortBy("P_H");
		elseif (event.target.text == "ER" and menuScene.statistics.modeCounter == 3) then scene:sortBy("P_ER");
		elseif (event.target.text == "HR" and menuScene.statistics.modeCounter == 3) then scene:sortBy("P_HR");
		elseif (event.target.text == "BB" and menuScene.statistics.modeCounter == 3) then scene:sortBy("P_BB");
		elseif (event.target.text == "SO" and menuScene.statistics.modeCounter == 3) then scene:sortBy("P_SO");
		elseif (event.target.text == "W" and menuScene.statistics.modeCounter == 3) then scene:sortBy("P_W");
		elseif (event.target.text == "L" and menuScene.statistics.modeCounter == 3) then scene:sortBy("P_L");
		elseif (event.target.text == "SV" and menuScene.statistics.modeCounter == 3) then scene:sortBy("P_SV");
		elseif (event.target.text == "DRS" and menuScene.statistics.modeCounter == 3) then scene:sortBy("DRS");
		elseif (event.target.text == "WHIP" and menuScene.statistics.modeCounter == 3) then scene:sortBy("P_WHIP");
		elseif (event.target.text == "ERA" and menuScene.statistics.modeCounter == 3) then scene:sortBy("P_ERA");

		end
		
		--Labels that that the table is not sorted by should be gray
		for i = 1, #menuScene.statistics.labels do
			menuScene.statistics.labels[i]:setFillColor(.8,.8,.8);
		end
		--Mark the selected label by changing the colour to red
		event.target:setFillColor(1,0,0);
		return true
	end 
	
	local labels = {}
	local labelsX = {}
	if (menuScene.statistics.modeCounter == 1) then
		--Show player ratings labels
		labels = {"Tm", "Pos", "Name", "Age", "Ovr", "Pot", "Con", "Pow", "Eye", "Vel", "Nst", "Ctl", "Stm", "Spe", "Def", "Dur", "Iq", "Sal", "Yrs", "Dft"}
		labelsX = {85,150,225,525,600,675,750,825, 900,975,1050,1125,1200,1275,1350,1425,1500,1575,1800,1875}

		--Showing progressions on the first day of the season
		--Adjust labelsX accordingly
		local path = system.pathForFile("data.db", system.DocumentsDirectory)
		db = sqlite3.open( path ) 
		
		for rowLeague in db:nrows([[SELECT * FROM league;]])do
			if (rowLeague.mode == "Season" and rowLeague.day == 1) then
				labelsX = {85,150,225,525,625,725,825,900, 975,1050,1125,1200,1275,1350,1425,1500,1575,1650,1875,1950}
			end
		end
		
		db:close()
		
		
	elseif (menuScene.statistics.modeCounter == 2) then
		--Show batting statistics
		labels = {"Tm", "Pos", "Name", "GP", "AB", "R", "H", "2B", "3B", "HR", "RBI", "BB", "SO", "SB","CS","DRS", "AVG", "OBP", "SLG"}
		labelsX = {85,150,225,525,600,675,750,825, 900,975,1050,1125,1200,1275,1350,1425,1500,1650,1800}
	else
		--Show Pitching Statistics
		labels = {"Tm", "Pos", "Name", "GP", "GS", "IP", "H", "ER", "HR", "BB", "SO", "W","L","SV","DRS", "WHIP", "ERA"}
		labelsX = {85,150,225,525,600,675,750,825, 900,975,1050,1125,1200,1275,1350,1425,1575}
	end
	
	--Render labels
	for i =1, #labels do
		menuScene.statistics.labels[i] =  display.newText(labels[i], labelsX[i], yPos, native.systemFont, 24 )
		menuScene.statistics.labels[i].anchorX,  menuScene.statistics.labels[i].anchorY = 0, 0;
		menuScene.statistics.labels[i]:setFillColor(.8,.8,.8)
		
		if (i == 3) then
			menuScene.statistics.labels[i]:setFillColor(1,0,0);
			menuScene.statistics.sort = "Name"
			scene:sortBy("name");
		end
		
		
		menuScene.scrollView:insert(menuScene.statistics.labels[i]);
		menuScene.statistics.labels[i]:addEventListener( "tap", tap );
	end

	
	
end

function scene:removePlayerStats()

	for i = 1, #menuScene.statistics.stats do
		--Remove all stats from menuScene.scrollView
		if (menuScene.statistics.stats[i] ~= nil) then
			menuScene.statistics.stats[i]:removeSelf();
			menuScene.statistics.stats[i] = nil;
		end
	end
	menuScene.statistics.stats = {};

end

function scene:refreshPlayerStats()

	--Show player data
	local path = system.pathForFile("data.db", system.DocumentsDirectory)
	db = sqlite3.open( path )   

	--Determine number of rows generated from query (count)
	local count = 0;
	
	--Generate WHERE clause for extra filters (created by extra filters popup)
	local filterQuery = [[]]
	for i = 1, #menuScene.extraFilter.info do
		local info = menuScene.extraFilter.info[i]
		if (info ~= "nil") then
			if (i == 1) then
				filterQuery = filterQuery .. [[ AND age >= ]] .. info.min .. [[ AND age <= ]] ..info.max;
			elseif (i == 2) then
				filterQuery = filterQuery .. [[ AND AB >= ]] .. info.min .. [[ AND AB <= ]] ..info.max;
			elseif (i == 3) then
				filterQuery = filterQuery .. [[ AND P_IP >= ]] .. info.min .. [[ AND P_IP <= ]] ..info.max;
			elseif (i == 4) then
				filterQuery = filterQuery .. [[ AND CAST(SUBSTR(draft_position,1,4) AS INTEGER) >= ]] .. info.min .. [[ AND CAST(SUBSTR(draft_position,1,4) AS INTEGER) <= ]] ..info.max;
			end
		end
	end

	--print("Filter Query: " .. filterQuery)
	
	
	--Generate the appropriate query to get the count
	local modifiedQuery;
	if (menuScene.statistics.teamCounter == 1) then --Count players of all teams
		modifiedQuery = [[SELECT Count(*) FROM players WHERE teamid <= 30]]
	else --Specific team
		local team =  [["]] .. menuScene.statistics.teams[menuScene.statistics.teamCounter] .. [["]];
		modifiedQuery = [[SELECT Count(*) FROM players WHERE teamid = (SELECT id FROM teams WHERE abv = ]] .. team .. [[)]]
	end
	modifiedQuery = modifiedQuery .. filterQuery
	if (menuScene.statistics.positionCounter == 1) then --All positions
		--positions = {"ALL", "BATTERS", "1B", "2B", "SS", "3B", "OF", "C", "PITCHERS", "SP", "RP"}
	elseif (menuScene.statistics.positionCounter == 2) then --Limit to Batters
		modifiedQuery = modifiedQuery .. [[ AND (posType = "1B" or posType = "2B" or posType = "SS" or posType = "3B" or posType = "OF" or posType = "C")]]
	elseif (menuScene.statistics.positionCounter == 9) then --Limit to Pitchers
		modifiedQuery = modifiedQuery .. [[ AND (posType = "SP" or posType = "RP")]]
	else --Limit to certain position type
		modifiedQuery = modifiedQuery .. [[ AND posType = "]] .. menuScene.statistics.positions[menuScene.statistics.positionCounter] .. [["]]
	end

	for row in db:rows(modifiedQuery) do  
		count = row[1] 
	end
	menuScene.statistics.count = count;
	
	--print("Modified Query: " .. modifiedQuery);
	--print("Count: " .. count);
	
	
	--Offset can't be greater than number of elements in database table
	if (menuScene.statistics.offset >= count) then
		menuScene.statistics.offset = count-menuScene.statistics.limit;
	end
	print("Offset: " .. menuScene.statistics.offset);
	
	
	--Fill in the rows with pertinent database information
	--Start at row offset + 1, limit = #elements
	local n = 0;
	local query;
	
	--Determine Actual Query
	if (menuScene.statistics.teamCounter == 1) then --Count players of all teams
		query = [[SELECT * FROM players WHERE teamid <= 30]]
	else --Specific team
		local team =  [["]] .. menuScene.statistics.teams[menuScene.statistics.teamCounter] .. [["]];
		query = [[SELECT * FROM players WHERE teamid = (SELECT id FROM teams WHERE abv = ]] .. team .. [[)]]
	end
	query = query .. filterQuery
	if (menuScene.statistics.positionCounter == 1) then --All positions
		--positions = {"ALL", "BATTERS", "1B", "2B", "SS", "3B", "OF", "C", "PITCHERS", "SP", "RP"}
	elseif (menuScene.statistics.positionCounter == 2) then --Limit to Batters
		query = query .. [[ AND (posType = "1B" or posType = "2B" or posType = "SS" or posType = "3B" or posType = "OF" or posType = "C")]]
	elseif (menuScene.statistics.positionCounter == 9) then --Limit to Pitchers
		query = query .. [[ AND (posType = "SP" or posType = "RP")]]
	else --Limit to certain position type
		query = query .. [[ AND posType = "]] .. menuScene.statistics.positions[menuScene.statistics.positionCounter] .. [["]]
	end
	query = query .. [[ ORDER BY ]] .. menuScene.statistics.sort .. [[ ]] .. menuScene.statistics.sortOrder ..
			[[ LIMIT ]] .. menuScene.statistics.limit .. [[ OFFSET ]] .. menuScene.statistics.offset .. [[;]]
	print("ACTUAL QUERY: " .. query);
	
	
	--Actual query, populate data table
	for row in db:nrows(query) do

	
	n = n+1;
	local teamName = "empty"
	for row in db:nrows([[SELECT * FROM teams WHERE id = ]] .. row.teamid .. [[;]])do
		teamName = row.abv;
	end
	
	--Generate the text used to display stats
	local labels
	local labelsX
	--Special property to depict overall change and potential change
	local labelsColor = {{1,1,1},{1,1,1}}
	
	if (menuScene.statistics.modeCounter == 1) then
		--Show player ratings labels
		local overall, potential = row.overall, row.potential
		labelsX = {10,85,150,225,525,600,675,750,825, 900,975,1050,1125,1200,1275,1350,1425,1500,1575,1800,1875}
		
		--Show progressions on the first day of the season
		for rowLeague in db:nrows([[SELECT * FROM league;]])do
			
			if (rowLeague.mode == "Season" and rowLeague.day == 1) then
				labelsX = {10,85,150,225,525,625,725,825,900, 975,1050,1125,1200,1275,1350,1425,1500,1575,1650,1875,1950}
				if (row.overallChange ~= 0) then
					if (row.overallChange > 0) then
						overall = overall .. " (+" .. row.overallChange .. ")"
						labelsColor[1] = {0,1,.2}
					else
						overall = overall .. " (" .. row.overallChange .. ")"
						labelsColor[1] = {1,.1,.1}
					end
				end
				
				if (row.potentialChange ~= 0) then
					if (row.potentialChange > 0) then
						potential = potential .. " (+" .. row.potentialChange .. ")"
						labelsColor[2] = {0,1,.2}
					else
						potential = potential .. " ("  .. row.potentialChange .. ")"
						labelsColor[2] = {1,.1,.1}
					end
				end
				
			end

		end
		
		labels = {menuScene.statistics.offset+n, teamName, row.posType, row.name, row.age, overall, potential,
			row.contact, row.power, row.eye, row.velocity, row.nastiness, row.control, row.stamina, row.speed,
			row.defense, row.durability,
			row.iq, "$" .. scene:comma_value(row.salary), row.years, row.draft_position}
		
		
	elseif (menuScene.statistics.modeCounter == 2) then
		--Show batting statistics
		labels = {menuScene.statistics.offset+n, teamName, row.posType, row.name,
			row.GP, row.AB, row.R, row.H, row.DOUBLES, row.TRIPLES, row.HR, row.RBI,
			row.BB, row.SO, row.SB, row.CS, row.DRS, row.AVG, row.OBP, row.SLG}
		labelsX = {10, 85,150,225,525,600,675,750,825, 900,975,1050,1125,1200,1275,1350,1425,1500,1650,1800}
	else
		labels = {menuScene.statistics.offset+n, teamName, row.posType, row.name,
			row.P_GP, row.P_GS, row.P_IP, row.P_H, row.P_ER, row.P_HR, row.P_BB, row.P_SO, row.P_W, row.P_L, row.P_SV,
			row.DRS, row.P_WHIP, row.P_ERA}
		labelsX = {10,85,150,225,525,600,675,750,825, 900,975,1050,1125,1200,1275,1350,1425,1575}
	end

	
	local function tap( event )
		scene:showPlayerCardPopup(row.id);
		return true;
	end 
	
	for i = 1, #labels do
		local num = #menuScene.statistics.stats+1 ;
		print("labels[i]: " .. tostring(labels[i]) .. "   labelsX[i]: " .. tostring(labelsX[i]))
		menuScene.statistics.stats[num] =  display.newText( labels[i], labelsX[i], (n+2) * 50, native.systemFont, 24 )
		menuScene.statistics.stats[num].anchorX, menuScene.statistics.stats[num].anchorY = 0, 0;
		--menuScene.statistics.stats[num]:setFillColor(1,1,1); 
		menuScene.scrollView:insert(menuScene.statistics.stats[num])
		
		--Clickable name
		if (i == 4) then
			--When the name of the player is touched, display his player card
			menuScene.statistics.stats[num]:addEventListener( "tap", tap );
			menuScene.statistics.stats[num]:setFillColor(.8,.8,.8)
			
			--If player is injured, show the injury picture beside his name
			if (row.injury > 0) then
				local playerLabel = menuScene.statistics.stats[num];
				local num = #menuScene.statistics.stats+1 ;
				menuScene.statistics.stats[num] =  display.newImage("Images/injury.png", playerLabel.x + playerLabel.width + 10, playerLabel.y + playerLabel.height/2)
				menuScene.statistics.stats[num].anchorX, menuScene.statistics.stats[num].anchorY = 0, .5;
				menuScene.statistics.stats[num].width, menuScene.statistics.stats[num].height = playerLabel.height, playerLabel.height
				menuScene.scrollView:insert(menuScene.statistics.stats[num])
			end
		end
		
		--Color code overall & potential change
		if (menuScene.statistics.modeCounter == 1 and (i == 6 or i == 7)) then
			if (i == 6) then
				local color = labelsColor[1]
				menuScene.statistics.stats[num]:setFillColor(color[1], color[2], color[3])
			elseif (i == 7) then
				local color = labelsColor[2]
				menuScene.statistics.stats[num]:setFillColor(color[1], color[2], color[3])
			end
		end
	end
	
	
	
	end
	
	db:close();

end

function scene:sortBy(sort) 
	
	
	menuScene.statistics.offset = 0;
	
	if (sort == menuScene.statistics.sort) then
		--Reverse order of the sort
		if (menuScene.statistics.sortOrder == "ASC") then
			menuScene.statistics.sortOrder = "DESC"
		else
			menuScene.statistics.sortOrder = "ASC"
		end
	end
	
	--Replace any ASC or DESC in the sort with the current sortOrder (to fix sort by 'DFT' bug)
	sort = string.gsub(sort, "ASC", menuScene.statistics.sortOrder)
	sort = string.gsub(sort, "DESC", menuScene.statistics.sortOrder)
	
	menuScene.statistics.sort = sort;
	
	
	
	scene:removePlayerStats();
	scene:refreshPlayerStats();
end

function scene:comma_value(n) -- credit http://richard.warburton.it
	local left,num,right = string.match(n,'^([^%d]*%d)(%d*)(.-)$')
	return left..(num:reverse():gsub('(%d%d%d)','%1,'):reverse())..right
end

function scene:destroyPlayerStatsPage()
	
	menuScene.statistics.sort = "name";

	for i = 1, #menuScene.statistics.stats do
		if(menuScene.statistics.stats[i] ~= nil) then
			menuScene.statistics.stats[i]:removeSelf();
			menuScene.statistics.stats[i] = nil
		end
	end
	menuScene.statistics.stats = {}
	
	for i = 1, #menuScene.statistics.labels do
		if(menuScene.statistics.labels[i] ~= nil) then
			menuScene.statistics.labels[i]:removeSelf();
			menuScene.statistics.labels[i] = nil
		end
	end
	menuScene.statistics.labels = {}
	
	if(menuScene.statistics.ellipsis ~= nil) then
		menuScene.statistics.ellipsis:removeSelf();
		menuScene.statistics.ellipsis = nil
	end
	
	if(menuScene.statistics.leftArrow ~= nil) then
		menuScene.statistics.leftArrow:removeSelf();
		menuScene.statistics.leftArrow = nil
	end
	
	if(menuScene.statistics.rightArrow ~= nil) then
		menuScene.statistics.rightArrow:removeSelf();
		menuScene.statistics.rightArrow = nil
	end
	
	if(menuScene.statistics.top ~= nil) then
		menuScene.statistics.top:removeSelf();
		menuScene.statistics.top = nil
	end
	
	if(menuScene.statistics.bottom ~= nil) then
		menuScene.statistics.bottom:removeSelf();
		menuScene.statistics.bottom = nil
	end
	
	if(menuScene.statistics.teamStepper ~= nil) then
		menuScene.statistics.teamStepper:removeSelf();
		menuScene.statistics.teamStepper = nil
	end
	
	if(menuScene.statistics.teamDisplay ~= nil) then
		menuScene.statistics.teamDisplay:removeSelf();
		menuScene.statistics.teamDisplay = nil
	end
	menuScene.statistics.teams = {}
	
	if(menuScene.statistics.positionStepper ~= nil) then
		menuScene.statistics.positionStepper:removeSelf();
		menuScene.statistics.positionStepper = nil
	end
	
	if(menuScene.statistics.positionDisplay ~= nil) then
		menuScene.statistics.positionDisplay:removeSelf();
		menuScene.statistics.positionDisplay = nil
	end
	
	if(menuScene.statistics.modeStepper ~= nil) then
		menuScene.statistics.modeStepper:removeSelf();
		menuScene.statistics.modeStepper = nil
	end
	
	if(menuScene.statistics.modeDisplay ~= nil) then
		menuScene.statistics.modeDisplay:removeSelf();
		menuScene.statistics.modeDisplay = nil
	end

end


--Extra filters popup
function scene:showExtraFilterPopup()
	
	--Semi-transparent black background that covers whole screen and blocks touches
	local black = display.newImage("Images/black.png", 0, 0);
	black.width, black.height = display.contentWidth, display.contentHeight
	black.anchorX, black.anchorY = 0,0
	black.alpha = .9;
	
	--Ghost element
	local topLabel = display.newText("", 0, 0, native.systemFont, 36);
	menuScene.extraFilter.elements[#menuScene.extraFilter.elements+1] = topLabel;
	
	
	local function blockTouches(event)
		return true; --Block the propagation of any touches or taps
	end
	black:addEventListener("tap", blockTouches);
	black:addEventListener("touch", blockTouches);
	menuScene.extraFilter.bg  = black;
	

	
	--Rig popup scroll view - covers entire screen
	menuScene.extraFilter.scrollView = widget.newScrollView {
		backgroundColor = { 0, 1, .3, 0 },
		x = display.contentCenterX,
		y = display.contentCenterY,
		width = display.contentWidth,
		height = display.contentHeight,
		horizontalScrollDisabled = true,
		verticalScrollDisabled = false
	  }
	  
	
	local yPos = 10
	local titleLabel = display.newText( "Extra Filters", display.contentCenterX, yPos, native.systemFont, 30 )
	titleLabel.anchorX, titleLabel.anchorY = .5,0;
	menuScene.extraFilter.elements[#menuScene.extraFilter.elements+1] = titleLabel;
	
	yPos = yPos + 50
	
	--Make the switches (bug in switches with scroll views)
	--Use checkboxes instead for right now
	for i = 1, 4 do
	
		local function onSwitchPress(event)
			--When checkbox is unchecked, blacken row to indicate inactivity
			local checkBox = event.target
			local oldX, oldY = menuScene.extraFilter.scrollView:getContentPosition()
			
			if (not checkBox.isOn) then
				local highlight = display.newRect( checkBox.x + checkBox.width + 10, checkBox.y-5, display.contentWidth - (checkBox.x + checkBox.width + 15), checkBox.height+10 )
				highlight:setFillColor( 0,0,0,.5 )
				highlight.anchorX, highlight.anchorY = 0, 0
				checkBox.highlight = highlight
				menuScene.extraFilter.scrollView:insert(highlight)
			else
				if (checkBox.highlight ~= nil) then
					checkBox.highlight:removeSelf();
					checkBox.highlight = nil
				end
			end
			--Prevent scroll view from 'snapping back'
			menuScene.extraFilter.scrollView:scrollToPosition
			{
				x = oldX,
				y = oldY,
				time = 10,
			}
			
			return true;
		end
		
		local opt = {
			width = 20,
			height = 20,
			numFrames = 2,
			sheetContentWidth = 40,
			sheetContentHeight = 20
		}
		local mySheet = graphics.newImageSheet( "Images/check.png", opt )	
		local checkboxButton = widget.newSwitch
		{
			left = 10,
			top = yPos,
			width = 50,
			height = 50,
			style = "checkbox",
			id = "Checkbox",
			onPress = onSwitchPress,
			sheet = mySheet,
			frameOff = 1,
			frameOn = 2,
		}
		checkboxButton.anchorX, checkboxButton.anchorY = 0, 0
		menuScene.extraFilter.switches[#menuScene.extraFilter.switches+1] = checkboxButton
		yPos = yPos + checkboxButton.height + 100
	end
	
	--Age filter
	local minAge, age, maxAge
	local xPos = menuScene.extraFilter.switches[1].x + menuScene.extraFilter.switches[1].width + 50
	yPos = menuScene.extraFilter.switches[1].y + menuScene.extraFilter.switches[1].height/2
	
	local function onLeftStepperPress( event )
		
		event.target:setValue(1); --Ignore the built in corona stepper counter, it messes things up
		
		local newValue = 0
		local oldValue = tonumber(minAge.text)
		
		if ( "increment" == event.phase ) then
			newValue = tonumber(oldValue) + 1
		elseif ( "decrement" == event.phase ) then
			newValue = tonumber(oldValue) - 1
		end
		
		if (newValue < 0) then newValue = 0
		elseif (newValue> 100) then newValue = 100 end
		
		minAge.text = newValue

	end
	local function onRightStepperPress( event )
		
		event.target:setValue(1); --Ignore the built in corona stepper counter, it messes things up
		
		local newValue = 0
		local oldValue = tonumber(maxAge.text)
		
		if ( "increment" == event.phase ) then
			newValue = tonumber(oldValue) + 1
		elseif ( "decrement" == event.phase ) then
			newValue = tonumber(oldValue) - 1
		end
		
		if (newValue < 0) then newValue = 0
		elseif (newValue> 100) then newValue = 100 end
		
		maxAge.text = newValue

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

	local leftStepper = widget.newStepper
	{
		initialValue = 10,
		x = xPos,
		y = yPos,
		width = 100,
		height = 50,
		sheet = stepperSheet,
		defaultFrame = 1,
		noMinusFrame = 2,
		noPlusFrame = 3,
		minusActiveFrame = 4,
		plusActiveFrame = 5,
		timerIncrementSpeed = 500, changeSpeedAtIncrement = 3,
		onPress = onLeftStepperPress
	}
	leftStepper.anchorX, leftStepper.anchorY = 0, .5;
	menuScene.extraFilter.elements[#menuScene.extraFilter.elements+1] = leftStepper;
	
	xPos = xPos + leftStepper.width + 20
	minAge = display.newText("18", xPos, yPos, native.systemFont, 36);
	minAge.anchorX, minAge.anchorY = 0, .5
	menuScene.extraFilter.elements[#menuScene.extraFilter.elements+1] = minAge;
	
	xPos = xPos + minAge.width + 20
	age = display.newText(" ≤ Age ≤ ", xPos, yPos, native.systemFont, 36);
	age.anchorX, age.anchorY = 0, .5
	menuScene.extraFilter.elements[#menuScene.extraFilter.elements+1] = age;
	
	xPos = xPos + age.width + 20
	maxAge = display.newText("50", xPos, yPos, native.systemFont, 36);
	maxAge.anchorX, maxAge.anchorY = 0, .5
	menuScene.extraFilter.elements[#menuScene.extraFilter.elements+1] = maxAge;
	
	xPos = xPos + maxAge.width + 20
	local rightStepper = widget.newStepper
	{
		initialValue = 10,
		x = xPos,
		y = yPos,
		width = 100,
		height = 50,
		sheet = stepperSheet,
		defaultFrame = 1,
		noMinusFrame = 2,
		noPlusFrame = 3,
		minusActiveFrame = 4,
		plusActiveFrame = 5,
		timerIncrementSpeed = 500, changeSpeedAtIncrement = 3,
		onPress = onRightStepperPress
	}
	rightStepper.anchorX, rightStepper.anchorY = 0, .5;
	menuScene.extraFilter.elements[#menuScene.extraFilter.elements+1] = rightStepper;
	
	
	--Min AB Filter
	local minAB, AB, maxAB
	local xPos = menuScene.extraFilter.switches[2].x + menuScene.extraFilter.switches[2].width + 50
	yPos = menuScene.extraFilter.switches[2].y + menuScene.extraFilter.switches[2].height/2
	
	local function onLeftStepperPress( event )
		
		event.target:setValue(1); --Ignore the built in corona stepper counter, it messes things up
		
		local newValue = 0
		local oldValue = tonumber(minAB.text)
		
		if ( "increment" == event.phase ) then
			newValue = tonumber(oldValue) + 1
		elseif ( "decrement" == event.phase ) then
			newValue = tonumber(oldValue) - 1
		end
		
		if (newValue < 0) then newValue = 0
		elseif (newValue> 9999) then newValue = 9999 end
		
		minAB.text = newValue

	end
	local function onRightStepperPress( event )
		
		event.target:setValue(1); --Ignore the built in corona stepper counter, it messes things up
		
		local newValue = 0
		local oldValue = tonumber(maxAB.text)
		
		if ( "increment" == event.phase ) then
			newValue = tonumber(oldValue) + 1
		elseif ( "decrement" == event.phase ) then
			newValue = tonumber(oldValue) - 1
		end
		
		if (newValue < 0) then newValue = 0
		elseif (newValue> 9999) then newValue = 9999 end
		
		maxAB.text = newValue

	end

	local leftStepper = widget.newStepper
	{
		initialValue = 10,
		x = xPos,
		y = yPos,
		width = 100,
		height = 50,
		sheet = stepperSheet,
		defaultFrame = 1,
		noMinusFrame = 2,
		noPlusFrame = 3,
		minusActiveFrame = 4,
		plusActiveFrame = 5,
		timerIncrementSpeed = 500, changeSpeedAtIncrement = 3,
		onPress = onLeftStepperPress
	}
	leftStepper.anchorX, leftStepper.anchorY = 0, .5;
	menuScene.extraFilter.elements[#menuScene.extraFilter.elements+1] = leftStepper;
	
	xPos = xPos + leftStepper.width + 20
	minAB = display.newText("0", xPos, yPos, native.systemFont, 36);
	minAB.anchorX, minAB.anchorY = 0, .5
	menuScene.extraFilter.elements[#menuScene.extraFilter.elements+1] = minAB;
	
	xPos = xPos + minAB.width + 55
	AB = display.newText(" ≤ AB ≤ ", xPos, yPos, native.systemFont, 36);
	AB.anchorX, AB.anchorY = 0, .5
	menuScene.extraFilter.elements[#menuScene.extraFilter.elements+1] = AB;
	
	xPos = xPos + AB.width + 35
	maxAB = display.newText("1000", xPos, yPos, native.systemFont, 36);
	maxAB.anchorX, maxAB.anchorY = 0, .5
	menuScene.extraFilter.elements[#menuScene.extraFilter.elements+1] = maxAB;
	
	xPos = xPos + maxAB.width + 20
	local rightStepper = widget.newStepper
	{
		initialValue = 10,
		x = xPos,
		y = yPos,
		width = 100,
		height = 50,
		sheet = stepperSheet,
		defaultFrame = 1,
		noMinusFrame = 2,
		noPlusFrame = 3,
		minusActiveFrame = 4,
		plusActiveFrame = 5,
		timerIncrementSpeed = 500, changeSpeedAtIncrement = 3,
		onPress = onRightStepperPress
	}
	rightStepper.anchorX, rightStepper.anchorY = 0, .5;
	menuScene.extraFilter.elements[#menuScene.extraFilter.elements+1] = rightStepper;
	
	--Min IP Filter
	local minIP, IP, maxIP
	local xPos = menuScene.extraFilter.switches[3].x + menuScene.extraFilter.switches[3].width + 50
	yPos = menuScene.extraFilter.switches[3].y + menuScene.extraFilter.switches[3].height/2
	
	local function onLeftStepperPress( event )
		
		event.target:setValue(1); --Ignore the built in corona stepper counter, it messes things up
		
		local newValue = 0
		local oldValue = tonumber(minIP.text)
		
		if ( "increment" == event.phase ) then
			newValue = tonumber(oldValue) + 1
		elseif ( "decrement" == event.phase ) then
			newValue = tonumber(oldValue) - 1
		end
		
		if (newValue < 0) then newValue = 0
		elseif (newValue> 9999) then newValue = 9999 end
		
		minIP.text = newValue

	end
	local function onRightStepperPress( event )
		
		event.target:setValue(1); --Ignore the built in corona stepper counter, it messes things up
		
		local newValue = 0
		local oldValue = tonumber(maxIP.text)
		
		if ( "increment" == event.phase ) then
			newValue = tonumber(oldValue) + 1
		elseif ( "decrement" == event.phase ) then
			newValue = tonumber(oldValue) - 1
		end
		
		if (newValue < 0) then newValue = 0
		elseif (newValue> 9999) then newValue = 9999 end
		
		maxIP.text = newValue

	end
	
	local function onStepperPress( event )
	
		menuScene.statistics.teamStepper:setValue(1); --Ignore the built in corona stepper counter, it messes things up
		if ( "increment" == event.phase ) then

		elseif ( "decrement" == event.phase ) then

		end

	end

	local leftStepper = widget.newStepper
	{
		initialValue = 10,
		x = xPos,
		y = yPos,
		width = 100,
		height = 50,
		sheet = stepperSheet,
		defaultFrame = 1,
		noMinusFrame = 2,
		noPlusFrame = 3,
		minusActiveFrame = 4,
		plusActiveFrame = 5,
		timerIncrementSpeed = 500, changeSpeedAtIncrement = 3,
		onPress = onLeftStepperPress
	}
	leftStepper.anchorX, leftStepper.anchorY = 0, .5;
	menuScene.extraFilter.elements[#menuScene.extraFilter.elements+1] = leftStepper;
	
	xPos = xPos + leftStepper.width + 20
	minIP = display.newText("0", xPos, yPos, native.systemFont, 36);
	minIP.anchorX, minIP.anchorY = 0, .5
	menuScene.extraFilter.elements[#menuScene.extraFilter.elements+1] = minIP;
	
	xPos = xPos + minIP.width + 55
	IP = display.newText(" ≤ IP ≤ ", xPos, yPos, native.systemFont, 36);
	IP.anchorX, IP.anchorY = 0, .5
	menuScene.extraFilter.elements[#menuScene.extraFilter.elements+1] = IP;
	
	xPos = xPos + IP.width + 35
	maxIP = display.newText("500", xPos, yPos, native.systemFont, 36);
	maxIP.anchorX, maxIP.anchorY = 0, .5
	menuScene.extraFilter.elements[#menuScene.extraFilter.elements+1] = maxIP;
	
	xPos = xPos + maxIP.width + 20
	local rightStepper = widget.newStepper
	{
		initialValue = 10,
		x = xPos,
		y = yPos,
		width = 100,
		height = 50,
		sheet = stepperSheet,
		defaultFrame = 1,
		noMinusFrame = 2,
		noPlusFrame = 3,
		minusActiveFrame = 4,
		plusActiveFrame = 5,
		timerIncrementSpeed = 500, changeSpeedAtIncrement = 3,
		onPress = onRightStepperPress
	}
	rightStepper.anchorX, rightStepper.anchorY = 0, .5;
	menuScene.extraFilter.elements[#menuScene.extraFilter.elements+1] = rightStepper;
	
	--Drafted Filter
	local minDrafted, Drafted, maxDrafted
	local xPos = menuScene.extraFilter.switches[4].x + menuScene.extraFilter.switches[4].width + 50
	yPos = menuScene.extraFilter.switches[4].y + menuScene.extraFilter.switches[4].height/2
	
	local function onLeftStepperPress( event )
		
		event.target:setValue(1); --Ignore the built in corona stepper counter, it messes things up
		
		local newValue = 0
		local oldValue = tonumber(minDrafted.text)
		
		if ( "increment" == event.phase ) then
			newValue = tonumber(oldValue) + 1
		elseif ( "decrement" == event.phase ) then
			newValue = tonumber(oldValue) - 1
		end
		
		if (newValue < 0) then newValue = 0
		elseif (newValue> 9999) then newValue = 9999 end
		
		minDrafted.text = newValue

	end
	local function onRightStepperPress( event )
		
		event.target:setValue(1); --Ignore the built in corona stepper counter, it messes things up
		
		local newValue = 0
		local oldValue = tonumber(maxDrafted.text)
		
		if ( "increment" == event.phase ) then
			newValue = tonumber(oldValue) + 1
		elseif ( "decrement" == event.phase ) then
			newValue = tonumber(oldValue) - 1
		end
		
		if (newValue < 0) then newValue = 0
		elseif (newValue> 9999) then newValue = 9999 end
		
		maxDrafted.text = newValue

	end
	
	local function onStepperPress( event )
	
		menuScene.statistics.teamStepper:setValue(1); --Ignore the built in corona stepper counter, it messes things up
		if ( "increment" == event.phase ) then

		elseif ( "decrement" == event.phase ) then

		end

	end

	local leftStepper = widget.newStepper
	{
		initialValue = 10,
		x = xPos,
		y = yPos,
		width = 100,
		height = 50,
		sheet = stepperSheet,
		defaultFrame = 1,
		noMinusFrame = 2,
		noPlusFrame = 3,
		minusActiveFrame = 4,
		plusActiveFrame = 5,
		timerIncrementSpeed = 500, changeSpeedAtIncrement = 3,
		onPress = onLeftStepperPress
	}
	leftStepper.anchorX, leftStepper.anchorY = 0, .5;
	menuScene.extraFilter.elements[#menuScene.extraFilter.elements+1] = leftStepper;
	
	xPos = xPos + leftStepper.width + 20
	minDrafted = display.newText("2014", xPos, yPos, native.systemFont, 36);
	minDrafted.anchorX, minDrafted.anchorY = 0, .5
	menuScene.extraFilter.elements[#menuScene.extraFilter.elements+1] = minDrafted;
	
	xPos = xPos + minDrafted.width + 40
	Drafted = display.newText(" ≤ Dft ≤ ", xPos, yPos, native.systemFont, 36);
	Drafted.anchorX, Drafted.anchorY = 0, .5
	menuScene.extraFilter.elements[#menuScene.extraFilter.elements+1] = Drafted;
	
	xPos = xPos + Drafted.width + 35
	maxDrafted = display.newText("2014", xPos, yPos, native.systemFont, 36);
	maxDrafted.anchorX, maxDrafted.anchorY = 0, .5
	menuScene.extraFilter.elements[#menuScene.extraFilter.elements+1] = maxDrafted;
	
	xPos = xPos + maxDrafted.width + 20
	local rightStepper = widget.newStepper
	{
		initialValue = 10,
		x = xPos,
		y = yPos,
		width = 100,
		height = 50,
		sheet = stepperSheet,
		defaultFrame = 1,
		noMinusFrame = 2,
		noPlusFrame = 3,
		minusActiveFrame = 4,
		plusActiveFrame = 5,
		timerIncrementSpeed = 500, changeSpeedAtIncrement = 3,
		onPress = onRightStepperPress
	}
	rightStepper.anchorX, rightStepper.anchorY = 0, .5;
	menuScene.extraFilter.elements[#menuScene.extraFilter.elements+1] = rightStepper;
	
	
	--Add all the switches to a scroll view
	for i = 1, #menuScene.extraFilter.switches do
		menuScene.extraFilter.scrollView:insert(menuScene.extraFilter.switches[i]);
	end
	
	--Add all the elements to a scroll view
	for i = 1, #menuScene.extraFilter.elements do
		menuScene.extraFilter.scrollView:insert(menuScene.extraFilter.elements[i]);
	end
	
	--See if there are any previous values in menuScene.extraFilter.info
	--If so, update this popup to reflect it
	for i = 1, #menuScene.extraFilter.info do
		local info = menuScene.extraFilter.info[i]
		if (info ~= "nil") then
			if (i == 1) then
				--Age Filter
				minAge.text, maxAge.text = menuScene.extraFilter.info[i].min, menuScene.extraFilter.info[i].max
			elseif (i == 2) then
				--AB Filter
				minAB.text, maxAB.text = menuScene.extraFilter.info[i].min, menuScene.extraFilter.info[i].max
			elseif (i == 3) then
				--IP Filter
				minIP.text, maxIP.text = menuScene.extraFilter.info[i].min, menuScene.extraFilter.info[i].max
			elseif (i == 4) then
				--Drafted Filter
				minDrafted.text, maxDrafted.text = menuScene.extraFilter.info[i].min, menuScene.extraFilter.info[i].max
			end
			 menuScene.extraFilter.switches[i]:setState({isOn = true})
		else
			local checkBox = menuScene.extraFilter.switches[i]
			--Blacken row to indicate inactivity
			
			local highlight = display.newRect( checkBox.x + checkBox.width + 10, checkBox.y-5, display.contentWidth - (checkBox.x + checkBox.width + 15), checkBox.height+10 )
			highlight:setFillColor( 0,0,0,.5 )
			highlight.anchorX, highlight.anchorY = 0, 0
			checkBox.highlight = highlight
			menuScene.extraFilter.scrollView:insert(highlight)
		
		end
	end
	
		  
	 local function destroy(event)
		if (event.phase == "ended") then 
			
			--Before exit, record extra filter information
			for i = 1, #menuScene.extraFilter.switches do
				local switch = menuScene.extraFilter.switches[i]
				if (switch.isOn) then
					if (i == 1) then
						--Age Filter
						menuScene.extraFilter.info[i] = {min = tonumber(minAge.text), max = tonumber(maxAge.text)}
					elseif (i == 2) then
						--AB Filter
						menuScene.extraFilter.info[i] = {min = tonumber(minAB.text), max = tonumber(maxAB.text)}
					elseif (i == 3) then
						--IP Filter
						menuScene.extraFilter.info[i] = {min = tonumber(minIP.text), max = tonumber(maxIP.text)}
					elseif (i == 4) then
						--Drafted Filter
						menuScene.extraFilter.info[i] = {min = tonumber(minDrafted.text), max = tonumber(maxDrafted.text)}
					end
				else
					menuScene.extraFilter.info[i] = "nil"
				end
			end
			
			--Refresh stats page to reflect new filter
			scene:removePlayerStats()
			menuScene.statistics.offset = 0
			scene:refreshPlayerStats()
			
			
			scene:destroyExtraFilterPopup(); 
		end
	end
	--Exit button
	menuScene.extraFilter.exit = widget.newButton
	{
		x = display.contentWidth,
		y = display.contentHeight,
		defaultFile = "Images/x.png",
		onEvent = destroy
	}
	menuScene.extraFilter.exit.anchorX, menuScene.extraFilter.exit.anchorY = 1, 1; 
	
	

end

function scene:destroyExtraFilterPopup()

	for i = 1, #menuScene.extraFilter.elements do
		if (menuScene.extraFilter.elements[i] ~= nil) then
			menuScene.extraFilter.elements[i]:removeSelf();
			menuScene.extraFilter.elements[i] = nil;
		end
	end
	menuScene.extraFilter.elements = {};
	
	for i = 1, #menuScene.extraFilter.switches do
		if (menuScene.extraFilter.switches[i] ~= nil) then
			menuScene.extraFilter.switches[i]:removeSelf();
			menuScene.extraFilter.switches[i] = nil;
		end
	end
	menuScene.extraFilter.switches = {};
	
	if (menuScene.extraFilter.bg ~= nil) then
		menuScene.extraFilter.bg:removeSelf();
		menuScene.extraFilter.bg = nil
	end
	
	if (menuScene.extraFilter.exit ~= nil) then
		menuScene.extraFilter.exit:removeSelf();
		menuScene.extraFilter.exit = nil
	end
	
	if (menuScene.extraFilter.scrollView ~= nil) then
		menuScene.extraFilter.scrollView:removeSelf();
		menuScene.extraFilter.scrollView = nil
	end
	
end


--Show the teams tab
function scene:showTeamsPage()
	
	--Add labels above the table
	local yPos =  45
	
	--Label touch listeners (When you touch the label, it sorts by the column);
	local function tap( event )
		
		audio.play( globalSounds["tap"] )
		
		if (event.target.text == "Name") then scene:teamSortBy("name");
		elseif (event.target.text == "Wins") then scene:teamSortBy("win");
		elseif (event.target.text == "Losses") then scene:teamSortBy("loss");
		elseif (event.target.text == "RS") then scene:teamSortBy("runsScored");
		elseif (event.target.text == "RA") then scene:teamSortBy("runsAllowed");
		elseif (event.target.text == "Money") then scene:teamSortBy("money");
		elseif (event.target.text == "Support") then scene:teamSortBy("support");
		elseif (event.target.text == "Population") then scene:teamSortBy("population");
		elseif (event.target.text == "Payroll") then scene:teamSortBy([[(SELECT SUM(salary) FROM players WHERE teamid = teams.id)]]);
		
		--The previous SQLite command is complex
		--It sorts the team by payroll
		--To see it in action, uncomment the code and bracket the SQL command
		
		--[[
		for row in db:nrows(  SELECT * FROM teams ORDER BY (SELECT SUM(salary) FROM players WHERE teamid = teams.id);  ) do
			print(row.name);
		end
		]]--
		
		end
		
		--Labels that that the table is not sorted by should be gray
		for i = 1, #menuScene.teams.labels do
			menuScene.teams.labels[i]:setFillColor(.8,.8,.8);
		end
		--Mark the selected label by changing the colour to red
		event.target:setFillColor(1,0,0);
		return true
	end 
	
	local labels = {}
	local labelsX = {}

	--Show player ratings labels
	labels = {"Name", "Wins", "Losses", "RS", "RA", "Money", "Support", "Population", "Payroll"}
	labelsX = {85,350,450,550,650,750,950,1075,1250}
	--Render labels
	for i =1, #labels do
		menuScene.teams.labels[i] =  display.newText(labels[i], labelsX[i], yPos, native.systemFont, 24 )
		menuScene.teams.labels[i].anchorX,  menuScene.teams.labels[i].anchorY = 0, 0;
		menuScene.teams.labels[i]:setFillColor(.8,.8,.8);
		
		if (i == 1) then
			menuScene.teams.labels[i]:setFillColor(1,0,0);
			menuScene.teams.sort = "Name"
		end
		menuScene.scrollView:insert(menuScene.teams.labels[i]);
		menuScene.teams.labels[i]:addEventListener( "tap", tap );
	end
	--Initially sort table by name
	scene:teamSortBy("name");
end

function scene:refreshTeamStats()
	
	--Showing team data is less complicated than showing player data because all of the teams
	--Are going to be shown on a single page
	--There are  no arrows, top, bottom, or filters to change offsets and database parameters

	--Show team data
	local path = system.pathForFile("data.db", system.DocumentsDirectory)
	db = sqlite3.open( path )   

	
	local n = 0;
	--Actual query, populate data table
	for row in db:nrows([[SELECT * FROM teams ORDER BY ]] .. menuScene.teams.sort .. [[ ]] .. menuScene.teams.sortOrder) do
	n = n+1;
	
	--Generate the text used to display stats
	local labels
	local labelsX
	local payroll
	
	for row in db:nrows([[SELECT SUM(salary) FROM players WHERE teamid = ]] .. row.id .. [[;]]) do
		payroll = row["SUM(salary)"]
	end
	
	labels = {n, row.name, row.win, row.loss, row.runsScored, row.runsAllowed, "$" .. scene:comma_value(row.money), row.support, 
		scene:comma_value(row.population), "$" .. scene:comma_value(payroll)}
	labelsX = {20, 85,350,450,550,650,750,950,1075,1250}

	
	for i = 1, #labels do
		local num = #menuScene.teams.stats+1 ;
		menuScene.teams.stats[num] =  display.newText( labels[i], labelsX[i], (n+1) * 50, native.systemFont, 24 )
		menuScene.teams.stats[num].anchorX, menuScene.teams.stats[num].anchorY = 0, 0;
		menuScene.teams.stats[num]:setFillColor(1,1,1); 
		menuScene.scrollView:insert(menuScene.teams.stats[num])
		
		if (i == 2) then
			--When the name of the team is touched, display team card
			local function tap( event )
				print(row.name .. " Show Team Card");
				scene:changeMode("Team Card", row.id);
				return true;
			end 
			menuScene.teams.stats[num]:setFillColor(.8,.8,.8);
			menuScene.teams.stats[num]:addEventListener( "tap", tap );
		end
	end
	

	
	end
	
	db:close();
end

function scene:removeTeamStats()

	for i = 1, #menuScene.teams.stats do
		--Remove all stats from menuScene.scrollView
		if (menuScene.teams.stats[i] ~= nil) then
			menuScene.teams.stats[i]:removeSelf();
			menuScene.teams.stats[i] = nil;
		end
	end
	menuScene.teams.stats = {};

end

function scene:teamSortBy(sort) 
	
	if (sort == menuScene.teams.sort) then
		--Reverse order of the sort
		if (menuScene.teams.sortOrder == "ASC") then
			menuScene.teams.sortOrder = "DESC"
		else
			menuScene.teams.sortOrder = "ASC"
		end
	end
	
	menuScene.teams.sort = sort;
	scene:removeTeamStats();
	scene:refreshTeamStats();
end

function scene:destroyTeamsPage()

	scene:removeTeamStats();
	
	for i = 1, #menuScene.teams.labels do
		--Remove all labels from menuScene.scrollView
		if (menuScene.teams.labels[i] ~= nil) then
			menuScene.teams.labels[i]:removeSelf();
			menuScene.teams.labels[i] = nil;
		end
	end
	menuScene.teams.labels = {};


end


--Show team card
function scene:showTeamCard(id)
	
	--Get player information from the database 
	local info;
	local playerTeamid;
	local goals;
	local players = {}; --Stores all the players on a particular team
	local autoSign
	local path = system.pathForFile("data.db", system.DocumentsDirectory)
	db = sqlite3.open( path )   

	for row in db:nrows([[SELECT * FROM players WHERE teamid = ]] .. id .. [[ ORDER BY name;]]) do 
		--print(row.name .. " is on the team");
		players[#players+1] = row;
	end
	for row in db:nrows([[SELECT * FROM teams WHERE id = ]] .. id .. [[;]])do
		info = row;
	end
	for row in db:nrows([[SELECT * FROM myteam]])do
		playerTeamid = row.teamid;
		goals = json.decode(row.goals)
	end
	for row in db:nrows([[SELECT * FROM settings]])do
		if (row.autoSign == 1) then autoSign = true
		else autoSign = false end
	end
	
	db:close();
	
	local nameLabel = display.newText( info.name, 60, 10, native.systemFont, 36 )
	nameLabel.anchorX, nameLabel.anchorY = 0,0;
	menuScene.teamCard.elements[#menuScene.teamCard.elements+1] = nameLabel;
	
	local recordLabel = display.newText( info.win .. " - " .. info.loss , 650, 10, native.systemFont, 36 )
	recordLabel.anchorX, recordLabel.anchorY = 0.5,0;
	menuScene.teamCard.elements[#menuScene.teamCard.elements+1] = recordLabel;
	
	local function showLineup(event)
		local path = system.pathForFile("data.db", system.DocumentsDirectory)
		db = sqlite3.open( path )   
		
		local lineup = lg:generateLineup(info.id);
		
		db:close();
		
		if (lineup == nil) then
			--If either of the two lineups are nil (which means lineup generator could not make a lineup)
			--Then show an error popup
			scene:showPopup("Lineup could not be generated", 24);
		else
			scene:showLineupPopup2(info.id, lineup);
		end
		
		return true;
	end
	
	local yPos = 75
	local viewLineup = display.newText( "View Lineup" , 650, yPos, native.systemFont, 24 )
	viewLineup.anchorX, viewLineup.anchorY = .5,0
	viewLineup:addEventListener("tap", showLineup);
	viewLineup:setFillColor(.8,.8,.8)
	menuScene.teamCard.elements[#menuScene.teamCard.elements+1] = viewLineup;
	
	if (id == playerTeamid) then
		yPos = yPos+50
		--This is player's team; allow him to change the lineup
		local function edit(event)
			scene:showEditLineupPopup(info.id);
			return true;
		end
	
		local editLineup = display.newText( "Edit Lineup" , 650, yPos, native.systemFont, 24 )
		editLineup.anchorX, editLineup.anchorY = .5,0
		editLineup:addEventListener("tap", edit);
		editLineup:setFillColor(.8,.8,.8)
		menuScene.teamCard.elements[#menuScene.teamCard.elements+1] = editLineup;
	end
	
	local function f3()
		scene:changeMode("Finances", info.id)
	end
	yPos = yPos+50
	local teamFinances = display.newText( "Team Finances" , 650, yPos, native.systemFont, 24 )
	teamFinances.anchorX, teamFinances.anchorY = .5,0
	teamFinances:addEventListener("tap", f3);
	teamFinances:setFillColor(.8,.8,.8)
	menuScene.teamCard.elements[#menuScene.teamCard.elements+1] = teamFinances;
	
	local function f()
		scene:showTeamOffersPopup(info.contract_offers, info.name);
	end
	yPos = yPos+50
	local viewOffers = display.newText( "Free Agent Offers" , 650, yPos, native.systemFont, 24 )
	viewOffers.anchorX, viewOffers.anchorY = .5,0
	viewOffers:addEventListener("tap", f);
	viewOffers:setFillColor(.8,.8,.8)
	menuScene.teamCard.elements[#menuScene.teamCard.elements+1] = viewOffers;
	
	local function f2()
		scene:showTeamHistoryPopup(id);
		return true;
	end
	yPos = yPos+50
	local viewHistory = display.newText( "Team History" , 650, yPos, native.systemFont, 24 )
	viewHistory.anchorX, viewHistory.anchorY = .5,0
	viewHistory:addEventListener("tap", f2);
	viewHistory:setFillColor(.8,.8,.8)
	menuScene.teamCard.elements[#menuScene.teamCard.elements+1] = viewHistory;
	
	--View Goals
	if (id == playerTeamid) then
	local function f4()
		local msg = "Win at least " .. goals.numGames .. " games\n\n" .. "Profit at least $" 
			.. utils:comma_value(goals.profit)
		scene:showPopup(msg, 24);
		return true;
	end
	yPos = yPos+50
	local viewGoals = display.newText( "Goals" , 650, yPos, native.systemFont, 24 )
	viewGoals.anchorX, viewGoals.anchorY = .5,0
	viewGoals:addEventListener("tap", f4);
	viewGoals:setFillColor(.8,.8,.8)
	menuScene.teamCard.elements[#menuScene.teamCard.elements+1] = viewGoals;
	end
	
	yPos = 275
	local teamLogo = display.newImage("rosters/teams/" .. info.name .. ".png", 40, 50);
	if (teamLogo == nil) then
		teamLogo = display.newImage("rosters/teams/GENERIC.png", 40, 50);
	end
	teamLogo.xScale, teamLogo.yScale = .7,.7
	teamLogo.anchorX, teamLogo.anchorY = 0, 0
	menuScene.teamCard.elements[#menuScene.teamCard.elements+1] = teamLogo
	
	
	local populationLabel =  display.newText( "Population: ", 60, yPos, native.systemFont, 24 )
	populationLabel.anchorX, populationLabel.anchorY = 0,0;
	menuScene.teamCard.elements[#menuScene.teamCard.elements+1] = populationLabel;
	
	local numPeople = math.floor((info.population/1000000) + 0.5)
	if (numPeople > 10) then numPeople = 15 end
	for i = 1, numPeople do
		local pop = display.newImage("Images/population.png", 170 + 20 * i, populationLabel.y + populationLabel.height/2);
		pop.xScale, pop.yScale = .15,.15
		pop.anchorX, pop.anchorY = 0,.5
		menuScene.teamCard.elements[#menuScene.teamCard.elements+1] = pop
	end
	
	yPos = yPos + 50
	local supportLabel =  display.newText( "Support:", 60, yPos, native.systemFont, 24 )
	supportLabel.anchorX, supportLabel.anchorY = 0,0;
	menuScene.teamCard.elements[#menuScene.teamCard.elements+1] = supportLabel;
	
	--Outer rect
	local totalWidth = 200
	local rectOut = display.newRect( supportLabel.x + supportLabel.width + 20, supportLabel.y + supportLabel.height/2
		, totalWidth, supportLabel.height )
	rectOut.anchorX, rectOut.anchorY = 0,.5
	rectOut.strokeWidth = 2
	rectOut:setFillColor(.1,.1,.1)
	rectOut:setStrokeColor( .05, .05, .05 )
	menuScene.teamCard.elements[#menuScene.teamCard.elements+1] = rectOut;
	
	--Inner rect
	local width = info.support/100 * totalWidth; 
	local rect = display.newRect( supportLabel.x + supportLabel.width + 20, supportLabel.y + supportLabel.height/2
		, width, supportLabel.height )
	rect.anchorX, rect.anchorY = 0,.5
	
	local first
	local second
	if (info.support < 35) then
		first={ 1, 0, 0 }
		second={ 0.95, 0.2, 0.2 }
	elseif (info.support < 65) then
		first={ 1, 1, 0 } 
		second={ 0.95, 0.95, 0.2 }
	else
		first={ 0, .7, .1 }
		second={ 0.2, 0.8, 0.3 }
	end
	
	local gradient = {
		type="gradient",
		color1=first, color2=second, direction="left"
	}
	rect:setFillColor(gradient);
	menuScene.teamCard.elements[#menuScene.teamCard.elements+1] = rect;
		
	
	local rosterLabel =  display.newText( "Roster", 60, 375, native.systemFont, 36 )
	rosterLabel.anchorX, rosterLabel.anchorY = 0,0;
	menuScene.teamCard.elements[#menuScene.teamCard.elements+1] = rosterLabel;
	
	local line = display.newLine( 10, 425, 790, 425 )
	line:setStrokeColor( 1, 1, 1, .5 )
	line.strokeWidth = 3
	menuScene.teamCard.elements[#menuScene.teamCard.elements+1] = line
	
	local rosterCountLabel =  display.newText( "Active / Minimum", 60, line.y + 15, native.systemFont, 24 )
	rosterCountLabel.anchorX, rosterCountLabel.anchorY = 0,0;
	menuScene.teamCard.elements[#menuScene.teamCard.elements+1] = rosterCountLabel;
	
	local num_first, num_second, num_short, num_third, num_catcher, num_of, num_sp, num_rp = 0,0,0,0,0,0,0,0;
	for i = 1, #players do
		if (players[i].posType == "1B" and players[i].injury == 0) then num_first = num_first + 1;
		elseif (players[i].posType == "2B" and players[i].injury == 0) then num_second = num_second + 1;
		elseif (players[i].posType == "SS" and players[i].injury == 0) then num_short = num_short + 1;
		elseif (players[i].posType == "3B" and players[i].injury == 0) then num_third = num_third + 1;
		elseif (players[i].posType == "C" and players[i].injury == 0) then num_catcher = num_catcher + 1;
		elseif (players[i].posType == "OF" and players[i].injury == 0) then num_of = num_of + 1;
		elseif (players[i].posType == "SP" and players[i].injury == 0) then num_sp = num_sp + 1;
		elseif (players[i].posType == "RP" and players[i].injury == 0) then num_rp = num_rp + 1;
		end
	end
	local labels = { "1B:  " .. num_first .. "/2",  "2B:  " .. num_second .. "/2",  "SS:  " .. num_short .. "/2",
		 "3B:  " .. num_third .. "/2",  "C:  " .. num_catcher .. "/2",  "OF:  " .. num_of .. "/5",  "SP:  " .. num_sp .. "/5",
		 "RP:  " .. num_rp .. "/6"}
		 
	local labelPos = {{x=60,y=line.y+60}, {x=210,y=line.y+60}, {x=360,y=line.y+60}, {x=510,y=line.y+60}, {x=660,y=line.y+60}, {x=60,y=line.y+110},
						{x=210,y=line.y+110}, {x=360,y=line.y+110}}
	local labelColors = {{1,1,1},  {1,1,1}, {1,1,1}, {1,1,1}, {1,1,1}, {1,1,1}, {1,1,1}, {1,1,1}  }
	
	if(num_first < 2) then labelColors[1] = {1,0,0} end
	if(num_second < 2) then labelColors[2] = {1,0,0} end
	if(num_short < 2) then labelColors[3] = {1,0,0} end
	if(num_third < 2) then labelColors[4] = {1,0,0} end
	if(num_catcher < 2) then labelColors[5] = {1,0,0} end
	if(num_of < 5) then labelColors[6] = {1,0,0} end
	if(num_sp < 5) then labelColors[7] = {1,0,0} end
	if(num_rp < 6) then labelColors[8] = {1,0,0} end
	
	for i = 1, #labels do
	local countLabel =  display.newText( labels[i], labelPos[i].x, labelPos[i].y, native.systemFont, 24 )
	countLabel.anchorX, countLabel.anchorY = 0,0;
	countLabel:setFillColor(labelColors[i][1], labelColors[i][2], labelColors[i][3]);
	menuScene.teamCard.elements[#menuScene.teamCard.elements+1] = countLabel;
	end
	

	
	--Disabled List
	yPos = line.y+200
	local disabledListLabel =  display.newText( "Disabled List", 60, yPos, native.systemFont, 24 )
	disabledListLabel.anchorX, disabledListLabel.anchorY = 0,0;
	menuScene.teamCard.elements[#menuScene.teamCard.elements+1] = disabledListLabel;
	
	yPos = disabledListLabel.y + disabledListLabel.height/2
	local injuryLabel = display.newImage("Images/injury.png", disabledListLabel.x + disabledListLabel.width + 15, yPos)
	injuryLabel.anchorX, injuryLabel.anchorY = 0,.5
	injuryLabel.width, injuryLabel.height = disabledListLabel.height, disabledListLabel.height
	menuScene.teamCard.elements[#menuScene.teamCard.elements+1] = injuryLabel;
	
	local injuredPlayers = {}
	
	for i = 1, #players do
		if (players[i].injury > 0) then
			injuredPlayers[#injuredPlayers+1] = players[i]
		end
	end
	local function injuredSort(a,b) --Sort from least to greatest
        return a.injury > b.injury
    end
	table.sort(injuredPlayers, injuredSort)

	for i = 1, #injuredPlayers do
		yPos = yPos + 50
		local player = injuredPlayers[i]
		
		local function tap(event)
			scene:showPlayerCardPopup(player.id)
		end
		local playerLabel =  display.newText(player.name .. " (" .. player.posType .. ") - " .. player.injury .. " days", 60, yPos, native.systemFont, 20 )
		playerLabel.anchorX, playerLabel.anchorY = 0,0;
		playerLabel:setFillColor(.8,.8,.8)
		playerLabel:addEventListener("tap", tap)
		menuScene.teamCard.elements[#menuScene.teamCard.elements+1] = playerLabel;
	end
	yPos = yPos + 50
	
	--Option for auto-sign
	if (id == playerTeamid) then
	
	local function onSwitchPress( event )
		local switch = event.target
		local path = system.pathForFile("data.db", system.DocumentsDirectory)
		db = sqlite3.open( path )   
		if (switch.isOn) then --Turn autosign on
			db:exec[[UPDATE settings SET autoSign = 1]]
		else --Turn autosign off
			db:exec[[UPDATE settings SET autoSign = 0]]
		end
		db:close();
	end
	
	local opt = {
		width = 20,
		height = 20,
		numFrames = 2,
		sheetContentWidth = 40,
		sheetContentHeight = 20
	}
	local mySheet = graphics.newImageSheet( "Images/check.png", opt )	
	local checkboxButton = widget.newSwitch
	{
		left = 60,
		top = yPos,
		width = 20,
		height = 20,
		style = "checkbox",
		id = "Checkbox",
		onPress = onSwitchPress,
		sheet = mySheet,
		frameOff = 1,
		frameOn = 2,
		initialSwitchState = autoSign
	}

	menuScene.teamCard.elements[#menuScene.teamCard.elements+1] = checkboxButton;
	
	local autoSignLabel =  display.newText( "Enable auto-signing of players to meet roster requirements", 60 + checkboxButton.width + 10, 
		yPos+checkboxButton.height/2, native.systemFont, 18 )
	autoSignLabel.anchorX, autoSignLabel.anchorY = 0,.5;
	menuScene.teamCard.elements[#menuScene.teamCard.elements+1] = autoSignLabel;
	end
	
	--Add everything to the scroll view
	for i = 1, #menuScene.teamCard.elements do
		menuScene.scrollView:insert(menuScene.teamCard.elements[i]);
	end
	
	

end

function scene:destroyTeamCard()

	for i = 1, #menuScene.teamCard.elements do
		if (menuScene.teamCard.elements[i] ~= nil) then
			menuScene.teamCard.elements[i]:removeSelf();
			menuScene.teamCard.elements[i] = nil;
		end
	end
	menuScene.teamCard.elements = {};

	
end

--Show team history
function scene:showTeamHistoryPopup(id)
	--Info is a decoded table containing all free agent offers
	--Semi-transparent black background that covers whole screen and blocks touches
	local black = display.newImage("Images/black.png", 0, 0);
	black.width, black.height = display.contentWidth, display.contentHeight
	black.anchorX, black.anchorY = 0,0
	black.alpha = .9;
	
	--Ghost element
	local topLabel = display.newText("", 0, 0, native.systemFont, 36);
	menuScene.teamHistoryPopup.elements[#menuScene.teamHistoryPopup.elements+1] = topLabel;
	
	
	local function blockTouches(event)
		return true; --Block the propagation of any touches or taps
	end
	black:addEventListener("tap", blockTouches);
	black:addEventListener("touch", blockTouches);
	menuScene.teamHistoryPopup.bg  = black;
	
	menuScene.teamHistoryPopup.scrollView = widget.newScrollView {
		backgroundColor = { 0, 1, .3, 0 },
		x = display.contentCenterX,
		y = display.contentCenterY,
		width = display.contentWidth,
		height = display.contentHeight,
		horizontalScrollDisabled = true,
		verticalScrollDisabled = false
	}
	
	
	
	local function destroy(event)
		if (event.phase == "ended") then scene:destroyTeamHistoryPopup(); end
	end
	--Exit button
	menuScene.teamHistoryPopup.exit = widget.newButton
	{
		x = display.contentWidth,
		y = display.contentHeight,
		defaultFile = "Images/x.png",
		onEvent = destroy
	}
	menuScene.teamHistoryPopup.exit.anchorX, menuScene.teamHistoryPopup.exit.anchorY = 1, 1; 
	
	local history = {}
	local teamName
	
	local path = system.pathForFile("data.db", system.DocumentsDirectory)
	db = sqlite3.open( path )  
	
	for row in db:nrows([[SELECT * FROM teams WHERE id = ]] .. id .. [[;]])do
		if (row.history ~= nil) then
			history = json.decode(row.history)
		end
		teamName = row.name
	end
	
	db:close();	
	
	
	--Team Name Label
	local teamLabel = display.newText(teamName, 20, 20, native.systemFont, 36);
	teamLabel.anchorX, teamLabel.anchorY = 0, 0;
	menuScene.teamHistoryPopup.elements[#menuScene.teamHistoryPopup.elements+1] = teamLabel;
	
	--Dividing line
	local line = display.newLine( 10, teamLabel.y + teamLabel.height + 10, 
		display.contentWidth - 10, teamLabel.y + teamLabel.height + 10 )
	line:setStrokeColor( 1, 1, 1, .5 )
	line.strokeWidth = 3
	menuScene.teamHistoryPopup.elements[#menuScene.teamHistoryPopup.elements+1] = line

	
	--If there are offers, list them in table format
	local rowData = {}
	function byval(a,b)
		--Sort by year
        return a.year < b.year
    end
	
	--Populate row data
	if (#history>0) then 
		for i = 1, #history do
			rowData[#rowData+1] = history[i]
		end
	else
		return
	end
	
	--Sort row data by name
	table.sort(rowData,byval)
	
	--Display data
	yPos = line.y + 20
	for i = 1, #rowData do
		local row = rowData[i]
		local infoLabel = display.newText(row.year .. "   " .. "(" .. row.win .. "-" .. row.loss .. ")  " .. row.info, 
			20, yPos, native.systemFont, 24);
		infoLabel.anchorX, infoLabel.anchorY = 0,0;
		menuScene.teamHistoryPopup.elements[#menuScene.teamHistoryPopup.elements+1] = infoLabel;
		yPos = yPos + 35
	end
	
	--Add all elements to scroll view
	for i = 1, #menuScene.teamHistoryPopup.elements do
		menuScene.teamHistoryPopup.scrollView:insert(menuScene.teamHistoryPopup.elements[i]);
	end
	
	
end

function scene:destroyTeamHistoryPopup()

	for i = 1, #menuScene.teamHistoryPopup.elements do
		if (menuScene.teamHistoryPopup.elements[i] ~= nil) then
			menuScene.teamHistoryPopup.elements[i]:removeSelf();
			menuScene.teamHistoryPopup.elements[i] = nil;
		end
	end
	menuScene.teamHistoryPopup.elements = {};
	
	if (menuScene.teamHistoryPopup.bg ~= nil) then
		menuScene.teamHistoryPopup.bg:removeSelf();
		menuScene.teamHistoryPopup.bg = nil
	end
	
	if (menuScene.teamHistoryPopup.exit ~= nil) then
		menuScene.teamHistoryPopup.exit:removeSelf();
		menuScene.teamHistoryPopup.exit = nil
	end
	
	if (menuScene.teamHistoryPopup.scrollView ~= nil) then
		menuScene.teamHistoryPopup.scrollView:removeSelf();
		menuScene.teamHistoryPopup.scrollView = nil
	end
	

end


--Show team offers
function scene:showTeamOffersPopup(offers, teamName)
	--Info is a decoded table containing all free agent offers
	--Semi-transparent black background that covers whole screen and blocks touches
	local black = display.newImage("Images/black.png", 0, 0);
	black.width, black.height = display.contentWidth, display.contentHeight
	black.anchorX, black.anchorY = 0,0
	black.alpha = .9;
	
	--Ghost element
	local topLabel = display.newText("", 0, 0, native.systemFont, 36);
	menuScene.teamOffersPopup.elements[#menuScene.teamOffersPopup.elements+1] = topLabel;
	
	
	local function blockTouches(event)
		return true; --Block the propagation of any touches or taps
	end
	black:addEventListener("tap", blockTouches);
	black:addEventListener("touch", blockTouches);
	menuScene.teamOffersPopup.bg  = black;
	
	menuScene.teamOffersPopup.scrollView = widget.newScrollView {
		backgroundColor = { 0, 1, .3, 0 },
		x = display.contentCenterX,
		y = display.contentCenterY,
		width = display.contentWidth,
		height = display.contentHeight,
		horizontalScrollDisabled = true,
		verticalScrollDisabled = false
	}
	
	
	
	local function destroy(event)
		if (event.phase == "ended") then scene:destroyTeamOffersPopup(); end
	end
	--Exit button
	menuScene.teamOffersPopup.exit = widget.newButton
	{
		x = display.contentWidth,
		y = display.contentHeight,
		defaultFile = "Images/x.png",
		onEvent = destroy
	}
	menuScene.teamOffersPopup.exit.anchorX, menuScene.teamOffersPopup.exit.anchorY = 1, 1; 
	
	--Team Name Label
	local teamLabel = display.newText("Free Agent Offers", 20, 20, native.systemFont, 36);
	teamLabel.anchorX, teamLabel.anchorY = 0, 0;
	menuScene.teamOffersPopup.elements[#menuScene.teamOffersPopup.elements+1] = teamLabel;
	
	--Dividing line
	local line = display.newLine( 10, teamLabel.y + teamLabel.height + 10, 
		display.contentWidth - 10, teamLabel.y + teamLabel.height + 10 )
	line:setStrokeColor( 1, 1, 1, .5 )
	line.strokeWidth = 3
	menuScene.teamOffersPopup.elements[#menuScene.teamOffersPopup.elements+1] = line

	--If no offers, return
	if (offers == nil or offers == {}) then
		return
	end
	
	--Show labels
	local labels = {"Pos", "Name", "Ovr", "Pot", "Sal($)", "Yrs"}
	local xPos = {20, 75, 370, 445, 520, 720}
	local yPos = teamLabel.y + teamLabel.height * 2
	for i = 1, #labels do
		local topLabel = display.newText(labels[i], xPos[i], yPos, native.systemFont, 24);
		topLabel.anchorX, topLabel.anchorY = 0,0;
		menuScene.teamOffersPopup.elements[#menuScene.teamOffersPopup.elements+1] = topLabel;
	end
	
	
	
	offers = json.decode(offers);
	
	--If there are offers, list them in table format
	local rowData = {}
	function byval(a,b)
		--rowData = { playerInfo1, playerInfo2, ...}
		--playerInfo = {posType, name , ovr, pot, sal, yrs}
		--a & b= playerInfo
		--Therefore, sorting by name
        return a[2] < b[2]
    end
	
	--Populate row data
	if (#offers>0) then 
		for i = 1, #offers do
			
			local infoLabels = {} --
			local path = system.pathForFile("data.db", system.DocumentsDirectory)
			db = sqlite3.open( path )   
			for row in db:nrows([[SELECT * FROM players WHERE id = ]] .. offers[i].playerid .. [[;]]) do 
				infoLabels[1], infoLabels[2], infoLabels[3], infoLabels[4] =
					row.posType, row.name, row.overall, row.potential
			end
			db:close();
			infoLabels[5], infoLabels[6], infoLabels[7] = 
				"$" .. scene:comma_value(offers[i].salary) , offers[i].years, offers[i].playerid 
			rowData[#rowData+1] = infoLabels
			
		end
	end
	
	--Sort row data by name
	table.sort(rowData,byval)
	
	--Display row data
	yPos = yPos + 50
	for n = 1, #rowData do
		local infoLabels = rowData[n]
		for i = 1, #labels do
			local infoLabel = display.newText(infoLabels[i], xPos[i], yPos, native.systemFont, 24);
			infoLabel.anchorX, infoLabel.anchorY = 0,0;
			menuScene.teamOffersPopup.elements[#menuScene.teamOffersPopup.elements+1] = infoLabel;
			
			if (i == 2) then
				--Clicking on name shows player card
				local playerId = infoLabels[7]; --Stored when populating row data
				infoLabel:setFillColor(.8,.8,.8);
				local function f()
					scene:showPlayerCardPopup(playerId);
					return true;
				end
				infoLabel:addEventListener("tap", f);
			end
		end
		yPos = yPos + 35
	end
	
	
	--Add all elements to scroll view
	for i = 1, #menuScene.teamOffersPopup.elements do
		menuScene.teamOffersPopup.scrollView:insert(menuScene.teamOffersPopup.elements[i]);
	end
	
	
end

function scene:destroyTeamOffersPopup()

	for i = 1, #menuScene.teamOffersPopup.elements do
		if (menuScene.teamOffersPopup.elements[i] ~= nil) then
			menuScene.teamOffersPopup.elements[i]:removeSelf();
			menuScene.teamOffersPopup.elements[i] = nil;
		end
	end
	menuScene.teamOffersPopup.elements = {};
	
	if (menuScene.teamOffersPopup.bg ~= nil) then
		menuScene.teamOffersPopup.bg:removeSelf();
		menuScene.teamOffersPopup.bg = nil
	end
	
	if (menuScene.teamOffersPopup.exit ~= nil) then
		menuScene.teamOffersPopup.exit:removeSelf();
		menuScene.teamOffersPopup.exit = nil
	end
	
	if (menuScene.teamOffersPopup.scrollView ~= nil) then
		menuScene.teamOffersPopup.scrollView:removeSelf();
		menuScene.teamOffersPopup.scrollView = nil
	end
	

end

--Show free agent offers
function scene:showFaOffersPopup(offers, faName)
	--Info is a decoded table containing all free agent offers
	--Semi-transparent black background that covers whole screen and blocks touches
	local black = display.newImage("Images/black.png", 0, 0);
	black.width, black.height = display.contentWidth, display.contentHeight
	black.anchorX, black.anchorY = 0,0
	black.alpha = .9;
	
	--Ghost element
	local topLabel = display.newText("", 0, 0, native.systemFont, 36);
	menuScene.faOffersPopup.elements[#menuScene.faOffersPopup.elements+1] = topLabel;
	
	
	local function blockTouches(event)
		return true; --Block the propagation of any touches or taps
	end
	black:addEventListener("tap", blockTouches);
	black:addEventListener("touch", blockTouches);
	menuScene.faOffersPopup.bg  = black;
	
	menuScene.faOffersPopup.scrollView = widget.newScrollView {
		backgroundColor = { 0, 1, .3, 0 },
		x = display.contentCenterX,
		y = display.contentCenterY,
		width = display.contentWidth,
		height = display.contentHeight,
		horizontalScrollDisabled = true,
		verticalScrollDisabled = false
	}
	
	
	
	local function destroy(event)
		if (event.phase == "ended") then scene:destroyFaOffersPopup(); end
	end
	--Exit button
	menuScene.faOffersPopup.exit = widget.newButton
	{
		x = display.contentWidth,
		y = display.contentHeight,
		defaultFile = "Images/x.png",
		onEvent = destroy
	}
	menuScene.faOffersPopup.exit.anchorX, menuScene.faOffersPopup.exit.anchorY = 1, 1; 
	
	--Name Label
	local nameLabel = display.newText(faName .. " Offers", 20, 20, native.systemFont, 36);
	nameLabel.anchorX, nameLabel.anchorY = 0, 0;
	menuScene.faOffersPopup.elements[#menuScene.faOffersPopup.elements+1] = nameLabel;
	
	--Dividing line
	local line = display.newLine( 10, nameLabel.y + nameLabel.height + 10, 
		display.contentWidth - 10, nameLabel.y + nameLabel.height + 10 )
	line:setStrokeColor( 1, 1, 1, .5 )
	line.strokeWidth = 3
	menuScene.faOffersPopup.elements[#menuScene.faOffersPopup.elements+1] = line
	
	--If no offers, return
	if (offers == nil or offers == {}) then
		return
	end
	
	--Show labels
	local labels = {"Team", "Sal($)", "Yrs"}
	local xPos = {20, 120, 370}
	local yPos = nameLabel.y + nameLabel.height * 2
	for i = 1, #labels do
		local topLabel = display.newText(labels[i], xPos[i], yPos, native.systemFont, 24);
		topLabel.anchorX, topLabel.anchorY = 0,0;
		menuScene.faOffersPopup.elements[#menuScene.faOffersPopup.elements+1] = topLabel;
	end
	
	offers = json.decode(offers);
	
	--If there are offers, list them in table format
	local rowData = {}
	function byval(a,b)
		--rowData = { teamInfo1, teamInfo2, ...}
		--teamInfo = {abv, sal, yrs}
		--a & b= teamInfo
		--Therefore, sorting by abbreviation
        return a[1] < b[1]
    end
	
	--Populate row data
	if (#offers>0) then 
		for i = 1, #offers do
			
			local infoLabels = {}
			local path = system.pathForFile("data.db", system.DocumentsDirectory)
			db = sqlite3.open( path )   
			for row in db:nrows([[SELECT * FROM teams WHERE id = ]] .. offers[i].teamid .. [[;]]) do 
				infoLabels[1] = row.abv
			end
			db:close();
			
			infoLabels[2], infoLabels[3] = "$" .. scene:comma_value(offers[i].salary) , offers[i].years
			rowData[#rowData+1] = infoLabels
			
		end
	end
	
	--Sort row data by name
	table.sort(rowData,byval)
	
	--Display row data
	yPos = yPos + 50
	for n = 1, #rowData do
		local infoLabels = rowData[n]
		for i = 1, #labels do
			local infoLabel = display.newText(infoLabels[i], xPos[i], yPos, native.systemFont, 24);
			infoLabel.anchorX, infoLabel.anchorY = 0,0;
			menuScene.faOffersPopup.elements[#menuScene.faOffersPopup.elements+1] = infoLabel;
		end
		yPos = yPos + 30
	end
	
	
	--Add all elements to scroll view
	for i = 1, #menuScene.faOffersPopup.elements do
		menuScene.faOffersPopup.scrollView:insert(menuScene.faOffersPopup.elements[i]);
	end
	
	
end

function scene:destroyFaOffersPopup()

	for i = 1, #menuScene.faOffersPopup.elements do
		if (menuScene.faOffersPopup.elements[i] ~= nil) then
			menuScene.faOffersPopup.elements[i]:removeSelf();
			menuScene.faOffersPopup.elements[i] = nil;
		end
	end
	menuScene.faOffersPopup.elements = {};
	
	if (menuScene.faOffersPopup.bg ~= nil) then
		menuScene.faOffersPopup.bg:removeSelf();
		menuScene.faOffersPopup.bg = nil
	end
	
	if (menuScene.faOffersPopup.exit ~= nil) then
		menuScene.faOffersPopup.exit:removeSelf();
		menuScene.faOffersPopup.exit = nil
	end
	
	if (menuScene.faOffersPopup.scrollView ~= nil) then
		menuScene.faOffersPopup.scrollView:removeSelf();
		menuScene.faOffersPopup.scrollView = nil
	end
	

end


--Show trade tab
function scene:showTradePage()

	--Get the team that the player is playing for
	local playerTeamid;
	local playerTeamname;
	
	
	local path = system.pathForFile("data.db", system.DocumentsDirectory)
	db = sqlite3.open( path )   

	for row in db:nrows([[SELECT * FROM myteam;]])do
		playerTeamid = row.teamid
	end
	for row in db:nrows([[SELECT * FROM teams WHERE id = ]] .. playerTeamid .. [[;]])do
		playerTeamname = row.name
	end
	
	--Prepare the table of teams for the trade team cycler (team stepper widget)
	menuScene.trade.teams = {}
	for row in db:nrows([[SELECT * FROM teams; ]]) do 
		--Because we remove an element from the table, teamid is no longer correlated
		--with the (menuScene.trade.counter)
		--we must record the id so that the appropriate players will be shown for each team
		menuScene.trade.teams[#menuScene.trade.teams+1] = {name = row.name, id = row.id};
	end
	table.remove(menuScene.trade.teams, playerTeamid); --Player can't trade with own team
	
	db:close();
	
	
	--PLAYER TEAM

	local yPos = 20
	local team1 = display.newText(  playerTeamname, 60, yPos, native.systemFont, 24 )
	team1.anchorX, team1.anchorY = 0, 0;
	menuScene.trade.elements[#menuScene.trade.elements+1] = team1;
	menuScene.scrollView:insert(team1);
	
	yPos = yPos + team1.height + 40
	menuScene.trade.scrollView1 = widget.newScrollView {
		backgroundColor = { 0, 1, .2, 0 },
		x = 60,
		y = yPos,
		width = 600,
		height = display.contentHeight-120,
		horizontalScrollDisabled = false,
		verticalScrollDisabled = false
	 }
	menuScene.trade.scrollView1.anchorX, menuScene.trade.scrollView1.anchorY = 0,0;
	menuScene.trade.scrollView1.orderBy = "overall"
	menuScene.trade.scrollView1.orderByDirection = "DESC"
	menuScene.scrollView:insert(menuScene.trade.scrollView1);
	--Ghost element
	local topLabel = display.newText("", 0, 0, native.systemFont, 36);
	menuScene.trade.scrollView1:insert(topLabel);
	
	yPos = menuScene.trade.scrollView1.y + menuScene.trade.scrollView1.height + 50
	
	

	local box1 = display.newLine(menuScene.trade.scrollView1.x-5, menuScene.trade.scrollView1.y-5,
		menuScene.trade.scrollView1.x + menuScene.trade.scrollView1.width+5, menuScene.trade.scrollView1.y-5)
	box1:append(menuScene.trade.scrollView1.x + menuScene.trade.scrollView1.width+5, menuScene.trade.scrollView1.y + menuScene.trade.scrollView1.height+5,
		menuScene.trade.scrollView1.x-5, menuScene.trade.scrollView1.y + menuScene.trade.scrollView1.height+5,
		menuScene.trade.scrollView1.x-5, menuScene.trade.scrollView1.y-5)
	box1:setStrokeColor( 1, 1, 1, .5 )
	box1.strokeWidth = 3
	menuScene.trade.elements[#menuScene.trade.elements+1] = box1
	menuScene.scrollView:insert(box1)
	
	--Dividing line
	local line = display.newLine( 0, yPos, display.contentWidth, yPos)
	line:setStrokeColor( 1, 1, 1, .5 )
	line.strokeWidth = 3
	menuScene.trade.elements[#menuScene.trade.elements+1] = line
	menuScene.scrollView:insert(line)
	
	
	
	
	
	--CPU TEAM
	
	--Team Stepper
	-- Handle stepper events
	yPos = yPos + 40
	
	local function onStepperPress( event )
	
		menuScene.trade.teamStepper:setValue(1); --Ignore the built in corona stepper counter, it messes things up
		if ( "increment" == event.phase ) then
			menuScene.trade.teamCounter = menuScene.trade.teamCounter + 1
			if (menuScene.trade.teamCounter > #menuScene.trade.teams) then --Loop to the start
				menuScene.trade.teamCounter = 1
			end
		elseif ( "decrement" == event.phase ) then
			menuScene.trade.teamCounter = menuScene.trade.teamCounter - 1
			if (menuScene.trade.teamCounter < 1) then --Loop to the end
				menuScene.trade.teamCounter = #menuScene.trade.teams
			end
		end

		menuScene.trade.teamDisplay.text  = menuScene.trade.teams[menuScene.trade.teamCounter].name;
		
		--Populate the scroll view with appropriate players
		scene:tradeDepopulateScrollView(menuScene.trade.scrollView2);
		scene:tradePopulateScrollView(menuScene.trade.scrollView2, menuScene.trade.teams[menuScene.trade.teamCounter].id);
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
	menuScene.trade.teamStepper = widget.newStepper
	{
		initialValue = 10,
		x = 60,
		y = yPos,
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
	menuScene.trade.teamStepper.anchorX, menuScene.trade.teamStepper.anchorY = 0, 0;
	menuScene.scrollView:insert(menuScene.trade.teamStepper);
	
	menuScene.trade.teamDisplay = display.newText( menuScene.trade.teams[menuScene.trade.teamCounter].name, 
		menuScene.trade.teamStepper.x + menuScene.trade.teamStepper.width + 20,
		menuScene.trade.teamStepper.y + menuScene.trade.teamStepper.height / 2, native.systemFont, 24 )
	menuScene.trade.teamDisplay.anchorX,  menuScene.trade.teamDisplay.anchorY = 0, .5;
	menuScene.trade.teamDisplay:setFillColor(1,1,1); 
	menuScene.scrollView:insert(menuScene.trade.teamDisplay);
	
	
	yPos = yPos + menuScene.trade.teamStepper.height + 50
	menuScene.trade.scrollView2 = widget.newScrollView {
		backgroundColor = { 0, 1, .2, 0 },
		x = 60,
		y = yPos,
		width = 600,
		height = display.contentHeight-120,
		horizontalScrollDisabled = false,
		verticalScrollDisabled = false
	 }
	menuScene.trade.scrollView2.anchorX, menuScene.trade.scrollView2.anchorY = 0,0;
	menuScene.trade.scrollView2.orderBy = "overall"
	menuScene.trade.scrollView2.orderByDirection = "DESC"
	menuScene.scrollView:insert(menuScene.trade.scrollView2);
	
	--Ghost element
	local topLabel = display.newText("", 0, 0, native.systemFont, 36);
	menuScene.trade.scrollView2:insert(topLabel);
	
	local box2 = display.newLine(menuScene.trade.scrollView2.x-5, menuScene.trade.scrollView2.y-5,
		menuScene.trade.scrollView2.x + menuScene.trade.scrollView2.width+5, menuScene.trade.scrollView2.y-5)
	box2:append(menuScene.trade.scrollView2.x + menuScene.trade.scrollView2.width+5, menuScene.trade.scrollView2.y + menuScene.trade.scrollView2.height+5,
		menuScene.trade.scrollView2.x-5, menuScene.trade.scrollView2.y + menuScene.trade.scrollView2.height+5,
		menuScene.trade.scrollView2.x-5, menuScene.trade.scrollView2.y-5)
	box2:setStrokeColor( 1, 1, 1, .5 )
	box2.strokeWidth = 3
	menuScene.trade.elements[#menuScene.trade.elements+2] = box2
	menuScene.scrollView:insert(box2)
	

	
	--Trade and cancel buttons
	yPos = menuScene.trade.scrollView2.y + menuScene.trade.scrollView2.height + 50
	local function handleButtonEvent(event)
		local button = event.target.id
		if (event.phase == "ended") then
		if (button == "cancel") then
		
			--Clear all the checkboxes (and highlights)
			for i = 1, #menuScene.trade.scrollView1.checkboxes do
				if (menuScene.trade.scrollView1.checkboxes[i] ~= nil) then
					
					menuScene.trade.scrollView1.checkboxes[i]:setState({isOn = false});
					
					if (menuScene.trade.scrollView1.checkboxes[i].highlight ~= nil) then
						menuScene.trade.scrollView1.checkboxes[i].highlight:removeSelf()
						menuScene.trade.scrollView1.checkboxes[i].highlight = nil
					end
				end
			end
			
			for i = 1, #menuScene.trade.scrollView2.checkboxes do
				if (menuScene.trade.scrollView2.checkboxes[i] ~= nil) then
					
					menuScene.trade.scrollView2.checkboxes[i]:setState({isOn = false});
					
					if (menuScene.trade.scrollView2.checkboxes[i].highlight ~= nil) then
						menuScene.trade.scrollView2.checkboxes[i].highlight:removeSelf()
						menuScene.trade.scrollView2.checkboxes[i].highlight = nil
					end
				end
			end

		elseif (button == "trade") then
		
			local playersTo_id = {}
			local playersFrom_id = {}
			--Must get the players that are being traded
			--To fill up the playersTo_id and playersFrom_id tables
			for i = 1, #menuScene.trade.scrollView1.checkboxes do
				if (menuScene.trade.scrollView1.checkboxes[i].isOn) then
					playersTo_id[#playersTo_id + 1] = menuScene.trade.scrollView1.checkboxes[i].playerid
				end
			end
			
			for i = 1, #menuScene.trade.scrollView2.checkboxes do
				if (menuScene.trade.scrollView2.checkboxes[i].isOn) then
					playersFrom_id[#playersFrom_id + 1] = menuScene.trade.scrollView2.checkboxes[i].playerid
				end
			end
			--Show Confirm Trade Popup
			scene:showConfirmTradePopup(playersTo_id, playersFrom_id, playerTeamid,
				menuScene.trade.teams[menuScene.trade.teamCounter].id);
		
			
		end
		end
	end
	local options = {
		width = 100,
		height = 50,
		numFrames = 4,
		sheetContentWidth = 200,
		sheetContentHeight = 100
	}
	local buttonSheet = graphics.newImageSheet( "Images/trade_menu.png", options )
	
	local trade = widget.newButton
	{
		id = "trade",
		sheet = buttonSheet,
		defaultFrame = 1,
		overFrame = 2,
		onEvent = handleButtonEvent
	}
	trade.anchorX, trade.anchorY = 0,0;
	trade.x = 60;
	trade.y = yPos
	menuScene.trade.elements[#menuScene.trade.elements+1] = trade
	menuScene.scrollView:insert(trade);
	
	-- Not working properly. Corona SDK error where when clearing checkbox that is offscreen, it is permanently disabled
	--[[local cancel = widget.newButton
	{
		id = "cancel",
		sheet = buttonSheet,
		defaultFrame = 3,
		overFrame = 4,
		onEvent = handleButtonEvent
	}
	cancel.anchorX, cancel.anchorY = 0,0;
	cancel.x = trade.x + trade.width + 5;
	cancel.y = yPos
	menuScene.trade.elements[#menuScene.trade.elements+1] = cancel
	menuScene.scrollView:insert(cancel);]]--
	
	
	--Populate the first scroll view with player's team
	scene:tradePopulateScrollView(menuScene.trade.scrollView1, playerTeamid);
	scene:tradePopulateScrollView(menuScene.trade.scrollView2, menuScene.trade.teams[menuScene.trade.teamCounter].id); 
end

function scene:tradePopulateScrollView(scrollView, teamid)

	local path = system.pathForFile("data.db", system.DocumentsDirectory)
	db = sqlite3.open( path )   

	scrollView.elements = {};
	scrollView.checkboxes = {};
	
	local function sortBy(event)
	
		audio.play( globalSounds["tap"] )
		
		local newSort = event.target.sort
		
		if (scrollView.orderBy == newSort) then
			--Flip the order by direction
			if (scrollView.orderByDirection == "DESC") then
				scrollView.orderByDirection = "ASC"
			else
				scrollView.orderByDirection = "DESC"
			end
		end
		
		scrollView.orderBy = newSort
		--Refresh scroll view to reflect new sort
		scene:tradeDepopulateScrollView(scrollView)
		scene:tradePopulateScrollView(scrollView, teamid)
	end
	
	--Render heading labels
	local labels = {"Name", "Pos", "Ovr", "Pot", "Salary"}
	local labelX = {40, 290, 340, 390, 440}
	local labelSort = {"name", "posType", "overall", "potential", "salary"}
	
	for i = 1, #labels do
		local label = display.newText(labels[i], labelX[i], 0, native.systemFont, 20);
		label.anchorX, label.anchorY = 0, 0;
		label.sort = labelSort[i]
		label:setFillColor(.8,.8,.8)
		label:addEventListener("tap", sortBy)
		scrollView.elements[#scrollView.elements+1] = label;
		scrollView:insert(label);
		
		if (scrollView.orderBy == label.sort) then
			label:setFillColor(1,0,0)
		end
	end

	
	--Populate table
	local n = 1;
	for row in db:nrows([[SELECT * FROM players WHERE teamid = ]] .. teamid .. [[ ORDER BY ]] .. scrollView.orderBy .. [[ ]] .. scrollView.orderByDirection .. [[;]])do
		
		local rowNum = n

		local function onSwitchPress(event)
			--When checkbox is checked, highlight the row
			
			print("Pressed Checkbox")
			
			local checkBox = event.target
			local oldX, oldY = scrollView:getContentPosition()
			if (checkBox.isOn) then
				local highlight = display.newRect( 0, rowNum * 50, scrollView.width, 40 )
				highlight:setFillColor( 0,1,0,.2 )
				highlight.anchorX, highlight.anchorY = 0, 0
				checkBox.highlight = highlight
				scrollView:insert(highlight)
			else
				if (checkBox.highlight ~= nil) then
					checkBox.highlight:removeSelf();
					checkBox.highlight = nil
				end
			end
			--Prevent scroll view from 'snapping back'
			scrollView:scrollToPosition
			{
				x = oldX,
				y = oldY,
				time = 10,
			}
			return true;
		end
		
		local opt = {
			width = 20,
			height = 20,
			numFrames = 2,
			sheetContentWidth = 40,
			sheetContentHeight = 20
		}
		local mySheet = graphics.newImageSheet( "Images/check.png", opt )	
		local checkboxButton = widget.newSwitch
		{
			left = 10,
			top = n*50,
			width = 20,
			height = 20,
			style = "checkbox",
			id = "Checkbox",
			onPress = onSwitchPress,
			sheet = mySheet,
			frameOff = 1,
			frameOn = 2,
		}
		checkboxButton.playerid = row.id;
		scrollView.checkboxes[#scrollView.checkboxes+1] = checkboxButton
		scrollView:insert(checkboxButton);
		
		local function tap(event)
			scene:showPlayerCardPopup(row.id);
		end
		local name = display.newText(row.name, 40, n * 50, native.systemFont, 20);
		name.anchorX, name.anchorY = 0, 0;
		name:setFillColor(.8,.8,.8)
		name:addEventListener("tap", tap);
		scrollView.elements[#scrollView.elements+1] = name
		scrollView:insert(name);
		
		if (row.injury > 0) then
			local injury =  display.newImage("Images/injury.png", name.x + name.width + 10, name.y + name.height/2)
			injury.anchorX, injury.anchorY = 0, .5;
			injury.width, injury.height = name.height, name.height
			scrollView.elements[#scrollView.elements+1] = injury
			scrollView:insert(injury)
		end
		
		local posType = display.newText(row.posType, 290, n * 50, native.systemFont, 20);
		posType.anchorX, posType.anchorY = 0, 0;
		scrollView.elements[#scrollView.elements+1] = posType
		scrollView:insert(posType);
		
		local overall = display.newText(row.overall, 340, n * 50, native.systemFont, 20);
		overall.anchorX, overall.anchorY = 0, 0;
		scrollView.elements[#scrollView.elements+1] = overall
		scrollView:insert(overall);
		
		local potential = display.newText(row.potential, 390, n * 50, native.systemFont, 20);
		potential.anchorX, potential.anchorY = 0, 0;
		scrollView.elements[#scrollView.elements+1] = potential
		scrollView:insert(potential);
		
		local salary = display.newText("$" .. scene:comma_value(row.salary), 440, n * 50, native.systemFont, 20);
		salary.anchorX, salary.anchorY = 0, 0;
		scrollView.elements[#scrollView.elements+1] = salary
		scrollView:insert(salary);
		n = n + 1;
	end
	
	db:close();

end

function scene:tradeDepopulateScrollView(scrollView)
	for i = 1, #scrollView.elements do
		if (scrollView.elements[i] ~= nil) then
			scrollView.elements[i]:removeSelf();
			scrollView.elements[i] = nil
		end
	end
	scrollView.elements = {}
	
	for i = 1, #scrollView.checkboxes do
		if (scrollView.checkboxes[i] ~= nil) then
		
			if (scrollView.checkboxes[i].highlight ~= nil) then
				scrollView.checkboxes[i].highlight:removeSelf();
				scrollView.checkboxes[i].highlight = nil
			end
			
			scrollView.checkboxes[i]:removeSelf();
			scrollView.checkboxes[i] = nil
			
		end
	end
	scrollView.checkboxes = {}
	
end

function scene:destroyTradePage()

	for i = 1, #menuScene.trade.elements do
		if (menuScene.trade.elements[i] ~= nil) then
			menuScene.trade.elements[i]:removeSelf();
			menuScene.trade.elements[i] = nil;
		end
	end
	menuScene.trade.elements = {};

	
	if(menuScene.trade.teamStepper ~= nil) then
		menuScene.trade.teamStepper:removeSelf();
		menuScene.trade.teamStepper = nil
	end
	
	if(menuScene.trade.teamDisplay ~= nil) then
		menuScene.trade.teamDisplay:removeSelf();
		menuScene.trade.teamDisplay = nil
	end
	
	if(menuScene.trade.scrollView1 ~= nil) then
		menuScene.trade.scrollView1:removeSelf();
		menuScene.trade.scrollView1 = nil
	end
	
	if(menuScene.trade.scrollView2 ~= nil) then
		menuScene.trade.scrollView2:removeSelf();
		menuScene.trade.scrollView2 = nil
	end
	

end


--Confirm trade popup
function scene:showConfirmTradePopup(playersTo_id, playersFrom_id, team1, team2)
	
	--playersTo_id = table of all player ids being sent to other team
	--playersFrom_id = table of all player ids being received from other team
	--team1 - player team
	--team2 - cpu team
	local playersTo = {}
	local playersToSalary = 0; --Total salary of players being sent
	local playersFrom = {}
	local playersFromSalary = 0; --Total salary of players being received
	local playerTeam, cpuTeam
	local day
	
	--Extract information about the players from the database
	local path = system.pathForFile("data.db", system.DocumentsDirectory)
	db = sqlite3.open( path )   
	for row in db:nrows([[SELECT * FROM league;]])do
		day = row.day
	end
	for row in db:nrows([[SELECT * FROM teams WHERE id = ]] .. team1 .. [[;]])do
		playerTeam = row
	end
	for row in db:nrows([[SELECT * FROM teams WHERE id = ]] .. team2 .. [[;]])do
		cpuTeam = row
	end
	
	for i = 1, #playersTo_id do
		for row in db:nrows([[SELECT * FROM players WHERE id = ]] .. playersTo_id[i] .. [[;]])do
			playersTo[i] = row;
		end
	end
	for i = 1, #playersFrom_id do
		for row in db:nrows([[SELECT * FROM players WHERE id = ]] .. playersFrom_id[i] .. [[;]])do
			playersFrom[i] = row;
		end
	end
	db:close();
	
	--Calculate total salaries
	for i = 1, #playersTo do
		playersToSalary = playersToSalary + playersTo[i].salary
	end
	for i = 1, #playersFrom do
		playersFromSalary = playersFromSalary + playersFrom[i].salary
	end
	

	--Semi-transparent black background that covers whole screen and blocks touches
	local black = display.newImage("Images/black.png", 0, 0);
	black.width, black.height = display.contentWidth, display.contentHeight
	black.anchorX, black.anchorY = 0,0
	black.alpha = .9;
	
	local function blockTouches(event)
		return true; --Block the propagation of any touches or taps
	end
	black:addEventListener("tap", blockTouches);
	black:addEventListener("touch", blockTouches);
	menuScene.confirmTradePopup.bg  = black;
	
	
	
	--Scroll Views
	menuScene.confirmTradePopup.scrollView = widget.newScrollView {
		backgroundColor = { 0, 1, 0, 0 },
		x = 0,
		y = 0,
		width = 400,
		height = display.contentHeight,
		horizontalScrollDisabled = true,
		verticalScrollDisabled = false
	  }
	menuScene.confirmTradePopup.scrollView.anchorX, menuScene.confirmTradePopup.scrollView.anchorY = 0,0;
	
	--Ghost element (need this so that scroll view doesn't accidentally cut content off)
	local topLabel = display.newText("", 0, 0, native.systemFont, 36);
	menuScene.confirmTradePopup.scrollView:insert(topLabel);
	
	menuScene.confirmTradePopup.scrollView2 = widget.newScrollView {
		backgroundColor = { 1, 0, 0, 0 },
		x = 400,
		y = 0,
		width = 400,
		height = display.contentHeight-50,
		horizontalScrollDisabled = true,
		verticalScrollDisabled = false
	  }
	menuScene.confirmTradePopup.scrollView2.anchorX, menuScene.confirmTradePopup.scrollView2.anchorY = 0,0;
	
	--Ghost element (need this so that scroll view doesn't accidentally cut content off)
	local topLabel = display.newText("", 0, 0, native.systemFont, 36);
	menuScene.confirmTradePopup.scrollView2:insert(topLabel);
	
	
	--Line Dividing Scroll Views
	local line = display.newLine( 400,0,400,480);
	line:setStrokeColor( 1, 1, 1, .5 )
	line.strokeWidth = 3
	menuScene.confirmTradePopup.elements [#menuScene.confirmTradePopup.elements +1] = line
	
	
	--Add the trade information to the popup
	local yPos = 10;
	
	local receive = display.newText(playerTeam.name .. " Get:", 20,yPos, native.systemFont, 20);
	receive.anchorX, receive.anchorY = 0, 0;
	menuScene.confirmTradePopup.elements[#menuScene.confirmTradePopup.elements+1] = receive
	menuScene.confirmTradePopup.scrollView:insert(receive)
	
	for i = 1, #playersFrom do
		yPos = 0;
		
		local dg = display.newGroup()
		dg.anchorX, dg.anchorY = 0, 0
		dg.anchorChildren = true
		dg.x, dg.y = 10, (i-1) * 150 + 50
		
		local name = display.newText(playersFrom[i].name, 140,10, native.systemFont, 20);
		name.anchorX, name.anchorY = 0, 0;
		local overall = display.newText("Ovr: " .. playersFrom[i].overall, 140,35, native.systemFont, 20);
		overall.anchorX, overall.anchorY = 0, 0;
		local potential = display.newText("Pot: " .. playersFrom[i].potential, 220,35, native.systemFont, 20);
		potential.anchorX, potential.anchorY = 0, 0;
		local salary = display.newText("$" .. utils:comma_value(playersFrom[i].salary) .. 
			" (" .. playersFrom[i].years .. " yrs)", 140,60, native.systemFont, 20);
		salary.anchorX, salary.anchorY = 0, 0;
		local value = math.round((tr:determineTradeValue(playersFrom[i], day)-playersFrom[i].years*playersFrom[i].salary)/1000000)
		local tradeValue = display.newText("Trade Value: " .. value, 140,85, native.systemFontBold, 24);
		tradeValue.anchorX, tradeValue.anchorY = 0, 0;
		dg:insert(name)
		dg:insert(overall)
		dg:insert(potential)
		dg:insert(salary)
		dg:insert(tradeValue)
		
		--Player Portrait
		local profile = display.newGroup()
		local portrait = display.newImage("rosters/portraits/" .. playersFrom[i].portrait , 0, 0);
		if (portrait == nil) then --Use generic portrait instead
			portrait = display.newImage("rosters/portraits/A.Generic.png" , 0, 0);
		end
		portrait.anchorX, portrait.anchorY = 0, 0
		portrait.xScale, portrait.alpha = 1, 1;
		
		local mask = graphics.newMask( "Images/portrait_mask.png" )
		portrait:setMask(mask)
		
		profile.anchorChildren = true
		profile.x, profile.y = 0 , 0
		profile:insert(portrait)
		profile.anchorX, profile.anchorY = 0, 0
		profile.xScale, profile.yScale = .4, .4
		dg:insert(profile)
		
		menuScene.confirmTradePopup.elements[#menuScene.confirmTradePopup.elements+1] = dg
		menuScene.confirmTradePopup.scrollView:insert(dg)
	end
	
	yPos = yPos + 50
	
	
	yPos = 10;
	local send = display.newText(cpuTeam.name .. " Get:", 20,yPos, native.systemFont, 20);
	send.anchorX, send.anchorY = 0, 0;
	menuScene.confirmTradePopup.elements[#menuScene.confirmTradePopup.elements+1] = send
	menuScene.confirmTradePopup.scrollView2:insert(send)
	
	for i = 1, #playersTo do
		yPos = 0;
		
		local dg = display.newGroup()
		dg.anchorX, dg.anchorY = 0, 0
		dg.anchorChildren = true
		dg.x, dg.y = 10, (i-1) * 150 + 50
		
		local name = display.newText(playersTo[i].name, 140,10, native.systemFont, 20);
		name.anchorX, name.anchorY = 0, 0;
		local overall = display.newText("Ovr: " .. playersTo[i].overall, 140,35, native.systemFont, 20);
		overall.anchorX, overall.anchorY = 0, 0;
		local potential = display.newText("Pot: " .. playersTo[i].potential, 220,35, native.systemFont, 20);
		potential.anchorX, potential.anchorY = 0, 0;
		local salary = display.newText("$" .. utils:comma_value(playersTo[i].salary) .. 
			" (" .. playersTo[i].years .. " yrs)", 140,60, native.systemFont, 20);
		salary.anchorX, salary.anchorY = 0, 0;
		local value = math.round((tr:determineTradeValue(playersTo[i], day)-playersTo[i].years*playersTo[i].salary)/1000000)
		local tradeValue = display.newText("Trade Value: " .. value, 140,85, native.systemFontBold, 24);
		tradeValue.anchorX, tradeValue.anchorY = 0, 0;
		dg:insert(name)
		dg:insert(overall)
		dg:insert(potential)
		dg:insert(salary)
		dg:insert(tradeValue)
		
		--Player Portrait
		local profile = display.newGroup()
		local portrait = display.newImage("rosters/portraits/" .. playersTo[i].portrait , 0, 0);
		if (portrait == nil) then --Use generic portrait instead
			portrait = display.newImage("rosters/portraits/A.Generic.png" , 0, 0);
		end
		portrait.anchorX, portrait.anchorY = 0, 0
		portrait.xScale, portrait.alpha = 1, 1;
		
		local mask = graphics.newMask( "Images/portrait_mask.png" )
		portrait:setMask(mask)
		
		profile.anchorChildren = true
		profile.x, profile.y = 0 , 0
		profile:insert(portrait)
		profile.anchorX, profile.anchorY = 0, 0
		profile.xScale, profile.yScale = .4, .4
		dg:insert(profile)
		
		menuScene.confirmTradePopup.elements[#menuScene.confirmTradePopup.elements+1] = dg
		menuScene.confirmTradePopup.scrollView2:insert(dg)
	end
	
	--Trade and cancel buttons
	local function handleButtonEvent(event)
		local button = event.target.id
		if (event.phase == "ended") then
		if (button == "cancel") then
			scene:destroyConfirmTradePopup()
		elseif (button == "trade") then
			scene:destroyConfirmTradePopup()
			local path = system.pathForFile("data.db", system.DocumentsDirectory)
			db = sqlite3.open( path ) 
			db:exec("BEGIN TRANSACTION;")
			
			local refresh = false;
			local mode, day
			for row in db:nrows([[SELECT * FROM league;]])do
				mode, day = row.mode, row.day
			end
			--Trades only allowed during regular season
			if (mode == "Season") then 
				local result = tr:acceptTrade(playersFrom, playersTo, team2, team1, day)
				local accepted, message = result[1], result[2]
				local playersFromLog = "" --Sent over flurry analytics
				local playersToLog = "" --Sent over flurry analytics
				
				for i = 1, #playersFrom do
					playersFromLog = playersFromLog .. playersFrom[i].name .. " (" .. playersFrom[i].overall .. "), "
				end
				for i = 1, #playersTo do
					playersToLog = playersToLog .. playersTo[i].name .. " (" .. playersTo[i].overall .. "), "
				end
				--print("playersFromLog " .. playersFromLog)
				--print("playersToLog " .. playersToLog)
				
				if (accepted) then
					analytics.logEvent("Trade Accepted", 
						{playersFrom = playersFromLog, playersTo = playersToLog})
					scene:showPopup("Trade accepted - " .. message, 32);
					tr:swapPlayers(playersFrom, playersTo, team2, team1)
					
					--After trade make sure there are enough players on CPU's team
					ss:meetMinRosterReqs(team2, 2, 2, 2, 2, 2, 5, 5, 6)
					--Remove traded players from myTeamLineup  
					ss:clearMyTeamLineup();
					refresh = true
				else
					analytics.logEvent("Trade Declined", 
						{playersFrom = playersFromLog, playersTo = playersToLog})
					scene:showPopup("Trade declined - " ..message, 32);
				end
			else
				scene:showPopup("Trade deadline past.", 32);
			end
			
		
			db:exec("END TRANSACTION;")
			db:close();
			
			if (refresh) then
				--Refresh trade screen after trade to reflect trade
				scene:destroyTradePage()
				scene:showTradePage()
			end
		
		end
		end
	end
	local options = {
		width = 100,
		height = 50,
		numFrames = 4,
		sheetContentWidth = 200,
		sheetContentHeight = 100
	}
	local buttonSheet = graphics.newImageSheet( "Images/trade_menu.png", options )
	
	local trade = widget.newButton
	{
		id = "trade",
		sheet = buttonSheet,
		defaultFrame = 1,
		overFrame = 2,
		onEvent = handleButtonEvent
	}
	trade.anchorX, trade.anchorY = 1,1;
	trade.x = display.contentWidth;
	trade.y = display.contentHeight;
	menuScene.confirmTradePopup.elements[#menuScene.confirmTradePopup.elements+1] = trade
	
	local cancel = widget.newButton
	{
		id = "cancel",
		sheet = buttonSheet,
		defaultFrame = 3,
		overFrame = 4,
		onEvent = handleButtonEvent
	}
	cancel.anchorX, cancel.anchorY = 1,1;
	cancel.x = trade.x - trade.width - 5;
	cancel.y = display.contentHeight;
	menuScene.confirmTradePopup.elements[#menuScene.confirmTradePopup.elements+1] = cancel

end

function scene:destroyConfirmTradePopup()
	
	
	for i = 1, #menuScene.confirmTradePopup.elements do
		if (menuScene.confirmTradePopup.elements[i] ~= nil) then
			menuScene.confirmTradePopup.elements[i]:removeSelf();
			menuScene.confirmTradePopup.elements[i] = nil;
		end
	end
	menuScene.confirmTradePopup.elements = {};
	
	if (menuScene.confirmTradePopup.bg ~= nil) then
		menuScene.confirmTradePopup.bg:removeSelf();
		menuScene.confirmTradePopup.bg = nil
	end
	
	if (menuScene.confirmTradePopup.scrollView ~= nil) then
		menuScene.confirmTradePopup.scrollView:removeSelf();
		menuScene.confirmTradePopup.scrollView = nil
	end
	
	if (menuScene.confirmTradePopup.scrollView2 ~= nil) then
		menuScene.confirmTradePopup.scrollView2:removeSelf();
		menuScene.confirmTradePopup.scrollView2 = nil
	end

	
end


--Lineup Popup
function scene:showLineupPopup2(team1, team1_lineup, team2, team2_lineup)
	
	--Semi-transparent black background that covers whole screen and blocks touches
	local black = display.newImage("Images/black.png", 0, 0);
	black.width, black.height = display.contentWidth, display.contentHeight
	black.anchorX, black.anchorY = 0,0
	black.alpha = .9;
	
	local function blockTouches(event)
		return true; --Block the propagation of any touches or taps
	end
	black:addEventListener("tap", blockTouches);
	black:addEventListener("touch", blockTouches);
	menuScene.lineupPopup.bg  = black;

	--Ghost element
	local topLabel = display.newText("", 0, 0, native.systemFont, 36);
	menuScene.lineupPopup.elements[#menuScene.lineupPopup.elements+1] = topLabel;
	
	--Team info (team being shown)
	local team_lineup = team1_lineup
	local team = team1

	--Team Name
	local teamName, teamAbv
	local yPos = 10
	local xPos = 180
	
	local path = system.pathForFile("data.db", system.DocumentsDirectory)
	db = sqlite3.open( path )   
	for row in db:nrows([[SELECT * FROM teams WHERE id = ]] .. team .. [[;]]) do 
		teamName = row.name
		teamAbv = row.abv
	end
	db:close()
	
	local team_name = display.newText(teamName, xPos, yPos, native.systemFont, 24);
	team_name.anchorX, team_name.anchorY = .5, 0;
	menuScene.lineupPopup.elements[#menuScene.lineupPopup.elements+1] = team_name;
	yPos = yPos + 75;

	
	local mode = "lineup"
	
	local carousel
	local swipeHandler
	--Refresh carousel information
	--Either show lineup, starter, bullpen, or bench
	local function refresh()
		
		team_name.text = teamName --.. " " .. mode:gsub("^%l", string.upper)
		
		--Remove everything from carousel
		if (carousel ~= nil) then
			carousel:removeSelf()
			carousel = nil
		end
		if (swipeHandler ~= nil) then
			black:removeEventListener( "touch", swipeHandler)
			swipeHandler = nil
		end
		
		
		--Display group that shows lineup in a carousel format
		carousel = display.newGroup()
		
		local buffer = 400; --Margin between each element in carousel
		local numElements = 0; --Number of elements in the carousel
		local curElement = 1; --Current element being shown
		local carouselPositions = {}; --Different x positions that carousel can switch between (x position corresponding to each element)
		local lineupDG = {}; --Stores display groups for each player in lineup
		
		--Generate list of information shown in carousel
		local list = {}
		if (mode == "lineup") then
			list = {team_lineup.first, team_lineup.second, team_lineup.short, team_lineup.third, 
				team_lineup.catcher, team_lineup.left, team_lineup.center, team_lineup.right, team_lineup.dh}
			local function battingOrderSort(a,b)
			  return a.batting_order < b.batting_order
			end
			table.sort(list, battingOrderSort)
		elseif (mode == "starter") then
			--list = {team_lineup.sp}
			
			local path = system.pathForFile("data.db", system.DocumentsDirectory)
			db = sqlite3.open( path )   

			--Get entire starting rotation
			for row in db:nrows([[SELECT * FROM players WHERE teamid = ]] .. team .. [[ AND posType = "SP" AND injury = 0
				ORDER BY overall DESC LIMIT 5;]]) do 
				list[#list+1] = row;
			end
			db:close()
			
			local matchedStarter = false
			for i = 1, #list do
				if (list[i].id == team_lineup.sp.id) then
					curElement = i
					matchedStarter = true
					break
				end
			end
			
			if (not matchedStarter) then
				list[#list+1] = team_lineup.sp
				curElement = #list
			end
			
		elseif (mode == "bullpen") then
			list[#list+1] = team_lineup.closer;
			for i=1, #team_lineup.bullpen do
				list[#list+1] = team_lineup.bullpen[i]
			end
			
		elseif (mode == "bench") then
			for i=1, #team_lineup.bullpen do
				list[#list+1] = team_lineup.bench[i]
			end
		end
		numElements = #list
		
		for i = 1, #list do
			local player = list[i]
			player.info1 = i .. ". " .. player.name
			player.info2 = "Ovr: " .. player.overall .. "  Pot: " .. player.potential
			player.info3 = ""
			if (mode == "lineup" or mode == "bench") then
				if (player.id == team_lineup.dh.id) then
					player.info1 = player.info1  .. " (DH)"
				elseif (player.id == team_lineup.left.id) then
					player.info1 = player.info1  .. " (LF)"
				elseif (player.id == team_lineup.center.id) then
					player.info1 = player.info1  .. " (CF)"
				elseif (player.id == team_lineup.right.id) then
					player.info1 = player.info1  .. " (RF)"
				else
					player.info1 = player.info1  .. " (" .. player.posType .. ")"
				end
				local avg = string.format("%.3f",player.AVG)
				if(string.sub(avg, 1,1) == "0") then --Remove leading 0, if any
					avg = string.sub(avg, 2)
				end
				player.info3 = "AVG:  " .. avg .. "  HR:  " .. player.HR .. "  RBI:  " .. player.RBI
			end
			if (mode == "starter") then
				player.info1 = player.info1  .. " (" .. player.P_W .. "-" .. player.P_L .. ")"
				local era = string.format("%.3f",player.P_ERA)
				local whip = string.format("%.3f",player.P_WHIP)
				
				player.info3 = "ERA:  " .. era .. "  WHIP:  " .. whip .. "  K:  " .. player.P_SO
			end
			if (mode == "bullpen") then
				if (i == 1) then player.info1 = player.info1  .. " (CL)" end
				local era = string.format("%.3f",player.P_ERA)
				local whip = string.format("%.3f",player.P_WHIP)
				
				player.info3 = "ERA:  " .. era .. "  WHIP:  " .. whip .. "  K:  " .. player.P_SO 
				if (player.P_SV > 0) then 
					player.info3 = player.info3 .. "  SV:  " .. player.P_SV
				end
			end
			
		end
		
		for i = 1, numElements do
			local player = list[i]
			
			local dg = display.newGroup()
			
			--Player Portrait
			local profile = display.newGroup()
			local teamLogo = display.newImage("rosters/teams/" .. teamName .. ".png" 
				, -80, -50);
			if (teamLogo == nil) then
				teamLogo = display.newImage("rosters/teams/GENERIC.png", -80, -50);
			end
			teamLogo.xScale, teamLogo.yScale = .5, .5
			teamLogo.alpha = .5

			local portrait = display.newImage("rosters/portraits/" .. player.portrait , 0, 0);
			if (portrait == nil) then --Use generic portrait instead
				portrait = display.newImage("rosters/portraits/A.Generic.png" , 0, 0);
			end
			portrait.xScale, portrait.alpha = 1, 1;
			
			local mask = graphics.newMask( "Images/portrait_mask.png" )
			portrait:setMask(mask)
			
			profile.anchorChildren = true
			profile.x, profile.y = (i-1) * buffer , -50
			profile.xScale, profile.yScale = .8, .8
			profile:insert(teamLogo)
			profile:insert(portrait)
			
			dg:insert(profile)
			
			
			--Stats/Info
			local function tap()
				scene:showPlayerCardPopup(player.id)
			end
			local info1 = display.newText(player.info1, (i-1) * buffer, 50, native.systemFont, 24);
			info1:addEventListener("tap", tap)
			dg:insert(info1)
			local info2 = display.newText(player.info2, (i-1) * buffer, 90, native.systemFont, 24);
			dg:insert(info2)
			local info3 = display.newText(player.info3, (i-1) * buffer, 130, native.systemFont, 20);
			dg:insert(info3)
			
			
			lineupDG[#lineupDG+1] = dg

			carousel:insert( dg )
			carouselPositions[#carouselPositions+1] = (i) * buffer;
		end
		

		carousel.anchorX, carousel.anchorY = 0,.5
		carousel.x, carousel.y = display.contentCenterX-carouselPositions[curElement], display.contentCenterY;	
			
		
		-- Insert the carousel into a container
		local container = display.newContainer( display.contentWidth, display.contentHeight ) --Prevents text from bleeding into "letterbox edges"
		-- Center the container in the display area
		container:translate( display.contentWidth*0.5, display.contentHeight*0.5 )
		container:insert( carousel, true )
		
		carousel.x = display.contentCenterX-carouselPositions[curElement]
		
		
		
		
		
		--Highlight current element. Dim other elements.
		local function highlight()
			for i = 1, #lineupDG do
				lineupDG[i].alpha = 0.3
			end
			lineupDG[curElement].alpha = 1
		end
		highlight()
		
		local origElement = 0; --Original element being shown before swipe
		local prevCurElement = 0; --For smoother swiping
		swipeHandler = function( event )
			if ( event.phase == "began") then
				origElement = curElement
				prevCurElement = curElement
				
			elseif ( event.phase == "moved" ) then
				local dX = event.x - event.xStart
				local sensitivity = 50 --Lower number = higher carousel swipe sensitivity
				local transitionTime = 250 --Time for each carousel transition
				local carousel_shift = math.floor(dX / sensitivity)
				
				curElement = origElement - carousel_shift
				if (curElement < 1) then curElement = 1 end
				if (curElement > numElements) then curElement = numElements end
				
				print("curElement: " .. curElement);
				if (curElement ~= prevCurElement) then --Smoother swiping, b/c no reloading of transitions during multiple "move" phases
					prevCurElement = curElement
					highlight()
					transition.to( carousel, { time=transitionTime, x=display.contentCenterX-carouselPositions[curElement] } )
				end
			elseif ( event.phase == "ended" ) then
				--highlight()
			end
			return true
		end
		
		black:addEventListener( "touch", swipeHandler)
		menuScene.lineupPopup.elements[#menuScene.lineupPopup.elements+1] = carousel

		
	end
	refresh()
	
	--Lineup menu buttons : lineup, starter, bullpen, bench
	local options = {
		width = 100,
		height = 40,
		numFrames = 8,
		sheetContentWidth = 200,
		sheetContentHeight = 160
	}
	local buttonSheet = graphics.newImageSheet( "Images/lineup.png", options )
	local buttons = {}
	
	local function handleButtonEvent(event)
		if (event.phase == "ended") then
			mode = event.target.id
			refresh()
		end
		return true
	end
	
	for i = 1, 4 do
		local buttonID = ""
		if (i == 1) then buttonID = "lineup"
		elseif (i == 2) then buttonID = "starter"
		elseif (i == 3) then buttonID = "bullpen"
		elseif (i == 4) then buttonID = "bench"
		end
		local button = widget.newButton
		{
			id = buttonID,
			sheet = buttonSheet,
			defaultFrame = 2*i-1,
			overFrame = 2*i,
			onEvent = handleButtonEvent
		}
		buttons[i] = button
		menuScene.lineupPopup.elements[#menuScene.lineupPopup.elements+1] = button;
	end
	
	local xPos = display.contentWidth
	local buttonBuffer = 10 --Space between each button
	for i = #buttons, 1,-1  do
		local button = buttons[i]
		button.anchorX, button.anchorY = 1, 0
		button.x, button.y = xPos-buttonBuffer, 5
		xPos = xPos - button.width
	end
	
	
	
	--If there are two teams, add a flip button so you can flip between team lineups
	if (team2 ~= nil) then
	local function flip(event)
		if (event.phase ~= "ended") then return end
		if (team == team1) then
			team_lineup = team2_lineup
			team = team2
		else
			team_lineup = team1_lineup
			team = team1
		end

		local path = system.pathForFile("data.db", system.DocumentsDirectory)
		db = sqlite3.open( path )   
		for row in db:nrows([[SELECT * FROM teams WHERE id = ]] .. team .. [[;]]) do 
			teamName = row.name
			teamAbv = row.abv
		end
		db:close()
		
		refresh()
		
	end
	local options = {
		width = 50,
		height = 50,
		numFrames = 2,
		sheetContentWidth = 100,
		sheetContentHeight = 50
	}
	local buttonSheet = graphics.newImageSheet( "Images/flip.png", options )
	local button = widget.newButton
		{
			id = "",
			sheet = buttonSheet,
			defaultFrame = 1,
			overFrame = 2,
			onEvent = flip
		}
	button.x,button.y = 5,5
	button.width, button.height = 40,40
	button.anchorX, button.anchorY = 0,0
	menuScene.lineupPopup.elements[#menuScene.lineupPopup.elements+1] = button
	end
	
	--Exit button
	local function destroy(event)
		if (event.phase == "ended") then scene:destroyLineupPopup(); end
	end
	menuScene.lineupPopup.exit = widget.newButton
	{
		x = display.contentWidth,
		y = display.contentHeight,
		defaultFile = "Images/x.png",
		onEvent = destroy
	}
	menuScene.lineupPopup.exit.anchorX, menuScene.lineupPopup.exit.anchorY = 1, 1; 
	

end

function scene:destroyLineupPopup()
	
	
	for i = 1, #menuScene.lineupPopup.elements do
		if (menuScene.lineupPopup.elements[i] ~= nil) then
			menuScene.lineupPopup.elements[i]:removeSelf();
			menuScene.lineupPopup.elements[i] = nil;
		end
	end
	menuScene.lineupPopup.elements = {};
	
	if (menuScene.lineupPopup.bg ~= nil) then
		menuScene.lineupPopup.bg:removeSelf();
		menuScene.lineupPopup.bg = nil
	end
	
	if (menuScene.lineupPopup.scrollView ~= nil) then
		menuScene.lineupPopup.scrollView:removeSelf();
		menuScene.lineupPopup.scrollView = nil
	end

	if (menuScene.lineupPopup.exit ~= nil) then
		menuScene.lineupPopup.exit:removeSelf();
		menuScene.lineupPopup.exit = nil
	end
	
end

--Edit Lineup Page
function scene:showEditLineupPopup(teamid)
	
	--Semi-transparent black background that covers whole screen and blocks touches
	local black = display.newImage("Images/black.png", 0, 0);
	black.width, black.height = display.contentWidth, display.contentHeight
	black.anchorX, black.anchorY = 0,0
	black.alpha = .9;
	
	local function blockTouches(event)
		return true; --Block the propagation of any touches or taps
	end
	black:addEventListener("tap", blockTouches);
	black:addEventListener("touch", blockTouches);
	menuScene.editLineupPopup.bg  = black;

	local labels = {"1B", "2B", "SS", "3B", "C", "LF", "CF", "RF", "DH", "PH", "PH", "PH", 
		"SP1", "SP2", "SP3", "SP4", "SP5", "RP", "RP", "RP", "RP", "RP", "CL"}
	
	local function changeSelectedPos(event)
		for i = 1, #menuScene.editLineupPopup.positionLabels do
			--Deselect other position labels
			menuScene.editLineupPopup.positionLabels[i]:setFillColor(1,1,1);
		end
		event.target:setFillColor(1,0,0);
		menuScene.editLineupPopup.positionSelected = event.target.id; --Change the position selected
		scene:editLineupRefreshAvailablePlayers(teamid,  menuScene.editLineupPopup.positionSelected);
		--Scroll to top of scroll view
		menuScene.editLineupPopup.scrollView2:scrollTo( "top", { time=0} )	
		return true;
	end
	
	--First base position is initially selected
	menuScene.editLineupPopup.positionSelected = 1;
	
	--Create position labels
	for i = 1, #labels do
		local position = display.newText(labels[i], 10, 10 + (50 * (i - 1)), native.systemFont, 24);
		position.id = i;
		position.anchorX, position.anchorY = 0,0
		position:addEventListener("tap", changeSelectedPos);
		if (i == menuScene.editLineupPopup.positionSelected) then
			position:setFillColor(1,0,0);
		end
		menuScene.editLineupPopup.positionLabels[i] = position
	
	end
	
	--Create the name labels
	for i = 1, #labels do
	
		--Show player card when the name is clicked
		local function tap(event)
			if (event.target.id ~= nil) then
				scene:showPlayerCardPopup(event.target.id);
			end
			return true;
		end
		
		local playerName = display.newText("", 70, 10 + (50 * (i - 1)), native.systemFont, 20);
		playerName.anchorX, playerName.anchorY = 0,0
		playerName:addEventListener("tap", tap);
		menuScene.editLineupPopup.positionNames[i] = playerName
		
		--Injury label corresponding with each player, only show if injury > 0
		local injuryLabel =  display.newImage("Images/injury.png", playerName.x + playerName.width + 10, playerName.y + playerName.height/2)
		injuryLabel.anchorX, injuryLabel.anchorY = 0, .5;
		injuryLabel.alpha = 0;
		injuryLabel.width, injuryLabel.height = playerName.height, playerName.height
		menuScene.editLineupPopup.elements[#menuScene.editLineupPopup.elements+1] = injuryLabel
		
		playerName.injuryLabel = injuryLabel; --Have a reference
	
	end
	
	--Create the 9 batting order steppers (Determine lineup's batting order)
	--Need only 9 because there are nine batters in a game
	
	for i = 1, 9 do
		local function changeOrder(event)
		
		local num = event.target.text
		num = (num:gsub("^%s*(.-)%s*$", "%1")) --Trim white space in string

		if (num == "CPU") then
			num = 1
		else
			num = tonumber(num);
			if (num >= 9) then
				num = "CPU"
			else
				num = num + 1
			end
		end
		 --Add extra whitespace so it will be easier for user to tap
		 event.target.text = num .. "       "
		return true
		end
	
		menuScene.editLineupPopup.battingOrderDisplays[i] = display.newText("CPU", 350, 10 + (50 * (i - 1)), native.systemFont, 20 )
		menuScene.editLineupPopup.battingOrderDisplays[i].anchorX,  menuScene.editLineupPopup.battingOrderDisplays[i].anchorY = 0, 0;
		menuScene.editLineupPopup.battingOrderDisplays[i]:setFillColor(.8,.8,.8); 
		
		menuScene.editLineupPopup.battingOrderDisplays[i]:addEventListener("tap", changeOrder);
	end
	
	--Add all the elements to a scroll view
	menuScene.editLineupPopup.scrollView = widget.newScrollView {
		backgroundColor = { 0, 1, 0, 0 },
		x = 0,
		y = 0,
		width = 400,
		height = display.contentHeight,
		horizontalScrollDisabled = true,
		verticalScrollDisabled = false
	  }
	menuScene.editLineupPopup.scrollView.anchorX, menuScene.editLineupPopup.scrollView.anchorY = 0,0;
	
	--Ghost element (need this so that scroll view doesn't accidentally cut content off)
	local topLabel = display.newText("", 0, 0, native.systemFont, 36);
	menuScene.editLineupPopup.scrollView:insert(topLabel);
	
	menuScene.editLineupPopup.scrollView2 = widget.newScrollView {
		backgroundColor = { 1, 0, 0, 0 },
		x = 400,
		y = 0,
		width = 400,
		height = display.contentHeight-50,
		horizontalScrollDisabled = true,
		verticalScrollDisabled = false
	  }
	menuScene.editLineupPopup.scrollView2.anchorX, menuScene.editLineupPopup.scrollView2.anchorY = 0,0;
	
	--Ghost element (need this so that scroll view doesn't accidentally cut content off)
	local topLabel = display.newText("", 0, 0, native.systemFont, 36);
	menuScene.editLineupPopup.scrollView2:insert(topLabel);
	
	for i = 1, #menuScene.editLineupPopup.elements do
		menuScene.editLineupPopup.scrollView:insert(menuScene.editLineupPopup.elements[i]);
	end
	
	for i = 1, #menuScene.editLineupPopup.positionLabels do
		menuScene.editLineupPopup.scrollView:insert(menuScene.editLineupPopup.positionLabels[i]);
	end
	
	for i = 1, #menuScene.editLineupPopup.positionNames do
		menuScene.editLineupPopup.scrollView:insert(menuScene.editLineupPopup.positionNames[i]);
	end
	
	for i = 1, #menuScene.editLineupPopup.battingOrderDisplays do
		menuScene.editLineupPopup.scrollView:insert(menuScene.editLineupPopup.battingOrderDisplays[i]);
	end
	
	
	--Line Dividing Scroll Views
	local line = display.newLine( 400,0,400,480);
	line:setStrokeColor( 1, 1, 1, .5 )
	line.strokeWidth = 3
	menuScene.editLineupPopup.elements [#menuScene.editLineupPopup.elements +1] = line
	
	--Save and cancel and clear buttons
	local function cancelTap(event)
		--Prevent tap events from propagating through buttons
		return true
	end
	
	
	local options = {
		width = 100,
		height = 50,
		numFrames = 6,
		sheetContentWidth = 200,
		sheetContentHeight = 150
	}
	local buttonSheet = graphics.newImageSheet( "Images/save_cancel.png", options )
	
	local function saveFunction(event)
		if (event.phase == "ended") then scene:saveLineup(); end
		return true;
	end
	
	local save = widget.newButton
	{
		id = "save",
		sheet = buttonSheet,
		defaultFrame = 1,
		overFrame = 2,
		onEvent = saveFunction
	}
	save:addEventListener("tap", cancelTap);
	save.anchorX, save.anchorY = 1,1;
	save.x = display.contentWidth;
	save.y = display.contentHeight;
	menuScene.editLineupPopup.elements[#menuScene.editLineupPopup.elements+1] = save
	
	local function cancel(event)
		if (event.phase == "ended") then scene:destroyEditLineupPopup(); end
		return true;
	end
	local cancel = widget.newButton
	{
		id = "cancel",
		sheet = buttonSheet,
		defaultFrame = 3,
		overFrame = 4,
		onEvent = cancel
	}
	cancel:addEventListener("tap", cancelTap);
	cancel.anchorX, cancel.anchorY = 1,1;
	cancel.x = save.x - save.width - 5;
	cancel.y = display.contentHeight;
	menuScene.editLineupPopup.elements[#menuScene.editLineupPopup.elements+1] = cancel
	
	scene:editLineupRefreshAvailablePlayers(teamid,  menuScene.editLineupPopup.positionSelected);
	scene:loadLineup(); --Loads saved lineup (if any) for editing
	
	local function clearFunction(event)
		
		if (event.phase == "ended") then
		for i = 1, #menuScene.editLineupPopup.positionNames do
			menuScene.editLineupPopup.positionNames[i].text = "";
			menuScene.editLineupPopup.positionNames[i].id = nil
			menuScene.editLineupPopup.positionNames[i].injuryLabel.alpha = 0;
		end
		for i = 1, #menuScene.editLineupPopup.battingOrderDisplays do
			menuScene.editLineupPopup.battingOrderDisplays[i].text = "CPU";
		end
		end
		return true;
	end
	
	local clear = widget.newButton
	{
		id = "clear",
		sheet = buttonSheet,
		defaultFrame = 5,
		overFrame = 6,
		onEvent = clearFunction
	}

	clear:addEventListener("tap", cancelTap);
	clear.anchorX, clear.anchorY = 1,1;
	clear.x = cancel.x - cancel.width - 5;
	clear.y = display.contentHeight;
	menuScene.editLineupPopup.elements[#menuScene.editLineupPopup.elements+1] = clear

end

function scene:loadLineup()
	
	local lineup;
	local path = system.pathForFile("data.db", system.DocumentsDirectory)
	db = sqlite3.open( path ) 

	for row in db:nrows([[SELECT * FROM myteam]])do
		lineup = row.customLineup
	end
	
	
	if (lineup ~= nil) then
		lineup = json.decode(lineup);
		for i = 1, #lineup do
		
			--Insert player names into the lineup
			if (lineup[i].id ~= nil) then --Cannot show player if id is nil
				local player
				for row in db:nrows([[SELECT * FROM players WHERE id = ]] .. lineup[i].id)do
					player = row
				end
				menuScene.editLineupPopup.positionNames[i].text = player.name;
				if (player.injury > 0) then --Show injury label next to player name
					menuScene.editLineupPopup.positionNames[i].injuryLabel.x = menuScene.editLineupPopup.positionNames[i].x + menuScene.editLineupPopup.positionNames[i].width + 10
					menuScene.editLineupPopup.positionNames[i].injuryLabel.alpha = 1;
				else
					menuScene.editLineupPopup.positionNames[i].injuryLabel.alpha = 0;
				end
				menuScene.editLineupPopup.positionNames[i].id = player.id
			end
			
			--Display the batting order
			if (lineup[i].batting_order ~= nil) then --Cannot show batting order if nil
				menuScene.editLineupPopup.battingOrderDisplays[i].text = lineup[i].batting_order
			end
		end
	
	end
	
	
	db:close();	
	
end

function scene:saveLineup()
	print("Saving Lineup");
	local canSaveLineup, reason = true, "None";
	
	--Make sure there are no duplicate players
	if (canSaveLineup) then
	local ids = {}
	local duplicates = false;
	for i = 1, #menuScene.editLineupPopup.positionNames do
		ids[#ids+1] = menuScene.editLineupPopup.positionNames[i].id;
	end
	

	for j=0, #ids do
		for k=j+1, #ids do
			if (k~=j and ids[k] == ids[j]) then
				 duplicates=true;
				 break;
			end
		end
		if (duplicates) then
			break
		end
	end
	
	if (duplicates) then
		canSaveLineup = false;
		reason = "Duplicate players"
	end
	end

	
	--Make sure there are no duplicate batting orders (Except "CPU")
	if (canSaveLineup) then
	local orders = {}
	local duplicates = false;
	for i = 1, #menuScene.editLineupPopup.battingOrderDisplays do
		local text = (menuScene.editLineupPopup.battingOrderDisplays[i].text:gsub("^%s*(.-)%s*$", "%1")) --Trim text
		if (text ~= "CPU") then
			orders[#orders+1] = text;
		end
	end
	
	for j=0, #orders do
		for k=j+1, #orders do
			if (k~=j and orders[k] == orders[j]) then
				 duplicates=true;
				 break;
			end
		end
		if (duplicates) then
			break
		end
	end
	
	if (duplicates) then
		canSaveLineup = false;
		reason = "Duplicate batting orders"
	end
	end
       
	--Save Lineup  
	if (canSaveLineup) then
		--Save the lineup
		local lineup = {}
		for i = 1, #menuScene.editLineupPopup.positionNames do
			--Stores the player ids in sequential order ("1B", "2B", "SS", "3B", "C", "LF", "CF", "RF", DH, PH, PH, PH, SP1,...)
			if (menuScene.editLineupPopup.battingOrderDisplays[i] ~= nil) then
				local text = (menuScene.editLineupPopup.battingOrderDisplays[i].text:gsub("^%s*(.-)%s*$", "%1")) --Trim text
				lineup[#lineup+1] = {id = menuScene.editLineupPopup.positionNames[i].id, batting_order = text}
			else
				lineup[#lineup+1] = {id = menuScene.editLineupPopup.positionNames[i].id}
			end
		end
		local result = json.encode(lineup);
		local path = system.pathForFile("data.db", system.DocumentsDirectory)
		db = sqlite3.open( path ) 
		
		--Record custom lineup into database
		local stmt= db:prepare[[ UPDATE myteam SET customLineup = ?]];
		stmt:bind_values(result) 
		stmt:step();
		
		--Destroy edit lineup popup
		scene:destroyEditLineupPopup(); 
		--Show confirm saved popup
		scene:showPopup("Lineup Saved!", 24);
		
		db:close();
		
	else
		scene:showPopup(reason,24);
	end
end

function scene:editLineupRefreshAvailablePlayers(teamid, position)

	--Remove All Available Players Elements
	for i = 1, #menuScene.editLineupPopup.availablePlayersElements do
		if (menuScene.editLineupPopup.availablePlayersElements[i] ~= nil) then
			menuScene.editLineupPopup.availablePlayersElements[i]:removeSelf()
			menuScene.editLineupPopup.availablePlayersElements[i] = nil
		end
	end
	menuScene.editLineupPopup.availablePlayersElements = {}
	
	local posType; --Filter players by a certain position
	local positionLabel = menuScene.editLineupPopup.positionLabels[position].text; --Get the label that the index 'position' refers to
	if (positionLabel == "SP1" or positionLabel == "SP2" or positionLabel == "SP3" or positionLabel == "SP4" or positionLabel == "SP5") then
		posType = [[posType = "SP"]]
	elseif (positionLabel == "RF" or positionLabel == "CF" or positionLabel == "LF") then
		posType = [[posType = "OF"]]
	elseif (positionLabel == "DH" or positionLabel == "PH") then
		posType = [[posType != "SP" AND posType != "RP"]]
	elseif (positionLabel == "CL") then
		posType = [[posType = "RP"]]
	else
		posType = [[posType = "]] .. positionLabel .. [["]];
	end

	local path = system.pathForFile("data.db", system.DocumentsDirectory)
	db = sqlite3.open( path )   
	
	
	local nameLabel = display.newText("Name", 60, 10, native.systemFont, 20);
	nameLabel.anchorX, nameLabel.anchorY = 0,0
	menuScene.editLineupPopup.availablePlayersElements[#menuScene.editLineupPopup.availablePlayersElements+1] = nameLabel
	
	local ovrLabel = display.newText("Overall", 310, 10, native.systemFont, 20);
	ovrLabel.anchorX, ovrLabel.anchorY = 0,0
	menuScene.editLineupPopup.availablePlayersElements[#menuScene.editLineupPopup.availablePlayersElements+1] = ovrLabel
	
	local n = 1;
	for row in db:nrows([[SELECT * FROM players WHERE teamid = ]] .. teamid .. [[ AND ]] .. posType .. [[ ORDER BY overall DESC;]])do
		--print("Player @ position: " .. row.name);
		
		--Show player card when the name is clicked
		local function tapName(event)
			scene:showPlayerCardPopup(row.id);
			return true;
		end
		local playerName = display.newText(row.name, 60, 10 + (50 * (n)), native.systemFont, 20);
		playerName.anchorX, playerName.anchorY = 0,0
		playerName:addEventListener("tap", tapName);
		menuScene.editLineupPopup.availablePlayersElements[#menuScene.editLineupPopup.availablePlayersElements+1] = playerName
		
		--Insert player into lineup
		local function tap(event)
			menuScene.editLineupPopup.positionNames[position].text = row.name
			menuScene.editLineupPopup.positionNames[position].id = row.id
			if (row.injury > 0) then
				menuScene.editLineupPopup.positionNames[position].injuryLabel.x = menuScene.editLineupPopup.positionNames[position].x + menuScene.editLineupPopup.positionNames[position].width + 10
				menuScene.editLineupPopup.positionNames[position].injuryLabel.alpha = 1;
			else
				menuScene.editLineupPopup.positionNames[position].injuryLabel.alpha = 0;
			end
			return true;
		end
		
		local assign =  display.newImage("Images/left.png", 10, 10 + (50 * (n)))
		assign.anchorX, assign.anchorY = 0, 0;
		assign.width, assign.height = playerName.height, playerName.height
		assign:addEventListener("tap", tap);
		menuScene.editLineupPopup.availablePlayersElements[#menuScene.editLineupPopup.availablePlayersElements+1] = assign
		
		if (row.injury > 0) then
			local injuryLabel =  display.newImage("Images/injury.png", playerName.x + playerName.width + 10, playerName.y + playerName.height/2)
			injuryLabel.anchorX, injuryLabel.anchorY = 0, .5;
			injuryLabel.width, injuryLabel.height = playerName.height, playerName.height
			menuScene.editLineupPopup.availablePlayersElements[#menuScene.editLineupPopup.availablePlayersElements+1] = injuryLabel
		end
		
		
		local playerOverall = display.newText(row.overall, 310, 10 + (50 * (n)), native.systemFont, 20);
		playerOverall.anchorX, playerOverall.anchorY = 0,0
		menuScene.editLineupPopup.availablePlayersElements[#menuScene.editLineupPopup.availablePlayersElements+1] = playerOverall
		
		n = n + 1;
	end
	
	--Add all the available player elements to scrollView2
	for i = 1, #menuScene.editLineupPopup.availablePlayersElements do
		menuScene.editLineupPopup.scrollView2:insert(menuScene.editLineupPopup.availablePlayersElements[i]);
	end
	
	
	
	db:close();

end

function scene:destroyEditLineupPopup()

	for i = 1, #menuScene.editLineupPopup.elements do
		if (menuScene.editLineupPopup.elements[i] ~= nil) then
			menuScene.editLineupPopup.elements[i]:removeSelf();
			menuScene.editLineupPopup.elements[i] = nil;
		end
	end
	menuScene.editLineupPopup.elements = {};
	
	for i = 1, #menuScene.editLineupPopup.availablePlayersElements do
		if (menuScene.editLineupPopup.availablePlayersElements[i] ~= nil) then
			menuScene.editLineupPopup.availablePlayersElements[i]:removeSelf()
			menuScene.editLineupPopup.availablePlayersElements[i] = nil
		end
	end
	menuScene.editLineupPopup.availablePlayersElements = {}
	
	for i = 1, #menuScene.editLineupPopup.positionLabels do
		if (menuScene.editLineupPopup.positionLabels[i] ~= nil) then
			menuScene.editLineupPopup.positionLabels[i]:removeSelf()
			menuScene.editLineupPopup.positionLabels[i] = nil
		end
	end
	menuScene.editLineupPopup.positionLabels = {}
	
	for i = 1, #menuScene.editLineupPopup.positionNames do
		if (menuScene.editLineupPopup.positionNames[i] ~= nil) then
			menuScene.editLineupPopup.positionNames[i]:removeSelf()
			menuScene.editLineupPopup.positionNames[i] = nil
		end
	end
	menuScene.editLineupPopup.positionNames = {}
	
	for i = 1, #menuScene.editLineupPopup.battingOrderDisplays do
		if (menuScene.editLineupPopup.battingOrderDisplays[i] ~= nil) then
			menuScene.editLineupPopup.battingOrderDisplays[i]:removeSelf()
			menuScene.editLineupPopup.battingOrderDisplays[i] = nil
		end
	end
	menuScene.editLineupPopup.battingOrderDisplays = {}
	
	
	if (menuScene.editLineupPopup.bg ~= nil) then
		menuScene.editLineupPopup.bg:removeSelf();
		menuScene.editLineupPopup.bg = nil
	end
	
	if (menuScene.editLineupPopup.scrollView ~= nil) then
		menuScene.editLineupPopup.scrollView:removeSelf();
		menuScene.editLineupPopup.scrollView = nil
	end
	
	if (menuScene.editLineupPopup.scrollView2 ~= nil) then
		menuScene.editLineupPopup.scrollView2:removeSelf();
		menuScene.editLineupPopup.scrollView2 = nil
	end

	if (menuScene.editLineupPopup.exit ~= nil) then
		menuScene.editLineupPopup.exit:removeSelf();
		menuScene.editLineupPopup.exit = nil
	end
	

end


--Boxscore Popup
function scene:showBoxscorePopup(team1_id, team2_id, box)

	--Semi-transparent black background that covers whole screen and blocks touches
	local black = display.newImage("Images/black.png", 0, 0);
	black.width, black.height = display.contentWidth, display.contentHeight
	black.anchorX, black.anchorY = 0,0
	black.alpha = .9;
	
	--Ghost element
	local topLabel = display.newText("", 0, 0, native.systemFont, 36);
	menuScene.boxscorePopup.elements[#menuScene.boxscorePopup.elements+1] = topLabel;
	
	local function blockTouches(event)
		return true; --Block the propagation of any touches or taps
	end
	black:addEventListener("tap", blockTouches);
	black:addEventListener("touch", blockTouches);
	menuScene.boxscorePopup.bg  = black;
	
	--Get team names
	local team1; --Away
	local team2; --Home
	
	local path = system.pathForFile("data.db", system.DocumentsDirectory)
	db = sqlite3.open( path )   
	for row in db:nrows([[SELECT * FROM teams WHERE id = ]] .. team1_id .. [[;]]) do 
		team1 = {name = row.name, abv = row.abv};
	end
	for row in db:nrows([[SELECT * FROM teams WHERE id = ]] .. team2_id .. [[;]]) do 
		team2 = {name = row.name, abv = row.abv};
	end
	db:close();
	
	--Show team names
	local teamsLabel = display.newText(team1.name .. " - " .. team2.name, 10, 10, native.systemFont, 24);
	teamsLabel.anchorX, teamsLabel.anchorY = 0, 0;
	menuScene.boxscorePopup.elements[#menuScene.boxscorePopup.elements+1] = teamsLabel
	
	--Show number of runs scored table
	local away_team_label = display.newText(team1.abv, 20, 120, native.systemFont, 20);
	away_team_label.anchorX, away_team_label.anchorY = 0,0
	menuScene.boxscorePopup.elements[#menuScene.boxscorePopup.elements+1] = away_team_label

	local home_team_label = display.newText(team2.abv, 20, 170, native.systemFont, 20);
	home_team_label.anchorX, home_team_label.anchorY = 0,0
	menuScene.boxscorePopup.elements[#menuScene.boxscorePopup.elements+1] = home_team_label
	
	local total_runs = display.newText("R", (#box.boxscore+2) * 60, 70, native.systemFont, 20);
	total_runs.anchorX, total_runs.anchorY = 0,0
	menuScene.boxscorePopup.elements[#menuScene.boxscorePopup.elements+1] = total_runs
	
	local line = display.newLine( (#box.boxscore+2) * 60-30, total_runs.y, (#box.boxscore+2) * 60-30, home_team_label.y +  home_team_label.height)
	line:setStrokeColor( 1, 1, 1, .5 )
	line.strokeWidth = 3
	menuScene.boxscorePopup.elements[#menuScene.boxscorePopup.elements+1] = line
	
	local away_score = display.newText(box.score1, total_runs.x, away_team_label.y, native.systemFont, 20);
	away_score.anchorX, away_score.anchorY = 0,0
	menuScene.boxscorePopup.elements[#menuScene.boxscorePopup.elements+1] = away_score
	
	local home_score = display.newText(box.score2, total_runs.x, home_team_label.y, native.systemFont, 20);
	home_score.anchorX, home_score.anchorY = 0,0
	menuScene.boxscorePopup.elements[#menuScene.boxscorePopup.elements+1] = home_score

	--Runs scored each inning grid
	for i = 1, #box.boxscore do
		local inning = display.newText(i, (i+1) * 60, total_runs.y, native.systemFont, 20);
		inning.anchorX, inning.anchorY = 0,0
		menuScene.boxscorePopup.elements[#menuScene.boxscorePopup.elements+1] = inning
	
		local top_runs = display.newText(box.boxscore[i].top, (i+1) * 60, away_team_label.y, native.systemFont, 20);
		top_runs.anchorX, top_runs.anchorY = 0,0
		menuScene.boxscorePopup.elements[#menuScene.boxscorePopup.elements+1] = top_runs
		
		local bottom_runs = display.newText(box.boxscore[i].bottom, (i+1) * 60, home_team_label.y, native.systemFont, 20);
		bottom_runs.anchorX, bottom_runs.anchorY = 0,0
		menuScene.boxscorePopup.elements[#menuScene.boxscorePopup.elements+1] = bottom_runs
	end
	
	--Show player card when the name is clicked
	local function tap(event)
		scene:showPlayerCardPopup(event.target.id);
	end
	
	--Batting statistics of away team
	local yPos = home_score.y+home_score.height+100;
	
	local away_team_label2 = display.newText(team1.name .. " (Away)", 20, yPos, native.systemFont, 36);
	away_team_label2.anchorX, away_team_label2.anchorY = 0,0
	menuScene.boxscorePopup.elements[#menuScene.boxscorePopup.elements+1] = away_team_label2
	yPos = yPos + away_team_label2.height + 30;
	
	local labels = {"Hitter", "AB", "R", "H", "RBI", "BB", "SO", "HR", "2B", "3B", "SB", "CS", "AVG", "OBP", "SLG"};
	local labelsX = {50,350,400,450,500,550,600,650,700,750,800,850,950,1050, 1150}
	
	for i = 1, #labels do
		local label = display.newText(labels[i], labelsX[i], yPos, native.systemFont, 20);
		label.anchorX, label.anchorY = 0,0
		menuScene.boxscorePopup.elements[#menuScene.boxscorePopup.elements+1] = label 
	end
	yPos = yPos + 50
	
	scene:sortLineup(box.team1_batting); --Show batters according to batting order
	local count = 1;
	for i = 1, #box.team1_batting do
		
		local player = box.team1_batting[i]
		local data = {player.NAME .. " " .. player.POSITION, player.AB, player.R, player.H, player.RBI, player.BB, player.SO,
			player.HR, player.DOUBLES, player.TRIPLES, player.SB, player.CS, player.AVG, player.OBP, player.SLG}
		
		if (player.PINCH_HITTER) then --Pinch Hitters get the abv PH after them, not their posType
			data[1] = player.NAME .. " (PH-" .. player.PINCH_HITTER_ORDER .. ")";
		else
			local num = display.newText(count .. ".", 20, yPos, native.systemFont, 20);
			num.anchorX, num.anchorY = 0,0
			menuScene.boxscorePopup.elements[#menuScene.boxscorePopup.elements+1] = num 
			
			count = count + 1;
		end
		
		
		
		for i = 1, #data do
			local data_label = display.newText(data[i], labelsX[i], yPos, native.systemFont, 20);
			data_label.anchorX, data_label.anchorY = 0,0
			menuScene.boxscorePopup.elements[#menuScene.boxscorePopup.elements+1] = data_label
			
			if (i == 1) then --Show player card when player's name is tapped
				data_label.id = player.ID
				data_label:setFillColor(.8,.8,.8);
				data_label:addEventListener("tap", tap);
			end
		end
		
		yPos = yPos + 50
	end
	
	--Pitching statistics of away team
	yPos = yPos + 50
	
	labels = {"Pitcher", "IP", "ER", "H", "BB", "SO", "HR", "ERA", "WHIP", "PC-ST"};
	labelsX = {50,350,400,450,500,550,600,700,800,900}
	
	for i = 1, #labels do
		local label = display.newText(labels[i], labelsX[i], yPos, native.systemFont, 20);
		label.anchorX, label.anchorY = 0,0
		menuScene.boxscorePopup.elements[#menuScene.boxscorePopup.elements+1] = label 
	end
	yPos = yPos + 50
	
	for i = 1, #box.team1_pitching do
		
		local player = box.team1_pitching[i]
		local data = {player.NAME .. " " .. player.POSITION, player.IP, player.ER, player.H, player.BB, player.SO,
			player.HR, player.ERA, player.WHIP, player.PITCHES .. "-" .. player.STRIKES}
			
		
		
		local num = display.newText(i .. ".", 20, yPos, native.systemFont, 20);
		num.anchorX, num.anchorY = 0,0
		menuScene.boxscorePopup.elements[#menuScene.boxscorePopup.elements+1] = num 
		
		for i = 1, #data do

			local data_label = display.newText(data[i], labelsX[i], yPos, native.systemFont, 20);
			data_label.anchorX, data_label.anchorY = 0,0
			menuScene.boxscorePopup.elements[#menuScene.boxscorePopup.elements+1] = data_label
			
			if (i == 1) then --Show player card when player's name is tapped
				data_label.id = player.ID
				data_label:setFillColor(.8,.8,.8);
				data_label:addEventListener("tap", tap);
			end
			
			if (i == 1) then --Put win, loss, or save indicator directly after the pitcher's name
				if (player.WIN == true) then
					local data = display.newText(" W", data_label.x+data_label.width, yPos, native.systemFont, 20);
					data.anchorX, data.anchorY = 0,0
					data:setFillColor(1,0,0);
					menuScene.boxscorePopup.elements[#menuScene.boxscorePopup.elements+1] = data 
				elseif (player.LOSS == true) then
					local data = display.newText(" L", data_label.x+data_label.width, yPos, native.systemFont, 20);
					data.anchorX, data.anchorY = 0,0
					data:setFillColor(1,0,0);
					menuScene.boxscorePopup.elements[#menuScene.boxscorePopup.elements+1] = data 
				elseif (player.SAVE == true) then
					local data = display.newText(" SV", data_label.x+data_label.width, yPos, native.systemFont, 20);
					data.anchorX, data.anchorY = 0,0
					data:setFillColor(1,0,0);
					menuScene.boxscorePopup.elements[#menuScene.boxscorePopup.elements+1] = data 
				end
			end
		end
		
		
		
		yPos = yPos + 50
	end
	
	
	
	--Batting statistics of home team
	yPos = yPos + 50;
	
	local away_team_label3 = display.newText(team2.name .. " (Home)", 20, yPos, native.systemFont, 36);
	away_team_label3.anchorX, away_team_label3.anchorY = 0,0
	menuScene.boxscorePopup.elements[#menuScene.boxscorePopup.elements+1] = away_team_label3
	yPos = yPos + away_team_label3.height + 30;
	
	local labels = {"Hitter", "AB", "R", "H", "RBI", "BB", "SO", "HR", "2B", "3B", "SB", "CS", "AVG", "OBP", "SLG"};
	local labelsX = {50,350,400,450,500,550,600,650,700,750,800,850,950,1050, 1150}
	
	for i = 1, #labels do
		local label = display.newText(labels[i], labelsX[i], yPos, native.systemFont, 20);
		label.anchorX, label.anchorY = 0,0
		menuScene.boxscorePopup.elements[#menuScene.boxscorePopup.elements+1] = label 
	end
	yPos = yPos + 50
	
	scene:sortLineup(box.team2_batting); --Show batters according to batting order
	
	count = 1;
	for i = 1, #box.team2_batting do
		
		local player = box.team2_batting[i]
		local data = {player.NAME .. " " .. player.POSITION, player.AB, player.R, player.H, player.RBI, player.BB, player.SO,
			player.HR, player.DOUBLES, player.TRIPLES, player.SB, player.CS, player.AVG, player.OBP, player.SLG}
		
		if (player.PINCH_HITTER) then --Pinch Hitters get the abv PH after them, not their posType
			data[1] = player.NAME .. " (PH-" .. player.PINCH_HITTER_ORDER .. ")";
		else
			local num = display.newText(count .. ".", 20, yPos, native.systemFont, 20);
			num.anchorX, num.anchorY = 0,0
			menuScene.boxscorePopup.elements[#menuScene.boxscorePopup.elements+1] = num 
			
			count = count + 1;
		end
		
		for i = 1, #data do
			local data_label = display.newText(data[i], labelsX[i], yPos, native.systemFont, 20);
			data_label.anchorX, data_label.anchorY = 0,0
			menuScene.boxscorePopup.elements[#menuScene.boxscorePopup.elements+1] = data_label
			
			if (i == 1) then --Show player card when player's name is tapped
				data_label.id = player.ID
				data_label:setFillColor(.8,.8,.8);
				data_label:addEventListener("tap", tap);
			end
		end
		
		yPos = yPos + 50
	end
	
	--Pitching statistics of away team
	yPos = yPos + 50
	
	labels = {"Pitcher", "IP", "ER", "H", "BB", "SO", "HR", "ERA", "WHIP", "PC-ST"};
	labelsX = {50,350,400,450,500,550,600,700,800,900}
	
	for i = 1, #labels do
		local label = display.newText(labels[i], labelsX[i], yPos, native.systemFont, 20);
		label.anchorX, label.anchorY = 0,0
		menuScene.boxscorePopup.elements[#menuScene.boxscorePopup.elements+1] = label 
	end
	yPos = yPos + 50
	
	for i = 1, #box.team2_pitching do
		
		local player = box.team2_pitching[i]
		local data = {player.NAME .. " " .. player.POSITION, player.IP, player.ER, player.H, player.BB, player.SO,
			player.HR, player.ERA, player.WHIP, player.PITCHES .. "-" .. player.STRIKES}
		
		local num = display.newText(i .. ".", 20, yPos, native.systemFont, 20);
		num.anchorX, num.anchorY = 0,0
		menuScene.boxscorePopup.elements[#menuScene.boxscorePopup.elements+1] = num 
		
		for i = 1, #data do
			local data_label = display.newText(data[i], labelsX[i], yPos, native.systemFont, 20);
			data_label.anchorX, data_label.anchorY = 0,0
			menuScene.boxscorePopup.elements[#menuScene.boxscorePopup.elements+1] = data_label
			
			if (i == 1) then --Show player card when player's name is tapped
				data_label.id = player.ID
				data_label:setFillColor(.8,.8,.8);
				data_label:addEventListener("tap", tap);
			end
			
			if (i == 1) then --Put win, loss, or save indicator directly after the pitcher's name
				if (player.WIN == true) then
					local data = display.newText(" W", data_label.x+data_label.width, yPos, native.systemFont, 20);
					data.anchorX, data.anchorY = 0,0
					data:setFillColor(1,0,0);
					menuScene.boxscorePopup.elements[#menuScene.boxscorePopup.elements+1] = data 
				elseif (player.LOSS == true) then
					local data = display.newText(" L", data_label.x+data_label.width, yPos, native.systemFont, 20);
					data.anchorX, data.anchorY = 0,0
					data:setFillColor(1,0,0);
					menuScene.boxscorePopup.elements[#menuScene.boxscorePopup.elements+1] = data 
				elseif (player.SAVE == true) then
					local data = display.newText(" SV", data_label.x+data_label.width, yPos, native.systemFont, 20);
					data.anchorX, data.anchorY = 0,0
					data:setFillColor(1,0,0);
					menuScene.boxscorePopup.elements[#menuScene.boxscorePopup.elements+1] = data 
				end
			end
		end
		
		yPos = yPos + 50
	end
	
	
	
	
	
	--Add all the elements to a scroll view
	menuScene.boxscorePopup.scrollView = widget.newScrollView {
		backgroundColor = { 0, 1, 0, 0 },
		x = 0,
		y = 0,
		width = display.contentWidth,
		height = display.contentHeight,
		horizontalScrollDisabled = false,
		verticalScrollDisabled = false
	  }
	menuScene.boxscorePopup.scrollView.anchorX, menuScene.boxscorePopup.scrollView.anchorY = 0,0;
	
	for i = 1, #menuScene.boxscorePopup.elements do
		menuScene.boxscorePopup.scrollView:insert(menuScene.boxscorePopup.elements[i]);
	end
	
	
	
	--Exit button
	local function destroy(event)
		if (event.phase == "ended") then scene:destroyBoxscorePopup(); end
	end
	menuScene.boxscorePopup.exit = widget.newButton
	{
		x = display.contentWidth,
		y = display.contentHeight,
		defaultFile = "Images/x.png",
		onEvent = destroy
	}
	menuScene.boxscorePopup.exit.anchorX, menuScene.boxscorePopup.exit.anchorY = 1, 1; 
	


end

function scene:destroyBoxscorePopup()

	for i = 1, #menuScene.boxscorePopup.elements do
		if (menuScene.boxscorePopup.elements[i] ~= nil) then
			menuScene.boxscorePopup.elements[i]:removeSelf();
			menuScene.boxscorePopup.elements[i] = nil;
		end
	end
	menuScene.boxscorePopup.elements = {};
	
	if (menuScene.boxscorePopup.bg ~= nil) then
		menuScene.boxscorePopup.bg:removeSelf();
		menuScene.boxscorePopup.bg = nil
	end
	
	if (menuScene.boxscorePopup.scrollView ~= nil) then
		menuScene.boxscorePopup.scrollView:removeSelf();
		menuScene.boxscorePopup.scrollView = nil
	end

	if (menuScene.boxscorePopup.exit ~= nil) then
		menuScene.boxscorePopup.exit:removeSelf();
		menuScene.boxscorePopup.exit = nil
	end
	
end

function scene:sortLineup(lineup)
	--Sorts lineup by batting order
	--If batting order is the same, then pinch hitters should come after non pinch hitters
	--If both are pinch hitters, then sort by PINCH_HITTER_ORDER (order that pinch hitters appeared in the game)
	
	local function compare(a,b)
		
	  if (a.BATTING_ORDER == b.BATTING_ORDER) then
		if (a.PINCH_HITTER and not b.PINCH_HITTER) then --Pinch hitters should come after non pinch hitters in the boxscore
			return false 
		end
		if (not a.PINCH_HITTER and b.PINCH_HITTER) then --Pinch hitters should come after non pinch hitters in the boxscore
			return true 
		end
		if (a.PINCH_HITTER and b.PINCH_HITTER) then --Pinch hitters should come after non pinch hitters in the boxscore
			return a.PINCH_HITTER_ORDER < b.PINCH_HITTER_ORDER
		end

	  end
	  
	  return a.BATTING_ORDER < b.BATTING_ORDER
	end

	table.sort(lineup, compare)

end



--Simulation tab
function scene:showSimulationTab()
	
	scene:refreshSimulationTab();

end

function scene:refreshSimulationTab()
	
	scene:destroySimulationTab(); --Remove all information from screen
	
	
	local mode = "Season" --Either Season, Playoffs, Draft, Free Agency
	local day = 1;
	local league_schedule;
	local playoffs_info; --Only used in the playoffs
	local teams = {}
	local myteamid;
	
	--Obtain the league schedule from the database
	local path = system.pathForFile("data.db", system.DocumentsDirectory)
	db = sqlite3.open( path )   

	--Get league information
	for row in db:nrows([[SELECT * FROM league;]])do
		mode = row.mode;
		local sched = {};
		
		if (mode == "Season") then
			sched = row.schedule
			league_schedule = json.decode(sched);
		elseif (mode == "Playoffs") then
			sched = row.playoffs_schedule
			playoffs_info = json.decode(row.playoffs_info)
			league_schedule = json.decode(sched);
		end
		
		
		day = row.day;
	end
	
	--Get myTeam info
	for row in db:nrows([[SELECT * FROM myteam;]])do
		myteamid = row.teamid;
	end
	
	--Get list of teams
	for row in db:nrows([[SELECT * FROM teams; ]]) do 
		teams[#teams+1] = row;
	end
	
	db:close();
	
	--If mode is not season or playoffs, call appropriate simulation method and return
	if (mode ~= "Season" and mode ~= "Playoffs") then 
		if (mode == "Season Awards") then scene:simulationShowAwards("Season") end
		if (mode == "Playoffs Awards") then scene:simulationShowAwards("Playoffs") end
		if (mode == "Draft") then scene:simulationDraft(day) end
		if (mode == "Free Agency") then scene:simulationFreeAgency(day) end
		if (mode == "Lost") then scene:simulationLostGame() end
		return 
	end
	
	local day_sched = league_schedule[day];
	local dayNotOver = false; --If there are still matchups left to be played, dayNotOver = true
	
	--Current day label
	local yPos = 10;
	local text = "Day " .. day .. " Matchups";
	if (mode == "Playoffs") then
		local round = "Quarterfinals"
		if (playoffs_info.finals ~= nil) then
			round = "Finals"
		elseif (playoffs_info.round2 ~= nil) then
			round = "Semifinals"
		end
		
		text = "Playoffs - " .. round
	end
	local curDay = display.newText(text, 60,yPos, native.systemFont, 24);
	curDay.anchorX, curDay.anchorY = 0, 0;
	menuScene.simulation.elements[#menuScene.simulation.elements+1] = curDay
	yPos = yPos + 100;
	
	
	
	--If playoffs, show playoff bracket
	local function sortSeeds(a,b)  
	  return a.seed < b.seed
	end
	
	if (mode == "Playoffs") then
		
		--Show Round 1
		local origyPos = yPos
		local bottomMostY = 0 --The lowest y-pos reached by playoffs chart
		local round1x, round2x, finalsx = 60, 260, 460
		local round1y, round2y, finalsy = {100, 220, 340, 460}, {160,400}, {280}
		local matchupGroups = {} --Table of all the matchup display groups
		
		if ( playoffs_info.round1 ~= nil ) then
		
			local index = {1,4,2,3}
			for i = 1, #index do
				--Creates individual display group for the matchup
				local matchup_dg = display.newGroup() 
				local matchup = playoffs_info.round1[index[i]]
				local team1 = matchup[1]
				local team2 = matchup[2]
				
				local teamsList = {team1, team2}
				table.sort(teamsList, sortSeeds) --Make sure lower seeds comes b4 higher seed
				
				--Add the matchup to the display group matchup_dg
				for i = 1, #teamsList do
					local seed = display.newText(teamsList[i].seed .. ". " 
						.. teams[playoffs_info.seeds[teamsList[i].seed]].abv .. " - " .. teamsList[i].wins,
						0,(i-1) * 50, native.systemFont, 20);
					seed.anchorX, seed.anchorY = 0, 0;
					matchup_dg:insert(seed)	--Matchup details (Seed, Team, Wins)
				end
				
					
				local line = display.newLine( -10 , matchup_dg.y, -10, matchup_dg.height )
				line:setStrokeColor( 1, 1, 1, .5 )
				line.strokeWidth = 3
				matchup_dg:insert(line) --Underlines matchup
				
				--Position the matchup group appropriately
				matchup_dg.x, matchup_dg.y = round1x,round1y[i]
				matchupGroups[#matchupGroups+1] = matchup_dg
				
				if (i == #index) then
					bottomMostY = round1y[i] + matchup_dg.height --Mark the bottom of the playoff bracket
				end

			end
		
		
		end
			
		if ( playoffs_info.round2 ~= nil ) then
		
			local index = {1,2}
			for i = 1, #index do
				--Creates individual display group for the matchup
				local matchup_dg = display.newGroup() 
				local matchup = playoffs_info.round2[index[i]]
				local team1 = matchup[1]
				local team2 = matchup[2]
				
				local teamsList = {team1, team2}
				table.sort(teamsList, sortSeeds) --Make sure lower seeds comes b4 higher seed
				
				--Add the matchup to the display group
				for i = 1, #teamsList do
					local seed = display.newText(teamsList[i].seed .. ". " 
						.. teams[playoffs_info.seeds[teamsList[i].seed]].abv .. " - " .. teamsList[i].wins,
						0,(i-1) * 50, native.systemFont, 20);
					seed.anchorX, seed.anchorY = 0, 0;
					matchup_dg:insert(seed)	--Matchup details (Seed, Team, Wins)
				end
				
					
				local line = display.newLine( -10 , matchup_dg.y, -10, matchup_dg.height )
				line:setStrokeColor( 1, 1, 1, .5 )
				line.strokeWidth = 3
				matchup_dg:insert(line) --Underlines matchup
				
				matchup_dg.x, matchup_dg.y = round2x,round2y[i]
				menuScene.simulation.elements[#menuScene.simulation.elements+1] = matchup_dg

			end
		
		
		end
		
		if ( playoffs_info.finals ~= nil ) then
		
			local index = {1}
			for i = 1, #index do
				--Creates individual display group for the matchup
				local matchup_dg = display.newGroup() 
				local matchup = playoffs_info.finals[index[i]]
				local team1 = matchup[1]
				local team2 = matchup[2]
				
				local teamsList = {team1, team2}
				table.sort(teamsList, sortSeeds) --Make sure lower seeds comes b4 higher seed
				
				--Add the matchup to the display group
				for i = 1, #teamsList do
					local seed = display.newText(teamsList[i].seed .. ". " 
						.. teams[playoffs_info.seeds[teamsList[i].seed]].abv .. " - " .. teamsList[i].wins,
						0,(i-1) * 50, native.systemFont, 20);
					seed.anchorX, seed.anchorY = 0, 0;
					matchup_dg:insert(seed)	--Matchup details (Seed, Team, Wins)
				end
				
					
				local line = display.newLine( -10 , matchup_dg.y, -10, matchup_dg.height )
				line:setStrokeColor( 1, 1, 1, .5 )
				line.strokeWidth = 3
				matchup_dg:insert(line) --Underlines matchup
				
				matchup_dg.x, matchup_dg.y = finalsx,finalsy[i]
				menuScene.simulation.elements[#menuScene.simulation.elements+1] = matchup_dg

			end
		
		
		end
		
		yPos = bottomMostY + 50
		
		--Add all the matchup groups as elements
		for i = 1, #matchupGroups do
			menuScene.simulation.elements[#menuScene.simulation.elements+1] = matchupGroups[i]
		end
		
	end
	
	
	--Display all the matchups
	if (day_sched ~= nil) then
	for i = 1, #day_sched do --Iterate through the matchups in the day
		
		local teamone = display.newText(teams[day_sched[i].team1].abv, 
			60,yPos, native.systemFont, 20);
		teamone.anchorX, teamone.anchorY = 0, 0;
		menuScene.simulation.elements[#menuScene.simulation.elements+1] = teamone
		
		local teamonerecord = display.newText(" (" ..teams[day_sched[i].team1].win .."-" .. teams[day_sched[i].team1].loss ..")", 
			teamone.x+teamone.width,yPos, native.systemFont, 20);
		teamonerecord.anchorX, teamonerecord.anchorY = 0, 0;
		teamonerecord:setFillColor(1,0,0);
		menuScene.simulation.elements[#menuScene.simulation.elements+1] = teamonerecord
		
		local slash = display.newText(" vs ", 
			teamonerecord.x+teamonerecord.width,yPos, native.systemFont, 20);
		slash.anchorX, slash.anchorY = 0, 0;
		menuScene.simulation.elements[#menuScene.simulation.elements+1] = slash
		
		local teamtwo = display.newText(teams[day_sched[i].team2].abv, 
			slash.x+slash.width,yPos, native.systemFont, 20);
		teamtwo.anchorX, teamtwo.anchorY = 0, 0;
		menuScene.simulation.elements[#menuScene.simulation.elements+1] = teamtwo
		
		local teamtworecord = display.newText(" (" ..teams[day_sched[i].team2].win .."-" .. teams[day_sched[i].team2].loss ..")", 
			teamtwo.x+teamtwo.width,yPos, native.systemFont, 20);
		teamtworecord.anchorX, teamtworecord.anchorY = 0, 0;
		teamtworecord:setFillColor(1,0,0);
		menuScene.simulation.elements[#menuScene.simulation.elements+1] = teamtworecord
		
		--Attempt to see if teams have already played the matchup, if so, store game info into variable "game"
		local path = system.pathForFile("data.db", system.DocumentsDirectory)
		db = sqlite3.open( path )   

		local game --Get the game from the games table in the database
		for row in db:nrows([[SELECT * FROM games WHERE id = ]] .. day_sched[i].matchup_id .. [[;]]) do 
			game = row;
		end
		db:close();
		
		if (game == nil) then --MATCHUP HAS NOT BEEN PLAYED YET, ALLOW USER TO SEE LINEUP OR WATCH THE GAME
			dayNotOver = true; --Day is not over
			local function tap(event) --Tap the lineup label
				local path = system.pathForFile("data.db", system.DocumentsDirectory)
				db = sqlite3.open( path )  
				
				local teamid1 = teams[day_sched[i].team1].id
				local lineup1 = lg:generateLineup(teamid1);
				
				local teamid2 = teams[day_sched[i].team2].id
				local lineup2 = lg:generateLineup(teamid2);
				
				db:close()
				
				if (lineup1 == nil or lineup2 == nil) then
					--If either of the two lineups are nil (which means lineup generator could not make a lineup)
					--Then show an error popup
					local msg = "Lineup could not be generated -"
					if (lineup1 == nil) then
						msg = msg .. " " .. teams[day_sched[i].team1].abv
					end
					if (lineup2 == nil) then
						msg = msg .. " " .. teams[day_sched[i].team2].abv
					end
					scene:showPopup(msg, 24);
				else
					scene:showLineupPopup2(teams[day_sched[i].team1].id, lineup1, teams[day_sched[i].team2].id, lineup2);
				end
				
				
			end
			
			local lineup = display.newText("Lineups", 400 ,yPos, native.systemFont, 20);
			lineup:setFillColor(.8,.8,.8)
			lineup.anchorX, lineup.anchorY = 0, 0;
			lineup:addEventListener("tap", tap);
			menuScene.simulation.elements[#menuScene.simulation.elements+1] = lineup
			
			local function tap2(event) --Tap the watch game label
				--scene:showPopup("Feature Not Available Yet", 24);
				local path = system.pathForFile("data.db", system.DocumentsDirectory)
				db = sqlite3.open( path )  
				db:exec("BEGIN TRANSACTION;")		
				
				local teamid1 = teams[day_sched[i].team1].id
				local lineup1 = lg:generateLineup(teamid1);
				local teamid2 = teams[day_sched[i].team2].id
				local lineup2 = lg:generateLineup(teamid2);
				if (lineup1 == nil or lineup2 == nil) then
					--Can't play game, lineup generator failed to make lineup, may be error on users part
					scene:showPopup("Error - Check Lineups", 24);
				else
					local score1, score2 = gs:simulateGame(lineup1, lineup2, teamid1, teamid2, day_sched[i].matchup_id);
					print(teams[day_sched[i].team1].name .. " - " .. teams[day_sched[i].team2].name .. "   " .. score1 .. " - " .. score2);
				end
				
				db:exec("END TRANSACTION;")
				db:close();
				scene:refreshSimulationTab();
			end
			
			local watch = display.newText("Simulate", 600 ,yPos, native.systemFont, 20);
			watch:setFillColor(.8,.8,.8)
			watch.anchorX, watch.anchorY = 0, 0;
			watch:addEventListener("tap", tap2);
			menuScene.simulation.elements[#menuScene.simulation.elements+1] = watch
		else --ELSE MATCHUP HAS ALREADY BEEN PLAYED, ALLOW USER TO SEE RESULTS AND BOX SCORE
			local info = json.decode(game.info);
			local score = display.newText(info.score1 .. " - " .. info.score2, 400 ,yPos, native.systemFont, 20);
			score.anchorX, score.anchorY = 0, 0;
			--score:addEventListener("tap", tap);
			menuScene.simulation.elements[#menuScene.simulation.elements+1] = score
			
			local function tap2(event)
				print(json.encode(info))
				scene:showBoxscorePopup(game.team1_id, game.team2_id, info);
			end
			
			local boxscore = display.newText("Boxscore", 600 ,yPos, native.systemFont, 20);
			boxscore:setFillColor(.8,.8,.8)
			boxscore.anchorX, boxscore.anchorY = 0, 0;
			boxscore:addEventListener("tap", tap2);
			menuScene.simulation.elements[#menuScene.simulation.elements+1] = boxscore
			
		end
		yPos = yPos + 50;
	end
	end
	
	--Decide whether to show the 'Simulate Day' Button or the 'Next Day' Button
	if (dayNotOver) then --There are still games left to be simulated
		
		--Default setting to simulate one game
		menuScene.simulation.num_days = 1;
		
		--Holds method held by timer; Allows for cancellation of the simulation
		--When user taps "Stop Simulation"
		local nextIteration;
		
		local function destroySimulationProgress()
			for i = 1, #menuScene.simulation.progress_elements do
				if (menuScene.simulation.progress_elements[i] ~= nil) then
					menuScene.simulation.progress_elements[i]:removeSelf();
					menuScene.simulation.progress_elements[i] = nil
				end
			end
			
			if (menuScene.simulation.progress_indicator ~= nil) then
				menuScene.simulation.progress_indicator:removeSelf();
				menuScene.simulation.progress_indicator = nil
			end
			
			if (menuScene.simulation.progress_info ~= nil) then
				menuScene.simulation.progress_info:removeSelf();
				menuScene.simulation.progress_info = nil
			end
		
			--Allow phone to sleep after simulation
			system.setIdleTimer( true )
			
			--Alert that simulation has finished
			audio.play( globalSounds["alert"] )
			
			--Hide ads
			--ads.hide()
		end
		
		local function showSimulationProgress()
			--Show progress screen whenever simulation takes some time
			local black = display.newImage("Images/black.png", 0, 0);
			black.width, black.height = display.contentWidth, display.contentHeight
			black.anchorX, black.anchorY = 0,0
			black.alpha = .1;
	
			local function blockTouches(event)
				return true; --Block the propagation of any touches or taps
			end
			black:addEventListener("tap", blockTouches);
			black:addEventListener("touch", blockTouches);
			menuScene.simulation.progress_elements[#menuScene.simulation.progress_elements+1]  = black;
			
			--Popup Background
			local popup = display.newImage("Images/popup.png", display.contentCenterX, display.contentCenterY);
			popup.width, popup.height = display.contentWidth/2, display.contentHeight/2
			popup.anchorX, popup.anchorY = .5,.5
			menuScene.simulation.progress_elements[#menuScene.simulation.progress_elements+1]  = popup;
			
			--Indicates what day we have simulated
			local indicator = display.newText("Simulating...", display.contentCenterX, 
				display.contentCenterY - 50, native.systemFont, 24);
			indicator.anchorX, indicator.anchorY =.5, 0;
			menuScene.simulation.progress_indicator = indicator
			
			--More information for indicator
			local info = display.newText("", display.contentCenterX, 
				indicator.y + indicator.height + 20, native.systemFont, 24);
			info.anchorX, info.anchorY =.5, 0;
			menuScene.simulation.progress_info = info
			
			--Allows for stoppage of simulation
			local function stopSimulation()

				if (nextIteration ~= nil) then
					timer.cancel(nextIteration)
				end
				--Destroy simulaion progress popup
				destroySimulationProgress();
				--Finished simulation, refresh tab to show final results
				scene:refreshSimulationTab();
			end
			
			local stop = display.newText("Stop Simulation", display.contentCenterX, 
				info.y + info.height + 30, native.systemFont, 24);
			stop.anchorX, stop.anchorY =.5, 0;
			stop:setFillColor(.8,.8,.8);
			stop:addEventListener("tap", stopSimulation);
			menuScene.simulation.progress_elements[#menuScene.simulation.progress_elements+1] = stop
			
			--Show Banner Ad (Bottom of Screen)
			--Disabled because to processor intensive and annoying
			
			--[[
			local function adListener( event )
				-- The 'event' table includes:
				-- event.name: string value of "adsRequest"
				-- event.response: message from the ad provider about the status of this request
				-- event.phase: string value of "loaded", "shown", or "refresh"
				-- event.type: string value of "banner" or "interstitial"
				-- event.isError: boolean true or false

				local msg = event.response
				-- Quick debug message regarding the response from the library
				print( "Message from the ads library: ", msg )

				if ( event.isError ) then
					print( "Error, no ad received", msg )
					--scene:showPopup("Error, no ad received", 24)
				else
					print( "Ah ha! Got one!" )
					--scene:showPopup("Ah ha! Got one!" , 24)
				end
			end
			ads.init( menuScene.adInfo.provider, menuScene.adInfo.appID, adListener )
			ads.show( "banner", { x=display.screenOriginX, y=10000000, appId=menuScene.adInfo.appID} )
			]]--
		end
			
		--Simulate "Button"
		local function simulate_day(event)
		
			audio.play( globalSounds["tap"] )
			
			--Prevent phone from sleeping during simulation
			system.setIdleTimer( false )
			
			local countFailed = 0;
			
			local final_day = (day + menuScene.simulation.num_days - 1); --Index of final day to simulate

			local function iterate(day)
				--Update the current mode of the simulation
				local path = system.pathForFile("data.db", system.DocumentsDirectory)
				db = sqlite3.open( path ) 
				for row in db:nrows([[SELECT * FROM league;]])do
					mode = row.mode
				end
				
				db:close()
				
				--If mode is no longer playoffs or season, end simulation
				if (mode ~= "Playoffs" and mode ~= "Season") then 
					print ("Break test") 
					destroySimulationProgress();
					scene:refreshSimulationTab();
					return 
				end
				
				--Update league schedule if playoffs, because the playoffs schedule is updated every day
				if (mode == "Playoffs") then
					local path = system.pathForFile("data.db", system.DocumentsDirectory)
					db = sqlite3.open( path ) 
					for row in db:nrows([[SELECT * FROM league;]])do
						local sched = row.playoffs_schedule
						league_schedule = json.decode(sched);
						playoffs_info = json.decode(row.playoffs_info);
					end
					db:close()
				end
				
				day_sched = league_schedule[day];
				
				local path = system.pathForFile("data.db", system.DocumentsDirectory)
				db = sqlite3.open( path )   
				db:exec("BEGIN TRANSACTION;")
				
				for i = 1, #day_sched do --Simulate all the games in a day
			
					local gameAlreadyPlayed = false;
					for row in db:nrows([[SELECT * FROM games WHERE id = ]] .. day_sched[i].matchup_id .. [[;]])do
						 gameAlreadyPlayed = true;
					end
									
					if (not gameAlreadyPlayed) then --Only simulate if game has not been played already
					local teamid1 = teams[day_sched[i].team1].id
					local lineup1 = lg:generateLineup(teamid1);
					local teamid2 = teams[day_sched[i].team2].id
					local lineup2 = lg:generateLineup(teamid2);
					if (lineup1 == nil or lineup2 == nil) then
						--Can't play game, lineup generator failed to make lineup, may be error on users part
						print("Lineup nil");
						countFailed = countFailed + 1;
					else
						local score1, score2 = gs:simulateGame(lineup1, lineup2, teamid1, teamid2, day_sched[i].matchup_id);
					end
					
					end
				end
				
				--Get current record of team
				local myteamWin, myteamLoss = 0,0
				for row in db:nrows([[SELECT * FROM teams WHERE id = ]] .. myteamid .. [[;]])do
					myteamWin, myteamLoss = row.win, row.loss;
				end
				
				db:exec("END TRANSACTION;")
				db:close()
				
				--If a game failed to simulate, break the loop
				--Cannot advance to next day until all games are complete
				if (countFailed > 0) then 
					destroySimulationProgress();
					scene:refreshSimulationTab();
					scene:showPopup("Simulation Failed In " .. countFailed .. " Games", 24);
					return
				else
					if (day ~= final_day) then
						--Only move onto the last day if not the final day of simulation
						ss:nextDay();
					else
						destroySimulationProgress();
						scene:refreshSimulationTab();
					end

				end
				
				--Next iteration, if valid
				local nextDay = day + 1;
				if (nextDay <= final_day) then 
					local function f()
						iterate(nextDay)
					end
					
					--Perform next iteration after a delay. The delay allows us to update a few graphics
					--Without this delay, we cannot update any graphics, b/c Corona has no multi-threading capabilities
					nextIteration = timer.performWithDelay( 1000 , 	f);
					menuScene.simulation.progress_indicator.text = "Simulated Day " .. day
					
					--If simulating season, also show myteam win-loss record
					if (mode == "Season") then
						menuScene.simulation.progress_info.text =
							" (" .. myteamWin .. " - " .. myteamLoss .. ")"
					elseif (mode == "Playoffs") then
					--If simulating playoffs, show what round is currently being played
						local text = "Blank";
						if ( playoffs_info.finals ~= nil ) then text = "Finals";	 
						elseif ( playoffs_info.round2 ~= nil ) then text = "Semifinals";
						elseif ( playoffs_info.round1 ~= nil ) then text = "Quarterfinals"; end
						menuScene.simulation.progress_info.text = text;
					end
				end
				
			end
			
			showSimulationProgress();
			
			local function startIteration()
				--Begin iteration through the days (Go through schedule and simulate games)
				iterate(day);
			end
			
			--Delay iteration a little to give simulation progress popup chance to load
			nextIteration = timer.performWithDelay(500, startIteration);
			

		end
		
		
		local simulate = display.newText("Simulate " .. menuScene.simulation.num_days .. " Day" ,
			display.contentWidth - 10,curDay.y, native.systemFont, 24);
		simulate:setFillColor(.8,.8,.8)
		simulate.anchorX, simulate.anchorY = 1, 0;
		simulate:addEventListener("tap", simulate_day);
		menuScene.simulation.elements[#menuScene.simulation.elements+1] = simulate
		
		
		--Num Days Stepper
		local dayStepper
		
		local function onStepperPress2( event )
			if (event.value == 1) then --One day
				menuScene.simulation.num_days = 1
				simulate.text = "Simulate " .. menuScene.simulation.num_days .. " Day"
			elseif (event.value == 2) then --One Week
				menuScene.simulation.num_days = 7
				simulate.text = "Simulate " .. menuScene.simulation.num_days .. " Days"
			elseif (event.value == 3) then --One Month
				menuScene.simulation.num_days = 30
				simulate.text = "Simulate " .. menuScene.simulation.num_days .. " Days"
			elseif (event.value == 4) then --One Season
				menuScene.simulation.num_days = 162
				simulate.text = "Simulate " .. menuScene.simulation.num_days .. " Days"
			else	--Variable num days
				menuScene.simulation.num_days = event.value-3
				simulate.text = "Simulate " .. menuScene.simulation.num_days .. " Days"
			end
			
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
		dayStepper = widget.newStepper
		{
			initialValue = 1,
			minimumValue = 1,
			maximumValue = 165,
			x = simulate.x,
			y = simulate.y + simulate.height + 10,
			width = 100,
			height = 50,
			sheet = stepperSheet,
			defaultFrame = 1,
			noMinusFrame = 2,
			noPlusFrame = 3,
			minusActiveFrame = 4,
			plusActiveFrame = 5,
			onPress = onStepperPress2
		}
		dayStepper.anchorX, dayStepper.anchorY = 1, 0;
		menuScene.simulation.elements[#menuScene.simulation.elements+1] = dayStepper;
	
	else --No more games left to be played, can move to next day
		local function next_day(event)
			audio.play( globalSounds["tap"] )
			ss:nextDay(); --Use season simulator to advance a day
			scene:refreshSimulationTab();
		end
		local nextDay = display.newText("Next Day" , display.contentWidth - 10,curDay.y, native.systemFont, 24);
		nextDay:setFillColor(.8,.8,.8)
		nextDay.anchorX, nextDay.anchorY = 1, 0;
		nextDay:addEventListener("tap", next_day);
		menuScene.simulation.elements[#menuScene.simulation.elements+1] = nextDay
	end
	
	
	--Insert all elements into scrollview
	for i = 1, #menuScene.simulation.elements do
		menuScene.scrollView:insert(menuScene.simulation.elements[i]);
	end
end

function scene:simulationShowAwards(mode)
	--mode == either season or playoffs
	local year
	local awards = {}
	
	--Obtain the league schedule from the database
	local path = system.pathForFile("data.db", system.DocumentsDirectory)
	db = sqlite3.open( path )   

	--Get league information
	for row in db:nrows([[SELECT * FROM league;]])do
		year = row.year
	end
	
	--Get list of awards from year
	for row in db:nrows([[SELECT * FROM awards WHERE year = ]] .. year .. [[ and type = "]] .. mode .. [["; ]]) do 
		awards[#awards+1] = row;
	end
	
	local yPos = 10
	local text
	if (mode == "Season") then
		text = year .. " Regular Season Awards"
	else
		text = year .. " Postseason Awards"
	end
	local title = display.newText( text, 60,yPos, native.systemFont, 24);
	title.anchorX, title.anchorY = 0, 0;
	menuScene.simulation.elements[#menuScene.simulation.elements+1] = title
	
	yPos=yPos+25
	--Display all the awards on the screen
	for i = 1, #awards do
		yPos=yPos+50
		local award = display.newText(awards[i].award .. " - " , 60,yPos, native.systemFont, 24);
		award.anchorX, award.anchorY = 0, 0;
		menuScene.simulation.elements[#menuScene.simulation.elements+1] = award
		
		local player = true;
		local name
		
		if (awards[i].playerid ~= nil) then --Player Award
			for row in db:nrows([[SELECT * FROM players WHERE id = ]] .. awards[i].playerid .. [[; ]]) do 
				name = row.name
			end
		else --Team award
			for row in db:nrows([[SELECT * FROM teams WHERE id = ]] .. awards[i].teamid .. [[; ]]) do 
				name = row.name
			end
			player = false;
		end
		
		local name = display.newText(name, 260,yPos, native.systemFont, 24);
		name:setFillColor(.8,.8,.8);
		name.anchorX, name.anchorY = 0, 0;
		menuScene.simulation.elements[#menuScene.simulation.elements+1] = name
		
	
		local function tap( event )
			if (player) then
				scene:showPlayerCardPopup(awards[i].playerid);
			else
				scene:changeMode("Team Card", awards[i].teamid);
			end
			return true;
		end 
		name:addEventListener("tap", tap)
		
		if (player) then --Show team abbreviation next to player
		local teamabv, teamid
		for row in db:nrows([[SELECT * FROM teams WHERE id = (SELECT teamid FROM players WHERE id = ]] .. awards[i].playerid .. [[); ]]) do 
			teamabv = row.abv
			teamid = row.id
		end
		
		local teamName = display.newText(teamabv, 600,yPos, native.systemFont, 24);
		teamName.anchorX, teamName.anchorY = 0, 0;
		teamName:setFillColor(.8,.8,.8);
		menuScene.simulation.elements[#menuScene.simulation.elements+1] = teamName
		
		local function tap2( event )
			scene:changeMode("Team Card", teamid);
			return true;
		end 
		teamName:addEventListener("tap", tap2)
		end
		
		
	
	end
	
	db:close();
	
	
	local function next_day(event)
		audio.play( globalSounds["tap"] )
		ss:nextDay(); --Use season simulator to advance a day
		scene:refreshSimulationTab();
	end
	local nextDay = display.newText("Next Day" , display.contentWidth - 10,title.y, native.systemFont, 24);
	nextDay.anchorX, nextDay.anchorY = 1, 0;
	nextDay:setFillColor(.8,.8,.8);
	nextDay:addEventListener("tap", next_day);
	menuScene.simulation.elements[#menuScene.simulation.elements+1] = nextDay
	
	--Insert all elements into scrollview
	for i = 1, #menuScene.simulation.elements do
		menuScene.scrollView:insert(menuScene.simulation.elements[i]);
	end

end

function scene:simulationLostGame(mode)
	
	local myTeamid
	local goals
	local totalWin, totalLoss = 0, 0
	local numChampionships = 0
	
	--Obtain the league schedule from the database
	local path = system.pathForFile("data.db", system.DocumentsDirectory)
	db = sqlite3.open( path )   

	--Determine reason for losing game
	for row in db:nrows([[SELECT * FROM myteam;]]) do 
		myTeamid = row.teamid
		goals = json.decode(row.goals)
	end
	for row in db:nrows([[SELECT * FROM teams WHERE id = ]] .. myTeamid .. [[;]]) do 
		if (row.history ~= nil) then
			local history = json.decode(row.history)
			for i = 1, #history do
				totalWin = totalWin + history[i].win
				totalLoss = totalLoss + history[i].loss
				if (history[i].info == "Champion") then
					numChampionships = numChampionships+1
				end
			end
		end
		totalWin = totalWin + row.win
		totalLoss = totalLoss + row.loss
	end
	
	db:close();
	
	local yPos = 10
	local text = "You've been fired!"
	local title = display.newText( text, display.contentCenterX,40, native.systemFont, 24);
	title.anchorX, title.anchorY = .5, 0;
	menuScene.simulation.elements[#menuScene.simulation.elements+1] = title
	
	local msg = ""
	
	--[[if (failedPlayoffs >= 4) then
		msg = "For lack of postseason success"
	elseif (failedProfit >= 3) then
		msg = "For lack of profit"
	end]]--
	
	local msgLabel = display.newText( msg, display.contentCenterX,title.y+title.height+10, native.systemFont, 24);
	msgLabel.anchorX, msgLabel.anchorY = .5, 0;
	menuScene.simulation.elements[#menuScene.simulation.elements+1] = msgLabel
	
	local finalRecordLabel = display.newText("Record: " .. totalWin .. "-" .. totalLoss, display.contentCenterX,
		display.contentCenterY, native.systemFont, 24);
	finalRecordLabel.anchorX, finalRecordLabel.anchorY = .5, 0;
	menuScene.simulation.elements[#menuScene.simulation.elements+1] = finalRecordLabel
	
	local numChampionshipsLabel = display.newText("Championships: " .. numChampionships, display.contentCenterX,
		finalRecordLabel.y+finalRecordLabel.height+10, native.systemFont, 24);
	numChampionshipsLabel.anchorX, numChampionshipsLabel.anchorY = .5, 0;
	menuScene.simulation.elements[#menuScene.simulation.elements+1] = numChampionshipsLabel
	
	local function mainMenu()
		audio.play( globalSounds["tap"] )
		storyboard.gotoScene("mainMenuScene", "fade", 500);
		scene:changeMode(""); --Empty parameter just destroys current page, thus freeing up memory
	end
	
	local mainMenuLabel = display.newText("Main Menu", display.contentCenterX,
		display.contentHeight - 10, native.systemFont, 24);
	mainMenuLabel.anchorX, mainMenuLabel.anchorY = .5, 1;
	mainMenuLabel:setFillColor(.8,.8,.8);
	mainMenuLabel:addEventListener("tap", mainMenu)
	menuScene.simulation.elements[#menuScene.simulation.elements+1] = mainMenuLabel
	
	
	--Insert all elements into scrollview
	for i = 1, #menuScene.simulation.elements do
		menuScene.scrollView:insert(menuScene.simulation.elements[i]);
	end

	
	

end

function scene:simulationDraft(day)

	local yPos = 10
	local extraArg = nil
	
	local title = display.newText( "Draft Day " .. day , 60,yPos, native.systemFont, 24);
	title.anchorX, title.anchorY = 0, 0;
	menuScene.simulation.elements[#menuScene.simulation.elements+1] = title
	
	local showNextDay = true;
	
	if (day == 1) then
		--Let user select amount of money dedicated to scouting
		extraArg = 0; --Money Spent
		
		local money = display.newText("$ " .. extraArg,
		display.contentCenterX,display.contentCenterY, native.systemFont, 24);
		money.anchorX, money.anchorY = 0, 0.5;
		menuScene.simulation.elements[#menuScene.simulation.elements+1] = money
		
		--Money Stepper
		local moneyStepper
		
		local function onStepperPress2( event )
			extraArg = (event.value * 500000)
			money.text ="$ " .. extraArg
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
		moneyStepper = widget.newStepper
		{
			initialValue = 0,
			minimumValue = 0,
			maximumValue = 10,
			x = money.x - 15,
			y = money.y,
			width = 100,
			height = 50,
			sheet = stepperSheet,
			defaultFrame = 1,
			noMinusFrame = 2,
			noPlusFrame = 3,
			minusActiveFrame = 4,
			plusActiveFrame = 5,
			onPress = onStepperPress2
		}
		moneyStepper.anchorX, moneyStepper.anchorY = 1, 0.5;
		menuScene.simulation.elements[#menuScene.simulation.elements+1] = moneyStepper;
		
		
		local question = display.newText("How much money will you spend on scouting?",
		display.contentCenterX,moneyStepper.y - (moneyStepper.height/2) - 50, native.systemFont, 24);
		question.anchorX, question.anchorY = 0.5, 0.5;
		menuScene.simulation.elements[#menuScene.simulation.elements+1] = question
		
	elseif (day == 2) then
		
		yPos = yPos + 100
		local function tap(event)
			scene:showDraftOrderPopup();
			return true;
		end
		local draftOrder = display.newText("Draft Order",display.contentCenterX,title.y, native.systemFont, 24);
		draftOrder.anchorX, draftOrder.anchorY = 0.5, 0;
		draftOrder:setFillColor(.8,.8,.8);
		menuScene.simulation.elements[#menuScene.simulation.elements+1] = draftOrder
		draftOrder:addEventListener("tap", tap);
		
		local function sort(event)
			audio.play( globalSounds["tap"] )
			local sort = event.target.sort
			if (sort == menuScene.simulation.draftSort2) then
				if (menuScene.simulation.draftSortOrder2 == "ASC") then
					menuScene.simulation.draftSortOrder2 = "DESC"
				else
					menuScene.simulation.draftSortOrder2 = "ASC"
				end
			end
			menuScene.simulation.draftSort2 = sort
			
			scene:refreshSimulationTab();
		end
		
		local labels = {"Player", "Proj", "Ovr", "Pot"}
		local labelsX = {60,400,550,680}
		local labelsSort = {
		"name", 
		[[CASE draftProjection
			WHEN "Top 5" THEN 0
			WHEN "Top 10" THEN 1
			WHEN "Round 1" THEN 2
			WHEN "Round 2" THEN 3
			WHEN "Round 3" THEN 4
			WHEN "Undrafted" THEN 5
		END]]
		,
		[[CASE evalOverall
			WHEN "A+" THEN 0
			WHEN "A" THEN 1
			WHEN "B+" THEN 2
			WHEN "B" THEN 3
			WHEN "C+" THEN 4
			WHEN "C" THEN 5
			WHEN "D+" THEN 6
			WHEN "D" THEN 7
			WHEN "F+" THEN 8
			WHEN "F" THEN 9
		END]]
		,
		[[CASE evalPotential
			WHEN "A+" THEN 0
			WHEN "A" THEN 1
			WHEN "B+" THEN 2
			WHEN "B" THEN 3
			WHEN "C+" THEN 4
			WHEN "C" THEN 5
			WHEN "D+" THEN 6
			WHEN "D" THEN 7
			WHEN "F+" THEN 8
			WHEN "F" THEN 9
		END]]}
		
		for i = 1, #labels do
			local label = display.newText(labels[i],labelsX[i],yPos, native.systemFont, 24);
			label.anchorX, label.anchorY = 0, 0;
			label:setFillColor(.8,.8,.8)
			label:addEventListener("tap",sort)
			label.sort = labelsSort[i]
			menuScene.simulation.elements[#menuScene.simulation.elements+1] = label
			
			if (menuScene.simulation.draftSort2 == label.sort) then
				label:setFillColor(1,0,0)
			end
		end

		local path = system.pathForFile("data.db", system.DocumentsDirectory)
		db = sqlite3.open( path ) 
		
		local scout_eval = {} --Scout evaluation made by player's team
		for row in db:nrows([[SELECT * FROM draft;]]) do
			scout_eval = json.decode(row.scout_eval);
		end
		
		
		--Show draft prospects sorted by projection
		for row in db:nrows([[SELECT * FROM draft_players ORDER BY ]] .. menuScene.simulation.draftSort2 .. [[ ]] 
			.. menuScene.simulation.draftSortOrder2 .. [[;]]) do 
			yPos = yPos+50
			
			local function tap()
				scene:showProspectCardPopup(row.id)
			end
			
			local name = display.newText(row.name .. " (" .. row.posType .. ")",60,yPos, native.systemFont, 20);
			name.anchorX, name.anchorY = 0, 0;
			name:setFillColor(.8,.8,.8);
			name:addEventListener("tap", tap);
			menuScene.simulation.elements[#menuScene.simulation.elements+1] = name
			
			
			local projection = display.newText(row.draftProjection,400,yPos, native.systemFont, 20);
			projection.anchorX, projection.anchorY = 0, 0;
			menuScene.simulation.elements[#menuScene.simulation.elements+1] = projection
			
			local overall = display.newText(scout_eval[row.id].overall,550,yPos, native.systemFont, 24);
			overall.anchorX, overall.anchorY = 0, 0;
			menuScene.simulation.elements[#menuScene.simulation.elements+1] = overall
			
			local potential = display.newText(scout_eval[row.id].potential,680,yPos, native.systemFont, 24);
			potential.anchorX, potential.anchorY = 0, 0;
			menuScene.simulation.elements[#menuScene.simulation.elements+1] = potential
		  
		end
		
		db:close()
		
	elseif (day == 3) then
		
		local numDraftedAlready = 0;
		local currentPick = 0;
		local totalNumberOfPicks = 0; --In the draft
		local myteamid
		local draft_selections = {}
		
		local path = system.pathForFile("data.db", system.DocumentsDirectory)
		db = sqlite3.open( path ) 
		
		local scout_eval = {} --Scout evaluation made by player's team
		for row in db:rows([[SELECT Count(*) FROM draft_players WHERE teamid IS NOT NULL]]) do
			numDraftedAlready = row[1] 
			print("#dalrdy: " .. numDraftedAlready);
			currentPick = numDraftedAlready + 1
		end
		for row in db:nrows([[SELECT * FROM draft]]) do
			 draft_selections = (json.decode(row.draft_selections))
			 totalNumberOfPicks = #draft_selections
		end
		for row in db:nrows([[SELECT * FROM myteam]]) do
			myteamid = row.teamid
		end
	
		db:close()
		
		
		yPos = yPos + 100
		
		--Show start draft button if currentPick == 1
		--Else show currentPick indicator
		if (currentPick == 1) then
			local startDraft
			local function tap(event)
				
				audio.play( globalSounds["tap"] )
				
				startDraft:removeSelf()
				startDraft = nil;
				local curPick = ss:cpuDraft();
				scene:refreshSimulationTab();
				
				if (curPick == 1) then
					--First pick belongs to user, show popup alerting him to pick
					scene:showPopup("Your turn to pick", 24);
				end
				return true;
			end
			startDraft = display.newText("Start Draft",display.contentWidth - 10,title.y, native.systemFont, 24);
			startDraft.anchorX, startDraft.anchorY = 1, 0;
			startDraft:setFillColor(.8,.8,.8);
			menuScene.simulation.elements[#menuScene.simulation.elements+1] = startDraft
			startDraft:addEventListener("tap", tap);
		else
		
			local text;
			if (currentPick > 90) then
				text = "Draft Finished"
			else
				local round = math.ceil(currentPick / 30)
				local pick = currentPick - math.floor(currentPick / 30) * 30
				if (pick == 0) then pick = 30 end
				text = "Round " .. round .. " Pick " .. pick
			end
			local pickIndicator = display.newText(text,display.contentCenterX,title.y, native.systemFont, 24);
			pickIndicator.anchorX, pickIndicator.anchorY = .5, 0;
			menuScene.simulation.elements[#menuScene.simulation.elements+1] = pickIndicator
		end
		
		--If draft is not finished, do not allow user to move onto the next day
		if (numDraftedAlready < totalNumberOfPicks) then
			showNextDay = false
		end
		
		local function sort(event)
			audio.play( globalSounds["tap"] )
			local sort = event.target.sort
			if (sort == menuScene.simulation.draftSort3) then
				if (menuScene.simulation.draftSortOrder3 == "ASC") then
					menuScene.simulation.draftSortOrder3 = "DESC"
				else
					menuScene.simulation.draftSortOrder3 = "ASC"
				end
			end
			menuScene.simulation.draftSort3 = sort
			
			scene:refreshSimulationTab();
		end
		
		local labels = {"Player", "Proj", "Ovr", "Pot"}
		local labelsX = {60,360,500,600}
		local labelsSort = {
		"name", 
		[[CASE draftProjection
			WHEN "Top 5" THEN 0
			WHEN "Top 10" THEN 1
			WHEN "Round 1" THEN 2
			WHEN "Round 2" THEN 3
			WHEN "Round 3" THEN 4
			WHEN "Undrafted" THEN 5
		END]]
		,
		[[CASE evalOverall
			WHEN "A+" THEN 0
			WHEN "A" THEN 1
			WHEN "B+" THEN 2
			WHEN "B" THEN 3
			WHEN "C+" THEN 4
			WHEN "C" THEN 5
			WHEN "D+" THEN 6
			WHEN "D" THEN 7
			WHEN "F+" THEN 8
			WHEN "F" THEN 9
		END]]
		,
		[[CASE evalPotential
			WHEN "A+" THEN 0
			WHEN "A" THEN 1
			WHEN "B+" THEN 2
			WHEN "B" THEN 3
			WHEN "C+" THEN 4
			WHEN "C" THEN 5
			WHEN "D+" THEN 6
			WHEN "D" THEN 7
			WHEN "F+" THEN 8
			WHEN "F" THEN 9
		END]]}
		
		for i = 1, #labels do
			local label = display.newText(labels[i],labelsX[i],yPos, native.systemFont, 24);
			label.anchorX, label.anchorY = 0, 0;
			label:setFillColor(.8,.8,.8)
			label:addEventListener("tap",sort)
			label.sort = labelsSort[i]
			menuScene.simulation.elements[#menuScene.simulation.elements+1] = label
			
			if (menuScene.simulation.draftSort3 == label.sort) then
				label:setFillColor(1,0,0)
			end
		end

		
		local path = system.pathForFile("data.db", system.DocumentsDirectory)
		db = sqlite3.open( path ) 
		
		local scout_eval = {} --Scout evaluation made by player's team
		for row in db:nrows([[SELECT * FROM draft;]]) do
			scout_eval = json.decode(row.scout_eval);
		end
		
		
		--Show available draft prospects sorted by projection
		for row in db:nrows([[SELECT * FROM draft_players WHERE teamid IS NULL ORDER BY ]] .. menuScene.simulation.draftSort3 .. [[ ]] 
			.. menuScene.simulation.draftSortOrder3 .. [[;]]) do 
			yPos = yPos+50

			local function tap(event)
				scene:showProspectCardPopup(row.id)
				return true
			end
			
			local name = display.newText(row.name .. " (" .. row.posType .. ")",60,yPos, native.systemFont, 18);
			name.anchorX, name.anchorY = 0, 0;
			name:setFillColor(.8,.8,.8);
			name:addEventListener("tap", tap);
			menuScene.simulation.elements[#menuScene.simulation.elements+1] = name
			
			
			local projection = display.newText(row.draftProjection,360,yPos, native.systemFont, 18);
			projection.anchorX, projection.anchorY = 0, 0;
			menuScene.simulation.elements[#menuScene.simulation.elements+1] = projection
			
			local overall = display.newText(scout_eval[row.id].overall,500,yPos, native.systemFont, 20);
			overall.anchorX, overall.anchorY = 0, 0;
			menuScene.simulation.elements[#menuScene.simulation.elements+1] = overall
			
			local potential = display.newText(scout_eval[row.id].potential,600,yPos, native.systemFont, 20);
			potential.anchorX, potential.anchorY = 0, 0;
			menuScene.simulation.elements[#menuScene.simulation.elements+1] = potential
			
			local function draft(event)
				audio.play( globalSounds["tap"] )
				print("Num drfted: " .. numDraftedAlready);
				print("Current Selection: " .. currentPick);
				if (draft_selections[currentPick] ~= myteamid) then 
					--If pick doesn't belong to player, don't let player draft
					scene:showPopup("Not your turn", 24);
					return true
				end
				ss:playerDraft(row.id);
				ss:cpuDraft();
				scene:refreshSimulationTab();
				return true;
			end
			
			local draftButton = display.newText("Draft",700,yPos, native.systemFont, 22);
			draftButton:setFillColor(.8,.8,.8);
			draftButton.anchorX, draftButton.anchorY = 0, 0;
			draftButton:addEventListener("tap", draft);
			menuScene.simulation.elements[#menuScene.simulation.elements+1] = draftButton
		  
		end
		
		db:close()
	elseif (day == 4) then
		local draftSummary = display.newText("Draft Summary",display.contentCenterX,title.y, native.systemFont, 24);
		draftSummary.anchorX, draftSummary.anchorY = .5, 0;
		menuScene.simulation.elements[#menuScene.simulation.elements+1] = draftSummary
		
		yPos = yPos+100
		
		local function sort(event)
			audio.play( globalSounds["tap"] )
			local sort = event.target.sort
			if (sort == menuScene.simulation.draftSort4) then
				if (menuScene.simulation.draftSortOrder4 == "ASC") then
					menuScene.simulation.draftSortOrder4 = "DESC"
				else
					menuScene.simulation.draftSortOrder4 = "ASC"
				end
			end
			menuScene.simulation.draftSort4 = sort
			
			scene:refreshSimulationTab();
		end
			
		local labels = {"Dft", "Tm", "Name", "Ovr", "Pot"}
		local labelsX = {20,125,250,550,700}
		local labelsSort = {
		"draftPos",
		"teamid",
		"name",
		"overall",
		"potential"}
		
		for i = 1, #labels do
			local label = display.newText(labels[i],labelsX[i],yPos, native.systemFont, 24);
			label.anchorX, label.anchorY = 0, 0;
			label:setFillColor(.8,.8,.8)
			label:addEventListener("tap",sort)
			label.sort = labelsSort[i]
			menuScene.simulation.elements[#menuScene.simulation.elements+1] = label
			
			if (menuScene.simulation.draftSort4 == label.sort) then
				label:setFillColor(1,0,0)
			end
		end

		
		local teams = {}
		
		local path = system.pathForFile("data.db", system.DocumentsDirectory)
		db = sqlite3.open( path ) 

		--Get teams
		for row in db:nrows([[SELECT * FROM teams ORDER BY id; ]]) do 
			teams[#teams+1] = row
		end
			
		--Show available draft prospects sorted by projection
		for row in db:nrows([[SELECT * FROM draft_players WHERE teamid IS NOT NULL ORDER BY ]] .. menuScene.simulation.draftSort4 .. [[ ]] 
			.. menuScene.simulation.draftSortOrder4 .. [[;]]) do 
			yPos = yPos+50
			
			local player
			for row in db:nrows([[SELECT * FROM players WHERE id = ]] .. row.player_id .. [[;]]) do 
				player = row
			end
			
			local function tap(event)
				scene:showPlayerCardPopup(player.id)
				return true
			end
			
			labels = {row.draftPos .. ".", teams[player.teamid].abv, 
				player.name .. " (" .. player.posType .. ")", player.overall, player.potential}
				
			for i = 1, #labels do
				local label = display.newText(labels[i] ,labelsX[i],yPos, native.systemFont, 18);
				label.anchorX, label.anchorY = 0, 0;
				menuScene.simulation.elements[#menuScene.simulation.elements+1] = label
				
				if (i == 3) then
					label:addEventListener("tap", tap)
				end
			end
		
		end
		
		db:close()
	end
	
	
	--Next day button
	if (showNextDay) then
	local function next_day(event)
		audio.play( globalSounds["tap"] )
		ss:nextDay(extraArg); --Use season simulator to advance a day
		scene:refreshSimulationTab();
	end
	local nextDay = display.newText("Next Day" , display.contentWidth - 10,title.y, native.systemFont, 24);
	nextDay.anchorX, nextDay.anchorY = 1, 0;
	nextDay:setFillColor(.8,.8,.8);
	nextDay:addEventListener("tap", next_day);
	menuScene.simulation.elements[#menuScene.simulation.elements+1] = nextDay
	end
	
	--Insert all elements into scrollview
	for i = 1, #menuScene.simulation.elements do
		menuScene.scrollView:insert(menuScene.simulation.elements[i]);
	end

	
end

function scene:simulationFreeAgency(day)

	local yPos = 10

	local title = display.newText( "Free Agency Day " .. day , 60,yPos, native.systemFont, 24);
	title.anchorX, title.anchorY = 0, 0;
	menuScene.simulation.elements[#menuScene.simulation.elements+1] = title
	
	local showNextDay = true;
	
	--Obtain the league schedule from the database
	local list
	local myteamid
	local teamName
	local day
	local payroll  = 0
	local projectedRevenue
	local FA_offers
	local FA_offer_commitments = 0 --Amount of money being offered to free agents currently
	local path = system.pathForFile("data.db", system.DocumentsDirectory)
	db = sqlite3.open( path )   

	--Get league information
	for row in db:nrows([[SELECT * FROM league;]])do
		list = row.recent_signings
		day = row.day
	end
	for row in db:nrows([[SELECT * FROM myteam;]])do
		myteamid = row.teamid
	end
	for row in db:nrows([[SELECT * FROM teams WHERE id = ]] .. myteamid .. [[;]])do
		teamName, FA_offers =  row.name, row.contract_offers
		local support, population, offers = row.support, row.population, row.contract_offers;
		projectedRevenue = at:determineRevenue(at:determineAttendance(support, population))
		projectedRevenue = projectedRevenue * 80 --Approx 80 home games a season
		projectedRevenue = projectedRevenue + ss.competitiveBalanceMoney --Competitive balance is also revenue
		projectedRevenue = projectedRevenue + tv:determineTVRevenue(population);
		
		if (offers ~= nil) then
			offers = json.decode(offers);
			for i = 1, #offers do
				FA_offer_commitments = FA_offer_commitments + offers[i].salary
			end
		
		end
	end
	for row in db:nrows([[SELECT * FROM players WHERE teamid = ]] .. myteamid .. [[;]]) do 
		payroll = payroll + row.salary
	end
	
	--Show FA Headquarters
	yPos = 80;
	local function f()
		scene:destroySimulationTab();
		menuScene.mode = "Free Agents";
		scene:showFreeAgentsTab()
		return true;
	end
	local sign = display.newText( "Sign Players"
		, 60,yPos, native.systemFont, 24);
	sign.anchorX, sign.anchorY = 0, 0;
	sign:setFillColor(.8,.8,.8);
	sign:addEventListener("tap", f);
	menuScene.simulation.elements[#menuScene.simulation.elements+1] = sign
	yPos = yPos + sign.height + 20;
	
	
	local function f2()
		scene:showTeamOffersPopup(FA_offers, teamName)
		return true;
	end
	local myOffers = display.newText( "View Your Offers"
		, 60,yPos, native.systemFont, 24);
	myOffers.anchorX, myOffers.anchorY = 0, 0;
	myOffers:setFillColor(.8,.8,.8);
	myOffers:addEventListener("tap", f2);
	menuScene.simulation.elements[#menuScene.simulation.elements+1] = myOffers
	yPos = yPos + myOffers.height + 40;
	
	--Box around sign players and view your offers
	local line = display.newLine( sign.x - 10 , sign.y - 10,
		sign.x + myOffers.width + 10,  sign.y - 10)
	line:setStrokeColor( 1, 1, 1, .5 )
	line.strokeWidth = 3
	menuScene.simulation.elements[#menuScene.simulation.elements+1] = line
	
	line = display.newLine( sign.x - 10 , myOffers.y + myOffers.height + 10,
		sign.x + myOffers.width + 10,  myOffers.y + myOffers.height + 10)
	line:setStrokeColor( 1, 1, 1, .5 )
	line.strokeWidth = 3
	menuScene.simulation.elements[#menuScene.simulation.elements+1] = line
	
	line = display.newLine( sign.x - 10 , sign.y - 10,
		sign.x - 10,  myOffers.y + myOffers.height + 10)
	line:setStrokeColor( 1, 1, 1, .5 )
	line.strokeWidth = 3
	menuScene.simulation.elements[#menuScene.simulation.elements+1] = line
	
	line = display.newLine( sign.x + myOffers.width + 10 , sign.y - 10,
		sign.x + myOffers.width + 10,  myOffers.y + myOffers.height + 10)
	line:setStrokeColor( 1, 1, 1, .5 )
	line.strokeWidth = 3
	menuScene.simulation.elements[#menuScene.simulation.elements+1] = line
	
	
	
	local projRevenue = display.newText( "Projected Revenue: $" .. scene:comma_value(projectedRevenue)
		, 50,yPos, native.systemFont, 24);
	projRevenue.anchorX, projRevenue.anchorY = 0, 0;
	menuScene.simulation.elements[#menuScene.simulation.elements+1] = projRevenue
	yPos = yPos + projRevenue.height + 20;
	
	local payroll = display.newText( "Current Payroll: $" .. scene:comma_value(payroll)
		, 50,yPos, native.systemFont, 24);
	payroll.anchorX, payroll.anchorY = 0, 0;
	menuScene.simulation.elements[#menuScene.simulation.elements+1] = payroll
	yPos = yPos + payroll.height + 20;
	
	local commit = display.newText( "FA Commitments: $" .. scene:comma_value(FA_offer_commitments)
		, 50,yPos, native.systemFont, 24);
	commit.anchorX, commit.anchorY = 0, 0;
	menuScene.simulation.elements[#menuScene.simulation.elements+1] = commit
	yPos = yPos + commit.height + 70;
	
	
	
	--Show Recent Signings
	
	if (list ~= nil) then
	list = json.decode(list);
	
	if (#list > 0) then
	local signedYst = display.newText( "Signed Yesterday:"
		, 50,yPos, native.systemFont, 24);
	signedYst.anchorX, signedYst.anchorY = 0, 0;
	menuScene.simulation.elements[#menuScene.simulation.elements+1] = signedYst
	yPos = yPos + signedYst.height + 50;
	
	line = display.newLine( signedYst.x - 5 , signedYst.y + signedYst.height + 5,
		signedYst.x + signedYst.width + 5,  signedYst.y + signedYst.height + 5)
	line:setStrokeColor( 1, 1, 1, .5 )
	line.strokeWidth = 3
	menuScene.simulation.elements[#menuScene.simulation.elements+1] = line
	end
	
	
	for i = 1, #list do
	
		local playerInfo, teamInfo;
		for row in db:nrows([[SELECT * FROM players WHERE id = ]] .. list[i].playerid .. [[;]])do
			playerInfo = row;
		end
		for row in db:nrows([[SELECT * FROM teams WHERE id = ]] .. list[i].teamid .. [[;]])do
			teamInfo = row;
		end
		
		local function tap(event)
			scene:showPlayerCardPopup(list[i].playerid);
			return true;
		end
		
		local list = {playerInfo.name .. " (" .. playerInfo.posType .. ")",
			teamInfo.abv, list[i].years .. " Yrs", "$ " .. scene:comma_value(list[i].salary)};
		local listX = {50,350,450,550};
		
		for i = 1, #list do
			local label = display.newText(list[i], listX[i],yPos, native.systemFont, 22);
			label.anchorX, label.anchorY = 0, 0;
			if (i==1) then 
				label:addEventListener("tap", tap); 
				label:setFillColor(.8,.8,.8);
			end
			menuScene.simulation.elements[#menuScene.simulation.elements+1] = label
		end

		

		
		yPos = yPos + 50
	end
	
	end
	
	db:close();
	
	
	--Next day button
	if (showNextDay) then

	--Default setting to simulate one game
	menuScene.simulation.num_days = 1;
	
	--Holds method held by timer; Allows for cancellation of the simulation
	--When user taps "Stop Simulation"
	local nextIteration;
	
	local function destroySimulationProgress()
		for i = 1, #menuScene.simulation.progress_elements do
			if (menuScene.simulation.progress_elements[i] ~= nil) then
				menuScene.simulation.progress_elements[i]:removeSelf();
				menuScene.simulation.progress_elements[i] = nil
			end
		end
		
		if (menuScene.simulation.progress_indicator ~= nil) then
			menuScene.simulation.progress_indicator:removeSelf();
			menuScene.simulation.progress_indicator = nil
		end
		
		if (menuScene.simulation.progress_info ~= nil) then
			menuScene.simulation.progress_info:removeSelf();
			menuScene.simulation.progress_info = nil
		end
	
		--Alert that simulation has finished
		audio.play( globalSounds["alert"] )
		
		--Allow phone to sleep after simulation
		system.setIdleTimer( true )
	end
	
	local function showSimulationProgress()
		--Show progress screen whenever simulation takes some time
		local black = display.newImage("Images/black.png", 0, 0);
		black.width, black.height = display.contentWidth, display.contentHeight
		black.anchorX, black.anchorY = 0,0
		black.alpha = .1;

		local function blockTouches(event)
			return true; --Block the propagation of any touches or taps
		end
		black:addEventListener("tap", blockTouches);
		black:addEventListener("touch", blockTouches);
		menuScene.simulation.progress_elements[#menuScene.simulation.progress_elements+1]  = black;
		
		--Popup Background
		local popup = display.newImage("Images/popup.png", display.contentCenterX, display.contentCenterY);
		popup.width, popup.height = display.contentWidth/2, display.contentHeight/2
		popup.anchorX, popup.anchorY = .5,.5
		menuScene.simulation.progress_elements[#menuScene.simulation.progress_elements+1]  = popup;
		
		--Indicates what day we have simulated
		local indicator = display.newText("Simulating...", display.contentCenterX, 
			display.contentCenterY - 50, native.systemFont, 24);
		indicator.anchorX, indicator.anchorY =.5, 0;
		menuScene.simulation.progress_indicator = indicator
		
		--More information for indicator
		local info = display.newText("", display.contentCenterX, 
			indicator.y + indicator.height + 20, native.systemFont, 24);
		info.anchorX, info.anchorY =.5, 0;
		menuScene.simulation.progress_info = info
		
		--Allows for stoppage of simulation
		local function stopSimulation()
			if (nextIteration ~= nil) then
				timer.cancel(nextIteration)
			end
			--Destroy simulaion progress popup
			destroySimulationProgress();
			--Finished simulation, refresh tab to show final results
			scene:refreshSimulationTab();
		end
		
		local stop = display.newText("Stop Simulation", display.contentCenterX, 
			info.y + info.height + 30, native.systemFont, 24);
		stop.anchorX, stop.anchorY =.5, 0;
		stop:setFillColor(.8,.8,.8);
		stop:addEventListener("tap", stopSimulation);
		menuScene.simulation.progress_elements[#menuScene.simulation.progress_elements+1] = stop
		

	end
	
	--Simulate "Button"
	local function simulate_day(event)
	
		audio.play( globalSounds["tap"] )
		
		--Prevent phone from sleeping during simulation
		system.setIdleTimer( false )
		
		local final_day = (day + menuScene.simulation.num_days - 1); --Index of final day to simulate

		local function iterate(day)
			--Update the current mode of the simulation
			local mode
			local path = system.pathForFile("data.db", system.DocumentsDirectory)
			db = sqlite3.open( path ) 
			for row in db:nrows([[SELECT * FROM league;]])do
				mode = row.mode
			end
			db:close()
			
			--If mode is no longer free agency end simulation
			if (mode ~= "Free Agency") then 
				print ("Break test") 
				destroySimulationProgress();
				scene:refreshSimulationTab();
				return
			end
			
			--Simulate day in free agency
			ss:nextDay();
			
			--Iterate to next day
			local nextDay = day + 1;
			if (nextDay <= final_day) then 
				local function f()
					iterate(nextDay)
				end
				--Perform next iteration after a delay. The delay allows us to update a few graphics
				--Without this delay, we cannot update any graphics, b/c Corona has no multi-threading capabilities
				nextIteration = timer.performWithDelay( 1000 , 	f);
				menuScene.simulation.progress_indicator.text = "Simulated Day " .. day
				--menuScene.simulation.progress_info.text = "Blank"
			else
				--Simulation is over
				destroySimulationProgress();
				scene:refreshSimulationTab();
			end
			

		end
		
		showSimulationProgress();
		
		local function startIteration()
			--Begin iteration through the days (Go through schedule and simulate games)
			iterate(day);
		end
		
		--Delay iteration a little to give simulation progress popup chance to load
		nextIteration = timer.performWithDelay(500, startIteration);
		
	end
	
	local simulate = display.newText("Simulate " .. menuScene.simulation.num_days .. " Day" ,
		display.contentWidth - 10,title.y, native.systemFont, 24);
	simulate.anchorX, simulate.anchorY = 1, 0;
	simulate:setFillColor(.8,.8,.8);
	simulate:addEventListener("tap", simulate_day);
	menuScene.simulation.elements[#menuScene.simulation.elements+1] = simulate
	
	
	--Num Days Stepper
	local dayStepper
	
	local function onStepperPress2( event )
		if (event.value == 1) then --One day
			menuScene.simulation.num_days = 1
			simulate.text = "Simulate " .. menuScene.simulation.num_days .. " Day"
		elseif (event.value == 2) then --One Week
			menuScene.simulation.num_days = 7
			simulate.text = "Simulate " .. menuScene.simulation.num_days .. " Days"
		elseif (event.value == 3) then --One Month
			menuScene.simulation.num_days = 30
			simulate.text = "Simulate " .. menuScene.simulation.num_days .. " Days"
		else	--Variable num days
			menuScene.simulation.num_days = event.value-2
			simulate.text = "Simulate " .. menuScene.simulation.num_days .. " Days"
		end
		
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
	dayStepper = widget.newStepper
	{
		initialValue = 1,
		minimumValue = 1,
		maximumValue = 165,
		x = simulate.x,
		y = simulate.y + simulate.height + 10,
		width = 100,
		height = 50,
		sheet = stepperSheet,
		defaultFrame = 1,
		noMinusFrame = 2,
		noPlusFrame = 3,
		minusActiveFrame = 4,
		plusActiveFrame = 5,
		onPress = onStepperPress2
	}
	dayStepper.anchorX, dayStepper.anchorY = 1, 0;
	menuScene.simulation.elements[#menuScene.simulation.elements+1] = dayStepper;

	
	end
	
	--Insert all elements into scrollview
	for i = 1, #menuScene.simulation.elements do
		menuScene.scrollView:insert(menuScene.simulation.elements[i]);
	end

	
end

function scene:destroySimulationTab()

	for i = 1, #menuScene.simulation.elements do
		if (menuScene.simulation.elements[i] ~= nil) then
			menuScene.simulation.elements[i]:removeSelf();
			menuScene.simulation.elements[i] = nil
		end
	end


end


--Draft Order Popup
function scene:showDraftOrderPopup(id)
	
	--Semi-transparent black background that covers whole screen and blocks touches
	local black = display.newImage("Images/black.png", 0, 0);
	black.width, black.height = display.contentWidth, display.contentHeight
	black.anchorX, black.anchorY = 0,0
	black.alpha = .9;
	
	--Ghost element
	local topLabel = display.newText("", 0, 0, native.systemFont, 36);
	menuScene.draftOrderPopup.elements[#menuScene.draftOrderPopup.elements+1] = topLabel;
	
	
	local function blockTouches(event)
		return true; --Block the propagation of any touches or taps
	end
	black:addEventListener("tap", blockTouches);
	black:addEventListener("touch", blockTouches);
	menuScene.draftOrderPopup.bg  = black;
	

	
	--Rig popup scroll view - covers entire screen
	menuScene.draftOrderPopup.scrollView = widget.newScrollView {
		backgroundColor = { 0, 1, .3, 0 },
		x = display.contentCenterX,
		y = display.contentCenterY,
		width = display.contentWidth,
		height = display.contentHeight,
		horizontalScrollDisabled = false,
		verticalScrollDisabled = false
	  }

	  
	 local function destroy(event)
		if (event.phase == "ended") then scene:destroyDraftOrderPopup(); end
	end
	--Exit button
	menuScene.draftOrderPopup.exit = widget.newButton
	{
		x = display.contentWidth,
		y = display.contentHeight,
		defaultFile = "Images/x.png",
		onEvent = destroy
	}
	menuScene.draftOrderPopup.exit.anchorX, menuScene.draftOrderPopup.exit.anchorY = 1, 1; 
	--menuScene.draftOrderPopup.scrollView:insert(menuScene.draftOrderPopup.exit);
	
	local yPos = 10
	local nameLabel = display.newText( "Draft Order", 60, yPos, native.systemFont, 30 )
	nameLabel.anchorX, nameLabel.anchorY = 0,0;
	menuScene.draftOrderPopup.elements[#menuScene.draftOrderPopup.elements+1] = nameLabel;
	yPos = yPos+50
	
	--Get prospect information from the database
	local draft_selections; --Of the prospect
	local teams = {}

	local path = system.pathForFile("data.db", system.DocumentsDirectory)
	db = sqlite3.open( path )   
	for row in db:nrows([[SELECT * FROM draft;]]) do 
		draft_selections = json.decode(row.draft_selections)
	end
	for row in db:nrows([[SELECT * FROM teams ORDER BY id;]]) do 
		teams[#teams+1] = row.name
	end
	
	db:close();
	
	for i = 1, #draft_selections/3 do --Only show order of first round
		yPos = yPos+50
		local teamLabel = display.newText( i .. ". " .. teams[draft_selections[i]], 60, yPos, native.systemFont, 30 )
		teamLabel.anchorX, teamLabel.anchorY = 0,0;
		menuScene.draftOrderPopup.elements[#menuScene.draftOrderPopup.elements+1] = teamLabel;
	
	end

	--Add all the elements to a scroll view
	for i = 1, #menuScene.draftOrderPopup.elements do
		--print("Inserted item " .. i);
		menuScene.draftOrderPopup.scrollView:insert(menuScene.draftOrderPopup.elements[i]);
	end
	
	

end

function scene:destroyDraftOrderPopup()

	for i = 1, #menuScene.draftOrderPopup.elements do
		if (menuScene.draftOrderPopup.elements[i] ~= nil) then
			menuScene.draftOrderPopup.elements[i]:removeSelf();
			menuScene.draftOrderPopup.elements[i] = nil;
		end
	end
	menuScene.draftOrderPopup.elements = {};
	
	if (menuScene.draftOrderPopup.bg ~= nil) then
		menuScene.draftOrderPopup.bg:removeSelf();
		menuScene.draftOrderPopup.bg = nil
	end
	
	if (menuScene.draftOrderPopup.exit ~= nil) then
		menuScene.draftOrderPopup.exit:removeSelf();
		menuScene.draftOrderPopup.exit = nil
	end
	
	if (menuScene.draftOrderPopup.scrollView ~= nil) then
		menuScene.draftOrderPopup.scrollView:removeSelf();
		menuScene.draftOrderPopup.scrollView = nil
	end
	
end



--Free agents tab
function scene:showFreeAgentsTab()
	
	--Free Agents Tab Label
	local title = display.newText(  "Free Agents", 60, 10, native.systemFont, 36 )
	title.anchorX, title.anchorY = 0,0
	menuScene.scrollView:insert(title);
	menuScene.freeAgents.elements[#menuScene.freeAgents.elements+1] = title;
	
	
	 --Add arrows
	local function left(event)
		if (event.phase == "ended") then
			scene:freeAgentsRemovePlayerStats();
			menuScene.freeAgents.offset = menuScene.freeAgents.offset - menuScene.freeAgents.limit;
			if (menuScene.freeAgents.offset < 0) then menuScene.freeAgents.offset = 0; end
			scene:freeAgentsRefreshPlayerStats();
		end
		return true
	end
	local function right(event)
		if (event.phase == "ended") then
		scene:freeAgentsRemovePlayerStats();
		menuScene.freeAgents.offset = menuScene.freeAgents.offset + menuScene.freeAgents.limit;
		
		local maxOffset = (math.ceil(menuScene.freeAgents.count / menuScene.freeAgents.limit)-1) * menuScene.freeAgents.limit;
		if (menuScene.freeAgents.offset > maxOffset) then
			menuScene.freeAgents.offset = maxOffset;
		end
		scene:freeAgentsRefreshPlayerStats();
		end
		return true
	
	end
	
	--Left button
	menuScene.freeAgents.leftArrow = widget.newButton
	{
		x = 650,
		y = 400,
		defaultFile = "Images/left.png",
		onEvent = left
	}
	menuScene.freeAgents.leftArrow.anchorX, menuScene.freeAgents.leftArrow.anchorY = 0, 0; 
	self.view:insert(menuScene.freeAgents.leftArrow);
	
	--Right button
	menuScene.freeAgents.rightArrow = widget.newButton
	{
		x = 750,
		y = 400,
		defaultFile = "Images/right.png",
		onEvent = right
	}
	menuScene.freeAgents.rightArrow.anchorX, menuScene.freeAgents.rightArrow.anchorY = 0, 0; 
	self.view:insert(menuScene.freeAgents.rightArrow);
	
	--Add top, bottom buttons
	menuScene.freeAgents.top =  display.newText(  "Top", 500, 425, native.systemFont, 20 )
	menuScene.freeAgents.top.anchorX,  menuScene.freeAgents.top.anchorY = 0, .5;
	menuScene.freeAgents.top:setFillColor(1,1,1,.5); 
	self.view:insert(menuScene.freeAgents.top);
	function menuScene.freeAgents.top:tap( event )
		scene:freeAgentsRemovePlayerStats();
		menuScene.freeAgents.offset = 0;
		scene:freeAgentsRefreshPlayerStats();
		return true
	end 
	menuScene.freeAgents.top:addEventListener( "tap", menuScene.freeAgents.top);
	
	menuScene.freeAgents.bottom =  display.newText(  "Bottom", 570, 425, native.systemFont, 20 )
	menuScene.freeAgents.bottom.anchorX,  menuScene.freeAgents.bottom.anchorY = 0, .5;
	menuScene.freeAgents.bottom:setFillColor(1,1,1,.5); 
	self.view:insert(menuScene.freeAgents.bottom);
	function menuScene.freeAgents.bottom:tap( event )
		scene:freeAgentsRemovePlayerStats();
		
		local maxOffset = (math.ceil(menuScene.freeAgents.count / menuScene.freeAgents.limit)-1) * menuScene.freeAgents.limit;
		menuScene.freeAgents.offset = maxOffset;
		
		scene:freeAgentsRefreshPlayerStats();
		return true
	end 
	menuScene.freeAgents.bottom:addEventListener( "tap", menuScene.freeAgents.bottom);
	
	
	--Add position stepper (limit data shown to certain position)
	-- Handle stepper events
	
	local function onStepperPress2( event )
	
		menuScene.freeAgents.positionStepper:setValue(1); --Ignore the built in corona stepper counter, it messes things up
		if ( "increment" == event.phase ) then
			menuScene.freeAgents.positionCounter = menuScene.freeAgents.positionCounter + 1
			if (menuScene.freeAgents.positionCounter > #menuScene.freeAgents.positions) then --Loop to the start
				menuScene.freeAgents.positionCounter = 1
			end
		elseif ( "decrement" == event.phase ) then
			menuScene.freeAgents.positionCounter = menuScene.freeAgents.positionCounter - 1
			if (menuScene.freeAgents.positionCounter < 1) then --Loop to the end
				menuScene.freeAgents.positionCounter = #menuScene.freeAgents.positions
			end
		end
		--print("Counter: " .. menuScene.freeAgents.positionCounter);
		menuScene.freeAgents.positionDisplay.text  = menuScene.freeAgents.positions[menuScene.freeAgents.positionCounter];
		menuScene.freeAgents.offset = 0;
		scene:freeAgentsRemovePlayerStats();
		scene:freeAgentsRefreshPlayerStats();
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
	menuScene.freeAgents.positionStepper = widget.newStepper
	{
		initialValue = 10,
		x = title.x + title.width + 25,
		y = title.y + (title.height/2),
		width = 100,
		height = 50,
		sheet = stepperSheet,
		defaultFrame = 1,
		noMinusFrame = 2,
		noPlusFrame = 3,
		minusActiveFrame = 4,
		plusActiveFrame = 5,
		onPress = onStepperPress2
	}
	menuScene.freeAgents.positionStepper.anchorX, menuScene.freeAgents.positionStepper.anchorY = 0, 0.5;
	menuScene.scrollView:insert(menuScene.freeAgents.positionStepper);
	
	local xPos = menuScene.freeAgents.positionStepper.x + menuScene.freeAgents.positionStepper.width + 5
	local yPos = menuScene.freeAgents.positionStepper.y
	menuScene.freeAgents.positionDisplay = display.newText( menuScene.freeAgents.positions[menuScene.freeAgents.positionCounter], xPos, yPos, native.systemFont, 20 )
	menuScene.freeAgents.positionDisplay.anchorX,  menuScene.freeAgents.positionDisplay.anchorY = 0, .5;
	menuScene.freeAgents.positionDisplay:setFillColor(1,1,1); 
	menuScene.scrollView:insert(menuScene.freeAgents.positionDisplay);
		
	--Add data to the table
	scene:freeAgentsRefreshPlayerStats();
	scene:freeAgentsUpdateLabels();
	

end

function scene:freeAgentsUpdateLabels()

	--Show labels above the statistics, indicating the type of stats (for example: overall, speed, age, salary, etc.);
	
	--Remove all labels
	for i = 1, #menuScene.freeAgents.labels do
		if (menuScene.freeAgents.labels[i] ~= nil) then
			menuScene.freeAgents.labels[i]:removeSelf();
			menuScene.freeAgents.labels[i] = nil
		end
	end
	menuScene.freeAgents.labels = {}
	
	--Add labels above the table
	local yPos =  100
	
	--Label touch listeners (When you touch the label, it sorts by the column);
	local function tap( event )
	
		audio.play( globalSounds["tap"] )
		
		if (event.target.text == "Tm") then 
		scene:freeAgentsSortBy([[(SELECT abv	FROM teams WHERE id = players.teamid)]]); --SQLite code that sorts by team name
		elseif (event.target.text == "Pos") then scene:freeAgentsSortBy("posType");
		elseif (event.target.text == "Name") then scene:freeAgentsSortBy("name");
		elseif (event.target.text == "Age") then scene:freeAgentsSortBy("age");
		elseif (event.target.text == "Con") then scene:freeAgentsSortBy("contact");
		elseif (event.target.text == "Pow") then scene:freeAgentsSortBy("power");
		elseif (event.target.text == "Eye") then scene:freeAgentsSortBy("eye");
		elseif (event.target.text == "Vel") then scene:freeAgentsSortBy("velocity");
		elseif (event.target.text == "Nst") then scene:freeAgentsSortBy("nastiness");
		elseif (event.target.text == "Ctl") then scene:freeAgentsSortBy("control");
		elseif (event.target.text == "Stm") then scene:freeAgentsSortBy("stamina");
		elseif (event.target.text == "Spe") then scene:freeAgentsSortBy("speed");
		elseif (event.target.text == "Def") then scene:freeAgentsSortBy("defense");
		elseif (event.target.text == "Dur") then scene:freeAgentsSortBy("durability");
		elseif (event.target.text == "Iq") then scene:freeAgentsSortBy("iq");
		elseif (event.target.text == "Sal Wanted") then scene:freeAgentsSortBy("FA_salary_wanted");
		elseif (event.target.text == "Yrs Wanted") then scene:freeAgentsSortBy("FA_years_wanted");
		elseif (event.target.text == "Ovr") then scene:freeAgentsSortBy("overall");
		elseif (event.target.text == "Pot") then scene:freeAgentsSortBy("potential");
		end
		
		--Labels that that the table is not sorted by should be white
		for i = 1, #menuScene.freeAgents.labels do
			menuScene.freeAgents.labels[i]:setFillColor(.8,.8,.8)
		end
		--Mark the selected label by changing the colour to red
		event.target:setFillColor(1,0,0);
		return true
	end 
	
	local labels = {}
	local labelsX = {}

	--Show player ratings labels
	labels = {"Tm", "Pos", "Name", "Age", "Ovr", "Pot", "Con", "Pow", "Eye", "Vel", "Nst", "Ctl", "Stm", "Spe", "Def", "Dur", "Iq", "Sal Wanted", "Yrs Wanted"}
	labelsX = {160,225,300,600,675,750,825,900,975,1050,1125,1200,1275,1350,1425,1500,1575,1650,1875}

	
	--Render labels
	for i =1, #labels do
		menuScene.freeAgents.labels[i] =  display.newText(labels[i], labelsX[i], yPos, native.systemFont, 24 )
		menuScene.freeAgents.labels[i].anchorX,  menuScene.freeAgents.labels[i].anchorY = 0, 0;
		menuScene.freeAgents.labels[i]:setFillColor(.8,.8,.8)
		
		if (i == 3) then
			menuScene.freeAgents.labels[i]:setFillColor(1,0,0);
			menuScene.freeAgents.sort = "Name"
			scene:freeAgentsSortBy("name");
		end
		
		
		menuScene.scrollView:insert(menuScene.freeAgents.labels[i]);
		menuScene.freeAgents.labels[i]:addEventListener( "tap", tap );
	end

end

function scene:freeAgentsRefreshPlayerStats()

	--Show player data
	local path = system.pathForFile("data.db", system.DocumentsDirectory)
	db = sqlite3.open( path )   

	--Determine number of rows generated from query
	local count = 0;
	--Generate the appropriate query to get the count
	local modifiedQuery;
	
	--positions = {"ALL", "BATTERS", "1B", "2B", "SS", "3B", "OF", "C", "PITCHERS", "SP", "RP"}
	if (menuScene.freeAgents.positionCounter == 1) then --All positions
		modifiedQuery = [[SELECT Count(*) FROM players WHERE teamid = 31]]
	elseif (menuScene.freeAgents.positionCounter == 2) then --Limit to Batters
		modifiedQuery = [[SELECT Count(*) FROM players WHERE (posType = "1B" or posType = "2B" or posType = "SS" or posType = "3B" or posType = "OF" or posType = "C")  AND teamid = 31;]]
	elseif (menuScene.freeAgents.positionCounter == 9) then --Limit to Pitchers
		modifiedQuery = [[SELECT Count(*) FROM players WHERE (posType = "SP" or posType = "RP") AND teamid = 31;]]
	else --Limit to certain position type
		modifiedQuery = [[SELECT Count(*) FROM players WHERE posType = "]] .. menuScene.freeAgents.positions[menuScene.freeAgents.positionCounter] .. [["  AND teamid = 31;]]
	end

	print("Modified Query: " .. modifiedQuery);
	for row in db:rows(modifiedQuery) do  
		count = row[1] 
	end
	menuScene.freeAgents.count = count;
	print("Count: " .. count);
	
	--Offset can't be greater than number of elements in database table
	if (menuScene.freeAgents.offset >= count) then
		menuScene.freeAgents.offset = count-menuScene.freeAgents.limit;
	end
	print("Offset: " .. menuScene.freeAgents.offset);
	
	
	--Fill in the rows with pertinent database information
	--Start at row offset + 1, limit = #elements
	local n = 0;
	local query;
	
	--Determine Actual Query
	
	query = [[SELECT * FROM players ]]
	--positions = {"ALL", "BATTERS", "1B", "2B", "SS", "3B", "OF", "C", "PITCHERS", "SP", "RP"}
	if (menuScene.freeAgents.positionCounter == 1) then --All positions
		query = query .. [[ WHERE teamid = 31 ]]
	elseif (menuScene.freeAgents.positionCounter == 2) then --Limit to Batters
		query = query .. [[ WHERE (posType = "1B" or posType = "2B" or posType = "SS" or posType = "3B" or posType = "OF" or posType = "C")  AND teamid = 31 ]]
	elseif (menuScene.freeAgents.positionCounter == 9) then --Limit to Pitchers
		query = query .. [[ WHERE (posType = "SP" or posType = "RP")  AND teamid = 31 ]]
	else --Limit to certain position type
		query = query .. [[ WHERE posType = "]] .. menuScene.freeAgents.positions[menuScene.freeAgents.positionCounter] .. [["  AND teamid = 31 ]]
	end
	query = query .. [[ORDER BY ]] .. menuScene.freeAgents.sort .. [[ ]] .. menuScene.freeAgents.sortOrder ..
		[[ LIMIT ]] .. menuScene.freeAgents.limit .. [[ OFFSET ]] .. menuScene.freeAgents.offset ..[[;]]

	print("ACTUAL QUERY: " .. query);
	
	
	--Actual query, populate data table
	for row in db:nrows(query) do

	
	n = n+1;
	local teamName = "FA"
	for row in db:nrows([[SELECT * FROM teams WHERE id = ]] .. row.teamid .. [[;]])do
		teamName = row.abv;
	end
	
	--Generate the text used to display stats
	local labels
	local labelsX
	
	--Show player ratings labels
	labels = {menuScene.freeAgents.offset+n, "SIGN", teamName, row.posType, row.name, row.age, row.overall,
		row.potential, row.contact, row.power, row.eye, row.velocity, row.nastiness, row.control, row.stamina, row.speed,
		row.defense, row.durability,
		row.iq, "$" .. scene:comma_value(row.FA_salary_wanted), row.FA_years_wanted}
	labelsX = {10,85,160,225,300,600,675,750,825,900,975,1050,1125,1200,1275,1350,1425,1500,1575,1650,1875}
	

	local function tap( event )
		print(row.name .. "(Player ID): " .. row.id);
		scene:showPlayerCardPopup(row.id);
		return true;
	end 
	local function negotiate(event)
		scene:showNegotiationPopup(row.id);
		return true;
	end
	for i = 1, #labels do
		local num = #menuScene.freeAgents.stats+1 ;
		menuScene.freeAgents.stats[num] =  display.newText( labels[i], labelsX[i], (n+2) * 50, native.systemFont, 24 )
		menuScene.freeAgents.stats[num].anchorX, menuScene.freeAgents.stats[num].anchorY = 0, 0;
		--menuScene.freeAgents.stats[num]:setFillColor(1,1,1); 
		menuScene.scrollView:insert(menuScene.freeAgents.stats[num])
		
		if (i == 2) then
			--When you tap the sign label, open negotiations popup
			menuScene.freeAgents.stats[num]:setFillColor(.8,.8,.8)
			menuScene.freeAgents.stats[num]:addEventListener( "tap", negotiate );
		end
		
		if (i == 5) then
			--When the name of the player is touched, display his player card
			menuScene.freeAgents.stats[num]:addEventListener( "tap", tap );

			--Change color of free agent name based off mood
			if (row.FA_mood <= 25) then
			menuScene.freeAgents.stats[num]:setFillColor( .8, .1, .1 )
			elseif (row.FA_mood <= 75) then
			menuScene.freeAgents.stats[num]:setFillColor( .85, .85, 0 )
			else
			menuScene.freeAgents.stats[num]:setFillColor( 0, .4, 0 )
			end
			
			--If player is injured, show the injury picture beside his name
			if (row.injury > 0) then
				local playerLabel = menuScene.freeAgents.stats[num];
				local num = #menuScene.freeAgents.stats+1 ;
				menuScene.freeAgents.stats[num] =  display.newImage("Images/injury.png", playerLabel.x + playerLabel.width + 10, playerLabel.y + playerLabel.height/2)
				menuScene.freeAgents.stats[num].anchorX, menuScene.freeAgents.stats[num].anchorY = 0, .5;
				menuScene.freeAgents.stats[num].width, menuScene.freeAgents.stats[num].height = playerLabel.height, playerLabel.height
				menuScene.scrollView:insert(menuScene.freeAgents.stats[num])
			end
		end
	end
	
	
	
	end
	
	db:close();
	



end

function scene:freeAgentsRemovePlayerStats()
	
	for i = 1, #menuScene.freeAgents.stats do
		--Remove all stats from menuScene.scrollView
		if (menuScene.freeAgents.stats[i] ~= nil) then
			menuScene.freeAgents.stats[i]:removeSelf();
			menuScene.freeAgents.stats[i] = nil;
		end
	end
	menuScene.freeAgents.stats = {};
	
end

function scene:freeAgentsSortBy(sort)

	menuScene.freeAgents.offset = 0;
	if (sort == menuScene.freeAgents.sort) then
		--Reverse order of the sort
		if (menuScene.freeAgents.sortOrder == "ASC") then
			menuScene.freeAgents.sortOrder = "DESC"
		else
			menuScene.freeAgents.sortOrder = "ASC"
		end
	end
	
	menuScene.freeAgents.sort = sort;
	scene:freeAgentsRemovePlayerStats();
	scene:freeAgentsRefreshPlayerStats();
	
end

function scene:destroyFreeAgentsTab()
	menuScene.freeAgents.sort = "name";

	for i = 1, #menuScene.freeAgents.elements do
		if (menuScene.freeAgents.elements[i] ~= nil) then
			menuScene.freeAgents.elements[i]:removeSelf();
			menuScene.freeAgents.elements[i] = nil;
		end
	end
	menuScene.freeAgents.elements = {}
	
	for i = 1, #menuScene.freeAgents.stats do
		if(menuScene.freeAgents.stats[i] ~= nil) then
			menuScene.freeAgents.stats[i]:removeSelf();
			menuScene.freeAgents.stats[i] = nil
		end
	end
	menuScene.freeAgents.stats = {}
	
	for i = 1, #menuScene.freeAgents.labels do
		if(menuScene.freeAgents.labels[i] ~= nil) then
			menuScene.freeAgents.labels[i]:removeSelf();
			menuScene.freeAgents.labels[i] = nil
		end
	end
	menuScene.freeAgents.labels = {}
	
	if(menuScene.freeAgents.leftArrow ~= nil) then
		menuScene.freeAgents.leftArrow:removeSelf();
		menuScene.freeAgents.leftArrow = nil
	end
	
	if(menuScene.freeAgents.rightArrow ~= nil) then
		menuScene.freeAgents.rightArrow:removeSelf();
		menuScene.freeAgents.rightArrow = nil
	end
	
	if(menuScene.freeAgents.top ~= nil) then
		menuScene.freeAgents.top:removeSelf();
		menuScene.freeAgents.top = nil
	end
	
	if(menuScene.freeAgents.bottom ~= nil) then
		menuScene.freeAgents.bottom:removeSelf();
		menuScene.freeAgents.bottom = nil
	end
	
	if(menuScene.freeAgents.positionStepper ~= nil) then
		menuScene.freeAgents.positionStepper:removeSelf();
		menuScene.freeAgents.positionStepper = nil
	end
	
	if(menuScene.freeAgents.positionDisplay ~= nil) then
		menuScene.freeAgents.positionDisplay:removeSelf();
		menuScene.freeAgents.positionDisplay = nil
	end
	
end


--League Tab (Standings)

function scene:showLeagueTab()
	
	local year, mode, day
	local teams = {}
	
	local path = system.pathForFile("data.db", system.DocumentsDirectory)
	db = sqlite3.open( path )   

	--Get league information
	for row in db:nrows([[SELECT * FROM league;]])do
		mode = row.mode;
		year = row.year;
		day = row.day;
	end
	
	--Get list of teams
	for row in db:nrows([[SELECT * FROM teams ORDER BY win DESC, runsScored DESC, runsAllowed ASC, RANDOM(); ]]) do 
		teams[#teams+1] = row;
	end
	
	db:close();
	
	local yPos = 25
	local league =  display.newText(year .. " " .. mode .. " -  Day " .. day, 60, yPos, native.systemFont, 32 )
	league.anchorX, league.anchorY = 0, 0.5;
	menuScene.league.elements[#menuScene.league.elements+1] = league
	
	
	yPos = yPos+60
	local standings =  display.newText("League Standings", 60, yPos, native.systemFont, 32 )
	standings.anchorX, standings.anchorY = 0, 0;
	menuScene.league.elements[#menuScene.league.elements+1] = standings
	
	local line = display.newLine( standings.x , standings.y + standings.height + 5, standings.x + standings.width,  standings.y + standings.height + 5 )
	line:setStrokeColor( 1, 1, 1, .5 )
	line.strokeWidth = 3
	menuScene.league.elements[#menuScene.league.elements+1] = line
	
	yPos = yPos + 50
	for i = 1, #teams do
		yPos = yPos + 50
		local team = teams[i]
		
		local num =  display.newText(i .. ".", 60, yPos, native.systemFont, 24 )
		num.anchorX, num.anchorY = 0, 0.5;
		menuScene.league.elements[#menuScene.league.elements+1] = num
		
		local teamabv =  display.newText(team.name .. " (" .. team.abv .. ")", 135, yPos, native.systemFont, 24 )
		teamabv.anchorX, teamabv.anchorY = 0, 0.5;
		--teamabv:setFillColor(.8,.8,.8,1);
		menuScene.league.elements[#menuScene.league.elements+1] = teamabv
		
		teamabv:addEventListener("tap", 
		function() 
			scene:changeMode("Team Card", team.id); 
		return true end)
		
		local record =  display.newText(team.win .. " - " .. team.loss, 500, yPos, native.systemFont, 24 )
		record.anchorX, record.anchorY = 0, 0.5;
		menuScene.league.elements[#menuScene.league.elements+1] = record
	end
		
		
	local function f()
		scene:showLeagueHistoryPopup();
		return true;
	end
	yPos = 25
	local viewHistory = display.newText( "League History" , display.contentWidth - 10, yPos, native.systemFont, 24 )
	viewHistory.anchorX, viewHistory.anchorY = 1,.5
	viewHistory:addEventListener("tap", f);
	viewHistory:setFillColor(.8,.8,.8)
	menuScene.league.elements[#menuScene.league.elements+1] =viewHistory;
	
	
	for i = 1, #menuScene.league.elements do
		menuScene.scrollView:insert(menuScene.league.elements[i]);
	end

end

function scene:destroyLeagueTab()

	for i = 1, #menuScene.league.elements do
		if (menuScene.league.elements[i] ~= nil) then
			menuScene.league.elements[i]:removeSelf();
			menuScene.league.elements[i] = nil
		end
	end


end

--Show league history
function scene:showLeagueHistoryPopup()
	--Info is a decoded table containing all free agent offers
	--Semi-transparent black background that covers whole screen and blocks touches
	local black = display.newImage("Images/black.png", 0, 0);
	black.width, black.height = display.contentWidth, display.contentHeight
	black.anchorX, black.anchorY = 0,0
	black.alpha = .9;
	
	--Ghost element
	local topLabel = display.newText("", 0, 0, native.systemFont, 36);
	menuScene.leagueHistoryPopup.elements[#menuScene.leagueHistoryPopup.elements+1] = topLabel;
	
	
	local function blockTouches(event)
		return true; --Block the propagation of any touches or taps
	end
	black:addEventListener("tap", blockTouches);
	black:addEventListener("touch", blockTouches);
	menuScene.leagueHistoryPopup.bg  = black;
	
	menuScene.leagueHistoryPopup.scrollView = widget.newScrollView {
		backgroundColor = { 0, 1, .3, 0 },
		x = display.contentCenterX,
		y = display.contentCenterY,
		width = display.contentWidth,
		height = display.contentHeight,
		horizontalScrollDisabled = true,
		verticalScrollDisabled = false
	}
	
	
	
	local function destroy(event)
		if (event.phase == "ended") then scene:destroyLeagueHistoryPopup(); end
	end
	--Exit button
	menuScene.leagueHistoryPopup.exit = widget.newButton
	{
		x = display.contentWidth,
		y = display.contentHeight,
		defaultFile = "Images/x.png",
		onEvent = destroy
	}
	menuScene.leagueHistoryPopup.exit.anchorX, menuScene.leagueHistoryPopup.exit.anchorY = 1, 1; 
	
	local history = {}
	local sortedHistory = {}
	local teams = {}

	local path = system.pathForFile("data.db", system.DocumentsDirectory)
	db = sqlite3.open( path )  
	
	for row in db:nrows([[SELECT * FROM teams;]])do
		teams[#teams+1] = row
	end
	for row in db:nrows([[SELECT * FROM awards WHERE award = "Champions" or award = "Runnerup";]])do
		if (history[row.year] == nil) then
			history[row.year] = {year = row.year, champion = "nil", runnerup = "nil"}
		end
		if (row.award == "Champions") then
			history[row.year].champion = teams[row.teamid].name;
		else
			history[row.year].runnerup = teams[row.teamid].name;
		end
	end
	
	
	--Sort history by year
	for k,v in pairs(history) do
		sortedHistory[#sortedHistory+1] = v;
	end
	function byval(a,b)
        return a.year < b.year
    end
	table.sort(sortedHistory,byval)
	
	db:close();	
	
	
	--Team Name Label
	local leagueLabel = display.newText("League History", 20, 20, native.systemFont, 36);
	leagueLabel.anchorX, leagueLabel.anchorY = 0, 0;
	menuScene.leagueHistoryPopup.elements[#menuScene.leagueHistoryPopup.elements+1] = leagueLabel;
	
	--Dividing line
	local line = display.newLine( 10, leagueLabel.y + leagueLabel.height + 10, 
		display.contentWidth - 10, leagueLabel.y + leagueLabel.height + 10 )
	line:setStrokeColor( 1, 1, 1, .5 )
	line.strokeWidth = 3
	menuScene.leagueHistoryPopup.elements[#menuScene.leagueHistoryPopup.elements+1] = line

	--Display labels
	local labels = {"Year", "Champion", "Runnerup"}
	local labelsX = {20, 200,500}
	yPos = line.y + 20
	for i = 1, #labels do
		local infoLabel = display.newText(labels[i], labelsX[i], yPos, native.systemFont, 24);
		infoLabel.anchorX, infoLabel.anchorY = 0,0;
		menuScene.leagueHistoryPopup.elements[#menuScene.leagueHistoryPopup.elements+1] = infoLabel;
	end
	--Display data
	yPos = yPos + 35
	for i = 1, #sortedHistory do
	
		local row = sortedHistory[i]
		local labels = {row.year, row.champion, row.runnerup}
		
		for i = 1, #labels do
			local infoLabel = display.newText(labels[i], labelsX[i], yPos, native.systemFont, 24);
			infoLabel.anchorX, infoLabel.anchorY = 0,0;
			menuScene.leagueHistoryPopup.elements[#menuScene.leagueHistoryPopup.elements+1] = infoLabel;
		end
		yPos = yPos + 35
	end
	
	--Add all elements to scroll view
	for i = 1, #menuScene.leagueHistoryPopup.elements do
		menuScene.leagueHistoryPopup.scrollView:insert(menuScene.leagueHistoryPopup.elements[i]);
	end
	
	
end

function scene:destroyLeagueHistoryPopup()

	for i = 1, #menuScene.leagueHistoryPopup.elements do
		if (menuScene.leagueHistoryPopup.elements[i] ~= nil) then
			menuScene.leagueHistoryPopup.elements[i]:removeSelf();
			menuScene.leagueHistoryPopup.elements[i] = nil;
		end
	end
	menuScene.leagueHistoryPopup.elements = {};
	
	if (menuScene.leagueHistoryPopup.bg ~= nil) then
		menuScene.leagueHistoryPopup.bg:removeSelf();
		menuScene.leagueHistoryPopup.bg = nil
	end
	
	if (menuScene.leagueHistoryPopup.exit ~= nil) then
		menuScene.leagueHistoryPopup.exit:removeSelf();
		menuScene.leagueHistoryPopup.exit = nil
	end
	
	if (menuScene.leagueHistoryPopup.scrollView ~= nil) then
		menuScene.leagueHistoryPopup.scrollView:removeSelf();
		menuScene.leagueHistoryPopup.scrollView = nil
	end
	

end


--Finance Tab
function scene:showFinanceTab(teamid)
	
	local numTeamsInLeague = 0
	local myTeamid
	local team, year, payrollAmount
	local profit
	local projectedRevenue, projectedTicket, projectedCompBalance, projectedTV
	local teamPayrolls = {} --List of payrolls for current team for next 10 years
	local highPayrolls, lowPayrolls, avgPayrolls = {}, {}, {}--List of high, low, avg payrolls for teams for next 10 years
	local highTeams, lowTeams = {}, {} --List of teams (ids) that correspond with the highest/lowest payrolls
	local teamNames = {}
	
	local path = system.pathForFile("data.db", system.DocumentsDirectory)
	db = sqlite3.open( path )   

	--Get team information
	for row in db:nrows([[SELECT * FROM teams WHERE id = ]] .. teamid .. [[;]])do
		team = row
		
		local support, population = row.support, row.population;
		projectedTicket = at:determineRevenue(at:determineAttendance(support, population)) * 80 --Approx 80 home games a season
		projectedCompBalance = ss.competitiveBalanceMoney --Competitive balance is also revenue
		projectedTV = tv:determineTVRevenue(population); --TV revenue
		projectedRevenue = projectedTicket + projectedCompBalance + projectedTV
		
		profit = row.money - row.prevMoney
		
	end
	--Get league information
	for row in db:nrows([[SELECT * FROM league;]])do
		year = row.year
	end
	--Get team names
	for row in db:nrows([[SELECT * FROM teams;]])do
		teamNames[row.id] = row.name
		numTeamsInLeague = numTeamsInLeague + 1
	end
	--Get myTeam
	for row in db:nrows([[SELECT * FROM myteam;]])do
		myTeamid = row.teamid
	end
	
	--Get payroll
	for row in db:nrows([[SELECT SUM(salary) FROM players WHERE teamid = ]] .. teamid .. [[;]]) do
		local amount = row["SUM(salary)"]
		if (amount ~= nil) then
			payrollAmount = amount
		else
			payrollAmount = 0
		end
	end

	--Fill teamPayrolls, highPayrolls, lowPayrolls, and avgPayrolls for next 10 years 
	for i = 0, 9 do --Loops through next 10 years (including this year)
		--Payroll for current team
		for row in db:nrows([[SELECT SUM(salary) FROM players WHERE teamid = ]] .. teamid .. [[ AND years > ]] .. i .. [[;]]) do
			local amount = row["SUM(salary)"]
			if (amount ~= nil) then
				teamPayrolls[#teamPayrolls+1] = amount
			else
				teamPayrolls[#teamPayrolls+1] = 0
			end
		end
		
		--All payrolls sorted from least to greatest for this year
		local payrolls = {} 
		for row in db:nrows([[SELECT * FROM teams ORDER BY (SELECT SUM(salary) FROM players WHERE teamid = teams.id AND years > ]] .. i .. [[) ASC]]) do
			local curTeamID = row.id
			for row in db:nrows([[SELECT SUM(salary) FROM players WHERE teamid = ]] .. curTeamID .. [[ AND years > ]] .. i .. [[;]]) do
				local amount = row["SUM(salary)"]
				if (amount ~= nil) then
					payrolls[#payrolls+1] = {teamid = curTeamID, amount = amount}
				else
					payrolls[#payrolls+1] = {teamid = curTeamID, amount = 0}
				end
			end
		end
		
		--Lowest payroll in league
		lowPayrolls[#lowPayrolls+1] = payrolls[1].amount
		lowTeams[#lowTeams+1] = teamNames[payrolls[1].teamid]
		--Highest payroll in league
		highPayrolls[#highPayrolls+1] = payrolls[#payrolls].amount
		highTeams[#highTeams+1] = teamNames[payrolls[#payrolls].teamid]
		--Average payroll of league
		local sum = 0
		for i = 1, #payrolls do
			sum = sum + payrolls[i].amount
		end
		avgPayrolls[#avgPayrolls+1] = math.floor(sum / #payrolls);
		
	end

	
	db:close();
	
	local yPos = 10
	local title = display.newText(team.name .. " Finances", 60, yPos, native.systemFont, 32 )
	title.anchorX, title.anchorY = 0,0
	menuScene.finance.elements[#menuScene.finance.elements+1] = title;
	
	yPos = yPos + 75
	local money = display.newText("Money: $" .. scene:comma_value(team.money), 60, yPos, native.systemFont, 24 )
	money.anchorX, money.anchorY = 0,0
	menuScene.finance.elements[#menuScene.finance.elements+1] = money;
	
	yPos = yPos + 50
	local payroll = display.newText("Payroll: $" .. scene:comma_value(payrollAmount), 60, yPos, native.systemFont, 24 )
	payroll.anchorX, payroll.anchorY = 0,0
	menuScene.finance.elements[#menuScene.finance.elements+1] = payroll;
	
	yPos = yPos + 50
	local function f()
		local msg = teamNames[teamid] .. " Projected Revenue Breakdown\n\n" .. 
			"Ticket: $" ..  scene:comma_value(projectedTicket) ..
			"\nTV: $" ..  scene:comma_value(projectedTV) ..
			"\nBalance: $" ..  scene:comma_value(projectedCompBalance) ..
			"\nTotal: $" ..  scene:comma_value(projectedRevenue);
		scene:showPopup(msg,24)
		return true;
	end
	
	local projRevenue = display.newText("Proj. Revenue: $" .. 
		scene:comma_value(projectedRevenue)
	, 60, yPos, native.systemFont, 24 )
	projRevenue.anchorX, projRevenue.anchorY = 0,0
	projRevenue:setFillColor(.8,.8,.8)
	projRevenue:addEventListener("tap", f);
	menuScene.finance.elements[#menuScene.finance.elements+1] = projRevenue;
	
	yPos = yPos + 50
	local function f2()
		local msg =  
			"Profit\n" .. 
			"\nSeason: +Ticket Revenue" .. 
			"\nAfter Season: +Comp Balance, +TV Revenue" ..
			"\nPostseason: +Ticket Revenue"..
			"\nOffseason: -Payroll, -Scouting Money"
		scene:showPopup(msg,24)
		return true;
	end
	
	local profitLabel = display.newText("Profit: $" .. scene:comma_value(profit), 60, yPos, native.systemFont, 24 )
	profitLabel.anchorX, profitLabel.anchorY = 0,0
	profitLabel:setFillColor(.8,.8,.8)
	profitLabel:addEventListener("tap", f2);
	menuScene.finance.elements[#menuScene.finance.elements+1] = profitLabel;
	
	yPos = yPos + 75
	local payrollForecast = display.newText("Payroll Forecast Graph", 60, yPos, native.systemFont, 24 )
	payrollForecast.anchorX, payrollForecast.anchorY = 0,0
	menuScene.finance.elements[#menuScene.finance.elements+1] = payrollForecast;
	
	
	
	--Add team stepper (Show finances for different teams)
	menuScene.finance.teamStepperCounter = teamid
	
	local function onStepperPress( event )
	
		menuScene.finance.teamStepper:setValue(1); --Ignore the built in corona stepper counter, it messes things up
		if ( "increment" == event.phase ) then
			menuScene.finance.teamStepperCounter = menuScene.finance.teamStepperCounter + 1
			if (menuScene.finance.teamStepperCounter > numTeamsInLeague) then --Loop to the start
				menuScene.finance.teamStepperCounter = 1
			end
		elseif ( "decrement" == event.phase ) then
			menuScene.finance.teamStepperCounter = menuScene.finance.teamStepperCounter - 1
			if (menuScene.finance.teamStepperCounter < 1) then --Loop to the end
				menuScene.finance.teamStepperCounter = numTeamsInLeague
			end
		end
		
		scene:destroyFinanceTab();
		scene:showFinanceTab(menuScene.finance.teamStepperCounter);
		
		
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
	menuScene.finance.teamStepper = widget.newStepper
	{
		initialValue = 10,
		x = display.contentWidth - 20,
		y = title.y+title.height/2,
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
	menuScene.finance.teamStepper.anchorX, menuScene.finance.teamStepper.anchorY = 1, .5;
	menuScene.finance.elements[#menuScene.finance.elements+1] = 	menuScene.finance.teamStepper
	
	
	
	yPos = yPos + 75
	--Display payroll graph for next ten years
	for i = 0, 9 do
	
		local year = year + i;
		local lowTeam, highTeam = lowTeams[i+1], highTeams[i+1]
		local teamPayroll, lowPayroll, highPayroll, avgPayroll = teamPayrolls[i+1], lowPayrolls[i+1], highPayrolls[i+1], avgPayrolls[i+1]
		
		local function f()
			local msg = year .. " Payrolls\n\n" .. 
				"Team: $" ..  scene:comma_value(teamPayroll) .. " (" .. teamNames[teamid].. ")\n" ..
				"Low: $" ..  scene:comma_value(lowPayroll) .. " (" .. lowTeam .. ")\n" ..
				"High: $" ..  scene:comma_value(highPayroll) .. " (" .. highTeam .. ")\n" ..
				"Avg: $" ..  scene:comma_value(avgPayroll);
			scene:showPopup(msg,24)
			return true;
		end
		local yearLabel = display.newText(year, 60, yPos, native.systemFont, 24 )
		yearLabel.anchorX, yearLabel.anchorY = 0,0
		yearLabel:setFillColor(.8,.8,.8)
		yearLabel:addEventListener("tap", f)
		menuScene.finance.elements[#menuScene.finance.elements+1] = yearLabel;
		
		--Payroll bar
		--0 width for $0, 500 width for $150,000,000
		local width = 1/300000 * teamPayroll
		local rect = display.newRect( yearLabel.x + yearLabel.width + 50, yearLabel.y, width, yearLabel.height )
		rect.anchorX, rect.anchorY = 0,0
		rect.strokeWidth = 2
		local gradient = {
			type="gradient",
			color1={ 1, 0, 0 }, color2={ 0.8, 0.5, 0.5 }, direction="left"
		}
		rect:setFillColor(gradient);
		rect:setStrokeColor( 1, 0, 0 )
		menuScene.finance.elements[#menuScene.finance.elements+1] = rect;
		
		--Low payroll line (turquoise)
		local x = 1/300000 * lowPayroll + rect.x
		local line = display.newLine( x, rect.y, x, rect.y+rect.height )
		line:setStrokeColor(0,1,1)
		line.strokeWidth = 3
		menuScene.finance.elements[#menuScene.finance.elements+1] = line;
		
		--Avg payroll line (blue)
		x = 1/300000 * avgPayroll + rect.x
		line = display.newLine( x, rect.y, x, rect.y+rect.height )
		line:setStrokeColor(0,0,1)
		line.strokeWidth = 3
		menuScene.finance.elements[#menuScene.finance.elements+1] = line;
		
		--High payroll line (magenta)
		x = 1/300000 * highPayroll + rect.x
		line = display.newLine( x, rect.y, x, rect.y+rect.height )
		line:setStrokeColor(1,0,1)
		line.strokeWidth = 3
		menuScene.finance.elements[#menuScene.finance.elements+1] = line;
		
			
		local payrollLabel = display.newText("$" .. scene:comma_value(teamPayroll), rect.x+rect.width+10, rect.y+rect.height/2, native.systemFont, 14 )
		payrollLabel.anchorX, payrollLabel.anchorY = 0,.5
		menuScene.finance.elements[#menuScene.finance.elements+1] = payrollLabel;
		
		yPos = yPos + 50
	end
	
	
	--Display graph key
	yPos = yPos + 20
	
	local keyLabel = display.newText("Key:", 60, yPos, native.systemFont, 24 )
	keyLabel.anchorX, keyLabel.anchorY = 0,0
	menuScene.finance.elements[#menuScene.finance.elements+1] = keyLabel;
	
	local lowLabel = display.newText("Low", keyLabel.x+keyLabel.width+50, yPos, native.systemFont, 24 )
	lowLabel.anchorX, lowLabel.anchorY = 0,0
	menuScene.finance.elements[#menuScene.finance.elements+1] = lowLabel;
	
	local line = display.newLine( lowLabel.x+lowLabel.width+20, lowLabel.y, lowLabel.x+lowLabel.width+20, lowLabel.y+lowLabel.height )
	line:setStrokeColor(0,1,1)
	line.strokeWidth = 3
	menuScene.finance.elements[#menuScene.finance.elements+1] = line;
	
	local avgLabel = display.newText("Average", line.x+line.width+50, yPos, native.systemFont, 24 )
	avgLabel.anchorX, avgLabel.anchorY = 0,0
	menuScene.finance.elements[#menuScene.finance.elements+1] = avgLabel;
	
	line = display.newLine( avgLabel.x+avgLabel.width+20, avgLabel.y, avgLabel.x+avgLabel.width+20, avgLabel.y+avgLabel.height )
	line:setStrokeColor(0,0,1)
	line.strokeWidth = 3
	menuScene.finance.elements[#menuScene.finance.elements+1] = line;
	
	local highLabel = display.newText("High", line.x+line.width+50, yPos, native.systemFont, 24 )
	highLabel.anchorX, highLabel.anchorY = 0,0
	menuScene.finance.elements[#menuScene.finance.elements+1] = highLabel;
	
	line = display.newLine( highLabel.x+highLabel.width+20, highLabel.y, highLabel.x+highLabel.width+20, highLabel.y+highLabel.height )
	line:setStrokeColor(1,0,1)
	line.strokeWidth = 3
	menuScene.finance.elements[#menuScene.finance.elements+1] = line;
	
	for i = 1, #menuScene.finance.elements do
		menuScene.scrollView:insert(menuScene.finance.elements[i]);
	end
	

end

function scene:destroyFinanceTab()
	for i = 1, #menuScene.finance.elements do
		if (menuScene.finance.elements[i] ~= nil) then
			menuScene.finance.elements[i]:removeSelf();
			menuScene.finance.elements[i] = nil
		end
	end
end


--Negotiation (with free agent) popup
function scene:showNegotiationPopup(playerid)

	--Semi-transparent black background that covers whole screen and blocks touches
	local black = display.newImage("Images/black.png", 0, 0);
	black.width, black.height = display.contentWidth, display.contentHeight
	black.anchorX, black.anchorY = 0,0
	black.alpha = .9;
	
	local function blockTouches(event)
		return true; --Block the propagation of any touches or taps
	end
	black:addEventListener("tap", blockTouches);
	black:addEventListener("touch", blockTouches);
	menuScene.negotiationPopup.bg  = black;
	
	local teams = {}
	local team_info --Info of team negotiating
	local info --Info of player negotiating
	local path = system.pathForFile("data.db", system.DocumentsDirectory)
	db = sqlite3.open( path )   

	for row in db:nrows([[SELECT * FROM players WHERE id = ]] .. playerid .. [[;]]) do 
		info = row; --So we can call stuff like info.name, info.number
	end
	for row in db:nrows([[SELECT * FROM teams WHERE id = (SELECT teamid FROM myteam);]]) do 
		team_info = row; --So we can call stuff like info.name, info.number
	end
	for row in db:nrows([[SELECT * FROM teams;]]) do 
		teams[#teams+1] = row; --So we can call stuff like info.name, info.number
	end
	
	db:close();
	
	--Original player want terms (don't change)
	menuScene.negotiationPopup.orig_num_years = info.FA_years_wanted 
	menuScene.negotiationPopup.orig_num_salary = info.FA_salary_wanted
	--Dynamic player want terms (changes with negotiation)
	menuScene.negotiationPopup.cur_num_years = info.FA_years_wanted 
	menuScene.negotiationPopup.cur_num_salary = info.FA_salary_wanted
	--What team offers
	menuScene.negotiationPopup.offer_num_years = info.FA_years_wanted 
	menuScene.negotiationPopup.offer_num_salary = info.FA_salary_wanted
	--Current mood
	menuScene.negotiationPopup.mood = info.FA_mood;
	

	local name = display.newText( info.name .. " - " .. info.posType, 60, 10, native.systemFont, 30 )
	name.anchorX, name.anchorY = 0,0;
	menuScene.negotiationPopup.elements[#menuScene.negotiationPopup.elements+1] = name;
	
	local function tap(event)
		scene:showFaOffersPopup(info.FA_offers, info.name);
		return true;
	end
	
	local viewOffers = display.newText( "View Offers", display.contentWidth - 50, 10, native.systemFont, 24 )
	viewOffers.anchorX, viewOffers.anchorY = 1,0;
	menuScene.negotiationPopup.elements[#menuScene.negotiationPopup.elements+1] = viewOffers;
	viewOffers:addEventListener("tap", tap);
	
	
	--Mood Meter
	local mood_meter = display.newImage("Images/mood_meter.png", display.contentCenterX, display.contentHeight);
	mood_meter.anchorX, mood_meter.anchorY = .5,1;
	menuScene.negotiationPopup.elements[#menuScene.negotiationPopup.elements+1] = mood_meter
	
	--Mood Indicator
	local mood_indicator = display.newImage("Images/mood_indicator.png", display.contentCenterX, display.contentHeight);
	mood_indicator.anchorX, mood_indicator.anchorY = .5,1;
	menuScene.negotiationPopup.elements[#menuScene.negotiationPopup.elements+1] = mood_indicator
	mood_indicator.rotation = scene:moodToRotation(menuScene.negotiationPopup.mood);
	
	--Mood Label
	local mood_label = display.newText( "Mood", display.contentCenterX, mood_meter.y - mood_meter.height - 15, native.systemFont, 20 )
	mood_label.anchorX, mood_label.anchorY = 0.5,1;
	menuScene.negotiationPopup.elements[#menuScene.negotiationPopup.elements+1] = mood_label;
	
	if (menuScene.negotiationPopup.mood <= 25) then
		mood_label:setFillColor(1,0,0,1);
	elseif (menuScene.negotiationPopup.mood <= 75) then
		mood_label:setFillColor(1,1,0,1);
	else
		mood_label:setFillColor(0,.8,0,1);
	end
	
	
	
	--What the player wants
	local wants = display.newText( "Wants ", 60, name.y + name.height + 30, native.systemFont, 24 )
	wants.anchorX, wants.anchorY = 0,0;
	menuScene.negotiationPopup.elements[#menuScene.negotiationPopup.elements+1] = wants;
	
	local wantsYears = display.newText( menuScene.negotiationPopup.cur_num_years .. " Yrs", 60, wants.y + wants.height + 30, native.systemFont, 24 )
	wantsYears.anchorX, wantsYears.anchorY = 0,0;
	menuScene.negotiationPopup.elements[#menuScene.negotiationPopup.elements+1] = wantsYears;
	
	local wantsSalary = display.newText( "$ " .. scene:comma_value(menuScene.negotiationPopup.cur_num_salary), 60, wantsYears.y + wantsYears.height + 30, native.systemFont, 24 )
	wantsSalary.anchorX, wantsSalary.anchorY = 0,0;
	menuScene.negotiationPopup.elements[#menuScene.negotiationPopup.elements+1] = wantsSalary;
	
	local wantsLine = display.newLine( wantsSalary.x , wantsSalary.y +wantsSalary.height+ 20, wantsSalary.x + wantsSalary.width, wantsSalary.y +wantsSalary.height+ 20)
	wantsLine:setStrokeColor( 1, 1, 1, .5 )
	wantsLine.strokeWidth = 3
	menuScene.negotiationPopup.elements[#menuScene.negotiationPopup.elements+1] = wantsLine;
	
	local wantsTotal = display.newText( "$ " .. scene:comma_value(menuScene.negotiationPopup.cur_num_salary*menuScene.negotiationPopup.cur_num_years),
		wantsSalary.x, wantsLine.y+20, native.systemFont, 24 )
	wantsTotal.anchorX, wantsTotal.anchorY = 0,0;
	menuScene.negotiationPopup.elements[#menuScene.negotiationPopup.elements+1] = wantsTotal;
	
	--What you are willing to offer
	local offer = display.newText( "Offer ", 400, name.y + name.height + 30, native.systemFont, 24 )
	offer.anchorX, offer.anchorY = 0,0;
	menuScene.negotiationPopup.elements[#menuScene.negotiationPopup.elements+1] = offer;
	
	local offerYears = display.newText( menuScene.negotiationPopup.offer_num_years .. " Yrs", offer.x, offer.y + offer.height + 30, native.systemFont, 24 )
	offerYears.anchorX, offerYears.anchorY = 0,0;
	menuScene.negotiationPopup.elements[#menuScene.negotiationPopup.elements+1] = offerYears;
	
	-- Textfield, with transparent background, lurking behind offer salary
	local t = native.newTextField( offer.x, 10, 10 , 10 )
	t.anchorX, t.anchorY = 0,0
	t.alpha = 0;
	t.inputType = "number"
	t.font = native.newFont( "Helvetica-Bold", 16 )
	t:setTextColor( 0.8, 0.8, 0.8 )
	t.hasBackground = false
	t.text = tostring(menuScene.negotiationPopup.offer_num_salary)
	menuScene.negotiationPopup.elements[#menuScene.negotiationPopup.elements+1] = t;
	
	
	local offerSalary = display.newText( "$ " .. scene:comma_value(menuScene.negotiationPopup.offer_num_salary), offer.x, offerYears.y + offerYears.height + 30, native.systemFont, 24 )
	offerSalary.anchorX, offerSalary.anchorY = 0,0;
	menuScene.negotiationPopup.elements[#menuScene.negotiationPopup.elements+1] = offerSalary;
	
	local offerLine = display.newLine( offerSalary.x , offerSalary.y +offerSalary.height+ 20, offerSalary.x + offerSalary.width, offerSalary.y +offerSalary.height+ 20 )
	offerLine:setStrokeColor( 1, 1, 1, .5 )
	offerLine.strokeWidth = 3
	menuScene.negotiationPopup.elements[#menuScene.negotiationPopup.elements+1] = offerLine;
	
	local offerTotal = display.newText( "$ " .. scene:comma_value(menuScene.negotiationPopup.offer_num_salary*menuScene.negotiationPopup.offer_num_years),
	offerSalary.x, offerLine.y+20, native.systemFont, 24 )
	offerTotal.anchorX, offerTotal.anchorY = 0,0;
	menuScene.negotiationPopup.elements[#menuScene.negotiationPopup.elements+1] = offerTotal;
	
	--Following attributes require offerSalary to be instantiated
	t.y, t.width, t.height = offerSalary.y, offerSalary.width, offerSalary.height
	
	--Handles the invisible text listener underneath offer salary
	local function textListener( event )

		if ( event.phase == "ended" or event.phase == "submitted" ) then
			--Display the entered salary in offerSalary and update offerTotal
			--scene:showPopup(t.text, 24);
			local num = tonumber(t.text);
			if (num > 30000000) then num = 30000000 end
			if (num < 500000) then num = 500000 end
			menuScene.negotiationPopup.offer_num_salary = tonumber(num);
			offerSalary.text  = "$ " .. scene:comma_value(menuScene.negotiationPopup.offer_num_salary);
			offerTotal.text = "$ " .. scene:comma_value(menuScene.negotiationPopup.offer_num_salary*menuScene.negotiationPopup.offer_num_years);
		end
	end
	
	t:addEventListener( "userInput", textListener )



	
	--Offer Year Stepper
	local function onStepperPress2( event )

		--print("Counter: " .. menuScene.statistics.positionCounter);
		menuScene.negotiationPopup.offer_num_years = event.value
		offerYears.text  = menuScene.negotiationPopup.offer_num_years .. " Yrs"
		offerTotal.text = "$ " .. scene:comma_value(menuScene.negotiationPopup.offer_num_salary*menuScene.negotiationPopup.offer_num_years);
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
	local yearStepper = widget.newStepper
	{
		initialValue = menuScene.negotiationPopup.cur_num_years,
		minimumValue = 1,
		maximumValue = 10,
		x = offerYears.x + offerYears.width + 100,
		y = offerYears.y + offerYears.height/2,
		width = 100,
		height = 50,
		sheet = stepperSheet,
		defaultFrame = 1,
		noMinusFrame = 2,
		noPlusFrame = 3,
		minusActiveFrame = 4,
		plusActiveFrame = 5,
		onPress = onStepperPress2
	}
	yearStepper.anchorX, yearStepper.anchorY = 0, 0.5;
	menuScene.negotiationPopup.elements[#menuScene.negotiationPopup.elements+1] = yearStepper;
	
	local salaryStepper
	
	--Offer Salary Stepper
	local function onStepperPress3( event )
		
		salaryStepper:setValue(1000000); --Ignore the built in corona stepper counter, it messes things up
		if ( "increment" == event.phase ) then
			menuScene.negotiationPopup.offer_num_salary = menuScene.negotiationPopup.offer_num_salary + 10000
			if (menuScene.negotiationPopup.offer_num_salary > 30000000) then 
				menuScene.negotiationPopup.offer_num_salary = 30000000
			end
			offerSalary.text  = "$ " .. scene:comma_value(menuScene.negotiationPopup.offer_num_salary);
		elseif ( "decrement" == event.phase ) then
			menuScene.negotiationPopup.offer_num_salary = menuScene.negotiationPopup.offer_num_salary - 10000
			if (menuScene.negotiationPopup.offer_num_salary < 500000) then 
				menuScene.negotiationPopup.offer_num_salary = 500000
			end
			offerSalary.text  = "$ " .. scene:comma_value(menuScene.negotiationPopup.offer_num_salary);
		end
		t.text = menuScene.negotiationPopup.offer_num_salary; --Update invisible text field's values to correspond with display label
		offerTotal.text = "$ " .. scene:comma_value(menuScene.negotiationPopup.offer_num_salary*menuScene.negotiationPopup.offer_num_years);
	end

	-- Create the widget
	salaryStepper = widget.newStepper
	{
		initialValue = 500001,
		minimumValue = 500000,
		maximumValue = 30000000,
		x = yearStepper.x,
		y = offerSalary.y + offerSalary.height/2,
		timerIncrementSpeed = 50,
		width = 100,
		height = 50,
		sheet = stepperSheet,
		defaultFrame = 1,
		noMinusFrame = 2,
		noPlusFrame = 3,
		minusActiveFrame = 4,
		plusActiveFrame = 5,
		onPress = onStepperPress3
	}
	salaryStepper.anchorX, salaryStepper.anchorY = 0, 0.5;
	menuScene.negotiationPopup.elements[#menuScene.negotiationPopup.elements+1] = salaryStepper;
	
	
	
	--Accept Button
	local options = {
		width = 100,
		height = 50,
		numFrames = 4,
		sheetContentWidth = 200,
		sheetContentHeight = 100
	}
	local buttonSheet = graphics.newImageSheet( "Images/accept_offer.png", options )
	
	local function acceptFunction(event)
		if (event.phase == "ended") then 
			
			local path = system.pathForFile("data.db", system.DocumentsDirectory)
			db = sqlite3.open( path ) 
			
			local mode
			for row in db:nrows([[SELECT * FROM league; ]]) do
				mode = row.mode
			end
			
			if (mode ~= "Season" and mode ~= "Season Awards" and mode ~= "Playoffs" and mode ~= "Playoffs Awards" and mode ~= "Free Agency") then
				--User not allowed to sign free agents in this mode
				scene:showPopup("No free agent signings during " .. mode, 24);
				return true
			end
			
			if (mode == "Free Agency") then
				--Cannot sign the player immediately, so FA has chance to weigh other offers
				--Can only offer a contract
				ss:offerContract(team_info.id, info.id, menuScene.negotiationPopup.cur_num_salary, 
					menuScene.negotiationPopup.cur_num_years, info.FA_offers);
				
				scene:destroyNegotiationPopup();
				local msg = team_info.name .. " has offered " .. info.name .. ":\n" .. 
					menuScene.negotiationPopup.cur_num_years .. " Yrs\n$" .. 
					scene:comma_value(menuScene.negotiationPopup.cur_num_salary);
					
				scene:showPopup(msg, 24);
				db:close();
			else
				ss:signFreeAgent(playerid, team_info.id, menuScene.negotiationPopup.cur_num_salary, 
					menuScene.negotiationPopup.cur_num_years)
				db:close();
				scene:destroyNegotiationPopup();
				scene:freeAgentsRemovePlayerStats()
				scene:freeAgentsRefreshPlayerStats()			
				local msg = team_info.name .. " has signed " .. info.name .. " for:\n" .. 
					menuScene.negotiationPopup.cur_num_years .. " Yrs\n$" .. 
					scene:comma_value(menuScene.negotiationPopup.cur_num_salary);
					
				scene:showPopup(msg, 24);
			end
			
			analytics.logEvent("Offered Player Contract", 
						{playerName = info.name, years = menuScene.negotiationPopup.cur_num_years, salary = menuScene.negotiationPopup.cur_num_salary})
			
		end
		
		return true;
	end
	
	local accept = widget.newButton
	{
		id = "accept",
		sheet = buttonSheet,
		defaultFrame = 1,
		overFrame = 2,
		onEvent = acceptFunction
	}
	accept.anchorX, accept.anchorY = 0,0;
	accept.x = wantsSalary.x;
	accept.y = wantsTotal.y + wantsTotal.height + 10;
	menuScene.negotiationPopup.elements[#menuScene.negotiationPopup.elements+1] = accept
	
	--Offer Button
	local function offerFunction(event)
		
		if (event.phase == "ended") then 
		
			local path = system.pathForFile("data.db", system.DocumentsDirectory)
			db = sqlite3.open( path )
			local mode
			for row in db:nrows([[SELECT * FROM league; ]]) do
				mode = row.mode
			end
			db:close();
			if (mode ~= "Season" and mode ~= "Season Awards" and mode ~= "Playoffs" and mode ~= "Playoffs Awards" and mode ~= "Free Agency") then
				--User not allowed to sign free agents in this mode
				scene:showPopup("No free agent signings during " .. mode, 24);
				return true
			end
	
				
			scene:fa_offer(); --Let free agent react appropriately to offer
			
			--Update free agents want displays
			wantsYears.text = menuScene.negotiationPopup.cur_num_years .. " Yrs"
			wantsSalary.text = "$ " .. scene:comma_value(menuScene.negotiationPopup.cur_num_salary)
			wantsTotal.text = "$ " .. scene:comma_value(menuScene.negotiationPopup.cur_num_salary*menuScene.negotiationPopup.cur_num_years)

			--Update mood meter
			if (menuScene.negotiationPopup.mood <= 25) then
				mood_label:setFillColor(1,0,0,1);
			elseif (menuScene.negotiationPopup.mood <= 75) then
				mood_label:setFillColor(1,1,0,1);
			else
				mood_label:setFillColor(0,.8,0,1);
			end
			mood_indicator.rotation = scene:moodToRotation(menuScene.negotiationPopup.mood);
			
		end
		return true;
	end
	
	local offer = widget.newButton
	{
		id = "offer",
		sheet = buttonSheet,
		defaultFrame = 3,
		overFrame = 4,
		onEvent = offerFunction
	}
	offer.anchorX, offer.anchorY = 0,0;
	offer.x = offerSalary.x;
	offer.y = offerTotal.y + offerTotal.height + 10;
	menuScene.negotiationPopup.elements[#menuScene.negotiationPopup.elements+1] = offer
	
	--Add all the elements to a scroll view (REMOVED - SCROLL VIEW NOT NEEDED)
	--[[menuScene.negotiationPopup.scrollView = widget.newScrollView {
		backgroundColor = { 0, 1, 0, 0 },
		x = 0,
		y = 0,
		width = display.contentWidth,
		height = display.contentHeight,
		horizontalScrollDisabled = false,
		verticalScrollDisabled = false
	  }
	menuScene.negotiationPopup.scrollView.anchorX, menuScene.negotiationPopup.scrollView.anchorY = 0,0;
	
	for i = 1, #menuScene.negotiationPopup.elements do
		--(REMOVED - SCROLL VIEW NOT NEEDED)
		--menuScene.negotiationPopup.scrollView:insert(menuScene.negotiationPopup.elements[i]);
	end
	]]--
	
	--Exit button
	local function destroy(event)
		if (event.phase == "ended") then 
			
			--Update the player's mood after the negotiation
			local path = system.pathForFile("data.db", system.DocumentsDirectory)
			db = sqlite3.open( path ) 
			db:exec([[UPDATE players SET FA_mood = ]] .. menuScene.negotiationPopup.mood .. [[ WHERE id = ]] .. info.id .. [[;]])
			db:close();
			
			scene:destroyNegotiationPopup(); 
		end
	end
	menuScene.negotiationPopup.exit = widget.newButton
	{
		x = display.contentWidth,
		y = display.contentHeight,
		defaultFile = "Images/x.png",
		onEvent = destroy
	}
	menuScene.negotiationPopup.exit.anchorX, menuScene.negotiationPopup.exit.anchorY = 1, 1; 
	
end

function scene:destroyNegotiationPopup()
	
	for i = 1, #menuScene.negotiationPopup.elements do
		if (menuScene.negotiationPopup.elements[i] ~= nil) then
			menuScene.negotiationPopup.elements[i]:removeSelf();
			menuScene.negotiationPopup.elements[i] = nil;
		end
	end
	menuScene.negotiationPopup.elements = {};
	
	if (menuScene.negotiationPopup.bg ~= nil) then
		menuScene.negotiationPopup.bg:removeSelf();
		menuScene.negotiationPopup.bg = nil
	end
	
	if (menuScene.negotiationPopup.exit ~= nil) then
		menuScene.negotiationPopup.exit:removeSelf();
		menuScene.negotiationPopup.exit = nil
	end
	
	if (menuScene.negotiationPopup.scrollView ~= nil) then
		menuScene.negotiationPopup.scrollView:removeSelf();
		menuScene.negotiationPopup.scrollView = nil
	end
	

end

function scene:moodToRotation(mood)
	--Returns the rotation that needs to be applied to the mood indicator on the mood meter
	
	-- 0 = -90, 50 = 0, 100 = 90
	local rotation = (18/10) * mood - 90
	return rotation
end

function scene:fa_offer()
	
	local a = menuScene.negotiationPopup.orig_num_years
	local b = menuScene.negotiationPopup.offer_num_years
	local c = menuScene.negotiationPopup.cur_num_years
	local x = menuScene.negotiationPopup.orig_num_salary
	local y = menuScene.negotiationPopup.offer_num_salary
	local z = menuScene.negotiationPopup.cur_num_salary
	local mood = menuScene.negotiationPopup.mood
	
	local diff = (x-y)/x * 100 --Percent difference between offer and original
	if (diff > 50) then --Terrible offer
		mood = 0
	elseif (diff > 25) then --Bad offer
		mood = mood * .5
	elseif (diff > 0) then --Okay offer
		mood = mood - 5
	end
	if (mood < 0) then mood = 0 end
	if (mood > 100) then mood = 100 end
	
	--Counter Salary
	if (mood <= 25) then
		--Bad mood
		if (y>x) then 
			z=y  --Accept users higher offer
		else 
			z=x  --Go back to original offer
		end
	else
		--100 mood = full discount; 25 mood = 0 discount
		if (y>x) then 
			z=y  --Accept users higher offer
		else
			--Determine discount given to player
			local percentage = ((4/3)*mood-(100/3))/100
			local discount = math.floor((x-y)*percentage)
			z=x-discount
		end
	end
	
	--Determine number of years
	local diff = (y-x)/x * 100 --Percent increase between offer and original
	local leeway = 0;
	
	if (diff < 20) then
		leeway = 0
	else
		leeway = math.floor( (1/70)*diff + (50/70) )
	end
	
	if (mood <= 25) then leeway = 0 end
	
	if (b>a) then --More years in offer than original want
		c=a+leeway
		if (c>b) then c=b end
	elseif (b==a) then
		--Do nothing
		--Year stays the same
	elseif (b<a) then
		c=a-leeway
		if (c<b) then c=b end
	end
	
	--Update the player's current wants
	menuScene.negotiationPopup.cur_num_years = c
	menuScene.negotiationPopup.cur_num_salary = z
	menuScene.negotiationPopup.mood = mood


end


--Generic popup
function scene:showPopup(message, fontSize)
	
	--Semi-transparent black background that covers whole screen and blocks touches
	local black = display.newImage("Images/black.png", 0, 0);
	black.width, black.height = display.contentWidth, display.contentHeight
	black.anchorX, black.anchorY = 0,0
	black.alpha = .9;
	local function blockTouches(event)
		return true; --Block the propagation of any touches or taps
	end
	black:addEventListener("tap", blockTouches);
	black:addEventListener("touch", blockTouches);
	menuScene.popup.elements[#menuScene.popup.elements+1]  = black;
	
	--Rig popup scroll view - covers entire screen
	menuScene.popup.scrollView = widget.newScrollView {
		backgroundColor = { 0, 1, .3, 0 },
		x = display.contentCenterX,
		y = display.contentCenterY,
		width = display.contentWidth,
		height = display.contentHeight,
		horizontalScrollDisabled = false,
		verticalScrollDisabled = false
	 }
	
	
	--Exit button
	local function destroy(event)
		if (event.phase == "ended") then scene:destroyPopup(); end
	end
	
	local exit = widget.newButton
	{
		x = display.contentWidth,
		y = display.contentHeight,
		defaultFile = "Images/x.png",
		onEvent = destroy
	}
	exit.anchorX, exit.anchorY = 1, 1; 
	menuScene.popup.elements[#menuScene.popup.elements+1]  = exit;
	
	
	
	--Display message
	local msg = display.newText( message, display.contentCenterX, display.contentCenterY, native.systemFont, fontSize )
	msg.anchorX,  msg.anchorY = 0.5, 0.5;
	menuScene.popup.elements[#menuScene.popup.elements+1] = msg;
	menuScene.popup.scrollView:insert(msg);
	
	

end

function scene:destroyPopup()

	for i = 1, #menuScene.popup.elements do
		if (menuScene.popup.elements[i] ~= nil) then
			menuScene.popup.elements[i]:removeSelf();
			menuScene.popup.elements[i] = nil;
		end
	end
	menuScene.popup.elements = {};
	
	if (menuScene.popup.scrollView ~= nil) then
		menuScene.popup.scrollView:removeSelf();
		menuScene.popup.scrollView = nil
	end
	

end


--Change what we are displaying based off mode
--Putting no argument or an invalid argument just clears the scene
function scene:changeMode(newMode, extraParameter)
	
	--Destroy contents of current mode
	if (menuScene.mode == "Statistics") then
		scene:destroyPlayerStatsPage();
	elseif (menuScene.mode == "Teams") then
		scene:destroyTeamsPage();
	elseif (menuScene.mode == "Team Card") then
		scene:destroyTeamCard();
	elseif (menuScene.mode == "Trade") then
		--menuScene.scrollView:setIsLocked(false); --Unlock the main scroll view
		--menuScene.scrollView._view._isVerticalScrollingDisabled = false
		--menuScene.scrollView._view._isHorizontalScrollingDisabled = false
		scene:destroyTradePage();
	elseif (menuScene.mode == "Simulation") then
		scene:destroySimulationTab();
	elseif (menuScene.mode == "Free Agents") then
		scene:destroyFreeAgentsTab();
	elseif (menuScene.mode == "League") then
		scene:destroyLeagueTab();
	elseif (menuScene.mode == "Finances") then
		scene:destroyFinanceTab();
	end

	
	
	--Switch to new mode/page
	if (newMode == "Statistics") then
		menuScene.mode = newMode;
		scene:showPlayerStatsPage();
	elseif (newMode == "Teams") then
		menuScene.mode = newMode;
		scene:showTeamsPage();
	elseif (newMode == "Team Card") then
		menuScene.mode = newMode;
		scene:showTeamCard(extraParameter);
	elseif (newMode == "Trade") then
		menuScene.mode = newMode;
		 --Lock the main scroll view, not needed for trade menu
		--menuScene.scrollView._view._isVerticalScrollingDisabled = true
		--menuScene.scrollView._view._isHorizontalScrollingDisabled = true
		scene:showTradePage();
	elseif (newMode == "Simulation") then
		menuScene.mode = newMode;
		scene:showSimulationTab()
	elseif (newMode == "Free Agents") then
		menuScene.mode = newMode;
		scene:showFreeAgentsTab()
	elseif (newMode == "League") then
		menuScene.mode = newMode;
		scene:showLeagueTab()
	elseif (newMode == "Finances") then
		menuScene.mode = newMode;
		scene:showFinanceTab(extraParameter)
	end
	menuScene.scrollView:scrollToPosition({x=0,y=0,time=0});

end


-- ****************************************************************************
-- ****************************************************************************
-- **********                 EXECUTION BEGINS HERE.                 **********
-- ****************************************************************************
-- ****************************************************************************


utils:log("gameScene", "Beginning execution");

-- Add scene lifecycle event handlers.
scene:addEventListener("createScene", scene);
scene:addEventListener("willEnterScene", scene);
scene:addEventListener("enterScene", scene);
scene:addEventListener("exitScene", scene);
scene:addEventListener("didExitScene", scene);
scene:addEventListener("destroyScene", scene);

return scene;