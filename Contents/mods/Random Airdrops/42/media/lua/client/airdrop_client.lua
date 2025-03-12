---@diagnostic disable: undefined-global

RandomAirdrops = RandomAirdrops or {};
airdrop_client = {};


airdrop_client.x = 0
airdrop_client.y = 0
local function getCompassDirection(playerX, playerY, targetX, targetY)
	airdrop_client.x = targetX
	airdrop_client.y = targetY

	local dX = targetX - playerX;
	local dY = playerY - targetY;

	local angleRadians = math.atan2(dY, dX);

	local angleDegrees = angleRadians * (180 / math.pi)

	if angleDegrees < 0 then
		angleDegrees = angleDegrees + 360
	end

	local compassAngle = (90 - angleDegrees)
	if compassAngle < 0 then
		compassAngle = compassAngle + 360
	end

	local directions = {
		{ name = "North",     min = 337.5, max = 360 },
		{ name = "North",     min = 0,     max = 22.5 },
		{ name = "NorthEast", min = 22.5,  max = 67.5 },
		{ name = "East",      min = 67.5,  max = 112.5 },
		{ name = "SouthEast", min = 112.5, max = 157.5 },
		{ name = "South",     min = 157.5, max = 202.5 },
		{ name = "SouthWest", min = 202.5, max = 247.5 },
		{ name = "West",      min = 247.5, max = 292.5 },
		{ name = "NorthWest", min = 292.5, max = 337.5 }
	}
	local result = "Unknown"
	for _, dir in ipairs(directions) do
		if dir.min > dir.max then
			if compassAngle >= dir.min or compassAngle < dir.max then
				result = getText("IGUI_Airdrop_Direction_"..dir.name)
				break
			end
		else
			if compassAngle >= dir.min and compassAngle < dir.max then
				result = getText("IGUI_Airdrop_Direction_"..dir.name)
				break
			end
		end
	end

	return result
end

function RandomAirdrops.FlyOver(_arguments)
	local player = getPlayer()
	local pX, pY = player:getX(), player:getY();

	local airdropX, airdropY = _arguments.x, _arguments.y

	local dX = airdropX - pX;
	local dY = airdropY - pY;
	local distance = math.sqrt(dX * dX + dY * dY);

	if player:isAsleep() or player:isDead() then
		return
	end

	if distance > 200 then
		player:playSound("FarAirdropSoundPlane");
		local direction = getCompassDirection(pX, pY, airdropX, airdropY)

		player:setHaloNote(getText("IGUI_Airdrop_Plane_Seeing").." "..direction, 255, 255, 255, 1000);
	else
		return
	end
end

