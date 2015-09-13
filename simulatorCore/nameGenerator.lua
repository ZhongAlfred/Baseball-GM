local sqlite3 = require "sqlite3"

local nameGenerator = {db = nil}

function nameGenerator:generateFirstName(female)
	
	local name
	local max = 90051
	local dbTable = "maleFirstName"
	
	if (female) then
		dbTable = "femaleFirstName"
		max = 89939
	end
	
	--Slows down generation, use manual values instead
	--local max;
	--for row in nameGenerator.db:nrows([[SELECT MAX(max) FROM ]] .. dbTable) do
	--	max = row["MAX(max)"] * 1000 - 1
	--end
	
	local randomNum = math.random(0,max)/1000
	
	for row in nameGenerator.db:nrows([[SELECT NAME FROM ]] .. dbTable .. [[ WHERE max > ]] .. randomNum .. [[ LIMIT 1;]]) do
		name = row.NAME;
	end

	return name;
end

function nameGenerator:generateLastName()
	
	local name
	local max = 63256
	local dbTable = "lastName"
	
	--Slows down generation, use manual values instead
	--local max;
	--for row in nameGenerator.db:nrows([[SELECT MAX(max) FROM ]] .. dbTable) do
	--	max = row["MAX(max)"] * 1000 - 1
	--end
	
	local randomNum = math.random(0,max)/1000
	for row in nameGenerator.db:nrows([[SELECT NAME FROM ]] .. dbTable .. [[ WHERE max > ]] .. randomNum .. [[ LIMIT 1;]]) do
		name = row.NAME;
	end

	return name;

end

function nameGenerator:generateName(female)
	return nameGenerator:generateFirstName(female) .. " " .. nameGenerator:generateLastName()
end

function nameGenerator:open()
	local path = system.pathForFile("data/names.db", system.ResourceDirectory)
	nameGenerator.db = sqlite3.open( path ) 
end

function nameGenerator:close()
	nameGenerator.db:close() 
end

return nameGenerator