return function(Config, ESP, MiddleClick)
    local CensuraDev = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/Censura/main/CensuraDev.lua"))()
    local UI = CensuraDev.new("DeadRails ESP")
    
    -- Toggle ESP (use ESPManager.SetEnabled for consistent state management)
    UI:CreateToggle("ESP Enable", Config.Enabled, function(state)
        ESP.SetEnabled(state) -- Use ESPManager.SetEnabled
    end)
    
    -- Max Distance Slider
    UI:CreateSlider("Max Distance", 100, 2000, Config.MaxDistance, function(value)
        Config.MaxDistance = value
    end)
    
    -- Middle Click Utility Toggle
    UI:CreateToggle("Middle Click Utility", MiddleClick.Enabled, function(state)
        MiddleClick.Enabled = state
    end)
    
    return UI
end
