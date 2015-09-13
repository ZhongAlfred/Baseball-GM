
local tv = {
	
}

function tv:determineTVRevenue(population)
	
	population = population * .000001
	local revenue = (45/14)*population +(50/14)
	revenue = revenue * 1000000

	return math.floor(revenue)
end

return tv