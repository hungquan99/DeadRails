-- Load modules
local Config = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/DeadRails/main/modules/Config.lua"))()
local Utilities = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/DeadRails/main/modules/Utilities.lua"))()
local ESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/DeadRails/main/modules/ESP.lua"))()(Config, Utilities)
local DensityManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/DeadRails/main/modules/DensityManager.lua"))()(Config, Utilities, ESP)
local TagFilter = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/DeadRails/main/modules/TagFilter.lua"))()(Config, Utilities, ESP)

-- Initialize UI with all modules
local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/DeadRails/main/modules/UI.lua"))()(Config, ESP, TagFilter, DensityManager)

-- Initialize the ESP system
ESP.Initialize()
