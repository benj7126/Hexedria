local Chronos = require "chronos"
local Layer = require "layer"

local Player = require "entities.player"

local outerRadius = 10
local innerRadius = outerRadius * 0.866025404

local World = {}

function World:new()
    local world = {}

    world.tempDKmap = nil
    
    world.layer = 0
    world.layerObj = nil

    world.player = nil -- refference to player

    world.guiActive = true

    world.transform = love.math.newTransform()

    world.speed = -0.4 -- speed of the world entity update
    -- should be something like 
    -- instant = 0
    -- fast = 0.05
    -- normal = 0.2
    -- slow = 0.4

    world.weapons = {}

    world.followingEntity = nil

    world.movementMaps = {}

    world.moveCooldown = 0

    world.transformTranslate = {0, 0}
    world.transformScale = 4

    world.mouseLast = {0, 0, 0}

    world.chronos = Chronos:new()

    setmetatable(world, self)
    self.__index = self
    return world
end

function World:initiatePlayer()
    self.player = Player:new(self)
    self.chronos:addEntity(self.player)
end

function World:addEntity(entity, x, y)
    self.layerObj:addEntity(entity, x, y)
end

function World:loadWeapons()
    local weapons = love.filesystem.getDirectoryItems("weapons")
    for i, v in pairs(weapons) do
        local name = string.sub(v, 1, #v-4)
        local weapon = require("weapons."..name)

        self.weapons[name] = weapon:new()
        self.weapons[name].name = name
    end
end

function World:removeEntity(entity)
    self.chronos:removeEntity(entity)
    self.layerObj:removeEntity(entity)
end

function World:getWeapon(name)
    return self.weapons[name]
end

function World:nextLayer() -- need some parameters or something to keep track of current layer, and some reason to keep track of layer...
    self.movementMaps = {}
    self.layerObj = Layer:new(self)

    self.layerObj:addEntity(self.player, 0, 0)

    local maps = love.filesystem.getDirectoryItems("maps")
    for i, v in pairs(maps) do
        local map = require("maps."..string.sub(v, 1, #v-4))

        self.layerObj:addMovementMap(map:getName(), map)
    end
end

function World:playerMoved(fx, fy, tx, ty)
    self.layerObj:playerMoved(fx, fy, tx, ty, self)
end

function World:update(dt)
    if self.player then
        self.player:preDraw(self)
    end

    if self.player.chronosInstance.time ~= -1 then
        self.moveCooldown = self.moveCooldown + dt
        
        local entity = self.chronos:getNextEntityNoUpdate()

        if self.moveCooldown >= self.speed then
            self.moveCooldown = 0
            local entity = self.chronos:getNextEntity()
        
            local clearTime = entity:AI(self)
        
            if clearTime or clearTime == nil then
                entity.chronosInstance.time = 0
            else
                entity.chronosInstance.time = -1
            end

            if self.layerObj.grid[entity.pos[1]][entity.pos[2]].visibility ~= 2 then
                self.moveCooldown = self.speed
            end
        end

        if self.speed == 0 then
            self:update(0)
--        elseif within vision then
--            self:update(self.speed)
        end
    end 
end

function World:draw()
    if self.player then
        self.player:preDraw(self)
    end

    if self.followingEntity then
        local pos = self.followingEntity.pos
        
        if self.layerObj.grid[pos[1]][pos[2]].visibility ~= 2 then
            self.followingEntity = nil
        end
    end

    local visibleEntites = self.layerObj:getVisibleEntites()

    local mx, my = love.mouse.getPosition()
    for i, entity in pairs(visibleEntites) do
        local val = entity.chronosInstance.time
        if val == -1 then val = 100 end
        local y = val/100*(H-48)+24
        if math.abs(mx-24) < 10 and math.abs(my-y) < 10 then
            entity.highlight = true
        end
    end

    self:applyTransform()

    self.layerObj:draw(self) -- clears visible tiles so do above before

    love.graphics.origin()

    if love.keyboard.isDown("space") then
        local x, y = self:getHex()
        if self.layerObj:hexExists(x, y) then
            if self.layerObj.grid[x][y].entity then
                local sx, sy = ScreenToHex(x, y)
                sx, sy = self.transform:transformPoint(sx, sy)
                self.layerObj.grid[x][y].entity:displayWindow(sx, sy)
            end
        end
    end

    if self.guiActive then
        self:drawGUI(visibleEntites)
        self:drawGround()
        if self.player then
            self:drawPlrGUI()
        end
    end
end

function World:drawGUI(visibleE)
    love.graphics.setLineWidth(5)

    SetColor(2)
    love.graphics.rectangle("fill", 24, 24, 2, H-48)

    for i, entity in pairs(visibleE) do
        local val = entity.chronosInstance.time
        if val == -1 then val = 100 end
        local y = val/100*(H-48)+24
        entity:drawIcon(24, y)
    end
end

function World:drawGround()
    love.graphics.rectangle("fill", W-16*3, 16, 48, 48)
end

function World:drawPlrGUI()
    local x, y = W-300-2.5, H-115-2.5
    self.player:displayWindowPLR(x, y)
end

function World:getHex()
    local x, y = self:getMousePosition()
    
    return ScreenToHexRound(x, y)
end

function World:getMousePosition()
    local x, y = love.mouse.getPosition()
    
    return self.transform:inverseTransformPoint(x, y)
end

function World:applyTransform()
    local x, y = love.mouse.getPosition()
    if self.mouseLast[3] == 2 then
        self.transformTranslate[1] = self.transformTranslate[1] + (x-self.mouseLast[1])/self.transformScale
        self.transformTranslate[2] = self.transformTranslate[2] + (y-self.mouseLast[2])/self.transformScale
        self.mouseLast = {x, y, 2}
    end
    self.transform = love.math.newTransform():translate(400, 300)
    :scale(self.transformScale, self.transformScale)
    
    if self.followingEntity ~= nil then
        local target = self.followingEntity.pos

        self.transformTranslate = {HexToScreen(target[1], target[2])}
    end
    
    self.transform:translate(self.transformTranslate[1], self.transformTranslate[2])

    love.graphics.applyTransform(self.transform)
end

function World:mousepressed(x, y, b)
    if self.player then
        self.player:mousepressed(self, x, y, b)
    end

    if b == 2 then
        self.followingEntity = nil
        self.mouseLast = {x, y, b}
    elseif b == 3 then
        self.followingEntity = nil
        local hx, hy = self:getHex()
        if self.layerObj:hexExists(hx, hy) then
            if self.layerObj.grid[hx][hy].entity then
                self.followingEntity = self.layerObj.grid[hx][hy].entity
            end
        end
    end
end

function World:mousereleased(x, y, b)
    self.mouseLast = {0, 0, 0}
end

function World:wheelmoved(x, y)
    self.transformScale = math.max(self.transformScale + y, 1)
end

function printLoop(val, str, depth)
    if depth > 10 then return end
    if type(val) == "table" then
        for i, v in pairs(val) do
            print(str..i)
            printLoop(v, "    "..str, depth+1)
        end
    elseif type(tostring(val)) == "string" then
        print(str..tostring(val))
    end
end

return World