-- DeadRails ESP Cheat by LxckStxp
-- Injected via Executor

local baseUrl = "https://raw.githubusercontent.com/LxckStxp/DeadRails/main/modules/"

local function loadModule(url)
    local success, result = pcall(game.HttpGet, game, url)
    if success then
        return loadstring(result)()
    else
        warn("Failed to load module at", url, ": ", result)
        return nil
    end
end

local Config = loadModule(baseUrl .. "Config.lua")
if not Config then error("Config.lua failed to load") end

local Utilities = loadModule(baseUrl .. "Utilities.lua")
if not Utilities then error("Utilities.lua failed to load") end

local ESP = loadModule(baseUrl .. "ESP/ESP.lua")()(Config, Utilities)
if not ESP then error("ESP.lua failed to load") end

local MiddleClick = loadModule(baseUrl .. "MiddleClick.lua")
if not MiddleClick then error("MiddleClick.lua failed to load") end

local Aimbot = loadModule(baseUrl .. "Aimbot.lua")
if not Aimbot then error("Aimbot.lua failed to load") end

local UI = loadModule(baseUrl .. "UI.lua")()(Config, ESP, MiddleClick, Aimbot)
if not UI then error("UI.lua failed to load") end

ESP.Initialize()
MiddleClick.Initialize()
Aimbot.Initialize()

print("DeadRails ESP Loaded Successfully!")
