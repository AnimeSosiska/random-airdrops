RandomAirdrops = RandomAirdrops or {}

function RandomAirdrops.UseFlare(playerObj, flare)
    local playerInv = playerObj:getInventory()
    if not playerInv:contains(flare) then
        local itemSquare = flare:getWorldItem():getSquare()
        if luautils.walkAdj(playerObj, itemSquare, true) then
            ISTimedActionQueue.add(ISInventoryTransferAction:new(playerObj, flare, flare:getContainer(), playerInv))
        end
    end
    ISTimedActionQueue.add(RandomAirdrops.UseFlareAction:new(playerObj, flare))
end

function RandomAirdrops.FlareItemOptions(player, context, items)
    local playerObj = getSpecificPlayer(player)
    local flare
    local c = 0

    items = ISInventoryPane.getActualItems(items)
    for i,item in ipairs(items) do
        if item:getType() == "SmokeFlare" then
            flare = item
        end
        if c > 0 then
            flare = nil
        end
        c = c + 1
    end
    if flare then
        context:addOption(getText("ContextMenu_RandomAirdrops_UseFlare"), playerObj, RandomAirdrops.UseFlare, flare)
    end
end
Events.OnFillInventoryObjectContextMenu.Add(RandomAirdrops.FlareItemOptions)