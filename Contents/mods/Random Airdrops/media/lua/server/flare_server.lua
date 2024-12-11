--
-- AIRDROP SMOKE FLARE
--
-- Declaramos as variaveis
local tickBeforeNextZed = 10;
local actualTick = 0;

local zombieOutfitTable = {
    "AirCrew", "AmbulanceDriver", "ArmyCamoDesert", "ArmyCamoGreen", "ArmyServiceUniform",
    "Bandit", "BaseballFan_KY", "BaseballFan_Rangers", "BaseballFan_Z", "BaseballPlayer_KY", "BaseballPlayer_Rangers",
    "BaseballPlayer_Z", "Bathrobe", "Bedroom", "Biker", "Bowling", "BoxingBlue", "BoxingRed", "Camper", "Chef", "Classy",
    "Cook_Generic", "Cook_IceCream", "Cook_Spiffos", "Cyclist", "Doctor", "DressLong", "DressNormal", "DressShort",
    "Farmer", "Fireman", "FiremanFullSuit", "FitnessInstructor", "Fossoil", "Gas2Go", "Generic_Skirt", "Generic01",
    "Generic02", "Generic03", "Generic04", "Generic05", "GigaMart_Employee", "Golfer", "HazardSuit", "Hobbo",
    "HospitalPatient", "Jackie_Jaye", "Joan", "Jockey04", "Jockey05", "Kate", "Kirsty_Kormick", "Mannequin1",
    "Mannequin2", "Nurse", "OfficeWorkerSkirt", "Party", "Pharmacist", "Police", "PoliceState", "Postal",
    "PrivateMilitia", "Punk", "Ranger", "Redneck", "Rocker", "Santa", "SantaGreen", "ShellSuit_Black", "ShellSuit_Blue",
    "ShellSuit_Green", "ShellSuit_Pink", "ShellSuit_Teal", "Ski Spiffo", "SportsFan", "StreetSports", "StripperBlack",
    "StripperPink", "Student", "Survivalist", "Survivalist02", "Survivalist03", "Swimmer", "Teacher", "ThunderGas",
    "TinFoilHat", "Tourist", "Trader", "TutorialMom", "Varsity", "Waiter_Classy", "Waiter_Diner", "Waiter_Market",
    "Waiter_PileOCrepe", "Waiter_PizzaWhirled", "Waiter_Restaurant", "Waiter_Spiffo", "Waiter_TachoDelPancho",
    "WaiterStripper", "Young", "Bob", "ConstructionWorker", "Dean", "Duke", "Fisherman", "Frank_Hemingway", "Ghillie",
    "Groom", "HockeyPsycho", "Hunter", "Inmate", "InmateEscaped", "InmateKhaki", "Jewelry", "Jockey01", "Jockey02",
    "Jockey03", "Jockey06", "John", "Judge_Matt_Hass", "MallSecurity", "Mayor_West_point", "McCoys", "Mechanic",
    "MetalWorker", "OfficeWorker", "PokerDealer", "PoliceRiot", "Priest", "PrisonGuard", "Rev_Peter_Watts", "Raider",
    "Security", "Sir_Twiggy", "Thug", "TutorialDad", "Veteran", "Waiter_TacoDelPancho", "Woodcut"
};

-- Mude isso para os zumbis raros que voce quer durante o airdrop, esses zumbis fazem parte do
-- mod Factoins Clothes do Project Factions do Dogao Games
local zombieRareOutfitTable = {
    "KATTAJ1_Army_Black", "KATTAJ1_Army_Green", "KATTAJ1_Army_Desert", "KATTAJ1_Army_White", "Stalker", "Nomad",
    "OminousNomad", "Prepper", "Headhunter", "DeadlyHeadhunter", "Amazona"
}
local playerSmokeFlares = {};

-- Adicionamos uma unidade de zumbi ao redor do jogador
local function SpawnOneZombie(player)
    local pLocation = player:getCurrentSquare();
    local zLocationX = 0;
    local zLocationY = 0;
    local canSpawn = false;
    local sandboxDistance = SandboxVars.AirdropMain.SmokeFlareHordeDistanceSpawn;
    for i = 0, 100 do
        if ZombRand(2) == 0 then
            zLocationX = ZombRand(10) - 10 + sandboxDistance;
            zLocationY = ZombRand(sandboxDistance * 2) - sandboxDistance;
            if ZombRand(2) == 0 then
                zLocationX = 0 - zLocationX;
            end
        else
            zLocationY = ZombRand(10) - 10 + sandboxDistance;
            zLocationX = ZombRand(sandboxDistance * 2) - sandboxDistance;
            if ZombRand(2) == 0 then
                zLocationY = 0 - zLocationY;
            end
        end
        zLocationX = zLocationX + pLocation:getX();
        zLocationY = zLocationY + pLocation:getY();
        local spawnSpace = getWorld():getCell():getGridSquare(zLocationX, zLocationY, 0);
        if spawnSpace then
            local isSafehouse = SafeHouse.getSafeHouse(spawnSpace);
            if spawnSpace:isSafeToSpawn() and spawnSpace:isOutside() and isSafehouse == nil then
                canSpawn = true;
                break
            end
        else
            print("[Air Drop] Zombie: Space not Loaded " .. player:getUsername());
        end
        if i == 100 then
            print("[Air Drop] Zombie: Can't find a place to spawn " .. player:getUsername());
        end
    end
    if canSpawn then
        -- Zumbis raros tem 1% de chance de aparecer
        -- a cada 100 zumbis 1 vai ser raro
        local outfit
        if ZombRand(100) + 1 == 1 then
            outfit = zombieRareOutfitTable[ZombRand(11) + 1];
        else
            outfit = zombieOutfitTable[ZombRand(139) + 1];
        end
        -- Adicionamos o zumbi
        addZombiesInOutfit(zLocationX, zLocationY, 0, 1, outfit, 50, false, false, false, false, 1.5);
        -- Adiciona mais um zumbi a tabela zombie spawned
        playerSmokeFlares[player:getUsername()]["zombieSpawned"] = playerSmokeFlares[player:getUsername()]["zombieSpawned"] + 1;
        -- Por fim adicionamos um barulho para os zumbis ouvirem e perseguir o jogador
        getWorldSoundManager():addSound(player, player:getCurrentSquare():getX(),
                player:getCurrentSquare():getY(), player:getCurrentSquare():getZ(), 200, 10);
    end
end

-- Inicia a horda, se specificPlayer for adicionado como parametro
-- a horda começara somente por ele
function StartHorde(specificPlayer)
    -- Valor aleatorizado entre metade e o dobro
    local zombieCount = SandboxVars.AirdropMain.SmokeFlareHorde * ((ZombRand(150) / 100) + 0.5);

    -- Calculamos a dificuldade
    local difficulty
    if SandboxVars.AirdropMain.SmokeFlareHorde > zombieCount then
        difficulty = "Easy";
    else
        difficulty = "Hard";
    end

    -- Adicionamos a tabela de spawn do jogador
    playerSmokeFlares[specificPlayer:getUsername()] = {};
    playerSmokeFlares[specificPlayer:getUsername()]["zombieCount"] = zombieCount;
    playerSmokeFlares[specificPlayer:getUsername()]["zombieSpawned"] = 0;
    playerSmokeFlares[specificPlayer:getUsername()]["player"] = specificPlayer;
    playerSmokeFlares[specificPlayer:getUsername()]["airdropArea"] = {
        x = specificPlayer:getX(),
        y = specificPlayer:getY(),
        z = specificPlayer:getZ()
    };

    local players = getOnlinePlayers();
    -- Compatibilidade com singleplayer
    if not players then
        -- Texto do Som para emitir ao jogador
        local alarmSound = "smokeflareradio" .. tostring(ZombRand(1));
        -- Alocamos o som que vai sair
        local sound = getSoundManager():PlaySound(alarmSound, false, 0);
        -- Soltamos o som parao  jogador
        getSoundManager():PlayAsMusic(alarmSound, sound, false, 0);
        sound:setVolume(0.1);
    else -- Caso contrario é um servidor prossiga normal
        -- Alertamos todos os jogadores que um airdrop foi spawnado
        for i = 0, players:size() - 1 do
            -- Obtém o jogador pelo índice
            local player = players:get(i);
            -- Emite o alerta ao jogador
            sendServerCommand(specificPlayer, "ServerAirdrop", "smokeflare", { difficulty = difficulty });
        end
    end

    --Mensagem de log
    print("[Air Drop] Smoke Flare called, spawning on: " .. specificPlayer:getUsername() .. " quantity: " .. zombieCount);

    -- Adicionamos o OnTick para spawnar os zumbis
    Events.OnTick.Add(CheckHordeRemainingForSmokeFlare);
end

-- Checamos se a horda já foi finalizada
function CheckHordeRemainingForSmokeFlare()
    -- Atualizamos o tick
    if actualTick <= tickBeforeNextZed then
        actualTick = actualTick + 1;
        return
    end
    actualTick = 0;

    -- Fazemos uma varredura para verificar se todos os zumbis ja spawnaram para o player
    local allZombiesSpawned = true;
    for playerUsername, playerSpawns in pairs(playerSmokeFlares) do
        if not isClient() and not isServer() then
            -- singleplayer
            for i = 0, getNumActivePlayers() - 1 do
                local player = getSpecificPlayer(i)
                if player:getUsername() == playerUsername then
                    -- Verificamos se o jogador já spawnou o suficiente
                    if playerSpawns.zombieSpawned < playerSpawns.zombieCount then
                        allZombiesSpawned = false;
                        SpawnOneZombie(player);
                    end
                end
            end
        else
            -- multiplayer
            -- Recebemos o personagem atraves do username
            local players = getOnlinePlayers();
            for i = 0, players:size() - 1 do
                -- Obtém o jogador pelo índice
                local player = players:get(i);
                -- Fazemos uma varredura para descobrir o IsoPlayer
                if player:getUsername() == playerUsername then
                    -- Verificamos se o jogador já spawnou o suficiente
                    if playerSpawns.zombieSpawned < playerSpawns.zombieCount then
                        allZombiesSpawned = false;
                        SpawnOneZombie(player);
                    end
                end
            end
            -- Se não encontrou o jogador remove porque ele kitou corno
            if not found then
                playerSmokeFlares[playerUsername] = nil;
            end
        end
    end

    -- Damos dispose na função caso todos os zumbis foram spawnados
    if allZombiesSpawned then
        -- Resetamos as Variaveis
        Events.OnTick.Remove(CheckHordeRemainingForSmokeFlare);
        for playerUsername, playerSpawns in pairs(playerSmokeFlares) do
            if not isClient() and not isServer() then
                -- singleplayer
                -- Texto do Som para emitir ao jogador
                local alarmSound = "airdrop" .. tostring(ZombRand(1));
                -- Alocamos o som que vai sair
                local sound = getSoundManager():PlaySound(alarmSound, false, 0);
                -- Soltamos o som parao  jogador
                getSoundManager():PlayAsMusic(alarmSound, sound, false, 0);
                sound:setVolume(0.1);
            else
                local players = getOnlinePlayers();
                -- Avisamos o jogador que spawnou o airdrop
                for i = 0, players:size() - 1 do
                    -- Obtém o jogador pelo índice
                    local player = players:get(i);
                    -- Fazemos uma varredura para descobrir o IsoPlayer
                    if player:getUsername() == playerUsername then
                        sendServerCommand(player, "ServerHorde", "smokeflare_finished", nil);
                    end
                end
            end
            SpawnSpecificAirdrop(playerSpawns.airdropArea);
        end
        playerSmokeFlares = {};
        print("[Air Drop] Smoke Flare finished airdrop has been Spawned");
        return
    end
end

function Recipe.OnCreate.StartBeacon(items, result, player)
    sendClientCommand( player,'ServerAirdrop', 'startBeacon', nil);
end

-- Handler para as mensagens do client
Events.OnClientCommand.Add(function(module, command, player, args)
    if module == "ServerAirdrop" and command == "startBeacon" then
        -- Precisamos checar se o jogador já não esta em uma horda de beacon
        for playerUsername, playerSpawns in pairs(playerSmokeFlares) do
            if player:getUsername() == playerUsername then
                print("[Air Drop] " .. player:getUsername() .. " trying to use a smoke flare again...")
                return;
            end
        end
        StartHorde(player);
    end
end)