local json = require("json")

local loveOverrides = {}


function loveOverrides.init()
    function love.decodeJsonFile(filepath)
        local dataJson = love.filesystem.newFileData(filepath):getString()
        return json.decode(dataJson)
    end
    love.ddd = love.ddd or {}
    love.ddd.constants = love.decodeJsonFile("data/constants.json")
    love.ddd.settings = love.decodeJsonFile("data/settings.json")
    love.ddd.animations = love.decodeJsonFile("data/animations.json")
end
return loveOverrides