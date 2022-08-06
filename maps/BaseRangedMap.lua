local Map = require("maps.BaseMap"):new()

Map.targetMin = 1
Map.targetMax = 1

function Map:getName()
    return "CloseRange"
end

function Map:setMapValues() -- call whenever targets moves (aka plr...)
    local size = self.layerBase.size

    for x = -size/2, size/2 do
        if self.gridClone[x] then
            for y = -size/2, size/2 do
                if self.gridClone[x][y] then
                    self.gridClone[x][y] = -1
                end
            end
        end
    end

    local toChange = self:getTargets()

    local plr = toChange[1][1]

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
                    if self.gridClone[v[1]][v[2]] == -1 and self.layerBase.grid[v[1]][v[2]]:unPassable() == false then
                        self.gridClone[v[1]][v[2]] = -2
                        table.insert(toChange, {v, val+1})
                    end
                end
            end
        end
    end
    
    local newToChange = {}

    local target = self.targetMax;

    while #newToChange == 0 and target ~= self.targetMin-1 do
        for x = -size/2, size/2 do
            if self.gridClone[x] then
                for y = -size/2, size/2 do
                    if self.gridClone[x][y] then
                        if self.gridClone[x][y] == target and CastHexRay(x, y, plr[1], plr[2], self.layerBase.world) then
                            table.insert(newToChange, {{x, y}, 0})
                            self.gridClone[x][y] = -2
                        else
                            self.gridClone[x][y] = -1
                        end
                    end
                end
            end
        end
        target = target - 1
    end

    if #newToChange == 0 then
        local plr = self.layerBase.world.player
        newToChange = {{{plr.pos[1], plr.pos[2]}, 0}}
    end

    while #newToChange ~= 0 do
        
        local low = {0, 9^9}
        for i, v in pairs(newToChange) do
            if v[2] < low[2] then
                low = {i, v[2]}
            end
        end

        local pos = newToChange[low[1]][1]
        local val = newToChange[low[1]][2]
        table.remove(newToChange, low[1])

        self.gridClone[pos[1]][pos[2]] = val

        local mabyNew = GetPositions(pos[1], pos[2])
        for i, v in pairs(mabyNew) do
            if self.gridClone[v[1]] then
                if self.gridClone[v[1]][v[2]] then
                    if self.gridClone[v[1]][v[2]] == -1 and self.layerBase.grid[v[1]][v[2]]:unPassable() == false then
                        self.gridClone[v[1]][v[2]] = -2
                        table.insert(newToChange, {v, val+1})
                    end
                end
            end
        end
    end
end

return Map