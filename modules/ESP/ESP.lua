return function(Config, Utilities)
    local ESPConfig = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/DeadRails/main/modules/ESP/ESPConfig.lua"))()
    local ESPObject = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/DeadRails/main/modules/ESP/ESPObject.lua"))()(Config, Utilities, ESPConfig)
    local ESPManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/DeadRails/main/modules/ESP/ESPManager.lua"))()(Config, Utilities, ESPObject, ESPConfig)
    
    local ESP = {}
    
    ESP.Initialize = ESPManager.Initialize
    ESP.Cleanup = ESPManager.Cleanup
    ESP.Update = ESPManager.Update
    
    return ESP
end
