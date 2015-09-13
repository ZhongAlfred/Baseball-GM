-- Create a scene object to tie functions to.
local scene = storyboard.newScene();

local tutorialScene = {
	
	group,
	title,
	box,
	info,
	picture,
	
	tutorial = {
	{pic = "15", info = {text = "Many pages are scrollable", x = display.contentCenterX, y = display.contentCenterY,fnt=32}},
	{pic = "5", info = {text = "You can tap gray text!!!", x = 630, y = 70,fnt=32},
		box = {x = 560, y = 100, width = 180, height = 380},},
	{pic = "1", info = {text = "You can tap gray text!!", x = 640, y = 360,fnt=32},
		box = {x = 540, y = 70, width = 220, height = 260},},
	{pic = "13", info = {text = "You can tap gray text!", x = 635, y = 80,fnt=32},
		box = {x = 620, y = 0, width = 180, height = 50},},
	{pic = "13", info = {text = "League Standings", x = display.contentCenterX, y = display.contentCenterY,fnt=32}, 
		box = {x = 0, y = 0, width = 800, height = 480}},
	{pic = "2", info = {text = "", x = 400, y = 40,fnt=32}, 
		box = {x = 0, y = 360, width = 250, height = 80}},
	{pic = "14", info = {text = "Tap again to reverse order", x = 425, y = 75,fnt=32}, 
		box = {x = 50, y = 100, width = 750, height = 35}},
	{pic = "12", info = {text = "Tap to sort by column", x = 425, y = 75,fnt=32}, 
		box = {x = 50, y = 100, width = 750, height = 35}},
	{pic = "11", info = {text = "Extra Filters", x = 700, y = 75,fnt=32}, 
		box = {x = 738, y = 0, width = 60, height = 50}},
	{pic = "11", info = {text = "Ratings/Statistics", x = 590, y = 75,fnt=32}, 
		box = {x = 460, y = 0, width = 260, height = 50}},
	{pic = "10", info = {text = "Filter Position", x = 510, y = 25,fnt=32}, 
		box = {x = 250, y = 0, width = 150, height = 50}},
	{pic = "9", info = {text = "Filter Team", x = 320, y = 25,fnt=32}, 
		box = {x = 65, y = 0, width = 150, height = 50}},
	{pic = "8", info = {text = "Player Card", x = display.contentCenterX, y = display.contentCenterY,fnt=32}, 
		box = {x = 0, y = 0, width = 800, height = 480}},
	{pic = "7", info = {text = "Player", x = 470, y = 172,fnt=32}, 
		box = {x = 220, y = 155, width = 175, height = 35}},
	{pic = "7", info = {text = "Statistics", x = display.contentCenterX, y = display.contentCenterY,fnt=32}, 
		box = {x = 0, y = 0, width = 800, height = 480}},
	{pic = "2", info = {text = "", x = 400, y = 40,fnt=32}, 
		box = {x = 0, y = 90, width = 250, height = 80}},
	{pic = "22", info = {text = "Yiss!", x = display.contentCenterX, y = display.contentCenterY,fnt=32}, },
	{pic = "21", info = {text = "Negotiate!", x = display.contentCenterX-80, y = display.contentCenterY,fnt=32}, },
	{pic = "20", info = {text = "", x = display.contentCenterX, y = display.contentCenterY,fnt=32}, 
		box = {x = 78, y = 150, width = 70, height = 35}},
	{pic = "20", info = {text = "Free Agents", x = display.contentCenterX, y = display.contentCenterY,fnt=32}, 
		box = {x = 0, y = 0, width = 800, height = 480}},
	{pic = "19", info = {text = "", x = 400, y = 40,fnt=32}, 
		box = {x = 0, y = 368, width = 250, height = 80}},
	{pic = "18", info = {text = "How do I fix this?", x = 630, y = 210,fnt=32},
		box = {x = 650, y = 240, width = 100, height = 35},},
	{pic = "18", info = {text = "Yep, too few catchers!!!", x = 630, y = 210,fnt=28},
		box = {x = 650, y = 240, width = 100, height = 35},},
	{pic = "17", info = {text = "You probably don't have enough players!", x = display.contentCenterX, y = display.contentCenterY+50,fnt=32}},
	{pic = "17", info = {text = "What if this happens during simulation?", x = display.contentCenterX, y = display.contentCenterY-50,fnt=32}},
	{pic = "6", info = {text = "Boxscore", x = display.contentCenterX, y = display.contentCenterY,fnt=32}, 
		box = {x = 0, y = 0, width = 800, height = 480}},
	{pic = "5", info = {text = "", x = display.contentCenterX, y = display.contentCenterY,fnt=32}, 
		box = {x = 592, y = 110, width = 100, height = 30}},
	{pic = "5", info = {text = "Finished Simulation", x = display.contentCenterX, y = display.contentCenterY,fnt=32}, 
		box = {x = 0, y = 0, width = 800, height = 480}},
	{pic = "3", info = {text = "Simulate", x = 705, y = 80,fnt=32}, 
		box = {x = 620, y = 12, width = 175, height = 35}},
	{pic = "4", info = {text = "Exit", x = 700, y = 455,fnt=32}, 
		box = {x = 750, y = 430, width = 50, height = 50}},
	{pic = "4", info = {text = "Lineups", x = display.contentCenterX, y = display.contentCenterY,fnt=32}, 
		box = {x = 0, y = 0, width = 800, height = 480}},
	{pic = "3", info = {text = "", x = 705, y = 80,fnt=32}, 
		box = {x = 390, y = 110, width = 95, height = 30}},
	{pic = "3", info = {text = "Simulation", x = display.contentCenterX, y = display.contentCenterY,fnt=32}, 
		box = {x = 0, y = 0, width = 800, height = 480}},
	{pic = "2", info = {text = "", x = 400, y = 40,fnt=32}, 
		box = {x = 0, y = 0, width = 250, height = 80}},
	{pic = "1", info = {text = "Menu", x = 120, y = 25,fnt=32}, 
		box = {x = 0, y = 0, width = 50, height = 50}},
	{pic = "1", info = {text = "Record", x = 500, y = 37,fnt=32}, 
		box = {x = 590, y = 12, width = 120, height = 50}},
	{pic = "1", info = {text = "My Team", x = display.contentCenterX, y = display.contentCenterY,fnt=32}, 
		box = {x = 0, y = 0, width = 800, height = 480}},

	},
	counter = 1,
}

-- ============================================================================
-- Called when the scene's view does not exist.
-- ============================================================================
function scene:createScene(inEvent)
		
	local function createSlide()
	
		print("tutorialScene.counter: " .. tutorialScene.counter)
	
		if (tutorialScene.group ~= nil) then
			tutorialScene.group:removeSelf()
			tutorialScene.group = nil
		end
		tutorialScene.group = display.newGroup()
		tutorialScene.group.alpha = 0
		
		local reverseOrder =  #tutorialScene.tutorial - tutorialScene.counter+1
		local slide = tutorialScene.tutorial[reverseOrder]
		
		local picture = display.newImage("tutorial/" .. slide.pic .. ".png", 0 , 0);
		picture.anchorX, picture.anchorY = 0, 0;
		tutorialScene.group:insert(picture);
		
		local text = display.newText( slide.info.text, slide.info.x, slide.info.y, native.systemFont, slide.info.fnt )
		text:setFillColor(1,0,0,1)
		text.anchorX, text.anchorY = .5,.5
		tutorialScene.group:insert(text);
		
		if (slide.box ~= nil) then
		local box = display.newLine( slide.box.x, slide.box.y, slide.box.x+slide.box.width, slide.box.y )
		box:append( slide.box.x+slide.box.width, slide.box.y+slide.box.height, slide.box.x, slide.box.y+slide.box.height, slide.box.x, slide.box.y)
		box:setStrokeColor( 1, 0, 0, 1 )
		box.strokeWidth = 5
		tutorialScene.group:insert(box);
		end
		
		
		self.view:insert(tutorialScene.group)
		
		transition.to( tutorialScene.group, { time=250, alpha=1.0} )
	end
	
	local function nextSlide()
		tutorialScene.counter = tutorialScene.counter + 1
		if (tutorialScene.counter > #tutorialScene.tutorial) then
			--Go to main menu
			Runtime:removeEventListener("tap", nextSlide)
			storyboard.gotoScene("mainMenuScene", "fade", 500);
		else
			--Create next slide
			createSlide()
		end
		return true
	end
	
	Runtime:addEventListener("tap", nextSlide)
	--Title
	tutorialScene.title = display.newText( "", 5, 5, native.systemFont, 50 )
	tutorialScene.title.anchorX, tutorialScene.title.anchorY = 0,0
	tutorialScene.title.alpha = .1;
	
	createSlide() --Show first slide
	
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

  storyboard.removeScene("tutorialScene")
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


utils:log("gameScene", "Beginning execution");

-- Add scene lifecycle event handlers.
scene:addEventListener("createScene", scene);
scene:addEventListener("willEnterScene", scene);
scene:addEventListener("enterScene", scene);
scene:addEventListener("exitScene", scene);
scene:addEventListener("didExitScene", scene);
scene:addEventListener("destroyScene", scene);

return scene;