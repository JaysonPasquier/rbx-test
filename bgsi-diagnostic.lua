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
                    if i <= 10 then  -- Show first 10 eggs
                        addLine("         • " .. egg.Name .. " [" .. egg.ClassName .. "]")
                    end
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
