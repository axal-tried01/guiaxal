-- loadstring(game:HttpGet("https://github.com/benzonati/Rivals-Anticheat-Bypass/raw/refs/heads/main/main.luau"))()

if not game:IsLoaded() then
    game.Loaded:Wait()
end
if game.GameId ~= 6035872082 then
    return
end
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
repeat
    task.wait()
until LocalPlayer
print("Rivals Anticheat Disabler executed!")
local success, err = pcall(function()
    assert(getgc, "executor missing required function getgc")
    assert(debug and debug.info, "executor missing required function debug.info (somehow)")
    assert(hookfunction, "executor missing required function hookfunction")
    assert(getconnections, "executor missing required function getconnections")
    assert(newcclosure, "executor missing required function newcclosure")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local LogService = game:GetService("LogService")
    local ScriptContext = game:GetService("ScriptContext")
    -- Méthode 1: Hook du remote AnalyticsPipeline
    task.spawn(function()
        local ok, remote = pcall(function()
            return ReplicatedStorage:WaitForChild("Remotes", 5):WaitForChild("AnalyticsPipeline", 5):WaitForChild("RemoteEvent", 5)
        end)
        if ok and remote and remote.OnClientEvent then
            local hooked = 0
            for _, conn in pairs(getconnections(remote.OnClientEvent)) do
                if conn and conn.Function then
                    if pcall(function()
                        hookfunction(conn.Function, newcclosure(function(...)
                            -- Bloquer tous les appels
                        end))
                    end) then 
                        hooked += 1
                    end
                end
            end
            print("Hooked " .. hooked .. " anticheat remote connections")
        end
    end)
    
    -- Méthode 2: Hook sélectif des fonctions AnalyticsPipelineController (backup)
    task.spawn(function()
        local hooked = 0
        local blacklistedNames = {
            "constructor", "new", "init", "destroy", "update", 
            "connect", "disconnect", "on", "once", "wait",
            "get", "set", "is", "has", "check", "validate"
        }
        
        local function isBlacklisted(name)
            if not name or name == "" then return true end
            name = name:lower()
            for _, blacklisted in ipairs(blacklistedNames) do
                if string.find(name, blacklisted) then
                    return true
                end
            end
            return false
        end
        
        for _, v in pairs(getgc(true)) do
            if typeof(v) == "function" then
                local ok, src = pcall(function()
                    return debug.info(v, "s")
                end)
                if ok and type(src) == "string" and string.find(src, "AnalyticsPipelineController") then
                    local funcName = pcall(function()
                        return debug.info(v, "n")
                    end) and debug.info(v, "n") or ""
                    
                    -- Hook seulement les fonctions de reporting (whitelist approach)
                    local shouldHook = false
                    if funcName and funcName ~= "" then
                        local lowerName = funcName:lower()
                        if string.find(lowerName, "report") or 
                           string.find(lowerName, "send") or 
                           string.find(lowerName, "track") or
                           string.find(lowerName, "log") or
                           string.find(lowerName, "flag") then
                            shouldHook = not isBlacklisted(funcName)
                        end
                    end
                    
                    if shouldHook then
                        local success = pcall(function()
                            hookfunction(v, newcclosure(function(...)
                                -- Bloquer silencieusement
                                return
                            end))
                        end)
                        if success then
                            hooked += 1
                        end
                    end
                end
            end
        end
        if hooked > 0 then
            print("Safely hooked " .. hooked .. " analytics functions")
        end
    end)
    task.spawn(function()
        local hooked = 0
        for _, conn in pairs(getconnections(LogService.MessageOut)) do
            if conn and conn.Function then
                if pcall(function()
                    hookfunction(conn.Function, newcclosure(function(...)
                    end))
                end) then
                    hooked += 1
                end
            end
        end
        print("Hooked " .. hooked .. " MessageOut connections")
    end)
    task.spawn(function()
        local hooked = 0
        for _, conn in ipairs(getconnections(ScriptContext.Error)) do
            if pcall(function()
                conn:Disable()
            end) then
                hooked += 1
            end
        end
        print("Hooked " .. hooked .. " error connections")
        pcall(function()
            hookfunction(ScriptContext.Error.Connect, newcclosure(function(...)
                return nil
            end))
        end)
    end)
    task.spawn(function()
        local KickNames = {
            "Kick",
            "kick"
        }
        for _, name in ipairs(KickNames) do
            local fn = LocalPlayer[name]
            if type(fn) == "function" then
                local oldkick
                oldkick = hookfunction(fn, newcclosure(function(self, ...)
                    if self == LocalPlayer then
                        return
                    end
                    return oldkick(self, ...)
                end))
            end
        end
    end)
end)
if not success then
    game:GetService("StarterGui"):SetCore("SendNotification", {
    	Title = "Rivals Anticheat Disabler",
    	Text = "Error, please check console",
    	Duration = 5
    })
    print("Rivals Anticheat Disabler failed: " .. tostring(err))
else
    game:GetService("StarterGui"):SetCore("SendNotification", {
    	Title = "Rivals Anticheat Disabler",
    	Text = "Successfully disabled anticheat!",
    	Duration = 5
    })
end
