
function isint(num)
    if type(num) ~= "number" then return false end
    if math.floor(num) ~= num then return false end
    return true
end

function isureal(num)
    if type(num) ~= "number" then return false end
    if num<=0 then return false end
    return true
end

function checked(var, typeName, errorLevel, errHandle)
    errorLevel = errorLevel or 1
    assert(errorLevel >= 0)
    assert(type(typeName) == "string")
    if type(var) == typeName then
        return var
    else
        if errHandle then
            error("Not yet implemented.")
        else
            if errorLevel == 0 then error("Unexpected variable of type " .. type(var) .. ", " .. typeName .. " expected.", 1 + errorLevel) end
        end
    end
end