return function(Config, ESP, MiddleClick)
    local CensuraDev = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/Censura/main/CensuraDev.lua"))()
    local UI = CensuraDev.new("DeadRails ESP")
    
    -- Sync UI toggle with ESP state
    local function syncUIToggle()
        local toggle = UI:CreateToggle("ESP Enable", ESP.IsEnabled(), function(state)
            print("UI Toggling ESP to:", state)
            ESP.SetEnabled(state)
        end)
        
        -- Ensure toggle reflects state changes from keybinds
        local function updateToggleState()
            toggle:SetState(ESP.IsEnabled(), true) -- Skip callback to avoid recursion
        end
        
        -- Monitor Config.Enabled changes (via ESPManager or keybind)
        local connection
        connection = RunService.Heartbeat:Connect(function()
            if toggle:GetState() ~= ESP.IsEnabled() then
                updateToggleState()
            end
        end)
        
        -- Clean up on UI destroy
        UI.Destroy = UI.Destroy or function()
            if connection then connection:Disconnect() end
            UI:Destroy()
        end
    end
    
    -- Initial sync
    syncUIToggle()
    
    -- Max Distance Slider
    UI:CreateSlider("Max Distance", 100, 2000, Config.MaxDistance, function(value)
        Config.MaxDistance = value
    end)
    
    -- Middle Click Utility Toggle
    UI:CreateToggle("Middle Click Utility", MiddleClick.Enabled, function(state)
        MiddleClick.Enabled = state
    end)
    
    -- Hook into CensuraDev's toggle key via ESPManager
    local toggleHandler = ESP.HandleToggleKey()
    if toggleHandler then
        local system = getgenv().CensuraSystem
        UI.KeybindConnection = UI.InputBegan:Connect(function(input, processed)
            if not processed and input.KeyCode == system.Settings.ToggleKey then
                local newState = toggleHandler()
                -- Update UI toggle state manually
                local toggle = UI.ContentFrame:FindFirstChild("ESP Enable")
                if toggle and toggle:IsA("TextButton") then
                    toggle:SetState(newState, true) -- Skip callback to avoid recursion
                end
            end
        end)
    end
    
    return UI
end
