local sqlite3 = require "sqlite3"
local json = require("json");
local pg = require("simulatorCore.playerGenerator");
local fa = require("simulatorCore.freeAgents");
local pd = require("simulatorCore.playerDevelopment");
local sg = require("simulatorCore.scheduleGenerator");
local at = require("simulatorCore.attendance");
local tv = require("simulatorCore.tv");
local ads = require( "ads" )
local pMsg = require("menuCore.pushMessage")

local seasonSimulator = {
	--Money given to each team after regular season
	--This is particularly helpful to smaller market teams
	competitiveBalanceMoney = 30000000,
	
	adInfo = {
		-- The name of the ad provider.
		provider = "admob",
		-- Your application ID
		appID = "ca-app-pub-2195505829394880/3390416657",
		appIDInterstitial = "ca-app-pub-2195505829394880/3043836253",
	},
}

function seasonSimulator:nextDay(extraArg)
	
	local mode = "Season"
	local day = 1;
	local year = 2000;
	local playerTeamid = 1;
	local profitGoal = 0
	local autoSign = false
	
	local path = system.pathForFile("data.db", system.DocumentsDirectory)
	db = sqlite3.open( path ) 
	
	--Get the league's current mode (Either Season, Playoffs, Draft, Free Agency)
	for row in db:nrows([[SELECT * FROM league;]])do
		mode = row.mode
		day = row.day
		year = row.year
	end
	for row in db:nrows([[SELECT * FROM myteam;]])do
		playerTeamid, profitGoal = row.teamid, row.profitGoal
	end
	for row in db:nrows([[SELECT * FROM settings;]])do
		if (row.autoSign == 1) then autoSign = true
		else autoSign = false end
	end
	
	
	db:exec("BEGIN TRANSACTION;")	
	
	--Next day
	if (day == 162 and mode == "Season") then
		
		--Competitive balance, after each season, each team earns extra
		--This is particularly helpful to smaller market teams
		local stmt = db:prepare[[UPDATE teams SET money = money + ?]];
		stmt:bind_values(seasonSimulator.competitiveBalanceMoney) 
		stmt:step();
		--TV Revenue
		for row in db:nrows([[SELECT * FROM teams;]])do
			local stmt = db:prepare[[UPDATE teams SET money = money + ? WHERE id = ?]];
			stmt:bind_values(tv:determineTVRevenue(row.population), row.id) 
			stmt:step();
		end
		
		db:exec([[UPDATE league SET day = 1, mode = "Season Awards";]])
		seasonSimulator:generateSeasonAwards();
		if (seasonSimulator:checkWinGoal(playerTeamid)) then
			--Met season goals
			local function show()
				local message = 
				[[
				Congratulations on meeting your season goal in wins.
				Keep up the good work!
				]]
				pMsg:showMessage(pMsg:newMessage("Owner", message))
			end
			timer.performWithDelay(500,show) --Little delay allows user to see animation of message
		else 
			--Failed season goals
			local function show()
				local message = 
				[[
				You have failed to achieve the goals I set for the season.
				You are not suitable to be a general manager. Sorry.
				]]
				pMsg:showMessage(pMsg:newMessage("Owner", message))
			end
			timer.performWithDelay(500,show) --Little delay allows user to see animation of message
		end
	elseif (mode == "Season") then
		--Increment the day
		db:exec([[UPDATE league SET day = day + 1;]])
	elseif (mode == "Season Awards") then
		seasonSimulator:recordStats("Season", year);
		seasonSimulator:startPlayoffs();
		seasonSimulator:updatePlayoffsSchedule();
	elseif (mode == "Playoffs Awards") then
		seasonSimulator:recordStats("Playoffs", year);
		seasonSimulator:recordTeamHistory(year);
		seasonSimulator:recordRatings(year);
		
		seasonSimulator:clearPlayoffs();
		seasonSimulator:nextYear();
		
		db:exec([[UPDATE league SET day = 1, mode = "Draft";]])
		
		db:exec("END TRANSACTION;")
		db:close() --Do database stuff to prepare for generating draft players
		
		--Generate draft players
		pg:generateDraftPlayers()
		
		local path = system.pathForFile("data.db", system.DocumentsDirectory) --Reopen database
		db = sqlite3.open( path )
		db:exec("BEGIN TRANSACTION;")

		--Generate order in which teams pick in the draft
		seasonSimulator:generateDraftOrder()
		--Clear wins and losses of all teams, since draft order has been decided
		db:exec([[UPDATE teams SET win = 0, loss = 0, runsScored = 0, runsAllowed = 0]])
		--Clear myTeam lineup
		seasonSimulator:clearMyTeamLineup();
	elseif (mode == "Playoffs") then
		--Increment the day
		db:exec([[UPDATE league SET day = day + 1;]])
		seasonSimulator:updatePlayoffsSchedule();
	elseif (mode == "Draft") then
		--Increment the day
		if (day == 1) then
			local moneySpentByPlayer = extraArg --Money spent on scouting by player
			seasonSimulator:generateMoneySpent(moneySpentByPlayer,playerTeamid);
			seasonSimulator:generateBigboards()
			seasonSimulator:generateScoutEval(moneySpentByPlayer)
			if (seasonSimulator:checkProfitGoal(playerTeamid)) then
				--Met season goals
				local function show()
					local message = 
					[[
					Congratulations on meeting your season goal for profit.
					Keep up the good work!
					]]
					pMsg:showMessage(pMsg:newMessage("Owner", message))
				end
				timer.performWithDelay(500,show) --Little delay allows user to see animation of message
			else 
				--Failed season goals
				local function show()
					local message = 
					[[
					You didn't make enough money for this team to be viable.
					You are not suitable to be a general manager. Sorry.
					]]
					pMsg:showMessage(pMsg:newMessage("Owner", message))
				end
				timer.performWithDelay(500,show) --Little delay allows user to see animation of message
			end
		elseif (day == 3) then
			--Puts drafted players into their new teams
			seasonSimulator:insertDraftedPlayers(year)
		elseif (day == 4) then
			seasonSimulator:clearDraft()
			db:exec([[UPDATE league SET day = 0, mode = "Free Agency";]])
			--Random interest from 20 - 100
			db:exec([[UPDATE players SET FA_interest = abs(random()%81) + 20 WHERE teamid = 31;]])
			--Show Season goals
			local function show()
				local path = system.pathForFile("data.db", system.DocumentsDirectory) --Reopen database
				db = sqlite3.open( path )
				seasonSimulator:generateSeasonGoals(playerTeamid)
				db:close()
			end
			timer.performWithDelay(500,show) --Little delay allows user to see animation of message
		end
		
		
		db:exec([[UPDATE league SET day = day + 1;]])
	elseif (mode == "Free Agency") then
		--Increment the day
		db:exec([[UPDATE league SET day = day + 1;]])
		db:exec([[UPDATE league SET recent_signings = NULL;]])
		seasonSimulator:teamOfferLogic(playerTeamid);
		seasonSimulator:freeAgentsNextDay();
		if (day == 30) then

			--Force all undecided free agents to sign with teams
			seasonSimulator:forceSign();
			
			--Clear all free agency info
			db:exec([[UPDATE teams SET contract_offers = NULL;]])
			db:exec([[UPDATE players SET FA_offers = NULL, FA_interest = 0;]])
			db:exec([[UPDATE league SET recent_signings = NULL;]])
			
			--Make Sure Each Team Reaches Recommended Roster Size
			for i = 1, 30 do
				if (i ~= playerTeamid or autoSign) then
					seasonSimulator:meetMinRosterReqs(i, 3, 3, 3, 3, 3, 6, 8, 8)
				end
			end
		
			--End of free agency period, start a new season
			db:exec([[UPDATE league SET day = 1, mode = "Season";]])
			
			--Generate new schedule
			local sched = json.encode(sg:generateSchedule2());
			local stmt = db:prepare[[ UPDATE league SET schedule = ?;)]];
			stmt:bind_values(sched) 
			stmt:step();
			
			--Before each season, progress players
			for row in db:nrows([[SELECT id FROM players;]])do
				pd:progressPlayer(row.id);
			end
			
			
			analytics.logEvent("New Year", {year=year})
		
			--Store current money as previous money
			db:exec([[UPDATE teams SET prevMoney = money;]])
			
			--Show Interstitial Ad (Full Screen) @ beginning of every new season
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
			ads.init( seasonSimulator.adInfo.provider, seasonSimulator.adInfo.appIDInterstitial, adListener )
			ads.show( "interstitial", {appId=seasonSimulator.adInfo.appIDInterstitial} )
			
		end
	end
	
	
	--Increase all pitchers days_rest by 1
	db:exec([[UPDATE players SET days_rest = days_rest + 1 WHERE posType = "SP" OR posType = "RP";]])
	
	--For all injured players, decrease injury by 1
	db:exec([[UPDATE players SET injury = injury - 1 WHERE injury > 0;]])
	
	
	--Make sure minimum roster requirements are matched during the season
	if (mode == "Season" or mode == "Playoffs") then
		for i = 1, 30 do
			if (i ~= playerTeamid or autoSign) then
				seasonSimulator:meetMinRosterReqs(i, 2, 2, 2, 2, 2, 5, 5, 6)
			end
		end
	end

	--Every single day - in season, playoffs, or free agency
	--Make sure there are at least 10 free agents at each position
	--If there are no available free agents at a position, generate a free agent at that position 
	--(prevents game from breaking)
	local posTypes = {"1B", "2B", "SS", "3B", "OF", "C", "SP", "RP"}
	for i = 1, #posTypes do
		local count
		for row in db:rows([[SELECT Count(*) FROM players WHERE posType = "]] .. posTypes[i] .. [[" AND teamid = 31;]]) do  
			count = row[1]
		end
		
		if (count < 10) then
			local numToGenerate = 10 - count;
			for n = 1, numToGenerate do
				pg:generateFreeAgent(posTypes[i])
			end
		end
	end
	
	
	
	db:exec("END TRANSACTION;")
	db:close();

end

function seasonSimulator:meetMinRosterReqs(teamid, num1B, num2B, numSS, num3B, numC, numOF, numSP, numRP)

	--Active player requirements (NOT INJURED)
	--At least 1 1B, 1 2B, 1 SS, 1 3B, 1 C, 3 OF, 5 SP, 6 RP healthy @ any moment
	
	
	--Min roster requirements
	local count = 0;
	local query = [[SELECT Count(*) FROM players WHERE teamid = ]] .. teamid .. [[ AND posType = "1B" AND injury = 0]];
	for row in db:rows(query) do  
		count = row[1]
	end
	if (count < num1B) then
		--Not enough first basemen
		for i = 1, num1B-count do
			seasonSimulator:signMinLevelFreeAgent(teamid, "1B");
		end
	end
	
	count = 0;
	query = [[SELECT Count(*) FROM players WHERE teamid = ]] .. teamid .. [[ AND posType = "2B" AND injury = 0]];
	for row in db:rows(query) do  
		count = row[1]
	end
	if (count < num2B) then
		--Not enough second basemen
		for i = 1, num2B-count do
			seasonSimulator:signMinLevelFreeAgent(teamid, "2B");
		end
	end
	
	count = 0;
	query = [[SELECT Count(*) FROM players WHERE teamid = ]] .. teamid .. [[ AND posType = "SS" AND injury = 0]];
	for row in db:rows(query) do  
		count = row[1]
	end
	if (count < numSS) then
		--Not enough SS
		for i = 1, numSS-count do
			seasonSimulator:signMinLevelFreeAgent(teamid, "SS");
		end
	end
	
	count = 0;
	query = [[SELECT Count(*) FROM players WHERE teamid = ]] .. teamid .. [[ AND posType = "3B" AND injury = 0]];
	for row in db:rows(query) do  
		count = row[1]
	end
	if (count < num3B) then
		--Not enough 3B
		for i = 1, num3B-count do
			seasonSimulator:signMinLevelFreeAgent(teamid, "3B");
		end
	end
	
	
	count = 0;
	query = [[SELECT Count(*) FROM players WHERE teamid = ]] .. teamid .. [[ AND posType = "C" AND injury = 0]];
	for row in db:rows(query) do  
		count = row[1]
	end
	if (count < numC) then
		--Not enough C
		for i = 1, numC-count do
			seasonSimulator:signMinLevelFreeAgent(teamid, "C");
		end
	end
	
	count = 0;
	query = [[SELECT Count(*) FROM players WHERE teamid = ]] .. teamid .. [[ AND posType = "OF" AND injury = 0]];
	for row in db:rows(query) do  
		count = row[1]
	end
	if (count < numOF) then
		--Not enough OF
		for i = 1, numOF-count do
			seasonSimulator:signMinLevelFreeAgent(teamid, "OF");
		end
	end
	
	
	count = 0;
	query = [[SELECT Count(*) FROM players WHERE teamid = ]] .. teamid .. [[ AND posType = "SP" AND injury = 0]];
	for row in db:rows(query) do  
		count = row[1]
	end
	if (count < numSP) then
		--Not enough SP
		for i = 1, numSP-count do
			seasonSimulator:signMinLevelFreeAgent(teamid, "SP");
		end
	end
	
	--Needs to be at least one pitcher ready to go (days_rest >= 5)
	count = 0;
	query = [[SELECT Count(*) FROM players WHERE teamid = ]] .. teamid .. [[ AND posType = "SP" AND injury = 0 AND days_rest >= 5]];
	for row in db:rows(query) do  
		count = row[1]
	end
	if (count < 1) then
		--No starting pitcher ready to pitch!
		print("No starting pitcher ready to pitch!");
		seasonSimulator:signMinLevelFreeAgent(teamid, "SP", true);
	end
	
	
	count = 0;
	query = [[SELECT Count(*) FROM players WHERE teamid = ]] .. teamid .. [[ AND posType = "RP" AND injury = 0]];
	for row in db:rows(query) do  
		count = row[1]
	end
	if (count < numRP) then
		--Not enough RP
		for i = 1, numRP-count do
			seasonSimulator:signMinLevelFreeAgent(teamid, "RP");
		end
	end
	
	


end

function seasonSimulator:updatePlayoffsSchedule()

	--Generate each day's schedule in the playoffs
	--This is because the schedule can change depending on who wins
	local playoffs_info
	local playoffs_schedule
	
	local year = 2000
	local day_schedule = {}
	local matchup_index = 1; --Index to assign matchup (Must be unique)
	
	for row in db:nrows([[ SELECT * FROM games ORDER BY id DESC]]) do  
		matchup_index = row.id+1; --Matchup Index 1 greater than previous game
		break;
	end
	
	for row in db:nrows([[ SELECT * FROM league; ]])do
		year = row.year
		playoffs_info = json.decode(row.playoffs_info)
		playoffs_schedule = row.playoffs_schedule
		if (playoffs_schedule == nil) then 
			playoffs_schedule = {} 
		else
			playoffs_schedule = json.decode(playoffs_schedule);
		end
	end
	
	if (playoffs_info.finals ~= nil) then
		--Playoffs (Final Round)
		
		--Add games to the day's schedule, only if matchup has not yet finished
		for i = 1, #playoffs_info.finals do
			local matchup = playoffs_info.finals[i]
			local team1 = matchup[2] --Away
			local team2 = matchup[1] --Home
			
			if (team1.wins < 4 and team2.wins < 4) then
				--If series isn't over, add a game to day's schedule
				day_schedule[#day_schedule+1] = {matchup_id = matchup_index, 
				team1 = playoffs_info.seeds[team1.seed], team2 = playoffs_info.seeds[team2.seed]}
				matchup_index = matchup_index + 1
			end
		end
		
		if (#day_schedule == 0) then
			--If there are no games scheduled, move to the next round

			local champion
			local runnnerup
			
			for i = 1, #playoffs_info.finals do
				local matchup = playoffs_info.finals[i]
				local team1 = matchup[1]
				local team2 = matchup[2]
				if (team1.wins == 4) then
					champion = playoffs_info.seeds[team1.seed]
					runnerup = playoffs_info.seeds[team2.seed]
				else
					champion = playoffs_info.seeds[team2.seed]
					runnerup = playoffs_info.seeds[team1.seed]
				end
			end
			
			--Playoffs over, show awards
			db:exec([[UPDATE league SET mode = "Playoffs Awards";]])
			seasonSimulator:generatePlayoffsAwards(champion, runnerup)

		else
			--There are still games left to be played in this round
			--Append day's schedule onto playoff schedule
			local stmt = db:prepare[[UPDATE league SET playoffs_schedule = ?;]];
			playoffs_schedule[#playoffs_schedule+1] = day_schedule
			stmt:bind_values( json.encode(playoffs_schedule)) 
			stmt:step();
			
		end
		
		

	elseif (playoffs_info.round2 ~= nil) then
		--Playoffs (Second Round)
		
		--Add games to the day's schedule, only if matchup has not yet finished
		for i = 1, #playoffs_info.round2 do
			local matchup = playoffs_info.round2[i]
			local team1 = matchup[2] --Away
			local team2 = matchup[1] --Home
			
			if (team1.wins < 4 and team2.wins < 4) then
				--If series isn't over, add a game to day's schedule
				day_schedule[#day_schedule+1] = {matchup_id = matchup_index, 
				team1 = playoffs_info.seeds[team1.seed], team2 = playoffs_info.seeds[team2.seed]}
				matchup_index = matchup_index + 1
			end
		end
		
		if (#day_schedule == 0) then
			--If there are no games scheduled, move to the next round

			local matchupWinners = {}--[1]Winner of semis 1 [2]Winner of semis 2
			
			for i = 1, #playoffs_info.round2 do
				local matchup = playoffs_info.round2[i]
				local team1 = matchup[1]
				local team2 = matchup[2]
				if (team1.wins == 4) then
					matchupWinners[i] = team1.seed
				else
					matchupWinners[i] = team2.seed
				end
			end
				
			--Add finals to playoffs info
			playoffs_info.finals = 
			{	{{seed=matchupWinners[1], wins=0}, {seed=matchupWinners[2], wins=0}}	}
			
			--Better seeded teams have home field advantage
			for i = 1, #playoffs_info.finals do
				local matchup = playoffs_info.finals[i]
				if (matchup[2].seed < matchup[1].seed) then
					local store = matchup[1].seed
					matchup[1].seed = matchup[2].seed
					matchup[2].seed = store
				end
			end
			
			
			--Record updated playoffs info
			local stmt = db:prepare[[UPDATE league SET playoffs_info = ?;]];
			stmt:bind_values( json.encode(playoffs_info)) 
			stmt:step();
			
			seasonSimulator:updatePlayoffsSchedule()
		else
			--There are still games left to be played in this round
			--Append day's schedule onto playoff schedule
			local stmt = db:prepare[[UPDATE league SET playoffs_schedule = ?;]];
			playoffs_schedule[#playoffs_schedule+1] = day_schedule
			stmt:bind_values( json.encode(playoffs_schedule)) 
			stmt:step();
			
		end
		
		
	elseif (playoffs_info.round1 ~= nil) then
		--Playoffs (First Round)
		
		--Add games to the day's schedule, only if matchup has not yet finished
		for i = 1, #playoffs_info.round1 do
			local matchup = playoffs_info.round1[i]
			local team1 = matchup[2] --Away
			local team2 = matchup[1] --Home
			
			if (team1.wins < 4 and team2.wins < 4) then
				--If series isn't over, add a game to day's schedule
				day_schedule[#day_schedule+1] = {matchup_id = matchup_index, 
				team1 = playoffs_info.seeds[team1.seed], team2 = playoffs_info.seeds[team2.seed]}
				matchup_index = matchup_index + 1
			end
		end
		
		if (#day_schedule == 0) then
			--If there are no games scheduled, move to the next round

			local matchupWinners = {}--[1]Winner of 1,8  [2]Winner of 2,7  [3]Winner of 3,6  [4]Winner of 4,5
			
			for i = 1, #playoffs_info.round1 do
				local matchup = playoffs_info.round1[i]
				local team1 = matchup[1]
				local team2 = matchup[2]
				if (team1.wins == 4) then
					matchupWinners[i] = team1.seed
				else
					matchupWinners[i] = team2.seed
				end
			end
				
			--Add round 2 to playoffs info
			playoffs_info.round2 = 
			{	{{seed=matchupWinners[1], wins=0}, {seed=matchupWinners[4], wins=0}},
			{{seed=matchupWinners[2], wins=0}, {seed=matchupWinners[3], wins=0}}	}
			
			--Better seeded teams have home field advantage
			for i = 1, #playoffs_info.round2 do
				local matchup = playoffs_info.round2[i]
				if (matchup[2].seed < matchup[1].seed) then
					local store = matchup[1].seed
					matchup[1].seed = matchup[2].seed
					matchup[2].seed = store
				end
			end
			
			--Record updated playoffs info
			local stmt = db:prepare[[UPDATE league SET playoffs_info = ?;]];
			stmt:bind_values( json.encode(playoffs_info)) 
			stmt:step();
			
			seasonSimulator:updatePlayoffsSchedule()
		else
			--There are still games left to be played in this round
			--Append day's schedule onto playoff schedule
			local stmt = db:prepare[[UPDATE league SET playoffs_schedule = ?;]];
			playoffs_schedule[#playoffs_schedule+1] = day_schedule
			stmt:bind_values( json.encode(playoffs_schedule)) 
			stmt:step();
			
		end
		
	end
		

end

function seasonSimulator:startPlayoffs()

	--If at the end of the regular season, change mode to playoffs
	db:exec([[UPDATE league SET day = 1, mode = "Playoffs";]])
	db:exec([[DELETE FROM games]]) --Delete all games from the games table
	
	--Generate playoffs_info
	--playoffs_info contains all seeds and round information
	local seeds = {}
	for row in db:nrows([[ SELECT * FROM teams ORDER BY win DESC, runsScored DESC, runsAllowed ASC, RANDOM() LIMIT 8; ]])do
		seeds[#seeds+1] = row.id
	end
	local round1 =
	{{{seed=1,wins=0},{seed=8,wins=0}},
	{{seed=2,wins=0},{seed=7,wins=0}},
	{{seed=3,wins=0},{seed=6,wins=0}},
	{{seed=4,wins=0},{seed=5,wins=0}}}
	local round2, finals = nil, nil;
	
	local playoff_info = {seeds = seeds, round1 = round1, round2 = round2, finals = finals}
	local stmt = db:prepare[[UPDATE league SET playoffs_info = ?;]];
	stmt:bind_values( json.encode(playoff_info)) 
	stmt:step();

end

function seasonSimulator:clearPlayoffs()
	db:exec([[UPDATE league SET playoffs_info = NULL, playoffs_schedule = NULL]])
	db:exec([[DELETE FROM games]]) --Delete all games from the games table
end

function seasonSimulator:clearMyTeamLineup()

	print("Clearing myTeam Lineup");
	
	--At the end of every year, remove players who have left myTeam from myTeam lineup
	local customLineup, teamid
	local playerIds = {} --List of players (their ids) still on the team
	
	for row in db:nrows([[SELECT * FROM myteam;]])do
		customLineup, teamid = row.customLineup, row.teamid;
	end
	
	
	if (customLineup == nil) then return end
	customLineup = json.decode(customLineup);
	
	for row in db:nrows([[SELECT * FROM players WHERE teamid = ]] .. teamid .. [[;]])do
		playerIds[#playerIds+1] = row.id;
	end

	
	--Remove players who have left myTeam
	for i = 1, #customLineup do
		local player = customLineup[i];
		local stillOnTeam = false;
		
		if (player ~= nil) then
		if (player.id ~= nil) then
			for x = 1, #playerIds do
				if (playerIds[x] == player.id) then
					stillOnTeam = true;
					break;
				end
			end
			
			if (not stillOnTeam) then
				if (player.batting_order ~= nil) then
					customLineup[i] = {batting_order = "CPU"}
				else
					customLineup[i] = {}
				end
			end
		end
		end
	
	end
	
	
	--Save cutomLineup after finished
	local stmt= db:prepare[[ UPDATE myteam SET customLineup = ?]];
	stmt:bind_values(json.encode(customLineup)) 
	stmt:step();
end

function seasonSimulator:recordStats(mode, year)

	local path2 = system.pathForFile("previousPlayerStats.db", system.DocumentsDirectory)
	local prevStats_db = sqlite3.open( path2 );
	prevStats_db:exec("BEGIN TRANSACTION;")	
	
	--Record season/playoff stats into previous_stats
	for row in db:nrows([[SELECT * FROM players WHERE GP > 0 or P_GP > 0 or teamid <= 30;]])do
	
		print("ROW ID: " .. row.id);
		
		--Create data table where you record the season's / playoff's stats
		local data;
		for row in prevStats_db:nrows([[SELECT * FROM history WHERE id = ]] .. row.id .. [[;]])do
			data = row.previous_stats;
		end

		if (data == nil) then 
			data = {season = {}, playoffs = {}, ratings = {}} 
		else
			data = json.decode(data)
		end
		
		
		local newData = {}
		newData.teamid, newData.GP, newData.R, newData.GP , newData.AB , newData.R , newData.H , newData.DOUBLES , newData.TRIPLES , newData.HR , newData.RBI , newData.BB ,
		newData.SO , newData.SB , newData.CS , newData.AVG , newData.OBP , newData.SLG , newData.P_GP , newData.P_GS , newData.P_IP , newData.P_H , newData.P_ER , newData.P_HR , newData.P_BB ,
		newData.P_SO , newData.P_W , newData.P_L , newData.P_SV , newData.P_WHIP , newData.P_ERA, newData.DRS =
		row.teamid, row.GP, row.R, row.GP , row.AB , row.R , row.H , row.DOUBLES , row.TRIPLES , row.HR , row.RBI , row.BB ,
		row.SO , row.SB , row.CS , row.AVG , row.OBP , row.SLG , row.P_GP , row.P_GS , row.P_IP , row.P_H , row.P_ER , row.P_HR , row.P_BB ,
		row.P_SO , row.P_W , row.P_L , row.P_SV , row.P_WHIP , row.P_ERA, row.DRS

		newData.year = year
		
		if (mode == "Season") then
			data.season[#data.season+1] = newData
		else
			data.playoffs[#data.playoffs+1] = newData
		end
		
		if (mode == "Playoffs" and (row.GP > 0 or row.P_GP > 0)) then 
		--For playoffs stats to be recorded, there must be > 0 games played
		local stmt = prevStats_db:prepare[[ UPDATE history SET previous_stats = ? WHERE id = ?]];
		local bindResult = stmt:bind_values(json.encode(data), row.id);
		local result = stmt:step();
		elseif (mode == "Season") then
		--For regular season stats to be recorded, must be on a team (GP can equal 0)
		local stmt = prevStats_db:prepare[[ UPDATE history SET previous_stats = ? WHERE id = ?]];
		local bindResult = stmt:bind_values(json.encode(data), row.id);
		local result = stmt:step();
		end
	end
	
	prevStats_db:exec("END TRANSACTION;")
	prevStats_db:close();
	
	--Reset all current stats to 0 to prep for playoffs/ new season
	db:exec[[UPDATE players SET GP = 0, AB = 0, R = 0, H = 0, DOUBLES = 0, TRIPLES = 0, HR = 0, RBI = 0, BB = 0,
		SO = 0, SB = 0, CS = 0, AVG = 0, OBP = 0, SLG = 0, P_GP = 0, P_GS = 0, P_IP = 0, P_H = 0, P_ER = 0, P_HR = 0, P_BB = 0,
		P_SO = 0, P_W = 0, P_L = 0, P_SV = 0, P_WHIP = 0, P_ERA = 0, DRS = 0 ]]

end

function seasonSimulator:recordRatings(year)
	
	--Ratings == Player Attributes
	--This is recorded so user can see progression of player as he ages
	
	local path2 = system.pathForFile("previousPlayerStats.db", system.DocumentsDirectory)
	local prevStats_db = sqlite3.open( path2 );
	prevStats_db:exec("BEGIN TRANSACTION;")	
	
	--Record ratings
	for row in db:nrows([[SELECT * FROM players;]])do
	
		--Create data table where you record the player's ratings
		local data;
		for row in prevStats_db:nrows([[SELECT * FROM history WHERE id = ]] .. row.id .. [[;]])do
			data = row.previous_stats;
		end

		if (data == nil) then 
			data = {season = {}, playoffs = {}, ratings = {}} 
		else
			data = json.decode(data)
		end
		
		
		local newData = {}
		
		--Record pertinent data
		if (row.posType == "SP" or row.posType == "RP") then
		newData.teamid, newData.overall, newData.potential,
			newData.velocity , newData.nastiness , newData.control , newData.stamina , newData.defense=
		row.teamid, row.overall, row.potential, row.velocity , 
			row.nastiness , row.control , row.stamina , row.defense
		else
		newData.teamid, newData.overall, newData.potential, newData.contact, newData.power, newData.eye , newData.speed , 
			 newData.defense =
		row.teamid, row.overall, row.potential, row.contact, row.power, row.eye , row.speed , row.defense
		end

		newData.year = year
		
		data.ratings[#data.ratings+1] = newData
		
		--Record it into database
		local stmt = prevStats_db:prepare[[ UPDATE history SET previous_stats = ? WHERE id = ?]];
		local bindResult = stmt:bind_values(json.encode(data), row.id);
		local result = stmt:step();

	end
	
	prevStats_db:exec("END TRANSACTION;")
	prevStats_db:close();
end

function seasonSimulator:recordTeamHistory(year)
	--Record win-loss record and how deep into playoffs team went
	
	local teams = {}
	local playoffs_info;
	local seeds
	
	for row in db:nrows([[SELECT * FROM league;]])do
		playoffs_info = json.decode(row.playoffs_info)
		seeds = playoffs_info.seeds
	end

	--Record season/playoff stats into previous_stats
	for row in db:nrows([[SELECT * FROM teams;]])do
		local curTeam = #teams+1
		teams[curTeam] = {year = year, win = row.win, loss = row.loss, info = ""}
	end
	
	--Change teams.info to indicate how far into playoffs team got
	for i = 1, #playoffs_info.round1 do
		local matchup = playoffs_info.round1[i]
		local team1 = seeds[matchup[1].seed]
		local team2 = seeds[matchup[2].seed]
		teams[team1].info = "Quarterfinals"
		teams[team2].info = "Quarterfinals"
	end
	for i = 1, #playoffs_info.round2 do
		local matchup = playoffs_info.round2[i]
		local team1 = seeds[matchup[1].seed]
		local team2 = seeds[matchup[2].seed]
		teams[team1].info = "Semifinals"
		teams[team2].info = "Semifinals"
	end
	for i = 1, #playoffs_info.finals do
		local matchup = playoffs_info.finals[i]
		local team1 = seeds[matchup[1].seed]
		local team1_wins = matchup[1].wins
		local team2 = seeds[matchup[2].seed]
		if (team1_wins == 4) then
		teams[team1].info = "Champions"
		teams[team2].info = "Runnerup"
		else
		teams[team2].info = "Champions"
		teams[team1].info = "Runnerup"
		end
	end
	
	--Record team stats into database
	for row in db:nrows([[SELECT * FROM teams;]])do
		local history = {}
		
		if (row.history ~= nil) then
			history = json.decode(row.history)
		end
		
		history[#history+1] = teams[row.id]
		
		local stmt = db:prepare[[ UPDATE teams SET history = ? WHERE id = ?]];
		local bindResult = stmt:bind_values(json.encode(history), row.id);
		local result = stmt:step();
	end
		
	
end

function seasonSimulator:nextYear()
	--Increase age, decrease years, subtract salary from money
	--If years = 0, becomes free agent
	
	
	db:exec([[UPDATE league SET year = year + 1;]])
	
	for row in db:nrows([[SELECT * FROM players WHERE teamid <= 30;]]) do 
		local stmt = db:prepare[[UPDATE teams SET money = money - ? WHERE id = ?;]];
		stmt:bind_values(row.salary, row.teamid) 
		stmt:step();
	end
	
	--Some players retire
	--Open retired players database for transcription
	local path3 = system.pathForFile("retiredPlayers.db", system.DocumentsDirectory)
	retired_db = sqlite3.open( path3 );
	retired_db:exec("BEGIN TRANSACTION;")
	
	for row in db:nrows([[SELECT id FROM players;]])do
		pd:decideRetire(row.id);

	end
	
	retired_db:exec("END TRANSACTION;")	
	retired_db:close();
	
	
	db:exec([[UPDATE players SET years = years - 1, age = age + 1 WHERE teamid <= 30;]])
	db:exec([[UPDATE players SET age = age + 1 WHERE teamid = 31;]])
	
	--Handle new free agents
	for row in db:nrows([[SELECT * FROM players WHERE teamid <= 30 AND years <= 0;]]) do
		local salaryWanted = fa:generateSalaryWanted(row.overall, row.potential, row.posType, row.age);
		local yearsWanted = fa:generateYearsWanted(row.overall, row.potential, row.posType, row.age);
		local mood = fa:generateMood()
		
		local stmt = db:prepare[[UPDATE players SET salary = 0, teamid = 31, FA_salary_wanted = ?, FA_years_wanted = ?, FA_mood = ? WHERE id = ?;]];
		stmt:bind_values(salaryWanted, yearsWanted, mood, row.id) 
		stmt:step();
	end

	
end

--Awards Stuff
function seasonSimulator:generateSeasonAwards()

	local year

	for row in db:nrows([[SELECT * FROM league;]]) do
		year = row.year
	end
	
	--Returns a table of rewards, including award name and player id
	local awards = {}
	
	
	--MVP
	for row in db:nrows(
	[[SELECT * FROM players ORDER BY (DRS * 5 + HR * 5 + RBI * 2 + R * 1.5 + SB * 1 - CS * .5 + BB * 2 + H) DESC LIMIT 1;]])do
		awards[#awards+1] = {id = row.id, award = "MVP", year = year}
	end
	
	--2 All Stars At Each Position (Exceptions 5 SP, 6 OF, 6 RP)
	for row in db:nrows(
	[[SELECT * FROM players WHERE posType = "1B" ORDER BY (DRS * 5 + HR * 5 + RBI * 2 + R * 1.5 + SB * 1 - CS * .5 + BB * 2 + H) DESC LIMIT 2;]])do
		awards[#awards+1] = {id = row.id, award = "1B All Star", year = year}
	end
	for row in db:nrows(
	[[SELECT * FROM players WHERE posType = "2B" ORDER BY (DRS * 5 + HR * 5 + RBI * 2 + R * 1.5 + SB * 1 - CS * .5 + BB * 2 + H) DESC LIMIT 2;]])do
		awards[#awards+1] = {id = row.id, award = "2B All Star", year = year}
	end
	for row in db:nrows(
	[[SELECT * FROM players WHERE posType = "SS" ORDER BY (DRS * 5 + HR * 5 + RBI * 2 + R * 1.5 + SB * 1 - CS * .5 + BB * 2 + H) DESC LIMIT 2;]])do
		awards[#awards+1] = {id = row.id, award = "SS All Star", year = year}
	end
	for row in db:nrows(
	[[SELECT * FROM players WHERE posType = "3B" ORDER BY (DRS * 5 + HR * 5 + RBI * 2 + R * 1.5 + SB * 1 - CS * .5 + BB * 2 + H) DESC LIMIT 2;]])do
		awards[#awards+1] = {id = row.id, award = "3B All Star", year = year}
	end
	for row in db:nrows(
	[[SELECT * FROM players WHERE posType = "C" ORDER BY (DRS * 5 + HR * 5 + RBI * 2 + R * 1.5 + SB * 1 - CS * .5 + BB * 2 + H) DESC LIMIT 2;]])do
		awards[#awards+1] = {id = row.id, award = "C All Star", year = year}
	end
	for row in db:nrows(
	[[SELECT * FROM players WHERE posType = "OF" ORDER BY (DRS * 5 + HR * 5 + RBI * 2 + R * 1.5 + SB * 1 - CS * .5 + BB * 2 + H) DESC LIMIT 6;]])do
		awards[#awards+1] = {id = row.id, award = "OF All Star", year = year}
	end
	--2 == 200, 4 = 0
	--local eraScore = (-100)x+(400)
	--1 == 100, 1.5 = 0
	--local whipScore= (-200)x+(300)
	
	for row in db:nrows(
	[[SELECT * FROM players WHERE P_IP > 150 and posType = "SP" ORDER BY 
		(P_W * 4 - P_L * 2 + P_SO * .5 - P_BB + ((-100)*P_ERA+(400)) +  ((-200)*P_WHIP+(300)) ) DESC LIMIT 5;]])do
		awards[#awards+1] = {id = row.id, award = "SP All Star", year = year}
	end
	
	for row in db:nrows(
	[[SELECT * FROM players WHERE (P_IP > 50 or P_SV >= 20) and posType = "RP" ORDER BY 
		(P_SV * 3 + P_SO*2 - P_BB * 2.5 + ((-100)*P_ERA+(400)) +  ((-200)*P_WHIP+(300)) ) DESC LIMIT 6;]])do
		awards[#awards+1] = {id = row.id, award = "RP All Star", year = year}
	end
	
	
	--Gold Gloves
	for row in db:nrows(
	[[SELECT * FROM players WHERE posType = "1B" ORDER BY (DRS) DESC LIMIT 1;]])do
		awards[#awards+1] = {id = row.id, award = "1B Gold Glove", year = year}
	end
	for row in db:nrows(
	[[SELECT * FROM players WHERE posType = "2B" ORDER BY (DRS) DESC LIMIT 1;]])do
		awards[#awards+1] = {id = row.id, award = "2B Gold Glove", year = year}
	end
	for row in db:nrows(
	[[SELECT * FROM players WHERE posType = "SS" ORDER BY (DRS) DESC LIMIT 1;]])do
		awards[#awards+1] = {id = row.id, award = "SS Gold Glove", year = year}
	end
	for row in db:nrows(
	[[SELECT * FROM players WHERE posType = "3B" ORDER BY (DRS) DESC LIMIT 1;]])do
		awards[#awards+1] = {id = row.id, award = "3B Gold Glove", year = year}
	end
	for row in db:nrows(
	[[SELECT * FROM players WHERE posType = "C" ORDER BY (DRS) DESC LIMIT 1;]])do
		awards[#awards+1] = {id = row.id, award = "C Gold Glove", year = year}
	end
	for row in db:nrows(
	[[SELECT * FROM players WHERE posType = "OF" ORDER BY (DRS) DESC LIMIT 1;]])do
		awards[#awards+1] = {id = row.id, award = "OF Gold Glove", year = year}
	end
	for row in db:nrows(
	[[SELECT * FROM players WHERE posType = "SP" ORDER BY (DRS) DESC LIMIT 1;]])do
		awards[#awards+1] = {id = row.id, award = "SP Gold Glove", year = year}
	end
	for row in db:nrows(
	[[SELECT * FROM players WHERE posType = "RP" ORDER BY (DRS) DESC LIMIT 1;]])do
		awards[#awards+1] = {id = row.id, award = "RP Gold Glove", year = year}
	end
	
	
	
	
	--Home Run King
	for row in db:nrows(
	[[SELECT * FROM players WHERE HR = (SELECT max(HR) FROM players);]])do
		awards[#awards+1] = {id = row.id, award = "Home Run King", year = year}
	end
	
	--Strikeout King
	for row in db:nrows(
	[[SELECT * FROM players WHERE P_SO = (SELECT max(P_SO) FROM players);]])do
		awards[#awards+1] = {id = row.id, award = "Strikeout King", year = year}
	end

	
	--For each award, add it to the corresponding player's awards list (trophy case!)
	for i = 1, #awards do
		local award = awards[i]
		
		
		--Retrieve player's existing trophy case
		local trophyCase
		for row in db:nrows([[SELECT * FROM players WHERE id = ]] .. award.id .. [[;]])do
			trophyCase = row.awards
		end
		if (trophyCase == nil) then
			trophyCase = {}
		else
			trophyCase = json.decode(trophyCase)
		end
		
		--Add award to collection
		trophyCase[#trophyCase+1] = {award = award.award, year = award.year}
		
		--Update trophy case in database
		local stmt = db:prepare([[UPDATE players SET awards = ? WHERE id = ]] .. award.id .. [[;]]);
		stmt:bind_values( json.encode(trophyCase)) 
		stmt:step();
	end
	
	--Add all awards to the awards table (Collection of all award in league history
	for i = 1, #awards do
		local award = awards[i]
		
		local stmt = db:prepare[[INSERT INTO awards (id, year, type, award, playerid) VALUES(NULL,?,"Season",?,?);]];
		stmt:bind_values( award.year,award.award,award.id) 
		stmt:step();
		
	end
	
	

end

function seasonSimulator:generatePlayoffsAwards(champion, runnerup)

	local year

	for row in db:nrows([[SELECT * FROM league;]]) do
		year = row.year
	end
	
	--Returns a table of rewards, including award name and player id
	local awards = {}
	
	--Champion
	local stmt = db:prepare[[INSERT INTO awards (id, year, type, award, teamid) VALUES(NULL,?,"Playoffs",?,?);]];
	stmt:bind_values( year,"Champions",champion) 
	stmt:step();
	
	--Runnerup
	local stmt = db:prepare[[INSERT INTO awards (id, year, type, award, teamid) VALUES(NULL,?,"Playoffs",?,?);]];
	stmt:bind_values( year,"Runnerup",runnerup) 
	stmt:step();
	
	--Golden Slugger
	for row in db:nrows(
	[[SELECT * FROM players ORDER BY (HR * 5 + RBI * 2 + R * 1.5 + SB * 2 + BB * 2 + H) DESC LIMIT 1;]])do
		awards[#awards+1] = {id = row.id, award = "Golden Batter", year = year}
	end
	
	--Golden Pitcher
	for row in db:nrows(
	[[SELECT * FROM players WHERE P_IP > 10 and posType = "SP" ORDER BY 
		(P_W * 4 - P_L * 2 + P_SV + P_SO * .5 - P_BB + ((-100)*P_ERA+(400)) +  ((-200)*P_WHIP+(300)) ) DESC LIMIT 1;]])do
		awards[#awards+1] = {id = row.id, award = "Golden Pitcher", year = year}
	end
	
	
	
	
	--For each award, add it to the corresponding player's awards list (trophy case!)
	for i = 1, #awards do
		local award = awards[i]
		
		
		--Retrieve player's existing trophy case
		local trophyCase
		for row in db:nrows([[SELECT * FROM players WHERE id = ]] .. award.id .. [[;]])do
			trophyCase = row.awards
		end
		if (trophyCase == nil) then
			trophyCase = {}
		else
			trophyCase = json.decode(trophyCase)
		end
		
		--Add award to collection
		trophyCase[#trophyCase+1] = {award = award.award, year = award.year}

		--Update trophy case in database
		local stmt = db:prepare([[UPDATE players SET awards = ? WHERE id = ]] .. award.id .. [[;]]);
		stmt:bind_values( json.encode(trophyCase)) 
		stmt:step();
	end
	
	--For every player who played for the champions, add the special champion award
	for row in db:nrows(
	[[SELECT * FROM players WHERE teamid = ]] .. champion ..[[;]])do
	
		local trophyCase
		trophyCase = row.awards
		if (trophyCase == nil) then
			trophyCase = {}
		else
			trophyCase = json.decode(trophyCase)
		end
		
		trophyCase[#trophyCase+1] = {award = "Champion", year = year}
		
		local stmt = db:prepare([[UPDATE players SET awards = ? WHERE id = ]] .. row.id .. [[;]]);
		stmt:bind_values( json.encode(trophyCase)) 
		stmt:step();
	end
	
	--For every player who played for the runnerups, add the special runnerup award
	for row in db:nrows(
	[[SELECT * FROM players WHERE teamid = ]] .. runnerup ..[[;]])do
	
		local trophyCase
		trophyCase = row.awards
		if (trophyCase == nil) then
			trophyCase = {}
		else
			trophyCase = json.decode(trophyCase)
		end
		
		trophyCase[#trophyCase+1] = {award = "Runnerup", year = year}
		
		local stmt = db:prepare([[UPDATE players SET awards = ? WHERE id = ]] .. row.id .. [[;]]);
		stmt:bind_values( json.encode(trophyCase)) 
		stmt:step();
	end
	
	
	--Add all awards to the awards table (Collection of all award in league history
	for i = 1, #awards do
		local award = awards[i]
		
		local stmt = db:prepare[[INSERT INTO awards (id, year, type, award, playerid) VALUES(NULL,?,"Playoffs",?,?);]];
		stmt:bind_values( award.year,award.award,award.id) 
		stmt:step();
		
	end
	
	

end

--Draft Stuff
function seasonSimulator:generateDraftOrder()
	
	print("GENERATING DRAFT ORDER");
	local standings = {} --Standings, from least wins to most wins
	
	for row in db:nrows([[SELECT * FROM teams ORDER BY win ASC, runsScored ASC, runsAllowed DESC, RANDOM(); ]]) do 
		standings[#standings+1] = row.id;
	end
	
	local order = {}
	
	for i = 1, 3 do --3 rounds worth of draft picks
		for x = 1, #standings do
			order[#order+1] = standings[x]
		end
	end
	
	local stmt = db:prepare[[UPDATE draft SET draft_selections = ?]];
	stmt:bind_values(json.encode(order)) 
	stmt:step();
	print("FINISHED GENERATING DRAFT ORDER");
	

end

function seasonSimulator:generateMoneySpent(player_moneySpent, player_teamid)

	local moneySpent = {}
	
	for row in db:nrows([[SELECT * FROM teams ORDER BY id ASC; ]]) do 
		local maxMoney = row.money * .01;
		if(maxMoney>5000000)then maxMoney=5000000 
		elseif (maxMoney<0) then maxMoney=0
		end
		local minMoney = 0;
		
		local money = math.random(minMoney,maxMoney);
		
		money = 500000 * math.floor((money + 250000) / 500000); --Round money to the nearest 500000
		moneySpent[#moneySpent+1] = money

	end
	
	moneySpent[player_teamid] = player_moneySpent
	
	for i = 1, #moneySpent do
		--Subtract the money spent from team's total money
		local stmt = db:prepare[[UPDATE teams SET money = money - ? WHERE id = ?]];
		stmt:bind_values(moneySpent[i], i) 
		stmt:step();
	end
	
	local stmt = db:prepare[[UPDATE draft SET money_spent = ?]];
	stmt:bind_values(json.encode(moneySpent)) 
	stmt:step();
	
end

function seasonSimulator:generateBigboards()
	print("Ho ho ho3");
	--Generate big boards for all teams based on money they spent on scouting
	local bigBoards = {}
	
	--Get money spent by each team
	local moneySpent = {}
	for row in db:nrows([[SELECT * FROM draft; ]]) do
		moneySpent = json.decode(row.money_spent)
	end
	
	 --Get actual playerScore of all draft prospects
	local playerScores = {}
	for row in db:nrows([[SELECT * FROM draft_players ORDER BY id ASC; ]]) do
		playerScores[#playerScores+1] = pg:generatePlayerScore(row.overall, row.potential, row.age, row.posType)
	end
	
	--Create big board for each team by adding appropriate fuzz to playerScores
	for i = 1, #moneySpent do

		--Setup bigboard
		local bigBoard = {}	
	
		local moneySpentByTeam = moneySpent[i] / 500000 --Should range from 0 to 10
		
		--Create copy of playerScores
		local playerScoresCopy = {}
		for x = 1, #playerScores do
			playerScoresCopy[x] = {id = x, score = playerScores[x]}
		end
		
		--Add fuzz to playerScoresCopy
		for x = 1, #playerScoresCopy do
			
			local fuzz = 1
			
			--0 = 60% Accurate, 10 = 90% Accurate
			local num = 3*moneySpentByTeam+60
			
			if (num >= math.random(1,100)) then
				--Accurate, leave fuzz @ 1
			else
				--Inaccurate
				--0 = 50% Slightly Inaccurate  10 = 80% chance slightly inaccurate
				local num2 = 3*moneySpentByTeam+50
				
				if (num2 >= math.random(1,100)) then
					--Slightly inaccurate
					fuzz = math.random(9,11)*.1
				else
					--Very inaccurate
					fuzz = math.random(7,13)*.1
				end
				
			end
			
			playerScoresCopy[x].score = playerScoresCopy[x].score * fuzz
		
		end
		
		--Sort playerScores high to low
		function byval(a,b)
			--Sorts high to low
			return a.score > b.score
		end
		table.sort(playerScoresCopy,byval)
		
		--Add playerids to bigBoard, sorted by playerScore
		for x = 1, #playerScoresCopy do
			bigBoard[#bigBoard+1] = playerScoresCopy[x].id
		end
		
		--Add bigBoard to list of bigBoards
		bigBoards[#bigBoards+1] = bigBoard
	end
	
	--Record big boards to database
	local stmt = db:prepare[[UPDATE draft SET big_boards = ?]];
	stmt:bind_values(json.encode(bigBoards)) 
	stmt:step();
	
	
	--Print actual big board for debugging
	
	--[[print("ACTUAL BIG BOARD:")
	print("----------------------")
	--Create copy of playerScores
	local playerScoresCopy = {}
	for x = 1, #playerScores do
		playerScoresCopy[x] = {id = x, score = playerScores[x]}
	end
	
	--Sort playerScores high to low
	function byval(a,b)
		--Sorts high to low
		return a.score > b.score
	end
	table.sort(playerScoresCopy,byval)
	
	for i = 1, #playerScoresCopy do
		print("Player ID: " .. playerScoresCopy[i].id .. "  Score: " .. playerScoresCopy[i].score);
	end
	]]--
end

function seasonSimulator:generateScoutEval(player_moneySpent)
	
	local moneySpent = player_moneySpent / 500000 --Should range from 0 to 10
	
	--Generate the scout evaluation for player's team based on amount of money spent by players team
	local scoutingReports = {}
	
	 --Get actual playerScore of all draft prospects
	local players = {}
	for row in db:nrows([[SELECT * FROM draft_players ORDER BY id ASC; ]]) do
		players[#players+1] = row
	end
	
	local function numberToGrade(num)
		if (num >= 90) then return "A+"
		elseif (num >= 80) then return "A"
		elseif (num >= 70) then return "B+"
		elseif (num >= 60) then return "B"
		elseif (num >= 55) then return "C+"
		elseif (num >= 50) then return "C"
		elseif (num >= 40) then return "D+"
		elseif (num >= 30) then return "D"
		elseif (num >= 15) then return "F+"
		else return "F"	end
	end
	
	local function generateFuzz()
		local fuzz = 1
			
		--0 = 50% Accurate, 10 = 80% Accurate
		local num = 3*moneySpent+50
		
		if (num >= math.random(1,100)) then
			--Accurate, leave fuzz @ 1
		else
			--Inaccurate
			--0 = 50% Slightly Inaccurate  10 = 80% chance slightly inaccurate
			local num2 = 3*moneySpent+50
			
			if (num2 >= math.random(1,100)) then
				--Slightly inaccurate
				fuzz = math.random(9,11)*.1
			else
				--Very inaccurate
				fuzz = math.random(7,13)*.1
			end
			
		end
		return fuzz
	
	end
	
	for i = 1, #players do
		local scoutingReport = {}
		local player = players[i]
		local overall, potential, nastiness, velocity, control, contact, power, eye, stamina, speed, defense, iq, durability

		
		overall = numberToGrade(player.overall * generateFuzz())
		potential = numberToGrade(player.potential * generateFuzz())
		nastiness = numberToGrade(player.nastiness * generateFuzz())
		velocity = numberToGrade(player.velocity * generateFuzz())
		control = numberToGrade(player.control * generateFuzz())
		contact = numberToGrade(player.contact * generateFuzz())
		power = numberToGrade(player.power * generateFuzz())
		eye = numberToGrade(player.eye * generateFuzz())
		stamina = numberToGrade(player.stamina * generateFuzz())
		speed = numberToGrade(player.speed * generateFuzz())
		defense = numberToGrade(player.defense * generateFuzz())
		iq = numberToGrade(player.iq * generateFuzz())
		durability = numberToGrade(player.durability * generateFuzz())
		
		scoutingReport = {overall = overall, potential = potential, nastiness = nastiness, 
			velocity = velocity, control = control,  contact = contact, power = power, eye = eye, 
			stamina = stamina, speed = speed, defense = defense, iq = iq, durability = durability}
			
		scoutingReports[#scoutingReports+1] = scoutingReport
	end
		
	local stmt = db:prepare[[UPDATE draft SET scout_eval = ?]];
	stmt:bind_values(json.encode(scoutingReports)) 
	stmt:step();
	
	for i = 1, #scoutingReports do
		local report = scoutingReports[i]
		local stmt = db:prepare[[UPDATE draft_players SET evalOverall = ?, evalPotential = ? WHERE id = ?]];
		stmt:bind_values(report.overall, report.potential, i); 
		stmt:step();
	end
	
	
end

function seasonSimulator:cpuDraft()
	
	local numDraftedAlready = 0;
	local currentPick = 0;
	local draft_selections = {}
	local myteamid = 0;
	local bigboards = {}
	
	local path = system.pathForFile("data.db", system.DocumentsDirectory)
	db = sqlite3.open( path ) 
	db:exec("BEGIN TRANSACTION");
	

	for row in db:rows([[SELECT Count(*) FROM draft_players WHERE teamid IS NOT NULL]]) do
		numDraftedAlready = row[1] 
		currentPick = numDraftedAlready + 1
	end
	for row in db:nrows([[SELECT * FROM draft]]) do
		draft_selections = json.decode(row.draft_selections)
		bigboards = json.decode(row.big_boards)
	end
	for row in db:nrows([[SELECT * FROM myteam]]) do
		myteamid = row.teamid
	end

	
	--Cpu make multiple picks, either until player's turn or end of draft
	for i = currentPick, #draft_selections do
		currentPick = currentPick + 1
		local curTeam = draft_selections[i]
		
		--If it's the players turn to draft, break cpuDraft to allow user to choose prospect
		if (myteamid == curTeam) then break end
		
		local teambigboard = bigboards[curTeam]
		
		--Loop through bigboard to find top available prospect
		for x = 1, #teambigboard do
			local prospectid = teambigboard[x]
			local available = false
			
			for row in db:nrows([[SELECT * FROM draft_players WHERE id = ]] .. prospectid .. [[;]]) do
				if (row.teamid == nil) then available = true end
			end
			
			if (available) then --Draft player
				local stmt = db:prepare[[UPDATE draft_players SET teamid = ?, draftPos = ? WHERE id = ?]];
				stmt:bind_values(curTeam, i, prospectid) 
				stmt:step();
				break;
			end
			
		end
		
	
	end
	
	db:exec("END TRANSACTION");
	db:close()
	
	return currentPick --Returns current pick that cpuDraft has stopped on

end

function seasonSimulator:playerDraft(prospectid)
	
	local numDraftedAlready = 0;
	local currentPick = 0;
	local myteamid
	
	local path = system.pathForFile("data.db", system.DocumentsDirectory)
	db = sqlite3.open( path ) 
	
	for row in db:nrows([[SELECT * FROM myteam]]) do
		myteamid = row.teamid
	end
	for row in db:rows([[SELECT Count(*) FROM draft_players WHERE teamid IS NOT NULL]]) do
		numDraftedAlready = row[1] 
		currentPick = numDraftedAlready + 1
	end
	
	local stmt = db:prepare[[UPDATE draft_players SET teamid = ?, draftPos = ? WHERE id = ?]];
	stmt:bind_values(myteamid, currentPick, prospectid) 
	stmt:step();
	
	
	
	db:close();
	
	
	

end

function seasonSimulator:clearDraft()
	
	db:exec([[DELETE FROM draft_players]]) --Delete all prospects from draft_players
	db:exec([[UPDATE draft SET draft_selections = NULL, money_spent = NULL, scout_eval = NULL, big_boards = NULL]])

end

function seasonSimulator:insertDraftedPlayers(year)
	
	local path2 = system.pathForFile("previousPlayerStats.db", system.DocumentsDirectory)
	local prevStats_db = sqlite3.open( path2 );
	prevStats_db:exec("BEGIN TRANSACTION;")	
	
	for row in db:nrows([[SELECT * FROM draft_players; ]]) do
		
		local prospectid = row.id
		local salary,years,teamid,fa_salary_wanted,fa_years_wanted
		
		local draftInfo = year .. " Undrafted";
		local transactionInfo

		if (row.teamid ~= nil) then
			--Drafted
			salary = seasonSimulator:getDraftSalary(row.draftPos)
			years = 5; --Prospects signed for 5 years
			teamid = row.teamid;
			fa_salary_wanted = 0
			fa_years_wanted = 0
			
			local currentPick = row.draftPos
			local round = math.ceil(currentPick / 30)
			local pick = currentPick - math.floor(currentPick / 30) * 30
			if (pick == 0) then pick = 30 end
			local text = "Round " .. round .. " Pick " .. pick
			draftInfo = year .. " " .. text
			for row in db:nrows([[SELECT * FROM teams WHERE id = ]] .. row.teamid .. [[;]]) do
				transactionInfo = "Drafted by " .. row.abv .. " (" .. year .. ")"
			end
		else
			--Free Agent
			salary = 0
			years = 0
			teamid = 31
			fa_salary_wanted = fa:generateSalaryWanted(row.overall, row.potential, row.posType, row.age);
			fa_years_wanted = 1
			transactionInfo = "Unrafted" .. " (" .. year .. ")"
		end
		
		--Insert prospect into players_database
		local insertQuery = [[INSERT INTO players VALUES ]] .. [[(NULL, ]] .. 
		teamid.. [[,]] .. [["]] .. row.posType.. [["]] .. [[,"]] .. row.name.. [["]] ..
		[[,"]] .. row.hand.. [["]] ..
		[[,]] .. row.age .. 
		[[,]] .. row.contact .. [[,]] .. row.power .. [[,]] .. row.eye .. 
		[[,]] .. row.velocity .. [[,]]  .. row.nastiness ..
		[[,]] .. row.control .. [[,]]  .. row.stamina .. 
		[[,]] .. row.speed .. [[,]] .. row.defense .. 
		[[,]] .. row.durability .. [[,]] .. row.iq ..
		[[,]] .. salary .. [[,]] .. years .. 
		[[,]] .. row.overall .. [[,]] .. row.potential ..
		[[,0,0,0,5,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,NULL,NULL,]] 
		.. fa_salary_wanted .. [[,]] .. fa_years_wanted .. [[,]] .. [[0]] .. [[,NULL,0,"]] .. draftInfo .. [[", "none", NULL);]]

		db:exec(insertQuery);
		
		--Insert playerid into draft_prospects so the prospect can refer to itself in the players_database
		--Also add corresponding player to previousStats db to track stats from previous seasons
		for row in db:rows([[SELECT last_insert_rowid();]]) do
			local playerid = row[1]
			--print("playerid: " .. playerid);
			local stmt = db:prepare[[UPDATE draft_players SET player_id = ? WHERE id = ?]];
			stmt:bind_values(playerid, prospectid) 
			stmt:step();
			local transactions = {}
			transactions[1] = transactionInfo
			local stmt = db:prepare[[UPDATE players SET transactions = ? WHERE id = ?]];
			stmt:bind_values(json.encode(transactions), playerid) 
			stmt:step();
			local stmt2 = prevStats_db:prepare[[INSERT INTO history VALUES(?, NULL)]];
			stmt2:bind_values(playerid) 
			stmt2:step();
		end
	
	end
	
	prevStats_db:exec("END TRANSACTION;")
	prevStats_db:close();
	

end

function seasonSimulator:getDraftSalary(draftPos)
	
	local salary = 0;
	if (draftPos == 1) then
		salary = 5000000
	elseif (draftPos <= 5) then
		salary = 4500000
	elseif (draftPos <= 10) then
		salary = 3000000
	elseif (draftPos <= 20) then
		salary = 2000000
	elseif (draftPos <= 30) then
		salary = 1000000
	elseif (draftPos <= 45) then
		salary = 750000
	else
		salary = 500000
	end

	return salary;
end

--Free Agents Stuff
function seasonSimulator:signMinLevelFreeAgent(teamid, position, enoughRest)

	--If there are no available free agents at a position, generate a free agent at that position 
	--(prevents game from breaking)
	local posTypes = {"1B", "2B", "SS", "3B", "OF", "C", "SP", "RP"}
	for i = 1, #posTypes do
		local count
		for row in db:rows([[SELECT Count(*) FROM players WHERE posType = "]] .. posTypes[i] .. [[" AND teamid = 31;]]) do  
			count = row[1]
		end
		
		if (count < 2) then
			local numToGenerate = 2 - count;
			for n = 1, numToGenerate do
				pg:generateFreeAgent(posTypes[i])
			end
		end
	end
	
	--Fill up roster due to insane number of injuries
	local extra = ""
	if (enoughRest) then extra = [[ days_rest >= 5 AND]] end
	
	local freeAgentId = [[(SELECT id FROM players WHERE injury = 0 AND teamid = 31 AND]] .. extra ..[[ posType = "]] .. position ..
	[[" AND FA_salary_wanted = (SELECT min(FA_salary_wanted) FROM players WHERE teamid = 31 AND injury = 0 AND posType = "]] .. position .. [[") ORDER BY overall DESC LIMIT 1)]] 
	
	--FA Priority
	--1. Lowest salary wanted of free agents of that position
	--2. Highest overall (of the lowest salaries)
	local id, salary, years
	for row in db:nrows([[SELECT * FROM players WHERE id = ]] .. freeAgentId .. [[;]])do
		id, salary, years = row.id, row.FA_salary_wanted, row.FA_years_wanted
	end
	
	if (id ~= nil) then
	seasonSimulator:signFreeAgent(id, teamid, salary, years);
	end
	
	
	
end

function seasonSimulator:freeAgentsNextDay()
	
	--FA_interest decreases between 10-30(random) every day
	db:exec([[UPDATE players SET FA_interest = FA_interest - (abs(random()%21) + 10) WHERE teamid = 31;]])
	db:exec([[UPDATE players SET FA_interest = 0 WHERE teamid = 31 AND FA_interest < 0;]]) --Lower limit of 0 for FA interest
	
	for row in db:nrows([[SELECT * FROM players WHERE FA_interest <= 0 AND teamid = 31;]])do
		
		--Choose best free agent offer
		if (row.FA_offers ~= nil) then
			local offers = json.decode(row.FA_offers); --{ {teamid = 31, years = 4, salary = 500000}, {...}}
			
			local bestOffers, bestOfferRating = {}, 0;
			
			
			for i = 1, #offers do
				local offerRating = fa:determineOfferRating(row.FA_salary_wanted, row.FA_years_wanted, 
					offers[i].salary, offers[i].years)
				if (offerRating > bestOfferRating) then
					--The best offer
					bestOfferRating = offerRating
					bestOffers = {i};
				elseif (offerRating == bestOfferRating) then
					--One of the best offers
					bestOffers[#bestOffers+1] = i
				end
			end
			
			if (#bestOffers > 0) then
				
				--Pick random team from those with best offers
				local bestOffer = bestOffers[math.random(1,#bestOffers)]
				
				--Sign the free agent
				seasonSimulator:signFreeAgent(row.id, offers[bestOffer].teamid, offers[bestOffer].salary, offers[bestOffer].years);
				
				--Add signing to recent signings list
				local recent_signings;
				
				for row in db:nrows([[SELECT recent_signings FROM league;]])do
					if (row.recent_signings == nil) then recent_signings = {}
					else recent_signings = json.decode(row.recent_signings) end
				end
				
				recent_signings[#recent_signings+1] = {playerid = row.id, teamid = offers[bestOffer].teamid,
								salary = offers[bestOffer].salary, years = offers[bestOffer].years}
				
				local stmt = db:prepare[[UPDATE league SET recent_signings = ?;]];
				stmt:bind_values(json.encode(recent_signings)); 
				stmt:step();
			end
		
		else
			--No offers to free agent, and interest is pretty low. 
			--Must decrease free agent wants
			local newSalary = math.floor(row.FA_salary_wanted * .97); 
			if (newSalary < 500000) then newSalary = 500000; end
			local newMood = row.FA_mood + 10;
			if (newMood > 100) then newMood = 100; end
			
			local newYears = row.FA_years_wanted
			if (30 >= math.random(1,100)) then
				newYears = newYears - 1 --30% chance of decreasing years wanted also
			end
			if (newYears == 0) then newYears = 1 end 
			
			local stmt = db:prepare[[UPDATE players SET FA_salary_wanted = ?, FA_years_wanted = ?, FA_mood = ? WHERE id = ?;]];
			stmt:bind_values(newSalary, newYears, newMood, row.id); 
			stmt:step();
		
		end
		
	end
end

function seasonSimulator:teamOfferLogic(playerTeamid)
	print("Team Offer Logic: ");
	print("**********************");
	for row in db:nrows([[SELECT * FROM teams;]])do
		
		--CPU Teams Offer Contracts
		if (row.id ~= playerTeamid) then
		
		local players = {}
		local payroll = 0
		
		for row in db:nrows([[SELECT * FROM players WHERE teamid = ]] .. row.id .. [[;]])do
			players[#players+1] = row
			payroll = payroll + row.salary
		end
		
		--Calculate revenue based off 80 home games
		local revenue = 
			at:determineRevenue(at:determineAttendance(row.support, row.population)) * 80
			+ seasonSimulator.competitiveBalanceMoney
			+ tv:determineTVRevenue(row.population);
		
		--Even if revenue is too low to sustain model, teams will still spend to maintain competition
		if (revenue < 60000000) then revenue = 60000000 end
		local budget =  revenue - payroll --Total annual revenue minus payroll
		
		--Subtract currently standing offers from budget
		if (row.contract_offers ~= nil) then
			local contract_offers = json.decode(row.contract_offers)
			for i = 1, #contract_offers do
				budget = budget - contract_offers[i].salary;
			end
		end
		
		print("");
		print(row.name .. "   Revenue: $" .. revenue .. "   Budget: $" .. budget)
		
		local balancedRoster = {sp = 10, rp = 10, first = 4, second = 4, short = 4, third = 4, catcher = 3, of = 7}
		local curRoster = {sp = 0, rp = 0, first = 0, second = 0, short = 0, third = 0, catcher = 0, of = 0}
		local needRoster = {sp = 0, rp = 0, first = 0, second = 0, short = 0, third = 0, catcher = 0, of = 0}
		
		--Fill in number of positions in curRoster
		for i = 1, #players do
			local pos = players[i].posType
			if (pos == "SP") then curRoster.sp = curRoster.sp + 1
			elseif (pos == "RP") then curRoster.rp = curRoster.rp + 1
			elseif (pos == "1B") then curRoster.first = curRoster.first + 1
			elseif (pos == "2B") then curRoster.second = curRoster.second + 1
			elseif (pos == "SS") then curRoster.short = curRoster.short + 1
			elseif (pos == "3B") then curRoster.third = curRoster.third + 1
			elseif (pos == "C") then curRoster.catcher = curRoster.catcher + 1
			elseif (pos == "OF") then curRoster.of = curRoster.of + 1 end
		end
		if (row.contract_offers ~= nil) then
			local contract_offers = json.decode(row.contract_offers)
			for i = 1, #contract_offers do
				for row in db:nrows([[SELECT * FROM players WHERE id = ]] .. contract_offers[i].playerid.. [[;]])do
					local pos = row.posType
					if (pos == "SP") then curRoster.sp = curRoster.sp + 1
					elseif (pos == "RP") then curRoster.rp = curRoster.rp + 1
					elseif (pos == "1B") then curRoster.first = curRoster.first + 1
					elseif (pos == "2B") then curRoster.second = curRoster.second + 1
					elseif (pos == "SS") then curRoster.short = curRoster.short + 1
					elseif (pos == "3B") then curRoster.third = curRoster.third + 1
					elseif (pos == "C") then curRoster.catcher = curRoster.catcher + 1
					elseif (pos == "OF") then curRoster.of = curRoster.of + 1 end
				end
			end
		end
			
		--Determine number needed at each position
		for key,value in pairs(needRoster) do
			local needed = balancedRoster[key] - curRoster[key]
			if (needed < 0) then needed = 0 end
			needRoster[key] = needed
		end
		
		local str = "Needed ||  "
		for key,value in pairs(needRoster) do
			str = str .. "   " .. key .. "-" .. value;
		end
		print(str);
		
		--Check to see if there are still some positions to fill
		local function openRoster()
			for key,value in pairs(needRoster) do
				if (value > 0) then return true end
			end
			return false;
		end
	
		local function isAPositionOfNeed(pos)
		
			if (pos == "SP") then return needRoster.sp > 0
			elseif (pos == "RP") then return needRoster.rp > 0
			elseif (pos == "1B") then return needRoster.first > 0
			elseif (pos == "2B") then return needRoster.second > 0
			elseif (pos == "SS") then return needRoster.short > 0
			elseif (pos == "3B") then return needRoster.third > 0
			elseif (pos == "C") then return needRoster.catcher > 0
			elseif (pos == "OF") then return needRoster.of > 0 end
			
		end
		
		local function offerContract(playerid, posType, salary, years, playerExistingOffers)
			salary = math.round(salary);
			if (salary > 30000000) then salary = 30000000 end
			if (salary < 500000) then salary = 500000 end
			print("Offer " .. playerid .. "  (" .. posType .. ")  " .. years .. " yrs  " .. " $" .. salary);
			
			budget = budget - salary
			
			if (posType == "SP") then needRoster.sp = needRoster.sp - 1
			elseif (posType == "RP") then needRoster.rp = needRoster.rp - 1
			elseif (posType == "1B") then needRoster.first = needRoster.first - 1
			elseif (posType == "2B") then needRoster.second = needRoster.second - 1
			elseif (posType == "SS") then needRoster.short = needRoster.short - 1
			elseif (posType == "3B") then needRoster.third = needRoster.third - 1
			elseif (posType == "C") then needRoster.catcher = needRoster.catcher - 1
			elseif (posType == "OF") then needRoster.of = needRoster.of - 1 end
			
			seasonSimulator:offerContract(row.id,playerid,salary, years, playerExistingOffers);
		
		end
		
		local function isContractOffered(playerid)
			
			if (row.contract_offers ~= nil) then
				local contract_offers = json.decode(row.contract_offers)
				for i = 1, #contract_offers do
					if (contract_offers[i].playerid == playerid) then
						return true;
					end
				end
			end
			
			return false;
		
		end
		

		for row in db:nrows([[SELECT * FROM players WHERE teamid = 31 ORDER BY overall DESC;]])do
			
			if (isAPositionOfNeed(row.posType) and not isContractOffered(row.id)) then
				local salary, years = row.FA_salary_wanted, row.FA_years_wanted
				if (budget < salary * .9) then --Don't offer, can't afford
				elseif (budget < salary) then offerContract(row.id, row.posType, salary*.9, years, row.FA_offers);
				elseif (budget < salary*2) then offerContract(row.id, row.posType, salary*math.random(90,110)*.01, years, row.FA_offers);
				elseif (budget < salary*3) then offerContract(row.id, row.posType, salary*math.random(90,120)*.01, years, row.FA_offers);
				elseif (budget < salary*5) then offerContract(row.id, row.posType, salary*math.random(92,122)*.01, years, row.FA_offers);
				elseif (budget < salary*10) then offerContract(row.id, row.posType, salary*math.random(95,125)*.01, years, row.FA_offers);
				else offerContract(row.id, row.posType, salary*math.random(95,140)*.01, years, row.FA_offers); end
			end
			
			if (budget < 500000 or not openRoster()) then
				break;
			end
		end

		end
	
	end

end

function seasonSimulator:offerContract(teamid, playerid, salary, years, playerExistingOffers)
	
	--Add into teams contract offers
	local contract_offers = {}
	
	for row in db:nrows([[SELECT * FROM teams WHERE id = ]] .. teamid .. [[;]])do
		if (row.contract_offers ~= nil) then
			contract_offers = json.decode(row.contract_offers)
		end
	end
	
	--If team has already offered contract to player, remove the offer
	for i = #contract_offers, 1, -1 do
		local offer = contract_offers[i]
		if (offer.playerid == playerid) then table.remove(contract_offers, i); end
	end

	
	contract_offers[#contract_offers+1] = {playerid = playerid, salary = salary, years = years}
	
	local stmt = db:prepare[[UPDATE teams SET contract_offers = ? WHERE id = ? ]];
	stmt:bind_values(json.encode(contract_offers), teamid); 
	stmt:step();
	
	
	--Add into players contract offers
	if (playerExistingOffers ~= nil) then
		playerExistingOffers = json.decode(playerExistingOffers)
	else playerExistingOffers = {} end
	
	--If player already has contract offer from team, remove the offer
	for i = #playerExistingOffers, 1, -1 do
		local offer = playerExistingOffers[i]
		if (offer.teamid == teamid) then table.remove(playerExistingOffers, i); end
	end

	
	playerExistingOffers[#playerExistingOffers+1] = {teamid = teamid, salary = salary, years = years}
	
	--Calculate new FA_interest (upper bound of 100)
	--(It does not change if myteam is offering contract)
	local oldInterest = 0;
	local newInterest = 0;
	for row in db:nrows([[SELECT * FROM players WHERE id = ]] .. playerid .. [[;]])do
		oldInterest = row.FA_interest
	end
	local myteamid = 0;
	for row in db:nrows([[SELECT * FROM myteam]])do
		myteamid = row.teamid
	end
	if (teamid == myteamid) then
		newInterest = oldInterest
	else
		newInterest = oldInterest + 5
		if (newInterest > 100) then newInterest = 100 end
	end
	
	local stmt = db:prepare[[UPDATE players SET FA_offers = ?, FA_interest = ? WHERE id = ? ]];
	stmt:bind_values(json.encode(playerExistingOffers), newInterest, playerid); 
	stmt:step();

end

function seasonSimulator:signFreeAgent(playerid, teamid, salary, years)
	
	local year, teamAbv
	for row in db:nrows([[SELECT * FROM teams WHERE id = ]] .. teamid .. [[;]])do
		teamAbv = row.abv;
	end
	for row in db:nrows([[SELECT * FROM league;]])do
		year = row.year
	end
	print(teamAbv .. " Signed Free agent id " .. playerid .. " for " .. salary .. " over " .. years .. " years");
	
	if (salary < 500000) then salary = 500000 end
	if (salary > 30000000) then salary = 30000000 end
	
	--Update player transactions to reflect signing
	local transactions
	for row in db:nrows([[SELECT * FROM players WHERE id = ]] .. playerid .. [[;]])do
		if (row.transactions ~= nil) then
			transactions = json.decode(row.transactions)
		else
			transactions = {}
		end
	end
	transactions[#transactions+1] = "Signed with " .. teamAbv .. " for $" .. utils:comma_value(salary) ..
		" over " .. years .. " yrs" .. " (" .. year .. ")"
	transactions = json.encode(transactions)
	
	local stmt = db:prepare[[UPDATE players SET salary = ?, years = ?, FA_interest = NULL,
		FA_offers = NULL, FA_salary_wanted = NULL, FA_years_wanted = NULL, FA_mood = NULL, teamid = ?,
		transactions = ? WHERE id = ? ]];
	stmt:bind_values(salary, years, teamid, transactions, playerid) 
	stmt:step();
	
	--Remove player offer from all team's contract offers
	for row in db:nrows([[SELECT * FROM teams;]])do
		local contract_offers = row.contract_offers
		local updatedTable = false;
		
		if (contract_offers ~= nil) then 
			--Example c_offer table: {{playerid = 123, salary = 500000, years = 2}, ...}
			contract_offers = json.decode(contract_offers);
			
			for i = #contract_offers, 1, -1 do
				if (contract_offers[i].playerid == playerid) then
					table.remove(contract_offers, i);
					updatedTable = true;
					break;
				end
			end
		end
		
		if (updatedTable) then
			local stmt = db:prepare[[UPDATE teams SET contract_offers = ? WHERE id = ?;]]
			stmt:bind_values(json.encode(contract_offers), row.id) 
			stmt:step();
		end
	
	end
	
	
end

function seasonSimulator:forceSign()
	--Usually called after final day of free agency.
	--Forces the players who is still deciding between offers to sign with a team
	
	for row in db:nrows([[SELECT * FROM players WHERE teamid = 31;]])do
		
		--Choose best free agent offer
		if (row.FA_offers ~= nil) then
			local offers = json.decode(row.FA_offers); --{ {teamid = 31, years = 4, salary = 500000}, {...}}
			
			local bestOffer, bestOfferRating = 0, 0;
			
			
			for i = 1, #offers do
				local offerRating = fa:determineOfferRating(row.FA_salary_wanted, row.FA_years_wanted, 
					offers[i].salary, offers[i].years)
				if (offerRating > bestOfferRating) then
					bestOfferRating = offerRating
					bestOffer = i;
				end
			end
			
			if (bestOffer ~= 0) then
				--Sign the free agent
				seasonSimulator:signFreeAgent(row.id, offers[bestOffer].teamid, offers[bestOffer].salary, offers[bestOffer].years);
			end
		
		end
		
	end
end

--Miscellaneous Stuff
function seasonSimulator:generateSeasonGoals(playerTeamid)
	
	local teamData
	for row in db:nrows([[SELECT * FROM teams WHERE id = ]] .. playerTeamid .. [[;]])do
		teamData = row
	end

	local numGames, profit
	if (teamData.support <= 30) then
		numGames = math.random(60,68)
		profit = math.random(5,15) * 1000000
	elseif (teamData.support <= 45) then
		numGames = math.random(67,76)
		profit = math.random(5,10) * 1000000
	elseif (teamData.support <= 60) then
		numGames = math.random(75,80)
		profit = math.random(0,10) * 1000000
	elseif (teamData.support <= 75) then
		numGames = math.random(80,85)
		profit = math.random(-2,10) * 1000000
	else
		numGames = math.random(82,90)
		profit = math.random(-5,10) * 1000000
	end
	

	local goal = json.encode({numGames = numGames, profit = profit});
	local stmt = db:prepare[[ UPDATE myteam SET goals = ?;)]];
	stmt:bind_values(goal) 
	stmt:step();
	
	local message = [[
	Your job as general manager is difficult, but I don't care. I still have 
	high expectations for you. Don't let me down. Here are my expectations 
	for this season:
  
	-Win at least ]] .. numGames .. [[ games
	-Earn a profit of at least ]] .. "$" .. utils:comma_value(profit) .. [[]]

	pMsg:showMessage(pMsg:newMessage("Owner", message))
end

function seasonSimulator:checkWinGoal(playerTeamid)
	--Returns boolean metGoals (if true, it means that player has met the goals)
	--If user doesn't meet season goals, he loses the game
	local teamData
	local goals
	
	for row in db:nrows([[SELECT * FROM teams WHERE id = ]] .. playerTeamid .. [[;]])do
		teamData = row
	end
	for row in db:nrows([[SELECT * FROM myteam;]])do
		goals = json.decode(row.goals)
	end
	
	if (teamData.win < goals.numGames) then
		db:exec([[UPDATE league SET day = 1, mode = "Lost";]])
		return false
	end
	return true
end

function seasonSimulator:checkProfitGoal(playerTeamid)
	--Returns boolean metGoals (if true, it means that player has met the goals)
	--If user doesn't meet season goals, he loses the game
	local teamData
	local goals
	
	for row in db:nrows([[SELECT * FROM teams WHERE id = ]] .. playerTeamid .. [[;]])do
		teamData = row
	end
	for row in db:nrows([[SELECT * FROM myteam;]])do
		goals = json.decode(row.goals)
	end
	
	local profit = teamData.money - teamData.prevMoney
	if ( profit < goals.profit) then
		db:exec([[UPDATE league SET day = 1, mode = "Lost";]])
		return false
	end
	return true
end


return seasonSimulator