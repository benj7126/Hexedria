local Instance = require "chronosInstance"
-- time manager

local Chronos = {}

function Chronos:new()
    local chronos = {}
    
    chronos.instances = {}

    setmetatable(chronos, self)
    self.__index = self
    return chronos
end

function Chronos:addLayer(layer)
    -- to be made
end

function Chronos:addEntity(entity)
    self.instances[entity] = Instance:new(entity)
end

function Chronos:remEntity(entity)
    self.instances[entity] = nil
end

function Chronos:removeLayer(layer)
    -- to be made
end

function Chronos:removeEntity(entity)
    self.instances[entity] = nil
end

function Chronos:resetEntity(entity)
    self.instances[entity].time = 0
end

function Chronos:getNextEntity()
    local lowest = {0, 9^9}
    --       {entityID, timesToUpdate}
    
    for i, v in pairs(self.instances) do
        local updates = v:updatesTillTurn()

        if updates < lowest[2] then
            lowest = {i, updates}
        end
    end

    for i, v in pairs(self.instances) do
        v:updateXTimes(lowest[2])
    end

    return self.instances[lowest[1]].entity
end

function Chronos:getNextEntityNoUpdate()
    local lowest = {0, 9^9}
    
    for i, v in pairs(self.instances) do
        local updates = v:updatesTillTurn()

        if updates < lowest[2] then
            lowest = {i, updates}
        end
    end
    
    return self.instances[lowest[1]].entity
end

return Chronos