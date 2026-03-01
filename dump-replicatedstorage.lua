-- ReplicatedStorage Complete Dumper (AI-Optimized Format)
-- Dumps ALL scripts with source code, paths, and hierarchy
-- Output: JSON + TXT formats for maximum compatibility

local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local timestamp = os.date("%Y%m%d_%H%M%S")
local scriptCount = 0
local totalLines = 0
local failedScripts = 0

-- Data structure for JSON output
local dumpData = {
    Metadata = {
        Timestamp = timestamp,
        Game = game.GameId,
        PlaceId = game.PlaceId,
        DumpVersion = "1.0"
    },
    Scripts = {},
    Hierarchy = {},
    Summary = {}
}

-- Recursive function to get full path
local function getFullPath(obj)
    local path = obj.Name
    local parent = obj.Parent

    while parent and parent ~= game do
        path = parent.Name .. "." .. path
        parent = parent.Parent
    end

    return path
end

-- Get script type emoji for readability
local function getScriptEmoji(scriptType)
    if scriptType == "ModuleScript" then return "📦"
    elseif scriptType == "LocalScript" then return "📜"
    elseif scriptType == "Script" then return "📄"
    else return "❓" end
end

-- Count lines in source code
local function countLines(source)
    local count = 1
    for _ in source:gmatch("\n") do
        count = count + 1
    end
    return count
end

-- Decompile and extract script data
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
    totalLines = totalLines + lines

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

-- Recursive scanner
local function scanFolder(folder, depth)
    depth = depth or 0
    local indent = string.rep("  ", depth)

    print(indent .. "📁 Scanning: " .. folder.Name)

    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("ModuleScript") or child:IsA("LocalScript") or child:IsA("Script") then
            scriptCount = scriptCount + 1
            local emoji = getScriptEmoji(child.ClassName)

            print(indent .. "  " .. emoji .. " " .. child.Name .. " (" .. child.ClassName .. ")")

            local scriptData, err = extractScript(child)

            if scriptData then
                table.insert(dumpData.Scripts, scriptData)
                print(indent .. "    ✅ " .. scriptData.Lines .. " lines")
            else
                failedScripts = failedScripts + 1
                print(indent .. "    ❌ " .. err)

                -- Still record failed scripts for reference
                table.insert(dumpData.Scripts, {
                    Path = getFullPath(child),
                    Type = child.ClassName,
                    Name = child.Name,
                    Parent = child.Parent.Name,
                    Error = err,
                    Failed = true
                })
            end

        elseif child:IsA("Folder") or child:IsA("Configuration") then
            scanFolder(child, depth + 1)
        end
    end
end

-- Build hierarchy tree (for navigation)
local function buildHierarchy(obj, depth)
    depth = depth or 0
    if depth > 10 then return "..." end  -- Prevent infinite recursion

    local node = {
        Name = obj.Name,
        Type = obj.ClassName,
        Children = {}
    }

    for _, child in ipairs(obj:GetChildren()) do
        if child:IsA("Folder") or child:IsA("ModuleScript") or child:IsA("LocalScript") or child:IsA("Script") then
            table.insert(node.Children, buildHierarchy(child, depth + 1))
        end
    end

    return node
end

print("╔════════════════════════════════════════════════════════════════╗")
print("║          ReplicatedStorage Complete Dump (AI Format)          ║")
print("╚════════════════════════════════════════════════════════════════╝")
print("")
print("🔍 Starting comprehensive scan...")
print("⏱️  This may take 30-60 seconds for large games")
print("")

local startTime = tick()

-- Scan all of ReplicatedStorage
scanFolder(RS)

-- Build hierarchy
print("\n📊 Building hierarchy tree...")
dumpData.Hierarchy = buildHierarchy(RS)

-- Add summary statistics
dumpData.Summary = {
    TotalScripts = scriptCount,
    SuccessfulScripts = scriptCount - failedScripts,
    FailedScripts = failedScripts,
    TotalLines = totalLines,
    ScanDuration = math.floor((tick() - startTime) * 100) / 100,
    Timestamp = os.date("%Y-%m-%d %H:%M:%S")
}

print("\n✅ Scan complete!")
print("   📦 Total Scripts: " .. scriptCount)
print("   ✅ Successful: " .. (scriptCount - failedScripts))
print("   ❌ Failed: " .. failedScripts)
print("   📝 Total Lines: " .. totalLines)
print("   ⏱️  Duration: " .. dumpData.Summary.ScanDuration .. "s")

-- ============================================================================
-- SAVE JSON FORMAT (Machine-readable, perfect for AI parsing)
-- ============================================================================
print("\n💾 Saving JSON format...")

local jsonSuccess, jsonData = pcall(function()
    return HttpService:JSONEncode(dumpData)
end)

if jsonSuccess and jsonData then
    local jsonFilename = "ReplicatedStorage_Dump_" .. timestamp .. ".json"
    writefile(jsonFilename, jsonData)
    print("   ✅ " .. jsonFilename .. " (" .. math.floor(#jsonData / 1024) .. " KB)")
else
    print("   ❌ JSON encode failed: " .. tostring(jsonData))
end

-- ============================================================================
-- SAVE TXT FORMAT (Human-readable with full separation)
-- ============================================================================
print("\n💾 Saving TXT format (human-readable)...")

local txtOutput = {}

-- Header
table.insert(txtOutput, "╔════════════════════════════════════════════════════════════════╗")
table.insert(txtOutput, "║       ReplicatedStorage Complete Dump - " .. timestamp .. "      ║")
table.insert(txtOutput, "╚════════════════════════════════════════════════════════════════╝")
table.insert(txtOutput, "")
table.insert(txtOutput, "📊 SUMMARY:")
table.insert(txtOutput, "   • Total Scripts: " .. scriptCount)
table.insert(txtOutput, "   • Successful: " .. (scriptCount - failedScripts))
table.insert(txtOutput, "   • Failed: " .. failedScripts)
table.insert(txtOutput, "   • Total Lines of Code: " .. totalLines)
table.insert(txtOutput, "   • Scan Duration: " .. dumpData.Summary.ScanDuration .. "s")
table.insert(txtOutput, "   • Timestamp: " .. dumpData.Summary.Timestamp)
table.insert(txtOutput, "")
table.insert(txtOutput, "════════════════════════════════════════════════════════════════")
table.insert(txtOutput, "")

-- Scripts (sorted by path for easier navigation)
table.sort(dumpData.Scripts, function(a, b)
    return a.Path < b.Path
end)

for i, script in ipairs(dumpData.Scripts) do
    local separator = "═"
    local emoji = getScriptEmoji(script.Type)

    table.insert(txtOutput, "")
    table.insert(txtOutput, string.rep(separator, 80))
    table.insert(txtOutput, emoji .. " SCRIPT #" .. i .. ": " .. script.Path)
    table.insert(txtOutput, string.rep(separator, 80))
    table.insert(txtOutput, "")
    table.insert(txtOutput, "📌 Type: " .. script.Type)
    table.insert(txtOutput, "📁 Parent: " .. script.Parent)

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

-- Footer
table.insert(txtOutput, "")
table.insert(txtOutput, "════════════════════════════════════════════════════════════════")
table.insert(txtOutput, "END OF DUMP - " .. scriptCount .. " scripts total")
table.insert(txtOutput, "════════════════════════════════════════════════════════════════")

local txtContent = table.concat(txtOutput, "\n")
local txtFilename = "ReplicatedStorage_Dump_" .. timestamp .. ".txt"
writefile(txtFilename, txtContent)
print("   ✅ " .. txtFilename .. " (" .. math.floor(#txtContent / 1024) .. " KB)")

-- ============================================================================
-- SAVE SCRIPT INDEX (Quick reference)
-- ============================================================================
print("\n💾 Saving script index...")

local indexOutput = {}
table.insert(indexOutput, "📋 REPLICATEDSTORAGE SCRIPT INDEX")
table.insert(indexOutput, "Generated: " .. dumpData.Summary.Timestamp)
table.insert(indexOutput, "")
table.insert(indexOutput, "Total: " .. scriptCount .. " scripts, " .. totalLines .. " lines")
table.insert(indexOutput, "")

for i, script in ipairs(dumpData.Scripts) do
    if not script.Failed then
        local emoji = getScriptEmoji(script.Type)
        table.insert(indexOutput, string.format("[%3d] %s %s (%d lines)",
            i, emoji, script.Path, script.Lines))
    end
end

local indexContent = table.concat(indexOutput, "\n")
local indexFilename = "ReplicatedStorage_Index_" .. timestamp .. ".txt"
writefile(indexFilename, indexContent)
print("   ✅ " .. indexFilename)

-- ============================================================================
-- PREVIEW (First 3 scripts)
-- ============================================================================
print("\n" .. string.rep("═", 80))
print("📄 PREVIEW (First 3 scripts):")
print(string.rep("═", 80))

for i = 1, math.min(3, #dumpData.Scripts) do
    local script = dumpData.Scripts[i]
    if not script.Failed then
        print("\n" .. i .. ". " .. script.Path .. " (" .. script.Lines .. " lines)")
        print("   " .. string.sub(script.Source, 1, 200):gsub("\n", "\n   ") .. "...")
    end
end

print("\n" .. string.rep("═", 80))
print("✅ DUMP COMPLETE!")
print(string.rep("═", 80))
print("")
print("📁 Files created:")
print("   1. " .. (jsonFilename or "JSON (failed)") .. " - Machine-readable (AI-optimized)")
print("   2. " .. txtFilename .. " - Human-readable (full source)")
print("   3. " .. indexFilename .. " - Quick reference index")
print("")
print("🤖 The JSON file is perfect for AI analysis!")
print("👤 The TXT file is perfect for human reading!")
print("📋 The index file is perfect for quick navigation!")
print("")
print("💡 Upload any of these to continue our conversation with FULL game code access!")
