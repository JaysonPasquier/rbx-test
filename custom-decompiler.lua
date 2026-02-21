-- BGSI Stealth Scanner v2 (No interference, 30min silent dump)
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local output_dir = "BGSI_Scan_" .. string.sub(tostring(tick()), 1, 8)
makefolder(output_dir)

local log_file = output_dir .. "/scan_log.txt"
local remotes_file = output_dir .. "/remotes.txt"
local guis_file = output_dir .. "/guis.txt"

local function safe_log(msg)
    pcall(function()
        writefile(log_file, "[" .. os.date("%H:%M:%S") .. "] " .. msg .. "\n", Enum.FileMode.Append)
    end)
end

safe_log("🕵️ Stealth scan started - silent mode")

-- PASSIVE REMOTE ENUM (100% safe, no interference)
pcall(function()
    for _, obj in pairs(game:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local full_path = obj:GetFullName()
            writefile(remotes_file, full_path .. " [" .. obj.ClassName .. "]\n", Enum.FileMode.Append)
            safe_log("📡 " .. obj.Name)
        end
    end
end)

-- PASSIVE GUI ENUM (game GUIs reveal farm targets)
pcall(function()
    for _, gui in pairs(player.PlayerGui:GetDescendants()) do
        if gui:IsA("TextButton") or gui:IsA("TextLabel") then
            local text = gui.Text or ""
            if text:lower():find("claim") or text:lower():find("blow") or text:lower():find("sell") or text:lower():find("hatch") then
                writefile(guis_file, gui:GetFullName() .. ": '" .. text .. "'\n", Enum.FileMode.Append)
                safe_log("🎯 FARM GUI: " .. gui:GetFullName())
            end
        end
    end
end)

-- NETWORK HOOK (passive monitoring only)
local remote_log = output_dir .. "/network.txt"
pcall(function()
    for _, remote in pairs(game:GetDescendants()) do
        if remote:IsA("RemoteEvent") and not getfenv(remote.FireServer).hooked then
            local old_fire = remote.FireServer
            getfenv(remote.FireServer).hooked = true
            remote.FireServer = function(...)
                pcall(function()
                    writefile(remote_log,
                        "[" .. os.date("%H:%M:%S") .. "] " .. remote:GetFullName() ..
                        " <- " .. HttpService:JSONEncode({...}) .. "\n",
                        Enum.FileMode.Append)
                end)
                return old_fire(...)
            end
            safe_log("🔗 Hooked: " .. remote.Name)
        end
    end
end)

-- LIVE GAME STATE (collectibles, hats, etc.)
spawn(function()
    while true do
        pcall(function()
            local collectibles = {}
            for _, obj in pairs(workspace:GetChildren()) do
                if obj.Name:lower():find("coin") or obj.Name:lower():find("chest") or obj.Name:lower():find("bubble") then
                    table.insert(collectibles, obj:GetFullName())
                end
            end
            if #collectibles > 0 then
                writefile(output_dir .. "/collectibles.txt",
                    "[" .. tick() .. "] " .. HttpService:JSONEncode(collectibles) .. "\n",
                    Enum.FileMode.Append)
            end
        end)
        wait(5) -- 12hr scan without interference
    end
end)

safe_log("✅ Stealth scan complete - check " .. output_dir)
safe_log("📡 remotes.txt = BGSI farm secrets!")
print("Files in: workspace." .. output_dir)
