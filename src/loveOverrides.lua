function love.graphics.withShader(shader, func)
    assert(type(func) == "function", "Argument #2 must not be nil.", 2)
    love.graphics.setShader(shader)
    local res = func()
    love.graphics.setShader()
    return res
end