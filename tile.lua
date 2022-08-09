local outerRadius = 10
local innerRadius = outerRadius * 0.866025404

local doorOpen = love.graphics.newImage("Door1.png")
local doorClosed = love.graphics.newImage("Door2.png")

local Tile = {}

function Tile:new(world)
    local tile = {}
    
    self.theWorld = world -- needed for time manager n such

    self.entity = nil
    self.wall = true
    self.visibility = 0 -- if 2 (is currently visible, if 1 it has been discovored, if 0 it has not)

    self.explodable = false
    -- can be removed to acces a new room

    self.isTrapDoor = false -- gateway for next layer

    self.doorRot = 0
    self.door = 0
    -- 0 = no door
    -- 1 = open door
    -- 2 = closed door

    self.highlight = 0

    self.color = {0, 0, 0}

    self.onGround = {}

    setmetatable(tile, self)
    self.__index = self

    return tile
end

function Tile:unPassable()
    return self.door == 2 or self.wall
end

local function drawHexagon(x, y) -- for now, will be replaced with an image
    love.graphics.polygon("fill",
        x, y + outerRadius,
        x + innerRadius, y + outerRadius * 0.5,
        x + innerRadius, y - outerRadius * 0.5,
        x, y - outerRadius,
        x - innerRadius, y - outerRadius * 0.5,
        x - innerRadius, y + outerRadius * 0.5
    )
end

function Tile:draw(x, y)
    self.visibility = 2 -- everything visible for testing purposes
    -- local mx, my = TestWorld:getHex()
    local nx, ny = ScreenToHex(x, y)

    -- if mx==x and my==y then
    --     love.graphics.setColor(0, 0, 1)
    -- end

    if self.highlight ~= 0 then
        if self.highlight == 1 then
            love.graphics.setColor(1, 1, 0)
            drawHexagon(nx, ny)
        elseif self.highlight == 2 then
            love.graphics.setColor(1, 0, 1)
            drawHexagon(nx, ny)
            
            if self.entity then
                self.entity:draw(nx, ny)
            end
        end
    else
        if self.visibility == 0 then
            love.graphics.setColor(0.1, 0.1, 0.1)
            drawHexagon(nx, ny)
        elseif self.visibility == 1 then
            love.graphics.setColor(0.4, 0.4, 0.4)
            if self.wall then
                love.graphics.setColor(0.7, 0.4, 0.7)
            end
            drawHexagon(nx, ny)
        elseif self.visibility == 2 then
            love.graphics.setColor(0.9, 0.9, 0.9)
            if self.wall then
                love.graphics.setColor(0.7, 0.4, 0.7)
            end
            drawHexagon(nx, ny)
    
            self.visibility = 1
    
            if self.entity then
                self.entity:draw(nx, ny)
            end
        end
    end

    local scale = (innerRadius*2)/2000

    local r = 0

    if self.doorRot == 1 then
        r = math.pi/3
    elseif self.doorRot == 3 then
        r = math.pi/3*2
    end

    if self.door == 1 then
        love.graphics.draw(doorOpen, nx, ny, r, scale, scale, 1000, 1000)
    elseif self.door == 2 then
        love.graphics.draw(doorClosed, nx, ny, r, scale, scale, 1000, 1000)
    end

    self.highlight = 0
end

function Tile:movedEntity()
    self.entity = nil -- moves to another tile, idk if i will use it, we will see
end

function Tile:leftClicked()
    print("a")
    if self.door ~= 0 then
        self.door = math.abs(self.door-3)
    end
end

return Tile