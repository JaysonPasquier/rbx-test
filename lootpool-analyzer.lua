-- LOOTPOOL VIEWER ANALYZER
-- Analyzes the LootPoolViewer GUI structure and finds all related scripts
-- Saves everything to local .txt files

print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("🔍 LOOTPOOL VIEWER ANALYZER")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")

-- File writing function (for executors)
local function saveToFile(filename, content)
    if writefile then
        writefile(filename, content)
        print("✅ Saved: " .. filename)
    else
        print("❌ writefile not available - copying to clipboard instead")
        if setclipboard then
            setclipboard(content)
            print("📋 Copied to clipboard!")
        end
    end
end

-- ========================================
-- PART 1: DUMP LOOTPOOLVIEWER STRUCTURE
-- ========================================
print("\n📊 ANALYZING LOOTPOOLVIEWER STRUCTURE...")

local lootPoolViewer = player:WaitForChild("PlayerGui"):WaitForChild("HUD"):WaitForChild("LootPoolViewer")
local structureOutput = {}

table.insert(structureOutput, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
table.insert(structureOutput, "📊 LOOTPOOLVIEWER FULL STRUCTURE")
table.insert(structureOutput, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
table.insert(structureOutput, "")
table.insert(structureOutput, "Path: " .. lootPoolViewer:GetFullName())
table.insert(structureOutput, "Class: " .. lootPoolViewer.ClassName)
table.insert(structureOutput, "")

local function dumpInstance(instance, indent)
    local output = {}

    -- Current instance info
    local prefix = string.rep("  ", indent)
    local line = prefix .. "├─ " .. instance.Name .. " [" .. instance.ClassName .. "]"
    table.insert(output, line)

    -- Properties
    if instance:IsA("Frame") or instance:IsA("ScreenGui") then
        table.insert(output, prefix .. "│  Visible: " .. tostring(instance.Visible))
        if instance:IsA("Frame") then
            table.insert(output, prefix .. "│  Size: " .. tostring(instance.Size))
            table.insert(output, prefix .. "│  Position: " .. tostring(instance.Position))
        end
    end

    if instance:IsA("TextLabel") or instance:IsA("TextButton") then
        table.insert(output, prefix .. "│  Text: '" .. instance.Text .. "'")
        table.insert(output, prefix .. "│  Visible: " .. tostring(instance.Visible))
    end

    if instance:IsA("ImageLabel") or instance:IsA("ImageButton") then
        table.insert(output, prefix .. "│  Image: " .. instance.Image)
        table.insert(output, prefix .. "│  Visible: " .. tostring(instance.Visible))
    end

    if instance:IsA("UIListLayout") or instance:IsA("UIGridLayout") then
        table.insert(output, prefix .. "│  Layout: " .. instance.ClassName)
    end

    -- Check for scripts
    if instance:IsA("LocalScript") or instance:IsA("Script") or instance:IsA("ModuleScript") then
        table.insert(output, prefix .. "│  ⚠️ SCRIPT FOUND!")
    end

    -- Children
    local children = instance:GetChildren()
    if #children > 0 then
        table.insert(output, prefix .. "│  Children: " .. #children)
        for i, child in ipairs(children) do
            for _, childLine in ipairs(dumpInstance(child, indent + 1)) do
                table.insert(output, childLine)
            end
        end
    end

    return output
end

local structureLines = dumpInstance(lootPoolViewer, 0)
for _, line in ipairs(structureLines) do
    table.insert(structureOutput, line)
end

table.insert(structureOutput, "")
table.insert(structureOutput, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
table.insert(structureOutput, "Total descendants: " .. #lootPoolViewer:GetDescendants())
table.insert(structureOutput, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

saveToFile("lootpool_structure.txt", table.concat(structureOutput, "\n"))

-- ========================================
-- PART 2: FIND ALL RELATED SCRIPTS
-- ========================================
print("\n🔎 SEARCHING ALL SCRIPTS FOR 'LootPoolViewer'...")

local scriptAnalysis = {}
table.insert(scriptAnalysis, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
table.insert(scriptAnalysis, "🔍 LOOTPOOLVIEWER SCRIPT ANALYSIS")
table.insert(scriptAnalysis, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
table.insert(scriptAnalysis, "")
table.insert(scriptAnalysis, "Searching for any mention of 'LootPoolViewer' in all scripts...")
table.insert(scriptAnalysis, "")

local searchLocations = {
    {name = "PlayerGui", location = player.PlayerGui},
    {name = "ReplicatedStorage", location = RS},
    {name = "StarterGui", location = game:GetService("StarterGui")},
    {name = "StarterPlayer", location = game:GetService("StarterPlayer")},
}

local foundScripts = {}
local totalScanned = 0

for _, searchData in ipairs(searchLocations) do
    table.insert(scriptAnalysis, "")
    table.insert(scriptAnalysis, "━━━ Scanning: " .. searchData.name .. " ━━━")

    pcall(function()
        for _, obj in pairs(searchData.location:GetDescendants()) do
            if obj:IsA("LocalScript") or obj:IsA("Script") or obj:IsA("ModuleScript") then
                totalScanned = totalScanned + 1

                local success, source = pcall(function()
                    return decompile(obj)
                end)

                if success and source then
                    -- Search for LootPoolViewer mention
                    if source:find("LootPoolViewer") then
                        table.insert(foundScripts, {
                            name = obj.Name,
                            path = obj:GetFullName(),
                            class = obj.ClassName,
                            source = source,
                            location = searchData.name
                        })

                        table.insert(scriptAnalysis, "")
                        table.insert(scriptAnalysis, "✅ MATCH FOUND: " .. obj.Name)
                        table.insert(scriptAnalysis, "   Path: " .. obj:GetFullName())
                        table.insert(scriptAnalysis, "   Type: " .. obj.ClassName)

                        -- Count mentions
                        local count = 0
                        for _ in source:gmatch("LootPoolViewer") do
                            count = count + 1
                        end
                        table.insert(scriptAnalysis, "   Mentions: " .. count .. " times")

                        -- Find line numbers with mentions
                        local lineNum = 1
                        local mentionLines = {}
                        for line in source:gmatch("[^\r\n]+") do
                            if line:find("LootPoolViewer") then
                                table.insert(mentionLines, lineNum)
                            end
                            lineNum = lineNum + 1
                        end
                        table.insert(scriptAnalysis, "   Lines: " .. table.concat(mentionLines, ", "))
                    end
                end
            end
        end
    end)
end

table.insert(scriptAnalysis, "")
table.insert(scriptAnalysis, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
table.insert(scriptAnalysis, "SUMMARY:")
table.insert(scriptAnalysis, "  Total scripts scanned: " .. totalScanned)
table.insert(scriptAnalysis, "  Scripts with 'LootPoolViewer': " .. #foundScripts)
table.insert(scriptAnalysis, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

saveToFile("lootpool_script_analysis.txt", table.concat(scriptAnalysis, "\n"))

-- ========================================
-- PART 3: SAVE FULL SCRIPT SOURCES
-- ========================================
print("\n💾 SAVING FULL SCRIPT SOURCES...")

for i, scriptData in ipairs(foundScripts) do
    local scriptOutput = {}

    table.insert(scriptOutput, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    table.insert(scriptOutput, "SCRIPT #" .. i .. ": " .. scriptData.name)
    table.insert(scriptOutput, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    table.insert(scriptOutput, "Path: " .. scriptData.path)
    table.insert(scriptOutput, "Type: " .. scriptData.class)
    table.insert(scriptOutput, "Location: " .. scriptData.location)
    table.insert(scriptOutput, "")
    table.insert(scriptOutput, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    table.insert(scriptOutput, "SOURCE CODE:")
    table.insert(scriptOutput, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    table.insert(scriptOutput, "")
    table.insert(scriptOutput, scriptData.source)
    table.insert(scriptOutput, "")
    table.insert(scriptOutput, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    table.insert(scriptOutput, "END OF SCRIPT #" .. i)
    table.insert(scriptOutput, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

    local filename = string.format("lootpool_script_%d_%s.txt", i, scriptData.name:gsub("[^%w]", "_"))
    saveToFile(filename, table.concat(scriptOutput, "\n"))
end

-- ========================================
-- PART 4: ADVANCED PATTERN SEARCH
-- ========================================
print("\n🔬 ADVANCED PATTERN ANALYSIS...")

local patternOutput = {}
table.insert(patternOutput, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
table.insert(patternOutput, "🔬 ADVANCED PATTERN ANALYSIS")
table.insert(patternOutput, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
table.insert(patternOutput, "")
table.insert(patternOutput, "Searching for related patterns in all scripts...")
table.insert(patternOutput, "")

local patterns = {
    "LootPool",
    "PoolViewer",
    "HUD%.LootPoolViewer",
    "Visible.*LootPool",
    "Enabled.*LootPool",
    "MaxDistance.*Egg",
    "Proximity.*Egg",
    "Distance.*Egg",
}

for _, pattern in ipairs(patterns) do
    table.insert(patternOutput, "")
    table.insert(patternOutput, "━━━ Pattern: '" .. pattern .. "' ━━━")

    local patternMatches = 0

    for _, scriptData in ipairs(foundScripts) do
        local matches = {}
        for match in scriptData.source:gmatch("[^\r\n]*" .. pattern .. "[^\r\n]*") do
            table.insert(matches, match)
            patternMatches = patternMatches + 1
        end

        if #matches > 0 then
            table.insert(patternOutput, "")
            table.insert(patternOutput, "  " .. scriptData.name .. ":")
            for _, match in ipairs(matches) do
                table.insert(patternOutput, "    → " .. match:match("^%s*(.-)%s*$"))
            end
        end
    end

    table.insert(patternOutput, "  Total matches: " .. patternMatches)
end

table.insert(patternOutput, "")
table.insert(patternOutput, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

saveToFile("lootpool_patterns.txt", table.concat(patternOutput, "\n"))

-- ========================================
-- PART 5: PROPERTY ANALYSIS
-- ========================================
print("\n📋 ANALYZING LOOTPOOLVIEWER PROPERTIES...")

local propertyOutput = {}
table.insert(propertyOutput, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
table.insert(propertyOutput, "📋 LOOTPOOLVIEWER PROPERTIES")
table.insert(propertyOutput, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
table.insert(propertyOutput, "")

-- Get all properties
local properties = {
    "Visible", "Enabled", "Active", "Adornee", "MaxDistance",
    "Size", "Position", "AnchorPoint", "ZIndex"
}

for _, propName in ipairs(properties) do
    pcall(function()
        local value = lootPoolViewer[propName]
        table.insert(propertyOutput, propName .. ": " .. tostring(value))
    end)
end

table.insert(propertyOutput, "")
table.insert(propertyOutput, "━━━ Changed Event Connections ━━━")
table.insert(propertyOutput, "")

-- Try to detect if properties have change listeners
table.insert(propertyOutput, "Note: Changed events are internal and cannot be directly detected")
table.insert(propertyOutput, "Check the script sources above for :GetPropertyChangedSignal() or .Changed")

table.insert(propertyOutput, "")
table.insert(propertyOutput, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

saveToFile("lootpool_properties.txt", table.concat(propertyOutput, "\n"))

-- ========================================
-- SUMMARY
-- ========================================
print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("✅ ANALYSIS COMPLETE!")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("")
print("📁 Files saved:")
print("  • lootpool_structure.txt - Full GUI hierarchy")
print("  • lootpool_script_analysis.txt - Script search summary")
print("  • lootpool_script_X_NAME.txt - Individual script sources (one per match)")
print("  • lootpool_patterns.txt - Advanced pattern analysis")
print("  • lootpool_properties.txt - Property values")
print("")
print("🔍 Found " .. #foundScripts .. " scripts that control LootPoolViewer")
print("📊 Scanned " .. totalScanned .. " total scripts")
print("")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
