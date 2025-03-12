require "radio/ISDynamicRadio"

RandomAirdrops = RandomAirdrops or {}

airdropRadio = airdropRadio or {};
airdropRadio.channelUUID = "AirdropRadio-AnimeAss";

local config =
    { --channel
        name = "Military Broadcast Channel",
        freq = { 88000, 108000 },
        category = "Emergency",
        uuid = "AirdropRadio-AnimeAss",
        register = true,
        airCounterMultiplier = 2.0,
    };

table.insert(DynamicRadio.channels, config)

function airdropRadio.OnLoadRadioScripts(_scriptManager)
    airdropRadio.Init();
    table.insert(DynamicRadio.scripts, airdropRadio);
end

function airdropRadio.Init()
    return
end

airdropRadio.lastAirdropDay = nil
function airdropRadio.OnEveryHour(_channel, _gametime)
    local currentDay = _gametime:getDay();
    -- Если деспавн не выключен - убираем аирдропы
    if not SandboxVars.AirdropMain.AirdropDisableDespawn then
        RandomAirdrops.DespawnAirdrops();
    end

    -- Если за этот день уже появлялся аирдроп - выходим из функции
    if airdropRadio.lastAirdropDay == currentDay then
        return
    end
    local airdropSpawnAreaName = RandomAirdrops.CheckAirdrop();
    if not airdropSpawnAreaName == false then
        local bc = airdropRadio.CreateBroadcast(airdropSpawnAreaName);
        _channel:setAiringBroadcast(bc);
        airdropRadio.lastAirdropDay = currentDay;
    end
end

Events.OnLoadRadioScripts.Add(airdropRadio.OnLoadRadioScripts());

function airdropRadio.CreateBroadcast(_airdropName)
    local bc = RadioBroadCast.new("GEN-"..tostring(ZombRand(100000,999999)),-1,-1);
    airdropRadio.FillBroadcast(bc, _airdropName);
    return bc;
end

function airdropRadio.FillBroadcast(_bc, _airdropName)
    local rand = newrandom()
    local _nameRandom = rand:random(1,3)
    local c = {r=1.0,g=1.0,b=1.0}

    airdropRadio.AddFuzz(c, _bc);

    airdropRadio.GetIntroString(_bc, _nameRandom);

    airdropRadio.GetMessageString(_bc, _nameRandom, _airdropName);

    --airdropRadio.GetCordMessageString(_bc, _airdropName);

    airdropRadio.GetArrivalTimeString(_bc, _nameRandom);

    airdropRadio.GetOutroString(_bc, _nameRandom);

    airdropRadio.AddFuzz(c, _bc);
end

function airdropRadio.AddFuzz(_c, _bc, _chance)
    local rand = ZombRand(1,_chance or 12);
    if rand==1 or rand==2 then
        _bc:AddRadioLine( RadioLine.new("<bzzt>", _c.r, _c.g, _c.b) );
    elseif rand==3 or rand==4 then
        _bc:AddRadioLine( RadioLine.new("<fzzt>", _c.r, _c.g, _c.b) );
    elseif rand==5 or rand==6 then
        _bc:AddRadioLine( RadioLine.new("<wzzt>", _c.r, _c.g, _c.b) );
    end
end

function airdropRadio.GetIntroString(_bc, _nameRandom)
    local rand = newrandom();
    local s = "";
    local c = {};

    if _nameRandom == 1 then
        local lineNum = rand:random(1, RadioChatter.Alpha.Intros);
        local str = string.format("IGUI_AirdropRadio_Intro_Alpha_%s", lineNum);
        s = getText(str);
        c = RadioChatter.Alpha.c;
    elseif _nameRandom == 2 then
        local lineNum = rand:random(1, RadioChatter.Bravo.Intros);
        local str = string.format("IGUI_AirdropRadio_Intro_Bravo_%s", lineNum);
        s = getText(str);
        c = RadioChatter.Bravo.c;
    elseif _nameRandom == 3 then
        local lineNum = rand:random(1, RadioChatter.Charlie.Intros);
        local str = string.format("IGUI_AirdropRadio_Intro_Charlie_%s", lineNum);
        s = getText(str);
        c = RadioChatter.Charlie.c;
    end
    _bc:AddRadioLine(RadioLine.new(s, c.r, c.g, c.b));
end

function airdropRadio.GetOutroString(_bc, _nameRandom)
    local rand = newrandom();
    local s = "";
    local c = {};

    if _nameRandom == 1 then
        local lineNum = rand:random(1, RadioChatter.Alpha.Outros);
        local str = string.format("IGUI_AirdropRadio_Outro_Alpha_%s", lineNum);
        s = getText(str);
        c = RadioChatter.Alpha.c;
    elseif _nameRandom == 2 then
        local lineNum = rand:random(1, RadioChatter.Bravo.Outros);
        local str = string.format("IGUI_AirdropRadio_Outro_Bravo_%s", lineNum);
        s = getText(str);
        c = RadioChatter.Bravo.c;
    elseif _nameRandom == 3 then
        local lineNum = rand:random(1, RadioChatter.Charlie.Outros);
        local str = string.format("IGUI_AirdropRadio_Outro_Charlie_%s", lineNum);
        s = getText(str);
        c = RadioChatter.Charlie.c;
    end
    _bc:AddRadioLine(RadioLine.new(s, c.r, c.g, c.b));
end

function airdropRadio.GetMessageString(_bc, _nameRandom, _airdropName)
    local rand = newrandom();
    local s = "";
    local c = {};
    local lineNum = rand:random(1,4);
    local str = string.format("IGUI_AirdropRadio_Message_%s", lineNum);
    s = getText(str).." "..getText(string.format("IGUI_Airdrop_Name_%s", _airdropName))
    if _nameRandom == 1 then
        c = RadioChatter.Alpha.c;
    elseif _nameRandom == 2 then
        c = RadioChatter.Bravo.c;
    elseif _nameRandom == 3 then
        c = RadioChatter.Charlie.c;
    end
    _bc:AddRadioLine(RadioLine.new(s, c.r, c.g, c.b));
end

function airdropRadio.GetArrivalTimeString(_bc, _nameRandom)
    local s = ""
    local c = {}
    s = getText("IGUI_AirdropRadio_ArrivalTime")
    if _nameRandom == 1 then
        c = RadioChatter.Alpha.c;
    elseif _nameRandom == 2 then
        c = RadioChatter.Bravo.c;
    elseif _nameRandom == 3 then
        c = RadioChatter.Charlie.c;
    end
    _bc:AddRadioLine(RadioLine.new(s, c.r, c.g, c.b));
    --RandomAirdrops.GettingRadioInfo(airdropRadio.channelUUID);
end
--
--function airdropRadio.GetCordMessageString(_bc, _airdropName)
--    local s = ""
--    local c = {}
--    s = getText("IGUI_AirdropRadio_Coordinates").." "
--end

RadioChatter = {}
RadioChatter.Alpha = {}
RadioChatter.Alpha.c = {}
RadioChatter.Alpha.c.r = 0.0
RadioChatter.Alpha.c.g = 0.5
RadioChatter.Alpha.c.b = 0.0
RadioChatter.Alpha.Intros = 4
RadioChatter.Alpha.Outros = 4

RadioChatter.Bravo = {}
RadioChatter.Bravo.c = {}
RadioChatter.Bravo.c.r = 0.27
RadioChatter.Bravo.c.g = 0.51
RadioChatter.Bravo.c.b = 0.71
RadioChatter.Bravo.Intros = 4
RadioChatter.Bravo.Outros = 4

RadioChatter.Charlie = {}
RadioChatter.Charlie.c = {}
RadioChatter.Charlie.c.r = 0.55
RadioChatter.Charlie.c.g = 0
RadioChatter.Charlie.c.b = 0
RadioChatter.Charlie.Intros = 4
RadioChatter.Charlie.Outros = 4