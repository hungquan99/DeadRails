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
        -- Enhanced Highlight
        local highlight = Instance.new("Highlight")
        highlight.FillTransparency = 0.75 -- Slightly more opaque for better visibility
        highlight.OutlineTransparency = 0.1 -- Stronger outline for depth
        highlight.Adornee = object
        highlight.Parent = game.CoreGui
        
        -- Enhanced BillboardGui
        local billboard = Instance.new("BillboardGui")
        billboard.Size = UDim2.new(0, 120, 0, 30) -- Slightly larger for better readability
        billboard.StudsOffset = Vector3.new(0, 2.5, 0) -- Raised a bit for cleaner placement
        billboard.Adornee = object:IsA("Model") and (object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart")) or object
        billboard.AlwaysOnTop = true
        billboard.Parent = game.CoreGui
        
        -- Background frame for text (subtle backdrop)
        local bgFrame = Instance.new("Frame")
        bgFrame.Size = UDim2.new(1, -10, 1, -6) -- Slightly inset
        bgFrame.Position = UDim2.new(0, 5, 0, 3)
        bgFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20) -- Dark semi-transparent backdrop
        bgFrame.BackgroundTransparency = 0.7
        bgFrame.BorderSizePixel = 0
        bgFrame.Parent = billboard
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 4) -- Rounded edges for polish
        corner.Parent = bgFrame
        
        -- Improved TextLabel
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.TextSize = 14 -- Slightly larger for clarity
        label.Font = Enum.Font.GothamBold -- Modern, bold font
        label.TextStrokeTransparency = 0.3 -- Stronger stroke for contrast
        label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0) -- Black stroke for readability
        label.Parent = bgFrame
        
        local esp = {
            Highlight = highlight,
            Billboard = billboard,
            Label = label,
            Object = object,
            Type = espType,
            LastPosition = nil,
            
            Update = function(self)
                if not Config.Enabled or not self.Object.Parent then
                    self.Highlight.Enabled = false
                    self.Billboard.Enabled = false
                    return
                end
                
                local position = Utilities.getPosition(self.Object)
                if not self.LastPosition or (position - self.LastPosition).Magnitude > 0.1 then
                    self.LastPosition = position
                else
                    position = self.LastPosition
                end
                
                local distance = Utilities.getDistance(position)
                if distance > Config.MaxDistance then
                    self.Highlight.Enabled = false
                    self.Billboard.Enabled = false
                    return
                end
                
                self.Highlight.Enabled = true
                self.Billboard.Enabled = true
                
                local color
                if self.Type == "Item" then
                    color = Utilities.getItemColor(self.Object, Config)
                else
                    color = Config.Colors[self.Type]
                end
                
                self.Highlight.FillColor = color
                self.Highlight.OutlineColor = color:Lerp(Color3.fromRGB(255, 255, 255), 0.3) -- Lighter outline for pop
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
            if currentTime - lastUpdate >= 0.2 then
                ESP.Update()
                lastUpdate = currentTime
            end
        end)
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
