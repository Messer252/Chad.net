-- ================================
-- Chad.Net CLIENT v9 (STABLE)
-- ================================

local PROTOCOL = "chadnet"

-------------------------------------------------
-- MODEM BOOT (ROBUST)
-------------------------------------------------
local modem = peripheral.find("modem")
if not modem then error("No modem found") end
rednet.open(peripheral.getName(modem))

-------------------------------------------------
-- STATE
-------------------------------------------------
local user = ""
local chat = {}
local input = ""
local online = {}
local status = "BOOTING..."

-------------------------------------------------
-- UI HELPERS
-------------------------------------------------
local function draw()
    term.clear()
    term.setCursorPos(1,1)

    local w,h = term.getSize()
    local right = math.floor(w * 0.7)

    print("CHAD.NET V9")
    print("STATUS: " .. status)
    print("--------------------------------")

    -- chat log
    for i = math.max(1, #chat - (h - 6)), #chat do
        print(chat[i])
    end

    print("--------------------------------")
    write("> " .. input)

    -- online list (right side)
    term.setCursorPos(right, 2)
    print("ONLINE")
    for i,v in ipairs(online) do
        term.setCursorPos(right, 2 + i)
        print(v)
    end
end

-------------------------------------------------
-- NETWORK LOOP
-------------------------------------------------
local function network()
    while true do
        local id, msg = rednet.receive(PROTOCOL)
        if type(msg) ~= "table" then goto continue end

        if msg.type == "login_ok" then
            status = "ONLINE"

        elseif msg.type == "pong" then
            status = "ONLINE"

        elseif msg.type == "chat" then
            table.insert(chat, msg.text)

        elseif msg.type == "system" then
            table.insert(chat, "[SYSTEM] " .. msg.text)

        elseif msg.type == "user_list" then
            online = msg.users

        elseif msg.type == "ttt_invite" then
            table.insert(chat, "[TTT] Invite from " .. msg.from)
        end

        draw()

        ::continue::
    end
end

-------------------------------------------------
-- INPUT LOOP
-------------------------------------------------
local function inputLoop()
    while true do
        local e,a = os.pullEvent()

        if e == "char" then
            input = input .. a

        elseif e == "key" and a == keys.backspace then
            input = input:sub(1,-2)

        elseif e == "key" and a == keys.enter then
            local msg = input
            input = ""

            if msg == "/users" then
                rednet.broadcast({type="user_list"}, PROTOCOL)

            elseif msg:sub(1,5) == "/ttt " then
                rednet.broadcast({
                    type="ttt_challenge",
                    target = msg:sub(6)
                }, PROTOCOL)

            else
                rednet.broadcast({
                    type="chat",
                    text=msg
                }, PROTOCOL)
            end

            draw()
        end
    end
end

-------------------------------------------------
-- HEARTBEAT
-------------------------------------------------
local function ping()
    while true do
        rednet.broadcast({type="ping"}, PROTOCOL)
        sleep(2)
    end
end

-------------------------------------------------
-- BOOT SEQUENCE (IMPORTANT FIX)
-------------------------------------------------
term.clear()
print("Chad.Net V9 starting...")

status = "CONNECTING..."
rednet.broadcast({type="ping"}, PROTOCOL)

draw()

parallel.waitForAny(network, inputLoop, ping)
