local Instance = {}

local timeForMove = 100

function Instance:new(entity)
    local instance = {}
    instance.entity = entity
    instance.time = 0 -- counts up to 100

    entity.chronosInstance = instance

    setmetatable(instance, self)
    self.__index = self

    return instance
end

function Instance:updatesTillTurn()
    return (timeForMove-self.time)/self.entity:getSpeed()
end

function Instance:updateXTimes(timesToUpdate)
    self.time = self.time + self.entity:getSpeed()*timesToUpdate
end

return Instance