-- DeadRails ESP System by LxckStxp
-- Main loader script

-- Load modules
local Config = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/DeadRails/main/modules/Config.lua"))()
local Utilities = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/DeadRails/main/modules/Utilities.lua"))()
local ESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/DeadRails/main/modules/ESP.lua"))()(Config, Utilities)
local DensityManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/DeadRails/main/modules/DensityManager.lua"))()(Config, Utilities, ESP)
local TagFilter = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/DeadRails/main/modules/TagFilter.lua"))()(Config, Utilities, ESP)

-- Initialize UI with all modules
local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/DeadRails/main/modules/UI.lua"))()(Config, ESP, TagFilter, DensityManager)

-- Initialize the system
ESP.Initialize()
print("DeadRails ESP System initialized!")

-- Set up keybinds
local UserInputService = game:GetService("UserInputService")

-- Quick filter keybinds
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    -- Toggle ESP with F1
    if input.KeyCode == Enum.KeyCode.F1 then
        Config.Enabled = not Config.Enabled
        if Config.Enabled then ESP.ScanForHumanoids() else ESP.Cleanup() end
    end
end)
