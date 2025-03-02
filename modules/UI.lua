-- DeadRails ESP System by LxckStxp
-- UI Module with Tag Filtering Support

return function(Config, ESP, TagFilter, DensityManager)
    local CensuraDev = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/Censura/main/CensuraDev.lua"))()
    local UI = CensuraDev.new("DeadRails ESP")
    
    -- Main ESP Controls Section
    local mainSection = UI:CreateSection("ESP Settings")
    
    -- Enable/Disable ESP
    mainSection:CreateToggle("Enable ESP", Config.Enabled, function(state)
        Config.Enabled = state
        if state then 
            ESP.ScanForHumanoids() 
        else 
            ESP.Cleanup()
        end
    end)
    
    -- Show Information Toggle
    mainSection:CreateToggle("Show Info", Config.ShowInfo, function(state)
        Config.ShowInfo = state
    end)
    
    -- Distance Settings
    mainSection:CreateSlider("Max Distance", 100, 2000, Config.MaxDistance, function(value)
        Config.MaxDistance = value
    end)
    
    -- Density Management Section (if DensityManager is provided)
    if DensityManager then
        local densitySection = UI:CreateSection("Density Settings")
        
        densitySection:CreateSlider("Min Opacity", 0, 100, (Config.OpacitySettings.MinOpacity or 0.1) * 100, function(value)
            Config.OpacitySettings.MinOpacity = value / 100
        end)
        
        densitySection:CreateSlider("Screen Density Radius", 50, 200, Config.OpacitySettings.ScreenDensityRadius or 100, function(value)
            Config.OpacitySettings.ScreenDensityRadius = value
        end)
        
        densitySection:CreateSlider("Focus Radius", 5, 50, Config.OpacitySettings.FocusRadius or 15, function(value)
            Config.OpacitySettings.FocusRadius = value
        end)
    end
    
    -- Tag Filtering Section (if TagFilter is provided)
    if TagFilter then
        -- Item Filters Section
        local itemFilterSection = UI:CreateSection("Item Filters")
        local itemToggles = {}
        
        -- Get item counts by tag
        local itemCounts = TagFilter.CountItemsByTag()
        
        -- Create toggle for each item tag
        for _, tag in ipairs(TagFilter.AvailableTags) do
            local count = itemCounts[tag] or 0
            itemToggles[tag] = itemFilterSection:CreateToggle(tag .. " (" .. count .. ")", false, function(state)
                TagFilter.ToggleTag(tag)
            end)
        end
        
        -- Enemy Filter Section
        local enemyFilterSection = UI:CreateSection("Enemy Filters")
        local enemyToggles = {}
        
        -- Get enemy counts by type
        local enemyCounts = TagFilter.CountEnemiesByType()
        
        -- Create toggle for each enemy type
        for _, enemyType in ipairs(TagFilter.EnemyTypes) do
            local count = enemyCounts[enemyType] or 0
            if count > 0 then -- Only show enemy types that exist
                enemyToggles[enemyType] = enemyFilterSection:CreateToggle(enemyType .. " (" .. count .. ")", false, function(state)
                    TagFilter.ToggleEnemy(enemyType)
                end)
            end
        end
        
        -- Controls Section for filter actions
        local filterControlsSection = UI:CreateSection("Filter Controls")
        
        -- Reset filters button
        filterControlsSection:CreateButton("Reset All Filters", function()
            TagFilter.ResetFilters()
            
            -- Reset all toggle buttons
            for tag, toggle in pairs(itemToggles) do
                toggle:SetState(false)
            end
            
            for enemyType, toggle in pairs(enemyToggles) do
                toggle:SetState(false)
            end
        end)
        
        -- Refresh counts button
        filterControlsSection:CreateButton("Refresh Counts", function()
            -- Get updated counts
            local updatedItemCounts = TagFilter.CountItemsByTag()
            local updatedEnemyCounts = TagFilter.CountEnemiesByType()
            
            -- Update toggle labels
            for tag, toggle in pairs(itemToggles) do
                toggle:UpdateText(tag .. " (" .. (updatedItemCounts[tag] or 0) .. ")")
            end
            
            for enemyType, toggle in pairs(enemyToggles) do
                toggle:UpdateText(enemyType .. " (" .. (updatedEnemyCounts[enemyType] or 0) .. ")")
            end
        end)
    end
    
    -- Advanced Options Section
    local advancedSection = UI:CreateSection("Advanced Options")
    
    -- Debug Mode (if available)
    if Config.Debug ~= nil then
        advancedSection:CreateToggle("Debug Mode", Config.Debug, function(state)
            Config.Debug = state
        end)
    end
    
    -- Keybind Information
    local keybindInfo = advancedSection:CreateLabel("Keybinds:")
    keybindInfo:UpdateText("Keybinds:\n1-5: Item filters\n6-9: Enemy filters\nBackspace: Reset filters\nF1: Toggle ESP")
    
    -- Return the UI object for further customization if needed
    return UI
end
