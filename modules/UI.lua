-- DeadRails ESP System by LxckStxp
-- UI Module with Tag Filtering Support

return function(Config, ESP, TagFilter, DensityManager)
    local CensuraDev = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/Censura/main/CensuraDev.lua"))()
    local UI = CensuraDev.new("DeadRails ESP")
    
    -- Main ESP Controls
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
    
    -- Density Management Settings (if DensityManager is provided)
    if DensityManager then
        UI:CreateSlider("Min Opacity", 0, 100, (Config.OpacitySettings.MinOpacity or 0.1) * 100, function(value)
            Config.OpacitySettings.MinOpacity = value / 100
        end)
        
        UI:CreateSlider("Screen Density Radius", 50, 200, Config.OpacitySettings.ScreenDensityRadius or 100, function(value)
            Config.OpacitySettings.ScreenDensityRadius = value
        end)
        
        UI:CreateSlider("Focus Radius", 5, 50, Config.OpacitySettings.FocusRadius or 15, function(value)
            Config.OpacitySettings.FocusRadius = value
        end)
    end
    
    -- Tag Filtering Section (if TagFilter is provided)
    if TagFilter then
        -- Item Filters
        local itemToggles = {}
        
        -- Get item counts by tag
        local itemCounts = TagFilter.CountItemsByTag()
        
        -- Create toggle for each item tag
        for _, tag in ipairs(TagFilter.AvailableTags) do
            local count = itemCounts[tag] or 0
            itemToggles[tag] = UI:CreateToggle(tag .. " (" .. count .. ")", false, function(state)
                TagFilter.ToggleTag(tag)
            end)
        end
        
        -- Enemy Filters
        local enemyToggles = {}
        
        -- Get enemy counts by type
        local enemyCounts = TagFilter.CountEnemiesByType()
        
        -- Create toggle for each enemy type
        for _, enemyType in ipairs(TagFilter.EnemyTypes) do
            local count = enemyCounts[enemyType] or 0
            if count > 0 then -- Only show enemy types that exist
                enemyToggles[enemyType] = UI:CreateToggle(enemyType .. " (" .. count .. ")", false, function(state)
                    TagFilter.ToggleEnemy(enemyType)
                end)
            end
        end
        
        -- Filter control buttons
        UI:CreateButton("Reset All Filters", function()
            TagFilter.ResetFilters()
            
            -- Reset all toggle buttons
            for tag, toggle in pairs(itemToggles) do
                toggle:SetState(false)
            end
            
            for enemyType, toggle in pairs(enemyToggles) do
                toggle:SetState(false)
            end
        end)
        
        UI:CreateButton("Refresh Counts", function()
            -- Get updated counts
            local updatedItemCounts = TagFilter.CountItemsByTag()
            local updatedEnemyCounts = TagFilter.CountEnemiesByType()
            
            -- Update toggle labels
            for tag, toggle in pairs(itemToggles) do
                toggle:SetText(tag .. " (" .. (updatedItemCounts[tag] or 0) .. ")")
            end
            
            for enemyType, toggle in pairs(enemyToggles) do
                toggle:SetText(enemyType .. " (" .. (updatedEnemyCounts[enemyType] or 0) .. ")")
            end
        end)
    end
    
    -- Debug Mode (if available)
    if Config.Debug ~= nil then
        UI:CreateToggle("Debug Mode", Config.Debug, function(state)
            Config.Debug = state
        end)
    end
    
    -- Example of how to use the UI
    UI:CreateButton("How to Use", function()
        local notification = Instance.new("ScreenGui")
        notification.Name = "ESPHelp"
        notification.Parent = game.CoreGui
        
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 300, 0, 150)
        frame.Position = UDim2.new(0.5, -150, 0.5, -75)
        frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        frame.BackgroundTransparency = 0.2
        frame.BorderSizePixel = 0
        frame.Parent = notification
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 5)
        corner.Parent = frame
        
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -20, 0, 30)
        title.Position = UDim2.new(0, 10, 0, 10)
        title.Text = "ESP Controls"
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.TextSize = 18
        title.Font = Enum.Font.GothamBold
        title.BackgroundTransparency = 1
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = frame
        
        local info = Instance.new("TextLabel")
        info.Size = UDim2.new(1, -20, 1, -50)
        info.Position = UDim2.new(0, 10, 0, 40)
        info.Text = "• 1-5: Toggle item filters\n• 6-9: Toggle enemy filters\n• Backspace: Reset all filters\n• F1: Toggle ESP"
        info.TextColor3 = Color3.fromRGB(220, 220, 220)
        info.TextSize = 14
        info.Font = Enum.Font.Gotham
        info.BackgroundTransparency = 1
        info.TextXAlignment = Enum.TextXAlignment.Left
        info.TextYAlignment = Enum.TextYAlignment.Top
        info.Parent = frame
        
        local close = Instance.new("TextButton")
        close.Size = UDim2.new(0, 80, 0, 25)
        close.Position = UDim2.new(0.5, -40, 1, -35)
        close.Text = "Close"
        close.TextColor3 = Color3.fromRGB(255, 255, 255)
        close.TextSize = 14
        close.Font = Enum.Font.GothamBold
        close.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        close.BackgroundTransparency = 0.5
        close.BorderSizePixel = 0
        close.Parent = frame
        
        local closeCorner = Instance.new("UICorner")
        closeCorner.CornerRadius = UDim.new(0, 4)
        closeCorner.Parent = close
        
        close.MouseButton1Click:Connect(function()
            notification:Destroy()
        end)
        
        -- Auto-close after 10 seconds
        task.delay(10, function()
            if notification.Parent then
                notification:Destroy()
            end
        end)
    end)
    
    return UI
end
