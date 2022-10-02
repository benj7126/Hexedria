local Player = require("Server/entity"):new()

Player.stats = { -- player needs to have vision, but only as a part of the player, and not on the tiles...
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

    if (type(self.stats.extraWeapon) == "string") then
        self.stats.extraWeapon = world:getWeapon(self.stats.extraWeapon):new()
    end
end

function Player:getData() -- online shit
    
end

return Player