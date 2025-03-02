-- DeadRails ESP System by LxckStxp
-- Enhanced Clusters Module

return function(Config, Utilities, ESP)
    local Players = game:GetService("Players")
    local Player = Players.LocalPlayer
    
    local Clusters = {
        Active = {},
        lastUpdate = 0
    }
    
    -- Determine the most common item type in a cluster
    function Clusters.GetMostCommonItemType(items)
        local typeCounts = {}
        local highestCount = 0
        local mostCommonType = "Item"
        
        for _, esp in ipairs(items) do
            local itemName = esp.Object.Name
            
            -- Clean up item name (remove numbers, underscores, etc.)
            local cleanName = itemName:gsub("%d+", ""):gsub("_", " "):gsub("^%s*(.-)%s*$", "%1")
            
            -- Skip if the name is too long or too short
            if #cleanName > 3 and #cleanName < 15 then
                typeCounts[cleanName] = (typeCounts[cleanName] or 0) + 1
                
                if typeCounts[cleanName] > highestCount then
                    highestCount = typeCounts[cleanName]
                    mostCommonType = cleanName
                end
            end
        end
        
        return mostCommonType
    end
    
    -- Function to determine the dominant color in a cluster
    function Clusters.GetDominantColor(entities)
        local colorCounts = {}
        local highestCount = 0
        local dominantColor = Config.Colors.Default
        
        for _, esp in ipairs(entities) do
            -- Get the highlight color
            local color = esp.Highlight.FillColor
            
            -- Convert to string for table key
            local colorStr = tostring(color)
            colorCounts[colorStr] = (colorCounts[colorStr] or 0) + 1
            
            if colorCounts[colorStr] > highestCount then
                highestCount = colorCounts[colorStr]
                dominantColor = color
            end
        end
        
        return dominantColor
    end
    
    -- Create a cluster with x-ray visibility
    function Clusters.Create(position, type, count)
        -- Create anchor part for the cluster
        local part = Instance.new("Part")
        part.Anchored = true
        part.CanCollide = false
        part.Transparency = 1
        part.Size = Vector3.new(1, 1, 1)
        part.Position = position
        part.Name = "ClusterAnchor_" .. type
        part.CanQuery = false
        part.Parent = workspace
        
        -- Create GUI elements with improved visibility
        local billboard = Instance.new("BillboardGui")
        billboard.Size = UDim2.new(0, 250, 0, 60)
        billboard.StudsOffset = Vector3.new(0, 4, 0)
        billboard.Adornee = part
        billboard.AlwaysOnTop = true
        billboard.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        billboard.Active = true
        billboard.LightInfluence = 0
        billboard.Parent = game.CoreGui
        
        local infoLabel = Instance.new("TextLabel")
        infoLabel.Size = UDim2.new(1, 0, 1, 0)
        infoLabel.BackgroundTransparency = 1
        infoLabel.TextStrokeTransparency = 0.3
        infoLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        infoLabel.TextSize = 16
        infoLabel.Font = Enum.Font.SourceSansBold
        infoLabel.Parent = billboard
        
        -- Set color based on type
        local defaultColor
        if type == "Item" then defaultColor = Config.Colors.Default
        elseif type == "Player" then defaultColor = Config.Colors.Player
        else defaultColor = Config.Colors.NPC end
        
        infoLabel.TextColor3 = defaultColor
        
        -- Create cluster object
        local cluster = {
            Part = part,
            Billboard = billboard,
            InfoLabel = infoLabel,
            Position = position,
            Type = type,
            Count = count,
            Entities = {},
            
            Update = function(self, newPosition, newCount, itemType, color)
                self.Position = newPosition
                self.Part.Position = newPosition
                self.Count = newCount
                
                -- Update color if provided
                if color then
                    self.InfoLabel.TextColor3 = color
                end
                
                local distance = Utilities.getDistance(self.Position)
                if distance > Config.MaxDistance then
                    self.Billboard.Enabled = false
                    return
                end
                
                self.Billboard.Enabled = true
                
                -- Use specific item type if provided, otherwise use generic type
                local displayText = itemType or self.Type
                if self.Type == "Humanoid" then displayText = "Enemy" end
                
                self.InfoLabel.Text = displayText .. " (x" .. self.Count .. ")\n[" .. math.floor(distance + 0.5) .. "m]"
            end,
            
            Destroy = function(self)
                Utilities.safeDestroy(self.Part)
                Utilities.safeDestroy(self.Billboard)
            end
        }
        
        return cluster
    end
    
    -- Process items for clustering
    function Clusters.ProcessItems(playerPos)
        local itemClusters = {}
        local processedItems = {}
        
        -- First pass: identify potential cluster centers
        local clusterCenters = {}
        for object, esp in pairs(ESP.Items) do
            if object and object.Parent and not processedItems[object] then
                local distance = Utilities.getDistance(esp.Position)
                
                if distance > Config.DetailDistance then
                    -- Count nearby items to find cluster centers
                    local nearbyCount = 0
                    for otherObject, otherEsp in pairs(ESP.Items) do
                        if otherObject and otherObject.Parent and otherObject ~= object then
                            local distBetween = (esp.Position - otherEsp.Position).Magnitude
                            if distBetween <= Config.ClusterDistance then
                                nearbyCount = nearbyCount + 1
                            end
                        end
                    end
                    
                    if nearbyCount >= 2 then
                        table.insert(clusterCenters, {
                            object = object,
                            esp = esp,
                            nearbyCount = nearbyCount
                        })
                    end
                end
            end
        end
        
        -- Sort cluster centers by number of nearby items
        table.sort(clusterCenters, function(a, b)
            return a.nearbyCount > b.nearbyCount
        end)
        
        -- Second pass: create clusters from the centers
        for _, center in ipairs(clusterCenters) do
            local object = center.object
            local esp = center.esp
            
            if not processedItems[object] then
                local cluster = {esp}
                processedItems[object] = true
                
                -- Find all nearby items
                for otherObject, otherEsp in pairs(ESP.Items) do
                    if otherObject and otherObject.Parent and not processedItems[otherObject] and otherObject ~= object then
                        local distBetween = (esp.Position - otherEsp.Position).Magnitude
                        if distBetween <= Config.ClusterDistance then
                            table.insert(cluster, otherEsp)
                            processedItems[otherObject] = true
                        end
                    end
                end
                
                -- Only create cluster if we have multiple items
                if #cluster > 1 then
                    -- Calculate average position
                    local avgPos = Vector3.new(0, 0, 0)
                    for _, clusterEsp in ipairs(cluster) do
                        avgPos = avgPos + clusterEsp.Position
                        
                        -- IMPORTANT: Don't disable individual highlights
                        -- Only set InCluster flag for text label purposes
                        clusterEsp.InCluster = true
                        
                        -- Keep highlight enabled
                        clusterEsp.Highlight.Enabled = true
                        
                        -- Only disable the billboard for clustered items
                        clusterEsp.Billboard.Enabled = false
                    end
                    avgPos = avgPos / #cluster
                    
                    -- Determine most common item type
                    local itemType = Clusters.GetMostCommonItemType(cluster)
                    
                    -- Get dominant color
                    local dominantColor = Clusters.GetDominantColor(cluster)
                    
                    -- Create unique ID for this cluster
                    local id = "Item_" .. tostring(math.floor(avgPos.X)) .. "_" .. 
                               tostring(math.floor(avgPos.Y)) .. "_" .. 
                               tostring(math.floor(avgPos.Z))
                    
                    itemClusters[id] = {
                        position = avgPos, 
                        count = #cluster, 
                        entities = cluster,
                        itemType = itemType,
                        color = dominantColor
                    }
                end
            end
        end
        
        -- Create item clusters
        for id, data in pairs(itemClusters) do
            Clusters.Active[id] = Clusters.Create(data.position, "Item", data.count)
            Clusters.Active[id].Entities = data.entities
            Clusters.Active[id]:Update(data.position, data.count, data.itemType, data.color)
        end
    end
    
    -- Process humanoids for clustering
    function Clusters.ProcessHumanoids(playerPos)
        local npcClusters = {}
        local playerClusters = {}
        local processedHumanoids = {}
        
        -- First identify potential cluster centers
        local npcCenters = {}
        local playerCenters = {}
        
        for object, esp in pairs(ESP.Humanoids) do
            if object and object.Parent and not processedHumanoids[object] then
                local distance = Utilities.getDistance(esp.Position)
                
                if distance > Config.DetailDistance then
                    local isPlayer = Utilities.isPlayerCharacter(object)
                    local nearbyCount = 0
                    
                    -- Count nearby humanoids of same type
                    for otherObject, otherEsp in pairs(ESP.Humanoids) do
                        if otherObject and otherObject.Parent and otherObject ~= object then
                            local otherIsPlayer = Utilities.isPlayerCharacter(otherObject)
                            if (isPlayer and otherIsPlayer) or (not isPlayer and not otherIsPlayer) then
                                local distBetween = (esp.Position - otherEsp.Position).Magnitude
                                if distBetween <= Config.ClusterDistance then
                                    nearbyCount = nearbyCount + 1
                                end
                            end
                        end
                    end
                    
                    -- If this humanoid has multiple nearby humanoids, consider it a cluster center
                    if nearbyCount >= 2 then
                        local center = {
                            object = object,
                            esp = esp,
                            nearbyCount = nearbyCount
                        }
                        
                        if isPlayer then
                            table.insert(playerCenters, center)
                        else
                            table.insert(npcCenters, center)
                        end
                    end
                end
            end
        end
        
        -- Sort centers by number of nearby humanoids
        table.sort(npcCenters, function(a, b) return a.nearbyCount > b.nearbyCount end)
        table.sort(playerCenters, function(a, b) return a.nearbyCount > b.nearbyCount end)
        
        -- Process NPC clusters
        for _, center in ipairs(npcCenters) do
            local object = center.object
            local esp = center.esp
            
            if not processedHumanoids[object] then
                local cluster = {esp}
                processedHumanoids[object] = true
                
                for otherObject, otherEsp in pairs(ESP.Humanoids) do
                    if otherObject and otherObject.Parent and not processedHumanoids[otherObject] and otherObject ~= object then
                        -- Only cluster NPCs with NPCs
                        if not Utilities.isPlayerCharacter(otherObject) then
                            local distBetween = (esp.Position - otherEsp.Position).Magnitude
                            if distBetween <= Config.ClusterDistance then
                                table.insert(cluster, otherEsp)
                                processedHumanoids[otherObject] = true
                            end
                        end
                    end
                end
                
                -- Create cluster if multiple NPCs
                if #cluster > 1 then
                    local avgPos = Vector3.new(0, 0, 0)
                    for _, clusterEsp in ipairs(cluster) do
                        avgPos = avgPos + clusterEsp.Position
                        
                        -- Only set InCluster flag for text label purposes
                        clusterEsp.InCluster = true
                        
                        -- Keep highlight enabled
                        clusterEsp.Highlight.Enabled = true
                        
                        -- Only disable the billboard
                        clusterEsp.Billboard.Enabled = false
                    end
                    avgPos = avgPos / #cluster
                    
                    -- Get dominant color
                    local dominantColor = Clusters.GetDominantColor(cluster)
                    
                    local id = "NPC_" .. tostring(math.floor(avgPos.X)) .. "_" .. 
                              tostring(math.floor(avgPos.Y)) .. "_" .. 
                              tostring(math.floor(avgPos.Z))
                    
                    npcClusters[id] = {
                        position = avgPos, 
                        count = #cluster, 
                        entities = cluster,
                        color = dominantColor
                    }
                end
            end
        end
        
        -- Process Player clusters
        for _, center in ipairs(playerCenters) do
            local object = center.object
            local esp = center.esp
            
            if not processedHumanoids[object] then
                local cluster = {esp}
                processedHumanoids[object] = true
                
                for otherObject, otherEsp in pairs(ESP.Humanoids) do
                    if otherObject and otherObject.Parent and not processedHumanoids[otherObject] and otherObject ~= object then
                        -- Only cluster players with players
                        if Utilities.isPlayerCharacter(otherObject) then
                            local distBetween = (esp.Position - otherEsp.Position).Magnitude
                            if distBetween <= Config.ClusterDistance then
                                table.insert(cluster, otherEsp)
                                processedHumanoids[otherObject] = true
                            end
                        end
                    end
                end
                
                -- Create cluster if multiple players
                if #cluster > 1 then
                    local avgPos = Vector3.new(0, 0, 0)
                    for _, clusterEsp in ipairs(cluster) do
                        avgPos = avgPos + clusterEsp.Position
                        
                        -- Only set InCluster flag for text label purposes
                        clusterEsp.InCluster = true
                        
                        -- Keep highlight enabled
                        clusterEsp.Highlight.Enabled = true
                        
                        -- Only disable the billboard
                        clusterEsp.Billboard.Enabled = false
                    end
                    avgPos = avgPos / #cluster
                    
                    -- Get dominant color
                    local dominantColor = Clusters.GetDominantColor(cluster)
                    
                    local id = "Player_" .. tostring(math.floor(avgPos.X)) .. "_" .. 
                              tostring(math.floor(avgPos.Y)) .. "_" .. 
                              tostring(math.floor(avgPos.Z))
                    
                    playerClusters[id] = {
                        position = avgPos, 
                        count = #cluster, 
                        entities = cluster,
                        color = dominantColor
                    }
                end
            end
        end
        
        -- Create NPC clusters
        for id, data in pairs(npcClusters) do
            Clusters.Active[id] = Clusters.Create(data.position, "Humanoid", data.count)
            Clusters.Active[id].Entities = data.entities
            Clusters.Active[id]:Update(data.position, data.count, nil, data.color)
        end
        
        -- Create player clusters
        for id, data in pairs(playerClusters) do
            Clusters.Active[id] = Clusters.Create(data.position, "Player", data.count)
            Clusters.Active[id].Entities = data.entities
            Clusters.Active[id]:Update(data.position, data.count, nil, data.color)
        end
    end
    
    -- Update all clusters
    function Clusters.Update()
        -- Only update clusters periodically to improve performance
        if Clusters.lastUpdate and tick() - Clusters.lastUpdate < (Config.ClusterRefreshRate or 0.5) then
            return
        end
        Clusters.lastUpdate = tick()
        
        -- Clean up old clusters
        for id, cluster in pairs(Clusters.Active) do
            cluster:Destroy()
            Clusters.Active[id] = nil
        end
        
        if not Config.Enabled or not Player.Character or 
           not Player.Character:FindFirstChild("HumanoidRootPart") then 
            return 
        end
        
        local playerPos = Player.Character.HumanoidRootPart.Position
        
        -- Reset clustering flags
        for _, esp in pairs(ESP.Items) do 
            esp.InCluster = false
            esp.Billboard.Enabled = true
        end
        
        for _, esp in pairs(ESP.Humanoids) do 
            esp.InCluster = false
            esp.Billboard.Enabled = true
        end
        
        -- Process items and humanoids
        Clusters.ProcessItems(playerPos)
        Clusters.ProcessHumanoids(playerPos)
        
        -- Limit visible clusters if needed
        local maxVisible = Config.MaxClustersVisible or 15
        local visibleCount = 0
        for id, cluster in pairs(Clusters.Active) do
            visibleCount = visibleCount + 1
            if visibleCount > maxVisible then
                cluster.Billboard.Enabled = false
            end
        end
    end
    
    -- Clean up all clusters
    function Clusters.Cleanup()
        for id, cluster in pairs(Clusters.Active) do
            cluster:Destroy()
            Clusters.Active[id] = nil
        end
    end
    
    -- Force refresh clustering
    function Clusters.ForceRefresh()
        Clusters.Cleanup()
        Clusters.Update()
    end
    
    -- Add update hook to ESP update loop
    local originalUpdate = ESP.Update
    ESP.Update = function()
        originalUpdate()
        Clusters.Update()
    end
    
    -- Initialize default config values if not set
    if not Config.ClusterRefreshRate then Config.ClusterRefreshRate = 0.5 end
    if not Config.MaxClustersVisible then Config.MaxClustersVisible = 15 end
    
    return Clusters
end
