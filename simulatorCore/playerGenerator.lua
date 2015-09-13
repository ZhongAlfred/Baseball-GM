local sqlite3 = require "sqlite3"
local fa = require("simulatorCore.freeAgents");
local ng = require("simulatorCore.nameGenerator");

local playerGenerator = {}

--New game functions
--Generates both players and teams
function playerGenerator:generatePlayers()
	print("Generating players");

	
	local path2 = system.pathForFile("previousPlayerStats.db", system.DocumentsDirectory)
	local prevStats_db = sqlite3.open( path2 );
	prevStats_db:exec("BEGIN TRANSACTION;")	

	--Create database based on generated players
	local path = system.pathForFile("data.db", system.DocumentsDirectory)
	db = sqlite3.open( path )   
	
	
	--Generate players
	ng:open()
	local players = {}; --Holds all the generated players in the league
	for i = 1, 30 do --30 teams to generate players for
		
		--Table of the positions played by the  players in the team
		--40 elements in the table to correlate with the 40 players per team
		local positions = {"SP", "SP", "SP", "SP", "SP", "SP", "SP", "SP", "SP", "RP", "RP", "RP", "RP",
		"RP", "RP", "RP", "RP", "1B", "2B", "SS", "3B", "1B", "2B", "SS", "3B", "OF", "OF", "OF", "OF",
		"OF", "OF", "C", "C", "1B", "2B", "SS", "3B"}
		for i = 1, 3 do
			--Add a few random positions to team's positions table 
			local index = {"SP", "RP", "1B", "2B", "SS", "3B", "OF", "C"};
			positions[#positions+1] = index[math.random(1,#index)];
		end
		local stars = {}
		for i = 1, 40 do
			if (3 >= math.random(1,100)) then --3% chance of being a star
				stars[#stars+1] = true;
			else
				stars[#stars+1] = false;
			end
		end
		
		for n = 1, 40 do --40 players per team
			
			--Attributes of the player
			local name, contact, power, eye, velocity, nastiness, control, stamina, speed, iq, age, salary, years, posType,
				defense,durability,hand,
				overall, potential;
			
			--Generate Name
			name = ng:generateName();

			--Generate Ratings
			posType = positions[n]
			if (stars[n]) then
				--Generate a star
				if (posType == "SP") then
					velocity = math.random(60,100);	
					nastiness = math.random(60,100);	
					control = math.random(60,100);	
					stamina = math.random(10,100);	
					defense = math.random(10,100);						
					iq = math.random(30,100);	
					age = math.random(18,32);
					years = math.random(1,7);
				elseif (posType == "RP") then
					velocity = math.random(60,100);	
					nastiness = math.random(60,100);	
					control = math.random(60,100);	
					stamina = math.random(10,100);
					defense = math.random(10,100);					
					iq = math.random(30,100);	
					age = math.random(22,34);
					years = math.random(1,5);
				else --Batter type
					contact = math.random(60,100);
					power = math.random(60,100);	
					eye = math.random(60,100);	
					speed = math.random(10,100);
					defense = math.random(10,100);					
					iq = math.random(50,100);	
					age = math.random(18,34);
					years = math.random(1,8);
				end
			else 
				--Non star
				if (posType == "SP") then
					velocity = math.random(25,70);	
					nastiness = math.random(25,70);	
					control = math.random(25,70);	
					stamina = math.random(0,90);	
					defense = math.random(0,100);
					iq = math.random(0,100);	
					age = math.random(18,35);
					years = math.random(1,5);
				elseif (posType == "RP") then
					velocity = math.random(25,70);	
					nastiness = math.random(25,70);	
					control = math.random(25,70);	
					stamina = math.random(0,100);
					defense = math.random(0,100);
					iq = math.random(0,100);	
					age = math.random(22,35);
					years = math.random(1,4);
				else --Batter type
					contact = math.random(25,70);
					power = math.random(25,70);	
					eye = math.random(25,70);	
					speed = math.random(10,100);
					defense = math.random(0,100);
					iq = math.random(0,100);	
					age = math.random(18,37);
					years = math.random(1,6);
				end

			end
			
			--Determine overall and potential based off ratings
			--Fill in extraneous ratings
			if (posType == "SP" or posType == "RP") then
				overall = playerGenerator:getOverallRating(true, velocity, nastiness, control, stamina, defense);
				potential = playerGenerator:getPotential(overall, age);
				
				contact = math.random(0,20);
				power = math.random(0,20);	
				eye = math.random(0,20);
				speed = math.random(0,100);
			else
				--Batter
				overall = playerGenerator:getOverallRating(false, contact, power, eye, speed, defense);
				potential = playerGenerator:getPotential(overall, age);
				
				velocity = math.random(0,20);	
				nastiness = math.random(0,20);	
				control = math.random(0,20);	
				stamina = math.random(50,100);	
			end
			

			--Determine handedness
			if (posType == "SP" or posType == "RP") then
				if (math.random(1,100) <= 20) then
					--20% Left handed
					hand = "L"
				else
					hand = "R"
				end
			else 
				local num = math.random(1,100)
				if (num <= 25) then
					--25% Left handed
					hand = "L"
				elseif (num <= 35) then
					--10% Switch Hitter
					hand = "S"
				else
					hand = "R"
				end
			
			end
			
			durability = math.random(0,100);
			
			
			salary = fa:generateSalaryWanted(overall, potential, posType, age);
			
			players[#players+1] = {name = name, teamid = i, contact = contact, power = power,
			eye = eye, velocity = velocity, nastiness = nastiness, control = control, stamina = stamina,
			speed = speed, defense = defense, durability = durability, hand = hand,
			iq = iq, age = age, salary = salary, years = years, posType = posType,
			overall = overall, potential = potential, FA_salary_wanted = 0, FA_years_wanted = 0, FA_mood = 0};

		end
	
		
	end
	
	--Generate free agents
	--Free agent teamid = 31
	for i = 1, 500 do
	
		local positions = {"SP", "SP", "SP", "SP", "RP", "RP", "RP","RP", "1B", "2B", "SS", "3B", "1B", "2B", "SS", "3B", "OF", "OF", "OF", "OF",
			"OF", "C", "C", "C", "1B", "2B", "SS", "3B"}
			
		--Attributes of the player
		local name, contact, power, eye, velocity, nastiness, control, stamina, speed, iq, age, salary, years, posType,
			defense,durability,hand,
			overall, potential;
		
		--Generate Name
		name = ng:generateName();
		
		local position = positions[math.random(1,#positions)]
		
		--Generate Ratings
		posType = position
		--Non star
		if (posType == "SP") then
			velocity = math.random(25,60);	
			nastiness = math.random(25,60);	
			control = math.random(25,60);	
			stamina = math.random(0,90);	
			defense = math.random(0,70);
			iq = math.random(0,100);	
			age = math.random(18,35);
		elseif (posType == "RP") then
			velocity = math.random(25,60);	
			nastiness = math.random(25,60);	
			control = math.random(25,60);	
			stamina = math.random(0,100);
			defense = math.random(0,70);
			iq = math.random(0,100);	
			age = math.random(22,35);
		else --Batter type
			contact = math.random(25,60);
			power = math.random(25,60);	
			eye = math.random(25,60);	
			speed = math.random(10,100);
			defense = math.random(0,70);
			iq = math.random(0,100);	
			age = math.random(18,37);
		end

	
		--Determine overall and potential based off ratings
		--Fill in extraneous ratings
		if (posType == "SP" or posType == "RP") then
			overall = playerGenerator:getOverallRating(true, velocity, nastiness, control, stamina, defense);
			potential = playerGenerator:getPotential(overall, age);
			
			contact = math.random(0,20);
			power = math.random(0,20);	
			eye = math.random(0,20);
			speed = math.random(0,100);
		else
			--Batter
			overall = playerGenerator:getOverallRating(false, contact, power, eye, speed, defense);
			potential = playerGenerator:getPotential(overall, age);
			
			velocity = math.random(0,20);	
			nastiness = math.random(0,20);	
			control = math.random(0,20);	
			stamina = math.random(50,100);	
		end
	
		--Determine handedness
		if (posType == "SP" or posType == "RP") then
			if (math.random(1,100) <= 20) then
				--20% Left handed
				hand = "L"
			else
				hand = "R"
			end
		else 
			local num = math.random(1,100)
			if (num <= 25) then
				--25% Left handed
				hand = "L"
			elseif (num <= 35) then
				--10% Switch Hitter
				hand = "S"
			else
				hand = "R"
			end
		
		end
		
		durability = math.random(0,100);
		
		local yearsWanted = 1;
		local salaryWanted = fa:generateSalaryWanted(overall, potential, posType, age);
		local FA_mood = 0;
		local num = math.random(1,100);
		
		if (num <= 70) then
			--Happy 70%
			FA_mood = math.random(90,100);
		elseif (num <= 80) then
			FA_mood = math.random(30,100);
		else
			FA_mood = math.random(0,20);
		end
		
		players[#players+1] = {name = name, teamid = 31, contact = contact, power = power,
			eye = eye, velocity = velocity, nastiness = nastiness, control = control, stamina = stamina,
			speed = speed, defense = defense, durability = durability, hand = hand,
			iq = iq, age = age, salary = 0, years = 0, posType = posType,
			overall = overall, potential = potential, FA_salary_wanted = salaryWanted, FA_years_wanted = yearsWanted,
			FA_mood = FA_mood};
	
	end
	ng:close()

	db:exec("BEGIN TRANSACTION;")
	
	playerGenerator:generateTeams();
	
	--Create players table
	db:exec[[
		CREATE TABLE players (id INTEGER PRIMARY KEY, teamid INTEGER, posType TEXT, name TEXT, hand TEXT, age INTEGER, 
		contact INTEGER, power INTEGER, eye INTEGER, velocity INTEGER, nastiness INTEGER, control INTEGER, 
		stamina INTEGER, speed INTEGER, defense INTEGER, durability INTEGER, iq INTEGER, salary INTEGER, years INTEGER,  overall INTEGER, potential INTEGER, overallChange INTEGER, potentialChange INTEGER,
		injury INTEGER, days_rest INTEGER, GP INTEGER, AB INTEGER, R INTEGER, H INTEGER, DOUBLES INTEGER, TRIPLES INTEGER, HR INTEGER, RBI INTEGER, BB INTEGER,
		SO INTEGER, SB INTEGER, CS INTEGER, AVG REAL, OBP REAL, SLG REAL, DRS REAL, P_GP INTEGER, P_GS INTEGER, P_IP REAL, P_H INTEGER, P_ER INTEGER, P_HR INTEGER, P_BB INTEGER,
		P_SO INTEGER, P_W INTEGER, P_L INTEGER, P_SV INTEGER, P_WHIP REAL, P_ERA REAL, previous_stats TEXT, awards TEXT,
		FA_salary_wanted INTEGER, FA_years_wanted INTEGER, FA_mood INTEGER, FA_offers TEXT, FA_interest INTEGER, draft_position TEXT, portrait TEXT, transactions TEXT);]]
	
	for i = 1, #players do
	
		local insertQuery = [[INSERT INTO players VALUES ]] .. [[(NULL, ]] .. 
		players[i].teamid.. [[,]] .. [["]] .. players[i].posType.. [["]] .. [[,"]] .. players[i].name.. [["]] ..
		[[,"]] .. players[i].hand.. [["]] ..
		[[,]] .. players[i].age .. 
		[[,]] .. players[i].contact .. [[,]] .. players[i].power .. [[,]] .. players[i].eye .. 
		[[,]] .. players[i].velocity .. [[,]]  .. players[i].nastiness ..
		[[,]] .. players[i].control .. [[,]]  .. players[i].stamina .. 
		[[,]] .. players[i].speed .. [[,]] .. players[i].defense .. 
		[[,]] .. players[i].durability .. [[,]] .. players[i].iq ..
		[[,]] .. players[i].salary .. [[,]] .. players[i].years .. 
		[[,]] .. players[i].overall .. [[,]] .. players[i].potential ..
		[[,0,0,0,5,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,NULL,NULL,]] 
		.. players[i].FA_salary_wanted .. [[,]] .. players[i].FA_years_wanted .. [[,]] .. players[i].FA_mood .. [[,NULL,0,"2014 Undrafted",]]
		.. [["none", NULL]] .. [[);]]

		db:exec(insertQuery);
		
		for row in db:rows([[SELECT last_insert_rowid();]]) do
			--Gets id of last inserted player
			local playerid = row[1]
			local stmt = prevStats_db:prepare[[INSERT INTO history VALUES(?, NULL)]];
			stmt:bind_values(playerid) 
			stmt:step();
		end
	end
	
	
	prevStats_db:exec("END TRANSACTION;")
	prevStats_db:close();
	db:exec("END TRANSACTION;")
	db:close()

end

function playerGenerator:generateTeams()
	
	--Generate teams
	local team = {};
	
	--team[31] = Free Agent
	--team[32] = Retired
	team[1] = {abv = "ARZ", name = "Arizona Desert", win = 0, loss = 0, money = 250000000, support=50, population=4400000};
	team[2] = {abv = "ATL", name = "Atlanta Lightning", win = 0, loss = 0, money = 250000000, support=50, population=5500000};
	team[3] = {abv = "BAL", name = "Baltimore Birds", win = 0, loss = 0, money = 100000000, support=50, population=2700000};
	team[4] = {abv = "BOS", name = "Boston Waves", win = 0, loss = 0, money = 600000000, support=50, population=4700000};
	team[5] = {abv = "CHI", name = "Chicago Cows", win = 0, loss = 0, money = 550000000, support=50, population=9500000};
	team[6] = {abv = "CIN", name = "Cincinnati Rolls", win = 0, loss = 0, money = 125000000, support=50, population=2100000};
	team[7] = {abv = "CLE", name = "Cleveland Kings", win = 0, loss = 0, money = 75000000, support=50, population=2000000};
	team[8] = {abv = "COL", name = "Colorado Mountains", win = 0, loss = 0, money = 100000000, support=50, population=2700000};
	team[9] = {abv = "DET", name = "Detroit Combustors", win = 0, loss = 0, money = 400000000, support=50, population=4300000};
	team[10] = {abv = "HOU", name = "Houston Stars", win = 0, loss = 0, money = 200000000, support=50, population=6300000};
	team[11] = {abv = "KC", name = "Kansas City Plains", win = 0, loss = 0, money = 150000000, support=50, population=2300000};
	team[12] = {abv = "LA", name = "Los Angeles Tremors", win = 0, loss = 0, money = 800000000, support=50, population=13100000};
	team[13] = {abv = "LON", name = "London Brigadiers", win = 0, loss = 0, money = 700000000, support=50, population=15000000};
	team[14] = {abv = "MIA", name = "Miami Bandwagons", win = 0, loss = 0, money = 200000000, support=50, population=5800000};
	team[15] = {abv = "MIL", name = "Milwaukee Knights", win = 0, loss = 0, money = 150000000, support=50, population=2000000};
	team[16] = {abv = "MIN", name = "Minnesota Mammoths", win = 0, loss = 0, money = 150000000, support=50, population=3400000};
	team[17] = {abv = "NY", name = "New York Revolutions", win = 0, loss = 0, money = 1200000000, support=50, population=25000000};
	team[18] = {abv = "OAK", name = "Oakland Otters", win = 0, loss = 0, money = 50000000, support=50, population=4500000};
	team[19] = {abv = "PHI", name = "Philadelphia Pineapples", win = 0, loss = 0, money = 350000000, support=50, population=6000000};
	team[20] = {abv = "PIT", name = "Pittsburgh Miners", win = 0, loss = 0, money = 200000000, support=50, population=2400000};
	team[21] = {abv = "SD", name = "San Diego Surfers", win = 0, loss = 0, money = 150000000, support=50, population=3200000};
	team[22] = {abv = "SF", name = "San Francisco Tides", win = 0, loss = 0, money = 450000000, support=50, population=4500000};
	team[23] = {abv = "SEA", name = "Seattle Settlers", win = 0, loss = 0, money = 400000000, support=50, population=3600000};
	team[24] = {abv = "SH", name = "Shanghai Shenanigans", win = 0, loss = 0, money = 1000000000, support=50, population=24000000}
	team[25] = {abv = "STL", name = "St. Louis Warriors", win = 0, loss = 0, money = 350000000, support=50, population=2800000};
	team[26] = {abv = "TB", name = "Tampa Bay Sages", win = 0, loss = 0, money = 150000000, support=50, population=2850000};
	team[27] = {abv = "TEX", name = "Texas Cowboys", win = 0, loss = 0, money = 400000000, support=50, population=6800000};
	team[28] = {abv = "TOR", name = "Toronto Borders", win = 0, loss = 0, money = 300000000, support=50, population=5600000};
	team[29] = {abv = "TKY", name = "Tokyo Titans", win = 0, loss = 0, money = 950000000, support=50, population=36900000};
	team[30] = {abv = "WAS", name = "Washington Presidents", win = 0, loss = 0, money = 250000000, support=50, population=5950000};
	
	--Create teams table
	db:exec[[
		CREATE TABLE teams (id INTEGER PRIMARY KEY, abv TEXT, name TEXT, win INTEGER, loss INTEGER,
		runsScored INTEGER, runsAllowed INTEGER, prevMoney INTEGER,
		money INTEGER, support INTEGER , population INTEGER, 
		previous_records TEXT, previous_championships TEXT, contract_offers TEXT, history TEXT);]]
		
	for i = 1, #team do
		local insertQuery = [[INSERT INTO teams VALUES ]] .. [[(NULL, ]] .. 
		[["]] .. team[i].abv .. [["]] .. [[,]] .. [["]] .. team[i].name.. [["]] ..
		[[,]] .. team[i].win .. [[,]] .. team[i].loss .. [[,0,0,]] .. team[i].money .. [[,]] .. team[i].money ..
		[[,]] .. team[i].support .. [[,]]  .. team[i].population .. [[,NULL,NULL,NULL,NULL);]]
		db:exec(insertQuery);
	end


end

function playerGenerator:customRosters(fileName)
	
	--Game Database
	local path = system.pathForFile("data.db", system.DocumentsDirectory)
	db = sqlite3.open( path )   
	
	--Previous Stats Database
	local path2 = system.pathForFile("previousPlayerStats.db", system.DocumentsDirectory)
	local prevStats_db = sqlite3.open( path2 );
	
	--Rosters Database (To import)
	local path = system.pathForFile("rosters/"..fileName, system.ResourceDirectory)
	local roster_db = sqlite3.open( path )  
	
	local players = {}
	local teams = {}
	
	--Get data from rosters database
	for row in roster_db:nrows([[ SELECT * FROM players; ]])do
		local player = row
		player.FA_salary_wanted = 0
		player.FA_years_wanted = 0
		player.FA_mood = 0
		players[#players+1] = player
	end
	for row in roster_db:nrows([[ SELECT * FROM teams; ]])do
		local team = row
		team.win = 0
		team.loss = 0
		teams[#teams+1] = team
	end

	roster_db:close();
	
	--Randomly generate free agents (Free agents not part of rosters database, yet
	ng:open()
	for i = 1, 500 do
	
		local positions = {"SP", "SP", "SP", "SP", "RP", "RP", "RP","RP", "1B", "2B", "SS", "3B", "1B", "2B", "SS", "3B", "OF", "OF", "OF", "OF",
			"OF", "C", "C", "C", "1B", "2B", "SS", "3B"}
			
		--Attributes of the player
		local name, contact, power, eye, velocity, nastiness, control, stamina, speed, iq, age, salary, years, posType,
			defense,durability,hand,
			overall, potential;
		
		--Generate Name
		name = ng:generateName();
		
		local position = positions[math.random(1,#positions)]
		
		--Generate Ratings
		posType = position
		--Non star
		if (posType == "SP") then
			velocity = math.random(25,60);	
			nastiness = math.random(25,60);	
			control = math.random(25,60);	
			stamina = math.random(0,90);	
			defense = math.random(0,70);
			iq = math.random(0,100);	
			age = math.random(18,35);
		elseif (posType == "RP") then
			velocity = math.random(25,60);	
			nastiness = math.random(25,60);	
			control = math.random(25,60);	
			stamina = math.random(0,100);
			defense = math.random(0,70);
			iq = math.random(0,100);	
			age = math.random(22,35);
		else --Batter type
			contact = math.random(25,60);
			power = math.random(25,60);	
			eye = math.random(25,60);	
			speed = math.random(10,100);
			defense = math.random(0,70);
			iq = math.random(0,100);	
			age = math.random(18,37);
		end

	
		--Determine overall and potential based off ratings
		--Fill in extraneous ratings
		if (posType == "SP" or posType == "RP") then
			overall = playerGenerator:getOverallRating(true, velocity, nastiness, control, stamina, defense);
			potential = playerGenerator:getPotential(overall, age);
			
			contact = math.random(0,20);
			power = math.random(0,20);	
			eye = math.random(0,20);
			speed = math.random(0,100);
		else
			--Batter
			overall = playerGenerator:getOverallRating(false, contact, power, eye, speed, defense);
			potential = playerGenerator:getPotential(overall, age);
			
			velocity = math.random(0,20);	
			nastiness = math.random(0,20);	
			control = math.random(0,20);	
			stamina = math.random(50,100);	
		end
	
		--Determine handedness
		if (posType == "SP" or posType == "RP") then
			if (math.random(1,100) <= 20) then
				--20% Left handed
				hand = "L"
			else
				hand = "R"
			end
		else 
			local num = math.random(1,100)
			if (num <= 25) then
				--25% Left handed
				hand = "L"
			elseif (num <= 35) then
				--10% Switch Hitter
				hand = "S"
			else
				hand = "R"
			end
		
		end
		
		durability = math.random(0,100);
		
		local yearsWanted = 1;
		local salaryWanted = fa:generateSalaryWanted(overall, potential, posType, age);
		local FA_mood = 0;
		local num = math.random(1,100);
		
		if (num <= 70) then
			--Happy 70%
			FA_mood = math.random(90,100);
		elseif (num <= 80) then
			FA_mood = math.random(30,100);
		else
			FA_mood = math.random(0,20);
		end
		
		players[#players+1] = {name = name, teamid = 31, contact = contact, power = power,
			eye = eye, velocity = velocity, nastiness = nastiness, control = control, stamina = stamina,
			speed = speed, defense = defense, durability = durability, hand = hand,
			iq = iq, age = age, salary = 0, years = 0, posType = posType,
			overall = overall, potential = potential, FA_salary_wanted = salaryWanted, FA_years_wanted = yearsWanted,
			FA_mood = FA_mood, portrait = "None"};
	
	end
	ng:close()
	
	
	
	prevStats_db:exec("BEGIN TRANSACTION;")
	db:exec("BEGIN TRANSACTION;")
	
	
	--Create teams table
	db:exec[[
		CREATE TABLE teams (id INTEGER PRIMARY KEY, abv TEXT, name TEXT, win INTEGER, loss INTEGER,
		runsScored INTEGER, runsAllowed INTEGER, prevMoney INTEGER,
		money INTEGER, support INTEGER , population INTEGER, 
		previous_records TEXT, previous_championships TEXT, contract_offers TEXT, history TEXT);]]
	--Insert teams into database
	for i = 1, #teams do
		local insertQuery = [[INSERT INTO teams VALUES ]] .. [[(NULL, ]] .. 
		[["]] .. teams[i].abv .. [["]] .. [[,]] .. [["]] .. teams[i].name.. [["]] ..
		[[,]] .. teams[i].win .. [[,]] .. teams[i].loss .. [[,0,0,]] .. teams[i].money .. [[,]] .. teams[i].money ..
		[[,]] .. teams[i].support .. [[,]]  .. teams[i].population .. [[,NULL,NULL,NULL,NULL);]]
		db:exec(insertQuery);
	end
	--Create players table
	db:exec[[
		CREATE TABLE players (id INTEGER PRIMARY KEY, teamid INTEGER, posType TEXT, name TEXT, hand TEXT, age INTEGER, 
		contact INTEGER, power INTEGER, eye INTEGER, velocity INTEGER, nastiness INTEGER, control INTEGER, 
		stamina INTEGER, speed INTEGER, defense INTEGER, durability INTEGER, iq INTEGER, salary INTEGER, years INTEGER,  overall INTEGER, potential INTEGER, overallChange INTEGER, potentialChange INTEGER,
		injury INTEGER, days_rest INTEGER, GP INTEGER, AB INTEGER, R INTEGER, H INTEGER, DOUBLES INTEGER, TRIPLES INTEGER, HR INTEGER, RBI INTEGER, BB INTEGER,
		SO INTEGER, SB INTEGER, CS INTEGER, AVG REAL, OBP REAL, SLG REAL, DRS REAL, P_GP INTEGER, P_GS INTEGER, P_IP REAL, P_H INTEGER, P_ER INTEGER, P_HR INTEGER, P_BB INTEGER,
		P_SO INTEGER, P_W INTEGER, P_L INTEGER, P_SV INTEGER, P_WHIP REAL, P_ERA REAL, previous_stats TEXT, awards TEXT,
		FA_salary_wanted INTEGER, FA_years_wanted INTEGER, FA_mood INTEGER, FA_offers TEXT, FA_interest INTEGER, draft_position TEXT, portrait TEXT, transactions TEXT);]]
	--Insert players into database
	for i = 1, #players do
		print(players[i].portrait)
		local insertQuery = [[INSERT INTO players VALUES ]] .. [[(NULL, ]] .. 
		players[i].teamid.. [[,]] .. [["]] .. players[i].posType.. [["]] .. [[,"]] .. players[i].name.. [["]] ..
		[[,"]] .. players[i].hand.. [["]] ..
		[[,]] .. players[i].age .. 
		[[,]] .. players[i].contact .. [[,]] .. players[i].power .. [[,]] .. players[i].eye .. 
		[[,]] .. players[i].velocity .. [[,]]  .. players[i].nastiness ..
		[[,]] .. players[i].control .. [[,]]  .. players[i].stamina .. 
		[[,]] .. players[i].speed .. [[,]] .. players[i].defense .. 
		[[,]] .. players[i].durability .. [[,]] .. players[i].iq ..
		[[,]] .. players[i].salary .. [[,]] .. players[i].years .. 
		[[,]] .. players[i].overall .. [[,]] .. players[i].potential ..
		[[,0,0,0,5,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,NULL,NULL,]] 
		.. players[i].FA_salary_wanted .. [[,]] .. players[i].FA_years_wanted .. [[,]] .. players[i].FA_mood .. [[,NULL,0,"2014 Undrafted",]]
		.. [["]] .. players[i].portrait .. [[",NULL]] .. [[);]]

		db:exec(insertQuery);
		
		for row in db:rows([[SELECT last_insert_rowid();]]) do
			--Gets id of last inserted player
			local playerid = row[1]
			local stmt = prevStats_db:prepare[[INSERT INTO history VALUES(?, NULL)]];
			stmt:bind_values(playerid) 
			stmt:step();
		end
	end
	
	
	
	db:exec("END TRANSACTION;")
	db:close();
	prevStats_db:exec("END TRANSACTION;")
	prevStats_db:close();
	
	


end

function playerGenerator:generateFreeAgent(posType)
	--Generates one free agent at specified posType
	--print("posType: " .. posType)
	ng:open()
	local player

	--Attributes of the player
	local name, contact, power, eye, velocity, nastiness, control, stamina, speed, iq, age, salary, years, 
		defense,durability,hand,
		overall, potential;
	
	--Generate Name
	name = ng:generateName();

	--Non star
	if (posType == "SP") then
		velocity = math.random(25,60);	
		nastiness = math.random(25,60);	
		control = math.random(25,60);	
		stamina = math.random(0,90);	
		defense = math.random(0,70);
		iq = math.random(0,100);	
		age = math.random(18,35);
	elseif (posType == "RP") then
		velocity = math.random(25,60);	
		nastiness = math.random(25,60);	
		control = math.random(25,60);	
		stamina = math.random(0,100);
		defense = math.random(0,70);
		iq = math.random(0,100);	
		age = math.random(22,35);
	else --Batter type
		contact = math.random(25,60);
		power = math.random(25,60);	
		eye = math.random(25,60);	
		speed = math.random(10,100);
		defense = math.random(0,70);
		iq = math.random(0,100);	
		age = math.random(18,37);
	end


	--Determine overall and potential based off ratings
	--Fill in extraneous ratings
	if (posType == "SP" or posType == "RP") then
		overall = playerGenerator:getOverallRating(true, velocity, nastiness, control, stamina, defense);
		potential = playerGenerator:getPotential(overall, age);
		
		contact = math.random(0,20);
		power = math.random(0,20);	
		eye = math.random(0,20);
		speed = math.random(0,100);
	else
		--Batter
		overall = playerGenerator:getOverallRating(false, contact, power, eye, speed, defense);
		potential = playerGenerator:getPotential(overall, age);
		
		velocity = math.random(0,20);	
		nastiness = math.random(0,20);	
		control = math.random(0,20);	
		stamina = math.random(50,100);	
	end

	--Determine handedness
	if (posType == "SP" or posType == "RP") then
		if (math.random(1,100) <= 20) then
			--20% Left handed
			hand = "L"
		else
			hand = "R"
		end
	else 
		local num = math.random(1,100)
		if (num <= 25) then
			--25% Left handed
			hand = "L"
		elseif (num <= 35) then
			--10% Switch Hitter
			hand = "S"
		else
			hand = "R"
		end
	
	end
	
	durability = math.random(0,100);
	
	local yearsWanted = 1;
	local salaryWanted = fa:generateSalaryWanted(overall, potential, posType, age);
	local FA_mood = 0;
	local num = math.random(1,100);
	
	if (num <= 70) then
		--Happy 70%
		FA_mood = math.random(90,100);
	elseif (num <= 80) then
		FA_mood = math.random(30,100);
	else
		FA_mood = math.random(0,20);
	end
	
	player = {name = name, teamid = 31, contact = contact, power = power,
		eye = eye, velocity = velocity, nastiness = nastiness, control = control, stamina = stamina,
		speed = speed, defense = defense, durability = durability, hand = hand,
		iq = iq, age = age, salary = 0, years = 0, posType = posType,
		overall = overall, potential = potential, FA_salary_wanted = salaryWanted, FA_years_wanted = yearsWanted,
		FA_mood = FA_mood};
	
		
	ng:close()
	
	local insertQuery = [[INSERT INTO players VALUES ]] .. [[(NULL, ]] .. 
	player.teamid.. [[,]] .. [["]] .. player.posType.. [["]] .. [[,"]] .. player.name.. [["]] ..
	[[,"]] .. player.hand.. [["]] ..
	[[,]] .. player.age .. 
	[[,]] .. player.contact .. [[,]] .. player.power .. [[,]] .. player.eye .. 
	[[,]] .. player.velocity .. [[,]]  .. player.nastiness ..
	[[,]] .. player.control .. [[,]]  .. player.stamina .. 
	[[,]] .. player.speed .. [[,]] .. player.defense .. 
	[[,]] .. player.durability .. [[,]] .. player.iq ..
	[[,]] .. player.salary .. [[,]] .. player.years .. 
	[[,]] .. player.overall .. [[,]] .. player.potential ..
	[[,0,0,0,5,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,NULL,NULL,]] 
	.. player.FA_salary_wanted .. [[,]] .. player.FA_years_wanted .. [[,]] .. player.FA_mood .. [[,NULL,0,"2014 Undrafted");]]

	db:exec(insertQuery);
	
	local path2 = system.pathForFile("previousPlayerStats.db", system.DocumentsDirectory)
	local prevStats_db = sqlite3.open( path2 );
	for row in db:rows([[SELECT last_insert_rowid();]]) do
		--Gets id of last inserted player
		local playerid = row[1]
		local stmt = prevStats_db:prepare[[INSERT INTO history VALUES(?, NULL)]];
		stmt:bind_values(playerid) 
		stmt:step();
	end
	prevStats_db:close();
	
	print("GENERATING FREE AGENT: "  .. name)
end

--Draft functions
function playerGenerator:generateDraftPlayers()
	
	--3 rounds, but 90 players will be left undrafted
	local numPlayers = 180;
	
	
	ng:open()
	local players = {}; --Holds all the generated players in the draft
	for i = 1, numPlayers do 
		
		--Table of the positions played by the  players in the team
		local positions = {"SP", "SP", "SP", "SP", "SP", "SP", "SP", "SP", "SP", "RP", "RP", "RP", "RP",
		"RP", "RP", "C", "1B", "2B", "SS", "3B", "1B", "2B", "SS", "3B", "OF", "OF", "OF", "OF",
		"OF", "OF", "C", "C", "C", "C", "1B", "2B", "SS", "3B"}

		--Attributes of the player
		local name, contact, power, eye, velocity, nastiness, control, stamina, speed, iq, age, salary, years, posType,
			defense,durability,hand,overall, potential;
		
		--Generate Name
		name = ng:generateName();

		--Generate Ratings
		local isStar = (1 == math.random(1,100)) --1% chance of being a star
		local posType = positions[math.random(1,#positions)]
		if (isStar) then
		--Generate a star
			if (posType == "SP") then
				velocity = math.random(60,100);	
				nastiness = math.random(60,100);	
				control = math.random(60,100);	
				stamina = math.random(10,100);	
				defense = math.random(10,100);						
				iq = math.random(30,100);	
				age = math.random(18,32);
				years = math.random(1,7);
			elseif (posType == "RP") then
				velocity = math.random(60,100);	
				nastiness = math.random(60,100);	
				control = math.random(60,100);	
				stamina = math.random(10,100);
				defense = math.random(10,100);					
				iq = math.random(30,100);	
				age = math.random(22,34);
				years = math.random(1,5);
			else --Batter type
				contact = math.random(60,100);
				power = math.random(60,100);	
				eye = math.random(60,100);	
				speed = math.random(10,100);
				defense = math.random(10,100);					
				iq = math.random(30,100);	
				age = math.random(18,34);
				years = math.random(1,8);
			end
		else 
			--Non star
			if (posType == "SP") then
				velocity = math.random(25,70);	
				nastiness = math.random(25,70);	
				control = math.random(25,70);	
				stamina = math.random(0,90);	
				defense = math.random(0,100);
				iq = math.random(0,100);	
				age = math.random(18,35);
				years = math.random(1,5);
			elseif (posType == "RP") then
				velocity = math.random(25,70);	
				nastiness = math.random(25,70);	
				control = math.random(25,70);	
				stamina = math.random(0,100);
				defense = math.random(0,100);
				iq = math.random(0,100);	
				age = math.random(22,35);
				years = math.random(1,4);
			else --Batter type
				contact = math.random(25,70);
				power = math.random(25,70);	
				eye = math.random(25,70);	
				speed = math.random(20,100);
				defense = math.random(0,100);
				iq = math.random(0,100);	
				age = math.random(18,37);
				years = math.random(1,6);
			end

		end
		age = math.random(18,22);
		--Determine overall and potential based off ratings
		--Fill in extraneous ratings
		if (posType == "SP" or posType == "RP") then
			overall = playerGenerator:getOverallRating(true, velocity, nastiness, control, stamina, defense);
			potential = playerGenerator:getPotential(overall, age);
			
			contact = math.random(0,20);
			power = math.random(0,20);	
			eye = math.random(0,20);
			speed = math.random(0,100);
		else
			--Batter
			overall = playerGenerator:getOverallRating(false, contact, power, eye, speed, defense);
			potential = playerGenerator:getPotential(overall, age);
			
			velocity = math.random(0,20);	
			nastiness = math.random(0,20);	
			control = math.random(0,20);	
			stamina = math.random(50,100);	
		end
		

		--Determine handedness
		if (posType == "SP" or posType == "RP") then
			if (math.random(1,100) <= 20) then
				--20% Left handed
				hand = "L"
			else
				hand = "R"
			end
		else 
			local num = math.random(1,100)
			if (num <= 25) then
				--25% Left handed
				hand = "L"
			elseif (num <= 35) then
				--10% Switch Hitter
				hand = "S"
			else
				hand = "R"
			end
		
		end
		
		durability = math.random(0,100);

		
		players[#players+1] = {name = name, teamid = i, contact = contact, power = power,
		eye = eye, velocity = velocity, nastiness = nastiness, control = control, stamina = stamina,
		speed = speed, defense = defense, durability = durability, hand = hand,
		iq = iq, age = age, posType = posType, overall = overall, potential = potential};


		
	end
	ng:close()
	
	
	local path = system.pathForFile("data.db", system.DocumentsDirectory)
	db = sqlite3.open( path ) 
	db:exec("BEGIN TRANSACTION;")
	
	print ("Generating " .. #players .. " players!!!");
	for i = 1, #players do
		
		local player = players[i]
		local stmt = db:prepare[[INSERT INTO draft_players (id,posType,name,hand,age,contact,power,eye,velocity,nastiness,control,
			stamina,speed,defense,durability,iq,overall,potential) VALUES(NULL,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?);]];
		stmt:bind_values( player.posType, player.name, player.hand, player.age, player.contact, player.power, player.eye, player.velocity, 
			player.nastiness, player.control, player.stamina, player.speed, player.defense, player.durability,
			player.iq, player.overall, player.potential) 
		stmt:step();
	end
	
	playerGenerator:generateDraftProjections()
	
	db:exec("END TRANSACTION;")
	
	db:close()
end

function playerGenerator:generateDraftProjections()
	
	--Assume database (db) is already open
	local prospects = {}
	
	--Get all draft prospects
	for row in db:nrows([[SELECT * FROM draft_players]]) do
		prospects[#prospects+1] = {id = row.id, overall = row.overall, 
		potential = row.potential, age = row.age, posType = row.posType, playerScore = 0}
	end
	
	--Generate player score for all prospects
	for i = 1, #prospects do
	
		local playerScore = playerGenerator:generatePlayerScore( prospects[i].overall, prospects[i].potential, 
			prospects[i].age, prospects[i].posType)

		--Add some fuzzing to make draft projections innacurate sometimes
		local num = math.random(1,100);
		local fuzz = 1; --Fuzz Coefficient
		
		
		if (5 >= num) then
			--5% chance of being very inaccurate
			--Fuzz ranges from .7 to 1.3
			fuzz = math.random(7,13)*.1
		elseif (35 >= num) then
			--30% chance of being slightly inaccurate
			--Fuzz ranges from .9 to 1.1
			fuzz = math.random(9,11)*.1
			
			--65% chance of being completely accurate
		end
		
		--Apply fuzz to player score
		playerScore = playerScore * fuzz
		
		prospects[i].playerScore = playerScore
	end
	
	
	--Sort prospects by player score (high to low)
	function byval(a,b)
        return a.playerScore > b.playerScore
    end
	table.sort(prospects,byval)
	
	
	--Assign draftProjections based on order
	for i = 1, #prospects do
		
		local prospect = prospects[i]
		if (i <= 5) then prospect.draftProjection = "Top 5"
		elseif (i <= 10) then prospect.draftProjection = "Top 10"
		elseif (i <= 30) then prospect.draftProjection = "Round 1"
		elseif (i <= 60) then prospect.draftProjection = "Round 2"
		elseif (i <= 90) then prospect.draftProjection = "Round 3"
		else prospect.draftProjection = "Undrafted" end
	end
	
	--Record draftProjection to database
	for i = 1, #prospects do
		
		local stmt = db:prepare[[UPDATE draft_players SET draftProjection = ? where id = ?]];
		stmt:bind_values( prospects[i].draftProjection, prospects[i].id) 
		stmt:step();
	end
	
end

function playerGenerator:generatePlayerScore(overall, potential, age, posType)
	--Generate playerScore for draft prospect
	local playerScore = 0

	playerScore = overall*2+potential
	
	if (posType == "SP") then playerScore = playerScore * 1.1 
	elseif (posType == "RP") then playerScore = playerScore * .9 end
	
	 --18 yrs = + 10, 22 yrs = -10
	local ageScore = (-5)*age + 100;
	playerScore = playerScore+ageScore;
	
	return playerScore
end



function playerGenerator:getOverallRating(isPitcher, a, b, c, d, e)

	if (isPitcher) then
	--For pitchers, parameters should be [velocity, nastiness, control, stamina, defense]
	return math.floor((10*a + 7*b + 7*c + 2*d + e)/27);
	end
	
	--For batters, parameters should be [contact, power, eye, speed, defense]
	return math.floor((5*a + 5*b + 3*c + 1*d + 3*e)/17);
	
	
end

function playerGenerator:getPotential(overall, age)
	
	local noPotential = false
	local maxPotentialIncrease = 100-overall;
	local potential = 0;
	
	if (age <= 23) then
		local rand = math.random(1,3)
		potential = math.random(maxPotentialIncrease/4,maxPotentialIncrease);
		noPotential = (45>=math.random(1,100)) --45% chance of no potential
	elseif (age <= 28) then
		maxPotentialIncrease = maxPotentialIncrease/2;
		potential = math.random(0,maxPotentialIncrease);
		noPotential = (70>=math.random(1,100)) --70% chance of no potential
	elseif (age <= 32) then
		maxPotentialIncrease = maxPotentialIncrease/4;
		potential = math.random(0,maxPotentialIncrease);
		noPotential = (80>=math.random(1,100)) --80% chance of no potential
	else
		potential = 0;
	end
	
	
	
	if (noPotential) then
		return overall
	else
		return overall + potential;
	end

end




return playerGenerator