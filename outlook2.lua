local modem = peripheral.find("modem")
if not modem then error("No modem") end
rednet.open(peripheral.getName(modem))

--------------------------------------------------
-- SERVER ID
--------------------------------------------------
local SERVER_FILE = "server_id.txt"
local SERVER_ID = tonumber(fs.exists(SERVER_FILE) and fs.open(SERVER_FILE,"r").readAll())

if not SERVER_ID then
    print("Enter server ID:")
    SERVER_ID = tonumber(read())
    local f = fs.open(SERVER_FILE,"w")
    f.write(tostring(SERVER_ID))
    f.close()
end

--------------------------------------------------
-- SAFE REQUEST
--------------------------------------------------
local function request(data)
    local id = tostring(os.epoch("utc"))..tostring(math.random(1000,9999))
    data._id = id

    rednet.send(SERVER_ID, data)

    local t = os.startTimer(5)

    while true do
        local e,a,b = os.pullEvent()

        if e == "rednet_message" then
            if a == SERVER_ID and type(b)=="table" and b.request == id then
                return b
            end
        elseif e == "timer" and a == t then
            return {ok=false, err="timeout"}
        end
    end
end

--------------------------------------------------
-- LOGIN
--------------------------------------------------
local token, user

local function login()
    term.clear()
    term.setCursorPos(1,1)

    print("LOGIN")
    local u = read()
    local p = read("*")

    local res = request({type="login", user=u, pass=p})

    if res.ok then
        token = res.token
        user = u
        return true
    end

    print(res.err or "fail")
    sleep(2)
    return false
end

--------------------------------------------------
-- INBOX
--------------------------------------------------
local function inbox()
    local res = request({type="inbox", token=token})

    term.clear()
    term.setCursorPos(1,1)

    if not res.ok then
        print("Inbox failed")
        sleep(2)
        return
    end

    local mail = res.data or {}

    print("INBOX\n")

    if #mail == 0 then
        print("No mail")
        read()
        return
    end

    for i,m in ipairs(mail) do
        print(i..". "..(m.subject or "no subject"))
        print("From:", m.from)
        print("----")
    end

    read()
end

--------------------------------------------------
-- SEND
--------------------------------------------------
local function send()
    term.clear()
    term.setCursorPos(1,1)

    print("TO:")
    local to = read()

    print("SUBJECT:")
    local subject = read()

    print("BODY:")
    local body = read()

    local res = request({
        type="send",
        token=token,
        to=to,
        subject=subject,
        body=body
    })

    print(res.ok and "SENT" or "FAILED")
    sleep(1)
end

--------------------------------------------------
-- UI
--------------------------------------------------
while true do
    if login() then
        while true do
            term.clear()
            term.setCursorPos(1,1)

            print("MAIL -", user)
            print("1 Inbox")
            print("2 Send")
            print("3 Logout")

            local c = read()

            if c=="1" then inbox()
            elseif c=="2" then send()
            elseif c=="3" then break end
        end
    end
end
