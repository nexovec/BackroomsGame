love.utils = {}
function love.utils.printTable(a)
    assert(type(a) == "table", "Parameter is not a table, but a " .. type(a))
    local function inner(aa)
        print("{")
        local elemCount = 0
        for k,v in pairs(aa) do
            elemCount = elemCount + 1
            if type(v) == "table" then
                inner(v)
            else
                print(k..": "..v)
            end
        end
        if elemCount == 0 then
            print("This table is empty")
        end
        print("}")
    end
    inner(a)
end


function love.utils.shallowCopy(a)
    assert(type(a) == "table", "This can only be used on tables")
    local self = {}
    for k,v in pairs(a) do
        self[k] = v
    end
    return self
end