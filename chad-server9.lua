-- =====================================
-- Chad.Net SERVER v6.3 (STABLE FIX)
-- =====================================

local PROTOCOL = "chadnet"

-------------------------------------------------
-- SAFE MODEM BOOT (NO CRASHES)
-------------------------------------------------
local modem = peripheral.find("modem")

if not modem then
    print("❌ ERROR: No modem found!")
    print("Attach a modem or Ender Modem and restart.")
    return
end

local modemName = peripheral.getName(modem)

local ok, err = pcall(rednet.open, modemName)

if not ok then
    print("❌ Failed to open rednet:")
    print(err)
    return
end

print("✅ Chad.Net Server Online")
print("Modem:", modemName)

-------------------------------------------------
-- STATE
-------------------------------------------------
local clients = {}   -- id -> {name, lastSeen}

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

    for _, data in pairs(clients) do
        table.insert(list, data.name)
    end

    return list
end

-------------------------------------------------
-- SERVER LOOP
-------------------------------------------------
while true do
    local id, msg = rednet.receive(PROTOCOL)

    if type(msg) == "table" then

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
        -- HEARTBEAT
        -------------------------------------------------
        if msg.type == "ping" then
            if clients[id] then
                clients[id].lastSeen = os.clock()
                send(id, {type="pong"})
            end
        end

        -------------------------------------------------
        -- CHAT
        -------------------------------------------------
        if msg.type == "chat" then
            local u = clients[id]
            if u then
                broadcast({
                    type="chat",
                    text="["..u.name.."]: "..msg.text
                })
            end
        end

        -------------------------------------------------
        -- USER LIST
        -------------------------------------------------
        if msg.type == "user_list" then
            send(id, {
                type="user_list",
                users=getOnlineUsers()
            })
        end

        -------------------------------------------------
        -- CLEANUP OFFLINE CLIENTS
        -------------------------------------------------
        for cid, data in pairs(clients) do
            if os.clock() - data.lastSeen > 12 then
                broadcast({
                    type="system",
                    text=data.name.." disconnected"
                })
                clients[cid] = nil
            end
        end
    end
end
