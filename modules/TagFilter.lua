-- DeadRails ESP System by LxckStxp
-- Tag Filtering Module

return function(Config, Utilities, ESP)
    local TagFilter = {
        ActiveTags = {},
        EnemyFilters = {}
    }
    
    -- Available item tags in the game
    TagFilter.AvailableTags = {
        "Fuel",
        "Valuable",
        "Corpse",
        "Weapon",
        "Ammo"
    }
    
    -- Enemy types in the game
    TagFilter.EnemyTypes = {
        "Zombie",
        "Walker",
        "Runner",
        "Vampire",
        "Outlaw",
        "RifleOutlaw",
        "Wolf",
        "Warewolf",
        "Banker"
    }
    
    -- Toggle a specific item tag filter
    function TagFilter.ToggleTag(tag)
        if TagFilter.ActiveTags[tag] then
            TagFilter.ActiveTags[tag] = nil
        else
            TagFilter.ActiveTags[tag] = true
        end
        
        -- Apply the filters
        TagFilter.ApplyFilters()
        
        return TagFilter.ActiveTags[tag] ~= nil -- Return the new state
    end
    
    -- Toggle a specific enemy type filter
    function TagFilter.ToggleEnemy(enemyType)
        if TagFilter.EnemyFilters[enemyType] then
            TagFilter.EnemyFilters[enemyType] = nil
        else
            TagFilter.EnemyFilters[enemyType] = true
        end
        
        -- Apply the filters
        TagFilter.ApplyFilters()
        
        return TagFilter.EnemyFilters[enemyType] ~= nil -- Return the new state
    end
    
    -- Check if an item matches the active filters
    function TagFilter.ItemMatchesFilter(esp)
        -- If no filters are active, show everything
        local hasActiveItemFilters = false
        for _ in pairs(TagFilter.ActiveTags) do
            hasActiveItemFilters = true
            break
        end
        
        if not hasActiveItemFilters then
            return true
        end
        
        -- Check if the item has any of the active tags
        for _, tag in ipairs(esp.Tags) do
            if TagFilter.ActiveTags[tag] then
                return true
            end
        end
        
        -- Also check the object name for tag keywords
        local itemName = esp.Object.Name:lower()
        for tag, _ in pairs(TagFilter.ActiveTags) do
            if itemName:find(tag:lower()) then
                return true
            end
        end
        
        return false
    end
    
    -- Check if an enemy matches the active filters
    function TagFilter.EnemyMatchesFilter(esp)
        -- If no enemy filters are active, show all enemies
        local hasActiveEnemyFilters = false
        for _ in pairs(TagFilter.EnemyFilters) do
            hasActiveEnemyFilters = true
            break
        end
        
        if not hasActiveEnemyFilters then
            return true
        end
        
        -- Check if the enemy type matches any active filters
        local enemyName = esp.Object.Name
        
        for enemyType, _ in pairs(TagFilter.EnemyFilters) do
            if enemyName:find(enemyType) then
                return true
            end
        end
        
        return false
    end
    
    -- Apply all active filters to ESP objects
    function TagFilter.ApplyFilters()
        -- Process items
        for _, esp in pairs(ESP.Items) do
            if esp.Object and esp.Object.Parent then
                local showItem = TagFilter.ItemMatchesFilter(esp)
                
                -- Set visibility based on filter
                esp.Highlight.Enabled = showItem and Config.Enabled
                esp.Billboard.Enabled = showItem and Config.Enabled and Config.ShowInfo
                
                -- Apply visual effect to filtered items (optional)
                if showItem then
                    -- Make filtered items more visible
                    esp.Highlight.OutlineColor = esp.Highlight.FillColor
                    esp.Highlight.OutlineTransparency = 0
                end
            end
        end
        
        -- Process humanoids (enemies)
        for _, esp in pairs(ESP.Humanoids) do
            if esp.Object and esp.Object.Parent then
                local showEnemy = TagFilter.EnemyMatchesFilter(esp)
                
                -- Set visibility based on filter
                esp.Highlight.Enabled = showEnemy and Config.Enabled
                esp.Billboard.Enabled = showEnemy and Config.Enabled and Config.ShowInfo
                
                -- Apply visual effect to filtered enemies (optional)
                if showEnemy then
                    -- Make filtered enemies more visible
                    esp.Highlight.OutlineTransparency = 0
                end
            end
        end
    end
    
    -- Hook into ESP update
    local originalUpdate = ESP.Update
    ESP.Update = function()
        originalUpdate()
        
        -- Apply filters after ESP updates
        if next(TagFilter.ActiveTags) or next(TagFilter.EnemyFilters) then
            TagFilter.ApplyFilters()
        end
    end
    
    -- Reset all filters
    function TagFilter.ResetFilters()
        TagFilter.ActiveTags = {}
        TagFilter.EnemyFilters = {}
        TagFilter.ApplyFilters()
    end
    
    -- Count items by tag
    function TagFilter.CountItemsByTag()
        local counts = {}
        
        -- Initialize counts
        for _, tag in ipairs(TagFilter.AvailableTags) do
            counts[tag] = 0
        end
        
        -- Count items with each tag
        for _, esp in pairs(ESP.Items) do
            if esp.Object and esp.Object.Parent then
                for _, tag in ipairs(esp.Tags) do
                    if counts[tag] then
                        counts[tag] = counts[tag] + 1
                    end
                end
                
                -- Also check name for tags
                local itemName = esp.Object.Name:lower()
                for _, tag in ipairs(TagFilter.AvailableTags) do
                    if itemName:find(tag:lower()) and #esp.Tags == 0 then
                        counts[tag] = counts[tag] + 1
                    end
                end
            end
        end
        
        return counts
    end
    
    -- Count enemies by type
    function TagFilter.CountEnemiesByType()
        local counts = {}
        
        -- Initialize counts
        for _, enemyType in ipairs(TagFilter.EnemyTypes) do
            counts[enemyType] = 0
        end
        
        -- Count enemies of each type
        for _, esp in pairs(ESP.Humanoids) do
            if esp.Object and esp.Object.Parent then
                local enemyName = esp.Object.Name
                
                for _, enemyType in ipairs(TagFilter.EnemyTypes) do
                    if enemyName:find(enemyType) then
                        counts[enemyType] = counts[enemyType] + 1
                        break
                    end
                end
            end
        end
        
        return counts
    end
    
    return TagFilter
end
