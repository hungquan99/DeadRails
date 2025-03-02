return function(Config, Utilities)
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local TweenService = game:GetService("TweenService")
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
        highlight.OutlineTransparency = 0.1
        highlight.Adornee = object
        highlight.Parent = game.CoreGui
        
        local glow = Instance.new("Highlight")
        glow.FillTransparency = 0.95
        glow.OutlineTransparency = 0.6
        glow.Adornee = object
        glow.Parent = game.CoreGui
        
        local billboard = Instance.new("BillboardGui")
        billboard.Size = UDim2.new(0, 130, 0, espType == "Item" and 25 or 35)
        billboard.StudsOffset = Vector3.new(0, 2.5, 0)
        billboard.Adornee = object:IsA("Model") and (object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart")) or object
        billboard.AlwaysOnTop = true
        billboard.Parent = game.CoreGui
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, espType == "Item" and 1 or 0.6, 0)
        label.Position = UDim2.new(0, 0, 0, 0)
        label.BackgroundTransparency = 1
        label.TextSize = 14
        label.Font = Enum.Font.GothamBold
        label.TextStrokeTransparency = 0.2
        label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        label.Parent = billboard
        
        local shadow = Instance.new("TextLabel")
        shadow.Size = UDim2.new(1, 2, espType == "Item" and 1 or 0.6, 2)
        shadow.Position = UDim2.new(0, -1, 0, -1)
        shadow.BackgroundTransparency = 1
        shadow.TextSize = 14
        shadow.Font = Enum.Font.GothamBold
        shadow.TextStrokeTransparency = 1
        shadow.TextTransparency = 0.5
        shadow.Parent = billboard
        
        local healthBar, healthFill, healthBorder
        if espType ~= "Item" then
            healthBar = Instance.new("Frame")
            healthBar.Size = UDim2.new(0.9, 0, 0.15, 0)
            healthBar.Position = UDim2.new(0.05, 0, 0.75, 0)
            healthBar.BackgroundTransparency = 1
            healthBar.Parent = billboard
            
            healthBorder = Instance.new("Frame")
            healthBorder.Size = UDim2.new(1, 4, 1, 4)
            healthBorder.Position = UDim2.new(0, -2, 0, -2)
            healthBorder.BackgroundColor3 = espType == "Player" and Config.Colors.Player or Config.Colors.NPC -- Color-coded
            healthBorder.BackgroundTransparency = 0.5
            healthBorder.BorderSizePixel = 0
            healthBorder.ZIndex = 0
            healthBorder.Parent = healthBar
            
            healthFill = Instance.new("Frame")
            healthFill.Size = UDim2.new(1, 0, 1, 0)
            healthFill.Position = UDim2.new(0, 0, 0, 0)
            healthFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            healthFill.BorderSizePixel = 0
            healthFill.ZIndex = 1
            healthFill.Parent = healthBar
            
            local gradient = Instance.new("UIGradient")
            gradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 0)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 255, 0))
            })
            gradient.Rotation = 0
            gradient.Parent = healthFill
            
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 3)
            corner.Parent = healthBorder
            corner:Clone().Parent = healthFill
        end
        
        local esp = {
            Highlight = highlight,
            Glow = glow,
            Billboard = billboard,
            Label = label,
            Shadow = shadow,
            HealthBar = healthBar,
            HealthFill = healthFill,
            HealthBorder = healthBorder,
            Object = object,
            Type = espType,
            LastPosition = nil,
            LastDistance = nil,
            PulseTween = nil, -- For rarity glow
            
            Update = function(self)
                if not Config.Enabled or not self.Object.Parent then
                    self.Highlight.Enabled = false
                    self.Glow.Enabled = false
                    self.Billboard.Enabled = false
                    if self.HealthBar then self.HealthBar.Visible = false end
                    if self.PulseTween then self.PulseTween:Pause() end
                    return
                end
                
                local position = Utilities.getPosition(self.Object)
                local distance = Utilities.getDistance(position)
                
                -- Spatial filtering: Skip if beyond 90% MaxDistance and static
                if self.LastDistance and distance > Config.MaxDistance * 0.9 and 
                   (self.LastPosition and (position - self.LastPosition).Magnitude < 5) then
                    return
                end
                
                self.LastPosition = position
                self.LastDistance = distance
                
                if distance > Config.MaxDistance then
                    self.Highlight.Enabled = false
                    self.Glow.Enabled = false
                    self.Billboard.Enabled = false
                    if self.HealthBar then self.HealthBar.Visible = false end
                    if self.PulseTween then self.PulseTween:Pause() end
                    return
                end
                
                self.Highlight.Enabled = true
                self.Glow.Enabled = true
                self.Billboard.Enabled = true
                
                -- Fade effect
                local fadeStart = Config.MaxDistance * 0.7
                local fade = distance > fadeStart and math.clamp((distance - fadeStart) / (Config.MaxDistance - fadeStart), 0, 1) or 0
                self.Highlight.FillTransparency = 0.8 + fade * 0.2
                self.Highlight.OutlineTransparency = 0.1 + fade * 0.9
                self.Glow.FillTransparency = 0.95 + fade * 0.05
                self.Glow.OutlineTransparency = 0.6 + fade * 0.4
                self.Label.TextTransparency = fade
                self.Label.TextStrokeTransparency = 0.2 + fade * 0.8
                self.Shadow.TextTransparency = 0.5 + fade * 0.5
                
                local color
                if self.Type == "Item" then
                    color = Utilities.getItemColor(self.Object, Config)
                    -- Rarity glow for Gold, Silver, Rare
                    if not self.PulseTween and (color == Config.Colors.Gold or color == Config.Colors.Silver or color == Config.Colors.Rare) then
                        self.PulseTween = TweenService:Create(self.Glow, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
                            FillTransparency = 0.9
                        })
                        self.PulseTween:Play()
                    end
                    if self.PulseTween then
                        self.PulseTween:Play()
                    end
                else
                    color = Config.Colors[self.Type]
                    if self.PulseTween then self.PulseTween:Pause() end
                end
                
                self.Highlight.FillColor = color
                self.Highlight.OutlineColor = color:Lerp(Color3.fromRGB(255, 255, 255), 0.4)
                self.Glow.FillColor = color:Lerp(Color3.fromRGB(255, 255, 255), 0.6)
                self.Glow.OutlineColor = color
                
                -- Truncate long names
                local name = self.Object.Name
                if #name > 12 then name = name:sub(1, 10) .. "..." end
                local text = string.format("%s [%dm]", name, math.floor(distance))
                self.Label.TextColor3 = color
                self.Label.Text = text
                self.Shadow.TextColor3 = color:Lerp(Color3.fromRGB(255, 255, 255), 0.7)
                self.Shadow.Text = text
                
                if self.Type ~= "Item" then
                    if distance <= 100 and Config.ShowHealthBars then
                        self.HealthBar.Visible = true
                        local health = Utilities.getHealth(self.Object)
                        local healthPercent = math.clamp(health.Current / health.Max, 0, 1)
                        -- Smooth health bar transition
                        TweenService:Create(self.HealthFill, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                            Size = UDim2.new(healthPercent, 0, 1, 0)
                        }):Play()
                        self.HealthBorder.BackgroundTransparency = 0.5 + fade * 0.5
                        self.HealthFill.BackgroundTransparency = fade
                    else
                        self.HealthBar.Visible = false
                    end
                end
            end,
            
            Destroy = function(self)
                if self.PulseTween then self.PulseTween:Cancel() end
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
