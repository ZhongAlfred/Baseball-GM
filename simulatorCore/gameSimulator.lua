local sqlite3 = require "sqlite3"
local json = require("json");
local at = require("simulatorCore.attendance");

--**************************
--[[IMPORTANT NOTE

Unlike other files in the simulator core, this file does not handle database
Creation and destruction, Therefore use the following code:

	local path = system.pathForFile("data.db", system.DocumentsDirectory)
	db = sqlite3.open( path )
	db:exec("BEGIN TRANSACTION;") --Use transactions for faster speeds

	gs:simulateGame(t1_lineup, t2_lineup, t1_id, t2_id, gameid)
	
	db:exec("END TRANSACTION;")
	db:close()

]]--
--***************************


local gameSimulator = {
	
	gameIsOver = false,
	inning = 1,
	portion = "top", --Top = Away Batting, Bottom = Home batting
	num_outs = 0,
	
	balls = 0,
	strikes = 0,
	
	home_batter_index = 1, --Which batter is currently up
	away_batter_index = 1,
	
	home_batter_lineup = {},--List of all home batters
	away_batter_lineup = {},
	
	home_cur_pitcher = nil,
	away_cur_pitcher = nil,
	
	home_pitchers_list = {}, --List of all pitchers who have pitched in the game, in sequential order
	away_pitchers_list = {},
	
	diamond = {first = nil, second = nil, third = nil},
	
	home_score = 0,
	away_score = 0,
	num_pinch_hitters = 0, --Keeps track of the number of pinch hitters in the game
	
	--Stores the the number of runs scored per inning
	boxscore = {{top = 0, bottom = 0}} --Has at least 9 innings, may have more depending on score
	


}

--Returns the game score for now
--Returns team1's score and team2's score
--Team 1 = Away, Team 2 = Home
function gameSimulator:simulateGame(t1_lineup, t2_lineup, t1_id, t2_id, gameid)
	
	gameSimulator:reset(); --Make sure its a new game; Destroy data from previously simulated games
	
	
	--Sort team1's lineup by batting order
	local t1_list = {}
	--Contains list of name of positions by batting order:
	--Example t1_list = {"first", "catcher", "center", "left", "third", "dh", "second", "right", "short"}
	
	for name,value in pairs(t1_lineup) do
		if (name ~= "sp" and name ~= "bullpen" and name ~= "closer" and name ~= "bench") then
        t1_list[#t1_list+1] = name
		end
    end	
	function byval(a,b)
        return t1_lineup[a].batting_order < t1_lineup[b].batting_order
    end
	table.sort(t1_list,byval)
	
	
	--Sort team2's lineup by batting order
	local t2_list = {} 
	for name,value in pairs(t2_lineup) do
		if (name ~= "sp" and name ~= "bullpen" and name ~= "closer" and name ~= "bench") then
        t2_list[#t2_list+1] = name
		end
    end
	function byval(a,b)
        return t2_lineup[a].batting_order < t2_lineup[b].batting_order
    end
	table.sort(t2_list,byval)
	
	
	--Populate home_batter_lineup and away_batter_lineup using t1_list and t2_list
	for i = 1, #t1_list do
		gameSimulator.away_batter_lineup[#gameSimulator.away_batter_lineup+1] = t1_lineup[t1_list[i]];
	end
	for i = 1, #t2_list do
		gameSimulator.home_batter_lineup[#gameSimulator.home_batter_lineup+1] = t2_lineup[t2_list[i]];
	end
		
	
	--Set all curgame stats to zero. Curgame stats record stats for this game only
	--Without setting curgame stats to zero, a nil pointer exception will be thrown
	--Curgame stats will be added onto season stats when record data is called
	local positions = {"first", "second", "short", "third", "catcher", "dh", "left", "center", "right", "sp", "closer"}
	for i = 1, #positions do
		t1_lineup[positions[i]].curgame_AB, t1_lineup[positions[i]].curgame_R, t1_lineup[positions[i]].curgame_H, t1_lineup[positions[i]].curgame_DOUBLES,
		t1_lineup[positions[i]].curgame_TRIPLES, t1_lineup[positions[i]].curgame_HR, t1_lineup[positions[i]].curgame_RBI, t1_lineup[positions[i]].curgame_BB,
		t1_lineup[positions[i]].curgame_SO, t1_lineup[positions[i]].curgame_SB, t1_lineup[positions[i]].curgame_CS, t1_lineup[positions[i]].curgame_P_IP,
		t1_lineup[positions[i]].curgame_P_H, t1_lineup[positions[i]].curgame_P_ER, t1_lineup[positions[i]].curgame_P_HR, t1_lineup[positions[i]].curgame_P_BB,
		t1_lineup[positions[i]].curgame_P_SO, t1_lineup[positions[i]].curgame_pitchesThrown,t1_lineup[positions[i]].curgame_DRS,  
		t1_lineup[positions[i]].curgame_strikesThrown = 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;
		t1_lineup[positions[i]].curgame_pitchesLeft = gameSimulator:determineLongevity(t1_lineup[positions[i]].stamina, t1_lineup[positions[i]].posType);
		t1_lineup[positions[i]].curgame_gotWin, t1_lineup[positions[i]].curgame_gotLoss, t1_lineup[positions[i]].curgame_gotSave = 
			false, false, false
		
		t2_lineup[positions[i]].curgame_AB, t2_lineup[positions[i]].curgame_R, t2_lineup[positions[i]].curgame_H, t2_lineup[positions[i]].curgame_DOUBLES,
		t2_lineup[positions[i]].curgame_TRIPLES, t2_lineup[positions[i]].curgame_HR, t2_lineup[positions[i]].curgame_RBI, t2_lineup[positions[i]].curgame_BB,
		t2_lineup[positions[i]].curgame_SO, t2_lineup[positions[i]].curgame_SB, t2_lineup[positions[i]].curgame_CS, t2_lineup[positions[i]].curgame_P_IP,
		t2_lineup[positions[i]].curgame_P_H, t2_lineup[positions[i]].curgame_P_ER, t2_lineup[positions[i]].curgame_P_HR, t2_lineup[positions[i]].curgame_P_BB,
		t2_lineup[positions[i]].curgame_P_SO, t2_lineup[positions[i]].curgame_pitchesThrown,t2_lineup[positions[i]].curgame_DRS,  
		t2_lineup[positions[i]].curgame_strikesThrown = 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;
		t2_lineup[positions[i]].curgame_pitchesLeft = gameSimulator:determineLongevity(t2_lineup[positions[i]].stamina, t2_lineup[positions[i]].posType);
		t2_lineup[positions[i]].curgame_gotWin, t2_lineup[positions[i]].curgame_gotLoss, t2_lineup[positions[i]].curgame_gotSave = 
			false, false, false
	end
	for i = 1, #t1_lineup.bullpen do
		t1_lineup.bullpen[i].curgame_AB, t1_lineup.bullpen[i].curgame_R, t1_lineup.bullpen[i].curgame_H, t1_lineup.bullpen[i].curgame_DOUBLES,
		t1_lineup.bullpen[i].curgame_TRIPLES, t1_lineup.bullpen[i].curgame_HR, t1_lineup.bullpen[i].curgame_RBI, t1_lineup.bullpen[i].curgame_BB,
		t1_lineup.bullpen[i].curgame_SO, t1_lineup.bullpen[i].curgame_SB, t1_lineup.bullpen[i].curgame_CS, t1_lineup.bullpen[i].curgame_P_IP,
		t1_lineup.bullpen[i].curgame_P_H, t1_lineup.bullpen[i].curgame_P_ER, t1_lineup.bullpen[i].curgame_P_HR, t1_lineup.bullpen[i].curgame_P_BB,
		t1_lineup.bullpen[i].curgame_P_SO, t1_lineup.bullpen[i].curgame_pitchesThrown, t1_lineup.bullpen[i].curgame_DRS,   
		t1_lineup.bullpen[i].curgame_strikesThrown = 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;
		t1_lineup.bullpen[i].curgame_pitchesLeft = gameSimulator:determineLongevity(t1_lineup.bullpen[i].stamina, t1_lineup.bullpen[i].posType);
		t1_lineup.bullpen[i].curgame_gotWin, t1_lineup.bullpen[i].curgame_gotLoss, t1_lineup.bullpen[i].curgame_gotSave = 
			false, false, false
	end
	for i = 1, #t2_lineup.bullpen do
		t2_lineup.bullpen[i].curgame_AB, t2_lineup.bullpen[i].curgame_R, t2_lineup.bullpen[i].curgame_H, t2_lineup.bullpen[i].curgame_DOUBLES,
		t2_lineup.bullpen[i].curgame_TRIPLES, t2_lineup.bullpen[i].curgame_HR, t2_lineup.bullpen[i].curgame_RBI, t2_lineup.bullpen[i].curgame_BB,
		t2_lineup.bullpen[i].curgame_SO, t2_lineup.bullpen[i].curgame_SB, t2_lineup.bullpen[i].curgame_CS, t2_lineup.bullpen[i].curgame_P_IP,
		t2_lineup.bullpen[i].curgame_P_H, t2_lineup.bullpen[i].curgame_P_ER, t2_lineup.bullpen[i].curgame_P_HR, t2_lineup.bullpen[i].curgame_P_BB,
		t2_lineup.bullpen[i].curgame_P_SO, t2_lineup.bullpen[i].curgame_pitchesThrown, t2_lineup.bullpen[i].curgame_DRS,
		t2_lineup.bullpen[i].curgame_strikesThrown = 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;
		t2_lineup.bullpen[i].curgame_pitchesLeft = gameSimulator:determineLongevity(t2_lineup.bullpen[i].stamina, t2_lineup.bullpen[i].posType);
		t2_lineup.bullpen[i].curgame_gotWin, t2_lineup.bullpen[i].curgame_gotLoss, t2_lineup.bullpen[i].curgame_gotSave = 
			false, false, false
	end
	for i = 1, #t1_lineup.bench do
		t1_lineup.bench[i].curgame_AB, t1_lineup.bench[i].curgame_R, t1_lineup.bench[i].curgame_H, t1_lineup.bench[i].curgame_DOUBLES,
		t1_lineup.bench[i].curgame_TRIPLES, t1_lineup.bench[i].curgame_HR, t1_lineup.bench[i].curgame_RBI, t1_lineup.bench[i].curgame_BB,
		t1_lineup.bench[i].curgame_SO, t1_lineup.bench[i].curgame_SB, t1_lineup.bench[i].curgame_CS, t1_lineup.bench[i].curgame_P_IP,
		t1_lineup.bench[i].curgame_P_H, t1_lineup.bench[i].curgame_P_ER, t1_lineup.bench[i].curgame_P_HR, t1_lineup.bench[i].curgame_P_BB,
		t1_lineup.bench[i].curgame_P_SO, t1_lineup.bench[i].curgame_pitchesThrown, t1_lineup.bench[i].curgame_DRS,
		t1_lineup.bench[i].curgame_strikesThrown, t1_lineup.bench[i].curgame_isPinchHitter
		= 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,true;
	end
	for i = 1, #t2_lineup.bench do
		t2_lineup.bench[i].curgame_AB, t2_lineup.bench[i].curgame_R, t2_lineup.bench[i].curgame_H, t2_lineup.bench[i].curgame_DOUBLES,
		t2_lineup.bench[i].curgame_TRIPLES, t2_lineup.bench[i].curgame_HR, t2_lineup.bench[i].curgame_RBI, t2_lineup.bench[i].curgame_BB,
		t2_lineup.bench[i].curgame_SO, t2_lineup.bench[i].curgame_SB, t2_lineup.bench[i].curgame_CS, t2_lineup.bench[i].curgame_P_IP,
		t2_lineup.bench[i].curgame_P_H, t2_lineup.bench[i].curgame_P_ER, t2_lineup.bench[i].curgame_P_HR, t2_lineup.bench[i].curgame_P_BB,
		t2_lineup.bench[i].curgame_P_SO, t2_lineup.bench[i].curgame_pitchesThrown, t2_lineup.bench[i].curgame_DRS,
		t2_lineup.bench[i].curgame_strikesThrown, t2_lineup.bench[i].curgame_isPinchHitter
		= 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,true;
	end
	
	
	gameSimulator.home_cur_pitcher = t2_lineup["sp"]
	gameSimulator.away_cur_pitcher = t1_lineup["sp"]
	 --Add pitcher to list of those who have pitched
	gameSimulator.home_pitchers_list[#gameSimulator.home_pitchers_list+1] = gameSimulator.home_cur_pitcher;
	gameSimulator.away_pitchers_list[#gameSimulator.away_pitchers_list+1] = gameSimulator.away_cur_pitcher;
	
	--Simulation loop 
	
	while (gameSimulator.gameIsOver == false) do
		local batter, pitcher;
		if (gameSimulator.portion == "top") then
			batter = gameSimulator.away_batter_lineup[gameSimulator.away_batter_index];
			pitcher = gameSimulator.home_cur_pitcher
		else
			batter = gameSimulator.home_batter_lineup[gameSimulator.home_batter_index];
			pitcher = gameSimulator.away_cur_pitcher
		end
		
		gameSimulator:simulateResult(
			gameSimulator:generateResult(
				gameSimulator:generateSwing(batter.contact, batter.power, batter.eye, batter.speed),
				gameSimulator:generatePitch(pitcher.velocity, pitcher.nastiness, pitcher.control), t1_lineup, t2_lineup
			), batter, pitcher, t1_lineup, t2_lineup
		)

		
	end
	
	--At the end of every game there is a small chance that there will be a injury to a player
	--This is to simulate realism
	gameSimulator:randomInjury(t1_lineup, t2_lineup);
	
	gameSimulator:recordData(t1_lineup, t2_lineup, t1_id, t2_id, gameid);
	
	
	--Debug simulation loop (Waits for a tap between each simulate result)
	--[[local function simulate()
		
		if (gameSimulator.gameIsOver == false) then
			local batter, pitcher;
			if (gameSimulator.portion == "top") then
				batter = gameSimulator.away_batter_lineup[gameSimulator.away_batter_index];
				pitcher = gameSimulator.home_cur_pitcher
			else
				batter = gameSimulator.home_batter_lineup[gameSimulator.home_batter_index];
				pitcher = gameSimulator.away_cur_pitcher
			end
			
			gameSimulator:simulateResult(
				gameSimulator:generateResult(
					gameSimulator:generateSwing(batter.contact, batter.power, batter.eye),
					gameSimulator:generatePitch(pitcher.velocity, pitcher.nastiness, pitcher.control)
				), batter, pitcher, t1_lineup, t2_lineup
			)
			--timer.performWithDelay(3000, simulate)
		else
			gameSimulator:recordData(t1_lineup, t2_lineup, t1_id, t2_id, gameid)
		end

		
	end
	
	Runtime:addEventListener("tap", simulate);]]--
	
	return 0, 0 --Not used anymore

end

function gameSimulator:generatePitch(velocity, nastiness, control)
	
	local isStrike = false;
	local speed = 0;
	local pitch_nastiness = 0;
	local pitch_location = 0; --Higher = Better
	
	 --Control = 30, Strike 52% of the time, Control = 100 Strike 67% of the time
	local percentage = (3/14)*control + (638/14);
	percentage = percentage - 1 --Increase walk rate
	if (percentage >= math.random(1,100)) then
		isStrike = true;
	end
	
	--Velocity = 30, Avg Fastball around 75, Velocity = 100, Avg Fastball around 100
	speed = (5/14) * velocity + (900/14)
	local variance = math.random(-5,5);
	speed = math.floor(speed + variance);
	
	--Nastiness = 30, Nasty 10% of the time; Nastiness = 100 Nasty 30% of the time
	local percentage = (2/7)*nastiness + (10/7);
	if (percentage >= math.random(1,100)) then
		--Nasty Pitch
		pitch_nastiness = math.random(45,100);
	else
		--Not Nasty Pitch
		pitch_nastiness = math.random(10,40);
	end
	
	--Control = 30, Good location 20% of the time; Control = 100, Good location 80% of the time
	local percentage = (6/7)*control - (40/7)
	if (percentage >= math.random(1,100)) then
		--Good control
		pitch_location = math.random(50,100);
	else
		--Bad Control
		pitch_location = math.random(10,40);
	end
	
	return {isStrike = isStrike, speed = speed, nastiness = pitch_nastiness, location = pitch_location}
	
end

function gameSimulator:generateSwing(contact, power, eye, speed)

	local squareup = 0;
	local swing_power = 0;
	local patience = 0; --Lower patience means more swings and misses, swing @ balls, and taking strikes
	local runnerSpeed = 0
	
	--Contact = 30, good squareup = 19%,   Contact = 100, good squareup = 28%
	
	--Quadratic regression
	--y = .001x^2-.019x+18.1
	local percentage = .001*contact^2-.019*contact+18.3--(1/7)*contact + (96/7)
	if (percentage >= math.random(1,100)) then
		--Good Squareup
		squareup = math.random(40,100);
	else
		--Bad Squareup
		squareup = math.random(0,30);
	end
	
	--Patience = Quadratic Regression
	--eye = 30 good patience 40% of the time eye = 100 good patience 100% of time
	local percentage = .00638*eye^2+.27*eye+10.4
	if (percentage >= math.random(1,100)) then
		--Good patience
		patience = math.random(60,100);
	else
		--Bad Patience
		patience = math.random(0,50);
	end
	
	--Power = 30, Powerful 2% of the time; Power = 100 Powerful 27% of the time
	
	--Used exponentialRegression function on calculator, got y = .69*1.038^X
	--Where y = chance of being powerful, x = power
	local percentage = (.69)*math.pow(1.038,power);
	if (percentage >= math.random(1,100)) then
		--Powerful
		swing_power = math.random(30,70);
	else
		--Not Powerful
		swing_power = math.random(0,35);
	end
	
	--Speed = 30, Fast 20% of the time; Speed = 100, Fast 90% of the time
	local percentage = speed - 10;
	if (percentage >= math.random(1,100)) then
		--Fast
		runnerSpeed = math.random(50,100);
	else
		--Not Fast
		runnerSpeed = math.random(0,30);
	end
	
	return {squareup = squareup, power = swing_power, patience = patience, speed = runnerSpeed}
	

end

function gameSimulator:generateResult(swing, pitch, t1_lineup, t2_lineup)
	--swing - squareup, power, patience
	--pitch - isStrike, speed, nastiness
	local squareup, power, patience, runnerSpeed, isStrike, pitchSpeed, nastiness, location = 
	swing.squareup, swing.power, swing.patience, swing.speed, pitch.isStrike, pitch.speed, pitch.nastiness, pitch.location
	local result = "none"
	
	--Result Simulator 2.0
	if (pitch.isStrike) then
		--Pitch is strike
		
		--The faster the pitch, the harder it is to square up the pitch
		--70 mph, squareup coefficient = 1.15, 105 mph coefficient = .85
		--Higher squareup coefficient = better squareup
		local coeff = (-.3/35) * pitchSpeed + 1.75
		
		--The better the location of the pitch, the harder it is to hit
		--0 location, coeff2 = 1.2, 100 location coeff2 = .8
		--Higher coeff2 = better squareup
		local coeff2 = (-.4/100) * location + 1.2
		
		 --Factor the location, speed, and nastiness of the pitch into how well the batter can squareup
		squareup = squareup * coeff * coeff2
		local  swingQuality = squareup - nastiness
		
		if (swingQuality <= -6) then --Terrible Swing
			local num = math.random(1,100);
			if (num <= 38) then
				--38% chance for a strike
				result = "strike"
			else
				--62% chance for a foul
				result = "foul"
			end
		elseif (swingQuality <= 33) then --Subpar Swing
			if (power < 25) then
				local num = math.random(1,100);
				if (num <= 35) then
				result = "foul";
				elseif (num <= 70) then
				result = "weak grounder"; --Potential double play
				elseif (num <= 100) then
					if( runnerSpeed > 90) then
						result = "single"; --Runner so fast, that he beat out the throw
					else
						result = "grounder"; -- out
					end
				end
			elseif (power < 40) then
				result = "flyout" -- out
			else
				result = "long flyout"
			end
		else --Good Swing
			if (power < 26) then --Orig = 30
				if (runnerSpeed > 95) then
					result = "double"
				else
					result = "single"
				end
			elseif (power < 35) then --Orig = 39
				if (runnerSpeed > 90) then
					result = "triple"
				else
					result = "double"
				end
			else
				result = "home run"
			end
		
		end
		
	
	else
		--Pitch is ball
		
		--50 Patience = 80% chance of taking ball, 100 Patience = 100% chance of taking ball
		local percentage = (20/50)*patience + 60
		
		--0 Nastiness = +0 percent chance of taking ball, 100 nastiness = -10% chance of taking ball
		local delta = (-1/10)*nastiness
		percentage = percentage+delta
		
		if (percentage >= math.random(1,100)) then
			--Takes the ball
			result = "ball";
		else
			--Still swings even though it's a ball
			result = "strike"
			
		
		end
		
	
	end
	
	
	return gameSimulator:defense(result, t1_lineup, t2_lineup);

end

function gameSimulator:simulateResult(result, batter, pitcher, t1_lineup, t2_lineup)
	
	--[[local lineup = "Lineup: "
	if (gameSimulator.portion == "top") then
	for i = 1, #gameSimulator.away_batter_lineup do
		lineup = lineup .. gameSimulator.away_batter_lineup[i].name .. ", "
	end
	else
	for i = 1, #gameSimulator.home_batter_lineup do
		lineup = lineup .. gameSimulator.home_batter_lineup[i].name .. ", "
	end
	end
	print(lineup);]]--
	--print(gameSimulator.portion .. " " .. gameSimulator.inning .. "  (" .. gameSimulator.num_outs .. " outs) - " ..
	--	"Batter: " .. batter.name .. "( " .. batter.batting_order .. ")" .. "   Pitcher: " .. pitcher.name);	
	
	--print("Batter AB: " .. batter.curgame_name .. "  - " .. batter.curgame_id);
	local run_scored = {}; --Number of runs scored in the play (table of all players who scored)
							--Will only be added if there are less than 3 outs after play
	local num_outs_recorded = 0; --Number of outs recorded in the play
	local ballThrown = false;
	local canStealBase = false; --Can steal base if result == strike or ball (but not walk)
	local nextBatter = false; --Flag to see if next batter should be called up, usually after an out
	
	--If the batter scores, the earn run is charged to the pitcher who pitched to him
	batter.curgame_pitcherResponsible = pitcher
	
	--Record number of pitches pitcher has thrown
	pitcher.curgame_pitchesThrown = pitcher.curgame_pitchesThrown + 1;
	
	
	if (result == "strike") then --print("Strike");
		gameSimulator.strikes = gameSimulator.strikes + 1
		if (gameSimulator.strikes == 3) then --Strikeout
			
			--Record stats
			batter.curgame_AB = batter.curgame_AB + 1;
			batter.curgame_SO = batter.curgame_SO + 1
			pitcher.curgame_P_SO = pitcher.curgame_P_SO+1
			
			--************
			
			num_outs_recorded = num_outs_recorded + 1
			nextBatter = true
		end
		canStealBase = true;
	elseif (result == "ball") then --print("Ball");
		ballThrown = true;
		gameSimulator.balls = gameSimulator.balls+1
		if (gameSimulator.balls == 4) then --Walk
		
			--Record stats
			batter.curgame_BB = batter.curgame_BB + 1
			pitcher.curgame_P_BB = pitcher.curgame_P_BB+1
			
			--************
			if (gameSimulator.diamond.first ~= nil) then
				if (gameSimulator.diamond.second ~= nil) then
					if (gameSimulator.diamond.third ~= nil) then
						run_scored[#run_scored+1] = gameSimulator.diamond.third
					end
					gameSimulator.diamond.third = gameSimulator.diamond.second
				end
				gameSimulator.diamond.second = gameSimulator.diamond.first
			end
			gameSimulator.diamond.first = batter
			
			nextBatter = true
		else
			canStealBase = true --Can't steal base off a walk
								--Actually you can, but only the runner at second can steal
								--Logic too hard to implement
		end
		
	elseif (result == "foul") then --print("Foul");
		gameSimulator.strikes = gameSimulator.strikes + 1
		if (gameSimulator.strikes >= 3) then
			gameSimulator.strikes = 2
		end
	elseif (result == "single") then --print("Single");
		if (gameSimulator.diamond.third ~= nil) then
			run_scored[#run_scored+1] = gameSimulator.diamond.third
		end
		gameSimulator.diamond = {first = batter, second = gameSimulator.diamond.first, 
			third = gameSimulator.diamond.second}
		
		--Record stats
		batter.curgame_AB = batter.curgame_AB + 1;
		batter.curgame_H = batter.curgame_H + 1
		pitcher.curgame_P_H = pitcher.curgame_P_H + 1
		--************
		
		nextBatter = true
	elseif (result == "double") then --print("double");
		if (gameSimulator.diamond.third ~= nil) then
			run_scored[#run_scored+1] = gameSimulator.diamond.third
		end
		if (gameSimulator.diamond.second ~= nil) then
			run_scored[#run_scored+1] = gameSimulator.diamond.second
		end
		gameSimulator.diamond = {first = nil, second = batter, third = gameSimulator.diamond.first}
		
		--Record stats
		batter.curgame_AB = batter.curgame_AB + 1;
		batter.curgame_H = batter.curgame_H + 1
		pitcher.curgame_P_H = pitcher.curgame_P_H + 1
		batter.curgame_DOUBLES = batter.curgame_DOUBLES + 1
		--************
		
		nextBatter = true
	elseif (result == "triple") then --print("triple");
		if (gameSimulator.diamond.third ~= nil) then
			run_scored[#run_scored+1] = gameSimulator.diamond.third
		end
		if (gameSimulator.diamond.second ~= nil) then
			run_scored[#run_scored+1] = gameSimulator.diamond.second
		end
		if (gameSimulator.diamond.first ~= nil) then
			run_scored[#run_scored+1] = gameSimulator.diamond.first
		end
		gameSimulator.diamond = {first = nil, second = nil, third = batter}
		
		--Record stats
		batter.curgame_AB = batter.curgame_AB + 1;
		batter.curgame_H = batter.curgame_H + 1
		pitcher.curgame_P_H = pitcher.curgame_P_H + 1
		batter.curgame_TRIPLES = batter.curgame_TRIPLES + 1
		--************
		
		nextBatter = true
	elseif (result == "home run") then --print("home run");
		run_scored[#run_scored+1] = batter
		if (gameSimulator.diamond.third ~= nil) then
			run_scored[#run_scored+1] = gameSimulator.diamond.third
		end
		if (gameSimulator.diamond.second ~= nil) then
			run_scored[#run_scored+1] = gameSimulator.diamond.second
		end
		if (gameSimulator.diamond.first ~= nil) then
			run_scored[#run_scored+1] = gameSimulator.diamond.first
		end
		gameSimulator.diamond = {first = nil, second = nil, third = nil}
		
		--Record stats
		batter.curgame_AB = batter.curgame_AB + 1;
		batter.curgame_H = batter.curgame_H + 1
		pitcher.curgame_P_H = pitcher.curgame_P_H + 1
		pitcher.curgame_P_HR = pitcher.curgame_P_HR + 1
		batter.curgame_HR = batter.curgame_HR + 1
		--************
		
		nextBatter = true
	elseif (result == "grounder") then --print("grounder");
		num_outs_recorded = num_outs_recorded + 1
		if (gameSimulator.diamond.third ~= nil) then
			run_scored[#run_scored+1] = gameSimulator.diamond.third
		end
		gameSimulator.diamond = {first = nil, second = gameSimulator.diamond.first, 
		third = gameSimulator.diamond.second}
		
		--Record stats
		batter.curgame_AB = batter.curgame_AB + 1;
		
		--************
		
		nextBatter = true
	elseif (result == "weak grounder") then --print("weak grounder");
		num_outs_recorded = num_outs_recorded + 1
		
		
		
		if (gameSimulator.diamond.third ~= nil) then
			run_scored[#run_scored+1] = gameSimulator.diamond.third
		end
		if (gameSimulator.diamond.first ~= nil) then
			num_outs_recorded = num_outs_recorded + 1
		end
		
		--Record stats
		batter.curgame_AB = batter.curgame_AB + 1;
		
		--************
		
		gameSimulator.diamond = {first = nil, second = nil, third = gameSimulator.diamond.second}
		nextBatter = true
	elseif (result == "flyout") then --print("flyout");
		num_outs_recorded = num_outs_recorded + 1
		
		--Record stats
		batter.curgame_AB = batter.curgame_AB + 1;
		
		--************
		
		nextBatter = true
		
		
	elseif (result == "long flyout") then --print("long flyout");
		num_outs_recorded = num_outs_recorded + 1
		if (gameSimulator.diamond.third ~= nil) then
			run_scored[#run_scored+1] = gameSimulator.diamond.third
		end
		gameSimulator.diamond = {first = gameSimulator.diamond.first, second = gameSimulator.diamond.second, third = nil}
		
		--Record stats
		batter.curgame_AB = batter.curgame_AB + 1;
		
		--************
		
		nextBatter = true
	
		
	
	end
	
	
	
	if (not ballThrown) then
		pitcher.curgame_strikesThrown = pitcher.curgame_strikesThrown + 1;
		--If it wasnt a ball, it was a strike, even foul balls, hits, and outs count as strikes as well as regular strikes
	end
	
	
	local max_num_outs = 3 - gameSimulator.num_outs;
	--For example if there are already two outs in an inning, only one more out can be recorded
	--So even double plays register only one out, although they usually count for 2
	if (num_outs_recorded > max_num_outs) then num_outs_recorded = max_num_outs end
	gameSimulator.num_outs = gameSimulator.num_outs + num_outs_recorded;
	if (num_outs_recorded >= 1) then
	gameSimulator:pitcherGotOut(pitcher, num_outs_recorded); end
	
	if (nextBatter) then
		--Switch pitcher out if he is too tired
		if (pitcher.curgame_pitchesThrown >= pitcher.curgame_pitchesLeft) then
			gameSimulator:switchPitcher(t1_lineup, t2_lineup);
		end
		
		--Move onto the next batter
		gameSimulator:nextBatter();
		
		--Change batter to a pinch hitter
		--For now, it happens randomly (just to test the capability)
		--In the future, update when to switch to pinch hitter logic
		if ((gameSimulator.inning >= 7) and (2 >= math.random(1,100))) then
			gameSimulator:switchBatter(t1_lineup, t2_lineup);
		end
		
		
	end
	
	
	if (gameSimulator.num_outs < 3) then
		gameSimulator:addScore(#run_scored);
		
		--Record Stats
		for i = 1, #run_scored do 
			local runner = run_scored[i]
			runner.curgame_R = runner.curgame_R + 1
			
			local pitcher = runner.curgame_pitcherResponsible --Pitcher responsible for the runner scoring
			pitcher.curgame_P_ER = pitcher.curgame_P_ER + 1
		end
		--pitcher.curgame_P_ER = pitcher.curgame_P_ER + #run_scored
		batter.curgame_RBI = batter.curgame_RBI + #run_scored
		--*******************
		
		
		--Determine if anyone steals a base
		if (canStealBase) then
		
			--Someone @ 2nd nobody @ 3rd
			if (gameSimulator.diamond.second ~= nil and gameSimulator.diamond.third == nil) then
				if (gameSimulator:decideSteal(gameSimulator.diamond.second, true)) then
					if (gameSimulator:stealBase(gameSimulator.diamond.second, true, t1_lineup, t2_lineup)) then
						--Second stole third
						gameSimulator.diamond.third = gameSimulator.diamond.second;
						gameSimulator.diamond.second = nil
						if (gameSimulator.diamond.first ~= nil) then
							gameSimulator.diamond.second = gameSimulator.diamond.first;
							gameSimulator.diamond.second.curgame_SB = gameSimulator.diamond.second.curgame_SB + 1; 
						end
						gameSimulator.diamond.third.curgame_SB = gameSimulator.diamond.third.curgame_SB + 1;
						
					else
						--Second caught stealing
						gameSimulator:pitcherGotOut(pitcher, 1)
						gameSimulator.num_outs = gameSimulator.num_outs + 1;
						gameSimulator.diamond.second.curgame_CS = gameSimulator.diamond.second.curgame_CS + 1; 
						gameSimulator.diamond.second = nil;
						
						--Runner at first still advances to second
						if (gameSimulator.diamond.first ~= nil) then
							--This doesn't count as a stolen base because the other runner was caught stealing
							gameSimulator.diamond.second = gameSimulator.diamond.first;
						end
						
						
					end
				end
			--Somebody @ first nobody @ second
			elseif (gameSimulator.diamond.first ~= nil and gameSimulator.diamond.second == nil) then
				if (gameSimulator:decideSteal(gameSimulator.diamond.first, false)) then
					if (gameSimulator:stealBase(gameSimulator.diamond.first, false, t1_lineup, t2_lineup)) then
						--First stole second
						gameSimulator.diamond.second = gameSimulator.diamond.first;
						gameSimulator.diamond.first = nil;
						gameSimulator.diamond.second.curgame_SB = gameSimulator.diamond.second.curgame_SB + 1; 
						
					else
						--First caught stealing
						gameSimulator:pitcherGotOut(pitcher, 1)
						gameSimulator.num_outs = gameSimulator.num_outs + 1
						gameSimulator.diamond.first.curgame_CS = gameSimulator.diamond.first.curgame_CS + 1; 
						gameSimulator.diamond.first = nil;
						
					end
				end
			end
			
			
		end
		
		--If someone caught stealing results in 3 outs, then move onto the next inning
		if (gameSimulator.num_outs >= 3) then
			gameSimulator:nextInning();
		end
		
	else
		gameSimulator:nextInning();
		
		--Bring out the closer if it's a save situation and closer hasn't pitched
		--This code is put after gameSimulator:nextInning() because closers are usually brought 
		--up at the start of an inning in the majors
		if (gameSimulator:isSaveSituation() and gameSimulator:isCloserAvailable(t1_lineup, t2_lineup)) then
			gameSimulator:switchPitcher(t1_lineup, t2_lineup);
		end
	end
end

--Defense influences the outcome of a ball put in play (ie. groundball might become single, homerun can be robbed)
function gameSimulator:defense(result, t1_lineup, t2_lineup)
	--Defense influences result of ball in play
	
	if (result == "ball" or result == "strike" or result == "foul") then
		--Defense can't change balls or strikes
		return result
	end
	
	local function getPlayer(position)
		if (gameSimulator.portion == "top") then
			--Home defending
			if (position == "pitcher") then return gameSimulator.home_cur_pitcher end
			return t2_lineup[position]
		else 
			--Away defending
			if (position == "pitcher") then return gameSimulator.away_cur_pitcher end
			return t1_lineup[position]
		end

	end
	
	local function outcome(player, difficulty)
		--Difficulty (1-10) indicates how hard it is to make a good play on the ball. 
		--For example, it is easier to rob a single than it is to rob a home run
		
		local defense = player.defense
		
		--0 defense = 0% chance making good play  -- 100 defense = 5% chance making good play (Quadratic)
		--local percentage = .000458*defense^2+.005*defense-.045
		--percentage = percentage * 4; -- Let's make 100 defense = 20% chance making good play (Quadratic)
		
		--0 defense = 0% chance making good play  -- 100 defense = 22% chance making good play (Linear)
		local percentage = (.22)*defense
		
		if (percentage*10 >= math.random(1,1000)) then
			if (math.random(1,10) >= difficulty) then
				return "Good"
			end
		end
		
		
		--0 defense = 94% neutral fielding   --100 defense = 99.5% neutral fielding (Linear)
		local percentage = (11/200)*defense + 94
		if (percentage*10 >= math.random(1,1000)) then
			return "Neutral"
		else
			return "Bad"
		end
	end
	
	if (result == "weak grounder") then
		local num = math.random(1,100);
		local difficulty = 2;
		local posType = "first"
		
		if (num <= 10) then
			posType = "first"
		elseif (num <= 25) then
			posType = "second"
		elseif (num <= 50) then
			posType = "short"
		elseif (num <= 65) then
			posType = "third"
		elseif (num <= 85) then
			posType = "catcher"
		elseif (num <= 85) then
			posType = "left"
		elseif (num <= 85) then
			posType = "right"
		elseif (num <= 85) then
			posType = "center"
		else
			posType = "pitcher"
		end
		
		local player = getPlayer(posType)
		local outcome = outcome(player, difficulty)
		
		if (outcome == "Bad") then
			result = "single"
			player.curgame_DRS = player.curgame_DRS - .4
		elseif (outcome == "Neutral") then
			--Result stays the same
		elseif (outcome == "Good") then
			result = "weak grounder"
			--player.curgame_DRS = player.curgame_DRS + .1
		end
		
		
	elseif (result == "grounder") then
	
		local num = math.random(1,100);
		local difficulty = 2;
		local posType = "first"
		
		if (num <= 15) then
			posType = "first"
		elseif (num <= 30) then
			posType = "second"
		elseif (num <= 48) then
			posType = "short"
		elseif (num <= 65) then
			posType = "third"
		elseif (num <= 67) then
			posType = "catcher"
		elseif (num <= 76) then
			posType = "left"
		elseif (num <= 85) then
			posType = "right"
		elseif (num <= 94) then
			posType = "center"
		else
			posType = "pitcher"
		end
		
		local player = getPlayer(posType)
		local outcome = outcome(player, difficulty)
		
		if (outcome == "Bad") then
			result = "single"
			player.curgame_DRS = player.curgame_DRS - .25
		elseif (outcome == "Neutral") then
			--Result stays the same
		elseif (outcome == "Good") then
			result = "weak grounder"
			player.curgame_DRS = player.curgame_DRS + .1
		end

	elseif (result == "single") then
	
		local num = math.random(1,100);
		local difficulty = 4;
		local posType = "first"
		
		if (num <= 15) then
			posType = "first"
		elseif (num <= 30) then
			posType = "second"
		elseif (num <= 48) then
			posType = "short"
		elseif (num <= 65) then
			posType = "third"
		elseif (num <= 67) then
			posType = "catcher"
		elseif (num <= 76) then
			posType = "left"
		elseif (num <= 85) then
			posType = "right"
		elseif (num <= 94) then
			posType = "center"
		else
			posType = "pitcher"
		end
		
		local player = getPlayer(posType)
		local outcome = outcome(player, difficulty)
		
		if (outcome == "Bad") then
			result = "double"
			player.curgame_DRS = player.curgame_DRS - .5
		elseif (outcome == "Neutral") then
			--Result stays the same
		elseif (outcome == "Good") then
			result = "grounder"
			player.curgame_DRS = player.curgame_DRS + .25
		end
	
	elseif (result == "double") then
	
		local num = math.random(1,100);
		local difficulty = 6;
		local posType = "first"
		
		if (num <= 7) then
			posType = "first"
		elseif (num <= 9) then
			posType = "second"
		elseif (num <= 12) then
			posType = "short"
		elseif (num <= 19) then
			posType = "third"
		elseif (num <= 19) then
			posType = "catcher"
		elseif (num <= 45) then
			posType = "left"
		elseif (num <= 71) then
			posType = "right"
		elseif (num <= 100) then
			posType = "center"
		else
			posType = "pitcher"
		end
		
		local player = getPlayer(posType)
		local outcome = outcome(player, difficulty)
		
		if (outcome == "Bad") then
			result = "triple"
			player.curgame_DRS = player.curgame_DRS - .5
		elseif (outcome == "Neutral") then
			--Result stays the same
		elseif (outcome == "Good") then
			result = "flyout"
			player.curgame_DRS = player.curgame_DRS + .5
		end
	
	elseif (result == "triple") then
	
		local num = math.random(1,100);
		local difficulty = 7;
		local posType = "first"
		
		if (num <= 5) then
			posType = "first"
		elseif (num <= 6) then
			posType = "second"
		elseif (num <= 7) then
			posType = "short"
		elseif (num <= 12) then
			posType = "third"
		elseif (num <= 12) then
			posType = "catcher"
		elseif (num <= 41) then
			posType = "left"
		elseif (num <= 70) then
			posType = "right"
		elseif (num <= 100) then
			posType = "center"
		else
			posType = "pitcher"
		end
		
		local player = getPlayer(posType)
		local outcome = outcome(player, difficulty)
		
		if (outcome == "Bad") then
			result = "homerun"
			player.curgame_DRS = player.curgame_DRS - 1.5
		elseif (outcome == "Neutral") then
			--Result stays the same
		elseif (outcome == "Good") then
			result = "long flyout"
			player.curgame_DRS = player.curgame_DRS + .75
		end
	
	elseif (result == "homerun") then
		local num = math.random(1,100);
		local difficulty = 9;
		local posType = "first"
		
		if (num <= 0) then
			posType = "first"
		elseif (num <= 0) then
			posType = "second"
		elseif (num <= 0) then
			posType = "short"
		elseif (num <= 0) then
			posType = "third"
		elseif (num <= 0) then
			posType = "catcher"
		elseif (num <= 33) then
			posType = "left"
		elseif (num <= 67) then
			posType = "right"
		elseif (num <= 100) then
			posType = "center"
		else
			posType = "pitcher"
		end
		
		local player = getPlayer(posType)
		local outcome = outcome(player, difficulty)
		
		if (outcome == "Bad") then
			result = "homerun"
			--player.curgame_DRS = player.curgame_DRS - 1.5
		elseif (outcome == "Neutral") then
			--Result stays the same
		elseif (outcome == "Good") then
			result = "long flyout"
			player.curgame_DRS = player.curgame_DRS + 1.5
		end
	
	elseif (result == "flyout") then
		local num = math.random(1,100);
		local difficulty = 5;
		local posType = "first"
		
		if (num <= 4) then
			posType = "first"
		elseif (num <= 12) then
			posType = "second"
		elseif (num <= 20) then
			posType = "short"
		elseif (num <= 25) then
			posType = "third"
		elseif (num <= 25) then
			posType = "catcher"
		elseif (num <= 50) then
			posType = "left"
		elseif (num <= 75) then
			posType = "right"
		elseif (num <= 100) then
			posType = "center"
		else
			posType = "pitcher"
		end
		
		local player = getPlayer(posType)
		local outcome = outcome(player, difficulty)
		
		if (outcome == "Bad") then
			result = "single"
			player.curgame_DRS = player.curgame_DRS - .25
		elseif (outcome == "Neutral") then
			--Result stays the same
		elseif (outcome == "Good") then
			result = "flyout"
			--player.curgame_DRS = player.curgame_DRS + .1
		end
	elseif (result == "long flyout") then
		local num = math.random(1,100);
		local difficulty = 5;
		local posType = "first"
		
		if (num <= 0) then
			posType = "first"
		elseif (num <= 0) then
			posType = "second"
		elseif (num <= 0) then
			posType = "short"
		elseif (num <= 0) then
			posType = "third"
		elseif (num <= 0) then
			posType = "catcher"
		elseif (num <= 33) then
			posType = "left"
		elseif (num <= 67) then
			posType = "right"
		elseif (num <= 100) then
			posType = "center"
		else
			posType = "pitcher"
		end
		
		local player = getPlayer(posType)
		local outcome = outcome(player, difficulty)
		
		if (outcome == "Bad") then
			result = "double"
			player.curgame_DRS = player.curgame_DRS - .5
		elseif (outcome == "Neutral") then
			--Result stays the same
		elseif (outcome == "Good") then
			result = "flyout"
			player.curgame_DRS = player.curgame_DRS + .1
		end
	
	end
	
	return result --Return result as influenced by defense
end

--Determine the number of pitches a pitcher can make before he is tired
function gameSimulator:determineLongevity(stamina, pitcherType)
	
	local pitches
	if (pitcherType == "SP") then
		--Starting Pitcher
		--0 stamina = 80 pitches, --100 stamina = 120 pitches
		pitches = (2/5)*stamina + 80
	else
		--Relief Pitcher
		--0 stamina = 15 pitches, --100 stamina = 40 pitches
		pitches = (1/4)*stamina + 15
		
	end

	return pitches
	
end

--Returns true if runner decides to steal
function gameSimulator:decideSteal(runner, atSecond)
	
	--  30 speed = -10% steal 100 speed = 10% steal
	local percentage = (2/7)*runner.speed - (130/7)
	
	--If the runner is atSecond, less likely to steal
	if (atSecond) then percentage = percentage * .5; end
	
	if (percentage >= math.random(1,100)) then
		return true
	end
	
	return false
	
end

--Returns true if base is stolen
function gameSimulator:stealBase(runner, atSecond , t1_lineup, t2_lineup)

	local catcher;
	
	if (gameSimulator.portion == "top") then
		catcher = t2_lineup["catcher"]
	else
		catcher = t1_lineup["catcher"]
	end
	
	--30 speed = 20% chance, 100 speed = 90% chance
	local percentage = (1/1) * runner.speed - 10
	
	--Catcher 0 defense = +5%, 100 defense = -20%
	percentage = percentage + (-.25) * catcher.defense + 5
	
	if (atSecond) then percentage = percentage * .75; end
	
	if (percentage >= math.random(1,100)) then
		catcher.curgame_DRS = catcher.curgame_DRS - .15
		return true
	end
	
	catcher.curgame_DRS = catcher.curgame_DRS + .4
	return false
end


function gameSimulator:nextBatter()
	--print("Next Batter");
	gameSimulator.balls = 0
	gameSimulator.strikes = 0
	
	if (gameSimulator.portion == "top") then
		gameSimulator.away_batter_index = gameSimulator.away_batter_index + 1;
		if (gameSimulator.away_batter_index > 9) then gameSimulator.away_batter_index = 1 end
	else
		gameSimulator.home_batter_index = gameSimulator.home_batter_index + 1;
		if (gameSimulator.home_batter_index > 9) then gameSimulator.home_batter_index = 1 end
	end
end

function gameSimulator:nextInning() --Not really next inning goes from top to bottom and then next
	gameSimulator.num_outs = 0;
	gameSimulator.diamond = {first = nil, second = nil, third = nil}
	if (gameSimulator.portion == "top") then
		gameSimulator.portion = "bottom"
		
		if (gameSimulator.inning >= 9 and gameSimulator.home_score > gameSimulator.away_score) then
			gameSimulator.gameIsOver = true;
			gameSimulator.boxscore[gameSimulator.inning].bottom = "X" --Didn't play the inning, show x instead of 0
		end
		
	else
		gameSimulator.portion = "top"
		gameSimulator.inning = gameSimulator.inning + 1
		
		if (gameSimulator.inning > 9 and gameSimulator.home_score ~= gameSimulator.away_score) then
			gameSimulator.gameIsOver = true;
		else
			--Game is not over, continue
			--Add new inning to the boxscore
			--This boxscore will eventually be recorded into the games table in the database
			gameSimulator.boxscore[#gameSimulator.boxscore+1] = {top = 0, bottom = 0};
		end
		
		
	end
end

function gameSimulator:addScore(num)
	if (gameSimulator.portion == "top") then
		gameSimulator.away_score = gameSimulator.away_score + num
		gameSimulator.boxscore[gameSimulator.inning].top = gameSimulator.boxscore[gameSimulator.inning].top+num
	else
		gameSimulator.home_score = gameSimulator.home_score + num
		gameSimulator.boxscore[gameSimulator.inning].bottom = gameSimulator.boxscore[gameSimulator.inning].bottom+num
	end

end

function gameSimulator:pitcherGotOut(pitcher, numOuts)
	
	--Register out to pitcher by increasing innings pitched by .1
	for i = 1, numOuts do
	local pitcher_ip = pitcher.curgame_P_IP; 
	local num = math.floor(pitcher_ip);
	local num2 = pitcher_ip - num;	

	if (math.abs(num2  - .2) < .005) then --.005 epsilon (error) chosen to allow for floating point miscalculations
		pitcher.curgame_P_IP = math.ceil(pitcher.curgame_P_IP);
	else
		pitcher.curgame_P_IP = pitcher.curgame_P_IP + .1;
	end
	end

end

function gameSimulator:isSaveSituation()
	--Determines whether game is in save situation
	if (gameSimulator.inning >= 9) then
		local home, away = gameSimulator.home_score, gameSimulator.away_score
		if (gameSimulator.portion == "top" and (home - away) > 0  and (home - away) <= 3) then return true end
		if (gameSimulator.portion == "bottom" and (away - home) > 0  and (away-home) <= 3) then return true end
	end
	return false

end

function gameSimulator:isCloserAvailable(t1_lineup, t2_lineup)
	
	if (gameSimulator.portion == "top") then
		--Check to see if home closer is available
		
		--Only available if pitch count = 0
		return (t2_lineup.closer.curgame_pitchesThrown == 0)
	else
		--Check to see if away closer is available
		
		--Only available if pitch count = 0
		return (t1_lineup.closer.curgame_pitchesThrown == 0)
	
	end

end

function gameSimulator:switchPitcher(t1_lineup, t2_lineup)
	
	if (gameSimulator.portion == "top") then
		--Home team switches pitching
		local pitchers = {} --List of pitching options, first in the list == higher priority
			
		--Sort bullpen by days rest (high to low)
		--If days_rest are equal sort by overall rating (high to low)
		local sortedBullpen = {} 
		for i = 1, #t2_lineup.bullpen do
			sortedBullpen[#sortedBullpen+1] = t2_lineup.bullpen[i];
		end
	
		local function sortBullpen(a,b)  
			
			if (a.days_rest == b.days_rest) then
				return a.overall > b.overall
			else
				return a.days_rest > b.days_rest
			end
		end
		table.sort(sortedBullpen, sortBullpen)
		
		--Add sorted bullpen to pitchers
		for i = 1, #sortedBullpen do
			pitchers[#pitchers+1] = sortedBullpen[i]
		end
		
		if (gameSimulator:isSaveSituation()) then
			table.insert(pitchers,1,t2_lineup.closer) --Closer has top priority
		else
			table.insert(pitchers,t2_lineup.closer) --Closer has least priority
		end
		
		
		for i = 1, #pitchers do
			if (pitchers[i].curgame_pitchesThrown == 0) then
				gameSimulator.home_cur_pitcher = pitchers[i];
				 --Add pitcher to list of those who have pitched
				gameSimulator.home_pitchers_list[#gameSimulator.home_pitchers_list+1] = gameSimulator.home_cur_pitcher;
				break;
			end
			--If all the pitchers have pitched, then the reliever still has to pitch on :(
		end
	
	else
		--Away team switches pitching
		local pitchers = {} --List of pitching options, first in the list == higher priority
			
		--Sort bullpen by days rest (high to low)
		--If days_rest are equal sort by overall rating (high to low)
		local sortedBullpen = {} 
		for i = 1, #t1_lineup.bullpen do
			sortedBullpen[#sortedBullpen+1] = t1_lineup.bullpen[i];
		end
	
		local function sortBullpen(a,b)  
			
			if (a.days_rest == b.days_rest) then
				return a.overall > b.overall
			else
				return a.days_rest > b.days_rest
			end
		end
		table.sort(sortedBullpen, sortBullpen)
		
		--Add sorted bullpen to pitchers
		for i = 1, #sortedBullpen do
			pitchers[#pitchers+1] = sortedBullpen[i]
		end
		
		
		if (gameSimulator:isSaveSituation()) then
			table.insert(pitchers,1,t1_lineup.closer) --Closer has top priority
		else
			table.insert(pitchers,t1_lineup.closer) --Closer has least priority
		end
		
		
		
		for i = 1, #pitchers do
			if (pitchers[i].curgame_pitchesThrown == 0) then
				gameSimulator.away_cur_pitcher = pitchers[i];
				--Add pitcher to list of those who have pitched
				gameSimulator.away_pitchers_list[#gameSimulator.away_pitchers_list+1] = gameSimulator.away_cur_pitcher;
				break;
			end
		end
	
	end


end

function gameSimulator:switchBatter(t1_lineup, t2_lineup)

	if (gameSimulator.portion == "top") then
		--Away team switches batting
		local batters = {} --List of available pinch hitters
		for i = 1, #t1_lineup.bench do
			if (t1_lineup.bench[i].curgame_AB == 0 and t1_lineup.bench[i].curgame_BB == 0) then --Only available if he hasn't yet batted in the game
				batters[#batters+1] = t1_lineup.bench[i];
			end
		end
		
		--print("Num available pinch hitters: " .. #batters);
		
		if (batters[1] ~= nil) then
		gameSimulator.num_pinch_hitters = gameSimulator.num_pinch_hitters + 1;
		--print("Away Switched Batter");
		gameSimulator.away_batter_lineup[gameSimulator.away_batter_index] = batters[1]
		
		 --Pinch hitters did not have batting order to begin the game
		 --Must provide them with a batting order so they show up in the boxscore
		batters[1].batting_order = gameSimulator.away_batter_index;
		batters[1].ph_order = gameSimulator.num_pinch_hitters
		end
	
	else
		--Home team switches batting
		local batters = {} --List of available pinch hitters
		for i = 1, #t2_lineup.bench do
			if (t2_lineup.bench[i].curgame_AB == 0 and t2_lineup.bench[i].curgame_BB == 0) then --Only available if he hasn't yet batted in the game
				batters[#batters+1] = t2_lineup.bench[i];
			end
		end
		
		if (batters[1] ~= nil) then
		gameSimulator.num_pinch_hitters = gameSimulator.num_pinch_hitters + 1;
		--print("Home Switched Batter");
		gameSimulator.home_batter_lineup[gameSimulator.home_batter_index] = batters[1]
		
		 --Pinch hitters did not have batting order to begin the game
		 --Must provide them with a batting order so they show up in the boxscore
		batters[1].batting_order = gameSimulator.home_batter_index;
		batters[1].ph_order = gameSimulator.num_pinch_hitters
		end
	
	end

end

function gameSimulator:reset()

	gameSimulator.gameIsOver = false;
	gameSimulator.inning = 1
	gameSimulator.portion = "top"
	gameSimulator.num_outs = 0
	gameSimulator.balls = 0
	gameSimulator.strikes = 0
	gameSimulator.home_batter_index = 1
	gameSimulator.away_batter_index = 1
	gameSimulator.diamond = {first = nil, second = nil, third = nil}
	gameSimulator.home_score = 0
	gameSimulator.away_score = 0
	gameSimulator.boxscore = {{top = 0, bottom = 0}}
	gameSimulator.home_pitchers_list = {}
	gameSimulator.away_pitchers_list = {}
	gameSimulator.home_batter_lineup = {}
	gameSimulator.away_batter_lineup = {}
	gameSimulator.num_pinch_hitters = 0
end

function gameSimulator:randomInjury(t1_lineup, t2_lineup)


	local allPlayers = {}
	
	for i = 1, #gameSimulator.away_batter_lineup do
		allPlayers[#allPlayers+1] = gameSimulator.away_batter_lineup[i]
	end
	for i = 1, #gameSimulator.away_pitchers_list do
		allPlayers[#allPlayers+1] = gameSimulator.away_pitchers_list[i]
	end
	for i = 1, #gameSimulator.home_batter_lineup do
		allPlayers[#allPlayers+1] = gameSimulator.home_batter_lineup[i]
	end
	for i = 1, #gameSimulator.home_pitchers_list do
		allPlayers[#allPlayers+1] = gameSimulator.home_pitchers_list[i]
	end
	
	
	for i = 1, #allPlayers do
		local player = allPlayers[i];
		local durability = player.durability
		--Quadratic regression (0 durability = 4%, 100 durability = .5%)
		local percentage = .00026 * durability^2 - .06 * durability + 4.03
		if (player.posType == "SP") then percentage = percentage * 3 end
			
		
		if (percentage*10 >= math.random(1,1000)) then
			--Injury occured
			local injury = 2;
			local num = math.random(1,100);
			
			if (player.posType == "SP") then
				if (num <= 30) then
					injury = 7
				elseif (num <= 60) then
					injury = 14
				elseif (num <= 90) then
					injury = 30
				elseif (num <= 97) then
					injury = 100
				elseif (num <= 100) then
					injury = 200
				end
			else
				if (num <= 45) then
					injury = 2
				elseif (num <= 65) then
					injury = 7
				elseif (num <= 85) then
					injury = 14
				elseif (num <= 95) then
					injury = 30
				elseif (num <= 98) then
					injury = 100
				elseif (num <= 100) then
					injury = 200
				end
			end
			player.injury = injury;
		end
	end

end

--After game, record stats into the database
function gameSimulator:recordData(t1_lineup, t2_lineup, t1_id, t2_id, gameid)
	

	local score1, score2 = gameSimulator.away_score, gameSimulator.home_score;
	
	--Generate attendance and revenue based on population and support for home team
	local population, support, attendance
	--Away Team
	local support_away
	
	for row in db:nrows([[ SELECT * FROM teams WHERE id = ]] .. t2_id .. [[; ]])do
		population, support = row.population, row.support
	end
	for row in db:nrows([[ SELECT * FROM teams WHERE id = ]] .. t1_id .. [[; ]])do
		support_away = row.support
	end
	
	
	local fuzz = math.random(-10,10);
	local revenue =  at:determineRevenue(at:determineAttendanceWithFuzz(support, population, fuzz))
	
	print("Population, Support, Attendance: " .. tostring(population)
		.. "; " .. tostring(support) .. "; " .. tostring(attendance));
	print("Revenue: " .. tostring(revenue));
	local stmt= db:prepare[[ UPDATE teams SET money = money + ? WHERE id = ?]];
	stmt:bind_values( revenue, t2_id);
	stmt:step();
	
	--Update runsScored and runsAllowed for each team
	local stmt= db:prepare[[ UPDATE teams SET runsScored = runsScored + ?, runsAllowed = runsAllowed + ? WHERE id = ?]];
	stmt:bind_values(score1, score2, t1_id);
	stmt:step();
	local stmt= db:prepare[[ UPDATE teams SET runsScored = runsScored + ?, runsAllowed = runsAllowed + ? WHERE id = ?]];
	stmt:bind_values(score2, score1, t2_id);
	stmt:step();
	

	--Pitchers who pitched have their days rest set to 0
	local allPitchers = {t1_lineup.sp, t1_lineup.closer, t2_lineup.sp, t2_lineup.closer}
	for i = 1, #t1_lineup.bullpen do
		allPitchers[#allPitchers+1] = t1_lineup.bullpen[i];
	end
	for i = 1, #t2_lineup.bullpen do
		allPitchers[#allPitchers+1] = t2_lineup.bullpen[i];
	end
			
	for i = 1, #allPitchers do
		if (allPitchers[i].curgame_pitchesThrown > 0) then
			db:exec([[UPDATE players SET days_rest = 0 WHERE id = ]] .. allPitchers[i].id)
		end
	end
		
	
	
	local playoffs_info
	for row in db:nrows([[ SELECT * FROM league; ]])do
		local mode = row.mode
		if (mode == "Playoffs") then
			playoffs_info = json.decode(row.playoffs_info)
		end
	end
	
	--If in the playoffs, update the win/loss into playoffs_info in the league table
	if (playoffs_info ~= nil) then
		
		--Increase support of each team in playoffs games (despite win or loss)
		support, support_away = gameSimulator:changeSupport(support, true), gameSimulator:changeSupport(support_away, true)
		stmt= db:prepare[[ UPDATE teams SET support = ? WHERE id = ?]];
		stmt:bind_values(support, t2_id);
		stmt:step();
		stmt= db:prepare[[ UPDATE teams SET support = ? WHERE id = ?]];
		stmt:bind_values(support_away, t1_id);
		stmt:step();
		
		--Determine who won the game
		local teamid
		if (score1 > score2) then
		--Team 1 won
			teamid = t1_id
		else
		--Team 2 won
			teamid = t2_id
		end
		
		--Look for the seed of the team that won
		local seed = 1; 
		for i = 1, #playoffs_info.seeds do
			if (teamid == playoffs_info.seeds[i]) then
				seed = i
				break;
			end
		end
		
		--Add the win to the wins of the corresponding seed in the current round
		if ( playoffs_info.finals ~= nil) then
			--Currently in finals
			
			--Go through matchups in the round
			for i = 1, #playoffs_info.finals do
				local matchup = playoffs_info.finals[i]
				local team1 = matchup[1]
				local team2 = matchup[2]
				
				if (team1.seed == seed) then
					team1.wins = team1.wins + 1
				end
				if (team2.seed == seed) then
					team2.wins = team2.wins + 1
				end
			
			end
		elseif ( playoffs_info.round2 ~= nil) then
			--Currently in round 2
			
			--Go through matchups in the round
			for i = 1, #playoffs_info.round2 do
				local matchup = playoffs_info.round2[i]
				local team1 = matchup[1]
				local team2 = matchup[2]
				
				if (team1.seed == seed) then
					team1.wins = team1.wins + 1
				end
				if (team2.seed == seed) then
					team2.wins = team2.wins + 1
				end
			
			end
		elseif ( playoffs_info.round1 ~= nil) then
			--Currently in round 1
			
			--Go through matchups in the round
			for i = 1, #playoffs_info.round1 do
				local matchup = playoffs_info.round1[i]
				local team1 = matchup[1]
				local team2 = matchup[2]
				
				if (team1.seed == seed) then
					team1.wins = team1.wins + 1
				end
				if (team2.seed == seed) then
					team2.wins = team2.wins + 1
				end
			
			end
		end	
		
		--Update playoffs_info in the database
		local stmt = db:prepare[[UPDATE league SET playoffs_info = ?;]];
		stmt:bind_values( json.encode(playoffs_info)) 
		stmt:step();
	end
	
	--Update regular season win loss, and pitcher win loss saves statistics
	if (score1 > score2) then
		--Team 1 won
		if (playoffs_info == nil) then
		db:exec([[UPDATE teams SET win = win + 1 WHERE id = ]] .. t1_id)
		db:exec([[UPDATE teams SET loss = loss + 1 WHERE id = ]] .. t2_id)
		
		support, support_away = gameSimulator:changeSupport(support, false), gameSimulator:changeSupport(support_away, true)
		
		stmt= db:prepare[[ UPDATE teams SET support = ? WHERE id = ?]];
		stmt:bind_values(support_away, t1_id);
		stmt:step();
		stmt= db:prepare[[ UPDATE teams SET support = ? WHERE id = ?]];
		stmt:bind_values(support, t2_id);
		stmt:step();
		end
		
		--Team1 SP gets the win (too lazy to do crazy MLB logic)
		t1_lineup.sp.curgame_gotWin = true;
		
		--See if anybody on team1 should get a save
		local lastPitcher = gameSimulator.away_pitchers_list[#gameSimulator.away_pitchers_list]
		if ( lastPitcher.curgame_pitchesThrown > 0 and lastPitcher.posType ~= "SP" and (score1-score2 + lastPitcher.curgame_P_ER) <= 3) then
			lastPitcher.curgame_gotSave = true;
		end

		t2_lineup.sp.curgame_gotLoss = true;
		
	else
		--Team 2 won
		if (playoffs_info == nil) then
		db:exec([[UPDATE teams SET win = win + 1 WHERE id = ]] .. t2_id)
		db:exec([[UPDATE teams SET loss = loss + 1 WHERE id = ]] .. t1_id)
		
		support, support_away = gameSimulator:changeSupport(support, true), gameSimulator:changeSupport(support_away, false)
		
		stmt= db:prepare[[ UPDATE teams SET support = ? WHERE id = ?]];
		stmt:bind_values(support_away, t1_id);
		stmt:step();
		stmt= db:prepare[[ UPDATE teams SET support = ? WHERE id = ?]];
		stmt:bind_values(support, t2_id);
		stmt:step();
		end
		
		t2_lineup.sp.curgame_gotWin = true;
		
		--See if anybody on team2 should get a save
		local lastPitcher = gameSimulator.home_pitchers_list[#gameSimulator.home_pitchers_list]
		if ( lastPitcher.curgame_pitchesThrown > 0 and lastPitcher.posType ~= "SP" and (score2-score1 + lastPitcher.curgame_P_ER) <= 3) then
			lastPitcher.curgame_gotSave = true;
		end

		t1_lineup.sp.curgame_gotLoss = true;
	
	end
	
	

	--Update batter stats in players database
	local batters = {t1_lineup.first, t1_lineup.second, t1_lineup.short, t1_lineup.third, t1_lineup.catcher,
			t1_lineup.dh, t1_lineup.left, t1_lineup.center, t1_lineup.right,
			t2_lineup.first, t2_lineup.second, t2_lineup.short, t2_lineup.third, t2_lineup.catcher,
			t2_lineup.dh, t2_lineup.left, t2_lineup.center, t2_lineup.right}
	for i = 1, #t1_lineup.bench do
		batters[#batters+1] = t1_lineup.bench[i]
	end
	for i = 1, #t2_lineup.bench do
		batters[#batters+1] = t2_lineup.bench[i]
	end
			
	for i = 1, #batters do
		local batter = batters[i]
		
		
		--Add the curgame stats to the batter's season stats
		batter.AB, batter.R, batter.H, batter.DOUBLES, batter.TRIPLES, batter.HR, batter.RBI, batter.BB, batter.SO, batter.SB, batter.CS, batter.DRS = 
		batter.AB+batter.curgame_AB, batter.R+batter.curgame_R, batter.H+batter.curgame_H,
		batter.DOUBLES+batter.curgame_DOUBLES, batter.TRIPLES+batter.curgame_TRIPLES,
		batter.HR+batter.curgame_HR, batter.RBI+batter.curgame_RBI, batter.BB+batter.curgame_BB, batter.SO+batter.curgame_SO, 
		batter.SB+batter.curgame_SB, batter.CS+batter.curgame_CS, batter.DRS+batter.curgame_DRS;
		
		batter.AVG, batter.OBP, batter.SLG =
		gameSimulator:calculateAvg(batter), gameSimulator:calculateObp(batter), gameSimulator:calculateSlg(batter);
		
		local gp_query = "GP";
		if (batter.curgame_AB > 0 or batter.curgame_BB > 0) then
			gp_query = "GP + 1"
		end
				
		local query = [[UPDATE players SET AB = ]]  .. batter.AB .. [[ ,R = ]] .. batter.R .. [[ ,H = ]] .. batter.H .. [[ ,DOUBLES = ]] .. batter.DOUBLES
			.. [[ ,GP = ]] .. gp_query
			.. [[ ,TRIPLES = ]] .. batter.TRIPLES .. [[ ,HR = ]] .. batter.HR .. [[ ,RBI = ]] .. batter.RBI
			.. [[ ,BB = ]] .. batter.BB .. [[ ,SO = ]] .. batter.SO .. [[ ,AVG = ]] .. batter.AVG
			.. [[ ,OBP = ]] .. batter.OBP .. [[ ,SLG = ]] .. batter.SLG 
			.. [[ ,SB = ]] .. batter.SB .. [[ ,CS = ]] .. batter.CS .. [[ ,DRS = ]] .. batter.DRS
			.. [[ ,injury = ]] .. batter.injury
			.. [[ WHERE id = ]] ..
			batter.id .. [[;]];
		--print("EXECUTING QUERY: " .. query);
		
		db:exec(query);
	end
	
	--Update pitcher stats in players database
	local pitchers = {t1_lineup.sp, t2_lineup.sp, t1_lineup.closer, t2_lineup.closer}
	for i = 1, #t1_lineup.bullpen do
		pitchers[#pitchers+1] = t1_lineup.bullpen[i]
	end
	for i = 1, #t2_lineup.bullpen do
		pitchers[#pitchers+1] = t2_lineup.bullpen[i]
	end
		
	for i = 1, #pitchers do
		local pitcher = pitchers[i]
		
		pitcher.P_IP, pitcher.P_H, pitcher.P_ER, pitcher.P_HR, pitcher.P_BB, pitcher.P_SO = 
		gameSimulator:addInnings(pitcher.P_IP,pitcher.curgame_P_IP), pitcher.P_H+pitcher.curgame_P_H,
		pitcher.P_ER+pitcher.curgame_P_ER, pitcher.P_HR+pitcher.curgame_P_HR, 
		pitcher.P_BB+pitcher.curgame_P_BB, pitcher.P_SO+pitcher.curgame_P_SO
		pitcher.P_WHIP, pitcher.P_ERA = gameSimulator:calculateWhip(pitcher), gameSimulator:calculateEra(pitcher)
		pitcher.DRS = pitcher.DRS + pitcher.curgame_DRS
		
		local gs_query; --Query that changes number of games started
		local gp_query; --Query that changes the number of games played
		if(pitcher.posType == "SP") then
			gs_query = "P_GS + 1";
		else
			gs_query = "P_GS"; --Stays the same
		end
		if(pitcher.curgame_pitchesThrown > 0) then
			gp_query = "P_GP + 1";
		else
			gp_query = "P_GP"; --Stays the same
		end
		
		local winQ, lossQ, saveQ
		if (pitcher.curgame_gotWin) then
			winQ = "P_W + 1"
		else
			winQ = "P_W"
		end
		
		if (pitcher.curgame_gotLoss) then
			lossQ = "P_L + 1"
		else
			lossQ = "P_L"
		end
		
		if (pitcher.curgame_gotSave) then
			saveQ = "P_SV + 1"
		else
			saveQ = "P_SV"
		end
			
		local query = [[UPDATE players SET P_GP = ]] .. gp_query .. [[ , P_GS = ]] .. gs_query .. [[, P_IP = ]] .. pitcher.P_IP .. [[ ,P_H = ]] .. pitcher.P_H .. [[ ,P_ER = ]] .. pitcher.P_ER
			.. [[ ,P_HR = ]] .. pitcher.P_HR .. [[ ,P_BB = ]] .. pitcher.P_BB .. [[ ,P_SO = ]] .. pitcher.P_SO
			.. [[ ,P_WHIP = ]] .. pitcher.P_WHIP .. [[ ,DRS = ]] .. pitcher.DRS
			.. [[ ,P_ERA = ]] .. pitcher.P_ERA
			.. [[ ,P_W = ]] ..  winQ   .. [[ , P_L = ]] .. lossQ  .. [[ , P_SV = ]] .. saveQ
			.. [[ ,injury = ]] .. pitcher.injury
			.. [[ WHERE id = ]] .. pitcher.id .. [[;]];

		--print("EXECUTING QUERY: " .. query);
		db:exec(query);
	end
	
	--Format Team Batting Stats To Add to The Game Record (in games table)
	local team1_batting = {}
	local team2_batting = {}
	local list = {"first", "second", "short", "third", "catcher", "dh", "left", "center", "right"}
	local list_abv = {"1B", "2B", "SS", "3B", "C", "DH", "LF", "CF", "RF"}
	for i = 1, #list do
		local batter = t1_lineup[list[i]]
		local batter2 = t2_lineup[list[i]]
		team1_batting[#team1_batting+1] = {NAME = batter.name, POSITION = list_abv[i], ID = batter.id,
			AB = batter.curgame_AB, R = batter.curgame_R, H = batter.curgame_H,
			DOUBLES = batter.curgame_DOUBLES, TRIPLES = batter.curgame_TRIPLES,
			HR = batter.curgame_HR, RBI = batter.curgame_RBI, BB = batter.curgame_BB, SO = batter.curgame_SO, 
			SB = batter.curgame_SB, CS = batter.curgame_CS, AVG = batter.AVG, OBP = batter.OBP, SLG = batter.SLG,
			BATTING_ORDER = batter.batting_order}
		team2_batting[#team2_batting+1] = {NAME = batter2.name, POSITION = list_abv[i], ID = batter2.id, 
			AB = batter2.curgame_AB, R = batter2.curgame_R, H = batter2.curgame_H,
			DOUBLES = batter2.curgame_DOUBLES, TRIPLES = batter2.curgame_TRIPLES,
			HR = batter2.curgame_HR, RBI = batter2.curgame_RBI, BB = batter2.curgame_BB, SO = batter2.curgame_SO, 
			SB = batter2.curgame_SB, CS = batter2.curgame_CS, AVG = batter2.AVG, OBP = batter2.OBP, SLG = batter2.SLG,
			BATTING_ORDER = batter2.batting_order}
	end
	for i = 1, #t1_lineup.bench do --Pinch hitters
		local batter = t1_lineup.bench[i]
		
		if (batter.curgame_AB > 0 or batter.curgame_BB > 0) then --Pinch hitters only in boxscore if they actually have an at bat
		team1_batting[#team1_batting+1] = {NAME = batter.name, POSITION = list_abv[i], ID = batter.id,
			AB = batter.curgame_AB, R = batter.curgame_R, H = batter.curgame_H,
			DOUBLES = batter.curgame_DOUBLES, TRIPLES = batter.curgame_TRIPLES,
			HR = batter.curgame_HR, RBI = batter.curgame_RBI, BB = batter.curgame_BB, SO = batter.curgame_SO, 
			SB = batter.curgame_SB, CS = batter.curgame_CS, AVG = batter.AVG, OBP = batter.OBP, SLG = batter.SLG,
			BATTING_ORDER = batter.batting_order, PINCH_HITTER = true, PINCH_HITTER_ORDER = batter.ph_order}
		end
	end
	for i = 1, #t2_lineup.bench do --Pinch hitters
		local batter = t2_lineup.bench[i]
		
		if (batter.curgame_AB > 0 or batter.curgame_BB > 0) then --Pinch hitters only in boxscore if they actually have an at bat
		team2_batting[#team2_batting+1] = {NAME = batter.name, POSITION = list_abv[i], ID = batter.id,
			AB = batter.curgame_AB, R = batter.curgame_R, H = batter.curgame_H,
			DOUBLES = batter.curgame_DOUBLES, TRIPLES = batter.curgame_TRIPLES,
			HR = batter.curgame_HR, RBI = batter.curgame_RBI, BB = batter.curgame_BB, SO = batter.curgame_SO, 
			SB = batter.curgame_SB, CS = batter.curgame_CS, AVG = batter.AVG, OBP = batter.OBP, SLG = batter.SLG,
			BATTING_ORDER = batter.batting_order, PINCH_HITTER = true, PINCH_HITTER_ORDER = batter.ph_order}
		end
	end
	
	--Format team pitching stats To Add to The Game Record (in games table)
	local team1_pitching = {}
	local team2_pitching = {}
	for i = 1, #gameSimulator.away_pitchers_list do --Go through list of all pitchers who have pitched in game
		local pitcher = gameSimulator.away_pitchers_list[i]
		--print("Pitcher name: " .. pitcher.name);
		if (pitcher.curgame_pitchesThrown > 0) then --Pitcher only in boxscore if they have pitched in the game
			team1_pitching[#team1_pitching+1] = {NAME = pitcher.name, POSITION = pitcher.posType,
				ID = pitcher.id, IP = pitcher.curgame_P_IP, H = pitcher.curgame_P_H,
				ER = pitcher.curgame_P_ER, HR = pitcher.curgame_P_HR, 
				BB = pitcher.curgame_P_BB, SO = pitcher.curgame_P_SO,
				ERA = pitcher.P_ERA, WHIP = pitcher.P_WHIP,
				PITCHES = pitcher.curgame_pitchesThrown, STRIKES = pitcher.curgame_strikesThrown,
				WIN = pitcher.curgame_gotWin, LOSS = pitcher.curgame_gotLoss, SAVE = pitcher.curgame_gotSave}
		end
	
	end
	for i = 1, #gameSimulator.home_pitchers_list do --Go through list of all pitchers who have pitched in game
		local pitcher = gameSimulator.home_pitchers_list[i]
		if (pitcher.curgame_pitchesThrown > 0) then --Pitcher only in boxscore if they have pitched in the game
			team2_pitching[#team2_pitching+1] = {NAME = pitcher.name, POSITION = pitcher.posType,
				ID = pitcher.id, IP = pitcher.curgame_P_IP, H = pitcher.curgame_P_H,
				ER = pitcher.curgame_P_ER, HR = pitcher.curgame_P_HR, 
				BB = pitcher.curgame_P_BB, SO = pitcher.curgame_P_SO,
				ERA = pitcher.P_ERA, WHIP = pitcher.P_WHIP,
				PITCHES = pitcher.curgame_pitchesThrown, STRIKES = pitcher.curgame_strikesThrown,
				WIN = pitcher.curgame_gotWin, LOSS = pitcher.curgame_gotLoss, SAVE = pitcher.curgame_gotSave}
		end
	
	end
	
	
	--Record the game into the game database
	local info = json.encode({score1 = score1, score2 = score2,
		team1_batting = team1_batting, team2_batting = team2_batting, 
		team1_pitching = team1_pitching, team2_pitching = team2_pitching,
		boxscore = gameSimulator.boxscore});
		
	
	local stmt= db:prepare[[ INSERT INTO games (id, team1_id, team2_id, info) VALUES( ?, ?, ?, ?)]];
	local bindResult = stmt:bind_values( gameid, t1_id, t2_id, info);
	local result = stmt:step();
	
end

function gameSimulator:changeSupport(orig, win)

	--Determine new support for a team after win or loss
	
	if (win) then
		if (orig >= 50) then 
			orig = orig + 1
		else
			--Actually want it to increase by 1.25, but support is an integer
			--Therefore, to achieve the 1.25 effect, increase by 2 25% of time
			local num = math.random(1,4);
			if (num == 1) then
				orig = orig + 2
			else
				orig = orig + 1
			end
		end
	else --Lost
		if (orig <= 50) then 
			orig = orig - 1
		else
			--Actually want it to decrease by 1.25, but support is an integer
			--Therefore, to achieve the 1.25 effect, increase by 2 25% of time
			local num = math.random(1,4);
			if (num == 1) then
				orig = orig - 2
			else
				orig = orig - 1
			end
		end
	end
	
	if (orig < 0) then orig = 0
	elseif (orig > 100) then orig = 100 
	end
	
	return orig


end

function gameSimulator:calculateAvg(batter)
	local avg = batter.H / batter.AB
	
	--Round to two decimal places
	avg = round2(avg, 3);
	
	if (avg == nil) then return 0 end
	return avg
end

function gameSimulator:calculateObp(batter)
	--Formula not perfect because Sac flies are not factored in
	--Sac flies do happen in the game simulation, but they are not recorded a stats
	--May record sac fly stats in the future
	
	local obp = (batter.H + batter.BB) / (batter.AB + batter.BB)
	
	--Round to two decimal places
	obp = round2(obp, 3);
	
	if (obp == nil) then return 0 end
	return obp
end

function gameSimulator:calculateSlg(batter)
	local singles = batter.H - batter.DOUBLES - batter.TRIPLES - batter.HR
	local slg = (singles + (2*batter.DOUBLES) + (3*batter.TRIPLES) + (4*batter.HR)) / batter.AB
	
	--Round to two decimal places
	slg = round2(slg, 3);
	
	if (slg == nil) then return 0 end
	return slg
end

function gameSimulator:calculateEra(pitcher)
	
	--Convert 8.2 ---> 8.66667       8.1 ------> 8.3333333       8 ----> 8
	local innings = math.floor(pitcher.P_IP)
	local extra = pitcher.P_IP - innings;
	local add = 0;
	
	if (math.abs(extra-.1) < .01) then
		add = (1/3)
	elseif (math.abs(extra-.2) < .01) then
		add = (2/3)
	end
	innings = innings + add;
	
	local era = (9 * pitcher.P_ER) / innings
	
	--Round to three decimal places
	era = round2(era, 3);
	
	if (era == nil) then return 0 end
	return era
end

function gameSimulator:calculateWhip(pitcher)
	--Convert 8.2 ---> 8.66667       8.1 ------> 8.3333333       8 ----> 8
	local innings = math.floor(pitcher.P_IP)
	local extra = pitcher.P_IP - innings;
	local add = 0;
	
	if (math.abs(extra-.1) < .01) then
		add = (1/3)
	elseif (math.abs(extra-.2) < .01) then
		add = (2/3)
	end
	innings = innings + add;
	
	local whip = (pitcher.P_H + pitcher.P_BB) / innings
	
	--Round to three decimal places
	whip = round2(whip, 3);
	
	if (whip == nil) then return 0 end
	return whip
end

function gameSimulator:addInnings(inning1, inning2)
	
	function convertInningsToOuts(innings)
	
		local total = math.floor(innings) * 3
		
		local num = innings - math.floor(innings)
		if (math.abs(num-.1) < .01) then
			total = total + 1
		elseif (math.abs(num-.2) < .01) then
			total = total + 2
		end

		return total

	end

	function convertOutsToInnings(outs)
		
		local num = math.floor(outs / 3)
		local remainder = outs % 3
		if (remainder == 1) then remainder = .1
		elseif (remainder == 2) then remainder = .2 end

		return num+remainder

	end
	
	
	local outs1 = convertInningsToOuts(inning1);
	local outs2 = convertInningsToOuts(inning2);
	
	return (convertOutsToInnings(outs1+outs2));
end


--Round to certain number of decimal places
function round2(num, idp)
  return tonumber(string.format("%." .. (idp or 0) .. "f", num))
end
return gameSimulator