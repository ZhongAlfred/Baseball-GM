-- ============================================================================
-- Our gameCore object will store our main game code.  We define the fields of
-- the object here but functions get added later (you could add the fields
-- later as well, but organizationally I prefer this form).
-- ============================================================================
local perspective=require("perspective");
local widget = require("widget");


local gameCore = {
  -- The DisplayGroup for the gameScene.
  gameDG = nil,
  -- Camera
  camera=perspective.createView(),
  
  
  
  field = nil, --Visual image of field
  walls = nil, --Although walls are drawn in field.png, 
			  --we need walls that are embodied as physics objects so that we can detect collisions
  ball = {
	sprite = nil,
	velocity = nil,
	direction = nil,
	height = nil,
	distance = nil,
	initialHeight = nil,
	launchAngle = nil,
	launchOrigin = {x = nil, y = nil}, --Off the bat, the origin would be home plate, 
						--but after bouncing, the origin would be at each bounce
	wallCounter = 0;				
	trail = {}, --This table used to show ball's trail path
	tCounter = 0,
	rolling = false,
	
	tracker = nil, --Visual of ball height
	isCatchable = false, --Is the ball catchable or not, determine whether runners should run off bat
	firstCatch = true,
	numBounces = 0, --Tracks num bounces of the ball
	throwDuration = 0,
	throwTgt = {}
	

  },
  
 
  fielders = {
  
  },
  
  runners = {},
  --For everything to work correctly, we assume that the most advanced runners come first in the table
  --The least advanced are at the end of the table
  
  --Coordinates for points such as pitcher, catcher, etc...
  fieldPos = {
  
	--Location of the bags
	first = {x=610, y = 740};
	second = {x=500, y = 630};
	third = {x=390, y = 740};
	home = {x=500, y = 850};

	--Fielder normal positions
	f_pitcher = {x=500, y=750};
	f_short = {x=440, y=600};
	f_first = {x=600, y = 680};
	f_second = {x=550, y = 590};
	f_third = {x=400, y = 680};
	f_catcher = {x=500, y = 870};
	f_left = {x = 280, y = 425};
	f_center = {x=500, y = 330};
	f_right = {x=720, y = 425};
  
  },
  
  --Coordinates for where fielder should throw or run the ball
  fieldTgt = nil,

  fielderTargetingBall = nil,
  
  runnersRetreating = false, --If fielder catches flyball, but runners were going, they have to go back
  runnersScored = {} --Stores all the runners who scored on a play, in case they have to retreat back
};

function gameCore:init(inDisplayGroup)

  utils:log("gameCore", "init()");

  -- Save reference to the DisplayGroup for gameScene.
  gc.gameDG = inDisplayGroup;

  -- Start physics engine and turn gravity on.
  physics.start(true);
  --physics.setDrawMode("hybrid");
  physics.setGravity( 0, 0 )
  --physics.setScale( 40 )
  
  gc:loadGraphics();
  gc:loadAudio();
  
  
  --Camera seems to be choppy and laggy when following ball
  --Must fix later after mechanics are working
  --Use something other than the perspective library
  gc.camera:add(gc.ball.sprite, 2, true);
  gc.camera:add(gc.field, 4, false);
  gc.camera:add(gc.walls, 3, false);
  
  for i,v in ipairs(gc.fielders) do
	gc.camera:add(v, 3, false);
  
  end
  gc.gameDG:insert(gc.camera);
  
  
  --Rig camera to baseball
  gc.camera.damping=20
  gc.camera:setBounds(false);
  gc.camera:track();

end -- End init().

function gameCore:loadGraphics() 

	--Initialize field and ball
	gc.field = display.newImage("Images/field.png", 0 , 0);
	gc.field.anchorX, gc.field.anchorY = 0, 0;
	gc.ball.sprite = display.newImage("Images/baseball.png", 100 , 100);
	gc.ball.sprite.name = "ball";
	gc.ball.sprite.xScale, gc.ball.sprite.yScale = .1,.1;
	gc.ball.sprite.x, gc.ball.sprite.y = gc.fieldPos.home.x, gc.fieldPos.home.y;
	local nw, nh = gc.ball.sprite.width*gc.ball.sprite.xScale*.5, gc.ball.sprite.height*gc.ball.sprite.yScale*.5;
	physics.addBody(gc.ball.sprite, "dynamic", { density = 1, friction = 2, bounce = 0 , shape={-nw,-nh,nw,-nh,nw,nh,-nw,nh}});
	
	--Initialize Walls
	gc.walls = display.newLine(35,395,   342, 203 );
	gc.walls.name = "walls";
	gc.walls:append(655,203,   963,395);
	gc.walls:setColor(1,0,0,1);
	gc.walls.width = 3;
	physics.addBody(gc.walls, "dynamic", { density = 1, friction = 2, bounce = 0});
	--gc.walls.isSleepingAllowed = false;
	
	--Initialize Fielders
	local leftfielder = display.newImage("Images/fielder.png", gc.fieldPos.f_left.x , gc.fieldPos.f_left.y);
	local centerfielder = display.newImage("Images/fielder.png", gc.fieldPos.f_center.x , gc.fieldPos.f_center.y);
	local rightfielder = display.newImage("Images/fielder.png", gc.fieldPos.f_right.x , gc.fieldPos.f_right.y);
	local first = display.newImage("Images/fielder.png", gc.fieldPos.f_first.x , gc.fieldPos.f_first.y);
	local second = display.newImage("Images/fielder.png", gc.fieldPos.f_second.x , gc.fieldPos.f_second.y);
	local short = display.newImage("Images/fielder.png", gc.fieldPos.f_short.x , gc.fieldPos.f_short.y);
	local third = display.newImage("Images/fielder.png", gc.fieldPos.f_third.x , gc.fieldPos.f_third.y);
	local catcher = display.newImage("Images/fielder.png", gc.fieldPos.f_catcher.x , gc.fieldPos.f_catcher.y);
	local pitcher = display.newImage("Images/fielder.png", gc.fieldPos.f_pitcher.x , gc.fieldPos.f_pitcher.y);
	leftfielder.name = "left";
	centerfielder.name = "center";
	rightfielder.name = "right";
	first.name = "first";
	second.name = "second";
	short.name = "short";
	third.name = "third";
	catcher.name = "catcher";
	pitcher.name = "pitcher";
	physics.addBody(leftfielder, "dynamic", { density = 1, friction = 2, bounce = 0, isSensor = true});
	physics.addBody(centerfielder, "dynamic", { density = 1, friction = 2, bounce = 0, isSensor = true});
	physics.addBody(rightfielder, "dynamic", { density = 1, friction = 2, bounce = 0, isSensor = true});
	physics.addBody(first, "dynamic", { density = 1, friction = 2, bounce = 0, isSensor = true});
	physics.addBody(second, "dynamic", { density = 1, friction = 2, bounce = 0, isSensor = true});
	physics.addBody(short, "dynamic", { density = 1, friction = 2, bounce = 0, isSensor = true});
	physics.addBody(third, "dynamic", { density = 1, friction = 2, bounce = 0, isSensor = true});
	physics.addBody(catcher, "dynamic", { density = 1, friction = 2, bounce = 0, isSensor = true});
	physics.addBody(pitcher, "dynamic", { density = 1, friction = 2, bounce = 0, isSensor = true});
	table.insert(gc.fielders, leftfielder);
	table.insert(gc.fielders, centerfielder);
	table.insert(gc.fielders, rightfielder);
	table.insert(gc.fielders, first);
	table.insert(gc.fielders, second);
	table.insert(gc.fielders, short);
	table.insert(gc.fielders, third);
	table.insert(gc.fielders, catcher);
	table.insert(gc.fielders, pitcher);
	
	--Test runners to fix bug, remove later
	--[[local runner3 = display.newImage("Images/fielder3.png", gc.fieldPos.third.x , gc.fieldPos.third.y);
	gc.camera:add(runner3, 3, false); --Add runner to the camera so he shows up
	runner3.name = "runner";
	runner3.current = "third";
	table.insert(gc.runners, runner3);
	
	local runner2 = display.newImage("Images/fielder3.png", gc.fieldPos.second.x , gc.fieldPos.second.y);
	gc.camera:add(runner2, 3, false); --Add runner to the camera so he shows up
	runner2.name = "runner";
	runner2.current = "second";
	table.insert(gc.runners, runner2);
	
	
	local runner = display.newImage("Images/fielder3.png", gc.fieldPos.first.x , gc.fieldPos.first.y);
	gc.camera:add(runner, 3, false); --Add runner to the camera so he shows up
	runner.name = "runner";
	runner.current = "first";
	table.insert(gc.runners, runner);]]--
	
	
	

	gc:hitBall();
end

function gameCore:loadAudio()

end

function gameCore:start()

  utils:log("gameCore", "start()");

  -- Activate multitouch.
  --system.activate("multitouch")

  -- Add listeners for main loop and collision detection.
  Runtime:addEventListener("enterFrame", gc);
  Runtime:addEventListener("collision", gc);
  Runtime:addEventListener("touch", gc);

end -- End start().

function gameCore:stop()

  utils:log("gameCore", "stop()");

  -- Dectivate multitouch.
  --system.deactivate("multitouch")

  -- Stop the physics engine.
  physics.stop();

  -- Remove listeners for main loop and collision detection.
  Runtime:removeEventListener("enterFrame", gc);
  Runtime:removeEventListener("collision", gc);
  Runtime:removeEventListener("touch", gc);

end -- End stop().

function gameCore:destroy()

  utils:log("gameCore", "destroy()");

  --gc:clearLevel();
  --gc:destroyMenu();
  --gc:destroyGamePlayArea();
  
  -- Audio.  All must be stopped if playing, disposed of an nil'd.
  --[[if gc.explosionSoundChannel ~= nil then
    audio.stop(gc.explosionSoundChannel);
  end
  audio.dispose(gc.explosionSoundChannel);
  gc.explosionSoundChannel = nil;
  gc.explosionSound = nil;]]--
  
  
  -- Graphics.

  -- Display Groups.  Note that gameDG already had removeSelf() called on it
  -- as part of the scene transition so we just need to nil the reference.
  gc.gameDG = nil;


end -- End destroy().

function gameCore:showMessage(inMsg)

  utils:log("gameCore", "showMessage(): inMsg = " .. inMsg);

  -- Create message text.
  local msgText = display.newText(inMsg, 0, 0, nil, 20);
  msgText:setFillColor(1, 1, 1,1);
  msgText.x = display.contentCenterX;
  msgText.y = display.contentCenterY;
  msgText.alpha = 1;
  msgText.xScale = 1.0;
  msgText.yScale = 1.0;

  transition.to(msgText,
    { time = 1000, alpha = 0, xScale = 5.0, yScale = 5.0,
      onComplete = function(inTarget)
        inTarget:removeSelf();
        inTarget = nil;
      end
    }
  );

end -- End showMessage().

function gameCore:stopAllActivity()

end -- End stopAllActivity().


--Baseball Functions
function gameCore:hitBall()
	
	--This function resets essential settings and initializes a new ball
	
	gc.runnersRetreating = false;
	gc.runnersScored = {};
	--Bounce off wall 148, 133, 35
	gc.ball.direction = math.random(45,135);
	gc.ball.velocity = math.random(140,150);
	gc.ball.launchAngle = math.random(5,70);
	gc.ball.initialHeight = 3;
	gc.ball.height = 3;
	gc.ball.launchOrigin.x, gc.ball.launchOrigin.y = gc.fieldPos.home.x, gc.fieldPos.home.y;
	gc.ball.wallCounter = 0; --Meant for wall hitting physics
	gc.ball.rolling = false; --Initially off bat, ball is not rolling
	
	gc.ball.firstCatch = true; --Ball has not been caught yet
	gc.ball.numBounces = 0;
	
	gc.counter = 0;
	print("Ball Direction: " .. tostring(gc.ball.direction) .. "  Ball Velocity: " .. 
		tostring(gc.ball.velocity) .. "  Launch Angle: " .. tostring(gc.ball.launchAngle));
		
	gc:resetFielders();
	gc:updateFielderTargets();
	
	gc:newRunner();
	
	--Runners must decide what to do once the ball goes off the bat
	for i=1, #gc.runners do
		gc:runnerDecide(gc.runners[i], "hit");
	end

end

function gameCore:newBall()

	--Hit another ball
	gc.camera:cancel();
	gc.ball.sprite:removeSelf();
	gc.ball.sprite = nil;

	local function hitTheBall()
		gc.ball.sprite = display.newImage("Images/baseball.png", 100 , 100);
		gc.ball.sprite.name = "ball";
		gc.ball.sprite.xScale, gc.ball.sprite.yScale = .1,.1;
		gc.ball.sprite.x, gc.ball.sprite.y = gc.fieldPos.home.x, gc.fieldPos.home.y;
		local nw, nh = gc.ball.sprite.width*gc.ball.sprite.xScale*.5, gc.ball.sprite.height*gc.ball.sprite.yScale*.5;
		physics.addBody(gc.ball.sprite, "dynamic", { density = 1, friction = 2, bounce = 0 , shape={-nw,-nh,nw,-nh,nw,nh,-nw,nh}});
		gc.ball.sprite.xScale, gc.ball.sprite.yScale = .1,.1;
		gc.ball.sprite.x, gc.ball.sprite.y = gc.fieldPos.home.x, gc.fieldPos.home.y;
		gc:hitBall();
		gc.ball.tCounter = 0;
		for i=1, #gc.ball.trail do
			gc.ball.trail[i]:removeSelf() -- Optional Display Object Removal
			gc.ball.trail[i] = nil -- Nil Out Table Instance
		end
		gc.camera:add(gc.ball.sprite, 2, true);
		gc.camera:track();
	end
	timer.performWithDelay(3000, hitTheBall);

end

--After ball is hit, determine where fielder should go to catch ball
function gameCore:updateFielderTargets(ballRolling)
	
	local fielderWithShortestDistance; --The fielder with shortest distance to catch ball
	
	if (ballRolling ~= true) then
	--Ball bouncing
	local v = gc.ball.velocity;
	local theta = math.rad(gc.ball.launchAngle);
	local h = gc.ball.initialHeight;
	local direction = math.rad(gc.ball.direction) ;
	local origX, origY = gc.ball.launchOrigin.x, gc.ball.launchOrigin.y;
	
	
	--Quadratic formula to find time when ball bounces
	local bounces = {}; --Table to store bounce data: time, x,y
	local curTime = 0; --Used to track time before each bounce
	
	repeat--Only calculate bounce locations, when theta <= 2, ball starts rolling
	
		--The plus part of quadratic formula; Can ignore
		local time1 = (-v*math.sin(theta) + math.sqrt(    math.pow(v*math.sin(theta),2)   + 64 * h) ) / -32;
		--print("Time1: " .. time1);
		
		--Time 2 is value we're looking for
		local time2 = (-v*math.sin(theta) - math.sqrt(    math.pow(v*math.sin(theta),2)   + 64 * h) ) / -32;
		--print("Time2: " .. time2);
		
		--Round up time to nearest (1/30) of a second because the fps of this game is 30
		if (    (time2 % (1/30))   ~=    0) then
			local n = (time2 / (1/30));
			n = math.ceil(n);
			time2 = n * (1/30);
		end
		curTime = curTime + time2;
		
		--Using that time, determine location of the bounce
		local d = v * math.cos( theta ) * time2; --Distance
		
		local landingX = origX + d * math.cos( direction );
		local landingY = origY - d * math.sin( direction );
		
		
		--Mark the ball's projected landing coordinates during first bounce
		--local hit = display.newImage("Images/mark.png", landingX , landingY);
		--gc.camera:add(hit, 3, false);
		
		--Simulate ball bounce
		theta = math.abs(theta) * .75;
		v = v * .75;
		origX, origY = landingX, landingY;
		h = 0;
		
		
		print("Projected Bounce " .. "X - " .. landingX .. " Y- " .. landingY);
		
		table.insert(bounces, {time = curTime, x = landingX, y = landingY});

	until (math.deg(theta) < 2)

	--Determine target location for each fielder
	local canBeCaughtFirstBounce = false; --Being caught before the first bounce is priority, even if fielder has to travel longer distance
	local shortestDistance = 100000; --Used to determine which fielder chases the ball
	fielderWithShortestDistance = -1;
	for i=1, #gc.fielders do
		
		
		--Determine whether fielder can run to a bounce location in time.
		--Want fielder to target bounce that has the shortest time, but the fielder still must be able to make it
		local target = -1;
		local x = gc.fielders[i].x;
		local y = gc.fielders[i].y;
		local distanceFirstBounce = math.sqrt(math.pow( math.abs(gc.fieldPos.home.x-bounces[1].x),2)+ math.pow(math.abs(gc.fieldPos.home.y-bounces[1].y),2)  );
		
		--Loop through bounce locations to set local target
		for n=1, #bounces do
			--Phythagorean theorem used to calculate distance between fielder and bounce location
			local distance = math.sqrt(math.pow( math.abs(x-bounces[n].x),2)+ math.pow(math.abs(y-bounces[n].y),2)  );
			
			--Determine time it will take fielder to reach the bounce location
			local fielderTime = distance / 30; --Assuming 30 is the fielder speed
			
			--If fielder can make it to the bounce location in time
			if (fielderTime <= bounces[n].time) then
				target = n;
				
				--Following if else determines which fielder has the shortest distance
				--And that fielder is the one that should be moving
				if (n == 1) then--N=1 means first bounce

					if (not canBeCaughtFirstBounce) then
						shortestDistance = distance;
						fielderWithShortestDistance = i;
						canBeCaughtFirstBounce = true;
					else
						--Some fielder can already catch the ball on first bounce
						--Compare distances to see which fielder should catch it
						if (distance < shortestDistance) then
							shortestDistance = distance;
							fielderWithShortestDistance = i;
							canBeCaughtFirstBounce = true;
						end
					end
				else
					--Takes care of bounces that aren't the first one. These have a lesser priority than 1st bounce.
					if (not canBeCaughtFirstBounce) then
						if (distance < shortestDistance) then
							shortestDistance = distance;
							fielderWithShortestDistance = i;
						end
					end
				
				end
				break;
			end
			
			--Even if fielder can't make it to any of the bounce locations in time, he will target
			--Toward the last bounce location or first bounce location, depending on distance of first bounce from the plate
			if (n == #bounces) then
				
				if (distanceFirstBounce > 400) then 
					--Target First Bounce
					target = 1;
					distance =  math.sqrt(math.pow( math.abs(x-bounces[1].x),2)+ math.pow(math.abs(y-bounces[1].y),2)  );
				else
					target = #bounces;
				end
				--Fielder with shortest distance to the ball, he should be the one targeting the ball
				if (distance < shortestDistance and not canBeCaughtFirstBounce) then
					shortestDistance = distance;
					fielderWithShortestDistance = i;
				end
			end
		end
		
		--Set the fielder's target as the targeted bounce as calculated above
		gc.fielders[i].target = {x = bounces[target].x, y = bounces[target].y};

	end
	
	if (canBeCaughtFirstBounce) then
		gc.ball.isCatchable = true;
	else
		gc.ball.isCatchable = false;
	end
	
	--print("Fielder With Shortest Distance: " .. gc.fielders[fielderWithShortestDistance].name .. "  " .. shortestDistance);
	--Only fielder with shortest distance to cover should move toward the ball
	--Set other fielder targets to nil
	for i=1, #gc.fielders do
		if (i ~= fielderWithShortestDistance) then
			gc.fielders[i].target = nil;
		end
	end
	gc.fielderTargetingBall = fielderWithShortestDistance;
	
	else 
		--Ball rolling logic
		--Fielder closest to the ball chases it
		local shortestDistance = 100000; --Used to determine which fielder chases the ball
		fielderWithShortestDistance = -1;
		
		for i=1, #gc.fielders do
			local x = gc.fielders[i].x;
			local y = gc.fielders[i].y;
			local distance = math.sqrt(math.pow( math.abs(x-gc.ball.sprite.x),2)+ math.pow(math.abs(y-gc.ball.sprite.y),2)  );
			
			if (distance < shortestDistance) then
				shortestDistance = distance;
				fielderWithShortestDistance = i;
			end
		end
		
		gc.fielders[fielderWithShortestDistance].target = {x = gc.ball.sprite.x, y = gc.ball.sprite.y};
		gc.fielderTargetingBall = fielderWithShortestDistance;
	end
	
	--Now set targets for all other fielders who aren't chasing the ball
	--Other fielders should appropriately cover designated bags
	print("fielderWithShortestDistance: " .. fielderWithShortestDistance .. "  ballRolling: " .. tostring(ballRolling));
	local activeFielder = gc.fielders[fielderWithShortestDistance].name; --Fielder that is catching ball
	if (activeFielder == "pitcher" or activeFielder == "left" or activeFielder == "center" or activeFielder == "right"
		or activeFielder == "short") then
		--Assume order of fielders in gc.fielders list is:
		--1 left, 2 center, 3 right, 4 first, 5 second, 6 short, 7 third, 8 catcher, 9 pitcher	
		gc.fielders[4].target =  {x = gc.fieldPos.first.x , y = gc.fieldPos.first.y}
		gc.fielders[5].target =  {x = gc.fieldPos.second.x , y = gc.fieldPos.second.y}
		gc.fielders[7].target =  {x = gc.fieldPos.third.x , y = gc.fieldPos.third.y}
		gc.fielders[8].target =  {x = gc.fieldPos.home.x , y = gc.fieldPos.home.y}
	elseif (activeFielder == "first") then
		gc.fielders[9].target =  {x = gc.fieldPos.first.x , y = gc.fieldPos.first.y}
		gc.fielders[5].target =  {x = gc.fieldPos.second.x , y = gc.fieldPos.second.y}
		gc.fielders[7].target =  {x = gc.fieldPos.third.x , y = gc.fieldPos.third.y}
		gc.fielders[8].target =  {x = gc.fieldPos.home.x , y = gc.fieldPos.home.y}
	elseif (activeFielder == "second") then
		gc.fielders[4].target =  {x = gc.fieldPos.first.x , y = gc.fieldPos.first.y}
		gc.fielders[6].target =  {x = gc.fieldPos.second.x , y = gc.fieldPos.second.y}
		gc.fielders[7].target =  {x = gc.fieldPos.third.x , y = gc.fieldPos.third.y}
		gc.fielders[8].target =  {x = gc.fieldPos.home.x , y = gc.fieldPos.home.y}
	elseif (activeFielder == "third") then
		gc.fielders[4].target =  {x = gc.fieldPos.first.x , y = gc.fieldPos.first.y}
		gc.fielders[5].target =  {x = gc.fieldPos.second.x , y = gc.fieldPos.second.y}
		gc.fielders[9].target =  {x = gc.fieldPos.third.x , y = gc.fieldPos.third.y}
		gc.fielders[8].target =  {x = gc.fieldPos.home.x , y = gc.fieldPos.home.y}
	elseif (activeFielder == "catcher") then
		gc.fielders[4].target =  {x = gc.fieldPos.first.x , y = gc.fieldPos.first.y}
		gc.fielders[5].target =  {x = gc.fieldPos.second.x , y = gc.fieldPos.second.y}
		gc.fielders[7].target =  {x = gc.fieldPos.third.x , y = gc.fieldPos.third.y}
		gc.fielders[9].target =  {x = gc.fieldPos.home.x , y = gc.fieldPos.home.y}
	end
	
	

end

--Reset Fielders after each hit
function gameCore:resetFielders()

	--Reset outfielders to norm positions
	if (gc.fielders[1] ~= nil) then
	gc.fielders[1].x, gc.fielders[1].y =  gc.fieldPos.f_left.x , gc.fieldPos.f_left.y;
	gc.fielders[2].x, gc.fielders[2].y =  gc.fieldPos.f_center.x , gc.fieldPos.f_center.y;
	gc.fielders[3].x, gc.fielders[3].y =  gc.fieldPos.f_right.x , gc.fieldPos.f_right.y;
	gc.fielders[4].x, gc.fielders[4].y =  gc.fieldPos.f_first.x , gc.fieldPos.f_first.y;
	gc.fielders[5].x, gc.fielders[5].y =  gc.fieldPos.f_second.x , gc.fieldPos.f_second.y;
	gc.fielders[6].x, gc.fielders[6].y =  gc.fieldPos.f_short.x , gc.fieldPos.f_short.y;
	gc.fielders[7].x, gc.fielders[7].y =  gc.fieldPos.f_third.x , gc.fieldPos.f_third.y;
	gc.fielders[8].x, gc.fielders[8].y =  gc.fieldPos.f_catcher.x , gc.fieldPos.f_catcher.y;
	gc.fielders[9].x, gc.fielders[9].y =  gc.fieldPos.f_pitcher.x , gc.fieldPos.f_pitcher.y;
	end
	
	gc:resetFielderHitWalls();
	gc:resetFielderCaughtBall();
	gc:resetFielderHasBall();

end

--After ball bounces off wall, fielders that were at the wall can now move again
function gameCore:resetFielderHitWalls()

	for i=1, #gc.fielders do
		
		gc.fielders[i].hitWall = false;
	
	end

end

--After fielder throws ball, he can catch balls again
function gameCore:resetFielderCaughtBall()

	for i=1, #gc.fielders do
		
		gc.fielders[i].caughtBall = false;
	
	end

end

--After fielder throws ball, he can catch balls again
function gameCore:resetFielderHasBall()

	for i=1, #gc.fielders do
		
		gc.fielders[i].hasBall = false;
	
	end

end

function gameCore:getFielderThatHasBall()

	for i=1, #gc.fielders do
		if (gc.fielders[i].hasBall) then
			return gc.fielders[i]; --One fielder does indeed possess the ball
		end
	end
	
	return nil;

end

--Throw the ball to a target
function gameCore:throwBall(tgtx, tgty, thrower)
	
	if (gc.ball.sprite == nil) then return end
	
	local curHeight = gc.ball.height
	local curX = gc.ball.sprite.x
	local curY = gc.ball.sprite.y
	
	local dx = curX - tgtx; --Change in x
	local dy = curY - tgty; --Change in y
	
	--Calculate the direction of the throw --DOne
	local theta = math.deg(math.atan(math.abs(dx/dy)));
	if (dy > 0 and dx > 0) then
		theta = theta + 90;
	elseif (dy > 0 and dx < 0) then
		theta = 90 - theta;
	elseif (dy < 0 and dx < 0) then
		theta = -90 + theta;
	elseif (dy < 0 and dx > 0) then
		theta = -90 - theta;
		
		
	elseif (dy > 0 and dx == 0) then
		theta = 90;
	elseif (dy < 0 and dx == 0) then
		theta = 270;
	elseif (dx > 0 and dy == 0) then
		theta = 180
	elseif (dx < 0 and dy == 0) then
		theta = 0;
	end
	

	--Calculate distance between fielder and target
	local distance = math.sqrt(math.pow( math.abs(dx),2)+ math.pow(math.abs(dy),2)  );
	
	
	--Actual throwing of ball	
	gc.ball.direction = theta;
	gc.ball.velocity = 100; --Power of the fielder
	gc.ball.launchAngle = math.deg(math.asin( (32 * distance) / (gc.ball.velocity * gc.ball.velocity) ) / 2 );
	
	gc.ball.initialHeight = 3;
	gc.ball.height = 3;
	gc.ball.launchOrigin.x, gc.ball.launchOrigin.y = curX, curY;
	gc.ball.wallCounter = 0; --Meant for wall hitting physics
	gc.ball.rolling = false; --Initially off bat, ball is not rolling
	gc.ball.throwTgt = {x = tgtx, y = tgty};
	
	if (tostring(gc.ball.launchAngle) == tostring(0/0)) then
		--Launch angle is indeterminate, which means that fielder does not have enough power to throw the ball
		--To the target in one bounce; To compensate we just launch at the optimal angle
		gc.ball.launchAngle = 35;
		
		--Readjust the throwTgt accordingly (throwTgt is actually more like throwDestination)
		local v, theta, h = gc.ball.velocity, math.rad(gc.ball.launchAngle), gc.ball.height;
		local time2 = (-v*math.sin(theta) - math.sqrt(    math.pow(v*math.sin(theta),2)   + 64 * h) ) / -32;
		local d = v * math.cos( theta ) * time2; --Distance
		local landingX = curX + d * math.cos( math.rad(gc.ball.direction) );
		local landingY = curY - d * math.sin( math.rad(gc.ball.direction) );
		gc.ball.throwTgt = {x = landingX, y = landingY};
		--Mark the ball's projected landing coordinates during first bounce
		--local hit = display.newImage("Images/mark.png", landingX , landingY);
		--gc.camera:add(hit, 3, false);
		
		gc:updateFielderTargets(); --Ball may not reach target, so we have to adjust the fielders to compensate
		
		for i=1, #gc.fielders do
			--Allows everyone, except the thrower, to catch the ball
			if (gc.fielders[i] ~= thrower) then
				gc.fielders[i].caughtBall = false;
			end
		end
	end
	
	gc.ball.tCounter = 0;
	gc.ball.throwDuration = gc:getThrowDuration(gc.ball.sprite.x, gc.ball.sprite.y, tgtx, tgty);
	
	for i=1, #gc.ball.trail do
		gc.ball.trail[i]:removeSelf() -- Optional Display Object Removal
		gc.ball.trail[i] = nil -- Nil Out Table Instance
	end
end

--Fielder decides what to do with the ball once he has it
function gameCore:fielderDecide(thrower)
	
	local fielder = gc:getFielderThatHasBall();
	
	--Determine whether to start new hit, because fielder takes no action
	local allTargetsNil = true;
	for i = 1, #gc.runners do
		if (gc.runners[i].target ~= nil) then
			allTargetsNil = false;
			break;
		end
	end
	if (allTargetsNil or #gc.runners < 0) then
		--No runners or no runners running, therefore no reason to throw ball around
		--Next batter up
		gc:newBall();
		gc.fieldTgt = nil;
		return;
	end
	
	
	--Decide which base to throw it to
	--Throw the ball to the runner closest to reaching home
	local base = nil;
	
	--Try to throw out on the most advanced runner possible
	for i = 1, #gc.runners do
		local runner = gc.runners[i];
		local throwTime = 0;
		local runTime = 0;
		
		
		if(runner.target == "first") then
			throwTime = gc:getThrowDuration(gc.ball.sprite.x, gc.ball.sprite.y, gc.fieldPos.first.x, gc.fieldPos.first.y, true);
			runTime =  math.sqrt(math.pow( math.abs(runner.x - gc.fieldPos.first.x),2)
						+ math.pow(math.abs(runner.y - gc.fieldPos.first.y),2)  ) / 30;  --t = d/r
		elseif(runner.target == "second") then
			throwTime = gc:getThrowDuration(gc.ball.sprite.x, gc.ball.sprite.y, gc.fieldPos.second.x, gc.fieldPos.second.y, true);
			runTime =  math.sqrt(math.pow( math.abs(runner.x - gc.fieldPos.second.x),2)
						+ math.pow(math.abs(runner.y - gc.fieldPos.second.y),2)  ) / 30;  --t = d/r
		elseif(runner.target == "third") then
			throwTime = gc:getThrowDuration(gc.ball.sprite.x, gc.ball.sprite.y, gc.fieldPos.third.x, gc.fieldPos.third.y, true);
			runTime =  math.sqrt(math.pow( math.abs(runner.x - gc.fieldPos.third.x),2)
						+ math.pow(math.abs(runner.y - gc.fieldPos.third.y),2)  ) / 30;  --t = d/r
		elseif(runner.target == "home") then
			throwTime = gc:getThrowDuration(gc.ball.sprite.x, gc.ball.sprite.y, gc.fieldPos.home.x, gc.fieldPos.home.y, true);
			runTime =  math.sqrt(math.pow( math.abs(runner.x - gc.fieldPos.home.x),2)
						+ math.pow(math.abs(runner.y - gc.fieldPos.home.y),2)  ) / 30;  --t = d/r
		end
		
		if (throwTime < runTime) then
			base = runner.target;
		end
	end
	
	if (base == nil) then --Can't throw anyone out, just throw to the target base of most advanced runner
		base = gc.runners[1].target;
	end 
	if (base == nil) then --Runners not running
		base = gc.runners[1].current;
	end
	if (base == "first") then
		gc.fieldTgt = {x = gc.fieldPos.first.x, y = gc.fieldPos.first.y};
	elseif (base == "second") then
		gc.fieldTgt = {x = gc.fieldPos.second.x, y = gc.fieldPos.second.y};
	elseif (base == "third") then
		gc.fieldTgt = {x = gc.fieldPos.third.x, y = gc.fieldPos.third.y};
	elseif (base == "home") then
		gc.fieldTgt = {x = gc.fieldPos.home.x, y = gc.fieldPos.home.y};
	end
	
	
	local shortestDistance = 100000;
	local index = -1; --Index of fielder closest to target bag
	
	--Find closest fielder to the target bag
	for i=1, #gc.fielders do
		local d = math.sqrt(math.pow( math.abs(gc.fielders[i].x - gc.fieldTgt.x),2)+ math.pow(math.abs(gc.fielders[i].y - gc.fieldTgt.y),2)  );
		if (d < shortestDistance) then index = i; shortestDistance = d; end
	end	
	
	if (gc.fielders[index] == thrower) then
		--print("Should be running!");
		--Person closest to target bag is the thrower
		--He should run to bag, not throw
		local time = (shortestDistance / 30) * 1000; --t = d/r
		gc.fielders[index].target = gc.fieldTgt;
		local function f()
					gc:fielderDecide(otherObjectReference);
		end
		timer.performWithDelay(time+50, f); --After fielder reaches bag, decide what to do again
	
	else
		--Throw ball
		--Make sure that only that fielder can catch the throw
		for i=1, #gc.fielders do
			 --Prevents other fielders from catching ball that isn't meant for them
			gc.fielders[i].caughtBall = true;
		end
		gc.fielders[index].caughtBall = false;
		
		--Wait for fielder to get to bag first
		gc.fielders[index].target = gc.fieldTgt;
		local time = (shortestDistance / 30) * 1000; --t = d/r
		
		--print("TIME: " .. time);
		
		local function throw()
			--Throw ball
			gc.fielderMode = "throwing";
			fielder.hasBall = false;
			gc:throwBall(gc.fieldTgt.x, gc.fieldTgt.y, thrower);
		end
		
		timer.performWithDelay(time, throw);
	end
	
	gc.counter = gc.counter+1;
end


--Base runner methods

--Create new runner
function gameCore:newRunner()

	local runner = display.newImage("Images/fielder3.png", gc.fieldPos.home.x , gc.fieldPos.home.y);
	gc.camera:add(runner, 3, false); --Add runner to the camera so he shows up
	
	runner.name = "runner";
	runner.target = "first";
	runner.current = "home";
	
	table.insert(gc.runners, runner);

end

--Remove runner @ index
function gameCore:removeRunner(index)
	gc.runners[index]:removeSelf();
	gc.runners[index] = nil;
	table.remove(gc.runners, index);
end

--Move runner to next base
function gameCore:advanceRunner(runner)

	if (runner.current == "home") then
		runner.target = "first";
	elseif (runner.current == "first") then
		local valid = true; --Only advance base if runner is not occupying target base
		for i = 1, #gc.runners do
			if (gc.runners[i].current == "second" and gc.runners[i].target == nil) then
				valid = false;
				break;
			end
		end
		if (valid) then
		runner.target = "second";
		end
	elseif (runner.current == "second") then
		local valid = true; --Only advance base if runner is not occupying target base
		for i = 1, #gc.runners do
			if (gc.runners[i].current == "third" and gc.runners[i].target == nil) then
				valid = false;
				break;
			end
		end
		if (valid) then
		runner.target = "third";
		end
	elseif (runner.current == "third") then
		runner.target = "home";
	end

end

--Move runner to previous base
function gameCore:retreatRunner(runner)

	if (runner.current == "home") then
		runner.target = "third";
	elseif (runner.current == "third") then
		runner.target = "second";
	elseif (runner.current == "second") then
		runner.target = "first";
	end

end

--Runner decides if he wants to move to the next base when:
--He reaches a base, tag play, ball is hit
--Needs polishing
function gameCore:runnerDecide(runner, event)
	
	if (event == "hit") then --The ball has been hit
		
		runner.originalBase = runner.current; --Remembers the base that the runner was on
		
		--Hit ball not catchable, must run
		if (not gc.ball.isCatchable) then 
			gc:advanceRunner(runner);
		end
		
		
		--If ball is catchable, then the runner should not advance yet
		
	end
	
	if (event == "tag") then --Flyball has been caught, see if runner can tag up
		
		local throwTime = 0;
		local runTime = 0;
		
		if(runner.current == "first") then
			throwTime = gc:getThrowDuration(gc.ball.sprite.x, gc.ball.sprite.y, gc.fieldPos.second.x, gc.fieldPos.second.y, true);
			runTime =  math.sqrt(math.pow( math.abs(runner.x - gc.fieldPos.second.x),2)
						+ math.pow(math.abs(runner.y - gc.fieldPos.second.y),2)  ) / 30;  --t = d/r
		elseif(runner.current == "second") then
			throwTime = gc:getThrowDuration(gc.ball.sprite.x, gc.ball.sprite.y, gc.fieldPos.third.x, gc.fieldPos.third.y, true);
			runTime =  math.sqrt(math.pow( math.abs(runner.x - gc.fieldPos.third.x),2)
						+ math.pow(math.abs(runner.y - gc.fieldPos.third.y),2)  ) / 30;  --t = d/r
		elseif(runner.current == "third") then
			throwTime = gc:getThrowDuration(gc.ball.sprite.x, gc.ball.sprite.y, gc.fieldPos.home.x, gc.fieldPos.home.y, true);
			runTime =  math.sqrt(math.pow( math.abs(runner.x - gc.fieldPos.home.x),2)
						+ math.pow(math.abs(runner.y - gc.fieldPos.home.y),2)  ) / 30;  --t = d/r
		end
		
		--print("--------");
		--print("Runner @: " .. runner.current)
		--print("Throw Time: " .. throwTime);
		--print("Run Time: " .. runTime);
		
		
		if (runTime < throwTime) then
			gc:advanceRunner(runner);
			--print("Running");
		else
			--print("Staying");
		end
		
		--print("--------");
		
	end

	if (event == "base") then --Runner has reached a base, decide to see if they go to next one
	
		if(not gc.runnersRetreating) then
		print("_______________________");
		print("Runner rounding " .. runner.current);
		if (gc.ball.firstCatch == true) then --********1********
			print("Ball has not been caught yet");
			--Ball has not yet been touched by fielder
			--This game logic is not very polished
			local throwTime = 0;
			local runTime = 0;
			local distanceFromBall = math.sqrt(math.pow( math.abs(gc.ball.sprite.x - gc.fielders[gc.fielderTargetingBall].x),2)
							+ math.pow(math.abs(gc.ball.sprite.y - gc.fielders[gc.fielderTargetingBall].y),2)  )
			throwTime = throwTime + distanceFromBall / 30; --t = d/r
			print("Time for fielder to get to ball: " .. throwTime);
			
			if(runner.current == "first") then
				throwTime = throwTime + gc:getThrowDuration(gc.ball.sprite.x, gc.ball.sprite.y, gc.fieldPos.second.x, gc.fieldPos.second.y);
				runTime =  math.sqrt(math.pow( math.abs(runner.x - gc.fieldPos.second.x),2)
							+ math.pow(math.abs(runner.y - gc.fieldPos.second.y),2)  ) / 30;  --t = d/r
			elseif(runner.current == "second") then
				throwTime = throwTime + gc:getThrowDuration(gc.ball.sprite.x, gc.ball.sprite.y, gc.fieldPos.third.x, gc.fieldPos.third.y);
				runTime =  math.sqrt(math.pow( math.abs(runner.x - gc.fieldPos.third.x),2)
							+ math.pow(math.abs(runner.y - gc.fieldPos.third.y),2)  ) / 30;  --t = d/r
			elseif(runner.current == "third") then
				throwTime = throwTime + gc:getThrowDuration(gc.ball.sprite.x, gc.ball.sprite.y, gc.fieldPos.home.x, gc.fieldPos.home.y);
				runTime =  math.sqrt(math.pow( math.abs(runner.x - gc.fieldPos.home.x),2)
							+ math.pow(math.abs(runner.y - gc.fieldPos.home.y),2)  ) / 30;  --t = d/r
			end
			print("Total throw time: " .. throwTime);
			print("Total run time: " .. runTime);
			if (runTime < throwTime) then
				gc:advanceRunner(runner);
			end
			
		elseif(gc:getFielderThatHasBall() ~= nil) then --********2********
			print("Fielder currently has ball");
			--Fielder has ball
			local throwTime = 0;
			local runTime = 0;
			
			if(runner.current == "first") then
				throwTime = gc:getThrowDuration(gc.ball.sprite.x, gc.ball.sprite.y, gc.fieldPos.second.x, gc.fieldPos.second.y);
				runTime =  math.sqrt(math.pow( math.abs(runner.x - gc.fieldPos.second.x),2)
							+ math.pow(math.abs(runner.y - gc.fieldPos.second.y),2)  ) / 30;  --t = d/r
			elseif(runner.current == "second") then
				throwTime = gc:getThrowDuration(gc.ball.sprite.x, gc.ball.sprite.y, gc.fieldPos.third.x, gc.fieldPos.third.y);
				runTime =  math.sqrt(math.pow( math.abs(runner.x - gc.fieldPos.third.x),2)
							+ math.pow(math.abs(runner.y - gc.fieldPos.third.y),2)  ) / 30;  --t = d/r
			elseif(runner.current == "third") then
				throwTime = gc:getThrowDuration(gc.ball.sprite.x, gc.ball.sprite.y, gc.fieldPos.home.x, gc.fieldPos.home.y);
				runTime =  math.sqrt(math.pow( math.abs(runner.x - gc.fieldPos.home.x),2)
							+ math.pow(math.abs(runner.y - gc.fieldPos.home.y),2)  ) / 30;  --t = d/r
			end
			print("Total throw time: " .. throwTime);
			print("Total run time: " .. runTime);
			if (runTime < throwTime) then
				gc:advanceRunner(runner);
			end
			
		elseif(gc:getFielderThatHasBall() == nil and gc.ball.firstCatch == false) then --********3********
			print("Ball currently being thrown");
			--Ball is being thrown to some location
			local throwTime = 0;
			local runTime = 0;
			
			throwTime = gc.ball.throwDuration - gc.ball.tCounter; --Time left on ball flight
			print("Time left on ball flight: " .. throwTime);
			if(runner.current == "first") then
				--Time to throw from ball's new location to target bag
				throwTime = throwTime + gc:getThrowDuration(gc.ball.throwTgt.x, gc.ball.throwTgt.y, gc.fieldPos.second.x, gc.fieldPos.second.y);
				runTime =  math.sqrt(math.pow( math.abs(runner.x - gc.fieldPos.second.x),2)
							+ math.pow(math.abs(runner.y - gc.fieldPos.second.y),2)  ) / 30;  --t = d/r
			elseif(runner.current == "second") then
				throwTime = throwTime + gc:getThrowDuration(gc.ball.throwTgt.x, gc.ball.throwTgt.y, gc.fieldPos.third.x, gc.fieldPos.third.y);
				runTime =  math.sqrt(math.pow( math.abs(runner.x - gc.fieldPos.third.x),2)
							+ math.pow(math.abs(runner.y - gc.fieldPos.third.y),2)  ) / 30;  --t = d/r
			elseif(runner.current == "third") then
				throwTime = throwTime + gc:getThrowDuration(gc.ball.throwTgt.x, gc.ball.throwTgt.y, gc.fieldPos.home.x, gc.fieldPos.home.y);
				runTime =  math.sqrt(math.pow( math.abs(runner.x - gc.fieldPos.home.x),2)
							+ math.pow(math.abs(runner.y - gc.fieldPos.home.y),2)  ) / 30;  --t = d/r
			end
			print("Total throw time: " .. throwTime);
			print("Total run time: " .. runTime);
			if (runTime < throwTime) then
				gc:advanceRunner(runner);
			end
		end
		print("_______________________");
		else
			--Runners retreating logic
			if (runner.current == runner.originalBase) then
				--Runner has successfully retreated
			else
				print("Retreating further");
				gc:retreatRunner(runner);
			end
			
		
		end
	end
	
	
end

--See how long throw will be in air
--From thrower to target
function gameCore:getThrowDuration(origX, origY, tgtx, tgty, tagPlay, thrower)
	
	
	local dx = origX - tgtx; --Change in x
	local dy = origY - tgty; --Change in y
	

	--Calculate distance between fielder and target
	local distance = math.sqrt(math.pow( math.abs(dx),2)+ math.pow(math.abs(dy),2)  );
	local velocity = 100; --Power of the fielder
	local launchAngle = math.deg(math.asin( (32 * distance) / (velocity * velocity) ) / 2 );
	
	if (tostring(launchAngle) == tostring(0/0)) then
		--Launch angle is indeterminate, which means that fielder does not have enough power to throw the ball
		--To the target in one bounce; To compensate we just launch at the optimal angle
		launchAngle = 35;
		
		--In tag plays, we do not want the time it will take for the throw to go to the first bounce
		--We want time for throw to go to target, approximately
		if (tagPlay == nil or tagPlay == false) then 
			--Fielder does not have strength to throw it to target
			--The following returns how much time it will take for the throw to go to the first bounce
			local v, theta, h = velocity, math.rad(launchAngle), 3; --3 is height ball is thrown from
			local time2 = (-v*math.sin(theta) - math.sqrt(    math.pow(v*math.sin(theta),2)   + 64 * h) ) / -32;
			return time2;
		end
	end
	
	local time = distance / (velocity * math.cos(math.rad(launchAngle)));
		--print("Time for throw to reach tgt base: " .. time .. " (s)");
	return time;


end

return gameCore;
