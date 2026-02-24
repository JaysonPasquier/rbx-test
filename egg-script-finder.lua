-- Simple Egg Data Dumper
-- Goes directly to ReplicatedStorage.Shared.Data.Eggs and dumps to file

print("🥚 Reading egg data...")

local HttpService = game:GetService("HttpService")

-- Get the Eggs module
local success, result = pcall(function()
    local eggsModule = game:GetService("ReplicatedStorage").Shared.Data.Rifts
    local eggsData = require(eggsModule)

    -- Convert to JSON string (preserves structure)
    return HttpService:JSONEncode(eggsData)
end)

if success then
    -- Save to file
    local filename = "Rifts_data.txt"
    if writefile then
        writefile(filename, result)
        print("✅ Saved to: " .. filename)
    else
        print("⚠️ writefile not available")
        print(result)
    end
else
    print("❌ Error: " .. tostring(result))
end
