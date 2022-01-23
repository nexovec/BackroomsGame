-- requires
local profile = require("profile")

local std = require("std")
local json = require("std.json")
local assets = require("assets")
local types = require("std.types")
local game
local server


-- variables
local timeLastLogged = nil
local delta = 0

local timeLastLoggedFPS = nil
local ticks = 0
local options = {}


function love.load(args)
    -- TODO: Untested platform warnings, compatibility checks
    options.isServer = args[1] == "--server"
    profile.start()

    if options.isServer then
        server = require("server")
        assets.initOnServer()
        if server == nil then print("You can't launch as a server because I yeeted the server files, precisely so you can't do this.") end
        server.load()
    else
        require("loveOverrides")
        game = require("game")
        assets.initOnClient()
        love.graphics.setDefaultFilter("nearest", "nearest")
        -- FIXME: Magic numbers

        -- make fullscreen
        love.window.setVSync(1)
        love.window.requestAttention()
        game.load(options)
    end

    if assets.get("settings").logging.shouldPerformanceLog then
        print(profile.report(10))
    end

    timeLastLoggedFPS = love.timer.getTime()
    profile.reset()
    profile.stop()
    collectgarbage("collect")
    collectgarbage("stop")
    timeLastLogged = love.timer.getTime()
end

function love.update(dt)
    profile.start()
    ticks = ticks + 1

    -- TODO: Update at 60 fps
    if options.isServer then
        server.update(dt)
    else
        game.tick(dt)
    end

    if assets.get("settings").logging.shouldLogFPS and love.timer.getTime() - timeLastLoggedFPS > 1 then
        print(ticks .. "\t:\t" .. collectgarbage("count"))
        ticks = 0
        timeLastLoggedFPS = timeLastLoggedFPS + 1.0
    end
    if (assets.get("settings").logging.shouldPerformanceLog and love.timer.getTime() - timeLastLogged >
    assets.get("settings").logging.performanceLogPeriodInSeconds) then
        print(profile.report(10))
        profile.reset()
        timeLastLogged = love.timer.getTime()
    end
    collectgarbage("collect")
    profile.stop()
end

function love.draw()
    -- TODO: Render at display refresh rate
    profile.start()
    game.draw()
    profile.stop()
end

function love.quit()
    -- TODO: Track unused requires(optionally detect unused things in types.makeType)
    if game then
        types.optionalCall(game.quit)
    else
        types.optionalCall(server.quit)
    end
end