local assert = require("std.assert")
local json = require("std.json")
local lua = require("std.luaOverrides")

-- API

function love.decodeJsonFile(filepath)
    local dataJson = love.filesystem.newFileData(filepath):getString()
    assert(dataJson)
    return json.decode(dataJson)
end

function YOLO()
    print("YOLO!!!!")
end

-- function love.graphics.printWrapped(msg, x, y, maxWidth)
--     -- PERFORMANCE: reallocates for every character, EXTREMELY SLOW!
--     if not maxWidth then
--         return love.graphics.print(msg, x, y)
--     end
--     local font = love.graphics.getFont()
--     if font:getWidth(msg) < maxWidth then
--         return love.graphics.print(msg, x, y)
--     end
--     local textWidth = font:getWidth(msg)
--     local elevation = 0
--     local rowString = ""
--     for k, v in utf8.codes(msg) do
--         local char = utf8.char(v)
--         local newRowString = rowString .. char
--         -- TODO: Investigate if each character can be measured independently
--         if font:getWidth(newRowString) > maxWidth then
--             love.graphics.print(rowString, x, y + elevation)
--             elevation = elevation + font:getHeight(rowString)
--             rowString = char
--         else
--             rowString = newRowString
--         end
--     end
--     love.graphics.print(rowString, x, y + elevation)
-- end
if love.graphics then
    function love.graphics.withShader(shader, func)
        assert(type(func) == "function", "Argument #2 must not be nil.", 2)
        local oldShader = love.graphics.getShader()
        love.graphics.setShader(shader)
        local res = func()
        love.graphics.setShader(oldShader)
        return res
    end

    function love.graphics.wrapGraphicsState(func)
        love.graphics.push("all")
        func()
        love.graphics.pop()
    end
end

if love.filesystem then
    function love.wrapRequirePath(path, moduleNameOrFunc, passCurrentRequirePaths)
        -- TODO: Test
        assert(type(path) == "string" and (type(moduleNameOrFunc) == "string" or type(moduleNameOrFunc) == "function"),
            "Unexpected moduleNameOrFunc argument type", 2, nil)
        local module
        local oldPath = love.filesystem.getRequirePath()
        if not passCurrentRequirePaths then
            love.filesystem.setRequirePath(path)
        else
            love.filesystem.setRequirePath(oldPath .. path)
        end
        if type(moduleNameOrFunc) == "string" then
            module = require(moduleNameOrFunc)
        elseif lua.isCallable(moduleNameOrFunc) then
            moduleNameOrFunc(path, moduleNameOrFunc, passCurrentRequirePaths)
        end
        love.filesystem.setRequirePath(oldPath)
        return module
    end

    -- function love.requireDirectory(pathToDir, localRequires)
    --     -- TODO: Test
    --     assert(type(pathToDir) == "string", nil, nil, nil)
    --     local requirePaths = localRequires .. ";"
    --     if localRequires then
    --         requirePaths = requirePaths .. love.filesystem.getRequirePath()
    --     end
    --     -- TODO: Make sure .init.lua is in requirePath.
    --     return love.wrapRequirePath(pathToDir, localRequires)
    -- end
end
