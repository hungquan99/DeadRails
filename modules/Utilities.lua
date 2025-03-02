local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local Utilities = {}

function Utilities.getDistance(position)
    if not Player.Character or not Player.Character:FindFirstChild("HumanoidRootPart") then return 9999 end
    return (Player.Character.HumanoidRootPart.Position - position).Magnitude
end

function Utilities.getPosition(object)
    if object:IsA("Model") then
        local primaryPart = object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart")
        return primaryPart and primaryPart.Position or Vector3.new(0, 0, 0)
    end
    return object:IsA("BasePart") and object.Position or Vector3.new(0, 0, 0)
end

function Utilities.isPlayerCharacter(model)
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character == model then return true end
    end
    return false
end

function Utilities.safeDestroy(instance)
    pcall(function()
        if instance and instance.Parent then
            instance:Destroy()
        end
    end)
end

-- Assign colors to items based on their name
function Utilities.getItemColor(object, Config)
    local name = object.Name:lower()
    if name:find("fuel") or name:find("gas") then return Config.Colors.Fuel end
    if name:find("gold") then return Config.Colors.Gold end
    if name:find("silver") then return Config.Colors.Silver end
    if name:find("weapon") or name:find("gun") or name:find("knife") then return Config.Colors.Weapon end
    if name:find("ammo") or name:find("bullet") then return Config.Colors.Ammo end
    if name:find("bandage") or name:find("snake oil") then return Config.Colors.Healing end
    return Config.Colors.Default -- Fallback for uncategorized items
end

return Utilities
