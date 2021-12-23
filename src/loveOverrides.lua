local json = require("json")

local loveOverrides = {}


function loveOverrides.loadData()
    function love.decodeJsonFile(filepath)
        local dataJson = love.filesystem.newFileData(filepath):getString()
        assert(dataJson)
        return json.decode(dataJson)
    end
    local constants = love.decodeJsonFile("data/constants.json")
    assert(isureal(constants.targetFPS))

    local settings = love.decodeJsonFile("data/settings.json")
    local animations = love.decodeJsonFile("data/animations.json")

    assert(not media)
    media = {}
    media.constants = constants
    media.settings = settings
    media.animations = animations
end
return loveOverrides