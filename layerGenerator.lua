local Tile = require "tile"

local randomGenVal = 0.4

local function makeGrid(world, size)
    local grid = {}

    for y = -size/2, size/2 do
        for x = -size/2, size/2 do
            if x-y <= size/2 and x-y >= -size/2 then
                if not grid[y] then
                    grid[y] = {}
                end
                
                grid[y][x-y] = Tile:new(world)

                if love.math.random(0, 100)/100 > randomGenVal then
                    grid[y][x-y].wall = false
                end
            end
        end
    end

    return grid
end

local function getWallsAround(grid, x, y)
    local positions = GetPositions(x, y)

    local walls = 0
    
    for i, v in pairs(positions) do
        if grid[v[1]] then
            if grid[v[1]][v[2]] then
                if grid[v[1]][v[2]].wall then
                    walls = walls + 1
                end
            else
                walls = walls + 1
            end
        else
            walls = walls + 1
        end
    end

    return walls
end

local function getDoorsAround(grid, x, y)
    local positions = GetPositions(x, y)

    local doors = 0
    
    for i, v in pairs(positions) do
        if grid[v[1]] then
            if grid[v[1]][v[2]] then
                if grid[v[1]][v[2]].door ~= 0 then
                    doors = doors + 1
                end
            else
                doors = doors + 1
            end
        else
            doors = doors + 1
        end
    end

    return doors
end

local function smoothMap(grid, size)
    for y = -size/2, size/2 do
        for x = -size/2, size/2 do
            if x-y <= size/2 and x-y >= -size/2 then
                local tx, ty = y, x-y
                local walls = getWallsAround(grid, tx, ty)

                if walls > 3 then
                    grid[tx][ty].wall = true
                elseif walls < 2 then
                    grid[tx][ty].wall = false
                end
            end
        end
    end

    return grid
end

local function doorPatters(x, y)
    return {
        {{x, y-1}, {x, y+1}},
        {{x-1, y}, {x+1, y}},
        {{x-1, y+1}, {x+1, y-1}},
    }
end

local function makeDoors(grid, size)
    for y = -size/2, size/2 do
        for x = -size/2, size/2 do
            if x-y <= size/2 and x-y >= -size/2 then
                local tx, ty = y, x-y

                if not grid[tx][ty].wall then
                    local walls = getWallsAround(grid, tx, ty)

                    if walls == 2 or walls == 3 and getDoorsAround(grid, tx, ty) == 0 then
                        local makeDoor = false
                        local doorRot = 0

                        for i, v in pairs(doorPatters(tx, ty)) do
                            if grid[v[1][1]] and grid[v[2][1]] then
                                if grid[v[1][1]][v[1][2]] and grid[v[2][1]][v[2][2]] then
                                    if grid[v[1][1]][v[1][2]].wall and grid[v[2][1]][v[2][2]].wall then
                                        makeDoor = true
                                        doorRot = i
                                    end
                                end
                            end
                        end

                        if makeDoor then
                            grid[tx][ty].door = 2
                            grid[tx][ty].doorRot = doorRot
                        end
                    end
                end
            end
        end
    end

    return grid
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

return function (world, size)
    local grid = makeGrid(world, size)
    
    smoothMap(grid, size)
    makeDoors(grid, size)
    
    return grid, {}
end