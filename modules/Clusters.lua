-- Enhanced Clusters module with better debugging and fixed logic
return function(Config, Utilities, ESP)
    local Players = game:GetService("Players")
    local Player = Players.LocalPlayer
    
    local Clusters = {
        Active = {}
    }
    
    -- Create a cluster with improved visibility
    function Clusters.Create(position, type, count)
        -- Create anchor part for the cluster
        local part = Instance.new("Part")
        part.Anchored = true
        part.CanCollide = false
        part.Transparency = 1
        part.Size = Vector3.new(1, 1, 1)  -- Explicitly set size
        part.Position = position
        part.Name = "ClusterAnchor_" .. type
        part.Parent = workspace
        
        -- Add visual indicator for debugging (can be disabled later)
        local sphereAttachment = Instance.new("Attachment")
        sphereAttachment.Parent = part
        
        local sphere = Instance.new("SphereHandleAdornment")
        sphere.Radius = 1
        sphere.Color3 = type == "Item" and Config.Colors.Default or 
                       (type == "Player" and Config.Colors.Player or Config.Colors.NPC)
        sphere.Transparency = 0.7
        sphere.AlwaysOnTop = true
        sphere.Adornee = part
        sphere.Parent = part
        
        -- Create GUI elements with larger size
        local billboard = Instance.new("BillboardGui")
        billboard.Size = UDim2.new(0, 250, 0, 60)  -- Larger size
        billboard.StudsOffset = Vector3.new(0, 4, 0)  -- Higher offset
        billboard.Adornee = part
        billboard.AlwaysOnTop = true
        billboard.Parent = game.CoreGui
        
        local infoLabel = Instance.new("TextLabel")
        infoLabel.Size = UDim2.new(1, 0, 1, 0)
        infoLabel.BackgroundTransparency = 1
        infoLabel.TextStrokeTransparency = 0.3  -- Improved visibility
        infoLabel.TextSize = 16  -- Larger text
        infoLabel.Font = Enum.Font.SourceSansBold
        infoLabel.Parent = billboard
        
        -- Set color based on type
        local color
        if type == "Item" then color = Config.Colors.Default
        elseif type == "Player" then color = Config.Colors.Player
        else color = Config.Colors.NPC end
        
        infoLabel.TextColor3 = color
        
        -- Create cluster object
        local cluster = {
            Part = part,
            Sphere = sphere,
            Billboard = billboard,
            InfoLabel = infoLabel,
            Position = position,
            Type = type,
            Count = count,
            Entities = {},
            
            Update = function(self, newPosition, newCount)
                self.Position = newPosition
                self.Part.Position = newPosition
                self.Count = newCount
                
                local distance = Utilities.getDistance(self.Position)
                if distance > Config.MaxDistance then
                    self.Billboard.Enabled = false
                    return
                end
                
                self.Billboard.Enabled = true
                
                local typeText = self.Type
                if self.Type == "Humanoid" then typeText = "Enemy" end
                
                self.InfoLabel.Text = typeText .. " (x" .. self.Count .. ")\n[" .. math.floor(distance + 0.5) .. "m]"
                
                -- Update sphere size based on cluster size
                self.Sphere.Radius = math.min(3, 1 + (self.Count * 0.2))
            end,
            
            Destroy = function(self)
                Utilities.safeDestroy(self.Part)
                Utilities.safeDestroy(self.Billboard)
            end
        }
        
        return cluster
    end
    
    -- Update all clusters with improved clustering logic
    function Clusters.Update()
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
        for _, esp in pairs(ESP.Items) do esp.InCluster = false end
        for _, esp in pairs(ESP.Humanoids) do esp.InCluster = false end
        
        -- Enhanced clustering algorithm
        Clusters.ProcessItems(playerPos)
        Clusters.ProcessHumanoids(playerPos)
    end
    
    -- Process items for clustering with improved logic
    function Clusters.ProcessItems(playerPos)
        local itemClusters = {}
        local processedItems = {}
        
        -- First pass: identify potential cluster centers
        local clusterCenters = {}
        for object, esp in pairs(ESP.Items) do
            if object and object.Parent and not processedItems[object] then
                local distance = Utilities.getDistance(esp.Position)
                
                -- Skip items that are too close to player
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
                    
                    -- If this item has multiple nearby items, consider it a cluster center
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
        
        -- Sort cluster centers by number of nearby items (descending)
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
                        clusterEsp.InCluster = true
                    end
                    avgPos = avgPos / #cluster
                    
                    -- Create unique ID for this cluster
                    local id = "Item_" .. tostring(math.floor(avgPos.X)) .. "_" .. 
                               tostring(math.floor(avgPos.Y)) .. "_" .. 
                               tostring(math.floor(avgPos.Z))
                    
                    itemClusters[id] = {position = avgPos, count = #cluster, entities = cluster}
                end
            end
        end
        
        -- Create item clusters
        for id, data in pairs(itemClusters) do
            Clusters.Active[id] = Clusters.Create(data.position, "Item", data.count)
            Clusters.Active[id].Entities = data.entities
            Clusters.Active[id]:Update(data.position, data.count)
            
            -- Print debug info
            if Config.Debug then
                print("Created Item Cluster: " .. id .. " with " .. data.count .. " items")
            end
        end
    end
    
    -- Process humanoids for clustering with improved logic
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
                        clusterEsp.InCluster = true
                    end
                    avgPos = avgPos / #cluster
                    
                    local id = "NPC_" .. tostring(math.floor(avgPos.X)) .. "_" .. 
                              tostring(math.floor(avgPos.Y)) .. "_" .. 
                              tostring(math.floor(avgPos.Z))
                    
                    npcClusters[id] = {position = avgPos, count = #cluster, entities = cluster}
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
                        clusterEsp.InCluster = true
                    end
                    avgPos = avgPos / #cluster
                    
                    local id = "Player_" .. tostring(math.floor(avgPos.X)) .. "_" .. 
                              tostring(math.floor(avgPos.Y)) .. "_" .. 
                              tostring(math.floor(avgPos.Z))
                    
                    playerClusters[id] = {position = avgPos, count = #cluster, entities = cluster}
                end
            end
        end
        
        -- Create NPC clusters
        for id, data in pairs(npcClusters) do
            Clusters.Active[id] = Clusters.Create(data.position, "Humanoid", data.count)
            Clusters.Active[id].Entities = data.entities
            Clusters.Active[id]:Update(data.position, data.count)
            
            if Config.Debug then
                print("Created NPC Cluster: " .. id .. " with " .. data.count .. " NPCs")
            end
        end
        
        -- Create player clusters
        for id, data in pairs(playerClusters) do
            Clusters.Active[id] = Clusters.Create(data.position, "Player", data.count)
            Clusters.Active[id].Entities = data.entities
            Clusters.Active[id]:Update(data.position, data.count)
            
            if Config.Debug then
                print("Created Player Cluster: " .. id .. " with " .. data.count .. " players")
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
    
    -- Add update hook to ESP update loop
    local originalUpdate = ESP.Update
    ESP.Update = function()
        originalUpdate()
        Clusters.Update()
    end
    
    -- Debug function to verify clustering
    function Clusters.DebugInfo()
        local activeCount = 0
        for _ in pairs(Clusters.Active) do activeCount = activeCount + 1 end
        
        local itemCount = 0
        for _ in pairs(ESP.Items) do itemCount = itemCount + 1 end
        
        local humanoidCount = 0
        for _ in pairs(ESP.Humanoids) do humanoidCount = humanoidCount + 1 end
        
        return {
            ActiveClusters = activeCount,
            TotalItems = itemCount,
            TotalHumanoids = humanoidCount,
            ClusterDistance = Config.ClusterDistance,
            DetailDistance = Config.DetailDistance
        }
    end
    
    -- Force refresh clustering
    function Clusters.ForceRefresh()
        Clusters.Cleanup()
        Clusters.Update()
    end
    
    return Clusters
end
