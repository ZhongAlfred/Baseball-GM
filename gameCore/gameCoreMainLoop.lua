-- ============================================================================
-- Our main game loop, executed each frame.
--
-- @param inEvent The event object describing the event.
-- ============================================================================
function gc:enterFrame(inEvent)
	
	--print("#gc.runners: " .. #gc.runners);
	
	--Only process ball and fielders if ball has been hit or is present on screen
	if (gc.ball.velocity == nil or gc.ball.sprite == nil) then return end
	
	if (gc:getFielderThatHasBall() == nil) then
		--Processes ball according to parametric equations
		gc:processBall();
		--However, if some fielder has possession of the ball, the ball moves with him
	end
	gc:processFielders();
	gc:fielderAtTargetBag();
	gc:processRunners();

end -- End enterFrame().

function gc:processBall()
	
	--Test to see if ball should start rolling
	if (not gc.ball.rolling) then
		
		if (gc.ball.height <= .5 and gc.ball.launchAngle <= 2) then 
			gc.ball.rolling = true; 
			--Ball starts rolling
			if (gc.ball.numBounces == 0) then
				--Technically, when the ball starts rolling, there should have been a "bounce"
				--This way, a double off the wall isn't confused with a flyball out once the fielder
				--Catches it, because the wall sets the gc.ball.launchAngle to 0, so there is no chance
				--For a single bounce. However the game must recognize it as a hit, not a flyball out
				gc.ball.numBounces = 1;
			end
			gc.ball.height = 0;
			gc.ball.distance = 0;
			gc.ball.initialHeight = 0;
			gc.ball.launchOrigin.x, gc.ball.launchOrigin.y = gc.ball.sprite.x, gc.ball.sprite.y;
			gc.ball.launchAngle = 0;
			gc.ball.tCounter = 0;
			
		end
		
	end
	
	--Rolling logic, else use parametric bounce logic
	if (gc.ball.rolling) then
	
		--Rolling logic - When ball height is near 0 and launch angle is clos to 0
		gc.ball.distance = gc.ball.distance + (gc.ball.velocity/30);
		gc.ball.velocity = gc.ball.velocity * .99;
		
		--Friction logic: if ball velocity gets under 2, set ball velocity to 0
		--so ball stops rolling. This models minimum force required to counteract ball-ground friction
		
		if (gc.ball.velocity < 2) then gc.ball.velocity = 0 end
	
	else
	
		--Parametric logic - Flyballs Usually
		--Parametric equations x = ball distance && y = height of ball
		gc.ball.distance = gc.ball.velocity * math.cos( math.rad(gc.ball.launchAngle) ) * gc.ball.tCounter;
		gc.ball.height = gc.ball.velocity * math.sin( math.rad(gc.ball.launchAngle) ) * gc.ball.tCounter 
			- (16 * gc.ball.tCounter * gc.ball.tCounter) + gc.ball.initialHeight; --3 is initial height of ball when launched
	end	
	
	--Scale ball according to height
	local scale = (1/750) * gc.ball.height + .1;
	gc.ball.sprite.xScale, gc.ball.sprite.yScale = scale,scale; 
	
	local nw, nh = gc.ball.sprite.width*scale*0.5, gc.ball.sprite.height*scale*0.5;
	physics.removeBody(gc.ball.sprite);
	physics.addBody(gc.ball.sprite, "dynamic", { density = 1, friction = 2, bounce = 0 , radius = gc.ball.sprite.width * scale *.5});
	
	
	--Calculates pixel coordinates of ball using information like distance and direction
	gc.ball.sprite.x = gc.ball.launchOrigin.x + gc.ball.distance * math.cos( math.rad(gc.ball.direction) );
	gc.ball.sprite.y = gc.ball.launchOrigin.y - gc.ball.distance * math.sin( math.rad(gc.ball.direction) );
	gc.ball.tCounter = gc.ball.tCounter + (1/30); --Time increases by 1/30 of a second per frame
	
	--Leave ball 'trail'
	local trail = display.newRect(gc.ball.sprite.x, gc.ball.sprite.y , 4,4);
	local coefficient = (1/300) * gc.ball.height;
	if (coefficient > 1) then coefficient = 1; end
	trail:setFillColor(1,1,1,coefficient); --Alpha set to coefficient to give illusion of depth
	gc.camera:add(trail, 3, false);
	table.insert(gc.ball.trail, 0, trail);
	
	--Trail can't be too long
	if (#gc.ball.trail > 30) then
		gc.ball.trail[#gc.ball.trail]:removeSelf();
		table.remove(gc.ball.trail)
	end
	
	--Update Ball Height Tracker
	if (gc.ball.tracker ~= nil) then 
		gc.ball.tracker:removeSelf();
		gc.ball.tracker = nil;
	end
	local fontsize = math.round((34/.9) *(scale) + 8);
	gc.ball.tracker = display.newText(tostring(math.round(gc.ball.height)), gc.ball.sprite.x, 
		gc.ball.sprite.y - gc.ball.sprite.height * scale, native.systemFontBold, fontsize);
	gc.ball.tracker.anchorY = 1;
	gc.camera:add(gc.ball.tracker, 3, false);
	
	--Bounce logic only if ball is touching ground and not rolling
	if (gc.ball.height <= 0 and not gc.ball.rolling) then
	
	--Ball bounces
	--print("Bounce (" .. gc.ball.tCounter .. "s)   X- " .. gc.ball.sprite.x .. " Y- " .. gc.ball.sprite.y);
	
	gc.ball.numBounces = gc.ball.numBounces + 1;
	gc.ball.initialHeight = 0.01;
	gc.ball.launchOrigin.x, gc.ball.launchOrigin.y = gc.ball.sprite.x, gc.ball.sprite.y;
	gc.ball.velocity = gc.ball.velocity * .75; --Loses velocity off bounce
	gc.ball.launchAngle = math.abs(gc.ball.launchAngle) * .75; --Loses some angle off bounce (more realistic)
	if (gc.ball.launchAngle <= 0) then gc.ball.launchAngle = 0; end
	gc.ball.tCounter = 0;

	end
	
	
	--Ball too slow, it now stops
	--Hit another ball
	if (gc.ball.velocity < .2) then 
		gc.ball.velocity = 0; 
		
		--Mark baseball to create spray chart
		local hit = display.newImage("Images/baseball.png", gc.ball.sprite.x , gc.ball.sprite.y);
		hit.xScale, hit.yScale = .1,.1;
		gc.camera:add(hit, 3, false);
		
		--Hit another ball
		gc.ball.sprite.xScale, gc.ball.sprite.yScale = .1,.1;
		gc.ball.sprite.x, gc.ball.sprite.y = gc.fieldPos.home.x, gc.fieldPos.home.y;
		gc:hitBall();
		gc.ball.tCounter = 0;
		for i=1, #gc.ball.trail do
			gc.ball.trail[i]:removeSelf() -- Optional Display Object Removal
			gc.ball.trail[i] = nil -- Nil Out Table Instance
		end
	end

end

function gc:processFielders()
  
  local targetX;
  local targetY;
	
  --Process fielder targets if ball is rolling
  if (gc.ball.rolling) then
	
	--Update the fielder targets appropriately
	--Closest fielder to the ball will chase it
	--While the others cover appropriate bags
	--Must call updateFielderTargets continuously because ball
	--Position changes continuously
	gc:updateFielderTargets(true);
  
  end
  
  --If there is no target or fielder is at the wall, fielder stays put
  for i,v in ipairs(gc.fielders) do
		
		local curX = gc.fielders[i].x;
		local curY = gc.fielders[i].y;
		
		--Set fielder target
		if(gc.fielders[i].target == nil or gc.fielders[i].hitWall == true) then
			
			gc.fielders[i].target = {x = curX, y = curY};
		end
  end
  
  --Actual movement of fielders based off their targets
  for i,v in ipairs(gc.fielders) do
	targetX = gc.fielders[i].target.x;
    targetY = gc.fielders[i].target.y;
	local curX = gc.fielders[i].x;
	local curY = gc.fielders[i].y;
	
	
	local yDif = curY - targetY;
	local xDif = targetX - curX;
	
	if (math.abs(yDif) < 2 and math.abs(xDif) < 2) then
		--Do nothing, player approximately has reached target
		--Some wierd shit, such as spasms and wrong direction, happens if we try to get fielder to exact location
	else
		--Calculates direction outfielder has to go
		local theta = math.atan(yDif/xDif);
		if (yDif < 0 and xDif < 0) then
			theta = theta + math.pi;
		elseif (yDif > 0 and xDif < 0) then
			theta = theta + math.pi;
		end
		--print("Theta: " .. math.deg(theta));
		
		
		
		--Moves player based off direction and speed
		local distance = 30 * (1/30); --distance = rate (30) * time (1/30s per frame);
		local deltaX=distance * math.cos(theta);
		local deltaY=distance * math.sin(theta);
		
		gc.fielders[i].x = gc.fielders[i].x + deltaX;
		gc.fielders[i].y = gc.fielders[i].y - deltaY;
		
		--If fielder has possession of the ball, the ball moves with him
		if (gc.fielders[i].hasBall) then
			gc.ball.sprite.x, gc.ball.sprite.y = gc.fielders[i].x, gc.fielders[i].y;
		end
	
	end
  
  end
  

end

function gc:processRunners()
	
	
	
	--Code segment pretty similar to the one found in processFielders()
	--Following moves runner toward targetBag
	for i=#gc.runners, 1, -1 do --Decrementing to allow for safe removal of table elements
		
	if (gc.runners[i].target ~= nil) then	
	
		local tgtX, tgtY;
		
		if (gc.runners[i].target == "first") then
			tgtX, tgtY = gc.fieldPos.first.x, gc.fieldPos.first.y;
		elseif (gc.runners[i].target == "second") then
			tgtX, tgtY = gc.fieldPos.second.x, gc.fieldPos.second.y;
		elseif (gc.runners[i].target == "third") then
			tgtX, tgtY = gc.fieldPos.third.x, gc.fieldPos.third.y;
		elseif (gc.runners[i].target == "home") then
			tgtX, tgtY = gc.fieldPos.home.x, gc.fieldPos.home.y;
		end
		
		local curX = gc.runners[i].x;
		local curY = gc.runners[i].y;
	
	
		local yDif = curY - tgtY;
		local xDif = tgtX - curX;
		
		if (math.abs(yDif) < 2 and math.abs(xDif) < 2) then
			--Player approximately has reached base
			--Some weird shit, such as spasms and wrong direction, happens if we try to get fielder to exact location
			
			if (gc.runners[i].target == "first") then --Previous bag was home, now bag is first, etc. etc.
				gc.runners[i].current = "first";
				gc.runners[i].target = nil;
				gc:runnerDecide(gc.runners[i], "base");
				--gc:advanceRunner(gc.runners[i]);
				
			elseif (gc.runners[i].target == "second") then
				gc.runners[i].current = "second";
				gc.runners[i].target = nil;
				gc:runnerDecide(gc.runners[i], "base");
				--gc:advanceRunner(gc.runners[i]);
				
			elseif (gc.runners[i].target == "third") then
				gc.runners[i].current = "third";
				gc.runners[i].target = nil;
				gc:runnerDecide(gc.runners[i], "base");
				--gc:advanceRunner(gc.runners[i]);
				
			elseif (gc.runners[i].target == "home") then
				table.insert(gc.runnersScored, {originalBase = gc.runners[i].originalBase});
				gc.runners[i].current = "home";
				gc:removeRunner(i);
			end
			
		else
			--Calculates direction runner has to go
			local theta = math.atan(yDif/xDif);
			if (yDif < 0 and xDif < 0) then
				theta = theta + math.pi;
			elseif (yDif > 0 and xDif < 0) then
				theta = theta + math.pi;
			end
			
			--Moves player based off direction and speed
			local distance = 30 * (1/30); --distance = rate (30) * time (1/30s per frame);
			local deltaX=distance * math.cos(theta);
			local deltaY=distance * math.sin(theta);
			
			gc.runners[i].x = gc.runners[i].x + deltaX;
			gc.runners[i].y = gc.runners[i].y - deltaY;
		end
		
	end	
	
	end

	--If all of the runners targets are nil, hit a new ball
	local allNil = true;
	for i=#gc.runners, 1, -1 do
		if (gc.runners[i].target ~= nil) then
			allNil = false;
			break;
		end
	end
	
	if(allNil) then
		
		--gc:newBall();
	
	end

end

function gc:fielderAtTargetBag()
	
	--Checks to see if fielder that has ball is at a bag
	--If so, runners that haven't gotten to that bag are called out
	for i=1, #gc.fielders do
		if (gc.fielders[i].hasBall) then
		
			if(math.abs(gc.fieldPos.first.x - gc.fielders[i].x) < 5 and math.abs(gc.fieldPos.first.y - gc.fielders[i].y) < 5) then
				for i=#gc.runners, 1, -1 do
					if (gc.runners[i].target == "first") then
						gc:removeRunner(i);
					end
				end
			elseif(math.abs(gc.fieldPos.second.x - gc.fielders[i].x) < 5 and math.abs(gc.fieldPos.second.y - gc.fielders[i].y) < 5) then
				for i=#gc.runners, 1, -1 do
					if (gc.runners[i].target == "second") then
						gc:removeRunner(i);
					end
				end
			elseif(math.abs(gc.fieldPos.third.x - gc.fielders[i].x) < 5 and math.abs(gc.fieldPos.third.y - gc.fielders[i].y) < 5) then
				for i=#gc.runners, 1, -1 do
					if (gc.runners[i].target == "third") then
						gc:removeRunner(i);
					end
				end
			elseif(math.abs(gc.fieldPos.home.x - gc.fielders[i].x) < 5 and math.abs(gc.fieldPos.home.y - gc.fielders[i].y) < 5) then
				for i=#gc.runners, 1, -1 do
					if (gc.runners[i].target == "home") then
						gc:removeRunner(i);
					end
				end
			end
		end
	end

end