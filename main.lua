-- DeadRails ESP System by LxckStxp
-- Main loader script

-- Load modules
local Config = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/DeadRails/main/modules/Config.lua"))()
local Utilities = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/DeadRails/main/modules/Utilities.lua"))()
local ESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/DeadRails/main/modules/ESP.lua"))()(Config, Utilities)
local Clusters = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/DeadRails/main/modules/Clusters.lua"))()(Config, Utilities, ESP)
local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/DeadRails/main/modules/UI.lua"))()(Config, ESP, Clusters)

-- Initialize the system
ESP.Initialize()
print("DeadRails ESP System initialized!")

-- Usage Example:
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/DeadRails/main/main.lua"))()
