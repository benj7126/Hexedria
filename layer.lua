local LayerGen = require "layerGenerator"

local G = require("entities.Goblin")
local SG = require("entities.StoneGoblin")

local Layer = {}

function Layer:new(world)
    local layer = {}

    layer.world = world

    layer.movementMaps = {}

    layer.size = 80
    
    layer.images = { -- then the other layers should replace the images
        
    }

    layer.grid, layer.rooms, layer.debug = LayerGen(world, layer.size)
    -- layer.rooms excluding starter room

    setmetatable(layer, self)
    self.__index = self

    layer.monsters = {}

    layer:setDefaults()

    layer:placeEntities()

    return layer
end

function Layer:placeEntities()
    
end

function Layer:setDefaults()
    self.monsters = {
        Normal = {G, SG},
        Strong = {},
        Boss = {}
    }
end

function Layer:getNextMove(entity, name)
    return self.movementMaps[name]:getNextMove(entity)
end

function Layer:getMapVal(entity, name)
    return self.movementMaps[name]:getMapVal(entity)
end

function Layer:removeEntity(entity)
    self.grid[entity.pos[1]][entity.pos[2]].entity = nil
    
    for i, v in pairs(self.movementMaps) do
        v:calcEntitys() -- huh, why dis no work?
    end
end

function Layer:addEntity(entity, x, y)
    self.grid[x][y].entity = entity
    entity.pos = {x, y}
    
    self.world.chronos:addEntity(entity)
    
    for i, v in pairs(self.movementMaps) do
        v:calcEntitys()
    end
end

function Layer:addMovementMap(name, map)
    if not self.movementMaps[name] then
        self.movementMaps[name] = map:new(self)
        self.movementMaps[name]:setupMap()
    end
end

function Layer:getVisibleEntites()
    local entities = {}
    
    for x = -self.size/2, self.size/2 do
        for y = -self.size/2, self.size/2 do
            if self.grid[x][y] then
                if self.grid[x][y].visibility == 2 and self.grid[x][y].entity then
                    table.insert(entities, self.grid[x][y].entity)
                end
            end
        end
    end

    return entities
end

function Layer:playerMoved(fx, fy, tx, ty, world)
    for x = -self.size/2, self.size/2 do
        for y = -self.size/2, self.size/2 do
            if self.grid[x][y] then
                local entity = self.grid[x][y].entity
                if entity then
                    if entity.name ~= "You" then
                        entity:playerMoved(fx, fy, tx, ty, world)
                    end
                end
            end
        end
    end
    
    -- let the entities make paths to the player before they change

    for i, v in pairs(self.movementMaps) do
        -- print(i, v:updatePlrMove())
        if v:updatePlrMove() then
            v:setMapValues()
        end
    end
end

function Layer:isHexFree(x, y) -- no entity
    if self.grid[x] then
        if self.grid[x][y] then
            if self.grid[x][y].entity == nil and self.grid[x][y]:unPassable() == false then
                return true
            end
        end
    end
    return false
end

function Layer:isHexWall(x, y) -- is there a wall there
    if self.grid[x] then
        if self.grid[x][y] then
            if self.grid[x][y]:unPassable() then
                return true
            end
        end
    end
    return false
end

function Layer:hexExists(x, y) -- is it in grid (within size, or something)
    if self.grid[x] then
        if self.grid[x][y] then
            return true
        end
    end
    return false
end

function Layer:moveEntityTo(entity, x, y)
    for i, v in pairs(self.movementMaps) do
        v:entityMoved(entity.pos[1], entity.pos[2], x, y)
    end

    self.grid[x][y].entity = self.grid[entity.pos[1]][entity.pos[2]].entity
    self.grid[entity.pos[1]][entity.pos[2]].entity = nil
    entity.pos = {x, y}
end

function Layer:draw()
    for x = -self.size/2, self.size/2 do
        for y = -self.size/2, self.size/2 do
            if self.grid[x][y] then
                self.grid[x][y]:draw(x, y, self.world)
                
                -- debugging layerGen
                -- if self.debug[x] then
                --     if self.debug[x][y] then
                --         love.graphics.setColor(0, 0, 1)
                --         local nx, ny = ScreenToHex(x, y)
                --         love.graphics.printf(self.debug[x][y], nx, ny, 100, "left", 0, 0.3)
                --     end
                -- end
            end
        end
    end
    -- self.movementMaps["CloseRange"]:draw()

    -- for i, v in pairs(self.movementMaps) do
    --     v:draw()
    -- end

    -- local x, y = TestWorld:getMousePosition()

    -- y = y/(outerRadius*1.5)
    -- x = x/(innerRadius*2)-y*0.5

    -- print(x, y)

    -- drawHexagonSMOL((x + y * 0.5)*innerRadius*2, y*outerRadius*1.5)
end

return Layer