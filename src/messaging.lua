local messaging = {}

local array = require("std.array")

messaging.devConsoleMessageHistory = array.wrap()
messaging.chatboxMessageHistory = array.wrap()

function messaging.chatboxMessage(message)
    -- TODO:
end

function messaging.logboxMessage(message)
    -- TODO:
end

return messaging
