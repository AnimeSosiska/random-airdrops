---@diagnostic disable: undefined-global

RandomAirdrops = RandomAirdrops or {};
airdrop_client = {};

airdrop_client.allow = false;
airdrop_client.x = 0;
airdrop_client.y = 0;

local function addLineToChat(message, color, username, options)
	if not isClient() then return end

	if type(options) ~= "table" then
		options = {
			showTime = false,
			serverAlert = false,
			showAuthor = false,
		};
	end

	if type(color) ~= "string" then
		color = "<RGB:1,1,1>";
	end

	if options.showTime then
		local dateStamp = Calendar.getInstance():getTime();
		local dateFormat = SimpleDateFormat.new("H:mm");
		if dateStamp and dateFormat then
			message = color .. "[" .. tostring(dateFormat:format(dateStamp) or "N/A") .. "]  " .. message;
		end
	else
		message = color .. message;
	end

	local msg = {
		getText = function(_)
			return message;
		end,
		getTextWithPrefix = function(_)
			return message;
		end,
		isServerAlert = function(_)
			return options.serverAlert;
		end,
		isShowAuthor = function(_)
			return options.showAuthor;
		end,
		getAuthor = function(_)
			return tostring(username);
		end,
		setShouldAttractZombies = function(_)
			return false
		end,
		setOverHeadSpeech = function(_)
			return false
		end,
	};

	if not ISChat.instance then return; end;
	if not ISChat.instance.chatText then return; end;
	ISChat.addLineInChat(msg, 0);
end

local function getCompassDirection(playerX, playerY, targetX, targetY)
	local dX = targetX - playerX;
	local dY = targetY - playerY;

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
	local pX, pY = getPlayer():getX(), getPlayer():getY();

	local airdropX, airdropY = _arguments.x, _arguments.y

	local dX = airdropX - pX;
	local dY = airdropY - pY;
	local distance = math.sqrt(dX * dX + dY * dY);

	if distance > 200 then
		getPlayer():playSound("FarAirdropSoundPlane");
		local direction = getCompassDirection(pX, pY, airdropX, airdropY)

		getPlayer():setHaloNote(getText("IGUI_Airdrop_Plane_Seeing").." "..direction, 255, 255, 255, 1000);
	else
		return
	end
end

