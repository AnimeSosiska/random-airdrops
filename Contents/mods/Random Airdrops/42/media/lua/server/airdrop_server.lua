---@diagnostic disable: undefined-global, deprecated

RandomAirdrops = RandomAirdrops or {};

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
    { x = 10592, y = 9737, z = 0, name = "Muldraugh" },
    { x = 11580, y = 8824, z = 0, name = "Dixie" },
    { x = 7277, y = 8354, z = 0, name = "Fallas_Lake" },
    { x = 10088, y = 12697, z = 0, name = "March_Ridge" },
    { x = 8106, y = 11577, z = 0, name = "Rosewood" },
    { x = 6381, y = 5282, z = 0, name = "Riverside" },
    { x = 11921, y = 6899, z = 0, name = "West_Point" },
    { x = 15185, y = 2758, z = 0, name = "Louis_Ville_Airport" },
    { x = 12936, y = 2999, z = 0, name = "Louis_Ville" },
    { x = 8041, y = 15285, z = 0, name = "Water_Treatment_Plant" },
    { x = 2501, y = 14099, z = 0, name = "Irvington" },
    { x = 13522, y = 4899, z = 0, name = "Valley_Station" },
    { x = 3520, y = 10924, z = 0, name = "Echo_Creek" },
    { x = 600, y = 9809, z = 0, name = "Ekron" },
    { x = 2100, y = 6284, z = 0, name = "Brandenburg" }
};
local airdropPositions = {};
local usingAirdropPositions = {};
-- Локально сохраняет все предметы для спавна в airdrop
local airdropLootTableDefault = {
    {
        -- Комбо одежды
        type = "combo",
        chance = 100,
        child = {
            {
                -- Дождевики
                type = "oneof",
                chance = 80,
                quantity = 2,
                child = {
                    {
                        type = "item",
                        chance = 100,
                        quantity = 1,
                        child = "Base.PonchoGreen"
                    },
                    {
                        type = "item",
                        chance = 100,
                        quantity = 1,
                        child = "Base.PonchoYellow"
                    }
                },
                -- Штаны
                type = "oneof",
                chance = 70,
                quantity = 2,
                child = {
                    {
                        type = "item",
                        chance = 100,
                        quantity = 1,
                        child = "Base.Trousers_HuntingCamo"
                    },
                    {
                        type = "item",
                        chance = 100,
                        quantity = 1,
                        child = "Base.Dungarees_HuntingCamo"
                    }
                }
            }
        }
    },
    {
        -- Комбо провианта
        type = "combo",
        chance = 90,
        child = {
            {
                -- "Один из" еды; одинаковое id чтобы был только один тип
                type = "oneof",
                chance = 60,
                id = 1,
                child = {
                    {
                        type = "item",
                        chance = 100,
                        quantity = 1,
                        child = "Base.CannedMushroomSoup_Box"
                    },
                    {
                        type = "item",
                        chance = 100,
                        quantity = 3,
                        child = "Base.CannedMushroomSoup"
                    }
                },
                {
                    type = "oneof",
                    chance = 60,
                    id = 1,
                    child = {
                        {
                            type = "item",
                            chance = 100,
                            quantity = 1,
                            child = "Base.TinnedSoup_Box"
                        },
                        {
                            type = "item",
                            chance = 100,
                            quantity = 3,
                            child = "Base.TinnedSoup"
                        }
                    }
                },
                {
                    type = "oneof",
                    chance = 60,
                    id = 1,
                    child = {
                        {
                            type = "item",
                            chance = 100,
                            quantity = 1,
                            child = "Base.MysteryCan_Box"
                        },
                        {
                            type = "item",
                            chance = 100,
                            quantity = 3,
                            child = "Base.MysteryCan"
                        }
                    }
                }
            },
            -- Выборка консервированной воды
            {
                type = "oneof",
                chance = 100,
                child = {
                    {
                        type = "item",
                        chance = 100,
                        quantity = 1,
                        child = "Base.WaterRationCan_Box"
                    },
                    {
                        type = "item",
                        chance = 100,
                        quantity = 4,
                        child = "Base.WaterRationCan"
                    }
                }
            },
            -- Таблеточки
            {
                type = "item",
                chance = 100,
                quantity = 3,
                child = "Base.WaterPurificationTablets"
            }
        }
    },
    {
        -- Комбо медицины
        type = "combo",
        chance = 70,
        child = {
            {
                type = "item",
                chance = 100,
                quantity = 1,
                child = "Base.AntibioticsBox"
            },
            {
                type = "oneof",
                chance = 100,
                child = {
                    {
                        type = "item",
                        chance = 100,
                        quantity = 1,
                        child = "Base.BandageBox"
                    },
                    {
                        type = "item",
                        chance = 100,
                        quantity = 4,
                        child = "Base.Bandage"
                    }
                }
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
SpawnedAirdrops = SpawnedAirdrop or {};
-- Сохраняйте глобально airdrop, которые еще будут спавниться, но не были заспавнены, потому что никто не загрузил чанк
-- эта переменная используется всегда, когда она отлична от 0, чтобы проверить, загружает ли кто-то чанк
-- содержит только элемент индекса позиций воздушных сбросов / spawnIndex
AirdropsToSpawn = AirdropsToSpawn or {};
-- Сохраняйте данные мода
-- OldAirdrops = List<spawnIndex> / старые воздушные сбросы - это все те воздушные сбросы, которые остались в мире после закрытия сервера
-- OldAirdropsData = List<SpawnedAirdrops/airdrop==boolean> / данные старых воздушных сбросов содержат данные только в случае DisableOldDespawn
-- RemovingOldAirdrops = List<spawnIndex> / все воздушные сбросы, которые удаляются при проверке, данные выделяются в начале сервера
-- SpecificAirdropsSpawned = List<spawnArea, ticksToDespawn> / все воздушные сбросы, заспавненные другими модами
AirdropsData = AirdropsData or {};

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

-- Проверка спавна аирдропа
function RandomAirdrops.CheckAirdrop()
    -- Та самая проверка на спавн аирдропа
    if ZombRand(100) + 1 <= SandboxVars.AirdropMain.AirdropFrequency then
        RandomAirdrops.spawnIndex = 0;
        local tries = 20;
        while tries > 0 do

            if #usingAirdropPositions == 0 then
                tries = 0; break;
            end

            RandomAirdrops.spawnIndex = ZombRand(#usingAirdropPositions) + 1;
            local alreadySpawned = false;
            for i = 1, #SpawnedAirdrops do
                if SpawnedAirdrops[i].index == spawnIndex then
                    alreadySpawned = true;
                    break;
                end
            end

            if SandboxVars.AirdropMain.AirdropDisableOldDespawn then
                for i = 1, #AirdropsData.OldAirdrops do
                    if AirdropsData.OldAirdrops[i] == spawnIndex then
                        alreadySpawned = true;
                        break;
                    end
                end
            end

            if alreadySpawned then
                tries = tries - 1;
            end
            if not alreadySpawned then break end
            print("[Air Drop] Cannot spawn airdrop, the index " .. spawnIndex .. " has already in use");
        end

        if tries <= 0 then
            print("[Air Drop] Warning cannot find a spawn area that has not been spawned, air drop not spawned");
            return nil;
        end

        local spawnAreaName = ""
        if SandboxVars.AirdropMain.DefaultAirdropCoordinates then
            spawnAreaName = getText("IGUI_Airdrop_Name_"..usingAirdropPositions[RandomAirdrops.spawnIndex].name)
        else
            spawnAreaName = getText(usingAirdropPositions[RandomAirdrops.spawnIndex].name)
        end
        -- Добавляем задержку спавна аирдропа
        RandomAirdrops.delay = 0;
        Events.EveryTenMinutes.Add(SpawnAirdropDelay)
        -- Возвращаем в aidrop_radio зону спавна
        return spawnAreaName;

    else
        print("[Air Drop] Global airdrop spawn chance check: no");
        return false;
    end
end

function SpawnAirdropDelay()
    local rand = newrandom()
    -- Ожидаем от 40 до 90 минут перед спавном аирдропа
    if RandomAirdrops.delay < rand:random(4, 9)  then
        RandomAirdrops.delay = RandomAirdrops.delay + 1;
        return;
    end
    Events.EveryTenMinutes.Remove(SpawnAirdropDelay);

    SpawnAirdrop(RandomAirdrops.spawnIndex);
end

-- Spawna um airdrop ao mundo aleatoriamente
function SpawnAirdrop(_spawnIndex)
    local spawnIndex = _spawnIndex;

    -- Recebemos a area de spawn
    local spawnArea = usingAirdropPositions[spawnIndex];

    -- Adicionamos a lista de airdrops spawnados
    table.insert(SpawnedAirdrops, { airdrop = nil, ticksToDespawn = SandboxVars.AirdropMain.AirdropRemovalTimer, index = spawnIndex });
    -- Adicionamos na lista de airdrops ainda para spawnar
    table.insert(AirdropsToSpawn, spawnIndex);

    -- Precisamos verificar se DisableOldDespawn esta ativo
    -- para podermos adicionar os dados a OldAirdropsData
    if SandboxVars.AirdropMain.AirdropDisableOldDespawn then
        -- Adicionamos a lista de OldAirdropsData
        table.insert(AirdropsData.OldAirdropsData, { airdrop = false, ticksToDespawn = SandboxVars.AirdropMain.AirdropRemovalTimer, index = spawnIndex });
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

    getSoundManager():PlayWorldSound("AirdropSoundPlane", getCell():getGridSquare(spawnArea.x, spawnArea.y, spawnArea.z), 0, 200, 5, true);
    getWorldSoundManager():addSound(spawnArea,
            spawnArea.x,
            spawnArea.y,
            spawnArea.z,
            200, 10);
    RandomAirdrops.FlyOver(spawnArea);
end

function RandomAirdrops.DespawnAirdrops()
    local localSpawnedAirdrops = deepcopy(SpawnedAirdrops);
    for i = 1, #localSpawnedAirdrops do
        if localSpawnedAirdrops[i].ticksToDespawn <= 0 then
            local airdrop = localSpawnedAirdrops[i].airdrop;

            if not airdrop then
                local spawnIndex = localSpawnedAirdrops[i].index;
                print("[Air Drop] Uncreated Air drop has been removed in X:" ..
                    usingAirdropPositions[spawnIndex].x .. " Y:" .. usingAirdropPositions[spawnIndex].y);
                removeElementFromAirdropsToSpawnBySpawnIndex(spawnIndex);
                removeElementFromSpawnedAirdropsBySpawnIndex(spawnIndex);
                if SandboxVars.AirdropMain.AirdropDisableOldDespawn then
                    removeElementFromOldAirdropsDataBySpawnIndex(spawnIndex)
                end
            else
                local havePlayerAround = checkPlayersAround(airdrop);

                local spawnIndex = localSpawnedAirdrops[i].index;

                if not havePlayerAround then
                    airdrop:permanentlyRemove();
                    print("[Air Drop] Air drop has been removed in X:" .. airdrop:getX() .. " Y:" .. airdrop:getY());
                    removeElementFromSpawnedAirdropsBySpawnIndex(spawnIndex);
                    removeAirdropFromOldAirdropsBySpawnIndex(spawnIndex);
                    if SandboxVars.AirdropMain.AirdropDisableOldDespawn then
                        removeElementFromOldAirdropsDataBySpawnIndex(spawnIndex)
                    end
                end
            end
        else
            for j = 1, #SpawnedAirdrops do
                if localSpawnedAirdrops[i].index == SpawnedAirdrops[j].index then
                    SpawnedAirdrops[j].ticksToDespawn = SpawnedAirdrops[j].ticksToDespawn - 1;
                    break;
                end
            end
        end
    end

    for i = 1, #AirdropsData.SpecificAirdropsSpawned do
        if AirdropsData.SpecificAirdropsSpawned[i].ticksToDespawn <= 0 then
            Events.OnTick.Remove(ForceDespawnAirdrops);
            Events.OnTick.Add(ForceDespawnAirdrops);
        else
            AirdropsData.SpecificAirdropsSpawned[i].ticksToDespawn = AirdropsData.SpecificAirdropsSpawned[i].ticksToDespawn - 1;
        end
    end

    if SandboxVars.AirdropMain.AirdropDisableOldDespawn then
        for i = 1, #AirdropsData.OldAirdropsData do
            local data = AirdropsData.OldAirdropsData[i];
            if data.ticksToDespawn <= 0 then
                if checkSpawnAirdropsExistenceBySpawnIndex(data.index) then
                    table.insert(AirdropsData.RemovingOldAirdrops, data.index);
                    Events.OnTick.Remove(ForceDespawnAirdrops);
                    Events.OnTick.Add(ForceDespawnAirdrops);
                end
            else
                for j = 1, #AirdropsData.OldAirdropsData do
                    if data.index == AirdropsData.OldAirdropsData[j].index then
                        AirdropsData.OldAirdropsData[j].ticksToDespawn = AirdropsData.OldAirdropsData[j].ticksToDespawn - 1;
                        break;
                    end
                end
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
                if airdrop:getScriptName() == "RandomAirdropsASV.airdrop" then
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
                        if airdrop:getScriptName() == "RandomAirdropsASV.airdrop" then
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
                    if airdrop:getScriptName() == "RandomAirdropsASV.airdrop" then
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
            local square
            if (spawnArea) then
                square = getCell():getGridSquare(spawnArea.x, spawnArea.y, spawnArea.z)
            end
            -- Verificamos se o square esta sendo carregado
            if square then
                -- Adicionamos o airdrop no mundo
                -- Notas importantes: addVehicleDebug necessita obrigatoriamente que square tenha
                -- o elemento chunk, não se engane chunk é na verdade o campo de visão do jogador,
                -- ou seja você só pode spawnar um veiculo se o player esta carregando o chunk por perto
                local airdrop = addVehicleDebug("RandomAirdropsASV.airdrop", IsoDirections.N, nil, square);
                -- Consertamos caso esteja quebrado
                airdrop:repair();
                -- Adicionamos os loots
                spawnAirdropItems(airdrop);

                -- Removemos da nossa lista de AirdropsToSpawn
                removeElementFromAirdropsToSpawnBySpawnIndex(spawnIndex);

                -- Adicionamos o aidrop para lista de SpawnedAirdrops
                addAirdropToSpawnedAirdropsBySpawnIndex(spawnIndex, airdrop)

                -- Precisamos verificar se DisableOldDespawn esta ativo
                -- para podermos adicionar dizer que airdrop é true na lista de OldAirdropsData
                if SandboxVars.AirdropMain.AirdropDisableOldDespawn then
                    -- Colocamos para true
                    for j = 1, #AirdropsData.OldAirdropsData do
                        -- Verifica se o spawnIndex é o mesmo do OldAirdropsData
                        if spawnIndex == AirdropsData.OldAirdropsData[j].index then
                            -- Colocamos para true
                            AirdropsData.OldAirdropsData[j].airdrop = true;
                            break;
                        end
                    end
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
        local airdrop = addVehicleDebug("RandomAirdropsASV.airdrop", IsoDirections.N, nil, square);
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
        return airdrop
    else
        print("[Air Drop] Specific Airdrop: Cannot spawn the square is invalid in X: " ..
            spawnArea.x .. " Y: " .. spawnArea.y);
    end
end

-- Carregamos os dados
Events.OnInitGlobalModData.Add(function(isNewGame)
    AirdropsData = ModData.getOrCreate("serverAirdropsData");
    -- Null Check
    if not AirdropsData.OldAirdrops then AirdropsData.OldAirdrops = {} end
    if not AirdropsData.OldAirdropsData then AirdropsData.OldAirdropsData = {} end
    if not AirdropsData.RemovingOldAirdrops then AirdropsData.RemovingOldAirdrops = {} end
    if not AirdropsData.SpecificAirdropsSpawned then AirdropsData.SpecificAirdropsSpawned = {} end
    readAirdropsPositions();
    readAirdropsLootTable();

    if SandboxVars.AirdropMain.DefaultAirdropCoordinates then
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