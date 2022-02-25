local macro = {}
local array = require("std.array")

function macro.addMacroEvent(type, contents)
    assert(macro.currentMacro)
    macro.currentMacro:append{
        frame = macro.currentFrame - macro.macroStartFrame,
        timestamp = tostring(love.timer.getTime()),
        mType = type,
        contents = contents
    }
end

function macro.startRecordingPlayerInputs(macroName)
    if macro.currentMacro then
        return false
    end
    macro.macroStartFrame = macro.currentFrame
    macro.currentMacro = array.wrap()
    macro.currentMacroName = macroName
    macro.isRecordingMacro = true
    return true
end

function macro.pauseRecordingPlayerInputs()
    if not macro.currentMacro then
        return false
    end
    macro.isRecordingMacro = not macro.isRecordingMacro
    return true
end

function macro.startPlayingMacro(obj)
    macro.playedMacroStartFrame = macro.currentFrame
    macro.currentlyPlayedMacro = obj
end

function macro.playedMacroDispatchEvents()
    if macro.currentlyPlayedMacro:length() == 0 then
        macro.playedMacroStartFrame = nil
        macro.currentlyPlayedMacro = nil
        return
    end
    for k, v in macro.currentlyPlayedMacro:iter() do
        if v.frame <= macro.currentFrame - macro.playedMacroStartFrame then
            -- FIXME: This is exploitable
            -- TODO: Dispatch multiple during the same tick.
            if type(v.contents) == "table" then
                love.event.push(v.mType, unpack(v.contents))
            else
                love.event.push(v.mType, v.contents)
            end
            table.remove(macro.currentlyPlayedMacro, k)
            return macro.playedMacroDispatchEvents()
        end
    end
end

function macro.stopRecordingPlayerInputs()
    -- TODO: Redirect the save folder
    local success = false
    if macro.isRecordingMacro then
        success = true
    end
    local tempMacro = macro.currentMacro
    macro.macroStartFrame = nil
    macro.currentMacro = nil
    macro.isRecordingMacro = false
    return tempMacro, success
end

return macro
