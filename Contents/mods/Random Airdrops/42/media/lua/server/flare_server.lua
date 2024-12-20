--
-- AIRDROP SMOKE FLARE
--
-- Declaramos as variaveis
local playerSmokeFlares = {};

-- Inicia a horda, se specificPlayer for adicionado como parametro
-- a horda começara somente por ele
function StartHorde(specificPlayer)

    -- Adicionamos a tabela de spawn do jogador
    playerSmokeFlares[specificPlayer:getUsername()] = {};
    playerSmokeFlares[specificPlayer:getUsername()]["player"] = specificPlayer;
    playerSmokeFlares[specificPlayer:getUsername()]["airdropArea"] = {
        x = specificPlayer:getX(),
        y = specificPlayer:getY(),
        z = specificPlayer:getZ()
    };

    specificPlayer:playSound("SmokeFlareIgnition")
    Events.EveryTenMinutes.Add(AirdropSpawnDelay)
end

function AirdropSpawnDelay()
    local delay = 0
    -- Waiting 30 minutes before spawning an airdrop
    while delay < 3 do
        delay = delay + 1
    end
    Events.EveryTenMinutes.Remove(AirdropSpawnDelay)
    for playerUsername, playerSpawns in pairs(playerSmokeFlares) do
        local airdrop = SpawnSpecificAirdrop(playerSpawns.airdropArea);
        getSoundManager():PlayWorldSound("AirdropSoundPlane", airdrop:getSquare(), 0, 200, 5, true)
        getWorldSoundManager():addSound(airdrop,
                playerSpawns.airdropArea.x,
                playerSpawns.airdropArea.y,
                playerSpawns.airdropArea.z,
                200, 10);
    end
    playerSmokeFlares = {};
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