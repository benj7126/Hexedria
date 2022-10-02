local enet = require "enet"
local host = enet.host_create("localhost:6789")

local World = require "Server/world"
-- test entity

local outerRadius = 10
local innerRadius = outerRadius * 0.866025404

-- print(innerRadius, outerRadius)
--       8.66025404 , 10

TestWorld = World:new()
TestWorld:setup()

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

while true do
    TestWorld:update(dt)
    
    print("a")
    local event = host:service(100)
    while event do
      if event.type == "receive" then
        print("Got message: ", event.data, event.peer)
        event.peer:send( "pong" )
      elseif event.type == "connect" then
        print(event.peer, "connected.")
      elseif event.type == "disconnect" then
        print(event.peer, "disconnected.")
      end
      event = host:service()
    end
end