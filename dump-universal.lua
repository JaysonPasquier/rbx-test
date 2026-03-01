-- Universal Game Dumper (All Locations)
-- Dumps ReplicatedStorage, PlayerScripts, PlayerGui, StarterPlayer, etc.
-- AI-Optimized JSON + Human-Readable TXT

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local timestamp = os.date("%Y%m%d_%H%M%S")

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local LOCATIONS = {
    {
        Name = "ReplicatedStorage",
        Container = RS,
        Description = "Shared modules, data, and utilities",
        Priority = 1
    },
    {
        Name = "PlayerScripts",
        Container = player:WaitForChild("PlayerScripts", 5),
        Description = "Client-side controllers and logic",
        Priority = 2
    },
    {
        Name = "PlayerGui",
        Container = player:WaitForChild("PlayerGui", 5),
        Description = "UI scripts and handlers",
        Priority = 3
    },
    {
        Name = "StarterPlayerScripts",
        Container = StarterPlayer:FindFirstChild("StarterPlayerScripts"),
        Description = "Template player scripts",
        Priority = 4
    },
    {
        Name = "StarterCharacterScripts",
        Container = StarterPlayer:FindFirstChild("StarterCharacterScripts"),
        Description = "Template character scripts",
        Priority = 5
    },
    {
        Name = "StarterGui",
        Container = StarterGui,
        Description = "Template UI elements",
        Priority = 6
    }
}

-- ============================================================================
-- GLOBAL STATS
-- ============================================================================

local globalStats = {
    totalScripts = 0,
    successfulScripts = 0,
    failedScripts = 0,
    totalLines = 0,
    locationStats = {}
}

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

local function getFullPath(obj)
    local path = obj.Name
    local parent = obj.Parent

    while parent and parent ~= game do
        path = parent.Name .. "." .. path
        parent = parent.Parent
    end

    return path
end

local function getScriptEmoji(scriptType)
    if scriptType == "ModuleScript" then return "📦"
    elseif scriptType == "LocalScript" then return "📜"
    elseif scriptType == "Script" then return "📄"
    else return "❓" end
end

local function countLines(source)
    if not source then return 0 end
    local count = 1
    for _ in source:gmatch("\n") do
        count = count + 1
    end
    return count
end

local function extractScript(script)
    local success, source = pcall(function()
        return decompile(script)
    end)

    if not success then
        return nil, "Decompile failed: " .. tostring(source)
    end

    if not source or source == "" then
        return nil, "Empty source code"
    end

    local lines = countLines(source)
    globalStats.totalLines = globalStats.totalLines + lines

    return {
        Path = getFullPath(script),
        Type = script.ClassName,
        Name = script.Name,
        Parent = script.Parent.Name,
        Lines = lines,
        Size = #source,
        Source = source
    }, nil
end

local function scanFolder(folder, depth, locationName)
    if not folder then return end
    depth = depth or 0
    local indent = string.rep("  ", depth)

    print(indent .. "📁 " .. folder.Name)

    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("ModuleScript") or child:IsA("LocalScript") or child:IsA("Script") then
            globalStats.totalScripts = globalStats.totalScripts + 1
            local emoji = getScriptEmoji(child.ClassName)

            print(indent .. "  " .. emoji .. " " .. child.Name)

            local scriptData, err = extractScript(child)

            if scriptData then
                globalStats.successfulScripts = globalStats.successfulScripts + 1
                scriptData.Location = locationName  -- Tag with location

                if not globalStats.locationStats[locationName].scripts then
                    globalStats.locationStats[locationName].scripts = {}
                end
                table.insert(globalStats.locationStats[locationName].scripts, scriptData)
            else
                globalStats.failedScripts = globalStats.failedScripts + 1
                print(indent .. "    ❌ " .. err)

                -- Record failed script
                if not globalStats.locationStats[locationName].scripts then
                    globalStats.locationStats[locationName].scripts = {}
                end
                table.insert(globalStats.locationStats[locationName].scripts, {
                    Path = getFullPath(child),
                    Type = child.ClassName,
                    Name = child.Name,
                    Parent = child.Parent.Name,
                    Location = locationName,
                    Error = err,
                    Failed = true
                })
            end

        elseif child:IsA("Folder") or child:IsA("Configuration") or child:IsA("ScreenGui") or child:IsA("Frame") then
            scanFolder(child, depth + 1, locationName)
        end
    end
end

-- ============================================================================
-- MAIN EXECUTION
-- ============================================================================

print("╔════════════════════════════════════════════════════════════════╗")
print("║              Universal Game Dumper (AI-Optimized)             ║")
print("╚════════════════════════════════════════════════════════════════╝")
print("")
print("🎯 Target Locations:")

-- Initialize location stats
for _, location in ipairs(LOCATIONS) do
    if location.Container then
        print("   ✅ " .. location.Name .. " - " .. location.Description)
        globalStats.locationStats[location.Name] = {
            description = location.Description,
            container = location.Container:GetFullName(),
            scripts = {}
        }
    else
        print("   ❌ " .. location.Name .. " - Not found (may not exist in this game)")
    end
end

print("")
print("🔍 Starting comprehensive scan...")
print("⏱️  This may take 60-120 seconds for complete dump")
print("")

local startTime = tick()

-- Scan each location
for _, location in ipairs(LOCATIONS) do
    if location.Container then
        print("\n" .. string.rep("═", 80))
        print("📍 SCANNING: " .. location.Name)
        print(string.rep("═", 80))
        scanFolder(location.Container, 0, location.Name)
    end
end

local scanDuration = math.floor((tick() - startTime) * 100) / 100

print("\n" .. string.rep("═", 80))
print("✅ SCAN COMPLETE!")
print(string.rep("═", 80))
print("   📦 Total Scripts: " .. globalStats.totalScripts)
print("   ✅ Successful: " .. globalStats.successfulScripts)
print("   ❌ Failed: " .. globalStats.failedScripts)
print("   📝 Total Lines: " .. globalStats.totalLines)
print("   ⏱️  Duration: " .. scanDuration .. "s")

-- ============================================================================
-- BUILD OUTPUT DATA
-- ============================================================================

local outputData = {
    Metadata = {
        Timestamp = timestamp,
        TimestampHuman = os.date("%Y-%m-%d %H:%M:%S"),
        Game = game.GameId,
        PlaceId = game.PlaceId,
        Player = player.Name,
        DumpVersion = "2.0-Universal"
    },
    Summary = {
        TotalScripts = globalStats.totalScripts,
        SuccessfulScripts = globalStats.successfulScripts,
        FailedScripts = globalStats.failedScripts,
        TotalLines = globalStats.totalLines,
        ScanDuration = scanDuration
    },
    Locations = globalStats.locationStats
}

-- Flatten all scripts for easier searching
outputData.AllScripts = {}
for locationName, locationData in pairs(globalStats.locationStats) do
    for _, script in ipairs(locationData.scripts) do
        table.insert(outputData.AllScripts, script)
    end
end

-- Sort by path
table.sort(outputData.AllScripts, function(a, b)
    return a.Path < b.Path
end)

-- ============================================================================
-- SAVE JSON (AI-Optimized)
-- ============================================================================

print("\n💾 Saving JSON format...")

local jsonSuccess, jsonData = pcall(function()
    return HttpService:JSONEncode(outputData)
end)

local jsonFilename
if jsonSuccess and jsonData then
    jsonFilename = "GameDump_Complete_" .. timestamp .. ".json"
    writefile(jsonFilename, jsonData)
    print("   ✅ " .. jsonFilename .. " (" .. math.floor(#jsonData / 1024) .. " KB)")
else
    print("   ❌ JSON encode failed: " .. tostring(jsonData))
end

-- ============================================================================
-- SAVE TXT (Human-Readable)
-- ============================================================================

print("\n💾 Saving TXT format...")

local txtOutput = {}

-- Header
table.insert(txtOutput, "╔════════════════════════════════════════════════════════════════╗")
table.insert(txtOutput, "║          Complete Game Dump - " .. timestamp .. "           ║")
table.insert(txtOutput, "╚════════════════════════════════════════════════════════════════╝")
table.insert(txtOutput, "")
table.insert(txtOutput, "📊 SUMMARY:")
table.insert(txtOutput, "   • Total Scripts: " .. globalStats.totalScripts)
table.insert(txtOutput, "   • Successful: " .. globalStats.successfulScripts)
table.insert(txtOutput, "   • Failed: " .. globalStats.failedScripts)
table.insert(txtOutput, "   • Total Lines: " .. globalStats.totalLines)
table.insert(txtOutput, "   • Scan Duration: " .. scanDuration .. "s")
table.insert(txtOutput, "   • Timestamp: " .. outputData.Metadata.TimestampHuman)
table.insert(txtOutput, "")

-- Location breakdown
table.insert(txtOutput, "📍 LOCATIONS SCANNED:")
for _, location in ipairs(LOCATIONS) do
    if globalStats.locationStats[location.Name] then
        local count = #globalStats.locationStats[location.Name].scripts
        table.insert(txtOutput, "   • " .. location.Name .. ": " .. count .. " scripts")
    end
end

table.insert(txtOutput, "")
table.insert(txtOutput, "════════════════════════════════════════════════════════════════")
table.insert(txtOutput, "")

-- All scripts (by location, then by path)
for _, location in ipairs(LOCATIONS) do
    local locationData = globalStats.locationStats[location.Name]
    if locationData and #locationData.scripts > 0 then
        table.insert(txtOutput, "")
        table.insert(txtOutput, "┏" .. string.rep("━", 78) .. "┓")
        table.insert(txtOutput, "┃  📍 " .. location.Name:upper() .. " (" .. #locationData.scripts .. " scripts)")
        table.insert(txtOutput, "┗" .. string.rep("━", 78) .. "┛")
        table.insert(txtOutput, "")

        -- Sort scripts by path
        local scripts = locationData.scripts
        table.sort(scripts, function(a, b)
            return a.Path < b.Path
        end)

        for i, script in ipairs(scripts) do
            local emoji = getScriptEmoji(script.Type)

            table.insert(txtOutput, string.rep("═", 80))
            table.insert(txtOutput, emoji .. " SCRIPT: " .. script.Path)
            table.insert(txtOutput, string.rep("═", 80))
            table.insert(txtOutput, "")
            table.insert(txtOutput, "📌 Type: " .. script.Type)
            table.insert(txtOutput, "📁 Parent: " .. script.Parent)
            table.insert(txtOutput, "📍 Location: " .. script.Location)

            if script.Failed then
                table.insert(txtOutput, "❌ Status: FAILED")
                table.insert(txtOutput, "⚠️  Error: " .. script.Error)
            else
                table.insert(txtOutput, "✅ Status: SUCCESS")
                table.insert(txtOutput, "📝 Lines: " .. script.Lines)
                table.insert(txtOutput, "💾 Size: " .. script.Size .. " bytes")
                table.insert(txtOutput, "")
                table.insert(txtOutput, "─── SOURCE CODE " .. string.rep("─", 63))
                table.insert(txtOutput, "")
                table.insert(txtOutput, script.Source)
                table.insert(txtOutput, "")
                table.insert(txtOutput, "─── END SOURCE CODE " .. string.rep("─", 59))
            end

            table.insert(txtOutput, "")
        end
    end
end

-- Footer
table.insert(txtOutput, "")
table.insert(txtOutput, "════════════════════════════════════════════════════════════════")
table.insert(txtOutput, "END OF DUMP - " .. globalStats.totalScripts .. " total scripts across all locations")
table.insert(txtOutput, "════════════════════════════════════════════════════════════════")

local txtContent = table.concat(txtOutput, "\n")
local txtFilename = "GameDump_Complete_" .. timestamp .. ".txt"
writefile(txtFilename, txtContent)
print("   ✅ " .. txtFilename .. " (" .. math.floor(#txtContent / 1024) .. " KB)")

-- ============================================================================
-- SAVE INDEX (Quick Reference)
-- ============================================================================

print("\n💾 Saving index...")

local indexOutput = {}
table.insert(indexOutput, "📋 COMPLETE GAME SCRIPT INDEX")
table.insert(indexOutput, "Generated: " .. outputData.Metadata.TimestampHuman)
table.insert(indexOutput, "")
table.insert(indexOutput, "Total: " .. globalStats.totalScripts .. " scripts, " .. globalStats.totalLines .. " lines")
table.insert(indexOutput, "")

-- By location
for _, location in ipairs(LOCATIONS) do
    local locationData = globalStats.locationStats[location.Name]
    if locationData and #locationData.scripts > 0 then
        table.insert(indexOutput, "")
        table.insert(indexOutput, "━━━ " .. location.Name .. " (" .. #locationData.scripts .. " scripts) ━━━")

        local scripts = locationData.scripts
        table.sort(scripts, function(a, b)
            return a.Path < b.Path
        end)

        for i, script in ipairs(scripts) do
            if not script.Failed then
                local emoji = getScriptEmoji(script.Type)
                table.insert(indexOutput, string.format("  %s %s (%d lines)",
                    emoji, script.Path, script.Lines))
            end
        end
    end
end

local indexContent = table.concat(indexOutput, "\n")
local indexFilename = "GameDump_Index_" .. timestamp .. ".txt"
writefile(indexFilename, indexContent)
print("   ✅ " .. indexFilename)

-- ============================================================================
-- LOCATION SUMMARIES (Individual files for each location)
-- ============================================================================

print("\n💾 Saving individual location summaries...")

for _, location in ipairs(LOCATIONS) do
    local locationData = globalStats.locationStats[location.Name]
    if locationData and #locationData.scripts > 0 then
        local summaryOutput = {}

        table.insert(summaryOutput, "📍 " .. location.Name:upper())
        table.insert(summaryOutput, location.Description)
        table.insert(summaryOutput, "")
        table.insert(summaryOutput, "Scripts: " .. #locationData.scripts)
        table.insert(summaryOutput, "")

        local scripts = locationData.scripts
        table.sort(scripts, function(a, b)
            return a.Path < b.Path
        end)

        for _, script in ipairs(scripts) do
            if not script.Failed then
                local emoji = getScriptEmoji(script.Type)
                table.insert(summaryOutput, emoji .. " " .. script.Name .. " (" .. script.Lines .. " lines)")
            end
        end

        local summaryContent = table.concat(summaryOutput, "\n")
        local summaryFilename = "Summary_" .. location.Name .. "_" .. timestamp .. ".txt"
        writefile(summaryFilename, summaryContent)
        print("   ✅ " .. summaryFilename)
    end
end

-- ============================================================================
-- FINAL REPORT
-- ============================================================================

print("\n" .. string.rep("═", 80))
print("✅ DUMP COMPLETE!")
print(string.rep("═", 80))
print("")
print("📁 Files Created:")
print("   1. " .. (jsonFilename or "JSON (failed)") .. " - Complete dump (AI-optimized)")
print("   2. " .. txtFilename .. " - Complete dump (human-readable)")
print("   3. " .. indexFilename .. " - Quick reference index")

for _, location in ipairs(LOCATIONS) do
    if globalStats.locationStats[location.Name] and #globalStats.locationStats[location.Name].scripts > 0 then
        print("   • Summary_" .. location.Name .. "_" .. timestamp .. ".txt")
    end
end

print("")
print("📊 Location Breakdown:")
for _, location in ipairs(LOCATIONS) do
    local locationData = globalStats.locationStats[location.Name]
    if locationData then
        local count = #locationData.scripts
        local successCount = 0
        for _, script in ipairs(locationData.scripts) do
            if not script.Failed then
                successCount = successCount + 1
            end
        end
        print(string.format("   • %-25s %3d scripts (%d succeeded)",
            location.Name .. ":", count, successCount))
    end
end

print("")
print("🤖 Upload the JSON file for AI analysis with COMPLETE game visibility!")
print("👤 Use the TXT file for human reading and reference!")
print("📋 Use location summaries for quick navigation!")
print("")
print(string.rep("═", 80))
