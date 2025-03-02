-- modules/UI.lua
return function(Config, ESP, DensityManager)
    local CensuraDev = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/Censura/main/CensuraDev.lua"))()
    local UI = CensuraDev.new("DeadRails ESP")
    
    -- ESP Controls
    UI:CreateToggle("Enable ESP", Config.Enabled, function(state)
        Config.Enabled = state
        if state then 
            ESP.ScanForHumanoids() 
        else 
            ESP.Cleanup()
        end
    end)
    
    UI:CreateToggle("Show Info", Config.ShowInfo, function(state)
        Config.ShowInfo = state
    end)
    
    UI:CreateSlider("Max Distance", 100, 2000, Config.MaxDistance, function(value)
        Config.MaxDistance = value
    end)
    
    -- Density Management Settings
    UI:CreateSlider("Min Opacity", 0, 100, Config.OpacitySettings.MinOpacity * 100, function(value)
        Config.OpacitySettings.MinOpacity = value / 100
    end)
    
    UI:CreateSlider("Screen Density Radius", 50, 200, Config.OpacitySettings.ScreenDensityRadius, function(value)
        Config.OpacitySettings.ScreenDensityRadius = value
    end)
    
    UI:CreateSlider("Focus Radius", 5, 50, Config.OpacitySettings.FocusRadius, function(value)
        Config.OpacitySettings.FocusRadius = value
    end)
    
    -- Debug toggle if needed
    if Config.Debug ~= nil then
        UI:CreateToggle("Debug Mode", Config.Debug, function(state)
            Config.Debug = state
        end)
    end
    
    return UI
end
