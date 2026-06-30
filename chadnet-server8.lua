local PROTOCOL = "chadnet"

-------------------------------------------------
-- OPEN MODEM (ROBUST)
-------------------------------------------------
local modem = peripheral.find("modem")
if modem then
    rednet.open(peripheral.getName(modem))
else
    error("No modem found")
end

-------------------------------------------------
-- STATE (FIXED)
-------------------------------------------------
local clients = {}  -- id -> {name, lastSeen}

-------------------------------------------------
local function send(id, msg)
    rednet.send(id, msg, PROTOCOL)
end

local function broadcast(msg)
    rednet.broadcast(msg, PROTOCOL)
end

-------------------------------------------------
local function getOnlineUsers()
    local list = {}

    for id, data in pairs(clients) do
        table.insert(list, data.name)
    end

    return list
end

-------------------------------------------------
-- MAIN LOOP
-------------------------------------------------
while true do
    local id, msg = rednet.receive(PROTOCOL)
    if type(msg) ~= "table" then goto continue end

    -------------------------------------------------
    -- LOGIN
    -------------------------------------------------
    if msg.type == "login" then
        clients[id] = {
            name = msg.user,
            lastSeen = os.clock()
        }

        send(id, {type="login_ok"})
        broadcast({type="system", text=msg.user.." joined Chad.Net"})
    end

    -------------------------------------------------
    -- PING (HEARTBEAT)
    -------------------------------------------------
    if msg.type == "ping" then
        if clients[id] then
            clients[id].lastSeen = os.clock()
        end

        send(id, {type="pong"})
    end

    -------------------------------------------------
    -- CHAT
    -------------------------------------------------
    if msg.type == "chat" then
        local u = clients[id]
        if u then
            broadcast({type="chat", text="["..u.name.."]: "..msg.text})
        end
    end

    -------------------------------------------------
    -- USERS (LIVE STATUS)
    -------------------------------------------------
    if msg.type == "user_list" then
        send(id, {
            type = "user_list",
            users = getOnlineUsers()
        })
    end

    -------------------------------------------------
    -- DM (FIXED SAFE LOOP)
    -------------------------------------------------
    if msg.type == "dm" then
        local from = clients[id] and clients[id].name
        if not from then goto continue end

        for cid, data in pairs(clients) do
            if data.name == msg.to or cid == id then
                send(cid, {
                    type="dm",
                    from=from,
                    text=msg.text
                })
            end
        end
    end

    -------------------------------------------------
    -- TIMEOUT CLEANUP (REAL OFFLINE DETECTION)
    -------------------------------------------------
    for cid, data in pairs(clients) do
        if os.clock() - data.lastSeen > 10 then
            broadcast({type="system", text=data.name.." disconnected"})
            clients[cid] = nil
        end
    end

    ::continue::
end
