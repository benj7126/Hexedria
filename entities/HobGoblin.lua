local Goblin = require("entity"):new()

function Goblin:setDefaults(world)
    self.name = 'Hob Goblin'
    self.speed = 1.2
    self.maxhp = 30
    self.weapon = "Fists"
end

return Goblin