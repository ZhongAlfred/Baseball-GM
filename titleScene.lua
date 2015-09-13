
-- Create a scene object to tie functions to.
local scene = storyboard.newScene();

-- ============================================================================
-- Called when the scene's view does not exist.
-- ============================================================================
function scene:createScene(inEvent)

  utils:log("titleScene", "createScene()");
  
  --Physics Warrior Text & Tween
  
	local txtNewGame = display.newText("New Game", display.contentCenterX, 0, native.systemFont, 52);
	txtNewGame.y = display.contentCenterY - txtNewGame.height - 20;
	txtNewGame:addEventListener("touch",
    function(inEvent)
      if inEvent.phase == "ended" then
        storyboard.gotoScene("gameScene", "zoomOutIn", 500);
      end
    end
	);
	self.view:insert(txtNewGame);
	

	
	local txtLevelEditor = display.newText("Level Editor", display.contentCenterX, 0, native.systemFont, 52);
	txtLevelEditor.y = display.contentCenterY + 20;
	txtLevelEditor:addEventListener("touch",
    function(inEvent)
      if inEvent.phase == "ended" then
        storyboard.gotoScene("levelEditorScene", "zoomOutIn", 500);
      end
    end
	);
	self.view:insert(txtLevelEditor);

end -- End createScene().


-- ============================================================================
-- Called BEFORE scene has moved on screen.
-- ============================================================================
function scene:willEnterScene(inEvent)

  utils:log("titleScene", "willEnterScene()");

end -- End willEnterScene().


-- ============================================================================
-- Called AFTER scene has moved on screen.
-- ============================================================================
function scene:enterScene(inEvent)

  utils:log("titleScene", "enterScene()");

end -- End enterScene().


-- ============================================================================
-- Called BEFORE scene moves off screen.
-- ============================================================================
function scene:exitScene(inEvent)

  utils:log("titleScene", "exitScene()");

end -- End exitScene().


-- ============================================================================
-- Called AFTER scene has moved off screen.
-- ============================================================================
function scene:didExitScene(inEvent)

  utils:log("titleScene", "didExitScene()");

end -- End didExitScene().


-- ============================================================================
-- Called prior to the removal of scene's "view" (display group).
-- ============================================================================
function scene:destroyScene(inEvent)

  utils:log("titleScene", "destroyScene()");
  
end -- End destroyScene().



-- ****************************************************************************
-- ****************************************************************************
-- **********                 EXECUTION BEGINS HERE.                 **********
-- ****************************************************************************
-- ****************************************************************************


utils:log("titleScene", "Beginning execution");

-- Add scene lifecycle event handlers.
scene:addEventListener("createScene", scene);
scene:addEventListener("willEnterScene", scene);
scene:addEventListener("enterScene", scene);
scene:addEventListener("exitScene", scene);
scene:addEventListener("didExitScene", scene);
scene:addEventListener("destroyScene", scene);

return scene;