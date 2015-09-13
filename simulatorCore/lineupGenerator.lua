local sqlite3 = require "sqlite3"
local json = require("json");

--**************************
--[[IMPORTANT NOTE

Unlike other files in the simulator core, this file does not handle database
Creation and destruction, Therefore use the following code:

	local path = system.pathForFile("data.db", system.DocumentsDirectory)
	db = sqlite3.open( path )   

	local lineup = lg:generateLineup(id)
	db:close()

]]--
--***************************

local lineupGenerator = {}

--Returns a table that contains a 1B, 2B, SS, 3B, C, DH, OF, OF, OF, SP, and 5 RPs
function lineupGenerator:generateLineup(teamid)
	
	--If roster does not meet minimum league requirements, refuse to generate lineup
	local num_first, num_second, num_short, num_third, num_catcher, num_of, num_sp, num_rp = 0,0,0,0,0,0,0,0;
	for row in db:nrows([[SELECT * FROM players WHERE teamid = ]] .. teamid)do
		if (row.posType == "1B" and row.injury == 0) then num_first = num_first + 1;
		elseif (row.posType == "2B" and row.injury == 0) then num_second = num_second + 1;
		elseif (row.posType == "SS" and row.injury == 0) then num_short = num_short + 1;
		elseif (row.posType == "3B" and row.injury == 0) then num_third = num_third + 1;
		elseif (row.posType == "C" and row.injury == 0) then num_catcher = num_catcher + 1;
		elseif (row.posType == "OF" and row.injury == 0) then num_of = num_of + 1;
		elseif (row.posType == "SP" and row.injury == 0) then num_sp = num_sp + 1;
		elseif (row.posType == "RP" and row.injury == 0) then num_rp = num_rp + 1;
		end
	end
	if (num_first < 2 or num_second < 2 or num_short < 2 or num_third < 2 or num_catcher < 2 or num_of < 5 or num_sp < 5 or num_rp < 6) then
		return nil
	end

	
	local lineup = {}

	
	local myteam
	for row in db:nrows([[SELECT * FROM myteam;]])do
		myteam = row;
	end
	if (myteam.teamid == teamid and myteam.customLineup ~= nil) then
		--Generate a lineup that is influenced by custom lineup
		return lineupGenerator:generateLineupForMyTeam(teamid, json.decode(myteam.customLineup));
	end

	local first, second, short, third, catcher, dh, sp, closer;
	local ofs = {};
	local bench = {}; --Backup Batters
	local rps = {}; --rps[1] = closer, because he has highest overall
	for row in db:nrows([[SELECT * FROM players WHERE teamid = ]] .. teamid .. [[ AND posType = "1B" AND injury = 0 ORDER BY overall DESC;]])do
		first = row;
		break;
	end
	for row in db:nrows([[SELECT * FROM players WHERE teamid = ]] .. teamid .. [[ AND posType = "2B" AND injury = 0 ORDER BY overall DESC;]])do
		second = row;
		break;
	end
	for row in db:nrows([[SELECT * FROM players WHERE teamid = ]] .. teamid .. [[ AND posType = "SS" AND injury = 0 ORDER BY overall DESC;]])do
		short = row;
		break;
	end
	for row in db:nrows([[SELECT * FROM players WHERE teamid = ]] .. teamid .. [[ AND posType = "3B" AND injury = 0 ORDER BY overall DESC;]])do
		third = row;
		break;
	end
	for row in db:nrows([[SELECT * FROM players WHERE teamid = ]] .. teamid .. [[ AND posType = "C" AND injury = 0 ORDER BY overall DESC;]])do
		catcher = row;
		break;
	end
	for row in db:nrows([[SELECT * FROM (SELECT * FROM players WHERE teamid = ]] .. teamid .. [[ AND posType = "OF" AND injury = 0 ORDER BY overall DESC LIMIT 3) ORDER BY speed DESC;]])do
		--Get the top three outfielders by overall
		--These outfielders are sorted by speed, in descending order
		--Fastest = CF
		--2nd = RF
		--3rd = LF
		ofs[#ofs+1] = row;
	end
	for row in db:nrows([[SELECT * FROM players WHERE teamid = ]] .. teamid .. [[ AND posType = "SP" AND injury = 0 AND days_rest >= 5 ORDER BY overall DESC LIMIT 6;]])do
		sp = row;
		break
	end
	for row in db:nrows([[SELECT * FROM players WHERE teamid = ]] .. teamid .. [[ AND posType = "RP" AND injury = 0 ORDER BY overall DESC LIMIT 6;]])do
		rps[#rps+1] = row;
	end
	closer = rps[1];
	table.remove(rps, 1); --Separate closer from rest of the relievers

	--If not enough active players, return a nil lineup
	if (first == nil or second == nil or short == nil or third == nil or 
		catcher == nil or ofs[3] == nil or ofs[1] == nil or ofs[2] == nil or 
		sp == nil or closer == nil or rps[1] == nil or
		rps[2] == nil or rps[3] == nil or rps[4] == nil or rps[5] == nil) then
		return nil
	end

	
	--Choose DH, batter with the best overall after all the starters
	--Also form bench of batters
	local alreadyTaken = {first.id, second.id, short.id, third.id, catcher.id, ofs[1].id, ofs[2].id, ofs[3].id} --List of batters already in lineup
	local query = [[SELECT * FROM players WHERE teamid = ]] .. teamid .. [[ AND posType != "RP" AND posType != "SP" AND injury = 0]]
	for i = 1, #alreadyTaken do
		--Exclude the players already taken from the query
		query = query .. [[ AND id != ]] .. alreadyTaken[i]
	end
	query = query .. [[ ORDER BY overall DESC LIMIT 4;]];
	
	local n = 1;
	for row in db:nrows(query)do
		if (n==1) then
			dh = row;
		else
			bench[#bench+1] = row;
		end
		n=n+1
	end

	--If not enough active players, return a nil lineup
	if (bench[1] == nil or bench[2] == nil or bench[3] == nil or dh == nil) then
		return nil
	end
	
	
	--Determine the batting order - Add the additional .batting_order property to each of the batter's info
	
	local batters = {first, second, short, third, catcher, dh, ofs[1], ofs[2], ofs[3]}

	--3 - Greatest contact + power (Greater priority over 1 & 2 holes)
	local total, index = 0, 1;
	for i = 1, #batters do
		local sum = batters[i].contact + batters[i].power
		if (sum > total) then
			total = sum
			index = i
		end
	end
	batters[index].batting_order = 3; --This property is not saved to database because it may be different each game
	table.remove(batters, index);
	
	--4 - Greatest contact + power
	local total, index = 0, 1;
	for i = 1, #batters do
		local sum = batters[i].contact + batters[i].power
		if (sum > total) then
			total = sum
			index = i
		end
	end
	batters[index].batting_order = 4; --This property is not saved to database because it may be different each game
	table.remove(batters, index);
	
	--5 - Greatest contact + power
	local total, index = 0, 1;
	for i = 1, #batters do
		local sum = batters[i].contact + batters[i].power
		if (sum > total) then
			total = sum
			index = i
		end
	end
	batters[index].batting_order = 5; --This property is not saved to database because it may be different each game
	table.remove(batters, index);
	
	
	--1 - Greatest contact + eye
	local total, index = 0, 1;
	for i = 1, #batters do
		local sum = batters[i].contact + batters[i].eye
		if (sum > total) then
			total = sum
			index = i
		end
	end
	batters[index].batting_order = 1; --This property is not saved to database because it may be different each game
	table.remove(batters, index);
	
	--2 - Greatest contact + eye
	local total, index = 0, 1;
	for i = 1, #batters do
		local sum = batters[i].contact + batters[i].eye
		if (sum > total) then
			total = sum
			index = i
		end
	end
	batters[index].batting_order = 2; --This property is not saved to database because it may be different each game
	table.remove(batters, index);
	
	--6 - Greatest contact + power + eye
	local total, index = 0, 1;
	for i = 1, #batters do
		local sum = batters[i].contact + batters[i].power + batters[i].eye
		if (sum > total) then
			total = sum
			index = i
		end
	end
	batters[index].batting_order = 6; --This property is not saved to database because it may be different each game
	table.remove(batters, index);
	
	--7 - Greatest contact + power + eye
	local total, index = 0, 1;
	for i = 1, #batters do
		local sum = batters[i].contact + batters[i].power + batters[i].eye
		if (sum > total) then
			total = sum
			index = i
		end
	end
	batters[index].batting_order = 7; --This property is not saved to database because it may be different each game
	table.remove(batters, index);
	
	--8 - Greatest contact + power + eye
	local total, index = 0, 1;
	for i = 1, #batters do
		local sum = batters[i].contact + batters[i].power + batters[i].eye
		if (sum > total) then
			total = sum
			index = i
		end
	end
	batters[index].batting_order = 8; --This property is not saved to database because it may be different each game
	table.remove(batters, index);
	
	--9 - Greatest contact + power + eye
	local total, index = 0, 1;
	for i = 1, #batters do
		local sum = batters[i].contact + batters[i].power + batters[i].eye
		if (sum > total) then
			total = sum
			index = i
		end
	end
	batters[index].batting_order = 9; --This property is not saved to database because it may be different each game
	table.remove(batters, index);
	
	
	--print("Lineup (After Generate) Mem Count: " .. collectgarbage('count'))

	--Bullpen = Relievers
	--Bench = Backup Batters (3)
	--Returns batters (including their info) by position
	return {first = first, second = second, short = short, third = third, catcher = catcher, left = ofs[3], 
	center = ofs[1], right = ofs[2],  dh = dh, bullpen = rps, closer = closer, sp = sp, bench = bench}
	

	
	
	
end

function lineupGenerator:generateLineupForMyTeam(teamid, customLineup)
	
	--Only difference from generate lineup is that this is influenced by customLineup
	local first, second, short, third, catcher, dh, sp, closer;
	local ofs = {};
	local bench = {}; --Backup Batters
	local rps = {}; --rps[1] = closer, because he has highest overall
	
	local alreadyTaken = {} --List of player ids already used by the custom lineup
	

	--Position players
	if (customLineup[1].id ~= nil) then
	--User has provided a custom first baseman
	for row in db:nrows([[SELECT * FROM players WHERE id = ]] .. customLineup[1].id)do
		if (row.injury == 0 and row.teamid == teamid) then
			first = row
			alreadyTaken[#alreadyTaken+1] = row.id;
		end
	end
	end

	if (customLineup[2].id ~= nil) then
	--User has provided a custom first baseman
	for row in db:nrows([[SELECT * FROM players WHERE id = ]] .. customLineup[2].id)do
		if (row.injury == 0 and row.teamid == teamid) then
			second = row
			alreadyTaken[#alreadyTaken+1] = row.id;
		end
	end
	end
	
	if (customLineup[3].id ~= nil) then
	--User has provided a custom first baseman
	for row in db:nrows([[SELECT * FROM players WHERE id = ]] .. customLineup[3].id)do
		if (row.injury == 0 and row.teamid == teamid) then
			short = row
			alreadyTaken[#alreadyTaken+1] = row.id;
		end
	end
	end
	
	if (customLineup[4].id ~= nil) then
	--User has provided a custom first baseman
	for row in db:nrows([[SELECT * FROM players WHERE id = ]] .. customLineup[4].id)do
		if (row.injury == 0 and row.teamid == teamid) then
			third = row
			alreadyTaken[#alreadyTaken+1] = row.id;
		end
	end
	end
	
	if (customLineup[5].id ~= nil) then
	--User has provided a custom first baseman
	for row in db:nrows([[SELECT * FROM players WHERE id = ]] .. customLineup[5].id)do
		if (row.injury == 0 and row.teamid == teamid) then
			catcher = row
			alreadyTaken[#alreadyTaken+1] = row.id;
		end
	end
	end
	
	--Outfielders
	if (customLineup[6].id ~= nil) then
	--User has provided a custom first baseman
	for row in db:nrows([[SELECT * FROM players WHERE id = ]] .. customLineup[6].id)do
		if (row.injury == 0 and row.teamid == teamid) then
			ofs[3] = row
			alreadyTaken[#alreadyTaken+1] = row.id;
		end
	end
	end

	if (customLineup[7].id ~= nil) then
	--User has provided a custom first baseman
	for row in db:nrows([[SELECT * FROM players WHERE id = ]] .. customLineup[7].id)do
		if (row.injury == 0 and row.teamid == teamid) then
			ofs[1] = row
			alreadyTaken[#alreadyTaken+1] = row.id;
		end
	end
	end
	
	if (customLineup[8].id ~= nil) then
	--User has provided a custom first baseman
	for row in db:nrows([[SELECT * FROM players WHERE id = ]] .. customLineup[8].id)do
		if (row.injury == 0 and row.teamid == teamid) then
			ofs[2] = row
			alreadyTaken[#alreadyTaken+1] = row.id;
		end
	end
	end

	
	--DH/Bench
	if (customLineup[9].id ~= nil) then
	--User has provided a custom first baseman
	for row in db:nrows([[SELECT * FROM players WHERE id = ]] .. customLineup[9].id)do
		if (row.injury == 0 and row.teamid == teamid) then
			bench[1] = row
			alreadyTaken[#alreadyTaken+1] = row.id;
		end
	end
	end

	if (customLineup[10].id ~= nil) then
	--User has provided a custom first baseman
	for row in db:nrows([[SELECT * FROM players WHERE id = ]] .. customLineup[10].id)do
		if (row.injury == 0 and row.teamid == teamid) then
			bench[2] = row
			alreadyTaken[#alreadyTaken+1] = row.id;
		end
	end
	end
	
	if (customLineup[11].id ~= nil) then
	--User has provided a custom first baseman
	for row in db:nrows([[SELECT * FROM players WHERE id = ]] .. customLineup[11].id)do
		if (row.injury == 0 and row.teamid == teamid) then
			bench[3] = row
			alreadyTaken[#alreadyTaken+1] = row.id;
		end
	end
	end
	
	if (customLineup[12].id ~= nil) then
	--User has provided a custom first baseman
	for row in db:nrows([[SELECT * FROM players WHERE id = ]] .. customLineup[12].id)do
		if (row.injury == 0 and row.teamid == teamid) then
			bench[4] = row
			alreadyTaken[#alreadyTaken+1] = row.id;
		end
	end
	end
	

	--Starting Pitcher
	if (customLineup[13].id ~= nil and sp == nil) then
		for row in db:nrows([[SELECT * FROM players WHERE id = ]] .. customLineup[13].id)do
		if (row.injury == 0 and row.teamid == teamid and row.days_rest >= 5) then
			sp = row
			alreadyTaken[#alreadyTaken+1] = row.id;
		end
		end
	end
	
	if (customLineup[14].id ~= nil and sp == nil) then
		for row in db:nrows([[SELECT * FROM players WHERE id = ]] .. customLineup[14].id)do
		if (row.injury == 0 and row.teamid == teamid and row.days_rest >= 5) then
			sp = row
			alreadyTaken[#alreadyTaken+1] = row.id;
		end
		end
	end
	
	if (customLineup[15].id ~= nil and sp == nil) then
		for row in db:nrows([[SELECT * FROM players WHERE id = ]] .. customLineup[15].id)do
		if (row.injury == 0 and row.teamid == teamid and row.days_rest >= 5) then
			sp = row
			alreadyTaken[#alreadyTaken+1] = row.id;
		end
		end
	end
	
	if (customLineup[16].id ~= nil and sp == nil) then
		for row in db:nrows([[SELECT * FROM players WHERE id = ]] .. customLineup[16].id)do
		if (row.injury == 0 and row.teamid == teamid and row.days_rest >= 5) then
			sp = row
			alreadyTaken[#alreadyTaken+1] = row.id;
		end
		end
	end
	
	if (customLineup[17].id ~= nil and sp == nil) then
		for row in db:nrows([[SELECT * FROM players WHERE id = ]] .. customLineup[17].id)do
		if (row.injury == 0 and row.teamid == teamid and row.days_rest >= 5) then
			sp = row
			alreadyTaken[#alreadyTaken+1] = row.id;
		end
		end
	end
	
	
	--Relief Pitchers
	if (customLineup[18].id ~= nil) then
	--User has provided a custom first baseman
	for row in db:nrows([[SELECT * FROM players WHERE id = ]] .. customLineup[18].id)do
		if (row.injury == 0 and row.teamid == teamid) then
			rps[2] = row
			alreadyTaken[#alreadyTaken+1] = row.id;
		end
	end
	end
	
	if (customLineup[19].id ~= nil) then
	--User has provided a custom first baseman
	for row in db:nrows([[SELECT * FROM players WHERE id = ]] .. customLineup[19].id)do
		if (row.injury == 0 and row.teamid == teamid) then
			rps[3] = row
			alreadyTaken[#alreadyTaken+1] = row.id;
		end
	end
	end
	
	if (customLineup[20].id ~= nil) then
	--User has provided a custom first baseman
	for row in db:nrows([[SELECT * FROM players WHERE id = ]] .. customLineup[20].id)do
		if (row.injury == 0 and row.teamid == teamid) then
			rps[4] = row
			alreadyTaken[#alreadyTaken+1] = row.id;
		end
	end
	end
	
	if (customLineup[21].id ~= nil) then
	--User has provided a custom first baseman
	for row in db:nrows([[SELECT * FROM players WHERE id = ]] .. customLineup[21].id)do
		if (row.injury == 0 and row.teamid == teamid) then
			rps[5] = row
			alreadyTaken[#alreadyTaken+1] = row.id;
		end
	end
	end
	
	if (customLineup[22].id ~= nil) then
	--User has provided a custom first baseman
	for row in db:nrows([[SELECT * FROM players WHERE id = ]] .. customLineup[22].id)do
		if (row.injury == 0 and row.teamid == teamid) then
			rps[6] = row
			alreadyTaken[#alreadyTaken+1] = row.id;
		end
	end
	end
	
	if (customLineup[23].id ~= nil) then
	--User has provided a custom first baseman
	for row in db:nrows([[SELECT * FROM players WHERE id = ]] .. customLineup[23].id)do
		if (row.injury == 0 and row.teamid == teamid) then
			rps[1] = row
			alreadyTaken[#alreadyTaken+1] = row.id;
		end
	end
	end
	
	
	--Fill in any remaining roster holes (Not according to custom lineup)
	local extraQuery = "" --Extra query excludes player ids that are already taken
	for i = 1, #alreadyTaken do
		extraQuery = extraQuery .. [[ AND id != ]] .. alreadyTaken[i]
	end
		
	if (first == nil) then
		for row in db:nrows([[SELECT * FROM players WHERE teamid = ]] .. teamid 
			.. [[ AND posType = "1B" AND injury = 0 ]] .. extraQuery .. [[ ORDER BY overall DESC;]])do
			first = row;
			alreadyTaken[#alreadyTaken+1] = row.id
			extraQuery = extraQuery .. [[ AND id != ]] .. row.id
			break;
		end
	end
	if (second == nil) then
		for row in db:nrows([[SELECT * FROM players WHERE teamid = ]] .. teamid 
			.. [[ AND posType = "2B" AND injury = 0 ]] .. extraQuery .. [[ ORDER BY overall DESC;]])do
			second = row;
			alreadyTaken[#alreadyTaken+1] = row.id
			extraQuery = extraQuery .. [[ AND id != ]] .. row.id
			break;
		end
	end
	if (short == nil) then
		for row in db:nrows([[SELECT * FROM players WHERE teamid = ]] .. teamid 
			.. [[ AND posType = "SS" AND injury = 0 ]] .. extraQuery .. [[ ORDER BY overall DESC;]])do
			short = row;
			alreadyTaken[#alreadyTaken+1] = row.id
			extraQuery = extraQuery .. [[ AND id != ]] .. row.id
			break;
		end
	end
	if (third == nil) then
		for row in db:nrows([[SELECT * FROM players WHERE teamid = ]] .. teamid 
			.. [[ AND posType = "3B" AND injury = 0 ]] .. extraQuery .. [[ ORDER BY overall DESC;]])do
			third = row;
			alreadyTaken[#alreadyTaken+1] = row.id
			extraQuery = extraQuery .. [[ AND id != ]] .. row.id
			break;
		end
	end
	if (catcher == nil) then
		for row in db:nrows([[SELECT * FROM players WHERE teamid = ]] .. teamid 
			.. [[ AND posType = "C" AND injury = 0 ]] .. extraQuery .. [[ ORDER BY overall DESC;]])do
			catcher = row;
			alreadyTaken[#alreadyTaken+1] = row.id
			extraQuery = extraQuery .. [[ AND id != ]] .. row.id
			break;
		end
	end
	if (ofs[1] == nil or ofs[2] == nil or ofs[3] == nil) then
		
		local availableOutfielders = {}
		local neededOutfielders = 3;
		for i = 1, 3 do
			if (ofs[i] ~= nil) then
				neededOutfielders = neededOutfielders - 1
			end
		end
		
		for row in db:nrows([[SELECT * FROM (SELECT * FROM players WHERE teamid = ]] .. teamid .. 
			[[ AND posType = "OF" AND injury = 0 ]] .. extraQuery .. [[ ORDER BY overall DESC LIMIT ]] 
			.. neededOutfielders .. [[) ORDER BY speed DESC;]])do
			--Get the top three outfielders by overall
			--These outfielders are sorted by speed, in descending order
			--Fastest = CF;   2nd = RF;   3rd = LF
			availableOutfielders[#availableOutfielders+1] = row
			alreadyTaken[#alreadyTaken+1] = row.id
			extraQuery = extraQuery .. [[ AND id != ]] .. row.id
		end
		
		--Populate the remaining outfield slots with available outfielders
		for i = 1, 3 do
			if (ofs[i] == nil) then
				ofs[i] = availableOutfielders[1]
				table.remove(availableOutfielders, 1);
			end
		end
	end
	if (bench[1] == nil or bench[2] == nil or bench[3] == nil or bench[4] == nil) then
	--Choose DH, batter with the best overall after all the starters
	--Also form bench of batters

	local query = [[SELECT * FROM players WHERE teamid = ]] .. teamid .. 
		[[ AND posType != "RP" AND posType != "SP" AND injury = 0]] .. extraQuery .. [[ ORDER BY overall DESC;]];
	
	for row in db:nrows(query)do
		for i = 1, 4 do
			if (bench[i] == nil) then
				bench[i] = row;
				break;
			end
		end
	end
	
	end
	dh = bench[1]
	table.remove(bench,1);
	if (sp == nil) then
		for row in db:nrows([[SELECT * FROM players WHERE teamid = ]] .. teamid .. [[ AND posType = "SP" AND injury = 0 AND days_rest >= 5 ORDER BY overall DESC;]])do
			sp = row;
			break
		end
	end
	if (rps[1] == nil or rps[2] == nil or rps[3] == nil or rps[4] == nil or rps[5] == nil or rps[6] == nil) then
		
		local query = [[SELECT * FROM players WHERE teamid = ]] .. teamid .. [[ AND posType = "RP" AND injury = 0]]
		for i = 1, #alreadyTaken do
			--Exclude the players already taken from the query
			if (alreadyTaken[i] ~= nil) then
			query = query .. [[ AND id != ]] .. alreadyTaken[i]
			end
		end
		query = query .. [[ ORDER BY overall DESC;]];
		
		
		
		for row in db:nrows(query)do
			for i = 1, 6 do
				if (rps[i] == nil) then
					rps[i] = row;
					break;
				end
			end
		end
		
	end
	closer = rps[1]
	table.remove(rps,1);
	
	--If not enough active players, return a nil lineup
	if (bench[1] == nil or bench[2] == nil or bench[3] == nil or dh == nil) then
		return nil
	end
	if (first == nil or second == nil or short == nil or third == nil or 
		catcher == nil or ofs[3] == nil or ofs[1] == nil or ofs[2] == nil or 
		sp == nil or closer == nil or rps[1] == nil or
		rps[2] == nil or rps[3] == nil or rps[4] == nil or rps[5] == nil) then
		return nil
	end
	
	--Determine the batting order - Add the additional .batting_order property to each of the batter's info
	local batters = {first, second, short, third, catcher, ofs[3], ofs[1], ofs[2],dh}
	for i = 9, 1, -1 do
		if (customLineup[i].batting_order ~= "CPU") then
			batters[i].batting_order = tonumber(customLineup[i].batting_order);
			table.remove(batters,i);
		end
	end
	

	local availableBattingOrders = {true,true,true,true,true,true,true,true,true}
	
	--Determine available batting orders left for cpu to assign after checking with the custom lineup's batting order
	for i = 1, 9 do
		if (customLineup[i].batting_order ~= "CPU") then --Batting order not for CPU to determine
			availableBattingOrders[tonumber(customLineup[i].batting_order)] = false;
		end
	end
	
	print("Available orders: " .. json.encode(availableBattingOrders));
	
	--3 - Greatest contact + power (Greater priority over 1 & 2 holes)
	if (availableBattingOrders[3] ) then
	local total, index = 0, 1;
	for i = 1, #batters do
		local sum = batters[i].contact + batters[i].power
		if (sum > total) then
			total = sum
			index = i
		end
	end
	batters[index].batting_order = 3; --This property is not saved to database because it may be different each game
	table.remove(batters, index);
	end
	
	--4 - Greatest contact + power
	if (availableBattingOrders[4] ) then
	local total, index = 0, 1;
	for i = 1, #batters do
		local sum = batters[i].contact + batters[i].power
		if (sum > total) then
			total = sum
			index = i
		end
	end
	batters[index].batting_order = 4; --This property is not saved to database because it may be different each game
	table.remove(batters, index);
	end
	
	--5 - Greatest contact + power
	if (availableBattingOrders[5] ) then
	local total, index = 0, 1;
	for i = 1, #batters do
		local sum = batters[i].contact + batters[i].power
		if (sum > total) then
			total = sum
			index = i
		end
	end
	batters[index].batting_order = 5; --This property is not saved to database because it may be different each game
	table.remove(batters, index);
	end
	
	--1 - Greatest contact + eye
	if (availableBattingOrders[1] ) then
	local total, index = 0, 1;
	for i = 1, #batters do
		local sum = batters[i].contact + batters[i].eye
		if (sum > total) then
			total = sum
			index = i
		end
	end
	batters[index].batting_order = 1; --This property is not saved to database because it may be different each game
	table.remove(batters, index);
	end
	
	--2 - Greatest contact + eye
	if (availableBattingOrders[2] ) then
	local total, index = 0, 1;
	for i = 1, #batters do
		local sum = batters[i].contact + batters[i].eye
		if (sum > total) then
			total = sum
			index = i
		end
	end
	batters[index].batting_order = 2; --This property is not saved to database because it may be different each game
	table.remove(batters, index);
	end
	
	--6 - Greatest contact + power + eye
	if (availableBattingOrders[6] ) then
	local total, index = 0, 1;
	for i = 1, #batters do
		local sum = batters[i].contact + batters[i].power + batters[i].eye
		if (sum > total) then
			total = sum
			index = i
		end
	end
	batters[index].batting_order = 6; --This property is not saved to database because it may be different each game
	table.remove(batters, index);
	end
	
	--7 - Greatest contact + power + eye
	if (availableBattingOrders[7] ) then
	local total, index = 0, 1;
	for i = 1, #batters do
		local sum = batters[i].contact + batters[i].power + batters[i].eye
		if (sum > total) then
			total = sum
			index = i
		end
	end
	batters[index].batting_order = 7; --This property is not saved to database because it may be different each game
	table.remove(batters, index);
	end
	
	--8 - Greatest contact + power + eye
	if (availableBattingOrders[8] ) then
	local total, index = 0, 1;
	for i = 1, #batters do
		local sum = batters[i].contact + batters[i].power + batters[i].eye
		if (sum > total) then
			total = sum
			index = i
		end
	end
	batters[index].batting_order = 8; --This property is not saved to database because it may be different each game
	table.remove(batters, index);
	end
	
	--9 - Greatest contact + power + eye
	if (availableBattingOrders[9] ) then
	local total, index = 0, 1;
	for i = 1, #batters do
		local sum = batters[i].contact + batters[i].power + batters[i].eye
		if (sum > total) then
			total = sum
			index = i
		end
	end
	batters[index].batting_order = 9; --This property is not saved to database because it may be different each game
	table.remove(batters, index);
	end
	
	


	return {first = first, second = second, short = short, third = third, catcher = catcher, left = ofs[3], 
	center = ofs[1], right = ofs[2],  dh = dh, bullpen = rps, closer = closer, sp = sp, bench = bench}
end

--Print the table generated by generateLineup()
function lineupGenerator:printLineup(lineup)
	
	print("_____________________________");
	print("_____________________________");
	print("1B: " ..lineup.first.name);
	print("2B: " ..lineup.second.name);
	print("SS: " ..lineup.short.name);
	print("3B: " ..lineup.third.name);
	print("C: " ..lineup.catcher.name);
	print("LF: " ..lineup.left.name);
	print("CF: " ..lineup.center.name);
	print("RF: " ..lineup.right.name);
	print("DH: " ..lineup.dh.name);
	print("***BENCH**********************");
	for i = 1, #lineup.bench do
		print("PH: " ..lineup.bench[i].name); --Pinch hitter
	end
	print("***BULLPEN********************");
	for i = 1, #lineup.bullpen do
		print("RP: " ..lineup.bullpen[i].name);
	end
	print("CL: " .. lineup.closer.name);
	print("SP: " .. lineup.sp.name);

end

return lineupGenerator;
