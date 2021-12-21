function table.shallowCopy(a)
    assert(type(a) == "table", "This can only be used on tables")
    local self = {}
    for k,v in pairs(a) do
        self[k] = v
    end
    return self
end

function table.prettyPrint()
    -- TODO:
end

function table.invert(tbl)
    local res = {}
    for k, v in pairs(tbl) do
        if not type(v) == "string" or type(v) == "number" then error("Table contains uninvertable type at index " .. k, 2) end
        res[v] = k
    end
    return res
end
function table.fastInvert(tbl)
    local res = {}
    for k, v in ipairs(tbl) do
        res[v] = k
    end
    return res
end