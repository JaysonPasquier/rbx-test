-- ============================================================
-- BGSI Universal Dump Script
-- Dumps: workspace hierarchy, ALL scripts with source,
--        ReplicatedStorage tree, PlayerData, and more
-- Execute in your Roblox exploit executor
-- ============================================================

local Players     = game:GetService("Players")
local RS          = game:GetService("ReplicatedStorage")
local WS          = game:GetService("Workspace")
local SSS         = game:GetService("ServerScriptService")
local SS          = game:GetService("StarterGui")
local lighting    = game:GetService("Lighting")
local localPlayer = Players.LocalPlayer

-- ── Output config ───────────────────────────────────────────
local FILENAME_TREE   = "BGSI_Tree_"        .. os.date("%Y%m%d_%H%M%S") .. ".txt"
local FILENAME_SCRIPTS = "BGSI_Scripts_"    .. os.date("%Y%m%d_%H%M%S") .. ".txt"
local FILENAME_PLAYER  = "BGSI_PlayerData_" .. os.date("%Y%m%d_%H%M%S") .. ".json"

-- ── Helpers ─────────────────────────────────────────────────
local function safeToString(v)
    if type(v) == "string" then return v
    elseif type(v) == "number" then return tostring(v)
    elseif type(v) == "boolean" then return tostring(v)
    elseif type(v) == "nil" then return "null"
    elseif typeof then
        local t = typeof(v)
        if t == "Vector3" then return ("Vector3(%g, %g, %g)"):format(v.X, v.Y, v.Z)
        elseif t == "CFrame" then
            local p = v.Position
            return ("CFrame(%g, %g, %g)"):format(p.X, p.Y, p.Z)
        elseif t == "Color3" then
            return ("Color3(%d, %d, %d)"):format(math.floor(v.R*255), math.floor(v.G*255), math.floor(v.B*255))
        else return tostring(v) end
    else return tostring(v) end
end

-- Simple JSON encoder (handles tables, arrays, strings, numbers, bools, nil)
local function jsonEncode(val, indent, seen)
    indent = indent or ""
    seen   = seen   or {}
    local t = type(val)

    if t == "nil"     then return "null"
    elseif t == "boolean" then return tostring(val)
    elseif t == "number"  then
        if val ~= val then return "null"  -- NaN
        elseif val == math.huge or val == -math.huge then return "null"
        else return tostring(val) end
    elseif t == "string" then
        -- Escape special characters
        val = val:gsub('\\', '\\\\')
                 :gsub('"',  '\\"')
                 :gsub('\n', '\\n')
                 :gsub('\r', '\\r')
                 :gsub('\t', '\\t')
        return '"' .. val .. '"'
    elseif t == "table" then
        if seen[val] then return '"[circular]"' end
        seen[val] = true

        local inner = indent .. "    "
        -- Detect if array
        local isArray = true
        local maxN = 0
        for k, _ in pairs(val) do
            if type(k) ~= "number" or k ~= math.floor(k) or k < 1 then
                isArray = false; break
            end
            if k > maxN then maxN = k end
        end
        if isArray and maxN ~= #val then isArray = false end

        local parts = {}
        if isArray then
            for i = 1, #val do
                parts[#parts+1] = inner .. jsonEncode(val[i], inner, seen)
            end
            seen[val] = nil
            if #parts == 0 then return "[]" end
            return "[\n" .. table.concat(parts, ",\n") .. "\n" .. indent .. "]"
        else
            -- Sort keys for stable output
            local keys = {}
            for k in pairs(val) do keys[#keys+1] = k end
            table.sort(keys, function(a, b)
                return tostring(a) < tostring(b)
            end)
            for _, k in ipairs(keys) do
                local v = val[k]
                -- Skip functions and userdata silently
                if type(v) ~= "function" and type(v) ~= "userdata" then
                    parts[#parts+1] = inner .. jsonEncode(tostring(k), inner, seen)
                                   .. ": " .. jsonEncode(v, inner, seen)
                end
            end
            seen[val] = nil
            if #parts == 0 then return "{}" end
            return "{\n" .. table.concat(parts, ",\n") .. "\n" .. indent .. "}"
        end
    else
        return '"[' .. type(val) .. ']"'
    end
end

-- ── 1. Player Data dump ─────────────────────────────────────
local function dumpPlayerData()
    print("[Dump] Dumping PlayerData...")
    local data = {}

    -- LocalData is a ModuleScript — must require() it first, then call :Get()
    local ok, ld = pcall(function()
        local svc = require(RS.Client.Framework.Services.LocalData)
        return svc:Get()
    end)
    if ok and type(ld) == "table" then
        data = ld
    else
        -- Fallback 1: try GetAsync-style (some versions expose .data directly)
        local ok2, ld2 = pcall(function()
            local svc = require(RS.Client.Framework.Services.LocalData)
            return type(svc.data) == "table" and svc.data or svc:GetData()
        end)
        if ok2 and type(ld2) == "table" then
            data = ld2
        else
            -- Fallback 2: try raw PlayerData attribute / leaderstats
            local ok3, ld3 = pcall(function()
                -- Some games store serialized data in a StringValue or attribute
                local attr = localPlayer:GetAttribute("Data")
                if attr then return game:GetService("HttpService"):JSONDecode(attr) end
                -- Try iterating the character for clues
                return { note = "No data source found" }
            end)
            data = (ok3 and type(ld3) == "table") and ld3 or {}
            data._error = "All LocalData strategies failed.  Err1=" .. tostring(ld) .. "  Err2=" .. tostring(ld2)
        end
    end

    -- Add extra live state
    data._dumpMeta = {
        player   = localPlayer.Name,
        userId   = localPlayer.UserId,
        time     = os.time(),
        date     = os.date("%Y-%m-%d %H:%M:%S"),
    }

    local encoded = jsonEncode(data)
    writefile(FILENAME_PLAYER, encoded)
    print("[Dump] PlayerData written to " .. FILENAME_PLAYER)
end

-- ── 2. Hierarchy tree + script sources ──────────────────────
local treeLines   = {}
local scriptLines = {}
local scriptCount = 0
local instanceCount = 0

local function appendTree(line)  treeLines[#treeLines+1]   = line end
local function appendScript(line) scriptLines[#scriptLines+1] = line end

local function getProperties(inst)
    local props = {}
    local classOk, className = pcall(function() return inst.ClassName end)
    if not classOk then return props end

    -- Common properties to read per class
    local readProp = function(name)
        local ok, v = pcall(function() return inst[name] end)
        if ok and v ~= nil then
            props[name] = safeToString(v)
        end
    end

    -- Universal
    readProp("Archivable")

    -- Part / BasePart
    if inst:IsA("BasePart") then
        readProp("Position"); readProp("Size"); readProp("Anchored")
        readProp("Material"); readProp("BrickColor"); readProp("Transparency")
    end

    -- Model
    if inst:IsA("Model") then
        local ok2, pv = pcall(function() return inst.PrimaryPart and inst.PrimaryPart.Name or "nil" end)
        if ok2 then props["PrimaryPart"] = pv end
    end

    -- Script / LocalScript / ModuleScript
    if inst:IsA("LuaSourceContainer") then
        local ok2, src = pcall(function() return decompile and decompile(inst) or inst.Source end)
        if ok2 and src and #src > 0 then
            props["Source"] = "[see scripts file]"
        else
            props["Source"] = "[no source / protected]"
        end
    end

    -- Value objects
    if inst:IsA("ValueBase") then
        readProp("Value")
    end

    -- RemoteEvent / RemoteFunction
    if inst.ClassName == "RemoteEvent" or inst.ClassName == "RemoteFunction" then
        props["IsRemote"] = "true"
    end

    return props
end

local function dumpInstance(inst, depth, parentPath)
    if depth > 50 then return end  -- safety limit

    local ok, name = pcall(function() return inst.Name end)
    if not ok then return end

    local ok2, className = pcall(function() return inst.ClassName end)
    if not ok2 then return end

    instanceCount = instanceCount + 1
    local path  = parentPath .. "." .. name
    local indent = string.rep("  ", depth)

    -- Tree line
    appendTree(indent .. "[" .. className .. "] " .. name .. "  →  " .. path)

    -- Properties
    local props = getProperties(inst)
    for k, v in pairs(props) do
        if k ~= "Source" then
            appendTree(indent .. "  ." .. k .. " = " .. v)
        end
    end

    -- Script source capture (separate file, keeps tree clean)
    if inst:IsA("LuaSourceContainer") then
        local ok3, src = pcall(function()
            return decompile and decompile(inst) or inst.Source
        end)
        if ok3 and src and #src > 0 then
            scriptCount = scriptCount + 1
            appendScript("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            appendScript("📌 [" .. scriptCount .. "] " .. className .. " :: " .. name)
            appendScript("📁 Path : " .. path)
            appendScript("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            appendScript(src)
            appendScript("")
        end
    end

    -- Recurse into children
    local ok4, children = pcall(function() return inst:GetChildren() end)
    if ok4 then
        for _, child in ipairs(children) do
            dumpInstance(child, depth + 1, path)
        end
    end
end

local function dumpService(service, serviceName)
    if not service then return end
    appendTree("")
    appendTree("╔══════════════════════════════════════════════════════════════╗")
    appendTree("║  SERVICE: " .. serviceName)
    appendTree("╚══════════════════════════════════════════════════════════════╝")

    local ok, children = pcall(function() return service:GetChildren() end)
    if not ok then
        appendTree("  [Could not get children: protected service]")
        return
    end

    for _, child in ipairs(children) do
        dumpInstance(child, 1, serviceName)
    end
end

local function dumpHierarchy()
    print("[Dump] Dumping game hierarchy...")

    appendTree("BGSI FULL GAME DUMP")
    appendTree("Player : " .. localPlayer.Name .. " (UserId: " .. localPlayer.UserId .. ")")
    appendTree("Date   : " .. os.date("%Y-%m-%d %H:%M:%S"))
    appendTree("═══════════════════════════════════════════════════════════════")

    -- Dump all accessible services
    dumpService(WS,       "Workspace")
    dumpService(RS,       "ReplicatedStorage")
    dumpService(lighting, "Lighting")

    -- StarterGui (if readable)
    local ok5, sg = pcall(function() return game:GetService("StarterGui") end)
    if ok5 then dumpService(sg, "StarterGui") end

    -- StarterPlayer
    local ok6, sp = pcall(function() return game:GetService("StarterPlayer") end)
    if ok6 then dumpService(sp, "StarterPlayer") end

    -- Players (all current players)
    appendTree("")
    appendTree("╔══════════════════════════════════════════════════════════════╗")
    appendTree("║  SERVICE: Players")
    appendTree("╚══════════════════════════════════════════════════════════════╝")
    local ok7, plrs = pcall(function() return Players:GetChildren() end)
    if ok7 then
        for _, plr in ipairs(plrs) do
            dumpInstance(plr, 1, "Players")
        end
    end

    appendTree("")
    appendTree("═══════════════════════════════════════════════════════════════")
    appendTree("Total instances dumped : " .. instanceCount)
    appendTree("Total scripts captured : " .. scriptCount)

    writefile(FILENAME_TREE, table.concat(treeLines, "\n"))
    print("[Dump] Hierarchy tree written to " .. FILENAME_TREE)

    if scriptCount > 0 then
        writefile(FILENAME_SCRIPTS, table.concat(scriptLines, "\n"))
        print("[Dump] Script sources written to " .. FILENAME_SCRIPTS)
    else
        print("[Dump] No script sources found (all obfuscated/protected)")
    end
end

-- ── 3. Additional RemoteEvent / RemoteFunction index ────────
local function dumpRemotes()
    print("[Dump] Indexing remotes...")
    local remoteLines = {}
    local remoteCount = 0

    local function scanForRemotes(inst, path)
        if depth and depth > 20 then return end
        local ok, children = pcall(function() return inst:GetDescendants() end)
        if not ok then return end
        for _, v in ipairs(children) do
            local ok2, cn = pcall(function() return v.ClassName end)
            if ok2 and (cn == "RemoteEvent" or cn == "RemoteFunction" or cn == "BindableEvent" or cn == "BindableFunction") then
                local ok3, vpath = pcall(function()
                    local parts = {}
                    local cur = v
                    while cur and cur ~= game do
                        table.insert(parts, 1, cur.Name)
                        cur = cur.Parent
                    end
                    return table.concat(parts, ".")
                end)
                remoteCount = remoteCount + 1
                remoteLines[#remoteLines+1] = ("[%s] %s"):format(cn, ok3 and vpath or v.Name)
            end
        end
    end

    scanForRemotes(RS, "ReplicatedStorage")
    scanForRemotes(WS, "Workspace")

    table.sort(remoteLines)
    local REMOTES_FILE = "BGSI_Remotes_" .. os.date("%Y%m%d_%H%M%S") .. ".txt"
    local remoteHeader = {
        "BGSI REMOTE INDEX",
        "Date : " .. os.date("%Y-%m-%d %H:%M:%S"),
        "Total: " .. remoteCount,
        "═══════════════════════════════════════════════════════════════",
        ""
    }
    local fullRemotes = table.concat(remoteHeader, "\n") .. "\n" .. table.concat(remoteLines, "\n")
    writefile(REMOTES_FILE, fullRemotes)
    print("[Dump] Remotes index written to " .. REMOTES_FILE .. "  (" .. remoteCount .. " entries)")
end

-- ── Run everything ───────────────────────────────────────────
print("╔═══════════════════════════════════════════════════════╗")
print("║           BGSI UNIVERSAL DUMP  — STARTING            ║")
print("╚═══════════════════════════════════════════════════════╝")

task.spawn(function()
    -- PlayerData
    pcall(dumpPlayerData)
    task.wait(0.2)

    -- Remotes index
    pcall(dumpRemotes)
    task.wait(0.2)

    -- Full hierarchy + scripts
    pcall(dumpHierarchy)

    print("╔═══════════════════════════════════════════════════════╗")
    print("║              BGSI UNIVERSAL DUMP — DONE              ║")
    print("║  Files written to your executor's workspace folder   ║")
    print("╚═══════════════════════════════════════════════════════╝")
end)
