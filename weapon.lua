local Weapon = {
    name = "",
    image = nil, 
}

function Weapon:new()
    local weapon = {}

    -- might consider something with a modifier or multiple, maby traits, and such
    -- so maby you can reroll it as well

    weapon.energyCost = 0 -- like mana, i guess...

    weapon.damage = 0
    weapon.weight = 0 -- every 1 weight minuses speed with 1/100, so:
    -- 10 = -0.1 speed 

    setmetatable(weapon, self)
    self.__index = self

    weapon:setDefaults()

    return weapon
end

function Weapon:setDefaults()
    
end

function Weapon:mapName()
    
end

function Weapon:getDamage()
    return self.damage
end

function Weapon:draw(x, y)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", x, y, 32, 32)
end

return Weapon