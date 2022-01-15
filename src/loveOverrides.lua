function love.graphics.withShader(shader, func)
    assert(type(func) == "function", "Argument #2 must not be nil.", 2)
    local oldShader = love.graphics.getShader()
    love.graphics.setShader(shader)
    local res = func()
    love.graphics.setShader(oldShader)
    return res
end
function love.graphics.applyShader(canvas, textureShader, uniformsTable, options)
    -- TODO: test
    local oldCanvas = love.graphics.getCanvas()
    love.graphics.setCanvas(canvas)
    love.graphics.withShader(textureShader, function()
        for i, v in pairs(uniformsTable) do
            textureShader:send(i, v)
        end
        if options then
            if options.draw then
                love.graphics.draw(options.draw, options.x, options.y)
            else
                love.graphics.rectangle("fill", options.x, options.y, canvas:getDimensions())
            end
        else
            love.graphics.rectangle("fill", 0, 0, canvas:getDimensions())
        end
    end)
    love.graphics.setCanvas()
    -- FIXME: this breaks the code
    -- love.graphics.setCanvas(oldCanvas)
end
function love.wrapRequirePath(path, moduleNameOrFunc, passCurrentRequirePaths)
    -- TODO: test
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
    elseif isCallable(moduleNameOrFunc) then
        moduleNameOrFunc(path, moduleNameOrFunc, passCurrentRequirePaths)
    end
    love.filesystem.setRequirePath(oldPath)
    return module
end

function love.requireDirectory(pathToDir, localRequires)
    -- TODO: test
    assert(type(pathToDir) == "string" ,nil, nil, nil)
    local requirePaths = localRequires .. ";"
    if localRequires then requirePaths = requirePaths .. love.filesystem.getRequirePath() end
    -- TODO: make sure .init.lua is in requirePath.
    return wrapRequirePath(pathToDir, localRequires)
end
function love.graphics.wrapGraphicsState(func)
    love.graphics.push("all")
    func()
    love.graphics.pop()
end
