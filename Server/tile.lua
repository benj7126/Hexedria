local outerRadius = 10
local innerRadius = outerRadius * 0.866025404

local Tile = {}

function Tile:new(world)
    local tile = {}
    
    self.theWorld = world -- needed for time manager n such

    self.entity = nil
    self.wall = true
    self.visibility = 0 -- if 2 (is currently visible, if 1 it has been discovored, if 0 it has not)

    self.explodable = false
    -- can be removed to acces a new room

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