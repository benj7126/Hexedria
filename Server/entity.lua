local Entity = {
    name = '#%¤¤¤#%¤#',
    maxhp = 0,
    hp = 0,
    maxmp = 0,
    mp = 0,
    speed = 1,
    weapon = 0,
    pos = {0, 0},
    chronosInstance = nil,
    followPath = {},
}

local outerRadius = 10
local innerRadius = outerRadius * 0.866025404

function Entity:new(world)
    local entity = {}

    if world == nil then
        setmetatable(entity, self)
        self.__index = self
        return entity
    end

    entity.name = '#%¤¤¤#%¤#'
    
    entity.speed = 0.8

    entity.maxhp = 10
    entity.maxmp = 10

    entity.lastSeenPlayer = {}
    
    entity.highlight = false

    entity.weapon = "Fists"
    entity.pos = {0, 0}

    entity.chronosInstance = nil

    setmetatable(entity, self)
    self.__index = self

    entity:setDefaults(world)
    
    entity.hp = entity.maxhp
    entity.mp = entity.maxmp

    entity.weapon = world:getWeapon(entity.weapon):new()

    return entity
end

function Entity:setDefaults(world)
    
end

function Entity:getSpeed()
    return self.speed-self.weapon.weight/100
end

function Entity:displayWindow(x, y) -- center of rectangle
    local displayeSize = {300.0, 200.0}
    
    local topLeft = {x-displayeSize[1]/2, y-displayeSize[2]-20}
    if topLeft[1] < 0 then
        topLeft[1] = 0
    elseif topLeft[1]+displayeSize[1] > W then
        topLeft[1] = W-displayeSize[1]
    end
    if topLeft[2] < 0 then
        topLeft[2] = 0
    elseif topLeft[2]+displayeSize[2]-20 > H then
        topLeft[2] = W-displayeSize[2]-20
    end

    x, y = topLeft[1], topLeft[2]
    local sx, sy = displayeSize[1], displayeSize[2]

    love.graphics.setLineWidth(5)

    SetColor(2)
    love.graphics.rectangle("fill", x, y, sx, sy)
    SetColor(1)
    love.graphics.rectangle("line", x, y, sx, sy)
    SetColor(5)
    love.graphics.printf("Name: "..self.name, x+10, y+10, sx)
    love.graphics.printf("Weilding: "..self.weapon.name, x+10, y+30, sx)

    self:drawStencilRect("fill", x+10, y+sy-40, (sx-20), 30, 15, self.maxhp, self.hp, {0, 1, 0})

    SetColor(1)
    love.graphics.rectangle("line", x+10, y+sy-40, sx-20, 30, 15)
end

function Entity:drawIcon(x, y)
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.rectangle("fill", x-10, y-10, 20, 20)
end

function Entity:attack(world, entity)
    entity:takeDamage(world, self.weapon:getDamage())
end

function Entity:takeDamage(world, amount)
    self.hp = self.hp - amount

    print(self.hp)

    if self.hp <= 0 then
        self:onDeath(world)
        world:removeEntity(self)
    end
end

function Entity:onDeath(world)
    if love.math.random(1, 2) == 1 then
        table.insert(world.layerObj.grid[self.pos[1]][self.pos[2]].onGround, self.weapon)
    end
end

function Entity:drawStencilRect(mode, x, y, w, h, round, max, cur, color) -- hm
    local function myStencilFunction()
        love.graphics.rectangle(mode, x, y, w, h, round)
    end

    love.graphics.stencil(myStencilFunction, "replace", 1)
    love.graphics.setStencilTest("greater", 0)

    love.graphics.setColor(color)
    love.graphics.rectangle(mode, x, y, w/max*cur, h)

    love.graphics.setStencilTest()
end

function Entity:AI(world)
        -- move
    if CastHexRay(self.pos[1], self.pos[2], world.player.pos[1], world.player.pos[2], world) then -- if you can see the player
        local nextPos = world.layerObj:getNextMove(self, self.weapon:mapName())
        self:stepTo(nextPos[1], nextPos[2], world)
        
        self.followPath = {} -- you can see the player
    else
        if #self.followPath == 0 then -- if entity has no idea where the player is
            local nextPos = world.layerObj:getNextMove(self, "StickToRoom")
            self:stepTo(nextPos[1], nextPos[2], world)
        else
            self:stepTo(self.followPath[1][1], self.followPath[1][2], world)
            table.remove(self.followPath, 1)
        end
    end

    -- then attack
    local dist = CubeDistance(self.pos[1], self.pos[2], world.player.pos[1], world.player.pos[2])
                        
    local map = world.layerObj.movementMaps[self.weapon:mapName()]

    if dist <= map.targetMax and dist >= map.targetMin then
        self:attack(world, world.player)
    end
end

function Entity:playerMoved(fx, fy, tx, ty, world)
    local lastPos = CastHexRay(self.pos[1], self.pos[2], fx, fy, world)
    local newPos = CastHexRay(self.pos[1], self.pos[2], tx, ty, world)

    print(lastPos, newPos)

    if lastPos and not newPos then
        local map = world.layerObj.movementMaps["Default"]

        self.followPath = map:getPathTowardsPlrFrom(self)
        print(#self.followPath)
    end
end

function Entity:draw(x, y)
    love.graphics.setColor(0, 0, 0)
    love.graphics.polygon("fill",
        x, y + outerRadius/2,
        x + innerRadius/2, y + outerRadius/2 * 0.5,
        x + innerRadius/2, y - outerRadius/2 * 0.5,
        x, y - outerRadius/2,
        x - innerRadius/2, y - outerRadius/2 * 0.5,
        x - innerRadius/2, y + outerRadius/2 * 0.5
    )

    love.graphics.setLineWidth(0.5)
    
    if self.highlight then
        love.graphics.setColor(1, 1, 0)
        love.graphics.polygon("line",
            x, y + outerRadius/2,
            x + innerRadius/2, y + outerRadius/2 * 0.5,
            x + innerRadius/2, y - outerRadius/2 * 0.5,
            x, y - outerRadius/2,
            x - innerRadius/2, y - outerRadius/2 * 0.5,
            x - innerRadius/2, y + outerRadius/2 * 0.5
        )
    end

    self.highlight = false
end

function Entity:stepTo(x, y, world)
    if world.layerObj:isHexFree(x, y) then
        world.layerObj:moveEntityTo(self, x, y)
    end
end

return Entity