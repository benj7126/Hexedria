local Player = require("entity"):new()

Player.stats = {
    vision = 4,
    hpRegen = 10,
    mpRegen = 10,

    extraWeapon = "Fists",
    move = true,
}

function Player:AI(world)
    self.stats.move = true
    return false
end

function Player:setDefaults(world)
    self.name = 'You'
    self.speed = 1
    self.maxhp = 100

    self.weapon = "Fists" -- Stones

    if (type(self.stats.extraWeapon) == "string") then
        self.stats.extraWeapon = world:getWeapon(self.stats.extraWeapon):new()
    end
end

function Player:displayWindow(x, y) -- well... dont think i will need this
end

function Player:displayWindowPLR(x, y) -- topleft
    love.graphics.setLineWidth(5)

    -- SetColor(2)
    -- love.graphics.rectangle("fill", x, y, 300, 115)
    -- SetColor(1)
    -- love.graphics.rectangle("line", x, y, 300, 115)
    
    self:drawStencilRect("fill", x+15, y+15, (300-30), 35, 17.5, self.maxhp, self.hp, {0, 1, 0})
    love.graphics.setColor(0, 0, 1)
    self:drawStencilRect("fill", x+15, y+65, (300-30), 35, 17.5, self.maxmp, self.mp, {0, 0, 1})

    SetColor(1)
    love.graphics.rectangle("line", x+15, y+15, 300-30, 35, 35/2)
    love.graphics.rectangle("line", x+15, y+65, 300-30, 35, 35/2)
end

function Player:mousepressed(world, x, y, b)
    self:setHighlight(world)

    local x, y = TestWorld:getHex()

    if b == 2 and self.stats.move then
        local takeAction = false


        if world.layerObj.grid[x] then
            if world.layerObj.grid[x][y] then
                takeAction = world.layerObj.grid[x][y]:rightClick(self, x, y)
            end
        end

        if takeAction then
            self.stats.move = false
        end
    end

    if b ~= 1 or self.chronosInstance.time ~= -1 then return end

    if (x == self.pos[1] and y == self.pos[2]) then
        if self.stats.move == true then
            self.stats.move = false
        else
            self.chronosInstance.time = 0
        end

        return
    end

    if world.layerObj.grid[x] then
        if world.layerObj.grid[x][y] then
            -- print(world.layerObj.grid[x][y].highlight, "j")
            if world.layerObj.grid[x][y].highlight == 1 then
                local lastX, lastY = self.pos[1], self.pos[2]
                self:stepTo(x, y, world)
                self.stats.move = false
                world:playerMoved(lastX, lastY, x, y)
            elseif world.layerObj.grid[x][y].highlight == 2 then
                self.chronosInstance.time = 0
                local target = world.layerObj.grid[x][y].entity
                self:attack(world, target)
            end
        end
    end
end

function Player:preDraw(world) -- this draw is not a graphics draw, its a setup for the draw of tiles
    self:setVision(world)
    self:setHighlight(world)
end

function Player:setVision(world) -- this draw is not a graphics draw, its a setup for the draw of tiles
    local px, py = self.pos[1], self.pos[2]
    
    local x, y = self.pos[1], self.pos[2]
    for vx = -self.stats.vision, self.stats.vision do
        for vy = -self.stats.vision, self.stats.vision do
            if math.abs(vx+vy) <= self.stats.vision then
                if world.layerObj.grid[x+vx] then
                    if world.layerObj.grid[x+vx][y+vy] then
                        if CastHexRay(x, y, x+vx, y+vy, world) then
                            world.layerObj.grid[x+vx][y+vy].visibility = 2
                        end
                    end
                end
            end
        end
    end
end

function Player:setHighlight(world) -- this draw is not a graphics draw, its a setup for the draw of tiles
    local px, py = self.pos[1], self.pos[2]

    if self.chronosInstance.time ~= -1 then return end
    
    if self.stats.move then
        local didSetTarget = false

        for i, v in pairs(GetPositions(px, py)) do
            if world.layerObj.grid[v[1]] then
                if world.layerObj.grid[v[1]][v[2]] then
                    if not world.layerObj.grid[v[1]][v[2]]:unPassable() then
                        world.layerObj.grid[v[1]][v[2]].highlight = 1
                        didSetTarget = true
                    end
                end
            end
        end

        if not didSetTarget then
            self.stats.move = false
        end
    else
        local didSetTarget = false

        local size = world.layerObj.size
        for x = -size/2, size/2 do
            for y = -size/2, size/2 do
                if world.layerObj.grid[x][y] then
                    if world.layerObj.grid[x][y].entity then
                        local dist = CubeDistance(x, y, px, py)
                        
                        print(self.weapon.name)
                        local map = world.layerObj.movementMaps[self.weapon:mapName()]

                        print(map.targetMax, map.targetMin)

                        if dist <= map.targetMax and dist >= map.targetMin and dist ~= 0 then
                            if CastHexRay(x, y, px, py, world) then
                                world.layerObj.grid[x][y].highlight = 2
                                didSetTarget = true
                            end
                        end
                    end
                end
            end
        end

        print(didSetTarget, "target")

        if not didSetTarget then
            self.chronosInstance.time = 0
        end
    end
end

return Player