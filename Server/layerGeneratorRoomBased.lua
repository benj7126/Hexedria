local Tile = require "Server/tile"

local function makeGrid(world, size)
    local grid = {}

    for y = -size/2, size/2 do
        for x = -size/2, size/2 do
            if x-y <= size/2 and x-y >= -size/2 then
                if not grid[y] then
                    grid[y] = {}
                end
                
                grid[y][x-y] = Tile:new(world)
            end
        end
    end

    return grid
end

local function genDijkstraGrid(gridBase, size)
    local dijkstraGrid = {}
    local toChange = {}

    for y = -size/2, size/2 do
        for x = -size/2, size/2 do
            if x-y <= size/2 and x-y >= -size/2 then
                if not dijkstraGrid[y] then
                    dijkstraGrid[y] = {}
                end
                
                if type(gridBase[y][x-y]) ~= "number" then
                    if gridBase[y][x-y].wall then
                        dijkstraGrid[y][x-y] = -1
                    else
                        table.insert(toChange, {{y, x-y}, 0})
                        dijkstraGrid[y][x-y] = 0
                    end
                else
                    dijkstraGrid[y][x-y] = gridBase[y][x-y]

                    if dijkstraGrid[y][x-y] == 0 then
                        table.insert(toChange, {{y, x-y}, 0})
                    end
                end
            end
        end
    end

    while #toChange ~= 0 do
        local low = {0, 9^9}
        for i, v in pairs(toChange) do
            if v[2] < low[2] then
                low = {i, v[2]}
            end
        end

        local pos = toChange[low[1]][1]
        local val = toChange[low[1]][2]
        table.remove(toChange, low[1])

        dijkstraGrid[pos[1]][pos[2]] = val

        local t = os.time()

        local mabyNew = GetPositions(pos[1], pos[2])
        for i, v in pairs(mabyNew) do
            if dijkstraGrid[v[1]] then
                if dijkstraGrid[v[1]][v[2]] then
                    if dijkstraGrid[v[1]][v[2]] == -1 then
                        dijkstraGrid[v[1]][v[2]] = -2
                        table.insert(toChange, {v, val+1})
                    end
                end
            end
        end
    end

    return dijkstraGrid
end

local function cloneMap(world, oldGrid, size)
    local grid = {}

    for y = -size/2, size/2 do
        for x = -size/2, size/2 do
            if x-y <= size/2 and x-y >= -size/2 then
                if not grid[y] then
                    grid[y] = {}
                end
                
                grid[y][x-y] = Tile:new(world)

                if oldGrid[y] then
                    if oldGrid[y][x-y] then
                        grid[y][x-y].wall = oldGrid[y][x-y].wall
                    end
                end
            end
        end
    end

    return grid
end

local function tryMakeRoomAtWithSize(grid, pos, radius)
    for vx = -radius, radius do
        for vy = -radius, radius do
            if math.abs(vx+vy) <= radius then
                if grid[pos[1]+vx] then
                    if grid[pos[1]+vx][pos[2]+vy] then
                        grid[pos[1]+vx][pos[2]+vy].wall = false
                    else
                        return false
                    end
                else
                    return false
                end
            end
        end
    end

    return true, grid
end

return function (world, size)
    local grid = makeGrid(world, size)

    local rooms = {{0, 0}}

    local roomPass = {}

    local endRoomSizes = {}
    
    local roomSizes = {4, 5, 7}
    local corridorLenghts = {5, 6, 10, 12}

    local starterRoomRadius = 3
    local starterRoomCenter = {0, 0}
    
    -- make starterRoom...
    tryMakeRoomAtWithSize(grid, starterRoomCenter, starterRoomRadius)

    local didGenRoom = true -- to stop when no more rooms are made

    local retry = 4
    local didRetry = retry

    while didRetry ~= 0 do
        local dijkstraGrid = genDijkstraGrid(grid, size)
        local thisSize = roomSizes[love.math.random(1, #roomSizes)]
        local thisLen = corridorLenghts[love.math.random(1, #corridorLenghts)]
        
        if didRetry == 1 then
            local thisSize = roomSizes[1]
            local thisLen = corridorLenghts[1]
        end

        local nGrid = {}

        local possibleEndLocations = {}

        for y = -size/2, size/2 do
            for x = -size/2, size/2 do
                if x-y <= size/2 and x-y >= -size/2 then
                    if dijkstraGrid[y][x-y] == thisSize*2 + thisLen then
                        table.insert(possibleEndLocations, {y, x-y})
                    end
                end
            end
        end

        local chosenLocation = {0, 0}

        if #possibleEndLocations ~= 0 then
            chosenLocation = possibleEndLocations[love.math.random(1, #possibleEndLocations)]

            local foundLocation = {chosenLocation[1], chosenLocation[2]}
            local val = thisSize*2+thisLen

            for i = 0, thisSize do
                local potentialDowns = GetPositions(foundLocation[1], foundLocation[2])

                local downs = {}

                for i, v in pairs(potentialDowns) do
                    if dijkstraGrid[v[1]] then
                        if dijkstraGrid[v[1]][v[2]] then
                            if dijkstraGrid[v[1]][v[2]] == val-1 then
                                table.insert(downs, v)
                            end
                        end
                    end
                end

                local rNr = love.math.random(1, #downs)

                foundLocation = {downs[rNr][1], downs[rNr][2]}
                val = val - 1
            end

            chosenLocation = foundLocation

            didGenRoom, nGrid = tryMakeRoomAtWithSize(cloneMap(world, grid, size), chosenLocation, thisSize)
        else
            didGenRoom = false
        end

        if didGenRoom then
            table.insert(rooms, chosenLocation)
            table.insert(roomPass, {chosenLocation[1], chosenLocation[2], thisSize})

            grid = nGrid

            -- make walkway
            local curNR = thisSize+thisLen
            local curPosition = {chosenLocation[1], chosenLocation[2]}

            while curNR ~= 0 do
                local positions = GetPositions(curPosition[1], curPosition[2])

                local possiblePositions = {}

                for i, v in pairs(positions) do
                    if dijkstraGrid[v[1]] then
                        if dijkstraGrid[v[1]][v[2]] then
                            if dijkstraGrid[v[1]][v[2]] == curNR-1 then -- or potentially dijkstraGrid[v[1]][v[2]] >= curNR
                                table.insert(possiblePositions, {{v[1], v[2]}, dijkstraGrid[v[1]][v[2]]})
                            end
                        end
                    end
                end

                local chosen = love.math.random(1, #possiblePositions)

                curPosition = {possiblePositions[chosen][1][1], possiblePositions[chosen][1][2]}
                curNR = possiblePositions[chosen][2]

                grid[curPosition[1]][curPosition[2]].wall = false
            end

            didRetry = retry
        else
            didRetry = didRetry - 1
        end
    end

    -- now make every room get at least 1 'pair' room, so 2 rooms that need to be connected (it can be any room)

    -- local roomsNPairs = {}

    -- for i, v in pairs(rooms) do
    --     roomsNPairs[v] = {}

    --     for i = 1, love.math.random(1, 1) do
    --         local rNr = love.math.random(1, #rooms-1)
            
    --         if rNr >= i then
    --             rNr = rNr + 1
    --         end
    
    --         table.insert(roomsNPairs[v], rNr)
    --     end
    -- end

    -- -- make a lot of pathways, lmao
    -- for i, v in pairs(roomsNPairs) do
        
    -- end

    -- instead make a random path

    -- start with new dijkstra map

    local tempBase = {}

    for y = -size/2, size/2 do
        for x = -size/2, size/2 do
            if x-y <= size/2 and x-y >= -size/2 then
                if not tempBase[y] then
                    tempBase[y] = {}
                end
                
                tempBase[y][x-y] = -1
            end
        end
    end

    for i, v in pairs(rooms) do
        tempBase[v[1]][v[2]] = 0
    end

    local pathMap = genDijkstraGrid(tempBase, size)

    for i, roomPos in pairs(rooms) do
        local curLocation = {roomPos[1], roomPos[2]}

        local height = 0
        local walking = 1 -- what way im walking

        for i = 1, love.math.random(1, 1) do
            while not (height == 0 and walking == -1) do
                local moves = GetPositions(curLocation[1], curLocation[2])

                local foundMoves = {}

                for i, v in pairs(moves) do
                    if pathMap[v[1]] then
                        if pathMap[v[1]][v[2]] then
                            if pathMap[v[1]][v[2]] == height+walking then
                                table.insert(foundMoves, v)
                            end
                        end
                    end
                end

                if #foundMoves == 0 then
                    if walking == 1 then
                        walking = -1
                    else
                        height = 0
                    end
                else
                    local chosen = 1
                    
                    -- try 1
                    chosen = love.math.random(1, #foundMoves)

                    -- try 2
                    -- if walking == 1 then
                    --     -- random
                    --     chosen = love.math.random(1, #foundMoves)
                    -- else
                    --     -- make it as long as possible
                    --     local longest = {-1, 1}
                    --     for i, v in pairs(foundMoves) do
                    --         local nDist = CubeDistance(roomPos[1], roomPos[2], v[1], v[2])
                    --         if nDist > longest[1] then
                    --             longest = {nDist, i}
                    --         end
                    --     end
                    -- end
                    
                    -- try 3
                    -- local closest = {99999, 1}
                    -- for i, v in pairs(foundMoves) do
                    --     for i2, roomPos2 in pairs(rooms) do
                    --         if not (roomPos2[1] == roomPos[1] and roomPos2[2] == roomPos[2]) then
                    --             local nDist = CubeDistance(roomPos2[1], roomPos[1], v[1], v[2])
                    --             if nDist < closest[1] then
                    --                 closest = {nDist, i}
                    --             end
                    --         end
                    --     end
                    -- end


                    grid[curLocation[1]][curLocation[2]].wall = false

                    curLocation = {foundMoves[chosen][1], foundMoves[chosen][2]}
                    height = height + walking
                end
            end
        end
    end

    local actualGrid = cloneMap(world, grid, size+2) -- now there are borders

    return actualGrid, roomPass, pathMap
end