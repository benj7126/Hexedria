local Chronos = require "Server/chronos"
local Layer = require "Server/layer"

local Player = require "Server/entities.player"

local outerRadius = 10
local innerRadius = outerRadius * 0.866025404

local World = {}

function World:new()
    local world = {}

    world.tempDKmap = nil
    
    world.layer = 0
    world.layerObj = nil

    world.players = {} -- list of players

    world.speed = 0--0.2 -- speed of the world entity update
    -- should be something like 
    -- instant = 0
    -- fast = 0.05
    -- normal = 0.2
    -- slow = 0.4

    world.weapons = {}

    world.moveCooldown = 0

    world.chronos = Chronos:new()

    setmetatable(world, self)
    self.__index = self
    return world
end

function World:setup()
    TestWorld:loadWeapons()
    TestWorld:nextLayer()
end


function World:initiatePlayer(peer)
    local plr = Player:new(self);
    plr:connect(peer)

    table.insert(self.player, Player:new(self))

    local x, y = self.layerObj:plrSpawn()

    self.chronos:addEntity(self.player, x, y)
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
    self.layerObj = Layer:new(self)

    for i, plr in pairs(self.players) do
        local x, y = self.layerObj:plrSpawn()
        self.layerObj:addEntity(self.player, x, y)
    end

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

function World:getHex()
    local x, y = self:getMousePosition()
    
    return ScreenToHexRound(x, y)
end

return World