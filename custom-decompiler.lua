-- BGSI Ultimate Game Scanner v2026
-- Dumps EVERYTHING to txt files (30min runtime, no limits)
-- Path, content, scripts, players, remotes, everything discoverable

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerScriptService")
local WS = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local output_dir = "GameScan_" .. HttpService:GenerateGUID(false) .. "/"
local scan_log = output_dir .. "scan_log.txt"
local full_dump = output_dir .. "full_dump.txt"

-- Create output folder
makefolder(output_dir)

print("🚀 BGSI Game Scanner Started - Full 30min dump incoming...")
print("📁 Output: " .. output_dir)

local function log(msg)
    writefile(scan_log, readfile(scan_log) .. "[" .. os.date("%H:%M:%S") .. "] " .. msg .. "\n")
    print(msg)
end

local function dump_object(obj, path, depth)
    if not obj or depth > 15 then return end -- Prevent infinite recursion

    local data = {
        path = path,
        class = obj.ClassName,
        name = obj.Name,
        parent = obj.Parent and obj.Parent.Name or "nil",
        children = #obj:GetChildren(),
        properties = {}
    }

    -- Dump key properties
    local props = {"Size", "Position", "CFrame", "Transparency", "BrickColor", "Material", "Anchored",
                   "CanCollide", "Value", "Text", "Source", "Script", "RemoteEvent", "RemoteFunction"}

    for _, prop in ipairs(props) do
        local success, value = pcall(function() return obj[prop] end)
        if success then
            data.properties[prop] = typeof(value)
            if typeof(value) == "string" and #value > 0 and #value < 5000 then
                data.properties[prop .. "_content"] = value:sub(1, 500) .. "..."
            elseif typeof(value) == "Vector3" then
                data.properties[prop] = tostring(value)
            end
        end
    end

    -- SPECIAL: Try to dump script source (executor only)
    if obj.ClassName == "Script" or obj.ClassName == "LocalScript" then
        local success, source = pcall(function() return obj.Source end)
        if success and source then
            data.script_source = #source .. " chars (truncated)"
            -- Save full script if <50k chars
            if #source < 50000 then
                writefile(output_dir .. "script_" .. path:gsub("[^%w]", "_") .. ".lua", source)
                log("💾 SCRIPT DUMPED: " .. path)
            end
        end
    end

    -- Dump RemoteEvents/Functions
    if obj.ClassName == "RemoteEvent" or obj.ClassName == "RemoteFunction" then
        data.remote_name = obj.Name
        log("📡 REMOTE FOUND: " .. path .. " (" .. obj.ClassName .. ")")
    end

    writefile(full_dump, HttpService:JSONEncode(data) .. "\n---\n", Enum.FileMode.Append)
end

local function scan_hierarchy(parent, base_path, depth)
    if depth > 12 then return end
    pcall(function()
        for _, child in pairs(parent:GetChildren()) do
            local path = base_path .. "/" .. child.Name
            dump_object(child, path, depth)
            scan_hierarchy(child, path, depth + 1)
        end
    end)
end

-- MAIN SCAN SECTIONS
local scan_sections = {
    {name = "Workspace", obj = WS, path = "Workspace"},
    {name = "ReplicatedStorage", obj = RS, path = "ReplicatedStorage"},
    {name = "ServerStorage", obj = game:GetService("ServerStorage"), path = "ServerStorage"},
    {name = "Lighting", obj = Lighting, path = "Lighting"},
    {name = "Players", obj = Players, path = "Players"},
    {name = "StarterGui", obj = player:WaitForChild("PlayerGui"), path = "PlayerGui"},
    {name = "Camera", obj = workspace.CurrentCamera, path = "Camera"}
}

-- DYNAMIC SCANS
log("🔍 Starting hierarchy scans...")
for _, section in ipairs(scan_sections) do
    log("📂 Scanning " .. section.name .. " (" .. #section.obj:GetDescendants() .. " objects)")
    scan_hierarchy(section.obj, section.path, 0)
end

-- PLAYER SCAN
log("👥 Scanning all players...")
for _, plr in pairs(Players:GetPlayers()) do
    pcall(function()
        local char = plr.Character
        if char then
            dump_object(char, "Players/" .. plr.Name .. "/Character", 0)
            for _, tool in pairs(char:GetChildren()) do
                if tool:IsA("Tool") then
                    dump_object(tool, "Players/" .. plr.Name .. "/Character/" .. tool.Name, 1)
                end
            end
        end
        dump_object(plr.PlayerGui, "Players/" .. plr.Name .. "/PlayerGui", 1)
        dump_object(plr.Backpack, "Players/" .. plr.Name .. "/Backpack", 1)
    end)
end

-- REMOTE EVENT SCAN (CRITICAL FOR BGSI)
log("📡 Deep RemoteEvent scan...")
for _, obj in pairs(game:GetDescendants()) do
    if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") or obj:IsA("BindableEvent") then
        local path = ""
        local current = obj
        while current do
            path = current.Name .. "/" .. path
            current = current.Parent
        end
        writefile(output_dir .. "remotes.txt", path .. " [" .. obj.ClassName .. "] (" .. #obj:GetChildren() .. " children)\n", Enum.FileMode.Append)
        log("📡 REMOTE: " .. path)
    end
end

-- NETWORK TRAFFIC SNIFFER (15min runtime)
log("🌐 Starting network sniffer (15min)...")
local remote_fires = {}
spawn(function()
    local start_time = tick()
    while tick() - start_time < 900 do -- 15 minutes
        for _, obj in pairs(game:GetDescendants()) do
            if obj:IsA("RemoteEvent") then
                local old_fire = obj.FireServer
                if not remote_fires[obj] then
                    obj.FireServer = function(...)
                        remote_fires[obj] = remote_fires[obj] or {}
                        table.insert(remote_fires[obj], {...})
                        writefile(output_dir .. "remote_calls.txt",
                            "[" .. os.date("%H:%M:%S") .. "] " .. obj:GetFullName() .. " -> " ..
                            HttpService:JSONEncode({...}) .. "\n", Enum.FileMode.Append)
                        return old_fire(...)
                    end
                end
            end
        end
        wait(1)
    end
end)

-- GUI ANALYSIS
log("🎨 GUI Scan...")
for _, gui in pairs(player.PlayerGui:GetDescendants()) do
    if gui:IsA("ScreenGui") or gui:IsA("Frame") or gui:IsA("TextLabel") then
        dump_object(gui, "PlayerGui/" .. gui:GetFullName(), 5)
    end
end

-- PHYSICS/RENDER ANALYSIS
log("⚡ Physics/Render scan...")
for _, obj in pairs(WS:GetDescendants()) do
    if obj:IsA("Part") and obj.Parent ~= WS.CurrentCamera then
        pcall(function()
            local props = {
                Size = tostring(obj.Size),
                Position = tostring(obj.Position),
                Velocity = tostring(obj.Velocity or Vector3.new()),
                AngularVelocity = tostring(obj.AngularVelocity or Vector3.new()),
                Material = tostring(obj.Material),
                CanCollide = tostring(obj.CanCollide)
            }
            writefile(output_dir .. "parts.txt",
                obj:GetFullName() .. ": " .. HttpService:JSONEncode(props) .. "\n",
                Enum.FileMode.Append)
        end)
    end
end

-- FINAL SUMMARY
spawn(function()
    wait(1800) -- 30 minutes total
    local summary = {
        total_objects = #game:GetDescendants(),
        remotes_found = 0,
        scripts_found = 0,
        guis_found = 0
    }

    -- Count everything
    for _, obj in pairs(game:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            summary.remotes_found += 1
        elseif obj:IsA("Script") or obj:IsA("LocalScript") then
            summary.scripts_found += 1
        elseif obj:IsA("ScreenGui") then
            summary.guis_found += 1
        end
    end

    writefile(output_dir .. "SUMMARY.txt", HttpService:JSONEncode(summary, true))
    log("✅ SCAN COMPLETE! Check folder: " .. output_dir)
    log("📊 Summary: " .. summary.total_objects .. " objects, " ..
        summary.remotes_found .. " remotes, " .. summary.scripts_found .. " scripts")
end)

log("⏳ Scanner running... (30min full analysis)")
print("Files generated in: workspace." .. output_dir)
print("💾 Check remotes.txt, scripts/, full_dump.txt for BGSI secrets!")