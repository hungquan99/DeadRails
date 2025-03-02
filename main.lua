local Config = require(script:WaitForChild("modules/Config"))
local Utilities = require(script:WaitForChild("modules/Utilities"))
local ESP = require(script:WaitForChild("modules/ESP"))(Config, Utilities)
local UI = require(script:WaitForChild("modules/UI"))(Config, ESP)

ESP.Initialize()
