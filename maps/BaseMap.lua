local Map = {}

local lowVal = -999

function Map:new(layer)
    local map = {}
    
    map.layerBase = layer
    map.gridClone = {}
    map.gridCloneEntity = {}

    setmetatable(map, self)
    self.__index = self

    return map
end

function Map:getName()
    return "Default"
end

function Map:setupMap()
    self.gridClone = GenerateGridClone(self.layerBase)
    self.gridCloneEntity = GenerateGridClone(self.layerBase)
    self:setMapValues()
    self:calcEntitys()
end

function Map:getNextMove(entity)
    local positions = GetPositions(entity.pos[1], entity.pos[2])
    local curVal = self.gridClone[entity.pos[1]][entity.pos[2]]

    local moves = {}

    -- loop for move closer

    for i, v in pairs(positions) do
        if self.gridClone[v[1]] then
            if self.gridClone[v[1]][v[2]] then
                if self.gridClone[v[1]][v[2]] + self.gridCloneEntity[v[1]][v[2]] == curVal-1 then
                    table.insert(moves, v)
                end
            end
        end
    end
    
    -- loop just to move (not walking away)
    if #moves == 0 then
        for i, v in pairs(positions) do
            if self.gridClone[v[1]] then
                if self.gridClone[v[1]][v[2]] then
                    if self.gridClone[v[1]][v[2]] + self.gridCloneEntity[v[1]][v[2]] == curVal then
                        table.insert(moves, v)
                    end
                end
            end
        end
    end

    if #moves == 0 then
        return entity.pos
    else
        return moves[love.math.random(1, #moves)]
    end
end

function Map:getPathTowardsPlrFrom(entity)
    local returnPath = {}

    local lastPos = {entity.pos[1], entity.pos[2]}
    local nextPos = self:getNextMove(entity)
    
    while not (lastPos[1] == nextPos[1] and lastPos[2] == nextPos[2]) do
        table.insert(returnPath, {nextPos[1], nextPos[2]})
        lastPos = {nextPos[1], nextPos[2]}
        nextPos = self:getNextMove({pos = lastPos})
    end

    return returnPath
end

function Map:getMapVal(entity)
    return self.gridClone[entity.pos[1]][entity.pos[2]]
end

function Map:updatePlrMove()
    return true
end

function Map:getTargets()
    local size = self.layerBase.size
    local change = {}

    for x = -size/2, size/2 do
        if self.gridClone[x] then
            for y = -size/2, size/2 do
                if self.gridClone[x][y] then
                    if self.layerBase.grid[x][y].entity ~= nil then
                        -- print(self.layerBase.grid[x][y].entity.name, "\n k\n k\n k\n k\n k\n k")
                        if self.layerBase.grid[x][y].entity.name == "You" then
                            table.insert(change, {{x, y}, 0})
                        end
                    end
                end
            end
        end
    end

    return change
end

function Map:setMapValues() -- call whenever targers moves
    local size = self.layerBase.size

    for x = -size/2, size/2 do
        if self.gridClone[x] then
            for y = -size/2, size/2 do
                if self.gridClone[x][y] then
                    self.gridClone[x][y] = lowVal
                end
            end
        end
    end

    local toChange = self:getTargets()

    while #toChange ~= 0 do
        
        local low = {0, 9^9}
        for i, v in pairs(toChange) do
            if v[2] < low[2] then
                low = {i, v[2]}
            end
        end

        local pos = toChange[low[1]][1]
        local val = toChange[low[1]][2]
        table.remove(toChange, low[1])

        self.gridClone[pos[1]][pos[2]] = val

        local mabyNew = GetPositions(pos[1], pos[2])
        for i, v in pairs(mabyNew) do
            if self.gridClone[v[1]] then
                if self.gridClone[v[1]][v[2]] then
                    if self.gridClone[v[1]][v[2]] == lowVal and self.layerBase.grid[v[1]][v[2]]:unPassable() == false then
                        self.gridClone[v[1]][v[2]] = lowVal-1
                        table.insert(toChange, {v, val+1})
                    end
                end
            end
        end
    end
    self:PostMapCalc()
end

function Map:PostMapCalc()
    
end

function Map:calcEntitys()
    local size = self.layerBase.size

    for x = -size/2, size/2 do
        if self.gridCloneEntity[x] then
            for y = -size/2, size/2 do
                if self.gridCloneEntity[x][y] then
                    if self.layerBase.grid[x][y].entity ~= nil then
                        self.gridCloneEntity[x][y] = 10
                    else
                        self.gridCloneEntity[x][y] = 0
                    end
                end
            end
        end
    end
end

function Map:entityMoved(fx, fy, tx, ty) -- from x, y | to x, y
    local save = self.gridCloneEntity[tx][ty]
    self.gridCloneEntity[tx][ty] = self.gridCloneEntity[fx][fy]
    self.gridCloneEntity[fx][fy] = save
end

function Map:entityKilled(x, y) -- from x, y | to x, y
    self.gridCloneEntity[x][y] = 0
end

function Map:draw()
    local size = self.layerBase.size

    love.graphics.setColor(1, 1, 1)

    for x = -size/2, size/2 do
        if self.gridClone[x] then
            for y = -size/2, size/2 do
                if self.gridClone[x][y] then
                    local nx, ny = ScreenToHex(x, y)
                    love.graphics.printf(""..self.gridClone[x][y]+self.gridCloneEntity[x][y], nx, ny, 100, "left", 0, 0.3)
                end
            end
        end
    end
end

return Map