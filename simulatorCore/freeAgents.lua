
local freeAgents = {}

function freeAgents:generateSalaryWanted(overall, potential, position, age, noFuzz)
	
	--Factor in potential to player overall
	local x = (5*overall + potential) / 6;
	
	local base = 0;
	--Logistic model yield SALARY
	--Range approx [.5,30]
	local e = math.exp(1) --Mathematical constant
	
	base = 31.63/(1+59151*e^(-.15445*x))
	base = base * 1000000
	
	if (position == "RP") then --Relief pitchers not worth as much
		base = base/3;
	end
	
	if (noFuzz ~= true) then
		local randomVariance = math.ceil(base/5);
		base = base + math.random(-randomVariance, randomVariance);
	end
	
	if (base < 500000) then base = 500000 end
	if (base > 30000000) then base = 30000000 end
	
	return math.floor(base)

end

function freeAgents:generateYearsWanted(overall, potential, position, age)
	
	local years
	if (age < 27) then
		years = math.random(3,10)
	elseif (age < 30) then
		years = math.random(2,4)
	elseif (age < 35) then
		years = math.random(3,10)
	else
		years = math.random(1,3)
	end
	
	if ((potential - overall) > 30) then
		years = years - 2;
	elseif ((potential - overall) > 15) then
		years = years - 1;
	end
	
	if (years < 1) then years = 1 end
	return years

end

function freeAgents:generateMood()
	
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
	
	return FA_mood
end

function freeAgents:determineOfferRating(salaryWanted, yearsWanted, salaryOffered, yearsOffered)
	local sw, yw, so, yo = salaryWanted, yearsWanted, salaryOffered, yearsOffered
	
	local rating = (so/sw) * 100
	local yearsDisparity = (  1  -  math.abs(yo-yw)/10);
	
	return rating * yearsDisparity

end

return freeAgents