-- modules/UI.lua
return function(Config, ESP, Clusters)
    local CensuraDev = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/Censura/main/CensuraDev.lua"))()
    local UI = CensuraDev.new("DeadRails ESP")
    
    -- ESP Controls
    UI:CreateToggle("Enable ESP", Config.Enabled, function(state)
        Config.Enabled = state
        if state then 
            ESP.ScanForHumanoids() 
        else 
            ESP.Cleanup()
            Clusters.Cleanup()
        end
    end)
    
    UI:CreateToggle("Show Info", Config.ShowInfo, function(state)
        Config.ShowInfo = state
    end)
    
    UI:CreateSlider("Max Distance", 100, 2000, Config.MaxDistance, function(value)
        Config.MaxDistance = value
    end)
    
    UI:CreateSlider("Detail Distance", 10, 100, Config.DetailDistance, function(value)
        Config.DetailDistance = value
    end)
    
    UI:CreateSlider("Cluster Distance", 5, 50, Config.ClusterDistance, function(value)
        Config.ClusterDistance = value
    end)
    
    -- Debug toggle if needed
    if Config.Debug ~= nil then
        UI:CreateToggle("Debug Mode", Config.Debug, function(state)
            Config.Debug = state
        end)
    end
    
    return UI
end
