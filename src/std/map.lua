local map = {}
function map.new()
    local self = {}
    setmetatable(self, map)
    return self
end
map.__index = map
setmetatable(map, map)
return map