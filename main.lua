local World = require "world"
-- test entity

local updateTimer = 0
W, H = love.graphics.getWidth(), love.graphics.getHeight()

local outerRadius = 10
local innerRadius = outerRadius * 0.866025404

-- print(innerRadius, outerRadius)
--       8.66025404 , 10

function love.load()
    TestWorld = World:new()
    TestWorld:loadWeapons()
    TestWorld:initiatePlayer()
    TestWorld:nextLayer()
    
    love.graphics.setFont(love.graphics.newFont("LEMONMILK-Regular.otf", 12))
end

function love.draw()
    love.graphics.setBackgroundColor(0.1, 0.1, 0.1)
    TestWorld:draw()
end

function love.update(dt)
    TestWorld:update(dt)
end

function love.mousepressed(x, y, b)
    TestWorld:mousepressed(x, y, b)
end

function love.mousereleased(x, y, b)
    TestWorld:mousereleased(x, y, b)
end

function love.wheelmoved( x, y )
    TestWorld:wheelmoved(x, y)
end

local function round(x)
    return math.floor(x+0.5)
end

local function axial_to_cube(x, y)
    return x, y, -x-y
end

function CubeDistance(fx, fy, tx, ty)
    local a = {axial_to_cube(fx, fy)}
    local b = {axial_to_cube(tx, ty)}
    return (math.abs(a[1] - b[1]) + math.abs(a[2] - b[2]) + math.abs(a[3] - b[3])) / 2
end

local function cube_round(q, r, s)
    local Rq = round(q)+0.0
    local Rr = round(r)+0.0
    local Rs = round(s)+0.0

    local q_diff = math.abs(Rq - q)
    local r_diff = math.abs(Rr - r)
    local s_diff = math.abs(Rs - s)

    if q_diff > r_diff and q_diff > s_diff then
        Rq = -Rr-Rs
    elseif r_diff > s_diff then
        Rr = -Rq-Rs
    else 
        Rs = -Rq-Rr
    end

    return Rq, Rr
end

function GenerateGridClone(layer)
    local map = {}

    local size = layer.size

    for x = -size/2, size/2 do
        if layer.grid[x] then
            map[x] = {}
            for y = -size/2, size/2 do
                if layer.grid[x][y] then
                    map[x][y] = 0
                end
            end
        end
    end

    return map
end

local colors = {
    {0.15294117647058825,0.14901960784313725,0.2627450980392157},
    {1,1,1},
    {0.8901960784313725,0.9647058823529412,0.9607843137254902},
    {0.7294117647058823,0.9098039215686274,0.9098039215686274},
    {0.17254901960784313,0.4117647058823529,0.5529411764705883},
}

function SetColor(colorIndex)
    love.graphics.setColor(colors[colorIndex])
end

function ScreenToHexRound(x, y)
    y = y/(outerRadius*1.5)
    x = x/(innerRadius*2)-y*0.5

    x, y = cube_round(axial_to_cube(x, y))

    return x, y
end

function ScreenToHex(x, y)
    return (x + y * 0.5)*innerRadius*2, y*outerRadius*1.5
end

function HexToScreen(x, y)
    return ((x + y * 0.5)*innerRadius*2)*-1, (y*outerRadius*1.5)*-1
end

function GetPositions(x, y)
    return {
        {x, y-1}, {x+1, y-1},
        {x-1, y}, {x+1, y},
        {x-1, y+1}, {x, y+1}
    }
end

function PosListContainsPos(list, pos)
    for i, v in pairs(list) do
        if v[1] == pos[1] and v[2] == pos[2] then
            return true
        end
    end
end

function HexDist(fx, fy, tx, ty)
    local x1, y1 = (fx + fy * 0.5)*innerRadius*2, fy*outerRadius*1.5
    local x2, y2 = (tx + ty * 0.5)*innerRadius*2, ty*outerRadius*1.5
    
    return math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
end

function CastHexRay(fx, fy, tx, ty, world)
    if fx==tx and fy==ty then
        return true
    end

    local n = CubeDistance(fx, fy, tx, ty)

    local x1, y1 = (fx + fy * 0.5)*innerRadius*2, fy*outerRadius*1.5
    local x2, y2 = (tx + ty * 0.5)*innerRadius*2, ty*outerRadius*1.5

    local dist = math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)

    local vec = {(x2-x1)/dist, (y2-y1)/dist}
    local flipVec = {(vec[2]*-1)/1000, (vec[1])/1000}

    for i = 0, dist, dist/n do
        local nx1, ny1 = ScreenToHexRound(x1+vec[1]*i+flipVec[1], y1+vec[2]*i+flipVec[2])
        local nx2, ny2 = ScreenToHexRound(x1+vec[1]*i-flipVec[1], y1+vec[2]*i-flipVec[2])

        if world.layerObj:isHexWall(nx1, ny1) and world.layerObj:isHexWall(nx2, ny2) and i~=dist then
            return false
        end
    end

    return true
end

--[[
for world gen:
    start at center, and go outwards
    make rooms, and make rooms, like a tree
    and stuff
]]--

-- hide, set all currently visible tiles to 0 and minus towards black spaces (only if the player is close)