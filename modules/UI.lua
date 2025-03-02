return function(Config, ESP)
    local CensuraDev = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/Censura/main/CensuraDev.lua"))()
    local UI = CensuraDev.new("DeadRails ESP")
    
    UI:CreateToggle("Enable ESP", Config.Enabled, function(state)
        Config.Enabled = state
        if not state then
            ESP.Cleanup()
        end
    end)
    
    UI:CreateSlider("Max Distance", 100, 2000, Config.MaxDistance, function(value)
        Config.MaxDistance = value
    end)
    
    return UI
end
