return function(Config, ESP, MiddleClick, Aimbot)
    local CensuraDev = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/Censura/main/CensuraDev.lua"))()
    local UI = CensuraDev.new("DeadRails ESP")
    
    -- Toggle ESP Enable
    UI:CreateToggle("ESP Enable", Config.Enabled, function(state)
        Config.Enabled = state
        if state then
            ESP.Initialize()
            ESP.Update()
        else
            ESP.Cleanup()
        end
    end)
    
    -- Max Distance Slider
    UI:CreateSlider("Max Distance", 100, 2000, Config.MaxDistance, function(value)
        Config.MaxDistance = value
    end)
    
    -- Middle Click Utility Toggle
    UI:CreateToggle("Middle Click Utility", MiddleClick.Enabled, function(state)
        MiddleClick.Enabled = state
    end)
    
    -- Aimbot Toggle (with safe access and debug)
    local aimbotEnabled = (Aimbot and Aimbot.Enabled ~= nil) and Aimbot.Enabled or false
    UI:CreateToggle("Aimbot", aimbotEnabled, function(state)
        if Aimbot and Aimbot.Enabled ~= nil then
            Aimbot.Enabled = state
            print("Aimbot toggled to:", state)
        else
            warn("Aimbot module not loaded or Enabled property missing")
        end
    end)
    
    return UI
end
