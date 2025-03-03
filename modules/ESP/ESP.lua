return function(Config, Utilities)
    local ESPConfig = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/DeadRails/main/modules/ESPConfig.lua"))()
    local ESPObject = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/DeadRails/main/modules/ESPObject.lua"))()(Config, Utilities, ESPConfig)
    local ESPManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/DeadRails/main/modules/ESPManager.lua"))()(Config, Utilities, ESPObject, ESPConfig)
    
    local ESP = {}
    
    -- Expose public interface
    ESP.Initialize = ESPManager.Initialize
    ESP.Cleanup = ESPManager.Cleanup
    ESP.Update = ESPManager.Update
    
    return ESP
end
