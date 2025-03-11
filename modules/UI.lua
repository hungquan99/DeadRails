return function(Config, ESP, MiddleClick, Aimbot)
    local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
    local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
    local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
    
    local minimizeUI = Enum.KeyCode.RightControl

    -- 🟢 Create Main UI
    local Window = Fluent:CreateWindow({
        Title = "Skull Hub",
        SubTitle = "Rivals",
        TabWidth = 160,
        Size = UDim2.fromOffset(580, 460),
        Acrylic = false,
        Theme = "Darker",
        MinimizeKey = minimizeUI
    })

    -- Tabs
    local Tabs = {
        Ma = Window:AddTab({ Title = "Main", Icon = "rbxassetid://95183678717613" }),
        Misc = Window:AddTab({ Title = "Misc", Icon = "rbxassetid://95183678717613" }),
    }

    do
        local Aim2Toggle = Tabs.Ma:AddToggle("SilentAimV2", { Title = "ESP", Description = "• Items 🟢\n• NPC/Player 🟢", Default = false })
        Aim2Toggle:OnChanged(function()
            Config.Enabled = Aim2Toggle.Value
            if Aim2Toggle.Value then
                ESP.Initialize()
                ESP.Update()
            else
                ESP.Cleanup()
            end
        end)

        local Slider = Tabs.Ma:AddSlider("Slider", {
            Title = "Slider",
            Description = "This is a slider",
            Default = Config.MaxDistance,
            Min = 100,
            Max = 2000,
            Rounding = 1,
            Callback = function(Value)
                Config.MaxDistance = Value
            end
        })

        local aimbotEnabled = (Aimbot and Aimbot.Enabled ~= nil) and Aimbot.Enabled or false
        local Aim1Toggle = Tabs.Ma:AddToggle("SilentAimV1", { Title = "Aimbot", Description = "• Hold M2 to aim.", Default = false })
        Aim1Toggle:OnChanged(function()
            if Aimbot and Aimbot.Enabled ~= nil then
                Aimbot.Enabled = Aim1Toggle.Value
                warn("Aimbot toggled to:", Aim1Toggle.Value)
            else
                warn("Aimbot module not loaded or Enabled property missing")
            end
        end)
    end

end
