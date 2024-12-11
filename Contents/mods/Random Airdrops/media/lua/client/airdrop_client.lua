---@diagnostic disable: undefined-global

-- Добавляет текст игроку
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

-- Вызывается всякий раз, когда сервер возвращает нам значение
local function OnServerCommand(module, command, arguments)
	-- Звуковое оповещение при падении airdrop
	if module == "ServerAirdrop" and command == "alert" then
		-- Текст звука для того чтобы послать к игроку
		local alarmSound = "airdrop" .. tostring(ZombRand(1));
		-- Выделяем звук, который выйдет
		local sound = getSoundManager():PlaySound(alarmSound, false, 0);
		-- Мы отпускаем звук для игрока
		getSoundManager():PlayAsMusic(alarmSound, sound, false, 0);
		sound:setVolume(0.1);

		-- Сообщение в чате о том, что прошел спавн
		addLineToChat(getText("IGUI_Airdrop_Incoming") .. ": " .. getText("IGUI_Airdrop_Name_" .. arguments.name),
			"<RGB:" .. "0,255,0" .. ">");
	end
	-- Звуковое оповещение, когда игрок использует флейр
	if module == "ServerAirdrop" and command == "smokeflare" then
		-- Текст звука для того чтобы послать к игроку
		local alarmSound = "smokeflareradio" .. tostring(ZombRand(1));

		-- Выделяем звук, который выйдет
		local sound = getSoundManager():PlaySound(alarmSound, false, 0);
		-- Мы отпускаем звук для игрока
		getSoundManager():PlayAsMusic(alarmSound, sound, false, 0);
		sound:setVolume(0.4);

		-- Сообщение в чате о том, что прошел спавн
		addLineToChat(
			getText("IGUI_Airdrop_Smoke_Flare_Message"), "<RGB:" .. "255,0,0" .. ">");
	end
	if module == "ServerAirdrop" and command == "smokeflare_finished" then
		-- Текст звука для того чтобы послать к игроку
		local alarmSound = "airdrop" .. tostring(ZombRand(1));

		-- Выделяем звук, который выйдет
		local sound = getSoundManager():PlaySound(alarmSound, false, 0);
		-- Мы отпускаем звук для игрока
		getSoundManager():PlayAsMusic(alarmSound, sound, false, 0);
		sound:setVolume(0.1);

		-- Сообщение в чате о том, что прошел спавн
		addLineToChat(
			getText("IGUI_Airdrop_Spawned"), "<RGB:" .. "255,0,0" .. ">");
	end
end
Events.OnServerCommand.Add(OnServerCommand)