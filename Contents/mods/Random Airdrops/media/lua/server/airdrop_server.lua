---@diagnostic disable: undefined-global, deprecated
-- By bobodev o brabo tem nome 😊😊

-- Переменные производительности
-- ждём тик, чтобы проверить аирдроп на спавн/деспавн
local ticksPerCheck = 0;
local ticksPerCheckDespawn = 0;
local ticksMax = SandboxVars.AirdropMain.AirdropTickCheck;
local giveUpDespawn = 0;
local Recipe = Recipe;
-- Lua Utils

-- Клонирует всю таблицу
local function deepcopy(orig)
    local copy

    if type(orig) == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else
        copy = orig
    end

    return copy
end

-- Локально сохраняет все позиции, в которых могут появиться airdrop
local airdropPositionsDefault = {
    { x = 10023, y = 11007, z = 0, name = "March_Ridge" },
    { x = 11702, y = 9688, z = 0, name = "Muldraugh" },
    { x = 11580, y = 8824, z = 0, name = "Dixie" },
    { x = 6659, y = 10096, z = 0, name = "Doe_Valley" },
    { x = 10080, y = 12603, z = 0, name = "March_Ridge" },
    { x = 9194, y = 11812, z = 0, name = "Rosewood" },
    { x = 5615, y = 5933, z = 0, name = "Riverside" },
    { x = 11289, y = 7114, z = 0, name = "West_Point" },
    { x = 10150, y = 6859, z = 0, name = "Nearest_West_Point" },
    { x = 3785, y = 9166, z = 0, name = "Far_Away_from_Riverside" },
    { x = 5710, y = 11186, z = 0, name = "Far_Away_from_Rosewood" },
    { x = 14033, y = 5750, z = 0, name = "Valley_Station" },
    { x = 6598, y = 5193, z = 0, name = "Riverside" },
    { x = 7847, y = 11699, z = 0, name = "Nearest_Rosewood" },
    { x = 9790, y = 12356, z = 0, name = "Nearest_March_Ridge" },
    { x = 9363, y = 12546, z = 0, name = "Nearest_Rosewood" },
    { x = 10931, y = 8775, z = 0, name = "Nearest_Muldraugh" },
    { x = 12832, y = 4423, z = 0, name = "Louis_Ville" }
};
local airdropPositions = {};
local usingAirdropPositions = {};
-- Локально сохраняет все предметы для спавна в airdrop
local airdropLootTableDefault = {
    {
        type = "combo",
        chance = 100,
        child = {
            {
                type = "item",
                chance = 100,
                quantity = 6,
                child = "Base.CannedCornedBeef"
            },
            {
                type = "item",
                chance = 100,
                quantity = 5,
                child = "Base.WaterBottleFull"
            },
            {
                type = "item",
                chance = 100,
                quantity = 3,
                child = "Base.CannedFruitCocktail"
            },
            {
                type = "item",
                chance = 100,
                quantity = 1,
                child = "Base.Ghillie_Top"
            },
            {
                type = "item",
                chance = 100,
                quantity = 1,
                child = "Base.Ghillie_Trousers"
            },
            {
                type = "item",
                chance = 100,
                quantity = 1,
                child = "Base.Hat_Army"
            },
            {
                type = "item",
                chance = 100,
                quantity = 1,
                child = "Base.HolsterDouble"
            }
        }
    },
    {
        type = "combo",
        chance = 60,
        child = {
            {
                type = "item",
                chance = 100,
                quantity = 1,
                child = "Base.Pistol3"
            },
            {
                type = "item",
                chance = 100,
                quantity = 1,
                child = "Base.44Clip"
            },
            {
                type = "item",
                chance = 70,
                quantity = 5,
                child = "Base.Bullets44Box"
            }
        }
    },
    {
        type = "combo",
        chance = 60,
        child = {
            {
                type = "item",
                chance = 100,
                quantity = 1,
                child = "Base.Shotgun"
            },
            {
                type = "item",
                chance = 100,
                quantity = 1,
                child = "Base.AmmoStraps"
            },
            {
                type = "item",
                chance = 100,
                quantity = 1,
                child = "Base.Sling"
            },
            {
                type = "item",
                chance = 70,
                quantity = 6,
                child = "Base.ShotgunShellsBox"
            }
        }
    },
    {
        type = "combo",
        chance = 100,
        child = {
            {
                type = "item",
                chance = 70,
                quantity = 2,
                child = "Base.HandAxe"
            },
            {
                type = "item",
                chance = 70,
                quantity = 1,
                child = "Base.Crowbar"
            },
            {
                type = "item",
                chance = 70,
                quantity = 1,
                child = "Base.PetrolCan"
            }
        }
    }
};
local airdropLootTable = {};
local usingAirdropLootTable = {};
-- Сохраняйте глобально все уже заспавненные воздушные сбросы для последующего удаления
-- airdrop = BaseVehicle / Буквально airdrop / будет равен нулю, когда airdrop еще не был создан!!!
-- ticksToDespawn = int / когда эта переменная достигнет 0, airdrop будет удален в функции DespawnAirdrops
-- index = int / это индекс позиций airdrop, мы используем его для проверки, был ли уже спавн в той области / spawnIndex
SpawnedAirdrops = {};
-- Сохраняйте глобально airdrop, которые еще будут спавниться, но не были заспавнены, потому что никто не загрузил чанк
-- эта переменная используется всегда, когда она отлична от 0, чтобы проверить, загружает ли кто-то чанк
-- содержит только элемент индекса позиций воздушных сбросов / spawnIndex
AirdropsToSpawn = {};
-- Сохраняйте данные мода
-- OldAirdrops = List<spawnIndex> / старые воздушные сбросы - это все те воздушные сбросы, которые остались в мире после закрытия сервера
-- OldAirdropsData = List<SpawnedAirdrops/airdrop==boolean> / данные старых воздушных сбросов содержат данные только в случае DisableOldDespawn
-- RemovingOldAirdrops = List<spawnIndex> / все воздушные сбросы, которые удаляются при проверке, данные выделяются в начале сервера
-- SpecificAirdropsSpawned = List<spawnArea, ticksToDespawn> / все воздушные сбросы, заспавненные другими модами
AirdropsData = {};

--Читает позиции из файла конфигурации.
local function readAirdropsPositions()
    print("[Air Drop] Loading air drops positions...")
    local fileReader = getFileReader("AirdropPositions.ini", true)
    local lines = {}
    local line = fileReader:readLine()
    while line do
        table.insert(lines, line)
        line = fileReader:readLine()
    end
    fileReader:close()
    airdropPositions = loadstring(table.concat(lines, "\n"))() or {}
    print("[Air Drop] Positions loaded");
end

-- Читает предметы из файла конфигурации.
local function readAirdropsLootTable()
    print("[Air Drop] Loading air drops loot table...")
    local fileReader = getFileReader("AirdropLootTable.ini", true)
    local lines = {}
    local line = fileReader:readLine()
    while line do
        table.insert(lines, line)
        line = fileReader:readLine()
    end
    fileReader:close()
    airdropLootTable = loadstring(table.concat(lines, "\n"))() or {}
    print("[Air Drop] Loot table loaded");
end

-- Проверяет, есть ли игроки рядом с воздушным сбросом, полученным в качестве параметра.
local function checkPlayersAround(airdrop)
    -- Мы получаем координату airdrop
    local airdropX = airdrop:getX();
    local airdropY = airdrop:getY();
    local airdropZ = airdrop:getZ();

    -- Собирает сетку(grid)
    local square = getCell():getGridSquare(airdropX, airdropY, airdropZ);

    --Если сетка существует, значит, есть игрок, загружающий чанк.
    if square then
        print("[Air Drop] Cannot despawn airdrop, a player is rendering close");
        return true;
    else
        return false
    end
end

-- Принимает airdrop в качестве параметра и добавляет к нему предметы.
local function spawnAirdropItems(airdrop)
    -- Мы собираем контейнер airdrop
    local airdropContainer = airdrop:getPartById("TruckBed"):getItemContainer();

    -- Для атрибута id; id элементов, находящихся здесь, игнорируются.
    local idSpawneds = {};

    local alocatedSelectedType
    -- Проходит по списку и вызывает функции на основе их типа
    -- функции должны быть переданы как параметры
    -- функции ссылаются на listSpawn
    local function listSpawn(list, selectType)
        alocatedSelectedType = selectType;
        -- Мы проходим по всем элементам таблицы лута
        for i = 1, #list do
            selectType(list[i]);
        end
    end

    -- Type: item
    local function spawnItem(child)
        airdropContainer:AddItem(child);
    end

    -- Type: combo
    local function spawnCombo(child)
        -- Мы проходим по всем элементам таблицы лута.
        listSpawn(child, alocatedSelectedType);
    end

    -- Type: oneof
    local function spawnOneof(child)
        local selectedIndex = ZombRand(#child) + 1;
        -- Нам нужно создать шаблонную таблицу, потому что listSpawn принимает только список(list)
        -- и мы вставляем только элемент, поэтому у нас есть таблица с элементом внутри
        alocatedSelectedType(child[selectedIndex]);
    end

    local function selectType(element)
        local jump = false;
        -- Мы проверяем, существует ли переменная id.
        if element.id then
            -- Мы проверяем, был ли id уже добавлен.
            if idSpawneds[element.id] then jump = true end
        end
        -- Проверяет, является ли шанс нулевым.
        if not element.chance then element.chance = 100 end
        -- Мы проверяем, необходимо ли пропустить.
        if not jump then
            -- Проверка типа
            if element.type == "combo" then
                -- Проверяет, есть ли у элемента id
                if element.id then
                    -- Если есть, добавьте таблицу id спавна
                    idSpawneds[element.id] = true;
                end
                -- Мы проверяем, чтобы убедиться, что количество не является нулевым.
                if element.quantity then
                    -- Мы добавляем в соответствии с количеством.
                    for _ = 1, element.quantity do
                        -- Мы проверяем шанс спавна для дочернего элемента.
                        if ZombRand(100) + 1 <= element.chance then
                            -- добавляем предмет
                            spawnCombo(element.child);
                        end
                    end
                else
                    -- Мы проверяем шанс спавна для дочернего элемента.
                    if ZombRand(100) + 1 <= element.chance then
                        -- добавляем предмет
                        spawnCombo(element.child);
                    end
                end
            elseif element.type == "item" then
                -- Проверяет, есть ли у элемента идентификатор.
                if element.id then
                    -- Если есть, добавьте таблицу id спавна
                    idSpawneds[element.id] = true;
                end
                -- Мы проверяем, чтобы убедиться, что количество не является нулевым.
                if element.quantity then
                    -- Мы добавляем в соответствии с количеством.
                    for _ = 1, element.quantity do
                        -- Мы проверяем шанс спавна для дочернего элемента.
                        if ZombRand(100) + 1 <= element.chance then
                            -- добавляем предмет
                            spawnItem(element.child);
                        end
                    end
                else
                    -- Мы проверяем шанс спавна для дочернего элемента.
                    if ZombRand(100) + 1 <= element.chance then
                        -- добавляем предмет
                        spawnItem(element.child);
                    end
                end
            elseif element.type == "oneof" then
                -- Проверяет, есть ли у элемента идентификатор.
                if element.id then
                    -- Если есть, добавьте таблицу id спавна
                    idSpawneds[element.id] = true;
                end
                -- Мы проверяем, чтобы убедиться, что количество не является нулевым.
                if element.quantity then
                    -- Мы добавляем в соответствии с количеством.
                    for _ = 1, element.quantity do
                        -- Мы проверяем шанс спавна для дочернего элемента.
                        if ZombRand(100) + 1 <= element.chance then
                            -- добавляем предмет
                            spawnOneof(element.child);
                        end
                    end
                else
                    -- Мы проверяем шанс спавна для дочернего элемента.
                    if ZombRand(100) + 1 <= element.chance then
                        -- добавляем предмет
                        spawnOneof(element.child);
                    end
                end
            end
        end
    end

    -- Мы начинаем спавн лута
    listSpawn(usingAirdropLootTable, selectType);
end

-- Удаляет элемент из переменной AirdropsToSpawn по spawnIndex
local function removeElementFromAirdropsToSpawnBySpawnIndex(spawnIndex)
    -- Сканирование в AirdropsToSpawn
    for i = 1, #AirdropsToSpawn do
        -- Проверяет, является ли spawnIndex таким же, как у AirdropsToSpawn
        if spawnIndex == AirdropsToSpawn[i] then
            -- Удаляет из таблицы
            table.remove(AirdropsToSpawn, i);
            break;
        end
    end
end

-- Удаляет элемент из переменной SpawnedAirdrops по spawnIndex
local function removeElementFromSpawnedAirdropsBySpawnIndex(spawnIndex)
    -- Сканирование в AirdropsToSpawn.
    for i = 1, #SpawnedAirdrops do
        -- Проверяет, является ли spawnIndex таким же, как у SpawnedAirdrops
        if spawnIndex == SpawnedAirdrops[i].index then
            -- Удаляет из таблицы.
            table.remove(SpawnedAirdrops, i);
            break;
        end
    end
end

-- Удаляет элемент из переменной SpawnedAirdrops по spawnIndex
local function removeElementFromOldAirdropsDataBySpawnIndex(spawnIndex)
    -- Сканирование в AirdropsToSpawn
    for i = 1, #AirdropsData.OldAirdropsData do
        -- Проверяет, является ли spawnIndex таким же, как у AirdropsToSpawn
        if spawnIndex == AirdropsData.OldAirdropsData[i].index then
            -- Удаляет из таблицы
            table.remove(AirdropsData.OldAirdropsData, i);
            break;
        end
    end
end

-- Уменьшает ticksToDespawn на основе spawnIndex
local function reduceTicksToDespawnFromSpawnedAirdropsBySpawnIndex(spawnIndex)
    -- Сканирование в AirdropsToSpawn
    for i = 1, #SpawnedAirdrops do
        -- Проверяет, является ли spawnIndex таким же, как у SpawnedAirdrops
        if spawnIndex == SpawnedAirdrops[i].index then
            -- Уменьшаем таблицу
            SpawnedAirdrops[i].ticksToDespawn = SpawnedAirdrops[i].ticksToDespawn - 1;
            break;
        end
    end
end

-- Уменьшает ticksToDespawn на основе spawnIndex
local function reduceTicksToDespawnFromOldAirdropsDataBySpawnIndex(spawnIndex)
    -- Сканирование в AirdropsToSpawn
    for i = 1, #AirdropsData.OldAirdropsData do
        -- Проверяет, является ли spawnIndex таким же, как у SpawnedAirdrops
        if spawnIndex == AirdropsData.OldAirdropsData[i].index then
            -- Уменьшаем таблицу
            AirdropsData.OldAirdropsData[i].ticksToDespawn = AirdropsData.OldAirdropsData[i].ticksToDespawn - 1;
            break;
        end
    end
end

-- Adiciona o aidrop no SpawnedAirdrops baseado no spawnIndex
local function addAirdropToSpawnedAirdropsBySpawnIndex(spawnIndex, airdrop)
    -- Varredura nos SpawnedAirdrops
    for i = 1, #SpawnedAirdrops do
        -- Verifica se o spawnIndex é o mesmo do SpawnedAirdrops
        if spawnIndex == SpawnedAirdrops[i].index then
            -- Adicionamos o airdrop a lista de SpawnedAirdrops
            SpawnedAirdrops[i].airdrop = airdrop;
            -- Adicionamos o id do airdrop a lista de OldAirdrops
            table.insert(AirdropsData.OldAirdrops, spawnIndex);
            break;
        end
    end
end

-- Adiciona o aidrop no SpawnedAirdrops baseado no spawnIndex
local function addTrueToOldAirdropsDataBySpawnIndex(spawnIndex)
    -- Varredura nos SpawnedAirdrops
    for i = 1, #AirdropsData.OldAirdropsData do
        -- Verifica se o spawnIndex é o mesmo do OldAirdropsData
        if spawnIndex == AirdropsData.OldAirdropsData[i].index then
            -- Colocamos para true
            AirdropsData.OldAirdropsData[i].airdrop = true;
            break;
        end
    end
end

-- Remove o da lista de OldAirdrops pelo Id do airdrop
local function removeAirdropFromOldAirdropsBySpawnIndex(spawnIndex)
    -- Varredura nos OldAirdrops
    for i = 1, #AirdropsData.OldAirdrops do
        -- Verifica se o id é o mesmo do OldAirdrops
        if spawnIndex == AirdropsData.OldAirdrops[i] then
            table.remove(AirdropsData.OldAirdrops, i)
            break;
        end
    end
end

-- Remove o da lista de RemovingOldAirdrop pelo Id do airdrop
local function removeAirdropFromRemovingAirdropsBySpawnIndex(spawnIndex)
    -- Varredura nos OldAirdrops
    for i = 1, #AirdropsData.RemovingOldAirdrops do
        -- Verifica se o id é o mesmo do OldAirdrops
        if spawnIndex == AirdropsData.RemovingOldAirdrops[i] then
            table.remove(AirdropsData.RemovingOldAirdrops, i)
            break;
        end
    end
end

-- Verifica atraves do spawnIndex se existe um OldAirdrops naquela posição
local function checkOldAirdropsExistenceBySpawnIndex(spawnIndex)
    -- Varredura nos OldAirdrops
    for i = 1, #AirdropsData.OldAirdrops do
        -- Verifica se o id é o mesmo do OldAirdrops
        if spawnIndex == AirdropsData.OldAirdrops[i] then
            -- Então existe sim um OldAirdrops
            return true;
        end
    end
    -- Não existe nenhum OldAirdrops
    return false;
end

-- Verifica a existencia do index em SpawnedAirdrops
local function checkSpawnAirdropsExistenceBySpawnIndex(spawnIndex)
    -- Varredura SpawnedAirdrops
    for i = 1, #SpawnedAirdrops do
        -- Verifica se o id é o mesmo do SpawnedAirdrops
        if spawnIndex == SpawnedAirdrops[i].index then
            -- Então existe sim o Index
            return true;
        end
    end
    -- Não existe nenhum Index
    return false;
end

-- Checa se é vai spawnar um airdrop
function CheckAirdrop()
    -- Fazemos um check para despawnar os Airdrops Anteriores
    if not SandboxVars.AirdropMain.AirdropDisableDespawn then
        DespawnAirdrops();
    end
    -- Checa se vai ter um airdrop nesta chamada 5% de chance
    if ZombRand(100) + 1 <= SandboxVars.AirdropMain.AirdropFrequency then
        -- Spawna uma unidade de airdrop
        local airdropLocationName = SpawnAirdrop();
        -- Verificamos se ele de fato spawnou um airdrop
        -- afinal em casos de erros ele não ira spawnar
        if not airdropLocationName then return end;
        -- Obtém a lista de jogadores online
        local players = getOnlinePlayers();
        -- Compatibilidade com singleplayer
        if not players then
            -- Texto do Som para emitir ao jogador
            local alarmSound = "airdrop" .. tostring(ZombRand(1));
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
                sendServerCommand(player, "ServerAirdrop", "alert", { name = airdropLocationName });
            end
        end
    else
        print("[Air Drop] Global airdrop spawn check: no");
    end
end

-- Spawna um airdrop ao mundo aleatoriamente
function SpawnAirdrop()
    local spawnIndex = 0;

    -- Seleciona aleatoriamente uma area de spawn que não foi spawnada ainda
    local tries = 20;
    while tries > 0 do
        -- Checa se airdropPositions é vazio
        if #usingAirdropPositions == 0 then
            tries = 0; break;
        end
        spawnIndex = ZombRand(#usingAirdropPositions) + 1
        local alreadySpawned = false;
        -- Varre todos os airdrops spawnados para ver se o index é diferente
        for i = 1, #SpawnedAirdrops do
            -- Verificamos se o index já foi usado
            if SpawnedAirdrops[i].index == spawnIndex then
                -- Refaça
                alreadySpawned = true;
                break;
            end
        end
        -- Se a variavel disable old despawn estiver ativa então
        -- precisamos verificar também se não existe spawnado já no OldAirdrops
        if SandboxVars.AirdropMain.AirdropDisableOldDespawn then
            -- Varre todos os airdrops spawnados para ver se o index é diferente
            for i = 1, #AirdropsData.OldAirdrops do
                -- Verificamos se o index já foi usado
                if AirdropsData.OldAirdrops[i] == spawnIndex then
                    -- Refaça
                    alreadySpawned = true;
                    break;
                end
            end
        end
        -- Se ja spawno então
        if alreadySpawned then
            -- Reduzimos a menos 1 as tentativas
            tries = tries - 1;
        end
        -- Verifica se não foi spawnado ainda
        if not alreadySpawned then break end
        print("[Air Drop] Cannot spawn airdrop, the index " .. spawnIndex .. " has already in use");
    end

    -- Caso não encontre um index que não foi spawnado
    if tries <= 0 then
        print("[Air Drop] Warning cannot find a spawn area that has not been spawned, air drop not spawned");
        return nil;
    end

    -- Recebemos a area de spawn
    local spawnArea = usingAirdropPositions[spawnIndex];

    -- Adicionamos a lista de airdrops spawnados
    table.insert(SpawnedAirdrops,
        { airdrop = nil, ticksToDespawn = SandboxVars.AirdropMain.AirdropRemovalTimer, index = spawnIndex });
    -- Adicionamos na lista de airdrops ainda para spawnar
    table.insert(AirdropsToSpawn, spawnIndex);

    -- Precisamos verificar se DisableOldDespawn esta ativo
    -- para podermos adicionar os dados a OldAirdropsData
    if SandboxVars.AirdropMain.AirdropDisableOldDespawn then
        -- Adicionamos a lista de OldAirdropsData
        table.insert(AirdropsData.OldAirdropsData,
            { airdrop = false, ticksToDespawn = SandboxVars.AirdropMain.AirdropRemovalTimer, index = spawnIndex });
    end

    -- Precisamos fazer isso pois pode ser que tenha mais de um airdrop por dia
    -- e também não queremos que o evento seja seja duplicado
    -- Removemos ticks anteriores
    Events.OnTick.Remove(CheckForCreateAirdrop);
    -- Readicionamos
    Events.OnTick.Add(CheckForCreateAirdrop);

    if SandboxVars.AirdropMain.AirdropConsoleDebugCoordinates then
        print("[Air Drop] Spawned in X:" ..
            spawnArea.x .. " Y: " .. spawnArea.y);
    end

    -- Retornamos o nome da area de spawn
    return spawnArea.name;
end

-- Reduz a setença para despawnar, chamado a cada hora ingame
-- se existir setenças Despawna os airdrops, caso for um Especial inicia
-- o evento OnTick para ForceDespawnAirdrops
function DespawnAirdrops()
    -- Precisamos salvar localmente a variavel para não ter atualizações indevidas
    -- durante o check, já que a atualização é feita durane o for
    local localSpawnedAirdrops = deepcopy(SpawnedAirdrops);
    -- Varremos todos os airdrops spawnados
    for i = 1, #localSpawnedAirdrops do
        -- Caso o airdrop não esteja setenciado apenas prossiga para o proximo
        if localSpawnedAirdrops[i].ticksToDespawn <= 0 then
            -- Recebemos o airdrop pelo indice
            local airdrop = localSpawnedAirdrops[i].airdrop;

            -- Checamos se airdrop é nulo e se esta setenciado
            -- Se estiver nulo significa que ele ainda não foi spawnado oficialmente
            if not airdrop then
                -- Agora precisamos das tabelas
                local spawnIndex = localSpawnedAirdrops[i].index;
                -- Pegamos as posições diretamente do airdropPositions
                -- porque o aidrop não foi spawnado ainda
                print("[Air Drop] Uncreated Air drop has been removed in X:" ..
                    usingAirdropPositions[spawnIndex].x .. " Y:" .. usingAirdropPositions[spawnIndex].y);
                -- Removemos da nossa lista de AirdropsToSpawn
                removeElementFromAirdropsToSpawnBySpawnIndex(spawnIndex);
                -- Removemos da nossa lista de SpawnedAirdrops
                removeElementFromSpawnedAirdropsBySpawnIndex(spawnIndex);
                -- Verificamos se DisableOldDespawne esta ativo
                if SandboxVars.AirdropMain.AirdropDisableOldDespawn then
                    -- Removemos da tabela de OldAirdropsData
                    removeElementFromOldAirdropsDataBySpawnIndex(spawnIndex)
                end
                -- Prosseguimos para o proximo indice
            else -- Caso o airdrop foi criado então temos alguma validações
                -- Checamos se existe algum jogador por perto
                local havePlayerAround = checkPlayersAround(airdrop);

                local spawnIndex = localSpawnedAirdrops[i].index;

                -- Se não há jogadores por perto
                if not havePlayerAround then
                    -- Removemos permanentemente do mundo
                    airdrop:permanentlyRemove();
                    print("[Air Drop] Air drop has been removed in X:" .. airdrop:getX() .. " Y:" .. airdrop:getY());
                    -- Removemos da nossa lista de SpawnedAirdrops
                    removeElementFromSpawnedAirdropsBySpawnIndex(spawnIndex);
                    -- Removemos da nossa lista de OldAirdrops
                    removeAirdropFromOldAirdropsBySpawnIndex(spawnIndex);
                    -- Verificamos se DisableOldDespawne esta ativo
                    if SandboxVars.AirdropMain.AirdropDisableOldDespawn then
                        -- Removemos da tabela de OldAirdropsData
                        removeElementFromOldAirdropsDataBySpawnIndex(spawnIndex)
                    end
                end
            end
        else
            -- Reduzimos em 1 o tick para despawnar do airdrop
            reduceTicksToDespawnFromSpawnedAirdropsBySpawnIndex(localSpawnedAirdrops[i].index);
        end
    end

    -- Varremos todos os airdrops especiais
    for i = 1, #AirdropsData.SpecificAirdropsSpawned do
        -- Verificamos a setença
        if AirdropsData.SpecificAirdropsSpawned[i].ticksToDespawn <= 0 then
            -- Removemos e adicionamos para não ter problemas de memoria e performance
            Events.OnTick.Remove(ForceDespawnAirdrops);
            Events.OnTick.Add(ForceDespawnAirdrops);
        else
            -- Reduzimos a setença
            AirdropsData.SpecificAirdropsSpawned[i].ticksToDespawn = AirdropsData.SpecificAirdropsSpawned[i]
                .ticksToDespawn - 1;
        end
    end

    -- Se o DisableOldDespawn estiver ativo, precisamos verificar o OldAirdropsData
    if SandboxVars.AirdropMain.AirdropDisableOldDespawn then
        -- Varremos todos os dados
        for i = 1, #AirdropsData.OldAirdropsData do
            local data = AirdropsData.OldAirdropsData[i];
            -- Verificamos se esta setenciado
            if data.ticksToDespawn <= 0 then
                -- Se a existencia de OldAirdrops não existe em SpawnedAirdrops
                if not checkSpawnAirdropsExistenceBySpawnIndex(data.index) then
                    -- Adicionamos ele ao RemovingOldAirdrops para ForceDespawnAirdrops
                    table.insert(AirdropsData.RemovingOldAirdrops, data.index);
                    -- Removemos e adicionamos para não ter problemas de memoria e performance
                    Events.OnTick.Remove(ForceDespawnAirdrops);
                    Events.OnTick.Add(ForceDespawnAirdrops);
                end
            else
                reduceTicksToDespawnFromOldAirdropsDataBySpawnIndex(data.index);
            end
        end
    end
end

-- Força e remove todos os airdrops na lista de RemovingOldAirdrops
-- Essa função é pesada pois faz uma varredura legal no mapa, não use com frequencia!
function ForceDespawnAirdrops()
    -- Checa a espera de ticks
    if ticksPerCheckDespawn < ticksMax then
        ticksPerCheckDespawn = ticksPerCheckDespawn + 1;
        return
    end
    ticksPerCheckDespawn = 0;
    -- Verificamos se RemovingOldAirdrops esta vazio e SpecificAirdropsSpawned esta vazio
    if #AirdropsData.RemovingOldAirdrops == 0 and #AirdropsData.SpecificAirdropsSpawned == 0 then
        --Remove o evento
        Events.OnTick.Remove(ForceDespawnAirdrops);
        print("[Air Drop] Finished cleaning the old air drops")
    end

    -- Varredura nos airdrops e despawnamos
    local localOldAirdrops = deepcopy(AirdropsData.RemovingOldAirdrops)
    for i = 1, #localOldAirdrops do
        -- Coletamos o spawn index
        local spawnIndex = localOldAirdrops[i];
        -- Recebemos a area de spawn
        local spawnArea = usingAirdropPositions[spawnIndex];
        -- Coletamos o square
        local square = getCell():getGridSquare(spawnArea.x, spawnArea.y, spawnArea.z);
        -- Verificamos se o chunk esta sendo carregado
        if square then
            -- Coletamos o airdrop
            local airdrop = square:getVehicleContainer();
            -- Verificamos se veiculo não está nulo
            if airdrop then
                -- Verificamos se o veiculo é o airdrop
                if airdrop:getScriptName() == "Base.airdrop" then
                    -- Removemos definitivamente
                    airdrop:permanentlyRemove();
                    removeAirdropFromRemovingAirdropsBySpawnIndex(spawnIndex)
                    removeAirdropFromOldAirdropsBySpawnIndex(spawnIndex);
                    if SandboxVars.AirdropMain.AirdropConsoleDebugCoordinates then
                        print("[Air Drop] Force Despawn air drop has been removed in X:" ..
                            airdrop:getX() .. " Y:" .. airdrop:getY());
                    end
                else
                    print("[Air Drop] WARNING exist a vehicle in airdrop spawn coordinate giving up...")
                    removeAirdropFromRemovingAirdropsBySpawnIndex(spawnIndex)
                    removeAirdropFromOldAirdropsBySpawnIndex(spawnIndex);
                end
            else
                -- Tentamos despawnar ate 6 vezes
                giveUpDespawn = giveUpDespawn + 1
                if giveUpDespawn >= 5 then
                    removeAirdropFromRemovingAirdropsBySpawnIndex(spawnIndex)
                    removeAirdropFromOldAirdropsBySpawnIndex(spawnIndex);
                    giveUpDespawn = 0;
                    print("[Air Drop] WARNING give up despawning the airdrop...")
                else
                    print("[Air Drop] WARNING chunk loaded but airdrop not found")
                end
            end
        else
            -- Debug
            if SandboxVars.AirdropMain.AirdropConsoleDebug then
                print("[Air Drop] Force despawn: chunk not loaded in index: " .. spawnIndex);
            end;
        end
    end

    -- Verificamos se esta ativo a configuracao DisaleOldSpawn
    if SandboxVars.AirdropMain.AirdropDisableOldDespawn then
        local empty = true;
        local localSpecificAirdropsSpawned = deepcopy(AirdropsData.SpecificAirdropsSpawned)
        for i = 1, #localSpecificAirdropsSpawned do
            -- Precisamos checar se ticksToDespawn é menor ou igual a 0
            -- ate pq ele nao pode despawnar se o ticks ainda não é 0
            if localSpecificAirdropsSpawned[i].ticksToDespawn <= 0 then
                empty = false;
                -- Recebemos a spawn area
                local spawnArea = localSpecificAirdropsSpawned[i].spawnArea
                -- Coletamos o square
                local square = getCell():getGridSquare(spawnArea.x, spawnArea.y, spawnArea.z);
                if square then
                    -- Coletamos o airdrop
                    local airdrop = square:getVehicleContainer();
                    -- Verificamos se veiculo não está nulo
                    if airdrop then
                        -- Verificamos se o veiculo é o airdrop
                        if airdrop:getScriptName() == "Base.airdrop" then
                            -- Removemos definitivamente
                            airdrop:permanentlyRemove();
                            -- Removemos do indice
                            table.remove(AirdropsData.SpecificAirdropsSpawned, i);
                            if SandboxVars.AirdropMain.AirdropConsoleDebugCoordinates then
                                print("[Air Drop] SPECIFIC Despawn air drop has been removed in X:" ..
                                    airdrop:getX() .. " Y:" .. airdrop:getY());
                            end
                        else
                            print("[Air Drop] WARNING exist a vehicle in SPECIFIC airdrop spawn coordinate giving up...")
                            -- Removemos do indice
                            table.remove(AirdropsData.SpecificAirdropsSpawned, i);
                        end
                    else
                        print("[Air Drop] WARNING chunk loaded but SPECIFIC airdrop not found, giving up")
                        -- Removemos do indice
                        table.remove(AirdropsData.SpecificAirdropsSpawned, i);
                    end
                end
            end
        end
        -- Se SpecificAirdropsSpawned estiver vazio e RemovingOldAirdrops também então vamos cancelar isso
        if empty and #AirdropsData.RemovingOldAirdrops == 0 then
            --Remove o evento
            Events.OnTick.Remove(ForceDespawnAirdrops);
            print("[Air Drop] Finished cleaning the old air drops")
        end
    else
        -- Airdrops spawnados pela função SpawnSpecificAirdrop, são diferentes
        -- dos airdrops convensionais pois eles spawnam em locais diferentes dos indexs
        local localSpecificAirdropsSpawned = deepcopy(AirdropsData.SpecificAirdropsSpawned)
        for i = 1, #localSpecificAirdropsSpawned do
            -- Recebemos a spawn area
            local spawnArea = localSpecificAirdropsSpawned[i].spawnArea
            -- Coletamos o square
            local square = getCell():getGridSquare(spawnArea.x, spawnArea.y, spawnArea.z);
            if square then
                -- Coletamos o airdrop
                local airdrop = square:getVehicleContainer();
                -- Verificamos se veiculo não está nulo
                if airdrop then
                    -- Verificamos se o veiculo é o airdrop
                    if airdrop:getScriptName() == "Base.airdrop" then
                        -- Removemos definitivamente
                        airdrop:permanentlyRemove();
                        -- Removemos do indice
                        table.remove(AirdropsData.SpecificAirdropsSpawned, i);
                        if SandboxVars.AirdropMain.AirdropConsoleDebugCoordinates then
                            print("[Air Drop] SPECIFIC Despawn air drop has been removed in X:" ..
                                airdrop:getX() .. " Y:" .. airdrop:getY());
                        end
                    else
                        print("[Air Drop] WARNING exist a vehicle in SPECIFIC airdrop spawn coordinate giving up...")
                        -- Removemos do indice
                        table.remove(AirdropsData.SpecificAirdropsSpawned, i);
                    end
                else
                    print("[Air Drop] WARNING chunk loaded but SPECIFIC airdrop not found, giving up")
                    -- Removemos do indice
                    table.remove(AirdropsData.SpecificAirdropsSpawned, i);
                end
            end
        end
    end
end

-- Essa função checa se o chunk do airdrop esta sendo carrepado
-- para poder criar o airdrop
function CheckForCreateAirdrop()
    -- Checa a espera de ticks
    if ticksPerCheck < ticksMax then
        ticksPerCheck = ticksPerCheck + 1;
        return
    end
    ticksPerCheck = 0;
    -- Verificamos se todos os airdrops já foram spawnados
    if #AirdropsToSpawn == 0 then
        Events.OnTick.Remove(CheckForCreateAirdrop);
        print("[Air Drop] All pending airdrops have been created or removed");
        return;
    end
    -- Precisamos salvar localmente a variavel para não ter atualizações indevidas
    -- durante o check, já que a atualização é feita durane o for
    local localAirdropsToSpawn = deepcopy(AirdropsToSpawn);
    for i = 1, #localAirdropsToSpawn do
        -- Recebemos a posicao de spawn
        local spawnIndex = localAirdropsToSpawn[i];
        -- Se não existe um OldAirdrops para excluir então continue
        if not checkOldAirdropsExistenceBySpawnIndex(spawnIndex) then
            local spawnArea = usingAirdropPositions[spawnIndex];
            -- Recebemos o square
            local square = getCell():getGridSquare(spawnArea.x, spawnArea.y, spawnArea.z)
            -- Verificamos se o square esta sendo carregado
            if square then
                -- Adicionamos o airdrop no mundo
                -- Notas importantes: addVehicleDebug necessita obrigatoriamente que square tenha
                -- o elemento chunk, não se engane chunk é na verdade o campo de visão do jogador,
                -- ou seja você só pode spawnar um veiculo se o player esta carregando o chunk por perto
                local airdrop = addVehicleDebug("Base.airdrop", IsoDirections.N, nil, square);
                -- Consertamos caso esteja quebrado
                airdrop:repair();
                -- Adicionamos os loots
                spawnAirdropItems(airdrop);

                -- Removemos da nossa lista de AirdropsToSpawn
                removeElementFromAirdropsToSpawnBySpawnIndex(spawnIndex);

                -- Adicionamos o aidrop para lista de SpawnedAirdrops
                addAirdropToSpawnedAirdropsBySpawnIndex(spawnIndex, airdrop);

                -- Precisamos verificar se DisableOldDespawn esta ativo
                -- para podermos adicionar dizer que airdrop é true na lista de OldAirdropsData
                if SandboxVars.AirdropMain.AirdropDisableOldDespawn then
                    -- Colocamos para true
                    addTrueToOldAirdropsDataBySpawnIndex(spawnIndex);
                end

                if SandboxVars.AirdropMain.AirdropConsoleDebugCoordinates then
                    print(
                        "[Air Drop] Chunk loaded, created new airdrop in X:" .. spawnArea.x .. " Y:" .. spawnArea.y);
                end
            else
                -- Debug
                if SandboxVars.AirdropMain.AirdropConsoleDebug then
                    print("[Air Drop] Create airdrop: chunk not loaded in index: " .. spawnIndex);
                end
            end
        else
            print("[Air drop] Cannot create the airdrop old airdrop still spawned in: " .. spawnIndex)
        end
    end
end

-- Função para adicionar um airdrop especifico em uma posição especifica, não usada durante
-- o mod, usado apenas em outros mods que necessitam spawnar um airdrop
-- spawnArea recebe como parametro x = int, y = int, z = int, despawnam de acordo com a configuração atual
function SpawnSpecificAirdrop(spawnArea)
    local square = getCell():getGridSquare(spawnArea.x, spawnArea.y, spawnArea.z);

    -- Verificamos se o square é valido
    if square then
        -- Criamos o veiculo no mundo, mais info olhe CheckForCreateAirdrop
        local airdrop = addVehicleDebug("Base.airdrop", IsoDirections.N, nil, square);
        -- Consertamos caso esteja quebrado
        airdrop:repair();
        -- Adicionamos os loots
        spawnAirdropItems(airdrop);
        table.insert(AirdropsData.SpecificAirdropsSpawned,
            { spawnArea = spawnArea, ticksToDespawn = SandboxVars.AirdropMain.AirdropRemovalTimer });
        -- Printa no console
        if SandboxVars.AirdropMain.AirdropConsoleDebugCoordinates then
            print("[Air Drop] Specific Airdrop Spawned in X:" ..
                spawnArea.x .. " Y: " .. spawnArea.y);
        end
    else
        print("[Air Drop] Specific Airdrop: Cannot spawn the square is invalid in X: " ..
            spawnArea.x .. " Y: " .. spawnArea.y);
    end
end

-- A cada hora dentro do jogo verifica se vai ter air drop
Events.EveryHours.Add(CheckAirdrop);

-- Carregamos os dados
Events.OnInitGlobalModData.Add(function(isNewGame)
    AirdropsData = ModData.getOrCreate("serverAirdropsData");
    -- Null Check
    if not AirdropsData.OldAirdrops then AirdropsData.OldAirdrops = {} end
    if not AirdropsData.SpecificAirdropsSpawned then AirdropsData.SpecificAirdropsSpawned = {} end
    -- Carrega todas as configurações
    readAirdropsPositions();
    readAirdropsLootTable();

    if SandboxVars.AirdropMain.DefaultAirdropPositions then
        usingAirdropPositions = deepcopy(airdropPositionsDefault);
    else
        usingAirdropPositions = deepcopy(airdropPositions);
    end

    if SandboxVars.AirdropMain.DefaultAirdropLootTable then
        usingAirdropLootTable = deepcopy(airdropLootTableDefault);
    else
        usingAirdropLootTable = deepcopy(airdropLootTable);
    end

    -- Limpador de airdrop antigo
    if not SandboxVars.AirdropMain.AirdropDisableOldDespawn then
        print("[Air Drop] Waiting for the first player connect to start removing old air drops")
        AirdropsData.RemovingOldAirdrops = deepcopy(AirdropsData.OldAirdrops);
        Events.OnTick.Add(ForceDespawnAirdrops);
    end
end)


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