local error = {}
local types = require("std.types")
function error.__call(msg, level)
    error(errMsg, 1 + errLevel)
end
return types.makeType(error)