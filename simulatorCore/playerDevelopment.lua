local pg = require("simulatorCore.playerGenerator");

local playerDevelopment = {}


function playerDevelopment:progressPlayer(playerid)

	--Player development 2.0
	for row in db:nrows([[SELECT * FROM players WHERE id = ]] .. playerid .. [[;]])do
		if (row.posType == "SP" or row.posType == "RP") then
			--Progress Pitcher
			local nr = playerDevelopment:newRatings(row)
			local stmt = db:prepare[[UPDATE players SET velocity = ?, nastiness = ?, control = ?, 
				stamina = ?, defense = ?, overall = ?, potential = ?, 
				overallChange = ? - overall, potentialChange = ? - potential WHERE id = ?;]];
			stmt:bind_values(nr.velocity, nr.nastiness, nr.control, nr.stamina, nr.defense, nr.overall, nr.potential, nr.overall, nr.potential, playerid);
			stmt:step();
			
		else
			local nr = playerDevelopment:newRatings(row)
			local stmt = db:prepare[[UPDATE players SET contact = ?, power = ?, eye = ?, 
				speed = ?, defense = ?, overall = ?, potential = ?,
				overallChange = ? - overall, potentialChange = ? - potential WHERE id = ?;]];
			stmt:bind_values(nr.contact, nr.power, nr.eye, nr.speed, nr.defense, nr.overall, nr.potential, nr.overall, nr.potential, playerid);
			stmt:step();
			
			
		end
	end

end

function playerDevelopment:newRatings(player)

	local age, iq, overall, potential = player.age, player.iq, player.overall, player.potential
	local teamid = player.teamid
	local oldValues = {player.contact,player.power,player.eye,player.speed,
		player.velocity,player.nastiness,player.control,player.stamina,player.defense}
	
	--Calculate progressionFactor
	local function calculateProgressionFactor()
		--local pf = (-1)*age+35 --Lower age = higher pf
		--Quadratic model
		local pf = (-.0443) * age^2 + 1.7 * age - 1.9
		
		
		--Players who are FA and not in training camp find it harder to progress
		if (teamid == 31) then pf = pf - 15 end 
		
		local fuzz = 0;
		local n = math.random(0,math.floor(iq/3+66)) --Higher iq correlates with higher pf
		if (n <= 15) then --Super Bad
			fuzz = math.random(-40,-15)
		elseif (n <= 25) then --Bad
			fuzz = math.random(-15,-5)
		elseif (n <= 45) then --Okay
			fuzz = math.random(-5,5)
		elseif (n <= 80) then --Good
			fuzz = math.random(5,10)
		elseif (n <= 95) then --Super Good
			fuzz = math.random(10,20)
		else --Excellent
			fuzz = math.random(15,30)
		end
	
		return pf + fuzz;
	end
	
	local lowBoostMin, lowBoostMax = 0, 5;
	local medBoostMin, medBoostMax = 5, 10;
	local lgBoostMin, lgBoostMax = 10, 25;
	local maxBoost = player.potential - player.overall + 1
	local boosts = {}
	
	for i = 1, #oldValues do --Apply boosts (or reductions) to player's attributes
		local boost
		
		local pf = calculateProgressionFactor()
		
		if (pf <= -25) then
			boost = -math.random(lgBoostMin,lgBoostMax)
		elseif (pf <= -15) then
			boost = -math.random(medBoostMin,medBoostMax)
		elseif (pf <= -3) then
			boost = -math.random(lowBoostMin,lowBoostMax)
		elseif (pf < 6) then
			boost = 0
		elseif (pf <= 23) then
			boost = math.random(lowBoostMin,lowBoostMax)	
		elseif (pf <= 33) then
			boost = math.random(medBoostMin,medBoostMax)	
		else 
			boost = math.random(lgBoostMin,lgBoostMax)
		end
		
		if (boost > maxBoost) then boost = maxBoost end
		boosts[i] = boost
	end
	
	local newValues = {}
	for i = 1, #oldValues do
		newValues[#newValues+1] = oldValues[i] + boosts[i]
	end
	for i = 1, #newValues do --Make sure none of the new values are under the 0 threshold
		if (newValues[i] < 0) then newValues[i] = 0 end
		if (newValues[i] > 100) then newValues[i] = 100 end
	end
	
	local newOverall
	if (player.posType == "SP" or player.posType == "RP") then
	    newOverall = pg:getOverallRating(true, newValues[5], newValues[6], newValues[7], newValues[8], newValues[9])
	else
		newOverall = pg:getOverallRating(false, newValues[1], newValues[2], newValues[3], newValues[4], newValues[9])
	end
	
	--Change potential
	local pf = calculateProgressionFactor();
	local newPotential
	if (pf < -10) then newPotential = potential - math.random(10,20)
	elseif (pf < 0) then newPotential = potential - math.random(5,15)
	elseif (pf < 10) then newPotential = potential - math.random(1,5)
	else newPotential = potential end
	
	if (newPotential < newOverall) then newPotential = newOverall end
	
	local newPlayer = {
	contact = newValues[1], 
	power = newValues[2], 
	eye = newValues[3],
	speed = newValues[4],
	velocity = newValues[5], 
	nastiness = newValues[6], 
	control = newValues[7],
	stamina = newValues[8],
	defense = newValues[9],
	overall = newOverall,
	potential = newPotential}
		
	return newPlayer
end

function playerDevelopment:decideRetire(playerid)
	
	
	for row in db:nrows([[SELECT * FROM players WHERE id = ]] .. playerid .. [[;]])do
		local chance = 0;
		
		
		if (row.age <= 27) then
			--Anyone below age of 27 won't retire
		elseif (row.age <= 30) then
			if (row.overall < 40) then
				chance = 80;
			elseif (row.overall < 45) then
				chance = 50;
			elseif (row.overall < 50) then
				chance = 20;
			end
		elseif (row.age <= 32) then
			if (row.overall < 40) then
				chance = 90;
			elseif (row.overall < 45) then
				chance = 60;
			elseif (row.overall < 50) then
				chance = 25;
			end
		elseif (row.age <= 35) then
			if (row.overall < 40) then
				chance = 95;
			elseif (row.overall < 45) then
				chance = 75;
			elseif (row.overall < 50) then
				chance = 35;
			elseif (row.overall < 55) then
				chance = 10;
			end
		elseif (row.age <= 38) then
			if (row.overall < 40) then
				chance = 100;
			elseif (row.overall < 45) then
				chance = 85;
			elseif (row.overall < 50) then
				chance = 75;
			elseif (row.overall < 55) then
				chance = 50;
			elseif (row.overall < 60) then
				chance = 25;
			end
		else
			if (row.overall < 55) then
				chance = 100;
			elseif (row.overall < 60) then
				chance = 75;
			elseif (row.overall < 65) then
				chance = 50;
			elseif (row.overall < 70) then
				chance = 40;
			else
				chance = 25;
			end
		end
	
		if (chance >= math.random(1,100)) then
		
			--Player retires, add him to retired players database
			local stmt = retired_db:prepare[[INSERT INTO players VALUES (?,?,?,?,?,?);]];
			stmt:bind_values(row.id,row.posType,row.name,row.age,row.awards,row.draft_position); 
			stmt:step();
			
			--Remove him from players table in data.db (this table was only meant for current players)
			--This removal should speed up any simulations
			db:exec([[DELETE FROM players WHERE id = ]] .. row.id .. [[;]])
		end
	end
end


return playerDevelopment;