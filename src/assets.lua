local json = require("json")

local assets = {}
local function decodeJsonFile(filepath)
    local dataJson = love.filesystem.newFileData(filepath):getString()
    assert(dataJson)
    return json.decode(dataJson)
end
local constants = decodeJsonFile("data/constants.json")
assert(isureal(constants.targetFPS))

local settings = decodeJsonFile("data/settings.json")
local animations = decodeJsonFile("data/animations.json")
assets.constants = constants
assets.settings = settings
assets.animations = animations
return assets