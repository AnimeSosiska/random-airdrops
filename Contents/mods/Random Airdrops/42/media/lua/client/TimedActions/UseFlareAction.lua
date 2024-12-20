require "TimedActions/ISBaseTimedAction"

RandomAirdrops = RandomAirdrops or {}

local UseFlareAction = ISBaseTimedAction:derive("UseFlareAction")
RandomAirdrops.UseFlareAction = UseFlareAction

function UseFlareAction:isValid()
    return self.character:getInventory():contains(self.flare)
end

function UseFlareAction:start()
    self.action:setTime(50)
    self:setActionAnim("RipSheets")
    self:setOverrideHandModels(self.flare, nil)
    self.sound = self.character:getEmitter():playSound("ClothesRipping")
end

function UseFlareAction:update()

end

function UseFlareAction:stop()
    self:stopSound()
    ISBaseTimedAction.stop(self)
end

function UseFlareAction:perform()
    self:stopSound()
    self.character:getInventory():Remove(self.flare)
    sendClientCommand(self.character,'ServerAirdrop', 'startBeacon', nil);
    local args = { x = self.character:getX(), y = self.character:getY(), z = self.character:getZ() }
    sendClientCommand(self.character, 'object', 'addSmokeOnSquare', args)
    ISBaseTimedAction.perform(self)
end

function UseFlareAction:stopSound()
    if self.sound and self.character:getEmitter():isPlaying(self.sound) then
        self.character:stopOrTriggerSound(self.sound);
    end
end

function UseFlareAction:new(character, flare)
    local o = ISBaseTimedAction.new(self, character)
    o.stopOnWalk = true
    o.stopOnRun = true
    o.stopOnAim = true
    o.maxTime = 10
    o.step = 0
    o.useProgressBar = true
    o.flare = flare
    return o
end