local Goblin = require("entity"):new()

function Goblin:setDefaults(world)
    self.name = 'Stone Wielding Goblin'
    self.speed = 0.9
    self.maxhp = 20
    self.weapon = "Stones"
end

return Goblin