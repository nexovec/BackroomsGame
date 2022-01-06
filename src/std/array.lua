local array = {}
function table.shallowCopy(a)
    assert(type(a) == "table", "This can only be used on tables")
    local self = {}
    for k,v in pairs(a) do
        self[k] = v
    end
    return self
end
function table.prettyPrint(tbl)
    if not tbl then
        return error('Table is nil!', 2)
    end
    if type(tbl) ~= 'table' then
        error('This is not a table. type: ' .. type(tbl) .. ((" " .. (tbl.type and tbl.type())) or ""), 2)
    end
    print('contents of a table:')
    print('-----------')
    for k, v in pairs(tbl) do
        local strv = tostring(v)
        print(tostring(k) .. string.rep(' ', math.max(50 - #strv, 0)) .. ':\t' .. strv)
    end
    print('-----------')
end

function array.prettyPrint(tbl)
    -- TODO: revise
    table.prettyPrint(tbl)
end

function array.invert(tbl)
    local res = {}
    for k, v in ipairs(tbl) do
        -- if not type(v) == "string" or type(v) == "number" then error("Table contains uninvertable type at index " .. k, 2) end
        res[v] = k
    end
    return res
end

return array