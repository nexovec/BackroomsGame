-- requires
local profile = require("profile")

local std = require("std")
local json = require("std.json")
local assets = require("assets")
local types = require("std.types")
local map = require("std.map")
local array = require("std.array")
local utf8 = require("utf8")
local macro = require("macro")
local game
local server

-- variables
local timeLastLogged = nil
local deltaTime = 0

local timeLastLoggedFPS = nil
local ticks = 0
local options = {}

local reportedFPS = 0

local currentFrame = 0

function love.load(args)
    -- TODO: Untested platform warnings, compatibility checks
    options.isServer = args[1] == "--server"
    profile.start()

    if options.isServer then
        server = require("server")
        assets.initOnServer()
        if server == nil then
            print("You can't launch as a server because I yeeted the server files, precisely so you can't do this.")
        end
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
    currentFrame = currentFrame + 1
    macro.currentFrame = currentFrame
    ticks = ticks + 1

    if options.isServer then
        server.update(dt)
    else
        targetTPS = assets.get("settings").targetTPS
        if not targetTPS then
            -- TODO: Use macros here
            game.tick(dt)
        else
            msPerTick = 1 / targetTPS
            deltaTime = deltaTime + dt
            while deltaTime >= msPerTick do
                if not not macro.currentlyPlayedMacro then
                    macro.playedMacroDispatchEvents()
                end
                -- shouldRender = true
                game.tick(deltaTime)
                deltaTime = deltaTime - msPerTick
            end
        end
    end

    if assets.get("settings").logging.shouldLogFPS and love.timer.getTime() - timeLastLoggedFPS > 1 then
        reportedFPS = ticks
        ticks = 0
        timeLastLoggedFPS = timeLastLoggedFPS + 1.0
    end
    if (assets.get("settings").logging.shouldPerformanceLog and love.timer.getTime() - timeLastLogged >
        assets.get("settings").logging.performanceLogPeriodInSeconds) then
        print(profile.report(10))
        profile.reset()
        timeLastLogged = love.timer.getTime()
    end
    collectgarbage("step")
    profile.stop()
end

function love.draw()
    -- TODO: Render at display refresh rate
    profile.start()
    game.draw()
    profile.stop()
    if assets.get("settings").logging.shouldLogFPS then
        love.graphics.setFont(assets.get("font"))
        love.graphics.print(reportedFPS)
    end
end

function love.quit()
    if game then
        types.optionalCall(game.quit)
    else
        types.optionalCall(server.quit)
    end
end

function love.keypressed(...)
    if macro.isRecordingMacro then
        macro.addMacroEvent("keypressed", ...)
    end
    game.keypressed(...)
end

function love.textinput(...)
    if macro.isRecordingMacro then
        macro.addMacroEvent("textinput", ...)
    end
    game.textinput(...)
end

function love.mousepressed(...)
    if macro.isRecordingMacro then
        macro.addMacroEvent("mousepressed", ...)
    end
    game.mousepressed(...)
end

function love.mousereleased(...)
    if macro.isRecordingMacro then
        macro.addMacroEvent("mousereleased", ...)
    end
    game.mousereleased(...)
end

function love.mousemoved(...)
    if macro.isRecordingMacro then
        macro.addMacroEvent("mousemoved", ...)
    end
    game.mousemoved(...)
end
