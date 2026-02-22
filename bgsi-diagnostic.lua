-- BGSI Diagnostic & Auto-Export Tool
-- Run this SEPARATELY from the main script to scan game structure
-- Exports everything to a .txt file in your workspace folder

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

print("🔍 === BGSI DIAGNOSTIC TOOL STARTING ===")
print("⏳ Scanning game structure... This will take a few seconds.")

-- Storage for all findings
local report = {}
local function addLine(text)
    table.insert(report, text)
    print(text)
end

addLine("========================================")
addLine("🔍 BGSI GAME DIAGNOSTIC REPORT")
addLine("Generated: " .. os.date("%Y-%m-%d %H:%M:%S"))
addLine("========================================\n")

-- === 1. SCAN REPLICATEDSTORAGE STRUCTURE ===
addLine("\n📦 === REPLICATEDSTORAGE STRUCTURE ===")
pcall(function()
    for _, child in pairs(RS:GetChildren()) do
        addLine("├─ " .. child.Name .. " [" .. child.ClassName .. "]")
        for _, subchild in pairs(child:GetChildren()) do
            addLine("│  ├─ " .. subchild.Name .. " [" .. subchild.ClassName .. "]")
        end
    end
end)

-- === 2. SCAN ALL REMOTES ===
addLine("\n\n📡 === ALL REMOTEEVENTS & REMOTEFUNCTIONS ===")
local remoteCount = 0
pcall(function()
    for _, obj in pairs(RS:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            remoteCount += 1
            addLine(string.format("[%d] %s → %s", remoteCount, obj.ClassName, obj:GetFullName()))
        end
    end
end)
addLine("\nTotal Remotes Found: " .. remoteCount)

-- === 3. BUBBLE/BLOW REMOTES ===
addLine("\n\n🧼 === BUBBLE/BLOW RELATED REMOTES ===")
pcall(function()
    for _, obj in pairs(RS:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local name = obj.Name:lower()
            if name:find("bubble") or name:find("blow") or name:find("click") or name:find("tap") or name:find("pop") then
                addLine("💡 FOUND: " .. obj:GetFullName() .. " [" .. obj.ClassName .. "]")
            end
        end
    end
end)

-- === 4. EGG/HATCH REMOTES ===
addLine("\n\n🥚 === EGG/HATCH RELATED REMOTES ===")
pcall(function()
    for _, obj in pairs(RS:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local name = obj.Name:lower()
            if name:find("egg") or name:find("hatch") or name:find("open") or name:find("purchase") or name:find("buy") then
                addLine("💡 FOUND: " .. obj:GetFullName() .. " [" .. obj.ClassName .. "]")
            end
        end
    end
end)

-- === 5. WORKSPACE STRUCTURE ===
addLine("\n\n🗺️ === WORKSPACE STRUCTURE ===")
pcall(function()
    for _, child in pairs(Workspace:GetChildren()) do
        addLine("├─ " .. child.Name .. " [" .. child.ClassName .. "]")
        if child.Name == "Rendered" then
            addLine("│  📂 RENDERED FOLDER (Important!):")
            for _, renderedChild in pairs(child:GetChildren()) do
                local childCount = #renderedChild:GetChildren()
                addLine("│  ├─ " .. renderedChild.Name .. " [" .. renderedChild.ClassName .. "] (" .. childCount .. " children)")
            end
        end
    end
end)

-- === 6. RIFT SCANNING ===
addLine("\n\n🌀 === RIFT STRUCTURE ===")
pcall(function()
    local rendered = Workspace:FindFirstChild("Rendered")
    if rendered then
        local rifts = rendered:FindFirstChild("Rifts")
        if rifts then
            addLine("✅ Found Rifts folder at: Workspace.Rendered.Rifts")
            addLine("Rifts detected: " .. #rifts:GetChildren())

            for i, rift in pairs(rifts:GetChildren()) do
                if i <= 3 then  -- Only show first 3 for brevity
                    addLine("\n[Rift " .. i .. "] " .. rift.Name)
                    addLine("   Full structure:")
                    for _, child in pairs(rift:GetDescendants()) do
                        local path = child:GetFullName():gsub("Workspace%.Rendered%.Rifts%." .. rift.Name .. "%.", "   ")
                        addLine("   " .. path .. " [" .. child.ClassName .. "]")

                        if child:IsA("TextLabel") then
                            addLine("      └─ Text: \"" .. child.Text .. "\"")
                        end
                    end
                end
            end
        else
            addLine("❌ No Rifts folder found in Workspace.Rendered")
        end
    else
        addLine("❌ No Rendered folder in Workspace")
    end
end)

-- === 7. EGG SCANNING (DETAILED) ===
addLine("\n\n🥚 === EGG STRUCTURE (Chuncker folders) ===")
pcall(function()
    local rendered = Workspace:FindFirstChild("Rendered")
    if rendered then
        addLine("✅ Rendered folder exists")
        addLine("All children in Rendered:")

        local foundEggFolder = false
        for _, child in pairs(rendered:GetChildren()) do
            local childCount = #child:GetChildren()
            addLine("   ├─ " .. child.Name .. " (" .. childCount .. " children)")

            -- Check if this might be an egg folder
            if child.Name:find("Chunk") or child.Name:find("Egg") or childCount > 5 then
                foundEggFolder = true
                addLine("      ⭐ POSSIBLE EGG FOLDER! Contents:")
                for i, egg in pairs(child:GetChildren()) do
                    if i <= 25 then  -- Show first 25 eggs (increased from 10)
                        local hasPlate = egg:FindFirstChild("Plate") and "✅ HAS PLATE" or "❌ NO PLATE"
                        addLine("         • " .. egg.Name .. " [" .. egg.ClassName .. "] " .. hasPlate)

                        -- Show first 3 children of each egg
                        if i <= 5 then
                            for j, part in pairs(egg:GetChildren()) do
                                if j <= 3 then
                                    addLine("            └─ " .. part.Name .. " [" .. part.ClassName .. "]")
                                end
                            end
                        end
                    end
                end

                if childCount > 25 then
                    addLine("         (...and " .. (childCount - 25) .. " more)")
                end
            end
        end

        if not foundEggFolder then
            addLine("\n⚠️ No obvious egg folder found. Try these:")
            addLine("   1. Walk to egg area in-game")
            addLine("   2. Re-run this script")
            addLine("   3. Check if eggs load dynamically by area")
        end
    end
end)

-- === 8. PET DATA ===
addLine("\n\n🐾 === PET DATA ===")
pcall(function()
    local petData = require(RS.Shared.Data.Pets)
    local count = 0
    addLine("✅ Pet data found! Sample pets:")
    for name, data in pairs(petData) do
        if count < 10 then
            local rarity = data.Rarity or "Unknown"
            addLine("   • " .. name .. " - Rarity: " .. rarity)
            count += 1
        end
    end
    addLine("\nTotal pets in data: " .. count)
end)

-- === 9. CODE DATA ===
addLine("\n\n🎁 === CODES DATA ===")
pcall(function()
    local codeData = require(RS.Shared.Data.Codes)
    local count = 0
    addLine("✅ Code data found! Available codes:")
    for code, data in pairs(codeData) do
        count += 1
        addLine("   • " .. code)
    end
    addLine("\nTotal codes: " .. count)
end)

-- === 10. GUI STRUCTURE (for stats) ===
addLine("\n\n🖥️ === PLAYERGUI STRUCTURE (Currency Labels) ===")
pcall(function()
    local screenGui = PlayerGui:FindFirstChild("ScreenGui")
    if screenGui then
        addLine("✅ ScreenGui found")
        local hud = screenGui:FindFirstChild("HUD")
        if hud then
            addLine("   ✅ HUD found")
            local left = hud:FindFirstChild("Left")
            if left then
                addLine("      ✅ Left panel found")
                local currency = left:FindFirstChild("Currency")
                if currency then
                    addLine("         ✅ Currency frame found")
                    addLine("\n         Currency Labels:")

                    for _, currencyItem in pairs(currency:GetChildren()) do
                        addLine("         ├─ " .. currencyItem.Name)
                        local frame = currencyItem:FindFirstChild("Frame")
                        if frame then
                            local label = frame:FindFirstChild("Label")
                            if label and label:IsA("TextLabel") then
                                addLine("         │  └─ Current Value: \"" .. label.Text .. "\"")
                                addLine("         │     Full Path: " .. label:GetFullName())
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- === 11. LEADERSTATS ===
addLine("\n\n📊 === LEADERSTATS ===")
pcall(function()
    local leaderstats = Players.LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        addLine("✅ Leaderstats found:")
        for _, stat in pairs(leaderstats:GetChildren()) do
            if stat:IsA("IntValue") or stat:IsA("NumberValue") then
                addLine("   • " .. stat.Name .. ": " .. tostring(stat.Value))
            end
        end
    else
        addLine("❌ No leaderstats found")
    end
end)

-- === 12. CHEST SCANNING ===
addLine("\n\n📦 === CHEST STRUCTURE ===")
pcall(function()
    local rendered = Workspace:FindFirstChild("Rendered")
    if rendered and rendered:FindFirstChild("Chests") then
        addLine("✅ Found Chests folder")
        local chests = rendered.Chests
        addLine("Total chests: " .. #chests:GetChildren())

        for i, chest in pairs(chests:GetChildren()) do
            addLine("\n[Chest " .. i .. "] " .. chest.Name .. " [" .. chest.ClassName .. "]")
            addLine("   Children:")
            for _, child in pairs(chest:GetChildren()) do
                addLine("      • " .. child.Name .. " [" .. child.ClassName .. "]")
                if child:IsA("ProximityPrompt") then
                    addLine("         └─ ⭐ HAS PROXIMITYPROMPT!")
                end
            end
        end
    else
        addLine("❌ No Chests folder found")
    end
end)

-- === 13. PICKUP SCANNING ===
addLine("\n\n💰 === PICKUP/DROP STRUCTURE ===")
pcall(function()
    local rendered = Workspace:FindFirstChild("Rendered")
    if rendered and rendered:FindFirstChild("Pickups") then
        addLine("✅ Found Pickups folder")
        local pickups = rendered.Pickups
        addLine("Current pickups in folder: " .. #pickups:GetChildren())

        if #pickups:GetChildren() > 0 then
            for i, pickup in pairs(pickups:GetChildren()) do
                if i <= 5 then
                    addLine("   [" .. i .. "] " .. pickup.Name .. " [" .. pickup.ClassName .. "]")
                end
            end
        else
            addLine("   ⚠️ No pickups currently spawned")
            addLine("   Try: Blow bubbles or break objects to spawn pickups")
        end
    else
        addLine("❌ No Pickups folder found")
    end
end)

-- === 14. ADMIN ABUSE EVENT DETECTION ===
addLine("\n\n👑 === ADMIN ABUSE EVENT DETECTION ===")
pcall(function()
    local rendered = Workspace:FindFirstChild("Rendered")
    local foundAdminEvent = false

    if rendered then
        -- Check for Super Egg
        for _, folder in pairs(rendered:GetChildren()) do
            for _, child in pairs(folder:GetChildren()) do
                local name = child.Name:lower()
                if name:find("super") or name:find("admin") then
                    foundAdminEvent = true
                    addLine("🎯 FOUND ADMIN EVENT ITEM: " .. child.Name .. " in " .. folder.Name)
                    addLine("   Full path: " .. child:GetFullName())
                end
            end
        end

        -- Check workspace for Admin-related models
        for _, child in pairs(Workspace:GetChildren()) do
            local name = child.Name:lower()
            if name:find("admin") or name:find("super") then
                foundAdminEvent = true
                addLine("🎯 FOUND: " .. child.Name .. " [" .. child.ClassName .. "]")
                addLine("   Location: " .. child:GetFullName())
            end
        end
    end

    if foundAdminEvent then
        addLine("\n✅ Admin Abuse event MAY be active!")
    else
        addLine("\n❌ Admin Abuse event NOT detected (or not started yet)")
    end
end)

-- === 15. TELEPORTER DETECTION ===
addLine("\n\n🌀 === TELEPORTER/PORTAL DETECTION ===")
pcall(function()
    local rendered = Workspace:FindFirstChild("Rendered")
    if rendered and rendered:FindFirstChild("Teleport") then
        addLine("✅ Found Teleport folder")
        local teleports = rendered.Teleport
        addLine("Active teleporters: " .. #teleports:GetChildren())

        for i, teleporter in pairs(teleports:GetChildren()) do
            addLine("   [" .. i .. "] " .. teleporter.Name)
            for _, part in pairs(teleporter:GetDescendants()) do
                if part:IsA("Part") or part:IsA("MeshPart") then
                    addLine("      • " .. part.Name .. " at " .. tostring(part.Position))
                end
            end
        end
    else
        addLine("⚠️ No active teleporters found")
    end
end)

-- === 16. COMPLETE PET RARITY BREAKDOWN ===
addLine("\n\n🐾 === COMPLETE PET RARITY BREAKDOWN ===")
pcall(function()
    local petData = require(RS.Shared.Data.Pets)
    local rarityCount = {Common=0, Unique=0, Rare=0, Epic=0, Legendary=0, Secret=0, Unknown=0}
    local totalPets = 0

    for name, data in pairs(petData) do
        totalPets = totalPets + 1
        local rarity = data.Rarity or "Unknown"
        rarityCount[rarity] = (rarityCount[rarity] or 0) + 1
    end

    addLine("✅ Total pets in game: " .. totalPets)
    addLine("\nBreakdown by rarity:")
    addLine("   • Common: " .. rarityCount.Common)
    addLine("   • Unique: " .. rarityCount.Unique)
    addLine("   • Rare: " .. rarityCount.Rare)
    addLine("   • Epic: " .. rarityCount.Epic)
    addLine("   • Legendary: " .. rarityCount.Legendary)
    addLine("   • Secret: " .. rarityCount.Secret)
    if rarityCount.Unknown > 0 then
        addLine("   • Unknown: " .. rarityCount.Unknown)
    end

    -- List all Secret pets
    addLine("\n🌟 All SECRET pets:")
    for name, data in pairs(petData) do
        if data.Rarity == "Secret" then
            addLine("   • " .. name)
        end
    end
end)

-- === 17. CODE REWARDS BREAKDOWN ===
addLine("\n\n🎁 === CODE REWARDS BREAKDOWN ===")
pcall(function()
    local codeData = require(RS.Shared.Data.Codes)
    local rewardTypes = {}

    addLine("✅ Analyzing " .. tostring(#codeData) .. " codes...")

    for code, rewards in pairs(codeData) do
        for _, reward in pairs(rewards) do
            local rewardType = reward.Type
            rewardTypes[rewardType] = (rewardTypes[rewardType] or 0) + 1
        end
    end

    addLine("\nReward types given by codes:")
    for rewardType, count in pairs(rewardTypes) do
        addLine("   • " .. rewardType .. ": " .. count .. " rewards")
    end

    -- Show best codes
    addLine("\n💎 Best codes (most rewards):")
    local codeList = {}
    for code, rewards in pairs(codeData) do
        table.insert(codeList, {code = code, count = #rewards})
    end
    table.sort(codeList, function(a, b) return a.count > b.count end)

    for i = 1, math.min(5, #codeList) do
        addLine("   " .. i .. ". \"" .. codeList[i].code .. "\" - " .. codeList[i].count .. " rewards")
    end
end)

-- === 18. PLAYER POSITION & LOCATION ===
addLine("\n\n📍 === PLAYER LOCATION ===")
pcall(function()
    local character = Players.LocalPlayer.Character
    if character then
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            addLine("✅ Current position: " .. tostring(hrp.Position))
            addLine("   CFrame: " .. tostring(hrp.CFrame))
        end
    end
end)

-- === 19. WORLD/STAGE INFORMATION ===
addLine("\n\n🌍 === WORLDS & STAGES ===")
pcall(function()
    local worlds = Workspace:FindFirstChild("Worlds")
    if worlds then
        addLine("✅ Found Worlds folder")
        addLine("Available worlds: " .. #worlds:GetChildren())
        for i, world in pairs(worlds:GetChildren()) do
            addLine("   [" .. i .. "] " .. world.Name)
        end
    end

    local stages = Workspace:FindFirstChild("Stages")
    if stages then
        addLine("\n✅ Found Stages folder")
        addLine("Available stages: " .. #stages:GetChildren())
        for i, stage in pairs(stages:GetChildren()) do
            if i <= 10 then
                addLine("   [" .. i .. "] " .. stage.Name)
            end
        end
        if #stages:GetChildren() > 10 then
            addLine("   (...and " .. (#stages:GetChildren() - 10) .. " more)")
        end
    end
end)

-- === 20. NPC/SHOP LOCATIONS ===
addLine("\n\n🏪 === NPC & SHOP LOCATIONS ===")
pcall(function()
    local npcs = {
        "EventShop", "TravelingMerchant", "DailyPerks", "RebirthMachine",
        "LunarWheelSpin", "GlobalIncentive", "Incentive", "TopIncentive"
    }

    addLine("Scanning for NPCs and shops...")
    for _, npcName in pairs(npcs) do
        local npc = Workspace:FindFirstChild(npcName)
        if npc then
            local pos = npc:IsA("Model") and npc:GetPivot().Position or (npc:IsA("BasePart") and npc.Position or Vector3.new())
            addLine("   ✅ " .. npcName .. " at " .. tostring(pos))
        end
    end
end)

-- === 21. PROXIMITYP ROMPTS ===
addLine("\n\n👆 === ALL PROXIMITYP ROMPTS ===")
pcall(function()
    local prompts = Workspace:GetDescendants()
    local promptCount = 0

    for _, obj in pairs(prompts) do
        if obj:IsA("ProximityPrompt") then
            promptCount = promptCount + 1
            if promptCount <= 20 then
                addLine("   [" .. promptCount .. "] " .. obj:GetFullName())
            end
        end
    end

    if promptCount > 20 then
        addLine("   (...and " .. (promptCount - 20) .. " more)")
    end
    addLine("\nTotal ProximityPrompts: " .. promptCount)
end)

-- === 22. ACTIVE FOLDER ANALYSIS ===
addLine("\n\n⚡ === ACTIVE FOLDER (Dynamic Content) ===")
pcall(function()
    local rendered = Workspace:FindFirstChild("Rendered")
    if rendered then
        local active = rendered:FindFirstChild("Active")
        if active then
            addLine("✅ Found Active folder: " .. #active:GetChildren() .. " items")
            for i, item in pairs(active:GetChildren()) do
                addLine("   [" .. i .. "] " .. item.Name .. " [" .. item.ClassName .. "]")
                if item:IsA("Model") then
                    addLine("      Children: " .. #item:GetChildren())
                    for j, child in pairs(item:GetChildren()) do
                        if j <= 3 then
                            addLine("         • " .. child.Name)
                        end
                    end
                end
            end
        end
    end
end)

-- === 23. COMPLETE ALL RIFTS LIST ===
addLine("\n\n🌌 === COMPLETE RIFT LIST ===")
pcall(function()
    local rendered = Workspace:FindFirstChild("Rendered")
    if rendered then
        local rifts = rendered:FindFirstChild("Rifts")
        if rifts then
            addLine("✅ All rifts currently spawned:")
            for i, rift in pairs(rifts:GetChildren()) do
                addLine("   [" .. i .. "] " .. rift.Name)

                -- Check for egg type
                local hasEggPlatform = rift:FindFirstChild("EggPlatformSpawn")
                local hasChest = rift:FindFirstChild("Chest")
                local hasGift = rift:FindFirstChild("Gift")

                if hasEggPlatform then addLine("      └─ Type: EGG RIFT") end
                if hasChest then addLine("      └─ Type: CHEST RIFT") end
                if hasGift then addLine("      └─ Type: GIFT RIFT") end
            end
        end
    end
end)

-- === 24. MEMORY & PERFORMANCE ===
addLine("\n\n⚙️ === PERFORMANCE INFO ===")
pcall(function()
    local stats = game:GetService("Stats")
    addLine("Memory usage: " .. math.floor(stats:GetTotalMemoryUsageMb()) .. " MB")
    addLine("Ping: " .. math.floor(Players.LocalPlayer:GetNetworkPing() * 1000) .. " ms")
    addLine("FPS: " .. math.floor(1 / game:GetService("RunService").RenderStepped:Wait()))
end)

-- === 25. POWERUP/POTION DATA ===
addLine("\n\n⚡ === POWERUP & POTION DATA ===")
pcall(function()
    -- Check for Powerups
    local powerupSuccess, powerupData = pcall(function()
        return require(RS.Shared.Data.Powerups)
    end)

    if powerupSuccess and powerupData then
        addLine("✅ Found Powerups data module")
        local powerupCount = 0
        for name, data in pairs(powerupData) do
            powerupCount = powerupCount + 1
            if powerupCount <= 15 then
                local duration = data.Duration or "N/A"
                local effect = data.Effect or data.Multiplier or "Unknown"
                addLine("   • " .. name .. " - Effect: " .. tostring(effect) .. " | Duration: " .. tostring(duration))
            end
        end
        if powerupCount > 15 then
            addLine("   (...and " .. (powerupCount - 15) .. " more)")
        end
        addLine("\nTotal powerups: " .. powerupCount)
    else
        addLine("⚠️ No Powerups data module found")
    end

    -- Check for Potions
    local potionSuccess, potionData = pcall(function()
        return require(RS.Shared.Data.Potions)
    end)

    if potionSuccess and potionData then
        addLine("\n✅ Found Potions data module")
        local potionCount = 0
        for name, data in pairs(potionData) do
            potionCount = potionCount + 1
            if potionCount <= 10 then
                addLine("   • " .. name)
            end
        end
        if potionCount > 10 then
            addLine("   (...and " .. (potionCount - 10) .. " more)")
        end
        addLine("\nTotal potions: " .. potionCount)
    end
end)

-- === 26. PLAYER INVENTORY & EQUIPPED PETS ===
addLine("\n\n🎒 === PLAYER INVENTORY & EQUIPPED PETS ===")
pcall(function()
    -- Check backpack
    local backpack = Players.LocalPlayer:FindFirstChild("Backpack")
    if backpack and #backpack:GetChildren() > 0 then
        addLine("✅ Backpack items: " .. #backpack:GetChildren())
        for i, tool in pairs(backpack:GetChildren()) do
            addLine("   • " .. tool.Name)
        end
    else
        addLine("⚠️ No items in backpack")
    end

    -- Check character for equipped tools
    local character = Players.LocalPlayer.Character
    if character then
        local equippedTool = character:FindFirstChildOfClass("Tool")
        if equippedTool then
            addLine("\n✅ Currently equipped: " .. equippedTool.Name)
        end
    end

    -- Try to find pet data in PlayerGui or elsewhere
    pcall(function()
        local petUI = PlayerGui:FindFirstChild("PetEquip") or PlayerGui:FindFirstChild("Pets")
        if petUI then
            addLine("\n✅ Found Pet UI system: " .. petUI.Name)
            addLine("   Scanning for equipped pets...")
            for _, desc in pairs(petUI:GetDescendants()) do
                if desc.Name == "PetName" or desc.Name == "EquippedPet" then
                    if desc:IsA("TextLabel") or desc:IsA("TextBox") then
                        addLine("   • Found: " .. desc.Text)
                    end
                end
            end
        end
    end)
end)

-- === 27. COMPLETE GUI STRUCTURE (All 18 Currencies) ===
addLine("\n\n💰 === COMPLETE GUI STRUCTURE FOR CURRENCIES ===")
pcall(function()
    local hud = PlayerGui:FindFirstChild("ScreenGui")
    if hud then
        hud = hud:FindFirstChild("HUD")
        if hud then
            local left = hud:FindFirstChild("Left")
            if left then
                local currency = left:FindFirstChild("Currency")
                if currency then
                    addLine("✅ Found Currency folder at: PlayerGui.ScreenGui.HUD.Left.Currency")
                    addLine("All currency elements:")

                    for _, currencyFrame in pairs(currency:GetChildren()) do
                        if currencyFrame:IsA("Frame") or currencyFrame:IsA("ImageLabel") then
                            addLine("\n   [" .. currencyFrame.Name .. "]")

                            -- Find the label
                            for _, child in pairs(currencyFrame:GetDescendants()) do
                                if child:IsA("TextLabel") and (child.Name == "Label" or child.Name == "Amount" or child.Name == "Value") then
                                    addLine("      └─ " .. child.Name .. ": \"" .. child.Text .. "\"")
                                    addLine("         Path: " .. child:GetFullName())
                                end
                            end
                        end
                    end

                    addLine("\n✅ Total currency displays found: " .. #currency:GetChildren())
                else
                    addLine("❌ Currency folder not found in HUD.Left")
                end
            end
        end
    end
end)

-- === 28. BADGE SYSTEM ===
addLine("\n\n🏆 === BADGE SYSTEM ===")
pcall(function()
    local BadgeService = game:GetService("BadgeService")

    -- Try to find badge data in RS
    local badgeSuccess, badgeData = pcall(function()
        return require(RS.Shared.Data.Badges)
    end)

    if badgeSuccess and badgeData then
        addLine("✅ Found Badges data module")
        local badgeCount = 0
        for badgeId, info in pairs(badgeData) do
            badgeCount = badgeCount + 1
            if badgeCount <= 10 then
                addLine("   • Badge ID: " .. tostring(badgeId) .. " - " .. tostring(info.Name or "Unknown"))
            end
        end
        if badgeCount > 10 then
            addLine("   (...and " .. (badgeCount - 10) .. " more badges)")
        end
        addLine("\nTotal badges: " .. badgeCount)
    else
        addLine("⚠️ No Badges data module found")
    end
end)

-- === 29. GAMEPASS DETECTION ===
addLine("\n\n💎 === GAMEPASS SYSTEM ===")
pcall(function()
    local gamepassSuccess, gamepassData = pcall(function()
        return require(RS.Shared.Data.Gamepasses)
    end)

    if gamepassSuccess and gamepassData then
        addLine("✅ Found Gamepasses data module")
        for name, id in pairs(gamepassData) do
            addLine("   • " .. name .. " (ID: " .. tostring(id) .. ")")
        end
    else
        addLine("⚠️ No Gamepasses data module found")
    end
end)

-- === 30. LIGHTING & ATMOSPHERE (Event Detection) ===
addLine("\n\n🌤️ === LIGHTING & ATMOSPHERE ===")
pcall(function()
    local Lighting = game:GetService("Lighting")
    addLine("Time of Day: " .. Lighting.TimeOfDay)
    addLine("Brightness: " .. tostring(Lighting.Brightness))
    addLine("Ambient: " .. tostring(Lighting.Ambient))

    local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
    if atmosphere then
        addLine("✅ Atmosphere detected - Density: " .. tostring(atmosphere.Density))
    end

    -- Check for special effects (might indicate events)
    local effectCount = 0
    for _, effect in pairs(Lighting:GetChildren()) do
        if effect:IsA("ColorCorrectionEffect") or effect:IsA("BloomEffect") or effect:IsA("BlurEffect") then
            effectCount = effectCount + 1
            addLine("   Effect: " .. effect.Name .. " [" .. effect.ClassName .. "]")
        end
    end

    if effectCount > 0 then
        addLine("⚠️ Special lighting effects active (possible event)")
    end
end)

-- === 31. PARTICLE EFFECTS (Event Indicators) ===
addLine("\n\n✨ === ACTIVE PARTICLE EFFECTS ===")
pcall(function()
    local particleCount = 0
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("ParticleEmitter") and obj.Enabled then
            particleCount = particleCount + 1
            if particleCount <= 15 then
                addLine("   [" .. particleCount .. "] " .. obj:GetFullName())
            end
        end
    end

    if particleCount > 15 then
        addLine("   (...and " .. (particleCount - 15) .. " more)")
    end
    addLine("\n✅ Total active particle emitters: " .. particleCount)
end)

-- === 32. TEAM SYSTEM ===
addLine("\n\n👥 === TEAM SYSTEM ===")
pcall(function()
    local Teams = game:GetService("Teams")
    if #Teams:GetChildren() > 0 then
        addLine("✅ Game has teams:")
        for _, team in pairs(Teams:GetChildren()) do
            addLine("   • " .. team.Name .. " - Color: " .. tostring(team.TeamColor))
        end

        local playerTeam = Players.LocalPlayer.Team
        if playerTeam then
            addLine("\n✅ Current team: " .. playerTeam.Name)
        end
    else
        addLine("⚠️ No team system detected")
    end
end)

-- === EXPORT TO FILE ===
addLine("\n\n========================================")
addLine("✅ DIAGNOSTIC SCAN COMPLETE")
addLine("========================================")

local fullReport = table.concat(report, "\n")

-- Save to clipboard (if available)
pcall(function()
    setclipboard(fullReport)
    print("\n📋 Report copied to clipboard!")
end)

-- Try to write to file (if writefile is available)
pcall(function()
    local filename = "BGSI_Diagnostic_Report_" .. os.date("%Y%m%d_%H%M%S") .. ".txt"
    writefile(filename, fullReport)
    print("💾 Report saved to: " .. filename)
end)

print("\n✅ You can now copy all this information!")
print("   Check your executor's output/console tab")
print("   Or check for the .txt file in your workspace folder")
