
local attendance = {
	
	ticketCost = 50
	
}

function attendance:determineAttendance(support, population)

	local populationUnit = math.pow(population, (1/3)); 
	local numPopulationUnits = (support + 4) * 4
	local attendanceEstimate = math.floor(populationUnit * numPopulationUnits)
	if (attendanceEstimate > 40000) then attendanceEstimate = 40000 end
	
	return attendanceEstimate

end

function attendance:determineAttendanceWithFuzz(support, population, fuzz)

	local populationUnit = math.pow(population, (1/3)); 
	local numPopulationUnits = (support + 4) * 4
	local attendanceEstimate = math.floor(populationUnit * (numPopulationUnits + fuzz))
	
	--Max attendance is 40000, Min attendance is 0, May change this in the future
	if (attendanceEstimate > 40000) then attendanceEstimate = 40000
	elseif (attendanceEstimate < 3000) then attendanceEstimate = 3000 end
	
	return attendanceEstimate

end

function attendance:determineRevenue(numAttend)

	return numAttend * attendance.ticketCost;

end


return attendance