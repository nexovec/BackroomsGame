local client = {}

local network = require("network")
local enet = require("enet")
local messaging = require("messaging")

local enetclient = nil
client.serverpeer = nil

local connectionFails = 0
local hasConnected = false

function client.beginClient(serverAddress)
    client.serverAddress = serverAddress
    messaging.chatboxMessageHistory:append("Attempting to join the server...")

    -- establish a connection to host on same PC
    enetclient = enet.host_create()
    client.serverpeer = enetclient:connect(client.serverAddress)
    client.serverpeer:timeout(0, 0, 5000)
end

function client.isConnected()
    return client.serverpeer and client.serverpeer:state() == "connected"
end

function client.sendMessage(...)
    local params = {...}
    local message = table.concat(params, ":")
    client.serverpeer:send(message)
end

function client.attemptLogin(username, password)
    -- TODO: Encrypt password
    client.sendMessage("status", "logIn", username .. ":" .. password)
end

-- client.hasPassedCallbacks = false
-- function client.passCallbacks(onLogOut,)
--     client.onLogOut = onLogOut
--     client.hasPassedCallbacks = true
-- end

function client.receivedMessageHandle(hostevent)
    local data = hostevent.data
    local prefix, trimmedMessage = network.getNetworkMessagePrefix(data)
    if prefix == "message" then
        messaging.chatboxMessageHistory:append(trimmedMessage)
    elseif prefix == "status" then
        prefix, trimmedMessage = network.getNetworkMessagePrefix(trimmedMessage)
        if prefix == "logOut" then
            assert(client.onLogOut)
            client.onLogOut(trimmedMessage)
            -- server tells you to disconnect
        elseif prefix == "connected" then
            -- TODO:
            return true
        else
            -- TODO: Don't crash
            error("Enet: message prefix " .. prefix .. " is unhandled!")
        end
    else
        -- TODO: Don't crash
        error(prefix .. ":" .. trimmedMessage)
    end
end

function client.handleEnetClient()
    assert(client.serverAddress)
    local hostevent = enetclient:service()
    if client.serverpeer:state() == "disconnected" then
        connectionFails = connectionFails + 1
        if connectionFails < 6 and hasConnected then
            messaging.chatboxMessageHistory:append("Connection lost. Reconnecting...")
        elseif connectionFails < 2 and not hasConnected then
            -- TODO: Notify user you're waiting for a response from the server
            messaging.chatboxMessageHistory:append("Can't connect to the server.")
        end
        client.serverpeer:reset()
        client.serverpeer = enetclient:connect(client.serverAddress)
        client.serverpeer:timeout(0, 0, math.min(connectionFails, 6) * 5000)
    end
    if not enetclient then
        return
    end
    if not hostevent then
        return
    end
    -- if hostevent.peer == clientpeer then return end

    local type = hostevent.type
    if type == "connect" then
        client.sendMessage("pingpong", "ping!")
        connectionFails = 0
        hasConnected = true
        messaging.chatboxMessageHistory:append("You've connected to the server!")
    end
    if type == "receive" then
        client.receivedMessageHandle(hostevent)
    end
    if type == "disconnected" then
        messaging.chatboxMessageHistory:append("You were disconnected")
        client.serverpeer = enetclient:connect(client.serverAddress)
    end
    -- luacheck: ignore unused hostevent
    hostevent = nil
end

function client.onDisconnect()
    client.serverpeer:disconnect_now()
end

return client
