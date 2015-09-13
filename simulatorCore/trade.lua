local fa = require("simulatorCore.freeAgents");
local pd = require("simulatorCore.playerDevelopment");
local ss = require("simulatorCore.seasonSimulator");
local at = require("simulatorCore.attendance");
local tv = require("simulatorCore.tv");

--**************************
--[[IMPORTANT NOTE

Unlike other files in the simulator core, this file does not handle database
Creation and destruction

]]--
--***************************

local trade = {
	
}

--Determine whether or not to accept trade
function trade:acceptTrade(playersA, playersB, teamA, teamB, day)
	
	
	
	--playersA - players CPU giving away
	--playersB - players CPU receiving
	--teamA - this team
	--teamB - other team
	--day - what day of the season it is. this is used to adjust the actual value for the first year of the player's contract
	
	for row in db:nrows([[SELECT * FROM teams WHERE id = ]] .. teamA .. [[;]])do
		teamA = row
	end
	for row in db:nrows([[SELECT * FROM teams WHERE id = ]] .. teamB .. [[;]])do
		teamB = row
	end
	
	local aNetValue, bNetValue = 0,0 --net value = value - cost
	local aValue, bValue = 0, 0 --Value of trade assets
	local aCost, bCost = 0, 0 --How much salary assets must be paid
	
	print("\n--------------A-------------")
	
	--Loop through all players CPU giving away
	for i = 1, #playersA do
		local player = playersA[i]
		local tValue = trade:determineTradeValue(player, day)
		aValue = aValue + tValue
		aCost = aCost + player.salary * player.years
	end
	

	print("\n--------------B-------------")
	
	--Loop through all players CPU receiving
	for i = 1, #playersB do
		local player = playersB[i]
		local tValue = trade:determineTradeValue(player, day)
		bValue = bValue + tValue
		bCost = bCost + player.salary * player.years
	end
	
	aNetValue = aValue - aCost
	bNetValue = bValue - bCost
	
	print("\naValue: " .. aValue)
	print("bValue: " .. bValue)
	print("aCost: " .. aCost)
	print("bCost: " .. bCost)
	print("aNetValue = aValue - aCost = " .. aNetValue)
	print("bNetValue = bValue - bCost = " .. bNetValue)
	
	
	--[[
	--cpuBiasWeight is how much CPU values own players over receiving players
	--A weight = 1 would be "fair" according to calculations
	--However, the player is smarter than the CPU, so the weight is higher
	--A higher weight makes it less likely for CPU to be tricked in a trade
	local cpuBiasWeight = 2
	local minValue = 10
	
	if (aValue > 0) then aValue = aValue * cpuBiasWeight
	else aValue = aValue * (1/cpuBiasWeight) end
	
	if (bValue > aValue) then
		--Must be at least net gain of 10 value in order for CPU to pull trigger
		--Any gain less than 10 is too risky for the CPU
		if (bValue-aValue >= 10) then 
			return {true, "Good trade"} --Accept trade
		end
	end
	
	local msg = "Bad trade"
	if (bValue-aValue >= -10) then 
		local msgs = {"Getting close", "Almost there", "Really close", "Need a little more"}
		msg = msgs[math.random(1,#msgs)]
	elseif (bValue-aValue >= -30) then 
		local msgs = {"Need more", "Hmmm...", "Spice it up", "Give me more"}
		msg = msgs[math.random(1,#msgs)]
	elseif (bValue-aValue >= -50) then 
		local msgs = {"Not good", "Bad deal", "Nope!", "I need a lot more"}
		msg = msgs[math.random(1,#msgs)]
	else
		local msgs = {"This is insulting!", "Absolutely terrible", "Hell no", "Absolutely not"}
		msg = msgs[math.random(1,#msgs)]
	end]]--
	

	if (bNetValue - aNetValue >= 10000000 and bNetValue >= aNetValue * 1.2) then return {true, "Good Trade"} end
	return {false, "Bad Trade"} --Decline trade
	
	
end

--Actual database swapping of players
function trade:swapPlayers(playersA, playersB, teamA, teamB)
	
	--playersA --> teamB and vice versa
	local year, teamAAbv, teamBAbv
	for row in db:nrows([[SELECT * FROM league;]])do
		year = row.year
	end
	for row in db:nrows([[SELECT * FROM teams WHERE id = ]] .. teamA .. [[;]])do
		teamAAbv = row.abv;
	end
	for row in db:nrows([[SELECT * FROM teams WHERE id = ]] .. teamB .. [[;]])do
		teamBAbv = row.abv;
	end
	
	for i = 1, #playersA do
		local player = playersA[i]
		
		--Update player transactions to reflect trade
		local transactions
		for row in db:nrows([[SELECT * FROM players WHERE id = ]] .. player.id .. [[;]])do
			if (row.transactions ~= nil) then
				transactions = json.decode(row.transactions)
			else
				transactions = {}
			end
		end
		transactions[#transactions+1] = "Traded from " .. teamAAbv .. " to " .. teamBAbv
			.. " (" .. year .. ")"
		transactions = json.encode(transactions)
		
		local stmt = db:prepare[[UPDATE players SET teamid = ?, transactions = ? WHERE id = ?]];
		stmt:bind_values(teamB, transactions, player.id) 
		stmt:step();
	end
	for i = 1, #playersB do
		local player = playersB[i]
		
		--Update player transactions to reflect trade
		local transactions
		for row in db:nrows([[SELECT * FROM players WHERE id = ]] .. player.id .. [[;]])do
			if (row.transactions ~= nil) then
				transactions = json.decode(row.transactions)
			else
				transactions = {}
			end
		end
		transactions[#transactions+1] = "Traded from " .. teamBAbv .. " to " .. teamAAbv
			.. " (" .. year .. ")"
		transactions = json.encode(transactions)
		
		local stmt = db:prepare[[UPDATE players SET teamid = ?, transactions = ? WHERE id = ?]];
		stmt:bind_values(teamA, transactions, player.id) 
		stmt:step();
	end
	

end

--Local functions utilized by trade core
function trade:determineTradeValue(player,day)

	--Return proper trade monetary value of player
	local totalTradeValue = 0
	
	--Store orig player values for future restoration
	local origValues = {}
	for k,v in pairs(player) do
		origValues[k] = v;
	end
	
	local function getTradeCoefficient(overall)
		local coeff = 0
		--Multiply the actual value of the player by the trade coefficient
		--This places more emphasis on trading for players with higher OVR
		--Coefficient = 50 = .88    ,   100 = 1.6 (Quadratic)
		coeff = .000284 * overall ^ 2 - .0221 * overall + 1.276
		if (overall < 50) then coeff = .88 end
		return coeff
	end
		
		
	--Calculate total trade value
	for i = 1, player.years do
		--How much player is actually worth in salary
		local actualValue = fa:generateSalaryWanted(player.overall, player.potential, player.posType, player.age, true);
		actualValue = actualValue * getTradeCoefficient(player.overall)
		
		if (i == 1) then
			--For the 1st year, adjust actual value based on how much of the regular season is left
			local fraction = (162 - day) / 162
			actualValue = math.floor(actualValue * fraction)
		end
		
		local tradeValue = actualValue-- - player.salary
		totalTradeValue = totalTradeValue + tradeValue
		
		print(player.name .. " - Age (" .. player.age .. ") Overall (" .. player.overall .. 
			") Pot (" .. player.potential .. ")" .. "  Act Value: $" .. actualValue );
		
		
		--Progress player (take averages of 100 progressions)
		--By progressing player, we get indication of the actual value of player as he ages
		local progressions = {}
		local avgProgression = {
			contact = 0, power = 0, eye = 0,speed = 0,velocity = 0, 
			nastiness = 0, control = 0,stamina = 0, defense = 0, overall = 0,potential = 0
		}
		for i = 1, 100 do
			local ratings = pd:newRatings(player)
			for k,v in pairs(ratings) do
				avgProgression[k] = avgProgression[k] + v
			end
		end
		for k,v in pairs(avgProgression) do
			avgProgression[k] = math.floor(v /100)
		end
		for k,v in pairs(avgProgression) do
			player[k] = v;
		end
		player.age = player.age + 1
		
		
	end

	
	--Restore player back to normal after progression calculating
	--Don't actually want to alter player variables
	for k,v in pairs(origValues) do
		player[k] = v;
	end
	

	return totalTradeValue
end


return trade