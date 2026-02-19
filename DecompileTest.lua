-- [TEST] FULL GAME DECOMPILE ATTEMPT - Logs what succeeds/fails
local success = {}
local failures = {}

print("=== DECOMPILE TEST START ===")

-- 1. SaveInstance (dumps models/parts bytecode)
if saveinstance then
    saveinstance("GameDump_" .. game.PlaceId .. ".rbxl")
    table.insert(success, "saveinstance OK - Full place file saved")
else
    table.insert(failures, "saveinstance blocked")
end

-- 2. Decompile all scripts
local scriptCount = 0
for _, obj in pairs(game:GetDescendants()) do
    if obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
        scriptCount = scriptCount + 1
        if decompile then
            local source = decompile(obj)
            if writefile then
                writefile("Decompiled/" .. obj.Name .. "_" .. scriptCount .. ".lua", source)
                table.insert(success, "Decompiled " .. obj.Name)
            end
        end
    end
end

-- 3. getscripts() dump (executor-specific)
if getscripts then
    local scripts = getscripts()
    for i, script in pairs(scripts) do
        if writefile then writefile("getscripts_" .. i .. ".lua", decompile(script)) end
    end
    table.insert(success, "getscripts found " .. #scripts)
end

-- 4. Read script bytecode directly
if readfile and isfile then
    for _, obj in pairs(game:GetDescendants()) do
        if obj.SourceSize and obj.SourceSize > 0 then
            local bytecode = obj.Source
            writefile("Bytecode_" .. obj.Name .. ".bin", bytecode)
        end
    end
end

-- Results
print("SUCCESS: " .. table.concat(success, ", "))
print("FAILED: " .. table.concat(failures, ", "))
print("Scripts scanned: " .. scriptCount)
print("Check 'Decompiled/' folder for extracted source!")
