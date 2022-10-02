local Map = require("maps.BaseMap"):new()

function Map:getName()
    return "StickToRoom"
end

function Map:updatePlrMove()
    return false
end

function Map:getTargets()
    local change = {}

    for i, v in pairs(self.layerBase.rooms) do
        -- print(i, v[1], v[2], v[3])
        table.insert(change, {{v[1], v[2]}, -v[3]})
    end

    return change
end

function Map:PostMapCalc()
    local size = self.layerBase.size
    
    for x = -size/2, size/2 do
        if self.gridClone[x] then
            for y = -size/2, size/2 do
                if self.gridClone[x][y] then
                    if self.gridClone[x][y] < 0 then
                        self.gridClone[x][y] = 0
                    end
                end
            end
        end
    end
end

return Map