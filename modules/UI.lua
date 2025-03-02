return function(Config, ESP)
    local CensuraDev = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/Censura/main/CensuraDev.lua"))()
    local UI = CensuraDev.new("DeadRails ESP")
    
    -- Toggle ESP
    UI:CreateToggle("Enable ESP", Config.Enabled, function(state)
        Config.Enabled = state
        if not state then
            ESP.Cleanup()
        end
    end)
    
    -- Max Distance Slider
    UI:CreateSlider("Max Distance", 100, 2000, Config.MaxDistance, function(value)
        Config.MaxDistance = value
    end)
    
    -- Toggle Health Bars
    Config.ShowHealthBars = true -- Default to enabled
    UI:CreateToggle("Show Health Bars", Config.ShowHealthBars, function(state)
        Config.ShowHealthBars = state
    end)
    
    -- Info Button
    UI:CreateButton("Info", function()
        -- Force UI refresh to ensure visibility (workaround for some executors)
        UI:CreateToggle("Dummy", true, function() end)
        local info = Instance.new("ScreenGui")
        info.Parent = game.CoreGui
        local frame = Instance.new("Frame", info)
        frame.Size = UDim2.new(0, 200, 0, 100)
        frame.Position = UDim2.new(0.5, -100, 0.5, -50)
        frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        frame.BackgroundTransparency = 0.2
        local corner = Instance.new("UICorner", frame)
        corner.CornerRadius = UDim.new(0, 5)
        local text = Instance.new("TextLabel", frame)
        text.Size = UDim2.new(1, -10, 1, -10)
        text.Position = UDim2.new(0, 5, 0, 5)
        text.BackgroundTransparency = 1
        text.Text = "Toggle ESP: RightAlt\nAdjust Distance: Slider\nHealth Bars: Toggle"
        text.TextColor3 = Color3.fromRGB(255, 255, 255)
        text.TextSize = 14
        text.Font = Enum.Font.Gotham
        text.TextWrapped = true
        text.TextYAlignment = Enum.TextYAlignment.Top
        -- Auto-close after 5 seconds
        task.delay(5, function() info:Destroy() end)
    end)
    
    return UI
end
