-- DeadRails ESP System by LxckStxp
-- Density Management Module

return function(Config, Utilities, ESP)
    local Players = game:GetService("Players")
    local Player = Players.LocalPlayer
    local Camera = workspace.CurrentCamera
    
    local DensityManager = {
        lastUpdate = 0,
        focusPoint = nil,
        screenPositions = {}
    }
    
    -- Configuration for dynamic opacity
    Config.OpacitySettings = {
        MinOpacity = 0.1,        -- Minimum opacity for far/low priority items
        MaxOpacity = 1.0,        -- Maximum opacity for close/high priority items
        ScreenDensityRadius = 100, -- Pixel radius to check for density
        MaxDensity = 5,          -- Max number of ESPs in a screen area before reducing opacity
        PriorityItems = {        -- Items that should maintain higher visibility
            ["Gold"] = 10,
            ["Silver"] = 9,
            ["Weapon"] = 8,
            ["Ammo"] = 7,
            ["Fuel"] = 6,
            ["Medkit"] = 10,
            ["Bandage"] = 8
        },
        FocusRadius = 15        -- Studs radius around camera look vector to prioritize
    }
    
    -- Calculate screen position for an object
    function DensityManager.GetScreenPosition(position)
        local screenPos, onScreen = Camera:WorldToScreenPoint(position)
        return Vector2.new(screenPos.X, screenPos.Y), onScreen and screenPos.Z > 0
    end
    
    -- Determine priority score for an ESP object
    function DensityManager.GetPriorityScore(esp)
        -- Base priority starts with inverse of distance (closer = higher priority)
        local distance = Utilities.getDistance(esp.Position)
        local basePriority = math.clamp(1 - (distance / Config.MaxDistance), 0, 1)
        
        -- Additional priority based on item type
        local itemPriority = 0
        
        if esp.Type == "Item" then
            local itemName = esp.Object.Name:lower()
            
            -- Check for priority items
            for keyword, priority in pairs(Config.OpacitySettings.PriorityItems) do
                if itemName:find(keyword:lower()) then
                    itemPriority = priority / 10
                    break
                end
            end
            
            -- Check tags for valuable items
            for _, tag in ipairs(esp.Tags) do
                if tag:lower():find("valuable") then
                    itemPriority = math.max(itemPriority, 0.8)
                end
            end
        elseif esp.Type == "Humanoid" then
            -- Players and NPCs get high priority
            itemPriority = Utilities.isPlayerCharacter(esp.Object) and 0.9 or 0.7
        end
        
        -- Combine base distance priority with item type priority
        return (basePriority * 0.6) + (itemPriority * 0.4)
    end
    
    -- Check if an object is in focus (near where player is looking)
    function DensityManager.IsInFocus(position)
        if not DensityManager.focusPoint then return false end
        
        return (position - DensityManager.focusPoint).Magnitude <= Config.OpacitySettings.FocusRadius
    end
    
    -- Update focus point based on camera look vector
    function DensityManager.UpdateFocusPoint()
        local cameraPosition = Camera.CFrame.Position
        local lookVector = Camera.CFrame.LookVector
        
        -- Project focus point forward along look vector
        DensityManager.focusPoint = cameraPosition + (lookVector * 50)
    end
    
    -- Calculate screen density (how many ESP items are in a screen area)
    function DensityManager.GetScreenDensity(screenPos)
        local count = 0
        local radius = Config.OpacitySettings.ScreenDensityRadius
        
        for _, pos in pairs(DensityManager.screenPositions) do
            if (screenPos - pos).Magnitude <= radius then
                count = count + 1
            end
        end
        
        return count
    end
    
    -- Get opacity for an ESP element based on priority and density
    function DensityManager.GetDynamicOpacity(esp)
        local position = esp.Position
        local screenPos, onScreen = DensityManager.GetScreenPosition(position)
        
        -- If not on screen, use minimum opacity
        if not onScreen then return Config.OpacitySettings.MinOpacity end
        
        -- Calculate priority
        local priority = DensityManager.GetPriorityScore(esp)
        
        -- Check if in focus area
        local focusBonus = DensityManager.IsInFocus(position) and 0.3 or 0
        
        -- Get screen density factor
        local density = DensityManager.GetScreenDensity(screenPos)
        local densityFactor = math.clamp(1 - (density / Config.OpacitySettings.MaxDensity), 0, 1)
        
        -- Store screen position for density calculations
        table.insert(DensityManager.screenPositions, screenPos)
        
        -- Final opacity calculation
        local opacity = math.clamp(
            (priority * 0.5) + (densityFactor * 0.3) + focusBonus,
            Config.OpacitySettings.MinOpacity,
            Config.OpacitySettings.MaxOpacity
        )
        
        return opacity
    end
    
    -- Get dynamic size for ESP text based on distance and priority
    function DensityManager.GetDynamicTextSize(esp)
        local distance = Utilities.getDistance(esp.Position)
        local priority = DensityManager.GetPriorityScore(esp)
        
        -- Base size is 14, scale down with distance but up with priority
        local baseSize = 14
        local distanceFactor = math.clamp(1 - (distance / Config.MaxDistance), 0.5, 1)
        local priorityBonus = priority * 4 -- Up to 4 points bonus for high priority
        
        return math.floor(baseSize * distanceFactor + priorityBonus)
    end
    
    -- Update all ESP visuals based on density management
    function DensityManager.Update()
        -- Only update periodically to improve performance
        if DensityManager.lastUpdate and tick() - DensityManager.lastUpdate < 0.2 then
            return
        end
        DensityManager.lastUpdate = tick()
        
        -- Skip if ESP is disabled
        if not Config.Enabled then return end
        
        -- Reset screen positions
        DensityManager.screenPositions = {}
        
        -- Update focus point
        DensityManager.UpdateFocusPoint()
        
        -- Process all ESP objects
        for _, esp in pairs(ESP.Items) do
            if esp.Object and esp.Object.Parent then
                local opacity = DensityManager.GetDynamicOpacity(esp)
                local textSize = DensityManager.GetDynamicTextSize(esp)
                
                -- Apply dynamic settings
                esp.Highlight.FillTransparency = 1 - opacity * 0.3 -- Convert opacity to transparency
                esp.Highlight.OutlineTransparency = 1 - opacity * 0.7
                esp.InfoLabel.TextTransparency = 1 - opacity
                esp.InfoLabel.TextStrokeTransparency = 1 - opacity * 0.7
                esp.InfoLabel.TextSize = textSize
            end
        end
        
        for _, esp in pairs(ESP.Humanoids) do
            if esp.Object and esp.Object.Parent then
                local opacity = DensityManager.GetDynamicOpacity(esp)
                local textSize = DensityManager.GetDynamicTextSize(esp)
                
                -- Apply dynamic settings
                esp.Highlight.FillTransparency = 1 - opacity * 0.3
                esp.Highlight.OutlineTransparency = 1 - opacity * 0.7
                esp.InfoLabel.TextTransparency = 1 - opacity
                esp.InfoLabel.TextStrokeTransparency = 1 - opacity * 0.7
                esp.InfoLabel.TextSize = textSize
            end
        end
    end
    
    -- Modify ESP.Update to include density management
    local originalUpdate = ESP.Update
    ESP.Update = function()
        originalUpdate()
        DensityManager.Update()
    end    
    
    return DensityManager
end
