-- requires
local profile = require("profile")

local std = require("std")
local json = require("std.json")
local assets = require("assets")
local types = require("std.types")
local map = require("std.map")
local game
local server

-- variables
local timeLastLogged = nil
local delta = 0

local timeLastLoggedFPS = nil
local ticks = 0
local options = {}

local reportedFPS = 0

-- TODO: Move macro handling to a separate file
local currentFrame = 0
local currentMacroName
local currentMacro
local isRecordingMacro
local recordedMacroes = map.wrap()

local function addMacroEvent(type, contents)
    currentMacro[tostring(love.timer.getTime())] = {
        frame = currentFrame,
        mType = type,
        contents = contents
    }
end

function startRecordingPlayerInputs(macroName)
    if currentMacro then
        return false
    end
    currentMacro = currentMacro or map.wrap()
    currentMacroName = macroName
    isRecordingMacro = true
    return true
end

function pauseRecordingPlayerInputs()
    if not currentMacro then
        return false
    end
    isRecordingMacro = not isRecordingMacro
    return true
end

function stopRecordingPlayerInputs()
    local currentMacroName = currentMacroName or ("macro " .. tostring(#recordedMacroes + 1))
    recordedMacroes[#currentMacroName + 1] = currentMacro
    -- print(json.encode(currentMacro))
    currentMacro = nil
    local temp = currentMacroName
    currentMacroName = nil
    isRecordingMacro = false
    return "Macro stored as " .. temp
end

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

deltaTime = 0

function love.update(dt)
    profile.start()
    currentFrame = currentFrame + 1
    ticks = ticks + 1

    if options.isServer then
        server.update(dt)
    else
        targetTPS = assets.get("settings").targetTPS
        if not targetTPS then
            game.tick(dt)
        else
            msPerTick = 1 / targetTPS
            deltaTime = deltaTime + dt
            if deltaTime >= msPerTick then
                -- shouldRender = true
                game.tick(deltaTime)
                deltaTime = 0
            end
        end
    end

    if assets.get("settings").logging.shouldLogFPS and love.timer.getTime() - timeLastLoggedFPS > 1 then
        -- print(ticks .. "\t:\t" .. collectgarbage("count"))
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
    -- TODO: Serialize recorded macroes
    local fileName = assets.get("settings").macroSaveFile
    local storedMacroes = love.filesystem.read("macro.json")
    if not storedMacroes then
        storedMacroes = "{}"
    end
    local macroes = map.wrap(json.decode(storedMacroes))
    local newMacroFileContents = json.encode(macroes:extend(macroes))
    -- FIXME:
    local s, m = love.filesystem.write(fileName, newMacroFileContents, #newMacroFileContents)
    if not s then
        error(m)
    end
    if game then
        types.optionalCall(game.quit)
    else
        types.optionalCall(server.quit)
    end
end

function love.keypressed(...)
    if isRecordingMacro then
        addMacroEvent("keypressed", ...)
    end
    game.keypressed(...)
end

function love.textinput(...)
    if isRecordingMacro then
        addMacroEvent("textinput", ...)
    end
    game.textinput(...)
end

function love.mousepressed(...)
    if isRecordingMacro then
        addMacroEvent("mousepressed", ...)
    end
    game.mousepressed(...)
end

function love.mousemoved(...)
    if isRecordingMacro then
        addMacroEvent("mousemoved", ...)
    end
    game.mousemoved(...)
end
