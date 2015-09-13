local scheduleGenerator = {


}

--Generates a table of schedules at the beginning of every season
function scheduleGenerator:generateSchedule()
	
	--Table of all 162 days
	--Each day is a table
	--Each day table contains 15 separate tables which 
	--contain the ids of the teams that are matched up
	local finalSchedule = {}; 
	local continueMatchup = {}; --Contains list of matchups that are going to be continued the next day, are not in available teams pool
	local counter = 1;
	
	for i = 1, 162 do --162 games in the season
	
		local day = {} --This day contains all the matchups for the day
	
		local teamids = {}; --List of all teams available to play
		
		for x = 1, 30 do --Populate the list of teamids
			teamids[x] = x;
		end
		
		--Remove teams that are in a continuing matchup from the available team pool
		for x = 1, #continueMatchup do
			for n = #teamids, 1, -1 do
				if (teamids[n] == continueMatchup[x].team1 or teamids[n] == continueMatchup[x].team2) then
					table.remove(teamids, n);
				end
			end
		end
		
		--Pair remaining teams with each other
		while (#teamids > 0) do --While there are still available teams
			local team1, team2;
			
			local num = math.random(1,#teamids);
			team1 = teamids[num]
			table.remove(teamids, num);
			
			num = math.random(1,#teamids);
			team2 = teamids[num]
			table.remove(teamids, num);
			
			--Record the matchup
			continueMatchup[#continueMatchup+1] = {team1 = team1, team2 = team2, daysLeft = math.random(1,4)}
		end
		
		--Add the matchups to the table of current day
		for x = 1, #continueMatchup do
			day[#day+1] = {team1 = continueMatchup[x].team1, team2 = continueMatchup[x].team2, matchup_id = counter}
			counter = counter + 1 --Assign unique id to each game, so that they can be identified
			continueMatchup[x].daysLeft = continueMatchup[x].daysLeft - 1
		end
		
		--If there are zero days left in the matchup, remove the matchup
		for x = #continueMatchup, 1, -1 do
			if (continueMatchup[x].daysLeft == 0) then
				table.remove(continueMatchup, x);
			end
		end
		
		--Add the day's schedule to the league's final schedule
		finalSchedule[#finalSchedule+1] = day
	
	end

	return finalSchedule



end


--2nd version of generateSchedule (Balances home and away games @ 81)
function scheduleGenerator:generateSchedule2()
	
	--*************************
	--CURRENTLY TESTING WITH 4 TEAMS && 10 GAMES
	--TO SIMPLIFY PROCESS
	--*************************
	
	local teams = {}
	
	for i = 1, 30 do
		teams[#teams+1] = {id = i, home = 0, away = 0}
	end
	
	local numGames = 162 --Total number of games played, usually 162 in a season
	local limit = numGames/2 --Limit for number of home and away games
	
	local final_schedule = {}
	local matchups = {} --Attributes = days_left, team1  (id), team2   (id)
	local counter = 1; --Counter that regulates matchup_ids to ensure that they are unique
	
	for i = 1, numGames do --Add numGames days worth of schedules into final schedule
		
		local day_schedule = {} --This day contains all the matchups for the day
		
		--******************************
		--Identifying all available teams
		--******************************
		
		--IDS of all available teams
		local availableTeams = {} 
		
		--Populate available teams
		for x = 1, 30 do
			availableTeams[#availableTeams+1] = x
		end
		
		--Remove teams already in matchups from list of available teams
		for x = 1, #matchups do
			for n = #availableTeams, 1, -1 do
				if (availableTeams[n] == matchups[x].team1 or availableTeams[n] == matchups[x].team2) then
					table.remove(availableTeams, n);
				end
			end
		end
		
		--******************************
		--Pair available teams with each other
		--Into matchups until no more available teams
		--******************************
		
		while (#availableTeams > 0) do
			
			--List of teams that can play away games teams[i].away < limit
			local away = {}
			
			--List of teams that can play home games teams[i].home < limit
			local home = {}
			
			--List of teams that can ONLY play away
			local awayOnly = {}
			
			--List of teams that can ONLY play home
			local homeOnly = {}
			
			for x = 1, #availableTeams do
				local team = teams[availableTeams[x]]
				
				local awayFlag = false;
				local homeFlag = false;
				if (team.away < limit) then
					away[#away+1] = team.id
					awayFlag = true
				end
				if (team.home < limit) then
					home[#home+1] = team.id
					homeFlag = true
				end
				
				if (not awayFlag and homeFlag) then
					homeOnly[#homeOnly+1] = team.id
				end
				if (awayFlag and not homeFlag) then
					awayOnly[#awayOnly+1] = team.id
				end
			end
			--print("Day " .. i .. "   " .. "#away= " ..#away .. "  #home" .. #home
			--	 .. "   #awayOnly= " ..#awayOnly .. "  #homeOnly" .. #homeOnly);
			
			local team1, team2
			
			--Check to see if teams can play with each other (@ least 1 home, 1 away)
			--If not, one of the existing matchups has to be broken apart
			local restartLoop = false --If true, it pretty much functions as a Java 'continue' statement in a loop
			
			if (#awayOnly > 0 and #home == 0) then
				--Teams left can only play away games
				--Can't match each other up
				
				--Loop through matchups to find a pair where both teams
				--Can play home games
				for x = 1, #matchups do
					local matchup = matchups[x]
					if (teams[matchup.team1].home < limit and teams[matchup.team2].home < limit) then
						--Both teams in matchup can play more home games
						--break matchup apart, and add teams to availableTeams pool
						
						--print("Broke matchup to provide more home games");
						availableTeams[#availableTeams+1] = matchup.team1
						availableTeams[#availableTeams+1] = matchup.team2
						table.remove(matchups, x);
						break;
					end
				end
				restartLoop = true;
			end
			
			if (#homeOnly > 0 and #away == 0) then
				--Teams left can only play home games
				--Can't match each other up
				
				--Loop through matchups to find a pair where both teams
				--Can play away games
				for x = 1, #matchups do
					local matchup = matchups[x]
					if (teams[matchup.team1].away < limit and teams[matchup.team2].away < limit) then
						--Both teams in matchup can play more away games
						--break matchup apart, and add teams to availableTeams pool
						
						--print("Broke matchup to provide more away games");
						availableTeams[#availableTeams+1] = matchup.team1
						availableTeams[#availableTeams+1] = matchup.team2
						table.remove(matchups, x);
						break;
					end
				end
				restartLoop = true
			end
			
			
			if (not restartLoop) then
			--Choose away team
			if (#awayOnly > 0) then 
				--Teams that can only play away games have priority over teams that can play both home and away
				team1 = awayOnly[math.random(1,#awayOnly)]
				scheduleGenerator:removeTableElement(awayOnly, team1);
				scheduleGenerator:removeTableElement(homeOnly, team1);
				scheduleGenerator:removeTableElement(away, team1);
				scheduleGenerator:removeTableElement(home, team1);
				scheduleGenerator:removeTableElement(availableTeams, team1);
			else
				team1 = away[math.random(1,#away)]
				scheduleGenerator:removeTableElement(awayOnly, team1);
				scheduleGenerator:removeTableElement(homeOnly, team1);
				scheduleGenerator:removeTableElement(away, team1);
				scheduleGenerator:removeTableElement(home, team1);
				scheduleGenerator:removeTableElement(availableTeams, team1);
			end
			
			--Choose home team
			if (#homeOnly > 0) then
				--Teams that can only play home games have priority over teams that can play both home and away
				team2 = homeOnly[math.random(1,#homeOnly)]
				scheduleGenerator:removeTableElement(awayOnly, team2);
				scheduleGenerator:removeTableElement(homeOnly, team2);
				scheduleGenerator:removeTableElement(away, team2);
				scheduleGenerator:removeTableElement(home, team2);
				scheduleGenerator:removeTableElement(availableTeams, team2)
			
			else
				team2 = home[math.random(1,#home)]
				scheduleGenerator:removeTableElement(awayOnly, team2);
				scheduleGenerator:removeTableElement(homeOnly, team2);
				scheduleGenerator:removeTableElement(away, team2);
				scheduleGenerator:removeTableElement(home, team2);
				scheduleGenerator:removeTableElement(availableTeams, team2);
			end
			
			 --Usually, a series between 2 clubs will last a max of 5 games
			local maxSeriesLength = 5;
			
			--However, if the home team does not have enough home games left or away team
			--Does not have enough away games left, then maxSeriesLength is adjusted accordingly
			if ((limit - teams[team1].away) < maxSeriesLength) then
				maxSeriesLength = (limit - teams[team1].away)
			end
			if ((limit - teams[team2].home) < maxSeriesLength) then
				maxSeriesLength = (limit - teams[team2].home)
			end
			
			if (maxSeriesLength < 1) then print("MAXLENGHT = 1") return "Error" end
			local seriesLength = math.random(1,maxSeriesLength)
			
			matchups[#matchups+1] = {team1 = team1, team2 = team2, daysLeft = seriesLength}
			end
		
		end
		
		
		--[[print("Day " .. i .. " Matchups");
		print("************************");
		--Print all matchups
		for x = 1, #matchups do
			print("Away: " .. matchups[x].team1);
			print("Home: " .. matchups[x].team2);
			print("Days Left: " .. matchups[x].daysLeft);
			print("");
		end
		]]--
		
		--******************************
		--Add the matchups to the table of current day
		--******************************
		
		for x = 1, #matchups do
			local team1, team2 = matchups[x].team1, matchups[x].team2
			
			day_schedule[#day_schedule+1] = {team1 = team1, team2 = team2, matchup_id = counter}
			counter = counter + 1 --Assign unique id to each game, so that they can be identified
			
			--Record the number of home/away games each team has now played in
			teams[team1].away = teams[team1].away + 1
			teams[team2].home = teams[team2].home + 1
			
			matchups[x].daysLeft = matchups[x].daysLeft - 1
		end
		
		--******************************
		--If there are zero days left in the matchup, remove the matchup
		--******************************
		for x = #matchups, 1, -1 do
			if (matchups[x].daysLeft == 0) then
				table.remove(matchups, x);
			end
		end
		
		--******************************
		--Add the day's schedule to the league's final schedule
		--******************************
		final_schedule[#final_schedule+1] = day_schedule
		
	end
		
	return final_schedule	


end

function scheduleGenerator:removeTableElement(t, element)
	for i = #t, 1, -1 do
		if (t[i] == element) then
			table.remove(t,i)
		end
	end
end


--Print the contents of the finalSchedule table
--For debugging purposes
function scheduleGenerator:printSchedule(finalSchedule)

	local teams = {}

	for i = 1, #finalSchedule do --Iterate through each individual day in the schedule
		print("Day " .. i .. " Schedule:");
		print("-------------------------");
		
		local day = finalSchedule[i]
		
		for i = 1, #day do --Iterate through each individual matchup in a day
			
			print(day[i].team1 .. " vs " .. day[i].team2);
			
			if (teams[day[i].team1] == nil) then
				teams[day[i].team1] = {home = 0, away = 0}
			end
			if (teams[day[i].team2] == nil) then
				teams[day[i].team2] = {home = 0, away = 0}
			end
			
			teams[day[i].team1].away = teams[day[i].team1].away + 1
			teams[day[i].team2].home = teams[day[i].team2].home + 1
		
		end
		
	end
	--Print out number of home/away games each team has
	for i = 1, #teams do
		print("Team " .. i .. " -   " .. "HOME: " .. teams[i].home .. "  AWAY: " .. teams[i].away);
	end




end

return scheduleGenerator