-- FIXME: THIS IS RIDICULOUS
local oldStringRef = string
local string = {}
function string.__call()
    error("Not yet implemented.")
end
local instance = {}

function instance.poopNumbers()
    print("Poop, poopity poop!")
end

setmetatable(instance, instance)
setmetatable(string, string)
return string