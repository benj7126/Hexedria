local Goblin = require("Server/entity"):new()

function Goblin:setDefaults(world)
    self.name = 'Goblin'
    self.speed = 0.9
    self.maxhp = 20
    self.weapon = "Fists"
end

return Goblin