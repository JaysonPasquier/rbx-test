-- CHUNK LOADING TEST SCRIPT
-- Tests multiple methods to force all game chunks to load

print("CHUNK LOADING TEST STARTING")
print("Testing multiple methods to load all game areas")
print("")

local Players = game:GetService("Players")
local Workspace = workspace
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local results = {}

print("Services loaded")
print("Player: " .. player.Name)
print("")

-- Helper function to count loaded chunks
local function countLoadedChunks()
    local rendered = Workspace:FindFirstChild("Rendered")
    if not rendered then return 0, {} end

    local count = 0
    local eggs = {}

    for _, folder in pairs(rendered:GetChildren()) do
        if folder.Name == "Chunker" then
            count = count + 1
            for _, child in pairs(folder:GetChildren()) do
                if child:IsA("Model") and child:FindFirstChild("Plate") then
                    table.insert(eggs, child.Name)
                end
            end
        end
    end

    return count, eggs
end

-- Helper function to get all world names
local function getWorlds()
    local worlds = Workspace:FindFirstChild("Worlds")
    if not worlds then return {} end

    local worldNames = {}
    for _, world in pairs(worlds:GetChildren()) do
        table.insert(worldNames, world.Name)
    end
    return worldNames
end

print("== INITIAL STATE ==")
local initialChunks, initialEggs = countLoadedChunks()
print("Loaded chunks: " .. initialChunks)
print("Eggs found: " .. #initialEggs)
if #initialEggs > 0 then
    for _, eggName in pairs(initialEggs) do
        print("  - " .. eggName)
    end
end
print("")

-- Get network remote
local networkRemote = RS.Shared.Framework.Network.Remote.RemoteEvent

-- TEST 1: Disable Workspace Streaming
print("TEST 1: Disabling workspace.StreamingEnabled")
task.spawn(function()
    local success, err = pcall(function()
        local wasEnabled = Workspace.StreamingEnabled
        print("StreamingEnabled is: " .. tostring(wasEnabled))

        if wasEnabled then
            Workspace.StreamingEnabled = false
            print("Set StreamingEnabled = false")
            task.wait(2)

            local chunks, eggs = countLoadedChunks()
            print("Result: " .. chunks .. " chunks, " .. #eggs .. " eggs")
            results["Disable Streaming"] = {success = true, chunks = chunks, eggs = #eggs}
        else
            print("Streaming already disabled")
            results["Disable Streaming"] = {success = false, reason = "Already disabled"}
        end
    end)

    if not success then
        print("Failed: " .. tostring(err))
        results["Disable Streaming"] = {success = false, reason = tostring(err)}
    end
    print("")
end)

task.wait(3)

-- TEST 2: World Teleport Cycling
print("TEST 2: Cycling through all worlds")
task.spawn(function()
    local success, err = pcall(function()
        local worlds = getWorlds()
        print("Found worlds: " .. table.concat(worlds, ", "))

        for i, worldName in pairs(worlds) do
            print("  Teleporting to: " .. worldName)
            networkRemote:FireServer("WorldTeleport", worldName)
            task.wait(1)
        end

        if #worlds > 0 then
            networkRemote:FireServer("WorldTeleport", worlds[1])
            task.wait(1)
        end

        local chunks, eggs = countLoadedChunks()
        print("Result: " .. chunks .. " chunks, " .. #eggs .. " eggs")
        results["World Cycling"] = {success = true, chunks = chunks, eggs = #eggs}
    end)

    if not success then
        print("Failed: " .. tostring(err))
        results["World Cycling"] = {success = false, reason = tostring(err)}
    end
    print("")
end)

task.wait(6)

-- TEST 3: Camera Streaming
print("TEST 3: Moving camera to force chunk loading")
task.spawn(function()
    local success, err = pcall(function()
        local camera = Workspace.CurrentCamera
        local originalCFrame = camera.CFrame
        local originalSubject = camera.CameraSubject

        local positions = {}
        local worlds = Workspace:FindFirstChild("Worlds")
        if worlds then
            for _, world in pairs(worlds:GetChildren()) do
                if world:IsA("Model") then
                    local primary = world.PrimaryPart or world:FindFirstChildWhichIsA("BasePart")
                    if primary then
                        table.insert(positions, primary.Position)
                    end
                end
            end
        end

        print("Found " .. #positions .. " world positions")

        for i, pos in pairs(positions) do
            camera.CameraType = Enum.CameraType.Scriptable
            camera.CFrame = CFrame.new(pos + Vector3.new(0, 500, 0))
            print("  Camera moved to position " .. i)
            task.wait(0.5)
        end

        camera.CameraType = Enum.CameraType.Custom
        camera.CameraSubject = originalSubject

        local chunks, eggs = countLoadedChunks()
        print("Result: " .. chunks .. " chunks, " .. #eggs .. " eggs")
        results["Camera Manipulation"] = {success = true, chunks = chunks, eggs = #eggs}
    end)

    if not success then
        print("Failed: " .. tostring(err))
        results["Camera Manipulation"] = {success = false, reason = tostring(err)}
    end
    print("")
end)

task.wait(5)

-- TEST 4: Request Stream Around
print("TEST 4: Using RequestStreamAroundAsync")
task.spawn(function()
    local success, err = pcall(function()
        if not player.RequestStreamAroundAsync then
            print("RequestStreamAroundAsync not available")
            results["Stream Request"] = {success = false, reason = "API not available"}
            return
        end

        local worlds = Workspace:FindFirstChild("Worlds")
        if worlds then
            for _, world in pairs(worlds:GetChildren()) do
                if world:IsA("Model") then
                    local primary = world.PrimaryPart or world:FindFirstChildWhichIsA("BasePart")
                    if primary then
                        print("  Requesting stream around: " .. world.Name)
                        player:RequestStreamAroundAsync(primary.Position)
                        task.wait(0.5)
                    end
                end
            end
        end

        local chunks, eggs = countLoadedChunks()
        print("Result: " .. chunks .. " chunks, " .. #eggs .. " eggs")
        results["Stream Request"] = {success = true, chunks = chunks, eggs = #eggs}
    end)

    if not success then
        print("Failed: " .. tostring(err))
        results["Stream Request"] = {success = false, reason = tostring(err)}
    end
    print("")
end)

task.wait(4)

-- FINAL RESULTS
print(string.rep("=", 50))
print("FINAL RESULTS")
print("")

local finalChunks, finalEggs = countLoadedChunks()
print("Current state:")
print("  Chunks loaded: " .. finalChunks .. " (was " .. initialChunks .. ")")
print("  Eggs found: " .. #finalEggs .. " (was " .. #initialEggs .. ")")
print("")
print("Eggs currently loaded:")
if #finalEggs > 0 then
    for _, eggName in pairs(finalEggs) do
        print("  * " .. eggName)
    end
else
    print("  No eggs loaded")
end
print("")

print("Method Performance:")
print("")
for method, result in pairs(results) do
    if result.success then
        print("SUCCESS: " .. method)
        print("   Chunks: " .. (result.chunks or 0))
        print("   Eggs: " .. (result.eggs or 0))
    else
        print("FAILED: " .. method)
        print("   Reason: " .. (result.reason or "Unknown"))
    end
    print("")
end

-- Recommend best method
local bestMethod = nil
local bestScore = 0
for method, result in pairs(results) do
    if result.success then
        local score = (result.chunks or 0) + (result.eggs or 0) * 10
        if score > bestScore then
            bestScore = score
            bestMethod = method
        end
    end
end

if bestMethod then
    print("RECOMMENDED METHOD: " .. bestMethod)
else
    print("No methods succeeded - chunks may be loaded by proximity only")
end

print("")
print(string.rep("=", 50))
print("TEST COMPLETE")
