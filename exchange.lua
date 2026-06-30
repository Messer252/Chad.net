-- OUTLOOK SERVER (STABLE + SERVER ID ENABLED)

local modem = peripheral.find("modem")
if not modem then error("No modem found") end
rednet.open(peripheral.getName(modem))

math.randomseed(os.epoch("utc"))

--------------------------------------------------
-- SERVER ID
--------------------------------------------------
local SERVER_ID = os.getComputerID()

term.clear()
term.setCursorPos(1,1)

print("=== OUTLOOK SERVER STARTING ===")
print("SERVER ID:", SERVER_ID)

--------------------------------------------------
-- OPTIONAL: SAVE SERVER ID TO FILE
--------------------------------------------------
local function saveServerID()
    local f = fs.open("server_id.txt", "w")
    f.write(tostring(SERVER_ID))
    f.close()
end

saveServerID()

--------------------------------------------------
-- ADMIN LOGIN
--------------------------------------------------
local ADMIN_USER = "admin"
local ADMIN_PASS = "1234"

print("\n=== ADMIN LOGIN ===")
print("Username:")
local u = read()

print("Password:")
local p = read("*")

if u ~= ADMIN_USER or p ~= ADMIN_PASS then
    print("Access denied")
    sleep(2)
    os.shutdown()
end

--------------------------------------------------
-- DATABASE
--------------------------------------------------
local DB_FILE = "mail_db.txt"

local db = {
    users = {},
    sessions = {},
    mail = {}
}

if fs.exists(DB_FILE) then
    local f = fs.open(DB_FILE, "r")
    local data = f.readAll()
    f.close()

    local loaded = textutils.unserialize(data)
    if loaded then db = loaded end
end

local function save()
    local f = fs.open(DB_FILE, "w")
    f.write(textutils.serialize(db))
    f.close()
end

--------------------------------------------------
-- UTIL
--------------------------------------------------
local function hash(str)
    local h = 0
    for i = 1, #str do
        h = (h * 31 + string.byte(str, i)) % 2147483647
    end
    return tostring(h)
end

local function uuid()
    return tostring(os.epoch("utc")) .. tostring(math.random(1000,9999))
end

local function auth(token)
    local s = db.sessions[token]
    if not s then return nil end
    if s.expires < os.epoch("utc") then
        db.sessions[token] = nil
        return nil
    end
    return s.user
end

--------------------------------------------------
-- USER SYSTEM
--------------------------------------------------
local function createUser()
    print("Username:")
    local user = read()

    print("Password:")
    local pass = read("*")

    if db.users[user] then
        print("User already exists")
        return
    end

    db.users[user] = hash(pass)
    db.mail[user] = {inbox={}, sent={}}
    save()

    print("User created: " .. user)
end

--------------------------------------------------
-- MESSAGE HANDLER
--------------------------------------------------
local function handle(id, msg)
    if type(msg) ~= "table" then return end
    if not msg._id then return end

    --------------------------------------------------
    -- LOGIN
    --------------------------------------------------
    if msg.type == "login" then
        local stored = db.users[msg.user]

        if stored and stored == hash(msg.pass) then
            local token = uuid()

            db.sessions[token] = {
                user = msg.user,
                expires = os.epoch("utc") + 600000
            }

            save()

            rednet.send(id, {
                ok = true,
                token = token,
                request = msg._id,
                server = SERVER_ID
            })
        else
            rednet.send(id, {
                ok = false,
                err = "Invalid login",
                request = msg._id,
                server = SERVER_ID
            })
        end

    --------------------------------------------------
    -- SEND MAIL
    --------------------------------------------------
    elseif msg.type == "send" then
        local user = auth(msg.token)
        if not user then
            rednet.send(id, {ok=false, request=msg._id})
            return
        end

        local mail = {
            id = uuid(),
            from = user,
            to = msg.to,
            subject = msg.subject,
            body = msg.body,
            time = os.epoch("utc")
        }

        db.mail[msg.to] = db.mail[msg.to] or {inbox={}, sent={}}

        table.insert(db.mail[msg.to].inbox, mail)
        table.insert(db.mail[user].sent, mail)

        save()

        rednet.send(id, {ok=true, request=msg._id})

    --------------------------------------------------
    -- INBOX
    --------------------------------------------------
    elseif msg.type == "inbox" then
        local user = auth(msg.token)
        if not user then
            rednet.send(id, {ok=false, request=msg._id})
            return
        end

        rednet.send(id, {
            ok = true,
            request = msg._id,
            data = db.mail[user].inbox or {}
        })
    end
end

--------------------------------------------------
-- MAIN LOOP + ADMIN PANEL
--------------------------------------------------
print("\nSERVER ONLINE")

parallel.waitForAny(
    -- NETWORK LOOP
    function()
        while true do
            local id, msg = rednet.receive()
            handle(id, msg)
        end
    end,

    -- ADMIN PANEL
    function()
        while true do
            print("\n[ADMIN]")
            print("1. Create user")
            print("2. List users")
            print("3. Shutdown")

            local c = read()

            if c == "1" then
                createUser()

            elseif c == "2" then
                for k,_ in pairs(db.users) do
                    print("- " .. k)
                end

            elseif c == "3" then
                os.shutdown()
            end
        end
    end
)
