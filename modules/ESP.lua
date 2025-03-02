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
        -- Enhanced Highlight with Layered Effect
        local highlight = Instance.new("Highlight")
        highlight.FillTransparency = 0.8 -- Base fill
        highlight.OutlineTransparency = 0.1 -- Crisp outline
        highlight.Adornee = object
        highlight.Parent = game.CoreGui
        
        -- Subtle glow layer (simulated highlight)
        local glow = Instance.new("Highlight")
        glow.FillTransparency = 0.95 -- Very faint
        glow.OutlineTransparency = 0.6 -- Softer outline
        glow.Adornee = object
        glow.Parent = game.CoreGui
        
        -- BillboardGui without background
        local billboard = Instance.new("BillboardGui")
        billboard.Size = UDim2.new(0, 130, 0, 25) -- Slightly wider, shorter
        billboard.StudsOffset = Vector3.new(0, 2.5, 0) -- Raised for clarity
        billboard.Adornee = object:IsA("Model") and (object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart")) or object
        billboard.AlwaysOnTop = true
        billboard.Parent = game.CoreGui
        
        -- Main TextLabel
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.TextSize = 14
        label.Font = Enum.Font.GothamBold
        label.TextStrokeTransparency = 0.2 -- Stronger stroke
        label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        label.Parent = billboard
        
        -- Shadow label for glow effect
        local shadow = Instance.new("TextLabel")
        shadow.Size = UDim2.new(1, 2, 1, 2) -- Slightly larger for blur
        shadow.Position = UDim2.new(0, -1, 0, -1) -- Offset for shadow
        shadow.BackgroundTransparency = 1
        shadow.TextSize = 14
        shadow.Font = Enum.Font.GothamBold
        shadow.TextStrokeTransparency = 1 -- No stroke, just glow
        shadow.TextTransparency = 0.5 -- Faint glow
        shadow.Parent = billboard
        
        local esp = {
            Highlight = highlight,
            Glow = glow, -- Added for layered effect
            Billboard = billboard,
            Label = label,
            Shadow = shadow, -- Added for text glow
            Object = object,
            Type = espType,
            LastPosition = nil,
            
            Update = function(self)
                if not Config.Enabled or not self.Object.Parent then
                    self.Highlight.Enabled = false
                    self.Glow.Enabled = false
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
                    self.Glow.Enabled = false
                    self.Billboard.Enabled = false
                    return
                end
                
                self.Highlight.Enabled = true
                self.Glow.Enabled = true
                self.Billboard.Enabled = true
                
                local color
                if self.Type == "Item" then
                    color = Utilities.getItemColor(self.Object, Config)
                else
                    color = Config.Colors[self.Type]
                end
                
                -- Highlight styling
                self.Highlight.FillColor = color
                self.Highlight.OutlineColor = color:Lerp(Color3.fromRGB(255, 255, 255), 0.4) -- Brighter outline
                self.Glow.FillColor = color:Lerp(Color3.fromRGB(255, 255, 255), 0.6) -- Glow tint
                self.Glow.OutlineColor = color
                
                -- Text styling
                local text = string.format("%s [%dm]", self.Object.Name, math.floor(distance))
                self.Label.TextColor3 = color
                self.Label.Text = text
                self.Shadow.TextColor3 = color:Lerp(Color3.fromRGB(255, 255, 255), 0.7) -- Subtle white glow
                self.Shadow.Text = text
            end,
            
            Destroy = function(self)
                Utilities.safeDestroy(self.Highlight)
                Utilities.safeDestroy(self.Glow)
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
