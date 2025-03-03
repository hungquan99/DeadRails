return function(Config, Utilities, ESPObject, ESPConfig)
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local Player = Players.LocalPlayer
    
    local ESPManager = {
        Items = {},
        Humanoids = {},
        Connection = nil
    }
    
    function ESPManager.Update()
        if not Config.Enabled then return end
        
        -- Handle items (corpses, etc.)
        local runtimeItems = workspace:FindFirstChild("RuntimeItems")
        if runtimeItems then
            for _, item in pairs(runtimeItems:GetChildren()) do
                if not ESPManager.Items[item] then
                    ESPManager.Items[item] = ESPObject.Create(item, "Item")
                end
            end
        end
        
        for item, esp in pairs(ESPManager.Items) do
            if item.Parent then
                esp:Update()
            else
                esp:Destroy()
                ESPManager.Items[item] = nil
            end
        end
        
        -- Handle humanoids (track alive ones only)
        for _, humanoid in pairs(workspace:GetDescendants()) do
            if humanoid:IsA("Model") and humanoid:FindFirstChildOfClass("Humanoid") and humanoid ~= Player.Character then
                local hum = humanoid:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 and not ESPManager.Humanoids[humanoid] then
                    local isPlayer = Utilities.isPlayerCharacter(humanoid)
                    ESPManager.Humanoids[humanoid] = ESPObject.Create(humanoid, isPlayer and "Player" or "NPC")
                end
            end
        end
        
        for humanoid, esp in pairs(ESPManager.Humanoids) do
            if humanoid.Parent then
                local hum = humanoid:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    esp:Update()
                else
                    -- Humanoid is dead, stop tracking as enemy
                    esp:Destroy()
                    ESPManager.Humanoids[humanoid] = nil
                end
            else
                esp:Destroy()
                ESPManager.Humanoids[humanoid] = nil
            end
        end
    end
    
    function ESPManager.Initialize()
        local lastUpdate = 0
        ESPManager.Connection = RunService.Heartbeat:Connect(function()
            local currentTime = tick()
            if currentTime - lastUpdate >= ESPConfig.UpdateInterval then
                ESPManager.Update()
                lastUpdate = currentTime
            end
        end)
        ESPManager.Update()
    end
    
    function ESPManager.Cleanup()
        for _, esp in pairs(ESPManager.Items) do
            esp:Destroy()
        end
        for _, esp in pairs(ESPManager.Humanoids) do
            esp:Destroy()
        end
        ESPManager.Items = {}
        ESPManager.Humanoids = {}
        if ESPManager.Connection then
            ESPManager.Connection:Disconnect()
            ESPManager.Connection = nil
        end
    end
    
    return ESPManager
end
