-- ===================================
-- 🧪 CHUNK LOADING TEST SCRIPT
-- Tests multiple methods to force all game chunks to load
-- ===================================

-- Check if we're in a valid Roblox environment
if not game then
    error("❌ Not running in Roblox environment!")
end

print("🧪 === CHUNK LOADING TEST STARTING ===")
print("Testing multiple methods to load all game areas...\n")

-- Safe service loading
local success, Players = pcall(function() return game:GetService("Players") end)
if not success then error("❌ Failed to get Players service") end

local success2, Workspace = pcall(function() return game:GetService("Workspace") end)
if not success2 then Workspace = workspace end -- Fallback to global

local success3, RS = pcall(function() return game:GetService("ReplicatedStorage") end)
if not success3 then error("❌ Failed to get ReplicatedStorage") end

local success4, RunService = pcall(function() return game:GetService("RunService") end)
if not success4 then error("❌ Failed to get RunService") end

local player = Players.LocalPlayer
if not player then
    error("❌ LocalPlayer not found!")
end

print("✅ Services loaded successfully")
print("Player:", player.Name)
print("")

local results = {}

-- Helper function to count loaded chunks
local function countLoadedChunks()
    local rendered = Workspace:FindFirstChild("Rendered")
    if not rendered then return 0, {} end  -- FIX: Return both values

    local count = 0
    local eggs = {}

    for _, folder in pairs(rendered:GetChildren()) do
        if folder.Name == "Chunker" then
            count = count + 1
            -- Check for eggs in this chunk
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

print("📊 === INITIAL STATE ===")
local initialChunks, initialEggs = countLoadedChunks()
print("Loaded chunks:", initialChunks)
print("Eggs found:", #initialEggs)
if #initialEggs > 0 then
    for _, eggName in pairs(initialEggs) do
        print("  - " .. eggName)
    end
else
    print("  (No eggs currently loaded)")
end
print("")

-- Get network remote for teleporting
local networkRemote = RS:FindFirstChild("Shared")
if networkRemote then
    networkRemote = networkRemote:FindFirstChild("Framework")
    if networkRemote then
        networkRemote = networkRemote:FindFirstChild("Network")
        if networkRemote then
            networkRemote = networkRemote:FindFirstChild("Remote")
            if networkRemote then
                networkRemote = networkRemote:FindFirstChild("RemoteEvent")
            end
        end
    end
end

-- ===================================
-- TEST 1: Disable Workspace Streaming
-- ===================================
print("🧪 TEST 1: Disabling workspace.StreamingEnabled")
task.spawn(function()
    local success, err = pcall(function()
        local wasEnabled = Workspace.StreamingEnabled
        print("Current StreamingEnabled:", wasEnabled)

        if wasEnabled then
            Workspace.StreamingEnabled = false
            print("✅ Set StreamingEnabled = false")
            task.wait(2) -- Wait for chunks to load

            local chunks, eggs = countLoadedChunks()
            print("Result: " .. chunks .. " chunks, " .. #eggs .. " eggs")
            results["Disable Streaming"] = {success = true, chunks = chunks, eggs = #eggs}
        else
            print("⚠️ Streaming already disabled")
            results["Disable Streaming"] = {success = false, reason = "Already disabled"}
        end
    end)

    if not success then
        print("❌ Failed:", err)
        results["Disable Streaming"] = {success = false, reason = tostring(err)}
    end
    print("")
end)

task.wait(3)

-- ===================================
-- TEST 2: World Teleport Cycling
-- ===================================
print("🧪 TEST 2: Cycling through all worlds")
task.spawn(function()
    if not networkRemote then
        print("❌ Network remote not found")
        results["World Cycling"] = {success = false, reason = "No remote"}
        return
    end

    local success, err = pcall(function()
        local worlds = getWorlds()
        print("Found worlds:", table.concat(worlds, ", "))

        local originalPos = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if originalPos then
            originalPos = originalPos.CFrame
        end

        -- Visit each world
        for i, worldName in pairs(worlds) do
            print("  Teleporting to:", worldName)
            networkRemote:FireServer("WorldTeleport", worldName)
            task.wait(1) -- Wait for chunks to load
        end

        -- Return to first world
        if #worlds > 0 then
            networkRemote:FireServer("WorldTeleport", worlds[1])
            task.wait(1)
        end

        local chunks, eggs = countLoadedChunks()
        print("Result: " .. chunks .. " chunks, " .. #eggs .. " eggs")
        results["World Cycling"] = {success = true, chunks = chunks, eggs = #eggs}
    end)

    if not success then
        print("❌ Failed:", err)
        results["World Cycling"] = {success = false, reason = tostring(err)}
    end
    print("")
end)

task.wait(6)

-- ===================================
-- TEST 3: Camera Streaming Manipulation
-- ===================================
print("🧪 TEST 3: Moving camera to force chunk loading")
task.spawn(function()
    local success, err = pcall(function()
        local camera = Workspace.CurrentCamera
        local originalCFrame = camera.CFrame
        local originalSubject = camera.CameraSubject

        print("Original camera position:", tostring(originalCFrame.Position))

        -- Get all world positions
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

        -- Move camera to each position
        for i, pos in pairs(positions) do
            camera.CameraType = Enum.CameraType.Scriptable
            camera.CFrame = CFrame.new(pos + Vector3.new(0, 500, 0)) -- High above each world
            print("  Camera moved to position " .. i)
            RunService.RenderStepped:Wait()
            task.wait(0.5)
        end

        -- Restore camera
        camera.CameraType = Enum.CameraType.Custom
        camera.CameraSubject = originalSubject

        local chunks, eggs = countLoadedChunks()
        print("Result: " .. chunks .. " chunks, " .. #eggs .. " eggs")
        results["Camera Manipulation"] = {success = true, chunks = chunks, eggs = #eggs}
    end)

    if not success then
        print("❌ Failed:", err)
        results["Camera Manipulation"] = {success = false, reason = tostring(err)}
    end
    print("")
end)

task.wait(5)

-- ===================================
-- TEST 4: Request Model Streaming
-- ===================================
print("🧪 TEST 4: Using RequestStreamAroundAsync")
task.spawn(function()
    local success, err = pcall(function()
        if not player:RequestStreamAroundAsync then
            print("⚠️ RequestStreamAroundAsync not available")
            results["Stream Request"] = {success = false, reason = "API not available"}
            return
        end

        local worlds = Workspace:FindFirstChild("Worlds")
        if worlds then
            for _, world in pairs(worlds:GetChildren()) do
                if world:IsA("Model") then
                    local primary = world.PrimaryPart or world:FindFirstChildWhichIsA("BasePart")
                    if primary then
                        print("  Requesting stream around:", world.Name)
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
        print("❌ Failed:", err)
        results["Stream Request"] = {success = false, reason = tostring(err)}
    end
    print("")
end)

task.wait(4)

-- ===================================
-- FINAL RESULTS
-- ===================================
print("=" .. string.rep("=", 60))
print("📊 === FINAL RESULTS ===\n")

local finalChunks, finalEggs = countLoadedChunks()
print("Current state:")
print("  Chunks loaded: " .. finalChunks .. " (was " .. initialChunks .. ")")
print("  Eggs found: " .. #finalEggs .. " (was " .. #initialEggs .. ")")
print("\nEggs currently loaded:")
if #finalEggs > 0 then
    for _, eggName in pairs(finalEggs) do
        print("  ✅ " .. eggName)
    end
else
    print("  (No eggs loaded)")
end
print("")

print("Method Performance:\n")
for method, result in pairs(results) do
    if result.success then
        print("✅ " .. method)
        print("   Chunks: " .. (result.chunks or 0))
        print("   Eggs: " .. (result.eggs or 0))
    else
        print("❌ " .. method)
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
    print("🏆 RECOMMENDED METHOD: " .. bestMethod)
else
    print("⚠️ No methods succeeded - chunks may be loaded by proximity only")
end

print("\n" .. string.rep("=", 60))
print("✅ TEST COMPLETE")
