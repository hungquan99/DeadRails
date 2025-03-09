if getgenv().SkullHubLoaded then return end
getgenv().SkullHubLoaded = true

local baseUrl = "https://raw.githubusercontent.com/hungquan99/DeadRails/main/modules/"

local Config = loadstring(game:HttpGet(baseUrl .. "Config.lua"))()
local Utilities = loadstring(game:HttpGet(baseUrl .. "Utilities.lua"))()
local ESP = loadstring(game:HttpGet(baseUrl .. "ESP/ESP.lua"))()(Config, Utilities)
local MiddleClick = loadstring(game:HttpGet(baseUrl .. "MiddleClick.lua"))()
local Aimbot = loadstring(game:HttpGet(baseUrl .. "Aimbot.lua"))()
local UI = loadstring(game:HttpGet(baseUrl .. "UI.lua"))()(Config, ESP, MiddleClick, Aimbot)

ESP.Initialize()
MiddleClick.Initialize()
Aimbot.Initialize()

print("[Skull Hub] Script Loaded Successfully!")
