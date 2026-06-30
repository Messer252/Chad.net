local PROTOCOL = "chadnet"

-------------------------------------------------
-- ROBUST MODEM OPEN (FIXED)
-------------------------------------------------
local function openModem()
    local modem = peripheral.find("modem")
    if modem then
        rednet.open(peripheral.getName(modem))
        return true
    end

    for _, side in ipairs(rs.getSides()) do
        if peripheral.getType(side) == "modem" then
            rednet.open(side)
            return true
        end
    end

    return false
end

if not openModem() then
    error("No modem found - cannot start rednet")
end

-------------------------------------------------
-- STATE
-------------------------------------------------
local user, chat, input = "", {}, ""
local status = "CONNECTING..."
local screen = "chat"

-------------------------------------------------
local function send(msg)
    rednet.broadcast(msg, PROTOCOL)
end

-------------------------------------------------
-- LOGIN
-------------------------------------------------
term.clear()
term.setCursorPos(1,1)

print("Chad.Net v6.3")
write("Username: ")
user = read()

send({type="login", user=user})

-------------------------------------------------
-- DRAW (UNCHANGED IDEA)
-------------------------------------------------
local function draw()
    term.clear()
    term.setCursorPos(1,1)

    print("Chad.Net | "..user.." | "..status)
    print("--------------------------------")

    if screen == "chat" then
        for i = math.max(1, #chat - 12), #chat do
            print(chat[i])
        end

    elseif screen == "help" then
        print("HELP MODE (/chat to exit)")

    elseif screen == "users" then
        print("Loading users...")
    end

    print("--------------------------------")
    write("> "..input)

    local _,h = term.getSize()
    term.setCursorPos(1,h)
    term.clearLine()
    term.write("[CHAT][HELP][USERS] "..status)
end

-------------------------------------------------
-- RECEIVE
-------------------------------------------------
local function recv()
    while true do
        local _, msg = rednet.receive(PROTOCOL)

        if type(msg) == "table" then

            if msg.type == "login_ok" then
                status = "ONLINE 🟢"

            elseif msg.type == "pong" then
                status = "ONLINE 🟢"

            elseif msg.type == "chat" then
                table.insert(chat, msg.text)

            elseif msg.type == "system" then
                table.insert(chat, msg.text)

            elseif msg.type == "dm" then
                table.insert(chat, "(DM) "..msg.from..": "..msg.text)

            elseif msg.type == "user_list" then
                table.insert(chat, "Online: "..table.concat(msg.users, ", "))
            end
        end

        draw()
    end
end

-------------------------------------------------
-- INPUT
-------------------------------------------------
local function inputLoop()
    draw()

    while true do
        local e,a = os.pullEvent()

        if e == "char" then
            input = input .. a

        elseif e == "key" then
            if a == keys.backspace then
                input = input:sub(1,-2)

            elseif a == keys.enter then
                local msg = input
                input = ""

                if msg == "/help" then
                    screen = "help"

                elseif msg == "/chat" then
                    screen = "chat"

                elseif msg == "/users" then
                    send({type="user_list"})

                else
                    send({type="chat", text=msg})
                end
            end
        end

        draw()
    end
end

-------------------------------------------------
-- HEARTBEAT
-------------------------------------------------
local function ping()
    while true do
        send({type="ping", user=user})
        sleep(2)
    end
end

parallel.waitForAny(recv, inputLoop, ping)
