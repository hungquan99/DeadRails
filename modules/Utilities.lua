-- DeadRails ESP System by LxckStxp
-- Utilities Module

local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local Utilities = {}

-- Get distance between player and position
function Utilities.getDistance(position)
    if not Player.Character or not Player.Character:FindFirstChild("HumanoidRootPart") then return 999999 end
    return (Player.Character.HumanoidRootPart.Position - position).Magnitude
end

-- Get position from an object
function Utilities.getPosition(object)
    if object:IsA("Model") then
        local primaryPart = object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart")
        return primaryPart and primaryPart.Position or Vector3.new(0,0,0)
    end
    return object:IsA("BasePart") and object.Position or Vector3.new(0,0,0)
end

-- Check if a model is a player character
function Utilities.isPlayerCharacter(model)
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character == model then return player end
    end
    return false
end

-- Get health information from a model
function Utilities.getHealth(model)
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if humanoid then return {Current = humanoid.Health, Max = humanoid.MaxHealth} end
    
    local health = model:FindFirstChild("Health")
    if health and health:IsA("NumberValue") then
        local maxHealth = model:FindFirstChild("MaxHealth")
        return {
            Current = health.Value,
            Max = (maxHealth and maxHealth:IsA("NumberValue")) and maxHealth.Value or 100
        }
    end
    
    return {Current = 0, Max = 100}
end

-- Get tags from a model
function Utilities.getTags(model)
    local tags = {}
    
    -- Find tags in TextLabels
    for _, child in pairs(model:GetDescendants()) do
        if child:IsA("TextLabel") and child.Text ~= "" and #child.Text <= 10 then
            table.insert(tags, child.Text)
        end
    end
    
    -- Find tags in StringValues
    for _, child in pairs(model:GetDescendants()) do
        if child:IsA("StringValue") and child.Value ~= "" and #child.Value <= 10 then
            table.insert(tags, child.Value)
        end
    end
    
    return tags
end

-- Determine color based on tags
function Utilities.getColorFromTags(object, tags, Config)
    -- Check for keywords in tags
    local hasValuable, hasCorpse, hasFuel, hasGold, hasSilver = false, false, false, false, false
    local lowerName = string.lower(object.Name)
    
    for _, tag in ipairs(tags) do
        local lowerTag = string.lower(tag)
        if lowerTag:find("valuable") or lowerTag:find("value") then hasValuable = true end
        if lowerTag:find("corpse") or lowerTag:find("body") or lowerTag:find("dead") then hasCorpse = true end
        if lowerTag:find("fuel") or lowerTag:find("gas") or lowerTag:find("energy") then hasFuel = true end
    end
    
    if lowerName:find("gold") then hasGold = true end
    if lowerName:find("silver") then hasSilver = true end
    
    -- Determine color based on tags
    if hasGold then return Config.Colors.Gold end
    if hasSilver then return Config.Colors.Silver end
    if hasValuable then return Config.Colors.Valuable end
    if hasCorpse then return Config.Colors.Corpse end
    if hasFuel then return Config.Colors.Fuel end
    
    return Config.Colors.Default
end

-- Safe destroy function
function Utilities.safeDestroy(instance)
    pcall(function() 
        if instance and instance.Parent then
            instance:Destroy() 
        end
    end)
end

return Utilities
