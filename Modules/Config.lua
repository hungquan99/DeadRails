-- DeadRails ESP System by LxckStxp
-- Configuration Module

local Config = {
    Enabled = true,
    ShowInfo = true,
    MaxDistance = 2000,
    DetailDistance = 50,
    ClusterDistance = 30,
    Colors = {
        Default = Color3.fromRGB(200, 200, 200),
        Player = Color3.fromRGB(0, 255, 0),
        NPC = Color3.fromRGB(255, 0, 0),
        Valuable = Color3.fromRGB(0, 255, 0),
        Corpse = Color3.fromRGB(139, 69, 19),
        Fuel = Color3.fromRGB(255, 165, 0),
        Gold = Color3.fromRGB(255, 215, 0),
        Silver = Color3.fromRGB(192, 192, 192)
    },
    Debug = false
}

return Config
