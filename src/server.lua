local server = {}

local array = require("std.array")
local timing = require("timing")
local network = require("network")
local assert = require("std.assert")
local assets = require("assets")
local json = require("std.json")
local enet = require("enet")
local map = require("std.map")
require("loveOverrides")

local enetServer
local connectedPeers = array.wrap()
local userSessions = map.wrap()

local credentialsPath = "data/credentials.json"
local credentials

local function beginServer()
    print("Starting the Server...")

    -- establish host for receiving msg
    enetServer = enet.host_create("192.168.0.234:6750")

end

local function onUserLogin(peer, username, password)
    -- print("Peer IP:", peer)
    assert(peer.disconnect)
    -- TODO: Logging of peer activity
    if userSessions[peer] then
        print("Address " .. peer .. " was already logged in.")
        peer:send("status:logOut:Peer is already logged in.")
        return false
    end

    for k, v in pairs(userSessions) do
        if v.username == username then
            print("A peer " .. tostring(peer) .. " requested a login with username " .. tostring(username) .. " already logged in by " .. tostring(k))
            peer:send("status:logOut:User was already logged in.")
            return false
        end
    end
    userSessions[peer] = {
        username = username,
        password = password
    }
    return true
end

local function onUserLogout(peer)
    userSessions[peer] = nil
end

local function registerAccount(creds, peer)
    -- TODO: Load fallback credentials instead of failing here.
    assert(creds.username)
    assert(creds.password)
    local username = creds.username
    local password = creds.password
    credentials:append{
        username = username,
        password = password
    }
    enetServer:broadcast("message: Username " .. tostring(username) .. " was just registered.")
    -- TODO: Ban SERVER as username
    peer = peer or "SERVER"
    print(tostring(peer), "has just registered as", username, "!")
    -- TODO: Save credentials.
    -- love.filesystem.write(credentialsPath, json.encode(credentials))
end

local function attemptLogin(peer, username, password)
    -- TODO: Limit username and password lengths and contents.
    -- TODO: Log IPs and how many accounts logged in with them.
    -- TODO: Log accounts created per IP
    -- TODO: Set high max connection couint in enet.
    -- TODO: Limit number of login retries.
    -- TODO: Don't actually say what the user's done wrong.
    if #username < 3 or #username > 16 then
        -- TODO: Allow only alphabet, _ and numerics in player names
        -- TODO: Use enum for network errors, darn it!
        return peer:send("status:logOut:Username must be 3 to 16 characters long.")
    end
    if #password < 3 or #password > 32 then
        return peer:send("status:logOut:⨻Password must not be retarded.")
    end
    for _, v in ipairs(credentials) do
        if type(v.username) ~= "string" or type(v.password) ~= "string" then
            print("Hey your credentials file is kind of a mess rn.")
            goto continue
        end
        if v.username == username then
            if v.password == password then
                -- logged in
                if onUserLogin(peer, username, password) == false then return false end
                enetServer:broadcast("message: User " .. username .. " just logged in.")
                print(peer, "just logged in as ", username, "!")
                return
            else
                -- wrong password
                peer:send("status:logOut:Wrong password.")
                return false
            end
        end
        ::continue::
    end

    -- register new username
    registerAccount({
        username = username,
        password = password
    }, peer)
    onUserLogin(peer, username, password)
    return true
end

local function receiveEnetHandle(hostevent)
    local data = hostevent.data
    local prefix, trimmedData = network.getNetworkMessagePrefix(data)
    if prefix == "message" then
        -- TODO: Maximum message length
        -- broadcast message to everybody
        local userSession = userSessions[hostevent.peer]
        if not userSession then
            -- error("Invalid user session of peer " .. tostring(hostevent.peer))
            -- TODO: log suspicious number of those
            return hostevent.peer:send("status:logOut:Server restarted. Log in again.")
        end
        local authorName = userSession.username
        if not authorName then
            error("A user tried to write to chat without logging in.")
        end
        local msg = authorName .. ": " .. trimmedData
        print(msg)
        enetServer:broadcast("message:" .. msg)
    elseif prefix == "status" then
        local prefix, trimmedData = network.getNetworkMessagePrefix(trimmedData)
        if prefix == "logIn" then
            attemptLogin(hostevent.peer, network.getNetworkMessagePrefix(trimmedData))
        elseif trimmedData == "ping!" then
            local tempHost = hostevent
            timing.delayCall(function()
                tempHost.peer:send("pingpong:pong!")
            end, 2)
        else
            -- TODO:
        end
    else
        -- TODO: Handle unwanted messages
    end
end

local function isLoggedIn(peer)
    if userSessions[peer] then
        return true
    else
        return false
    end
end

local function onDisconnect(peer)
    if isLoggedIn(peer) then
        onUserLogout(peer)
    end
    print("Address " .. tostring(peer) .. " has disconnected")
    -- TODO: reset username
    connectedPeers[connectedPeers:indexOf(peer)] = nil
end

local function handleDisconnections()
    for k, v in ipairs(connectedPeers) do
        if v:state() == "disconnected" then
            onDisconnect(v)
        end
    end
    connectedPeers = connectedPeers:squashed()
end

function handleEnetServer()
    handleDisconnections()
    if not enetServer then
        error("You're running a different server instance already.")
    end
    local hostevent = enetServer:service()
    if hostevent then
        -- print("Server detected message type: " .. hostevent.type)
        if hostevent.type == "connect" then
            print(hostevent.peer, "connected.")
            connectedPeers:append(hostevent.peer)
            hostevent.peer:timeout(0, 0, 5000)
            -- TODO: Implement max connection count
        end
        if not connectedPeers:contains(hostevent.peer) then
            -- TODO: Log unregistered clients trying to send messages
            print("ERRORRRROOROROOROROROR")
            return
        end
        if hostevent.type == "disconnect" then
            onDisconnect(hostevent.peer)
        end
        if hostevent.type == "receive" then
            receiveEnetHandle(hostevent)
        end
        -- TODO: Unlog timed-out clients
    end
    hostevent = nil
end

function server.load()
    beginServer()
    -- TODO: Server console
    -- TODO: Save credentials when new account registers
    -- TODO: Username blacklist
    -- TODO: Ip blacklist
    local listOfCredentials = array.wrap(decodeJsonFile("data/credentials.json"))
    credentials = array.wrap()
    for k, v in listOfCredentials:iter() do
        registerAccount(v)
    end
    -- DEBUG:
    -- registerAccount({username = "nexovec", password = "heslo"})
end

function server.update(dt)
    assets.update(dt)
    handleEnetServer()
end

function server.draw()
    -- TODO:
end

function server.quit()
    print("Terminating the server")
end

return server
