local BiezeModule = {} -- basic quadratic bezier module forked from somewhere

local function lerp(a,b,t)
	return a+(b-a) * t
end

function BiezeModule.elapsedTime(t)
	return 1-(1-2*t)^2
end

function BiezeModule.quadraticBieze(a,b,c,t)
	local dot1 = lerp(a,b,t)
	local dot2 = lerp(b,c,t)
	local finaledot = lerp(dot1,dot2,t)	

	return finaledot
end

return BiezeModule