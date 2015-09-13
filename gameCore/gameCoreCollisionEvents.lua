-- ============================================================================
-- Handle collision events during gameplay.
-- ============================================================================
function gc:collision(event)
	
	local otherObject = nil --Name of object other than ball. Can be either wall or a fielder
	local otherObjectReference = nil --Sprite of other object
	
	if (event.object1.name == "ball" or event.object2.name == "ball") then
	
	
		if (event.object1.name == "ball") then 
			otherObject = event.object2.name 
			otherObjectReference = event.object2
		else 
			otherObject = event.object1.name 
			otherObjectReference = event.object1
		end
	
	
		if (event.phase == "began") then
		
		--print("Ball Height: " .. gc.ball.height);
		if (otherObject == "walls") then
		
			if (gc.ball.height > 10) then print("HOMERUN"); 
			else --Hit wall, following is physics to bounce off wall. This physics needs eventual fixing
				if (gc.ball.wallCounter == 0) then
					print("Bounce off wall");
					gc.ball.launchOrigin.x, gc.ball.launchOrigin.y = gc.ball.sprite.x, gc.ball.sprite.y;
					gc.ball.velocity = gc.ball.velocity * .5;
					gc.ball.direction = gc.ball.direction + 180; --Other end of pi chart
					gc.ball.launchAngle = 0;
					gc.ball.initialHeight = gc.ball.height;
					if (gc.ball.initialHeight < 0) then gc.ball.initialHeight = 0 end --Ball can't be underground
					gc.ball.distance = 0;
					gc.ball.tCounter = 0;
					gc.ball.wallCounter = 1;
					
					--Fielder movement restriction removed
					gc:resetFielderHitWalls();
					gc:updateFielderTargets();
				end
			end
			
		else
			--Other object must be a fielder
			--Ball must be less than seven feet
			--And fielder.caughtBall == false, so that the fielder that catches the ball can't catch it again after throwing it
			--Can only catch it if no other fielder has possession of the ball
			if (gc.ball.height <= 7 and otherObjectReference.caughtBall ~= true and gc:getFielderThatHasBall() == nil) then
				--print(otherObject .. " caught the ball!");
				
				--Runner tag play
				if (gc.ball.firstCatch) then --Caught ball from the bat, not from a thrower
					gc.ball.firstCatch = false; --Subsequent balls are thrown by other fielders
					if (gc.ball.numBounces == 0) then  --Flyball catch
						
						gc:removeRunner(#gc.runners); --Removes appropriate runner
						
						if (gc.ball.isCatchable) then
							--Tag play
							for i=1, #gc.runners do
								gc:runnerDecide(gc.runners[i], "tag");
							end
						else
							--Ball was not supposed to be caught
							--Since the runners were going because they thought it wasn't going to be caught,
							--They must go back to runner.originalBase
							gc.runnersRetreating = true;
							for i=1, #gc.runners do --Reverse the current bags
								if (gc.runners[i].current == "first") then
									gc.runners[i].current = "second";
								elseif (gc.runners[i].current == "second") then
									gc.runners[i].current = "third";
								elseif (gc.runners[i].current == "third") then
									gc.runners[i].current = "home";
								end
							end
							for i=1, #gc.runnersScored do --All runners who scored have to return to original base
								local runner = display.newImage("Images/fielder3.png", gc.fieldPos.home.x , gc.fieldPos.home.y);
								gc.camera:add(runner, 3, false); --Add runner to the camera so he shows up
								runner.name = "runner";
								runner.target = "third";
								runner.current = "home";
								runner.originalBase = gc.runnersScored[i].originalBase;
								 --Insert at the beginning of table because he is lead runner
								 --Messes up base running if he is inserted at end of the table
								table.insert(gc.runners, 1, runner);
							end
							
							for i=1, #gc.runners do
								gc:retreatRunner(gc.runners[i]);
							end
						end
					end
				end
				
				
				--Prevents fielder from catching a ball that he throws himself
				gc:resetFielderCaughtBall(); --Other fielders are allowed to catch the fielder's throw
				otherObjectReference.caughtBall = true; --Fielder that has the ball cannot catch the ball if thrown
				
				--Enables fielder to move with the ball if he chooses to run toward a bag
				otherObjectReference.hasBall = true;
				
				--Fielder decides what to do with the ball (throw it, run it to the bag, do nothing)
				local function f()
					gc:fielderDecide(otherObjectReference);
				end
				timer.performWithDelay(250, f);
				
			end
		
		end
		
		
		
		end

	end
	
	--Handle wall, fielder collision
	if (event.object1.name == "walls" or event.object2.name == "walls") then
	
		if (event.phase == "began") then
		
			if (event.object1.name == "walls") then 
			otherObject = event.object2.name 
			otherObjectReference = event.object2
			else 
			otherObject = event.object1.name 
			otherObjectReference = event.object1
			end
		
			--Other object is a fielder, fielder stops at the wall
			if(otherObject ~= "ball") then
				otherObjectReference.hitWall = true;
			end
		
		end
	end
end