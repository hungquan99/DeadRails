local Config = {
    Enabled = true,
    MaxDistance = 1000,
    Colors = {
        -- Humanoid Colors
        Player = Color3.fromRGB(0, 0, 255),    -- Blue for players
        NPC = Color3.fromRGB(255, 0, 0),       -- Red for NPCs
        
        -- Item Colors
        Default = Color3.fromRGB(200, 200, 200), -- Gray for unidentified items
        Fuel = Color3.fromRGB(255, 165, 0),     -- Orange for fuel
        Gold = Color3.fromRGB(255, 215, 0),     -- Yellow for gold
        Silver = Color3.fromRGB(192, 192, 192), -- Silver for silver
        Weapon = Color3.fromRGB(255, 0, 255),   -- Magenta for weapons
        Ammo = Color3.fromRGB(0, 255, 255),     -- Cyan for ammo
        Medkit = Color3.fromRGB(0, 255, 0)      -- Green for medkits
    }
}

return Config
