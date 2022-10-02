local Weapon = require("Server/weapon"):new()

function Weapon:setDefaults()
    self.damage = 2
end

function Weapon:mapName()
    return "CloseRange"
end

return Weapon