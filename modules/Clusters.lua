-- DeadRails ESP System by LxckStxp
-- Clusters Module

return function(Config, Utilities, ESP)
    local Clusters = {
        Active = {}
    }
    
    -- Create a cluster
    function Clusters.Create(position, type, count)
        -- Create anchor part for the cluster
        local part = Instance.new("Part")
        part.Anchored = true
        part.CanCollide = false
        part.Transparency = 1
        part.Position = position
        part.Parent = workspace
        
        -- Create GUI elements
        local billboard = Instance.new("BillboardGui")
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.Adornee = part
        billboard.AlwaysOnTop = true
        billboard.Parent = game.CoreGui
        
        local infoLabel = Instance.new("TextLabel")
        infoLabel.Size = UDim2.new(1, 0, 1, 0)
        infoLabel.BackgroundTransparency = 1
        infoLabel.TextStrokeTransparency = 0.5
        infoLabel.TextSize = 14
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
            end,
            
            Destroy = function(self)
                Utilities.safeDestroy(self.Part)
                Utilities.safeDestroy(self.Billboard)
            end
        }
        
        return cluster
    end
    
    -- Update all clusters
    function Clusters.Update()
        -- Clean up old clusters
        for id, cluster in pairs(Clusters.Active) do
            cluster:Destroy()
            Clusters.Active[id] = nil
        end
        
        if not Config.Enabled or not game.Players.LocalPlayer.Character or 
           not game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then 
            return 
        end
        
        -- Reset clustering flags
        for _, esp in pairs(ESP.Items) do esp.InCluster = false end
        for _, esp in pairs(ESP.Humanoids) do esp.InCluster = false end
        
        -- Process items for clustering
        local itemClusters = {}
        local processedItems = {}
        
        for object, esp in pairs(ESP.Items) do
            if object and object.Parent and not processedItems[object] then
                local distance = Utilities.getDistance(esp.Position)
                
                if distance <= Config.DetailDistance then
                    esp.InCluster = false
                else
                    -- Find nearby items to cluster
                    local cluster = {esp}
                    processedItems[object] = true
                    
                    for otherObject, otherEsp in pairs(ESP.Items) do
                        if otherObject and otherObject.Parent and not processedItems[otherObject] and otherObject ~= object then
                            if (esp.Position - otherEsp.Position).Magnitude <= Config.ClusterDistance then
                                table.insert(cluster, otherEsp)
                                processedItems[otherObject] = true
                            end
                        end
                    end
                    
                    -- Create cluster if multiple items found
                    if #cluster > 1 then
                        local avgPos = Vector3.new(0, 0, 0)
                        for _, clusterEsp in ipairs(cluster) do
                            avgPos = avgPos + clusterEsp.Position
                            clusterEsp.InCluster = true
                        end
                        avgPos = avgPos / #cluster
                        
                        local id = "Item_" .. tostring(avgPos)
                        itemClusters[id] = {position = avgPos, count = #cluster, entities = cluster}
                    end
                end
            end
        end
        
        -- Process humanoids for clustering
        local npcClusters = {}
        local playerClusters = {}
        local processedHumanoids = {}
        
        for object, esp in pairs(ESP.Humanoids) do
            if object and object.Parent and not processedHumanoids[object] then
                local distance = Utilities.getDistance(esp.Position)
                local player = Utilities.isPlayerCharacter(object)
                local clusterType = player and "Player" or "Humanoid"
                
                if distance <= Config.DetailDistance then
                    esp.InCluster = false
                else
                    -- Find nearby humanoids to cluster
                    local cluster = {esp}
                    processedHumanoids[object] = true
                    
                    for otherObject, otherEsp in pairs(ESP.Humanoids) do
                        if otherObject and otherObject.Parent and not processedHumanoids[otherObject] and otherObject ~= object then
                            -- Only cluster same types (players with players, NPCs with NPCs)
                            local otherIsPlayer = Utilities.isPlayerCharacter(otherObject)
                            if (player and otherIsPlayer) or (not player and not otherIsPlayer) then
                                if (esp.Position - otherEsp.Position).Magnitude <= Config.ClusterDistance then
                                    table.insert(cluster, otherEsp)
                                    processedHumanoids[otherObject] = true
                                end
                            end
                        end
                    end
                    
                    -- Create cluster if multiple humanoids found
                    if #cluster > 1 then
                        local avgPos = Vector3.new(0, 0, 0)
                        for _, clusterEsp in ipairs(cluster) do
                            avgPos = avgPos + clusterEsp.Position
                            clusterEsp.InCluster = true
                        end
                        avgPos = avgPos / #cluster
                        
                        local id = clusterType .. "_" .. tostring(avgPos)
                        if player then
                            playerClusters[id] = {position = avgPos, count = #cluster, entities = cluster}
                        else
                            npcClusters[id] = {position = avgPos, count = #cluster, entities = cluster}
                        end
                    end
                end
            end
        end
        
        -- Create item clusters
        for id, data in pairs(itemClusters) do
            Clusters.Active[id] = Clusters.Create(data.position, "Item", data.count)
            Clusters.Active[id].Entities = data.entities
            Clusters.Active[id]:Update(data.position, data.count)
        end
        
        -- Create NPC clusters
        for id, data in pairs(npcClusters) do
            Clusters.Active[id] = Clusters.Create(data.position, "Humanoid", data.count)
            Clusters.Active[id].Entities = data.entities
            Clusters.Active[id]:Update(data.position, data.count)
        end
        
        -- Create player clusters
        for id, data in pairs(playerClusters) do
            Clusters.Active[id] = Clusters.Create(data.position, "Player", data.count)
            Clusters.Active[id].Entities = data.entities
            Clusters.Active[id]:Update(data.position, data.count)
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
    
    return Clusters
end
