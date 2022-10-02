local Weapon = require("weapon"):new()

function Weapon:setDefaults()
    self.damage = 2
    self.weight = 15
end

function Weapon:mapName()
    return "MidRange"
end

return Weapon