-- Streamlined Roblox ESP System with Humanoid Detection
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Load UI Library
local CensuraDev = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/Censura/main/CensuraDev.lua"))()
local UI = CensuraDev.new("ESP System")

-- ESP Configuration
local Config = {
    ESP = {
        Enabled = true,
        ShowInfo = true,
        MaxDistance = 2000,
        DefaultColor = Color3.fromRGB(200, 200, 200) -- Default gray
    },
    -- Color coordination based on tags
    TagColors = {
        Valuable = Color3.fromRGB(0, 255, 0), -- Green
        Corpse = Color3.fromRGB(139, 69, 19), -- Brown
        Fuel = Color3.fromRGB(255, 165, 0), -- Orange
        Gold = Color3.fromRGB(255, 215, 0), -- Gold
        Silver = Color3.fromRGB(192, 192, 192) -- Silver
    },
    -- Special combination colors
    CombinationColors = {
        ValuableCorpse = Color3.fromRGB(128, 0, 32), -- Burgundy
        ValuableFuel = Color3.fromRGB(255, 255, 0) -- Yellow
    },
    -- Humanoid colors
    HumanoidColors = {
        Player = Color3.fromRGB(0, 255, 0), -- Green for players
        NPC = Color3.fromRGB(255, 0, 0) -- Red for NPCs
    }
}

-- ESP Storage
local ESPObjects = {
    Items = {},
    Humanoids = {}
}

-- Utility Functions
local function getDistance(position)
    if not Player.Character or not Player.Character:FindFirstChild("HumanoidRootPart") then return 0 end
    return math.floor((Player.Character.HumanoidRootPart.Position - position).Magnitude + 0.5)
end

-- Get tags from an object and filter by length
local function getTags(model)
    local tags = {}
    
    -- Look for TextLabels with descriptive text
    for _, child in pairs(model:GetDescendants()) do
        if child:IsA("TextLabel") and child.Text ~= "" then
            -- Only include tags that are 10 characters or less
            if #child.Text <= 10 then
                table.insert(tags, child.Text)
            end
        end
    end
    
    -- Also check for StringValues that might contain tags
    for _, child in pairs(model:GetDescendants()) do
        if child:IsA("StringValue") and child.Value ~= "" then
            -- Only include tags that are 10 characters or less
            if #child.Value <= 10 then
                table.insert(tags, child.Value)
            end
        end
    end
    
    return tags
end

-- Determine color based on tags and name
local function determineColor(object, tags)
    -- Check for special combinations first
    local hasValuable = false
    local hasCorpse = false
    local hasFuel = false
    local hasGold = false
    local hasSilver = false
    
    -- Convert tags to lowercase for case-insensitive matching
    local lowerTags = {}
    for _, tag in ipairs(tags) do
        local lowerTag = string.lower(tag)
        table.insert(lowerTags, lowerTag)
        
        if lowerTag:find("valuable") or lowerTag:find("value") then
            hasValuable = true
        end
        if lowerTag:find("corpse") or lowerTag:find("body") or lowerTag:find("dead") then
            hasCorpse = true
        end
        if lowerTag:find("fuel") or lowerTag:find("gas") or lowerTag:find("energy") then
            hasFuel = true
        end
    end
    
    -- Check object name for gold/silver
    local lowerName = string.lower(object.Name)
    if lowerName:find("gold") then
        hasGold = true
    end
    if lowerName:find("silver") then
        hasSilver = true
    end
    
    -- Check for special combinations
    if hasValuable and hasCorpse then
        return Config.CombinationColors.ValuableCorpse
    end
    if hasValuable and hasFuel then
        return Config.CombinationColors.ValuableFuel
    end
    
    -- Check for individual tags
    if hasGold then
        return Config.TagColors.Gold
    end
    if hasSilver then
        return Config.TagColors.Silver
    end
    if hasValuable then
        return Config.TagColors.Valuable
    end
    if hasCorpse then
        return Config.TagColors.Corpse
    end
    if hasFuel then
        return Config.TagColors.Fuel
    end
    
    -- Default color if no specific tags matched
    return Config.ESP.DefaultColor
end

local function getHealth(character)
    -- Try to find Humanoid
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        return {Current = humanoid.Health, Max = humanoid.MaxHealth}
    end
    
    -- Try to find health values
    local health = character:FindFirstChild("Health")
    if health and health:IsA("NumberValue") then
        local maxHealth = character:FindFirstChild("MaxHealth")
        return {
            Current = health.Value,
            Max = (maxHealth and maxHealth:IsA("NumberValue")) and maxHealth.Value or 100
        }
    end
    
    return {Current = 0, Max = 100}
end

-- Check if a character belongs to a player
local function isPlayerCharacter(character)
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character == character then
            return true
        end
    end
    return false
end

-- Get player name from character
local function getPlayerFromCharacter(character)
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character == character then
            return player
        end
    end
    return nil
end

-- Create ESP for an object
local function createESP(object, espType)
    -- Create highlight
    local highlight = Instance.new("Highlight")
    highlight.FillTransparency = 0.7
    highlight.OutlineTransparency = 0
    highlight.Adornee = object
    highlight.Parent = game.CoreGui
    
    -- Create billboard for info
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
    
    -- ESP object with methods
    local esp = {
        Highlight = highlight,
        Billboard = billboard,
        InfoLabel = infoLabel,
        Tags = {},
        Type = espType,
        
        Update = function(self)
            -- Check if ESP is enabled
            if not Config.ESP.Enabled then
                self.Highlight.Enabled = false
                self.Billboard.Enabled = false
                return
            end
            
            -- Get primary part for distance calculation
            local primaryPart
            if object:IsA("Model") then
                primaryPart = object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart")
            else
                primaryPart = object
            end
            
            if not primaryPart then return end
            
            -- Check distance
            local distance = getDistance(primaryPart.Position)
            if distance > Config.ESP.MaxDistance then
                self.Highlight.Enabled = false
                self.Billboard.Enabled = false
                return
            end
            
            -- Update highlight
            self.Highlight.Enabled = true
            
            -- Determine color and info based on type
            if self.Type == "Item" then
                self.Tags = getTags(object)
                local color = determineColor(object, self.Tags)
                self.Highlight.FillColor = color
                self.Highlight.OutlineColor = color
                self.InfoLabel.TextColor3 = color
            elseif self.Type == "Humanoid" then
                local isPlayer = isPlayerCharacter(object)
                local color = isPlayer and Config.HumanoidColors.Player or Config.HumanoidColors.NPC
                self.Highlight.FillColor = color
                self.Highlight.OutlineColor = color
                self.InfoLabel.TextColor3 = color
            end
            
            -- Update info
            if Config.ESP.ShowInfo then
                self.Billboard.Enabled = true
                
                local infoText = object.Name .. " [" .. distance .. "m]"
                
                -- Add tags for items
                if self.Type == "Item" and #self.Tags > 0 then
                    infoText = infoText .. "\n" .. table.concat(self.Tags, " | ")
                end
                
                -- Add health for humanoids
                if self.Type == "Humanoid" then
                    local health = getHealth(object)
                    infoText = infoText .. "\nHP: " .. math.floor(health.Current) .. "/" .. math.floor(health.Max)
                end
                
                -- Add player name if it's a player character
                if self.Type == "Humanoid" and isPlayerCharacter(object) then
                    local player = getPlayerFromCharacter(object)
                    if player then
                        infoText = player.Name .. " [" .. distance .. "m]" .. "\nHP: " .. math.floor(getHealth(object).Current)
                    end
                end
                
                self.InfoLabel.Text = infoText
            else
                self.Billboard.Enabled = false
            end
        end,
        
        Destroy = function(self)
            pcall(function() self.Highlight:Destroy() end)
            pcall(function() self.Billboard:Destroy() end)
        end
    }
    
    return esp
end

-- Scan for humanoids in the workspace
local function scanForHumanoids()
    -- Don't scan if ESP is disabled
    if not Config.ESP.Enabled then return end
    
    -- Scan through all workspace descendants
    for _, instance in pairs(workspace:GetDescendants()) do
        -- Check if it's a character model with a humanoid
        if instance:IsA("Model") and instance:FindFirstChildOfClass("Humanoid") then
            -- Skip player's own character
            if Player.Character ~= instance and not ESPObjects.Humanoids[instance] then
                ESPObjects.Humanoids[instance] = createESP(instance, "Humanoid")
            end
        end
    end
end

-- Update all ESP objects
local function updateESP()
    -- Update items
    if workspace:FindFirstChild("RuntimeItems") and Config.ESP.Enabled then
        -- Add new items
        for _, item in pairs(workspace.RuntimeItems:GetChildren()) do
            if not ESPObjects.Items[item] then
                ESPObjects.Items[item] = createESP(item, "Item")
            end
        end
        
        -- Update and clean up items
        for item, esp in pairs(ESPObjects.Items) do
            if item and item.Parent then
                esp:Update()
            else
                esp:Destroy()
                ESPObjects.Items[item] = nil
            end
        end
    end
    
    -- Scan for new humanoids periodically (every 1 second to reduce performance impact)
    if tick() % 1 < 0.1 then
        scanForHumanoids()
    end
    
    -- Update and clean up humanoids
    for character, esp in pairs(ESPObjects.Humanoids) do
        if character and character.Parent then
            esp:Update()
        else
            esp:Destroy()
            ESPObjects.Humanoids[character] = nil
        end
    end
end

-- Clean up function
local function cleanupESP()
    for _, esp in pairs(ESPObjects.Items) do
        esp:Destroy()
    end
    
    for _, esp in pairs(ESPObjects.Humanoids) do
        esp:Destroy()
    end
    
    ESPObjects.Items = {}
    ESPObjects.Humanoids = {}
end

-- Create UI Controls
UI:CreateButton("ESP Settings", function() end):SetEnabled(false)

UI:CreateToggle("Enable ESP", Config.ESP.Enabled, function(state)
    Config.ESP.Enabled = state
    -- If enabling, immediately scan for humanoids
    if state then
        scanForHumanoids()
    else
        -- Clean up ESP when disabled
        for _, esp in pairs(ESPObjects.Items) do
            esp:Destroy()
        end
        for _, esp in pairs(ESPObjects.Humanoids) do
            esp:Destroy()
        end
        ESPObjects.Items = {}
        ESPObjects.Humanoids = {}
    end
end)

UI:CreateToggle("Show Info", Config.ESP.ShowInfo, function(state)
    Config.ESP.ShowInfo = state
end)

UI:CreateSlider("Max Distance", 100, 2000, Config.ESP.MaxDistance, function(value)
    Config.ESP.MaxDistance = value
end)

-- Start the ESP system
local espConnection = RunService.RenderStepped:Connect(updateESP)

-- Handle script termination
game:GetService("Players").LocalPlayer.CharacterRemoving:Connect(function()
    espConnection:Disconnect()
    cleanupESP()
end)

-- Listen for new characters being added to workspace
workspace.ChildAdded:Connect(function(child)
    if child:IsA("Model") and Config.ESP.Enabled then
        -- Wait a moment for the humanoid to be added to the model
        task.delay(0.1, function()
            if child:FindFirstChildOfClass("Humanoid") and not ESPObjects.Humanoids[child] then
                ESPObjects.Humanoids[child] = createESP(child, "Humanoid")
            end
        end)
    end
end)

-- Listen for player joining to detect their characters
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        if Config.ESP.Enabled and not ESPObjects.Humanoids[character] then
            ESPObjects.Humanoids[character] = createESP(character, "Humanoid")
        end
    end)
end)

-- Initialize existing player characters
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= Player and player.Character and Config.ESP.Enabled then
        ESPObjects.Humanoids[player.Character] = createESP(player.Character, "Humanoid")
    end
    
    player.CharacterAdded:Connect(function(character)
        if Config.ESP.Enabled and not ESPObjects.Humanoids[character] then
            ESPObjects.Humanoids[character] = createESP(character, "Humanoid")
        end
    end)
end

print("ESP System initialized with humanoid detection!")

-- Perform initial scan for humanoids
scanForHumanoids()
