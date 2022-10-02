local Map = require("Server/maps.BaseRangedMap"):new()

Map.targetMin = 2
Map.targetMax = 3

function Map:getName()
    return "MidRange"
end

return Map