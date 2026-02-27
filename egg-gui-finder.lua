-- EGG GUI FINDER SCRIPT
-- Run this in Roblox Studio Command Bar or with your executor
-- Helps find proximity-based egg GUIs and make them always visible

print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("🔍 EGG GUI FINDER & MANIPULATOR")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- SEARCH TEXT (change this to search for different eggs)
local searchText = "Common Egg"  -- Change to your egg name
print("\n🔎 Searching for: '" .. searchText .. "'")

-- ========================================
-- PART 1: SEARCH ALL GUI TEXT ELEMENTS
-- ========================================
print("\n📱 SCANNING PLAYERGUI FOR TEXT...")
local guiMatches = {}

local function searchGuiForText(parent, path)
    for _, child in pairs(parent:GetDescendants()) do
        if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
            local text = child.Text or ""
            if text:lower():find(searchText:lower()) then
                table.insert(guiMatches, {
                    path = child:GetFullName(),
                    text = text,
                    visible = child.Visible,
                    parent = child.Parent.Name
                })
            end
        end
    end
end

searchGuiForText(playerGui, "PlayerGui")

if #guiMatches > 0 then
    print("✅ Found " .. #guiMatches .. " GUI text matches:")
    for i, match in ipairs(guiMatches) do
        print(string.format("  [%d] %s", i, match.path))
        print(string.format("      Text: '%s' | Visible: %s", match.text, tostring(match.visible)))
    end
else
    print("❌ No GUI text matches found in PlayerGui")
end

-- ========================================
-- PART 2: FIND BILLBOARDGUIS IN WORKSPACE
-- ========================================
print("\n🌍 SCANNING WORKSPACE FOR BILLBOARDGUIS...")
local billboardGuis = {}

for _, obj in pairs(game.Workspace:GetDescendants()) do
    if obj:IsA("BillboardGui") or obj:IsA("SurfaceGui") then
        -- Check if it has text matching our search
        local hasMatchingText = false
        local foundText = ""

        for _, child in pairs(obj:GetDescendants()) do
            if child:IsA("TextLabel") or child:IsA("TextButton") then
                local text = child.Text or ""
                if text:lower():find(searchText:lower()) then
                    hasMatchingText = true
                    foundText = text
                    break
                end
            end
        end

        if hasMatchingText then
            table.insert(billboardGuis, {
                instance = obj,
                path = obj:GetFullName(),
                type = obj.ClassName,
                text = foundText,
                maxDistance = obj:IsA("BillboardGui") and obj.MaxDistance or "N/A",
                enabled = obj.Enabled,
                parent = obj.Parent
            })
        end
    end
end

if #billboardGuis > 0 then
    print("✅ Found " .. #billboardGuis .. " proximity GUIs in Workspace:")
    for i, gui in ipairs(billboardGuis) do
        print(string.format("  [%d] %s", i, gui.path))
        print(string.format("      Type: %s | Text: '%s'", gui.type, gui.text))
        print(string.format("      MaxDistance: %s | Enabled: %s", tostring(gui.maxDistance), tostring(gui.enabled)))
        print(string.format("      Parent: %s", gui.parent.Name))
    end
else
    print("❌ No matching BillboardGuis found in Workspace")
end

-- ========================================
-- PART 3: MAKE BILLBOARDGUIS ALWAYS VISIBLE
-- ========================================
print("\n🔧 PROXIMITY GUI MANIPULATION OPTIONS:")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

if #billboardGuis > 0 then
    print("\n💡 To make egg GUIs always visible, run these commands:")
    print("\n-- Option 1: Set MaxDistance to infinity (always visible)")
    for i, gui in ipairs(billboardGuis) do
        if gui.instance:IsA("BillboardGui") then
            local pathParts = {}
            for part in gui.path:gmatch("[^%.]+") do
                table.insert(pathParts, part)
            end
            -- Create a simplified path
            local simplePath = gui.path:gsub("^Workspace%.", "workspace.")
            print(string.format("game:GetService('Workspace')%s.MaxDistance = math.huge", gui.path:gsub("^Workspace", "")))
        end
    end

    print("\n-- Option 2: Keep them enabled even when far")
    for i, gui in ipairs(billboardGuis) do
        local simplePath = gui.path:gsub("^Workspace%.", "workspace.")
        print(string.format("game:GetService('Workspace')%s.Enabled = true", gui.path:gsub("^Workspace", "")))
    end

    print("\n-- Option 3: Find ALL egg BillboardGuis and make visible")
    print([[
for _, obj in pairs(workspace:GetDescendants()) do
    if obj:IsA("BillboardGui") and obj.Parent.Name:find("Egg") then
        obj.MaxDistance = math.huge
        obj.Enabled = true
    end
end
]])
end

-- ========================================
-- PART 4: FIND CURRENT EGG INSTANCE
-- ========================================
print("\n🥚 FINDING EGG INSTANCES IN WORKSPACE...")
local eggInstances = {}

for _, obj in pairs(workspace:GetDescendants()) do
    if obj:IsA("Model") and obj.Name:find("Egg") then
        -- Check if it has a GUI
        local hasGui = false
        for _, child in pairs(obj:GetDescendants()) do
            if child:IsA("BillboardGui") or child:IsA("SurfaceGui") then
                hasGui = true
                break
            end
        end

        if hasGui then
            table.insert(eggInstances, {
                name = obj.Name,
                path = obj:GetFullName(),
                hasGui = hasGui
            })
        end
    end
end

if #eggInstances > 0 then
    print("✅ Found " .. #eggInstances .. " egg models with GUIs:")
    for i, egg in ipairs(eggInstances) do
        print(string.format("  [%d] %s", i, egg.name))
        print(string.format("      Path: %s", egg.path))
    end
else
    print("⚠️ No egg models with GUIs found (may need to be near eggs)")
end

-- ========================================
-- PART 5: AUTO-FIX ALL EGG GUIS
-- ========================================
print("\n🔧 AUTO-FIX FUNCTION:")
print("Copy and run this function to make ALL egg GUIs always visible:")
print([[
-- Run this to make all egg GUIs always visible
local function makeEggGuisAlwaysVisible()
    local count = 0
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BillboardGui") then
            -- Check if parent is an egg or has "Egg" in name
            local isEgg = false
            local parent = obj.Parent
            if parent and (parent.Name:find("Egg") or parent.Parent and parent.Parent.Name:find("Egg")) then
                isEgg = true
            end

            if isEgg then
                obj.MaxDistance = math.huge
                obj.Enabled = true
                obj.AlwaysOnTop = true
                count = count + 1
            end
        end
    end
    print("✅ Made " .. count .. " egg GUIs always visible!")
end

makeEggGuisAlwaysVisible()
]])

-- ========================================
-- PART 6: LIVE MONITORING
-- ========================================
print("\n📡 LIVE MONITORING SCRIPT:")
print("Run this to continuously monitor and fix egg GUI visibility:")
print([[
-- Live monitoring (keeps egg GUIs always visible)
local monitoring = true

task.spawn(function()
    while monitoring do
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("BillboardGui") and obj.Parent and obj.Parent.Name:find("Egg") then
                if obj.MaxDistance ~= math.huge then
                    obj.MaxDistance = math.huge
                    obj.Enabled = true
                    print("🔧 Fixed GUI for: " .. obj.Parent.Name)
                end
            end
        end
        task.wait(1)
    end
end)

print("✅ Egg GUI monitoring started! Set 'monitoring = false' to stop")
]])

print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("✅ SCAN COMPLETE!")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
