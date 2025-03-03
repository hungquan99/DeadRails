return function(Config, Utilities)
    local ESPConfig = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/DeadRails/main/modules/ESP/ESPConfig.lua"))()
    local ESPObject = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/DeadRails/main/modules/ESP/ESPObject.lua"))()(Config, Utilities, ESPConfig)
    local ESPManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/DeadRails/main/modules/ESP/ESPManager.lua"))()(Config, Utilities, ESPObject, ESPConfig)
    
    local ESP = {}
    
    -- Expose public interface from ESPManager
    ESP.Initialize = ESPManager.Initialize
    ESP.Cleanup = ESPManager.Cleanup
    ESP.Update = ESPManager.Update
    ESP.SetEnabled = ESPManager.SetEnabled
    ESP.IsEnabled = ESPManager.IsEnabled
    ESP.HandleToggleKey = ESPManager.HandleToggleKey
    
    return ESP
end
