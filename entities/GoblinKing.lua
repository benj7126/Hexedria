local Goblin = require("entity"):new()

function Goblin:setDefaults(world)
    self.name = 'King of Goblins'
    self.speed = 0.7
    self.maxhp = 50
    self.weapon = "Fists"
end

return Goblin