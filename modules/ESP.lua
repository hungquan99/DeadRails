-- DeadRails ESP System by LxckStxp
-- ESP Module

return function(Config, Utilities)
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local Player = Players.LocalPlayer
    
    local ESP = {
        Items = {},
        Humanoids = {},
        Connection = nil
    }
    
    -- Create ESP for an object
    function ESP.Create(object, espType)
        -- Create visual elements
        local highlight = Instance.new("Highlight")
        highlight.FillTransparency = 0.7
        highlight.OutlineTransparency = 0
        highlight.Adornee = object
        highlight.Parent = game.CoreGui
        
        local billboard = Instance.new("BillboardGui")
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.Adornee = object:IsA("Model") and (object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart")) or object
        billboard.AlwaysOnTop = true
        billboard.Parent = game.CoreGui
        
        local infoLabel = Instance.new("TextLabel")
        infoLabel.Size = UDim2.new(1, 0, 1, 0)
        infoLabel.BackgroundTransparency = 1
        infoLabel.TextStrokeTransparency = 0.5
        infoLabel.TextSize = 14
        infoLabel.Font = Enum.Font.SourceSansBold
        infoLabel.Parent = billboard
        
        -- Create ESP object
        local esp = {
            Highlight = highlight,
            Billboard = billboard,
            InfoLabel = infoLabel,
            Object = object,
            Type = espType,
            Position = Utilities.getPosition(object),
            InCluster = false,
            Tags = {},
            
            Update = function(self)
                -- Skip if in cluster or ESP disabled
                if self.InCluster or not Config.Enabled then
                    self.Highlight.Enabled = false
                    self.Billboard.Enabled = false
                    return
                end
                
                -- Update position
                self.Position = Utilities.getPosition(self.Object)
                
                -- Check distance
                local distance = Utilities.getDistance(self.Position)
                if distance > Config.MaxDistance then
                    self.Highlight.Enabled = false
                    self.Billboard.Enabled = false
                    return
                end
                
                -- Set color based on type
                self.Highlight.Enabled = true
                
                if self.Type == "Item" then
                    self.Tags = Utilities.getTags(object)
                    local color = Utilities.getColorFromTags(object, self.Tags, Config)
                    self.Highlight.FillColor = color
                    self.Highlight.OutlineColor = color
                    self.InfoLabel.TextColor3 = color
                else -- Humanoid
                    local player = Utilities.isPlayerCharacter(object)
                    local color = player and Config.Colors.Player or Config.Colors.NPC
                    self.Highlight.FillColor = color
                    self.Highlight.OutlineColor = color
                    self.InfoLabel.TextColor3 = color
                end
                
                -- Update info text
                if Config.ShowInfo then
                    self.Billboard.Enabled = true
                    local distText = math.floor(distance + 0.5) .. "m"
                    local infoText = object.Name .. " [" .. distText .. "]"
                    
                    -- Add tags for items
                    if self.Type == "Item" and #self.Tags > 0 then
                        infoText = infoText .. "\n" .. table.concat(self.Tags, " | ")
                    end
                    
                    -- Add health for humanoids
                    if self.Type == "Humanoid" then
                        local health = Utilities.getHealth(object)
                        infoText = infoText .. "\nHP: " .. math.floor(health.Current) .. "/" .. math.floor(health.Max)
                        
                        -- Add player name if applicable
                        local player = Utilities.isPlayerCharacter(object)
                        if player then
                            infoText = player.Name .. " [" .. distText .. "]\nHP: " .. math.floor(health.Current)
                        end
                    end
                    
                    self.InfoLabel.Text = infoText
                else
                    self.Billboard.Enabled = false
                end
            end,
            
            Destroy = function(self)
                Utilities.safeDestroy(self.Highlight)
                Utilities.safeDestroy(self.Billboard)
            end
        }
        
        return esp
    end
    
    -- Scan for humanoids in workspace
    function ESP.ScanForHumanoids()
        if not Config.Enabled then return end
        
        for _, instance in pairs(workspace:GetDescendants()) do
            if instance:IsA("Model") and instance:FindFirstChildOfClass("Humanoid") and
               Player.Character ~= instance and not ESP.Humanoids[instance] then
                ESP.Humanoids[instance] = ESP.Create(instance, "Humanoid")
            end
        end
    end
    
    -- Update all ESP objects
    function ESP.Update()
        -- Process items
        if workspace:FindFirstChild("RuntimeItems") and Config.Enabled then
            -- Add new items
            for _, item in pairs(workspace.RuntimeItems:GetChildren()) do
                if not ESP.Items[item] then
                    ESP.Items[item] = ESP.Create(item, "Item")
                end
            end
            
            -- Update and clean up items
            for item, esp in pairs(ESP.Items) do
                if item and item.Parent then
                    esp:Update()
                else
                    esp:Destroy()
                    ESP.Items[item] = nil
                end
            end
        end
        
        -- Scan for new humanoids periodically
        if tick() % 1 < 0.1 then
            ESP.ScanForHumanoids()
        end
        
        -- Update and clean up humanoids
        for character, esp in pairs(ESP.Humanoids) do
            if character and character.Parent then
                esp:Update()
            else
                esp:Destroy()
                ESP.Humanoids[character] = nil
            end
        end
    end
    
    -- Clean up ESP objects
    function ESP.Cleanup()
        for _, esp in pairs(ESP.Items) do esp:Destroy() end
        for _, esp in pairs(ESP.Humanoids) do esp:Destroy() end
        
        ESP.Items = {}
        ESP.Humanoids = {}
        
        if ESP.Connection then
            ESP.Connection:Disconnect()
            ESP.Connection = nil
        end
    end
    
    -- Initialize ESP system
    function ESP.Initialize()
        -- Set up event connections
        workspace.ChildAdded:Connect(function(child)
            if child:IsA("Model") and Config.Enabled then
                task.delay(0.1, function()
                    if child:FindFirstChildOfClass("Humanoid") and not ESP.Humanoids[child] then
                        ESP.Humanoids[child] = ESP.Create(child, "Humanoid")
                    end
                end)
            end
        end)
        
        -- Handle player joining
        Players.PlayerAdded:Connect(function(player)
            player.CharacterAdded:Connect(function(character)
                if Config.Enabled and not ESP.Humanoids[character] then
                    ESP.Humanoids[character] = ESP.Create(character, "Humanoid")
                end
            end)
        end)
        
        -- Initialize existing player characters
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= Player and player.Character and Config.Enabled then
                ESP.Humanoids[player.Character] = ESP.Create(player.Character, "Humanoid")
            end
            
            player.CharacterAdded:Connect(function(character)
                if Config.Enabled and not ESP.Humanoids[character] then
                    ESP.Humanoids[character] = ESP.Create(character, "Humanoid")
                end
            end)
        end
        
        -- Handle script termination
        Player.CharacterRemoving:Connect(function()
            ESP.Cleanup()
        end)
        
        -- Start the update loop
        ESP.Connection = RunService.RenderStepped:Connect(ESP.Update)
        
        -- Perform initial scan
        ESP.ScanForHumanoids()
    end
    
    return ESP
end
