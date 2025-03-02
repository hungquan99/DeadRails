-- DeadRails ESP System by LxckStxp
-- Main loader script

-- Load modules
local Config = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/DeadRails/main/modules/Config.lua"))()
local Utilities = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/DeadRails/main/modules/Utilities.lua"))()
local ESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/DeadRails/main/modules/ESP.lua"))()(Config, Utilities)
local DensityManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/DeadRails/main/modules/DensityManager.lua"))()(Config, Utilities, ESP)
local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/DeadRails/main/modules/UI.lua"))()(Config, ESP, DensityManager)

-- Initialize the system
ESP.Initialize()
print("DeadRails ESP System initialized with Dynamic Opacity!")
