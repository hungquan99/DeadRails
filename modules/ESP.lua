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
        local highlight = Instance.new("Highlight")
        highlight.FillTransparency = 0.8
        highlight.OutlineTransparency = 0.2 -- Slightly visible outline for clarity
        highlight.Adornee = object
        highlight.Parent = game.CoreGui
        
        local billboard = Instance.new("BillboardGui")
        billboard.Size = UDim2.new(0, 100, 0, 20)
        billboard.StudsOffset = Vector3.new(0, 2, 0)
        billboard.Adornee = object:IsA("Model") and (object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart")) or object
        billboard.AlwaysOnTop = true
        billboard.Parent = game.CoreGui
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.TextSize = 12
        label.Font = Enum.Font.SourceSansBold
        label.TextStrokeTransparency = 0.5 -- Add stroke for readability
        label.Parent = billboard
        
        local esp = {
            Highlight = highlight,
            Billboard = billboard,
            Label = label,
            Object = object,
            Type = espType,
            LastPosition = nil, -- Cache position for efficiency
            
            Update = function(self)
                if not Config.Enabled or not self.Object.Parent then
                    self.Highlight.Enabled = false
                    self.Billboard.Enabled = false
                    return
                end
                
                -- Update position only if necessary
                local position = Utilities.getPosition(self.Object)
                if not self.LastPosition or (position - self.LastPosition).Magnitude > 0.1 then
                    self.LastPosition = position
                else
                    position = self.LastPosition -- Reuse cached position
                end
                
                local distance = Utilities.getDistance(position)
                if distance > Config.MaxDistance then
                    self.Highlight.Enabled = false
                    self.Billboard.Enabled = false
                    return
                end
                
                self.Highlight.Enabled = true
                self.Billboard.Enabled = true
                
                -- Set color based on type
                local color
                if self.Type == "Item" then
                    color = Utilities.getItemColor(self.Object, Config)
                else -- Humanoid
                    color = Config.Colors[self.Type]
                end
                
                self.Highlight.FillColor = color
                self.Highlight.OutlineColor = color
                self.Label.TextColor3 = color
                self.Label.Text = string.format("%s [%dm]", self.Object.Name, math.floor(distance))
            end,
            
            Destroy = function(self)
                Utilities.safeDestroy(self.Highlight)
                Utilities.safeDestroy(self.Billboard)
            end
        }
        
        return esp
    end
    
    -- Update all ESP objects
    function ESP.Update()
        if not Config.Enabled then return end
        
        -- Items
        local runtimeItems = workspace:FindFirstChild("RuntimeItems")
        if runtimeItems then
            for _, item in pairs(runtimeItems:GetChildren()) do
                if not ESP.Items[item] then
                    ESP.Items[item] = ESP.Create(item, "Item")
                end
            end
        end
        
        for item, esp in pairs(ESP.Items) do
            if item.Parent then
                esp:Update()
            else
                esp:Destroy()
                ESP.Items[item] = nil
            end
        end
        
        -- Humanoids
        for _, humanoid in pairs(workspace:GetDescendants()) do
            if humanoid:IsA("Model") and humanoid:FindFirstChildOfClass("Humanoid") and humanoid ~= Player.Character then
                if not ESP.Humanoids[humanoid] then
                    local isPlayer = Utilities.isPlayerCharacter(humanoid)
                    ESP.Humanoids[humanoid] = ESP.Create(humanoid, isPlayer and "Player" or "NPC")
                end
            end
        end
        
        for humanoid, esp in pairs(ESP.Humanoids) do
            if humanoid.Parent then
                esp:Update()
            else
                esp:Destroy()
                ESP.Humanoids[humanoid] = nil
            end
        end
    end
    
    -- Initialize ESP system
    function ESP.Initialize()
        local lastUpdate = 0
        ESP.Connection = RunService.Heartbeat:Connect(function()
            local currentTime = tick()
            if currentTime - lastUpdate >= 0.2 then -- Update every 0.2 seconds
                ESP.Update()
                lastUpdate = currentTime
            end
        end)
        
        -- Initial scan to populate ESP immediately
        ESP.Update()
    end
    
    -- Cleanup
    function ESP.Cleanup()
        for _, esp in pairs(ESP.Items) do
            esp:Destroy()
        end
        for _, esp in pairs(ESP.Humanoids) do
            esp:Destroy()
        end
        ESP.Items = {}
        ESP.Humanoids = {}
        if ESP.Connection then
            ESP.Connection:Disconnect()
            ESP.Connection = nil
        end
    end
    
    return ESP
end
