local UTIL = {}

function UTIL.ms_to_min_sec(ms)
	if not ms then
		return "0:00"
	end
	local total_seconds = math.floor(ms / 1000)
	local minutes = math.floor(total_seconds / 60)
	local seconds = total_seconds % 60
	return string.format("%d:%02d", minutes, seconds)
end

function UTIL.angle_to_destination(x_pos, z_pos, x_dest, z_dest)
	local dx = x_dest - x_pos
	local dz = z_dest - z_pos

	local angle_rad = math.atan2(-dx, dz)
	local angle_deg = math.deg(angle_rad)

	angle_deg = ((angle_deg + 180) % 360) - 180

	return angle_deg
end

function UTIL.round(n)
	return math.floor(n * 100 + 0.5) / 100
end

function UTIL.angle_difference(a1, a2)
	local diff = a2 - a1
	diff = (diff + 180) % 360 - 180
	return diff
end

return UTIL
