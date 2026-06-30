-- =====================================
-- Chad.Net v6 CLIENT (MENU UI)
-- =====================================

local PROTOCOL = "chadnet"

for _, side in ipairs({"left","right","top","bottom","front","back"}) do
    if peripheral.isPresent(side) and peripheral.getType(side) == "modem" then
        rednet.open(side)
        break
    end
end

local monitor
for _, side in ipairs({"left","right","top","bottom","front","back"}) do
    if peripheral.isPresent(side) and peripheral.getType(side) == "monitor" then
        monitor = peripheral.wrap(side)
        monitor.setTextScale(0.5)
        break
    end
end

if monitor then term.redirect(monitor) end

-------------------------------------------------
-- STATE
-------------------------------------------------
local user
local chat = {}
local input = ""
local status = "Connecting..."

-------------------------------------------------
local function send(msg)
    rednet.broadcast(msg, PROTOCOL)
end

-------------------------------------------------
-- LOGIN
-------------------------------------------------
term.clear()
term.setCursorPos(1,1)

print("Chad.Net v6")
write("Username: ")
user = read()

send({type="login", user=user})

sleep(1)

-------------------------------------------------
-- MENU
-------------------------------------------------
local function menu()
    term.clear()
    print("=== Chad.Net MENU ===")
    print("1) 💬 Chat")
    print("2) 📩 Messages (DM)")
    print("3) 🎮 TicTacToe")
    print("4) ⛏ Bot Monitor")
    print("5) 👥 Online Users")
    print("6) ❌ Exit")
    print("---------------------")
    write("Select: ")
    return read()
end

-------------------------------------------------
-- CHAT
-------------------------------------------------
local function chatMode()
    while true do
        term.clear()
        print("CHAT (type back)")
        print("----------------")

        for i = math.max(1,#chat-12), #chat do
            print(chat[i])
        end

        write("> ")
        local t = read()
        if t == "back" then return end

        send({type="chat", text=t})
    end
end

-------------------------------------------------
-- DM
-------------------------------------------------
local function dmMode()
    term.clear()
    print("Message user:")
    local to = read()

    while true do
        term.clear()
        print("DM "..to.." (back)")
        write("> ")
        local t = read()
        if t == "back" then return end

        send({type="dm", to=to, text=t})
    end
end

-------------------------------------------------
-- TIC TAC TOE
-------------------------------------------------
local function tttMode()
    term.clear()
    print("Opponent:")
    local opp = read()

    send({type="ttt_challenge", target=opp})

    print("Challenge sent!")
    sleep(1)
end

-------------------------------------------------
-- BOT
-------------------------------------------------
local function botMode()
    term.clear()
    print("Bot ID:")
    local id = tonumber(read())

    send({type="bot_query", id=id})
    sleep(1)
    print("Press enter")
    read()
end

-------------------------------------------------
-- USERS
-------------------------------------------------
local function usersMode()
    send({type="user_list"})

    sleep(1)
    print("Press enter")
    read()
end

-------------------------------------------------
-- RECEIVE
-------------------------------------------------
local function recv()
    while true do
        local _, msg = rednet.receive(PROTOCOL)

        if msg.type == "chat" then
            table.insert(chat, msg.text)

        elseif msg.type == "dm" then
            table.insert(chat, "(DM) "..msg.from..": "..msg.text)

        elseif msg.type == "system" then
            table.insert(chat, msg.text)

        elseif msg.type == "bot_info" and msg.data then
            table.insert(chat, textutils.serialize(msg.data))

        elseif msg.type == "user_list" then
            table.insert(chat, "Users: "..table.concat(msg.users, ", "))

        elseif msg.type == "ttt_state" then
            table.insert(chat, "Turn: "..msg.turn)

        elseif msg.type == "ttt_result" then
            table.insert(chat, msg.text)

        elseif msg.type == "login_ok" then
            status = "Online"
        end
    end
end

-------------------------------------------------
-- HEARTBEAT
-------------------------------------------------
local function ping()
    while true do
        send({type="ping"})
        sleep(2)
    end
end

-------------------------------------------------
-- MAIN
-------------------------------------------------
parallel.waitForAny(function()
    while true do
        local c = menu()

        if c == "1" then chatMode()
        elseif c == "2" then dmMode()
        elseif c == "3" then tttMode()
        elseif c == "4" then botMode()
        elseif c == "5" then usersMode()
        elseif c == "6" then os.shutdown()
        end
    end
end, recv, ping)
