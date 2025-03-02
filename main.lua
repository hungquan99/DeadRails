-- DeadRails ESP Cheat by LxckStxp
-- Injected via Executor

-- Base URL for the repository
local baseUrl = "https://raw.githubusercontent.com/LxckStxp/DeadRails/main/modules/"

-- Load modules using loadstring
local Config = loadstring(game:HttpGet(baseUrl .. "Config.lua"))()
local Utilities = loadstring(game:HttpGet(baseUrl .. "Utilities.lua"))()
local ESP = loadstring(game:HttpGet(baseUrl .. "ESP.lua"))()(Config, Utilities)
local MiddleClick = loadstring(game:HttpGet(baseUrl .. "MiddleClick.lua"))()
local UI = loadstring(game:HttpGet(baseUrl .. "UI.lua"))()(Config, ESP, MiddleClick)

-- Initialize the ESP and MiddleClick systems
ESP.Initialize()
MiddleClick.Initialize()

print("DeadRails ESP Loaded Successfully!")
