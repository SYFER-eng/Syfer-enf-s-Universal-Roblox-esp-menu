-- Load the ESP Library
local ESPLib = loadstring(game:HttpGet('https://raw.githubusercontent.com/SYFER-eng/Syfer-enf-s-Universal-Roblox-esp-menu/refs/heads/main/Lib/Lib.lua'))()

-- Check if library loaded successfully
if not ESPLib then
    warn("Failed to load ESP Library! Attempting to use local version...")
    -- Try loading from locally saved script as fallback
    ESPLib = require(script.Parent.RobloxESPLib)
    
    if not ESPLib then
        warn("Failed to load ESP Library! Script cannot continue.")
        return
    end
end

-- Initialize the library
ESPLib = ESPLib.Init()

-- Create UI
local UI = ESPLib.UI.Framework.new()

-- Cache frequently used theme values
local Theme = ESPLib.Config.UI.Theme

-- Create ESP Tab
local espTab = UI:CreateTab("ESP", 0)

-- Create heading for ESP options
UI:CreateLabel(espTab, "ESP Features", Vector2.new(20, 15), true)

-- Create main ESP toggle
local espToggle = UI:CreateToggle(espTab, "Enable ESP", ESPLib.Config.ESP.Enabled, function(enabled)
    ESPLib.Config.ESP.Enabled = enabled
end, Vector2.new(20, 50))

-- Create other ESP feature toggles (arranged in two columns)
UI:CreateToggle(espTab, "Show Boxes", ESPLib.Config.ESP.BoxEnabled, function(enabled)
    ESPLib.Config.ESP.BoxEnabled = enabled
end, Vector2.new(20, 90))

UI:CreateToggle(espTab, "Show Names", ESPLib.Config.ESP.NameEnabled, function(enabled)
    ESPLib.Config.ESP.NameEnabled = enabled
end, Vector2.new(20, 130))

UI:CreateToggle(espTab, "Show Distance", ESPLib.Config.ESP.DistanceEnabled, function(enabled)
    ESPLib.Config.ESP.DistanceEnabled = enabled
end, Vector2.new(20, 170))

UI:CreateToggle(espTab, "Show Tracers", ESPLib.Config.ESP.TracerEnabled, function(enabled)
    ESPLib.Config.ESP.TracerEnabled = enabled
end, Vector2.new(20, 210))

UI:CreateToggle(espTab, "Show Health", ESPLib.Config.ESP.HealthEnabled, function(enabled)
    ESPLib.Config.ESP.HealthEnabled = enabled
end, Vector2.new(250, 90))

UI:CreateToggle(espTab, "Team Check", ESPLib.Config.ESP.TeamCheck, function(enabled)
    ESPLib.Config.ESP.TeamCheck = enabled
end, Vector2.new(250, 130))

UI:CreateToggle(espTab, "Team Color", ESPLib.Config.ESP.TeamColor, function(enabled)
    ESPLib.Config.ESP.TeamColor = enabled
end, Vector2.new(250, 170))

UI:CreateToggle(espTab, "Rainbow Mode", ESPLib.Config.ESP.RainbowMode, function(enabled)
    ESPLib.Config.ESP.RainbowMode = enabled
end, Vector2.new(250, 210))

-- Create dropdown for tracer origin
UI:CreateLabel(espTab, "Tracer Settings", Vector2.new(20, 260), true)

UI:CreateDropdown(espTab, "Tracer Origin", {"Bottom", "Center", "Mouse"}, ESPLib.Config.ESP.TracerOrigin, function(value)
    ESPLib.Config.ESP.TracerOrigin = value
end, Vector2.new(20, 290))

-- Create Appearance Tab
local appearanceTab = UI:CreateTab("Appearance", 120)

-- Create appearance settings
UI:CreateLabel(appearanceTab, "Colors", Vector2.new(20, 15), true)

UI:CreateColorPicker(appearanceTab, "Box Color", ESPLib.Config.ESP.BoxColor, function(color)
    ESPLib.Config.ESP.BoxColor = color
end, Vector2.new(20, 50))

UI:CreateColorPicker(appearanceTab, "Text Color", ESPLib.Config.ESP.TextColor, function(color)
    ESPLib.Config.ESP.TextColor = color
end, Vector2.new(250, 50))

UI:CreateColorPicker(appearanceTab, "Tracer Color", ESPLib.Config.ESP.TracerColor, function(color)
    ESPLib.Config.ESP.TracerColor = color
end, Vector2.new(20, 120))

UI:CreateLabel(appearanceTab, "Thickness Settings", Vector2.new(20, 190), true)

UI:CreateSlider(appearanceTab, "Box Thickness", 1, 5, ESPLib.Config.ESP.BoxThickness, function(value)
    ESPLib.Config.ESP.BoxThickness = value
end, Vector2.new(20, 220))

UI:CreateSlider(appearanceTab, "Tracer Thickness", 1, 5, ESPLib.Config.ESP.TracerThickness, function(value)
    ESPLib.Config.ESP.TracerThickness = value
end, Vector2.new(20, 280))

UI:CreateSlider(appearanceTab, "Text Size", 10, 20, ESPLib.Config.ESP.TextSize, function(value)
    ESPLib.Config.ESP.TextSize = value
end, Vector2.new(250, 220))

-- Create Settings Tab
local settingsTab = UI:CreateTab("Settings", 240)

UI:CreateLabel(settingsTab, "General Settings", Vector2.new(20, 15), true)

UI:CreateSlider(settingsTab, "Max Distance", 100, 5000, ESPLib.Config.ESP.MaxDistance, function(value)
    ESPLib.Config.ESP.MaxDistance = value
end, Vector2.new(20, 50))

UI:CreateToggle(settingsTab, "Text Outline", ESPLib.Config.ESP.TextOutline, function(enabled)
    ESPLib.Config.ESP.TextOutline = enabled
end, Vector2.new(20, 110))

UI:CreateLabel(settingsTab, "UI Settings", Vector2.new(20, 160), true)

UI:CreateSlider(settingsTab, "Animation Speed", 0.1, 1, ESPLib.Config.UI.Animation.Speed, function(value)
    ESPLib.Config.UI.Animation.Speed = value
end, Vector2.new(20, 190))

UI:CreateDropdown(settingsTab, "Animation Style", {"Linear", "Quad", "Cubic", "Sine"}, ESPLib.Config.UI.Animation.EasingStyle, function(value)
    ESPLib.Config.UI.Animation.EasingStyle = value
end, Vector2.new(20, 240))

UI:CreateButton(settingsTab, "Reset All Settings", function()
    -- Reset all settings to defaults
    for setting, value in pairs(ESPLib.Config.ESP) do
        if type(value) == "boolean" then
            ESPLib.Config.ESP[setting] = false
        elseif type(value) == "number" then
            if setting:find("Thickness") then
                ESPLib.Config.ESP[setting] = 1
            elseif setting == "TextSize" then
                ESPLib.Config.ESP[setting] = 13
            elseif setting == "MaxDistance" then
                ESPLib.Config.ESP[setting] = 1000
            end
        elseif type(value) == "string" then
            if setting == "TracerOrigin" then
                ESPLib.Config.ESP[setting] = "Bottom"
            end
        end
    end
    
    ESPLib.Config.ESP.BoxColor = Color3.fromRGB(255, 0, 0)
    ESPLib.Config.ESP.TextColor = Color3.fromRGB(255, 255, 255)
    ESPLib.Config.ESP.TracerColor = Color3.fromRGB(255, 0, 0)
    
    -- Turn on basic features
    ESPLib.Config.ESP.Enabled = true
    ESPLib.Config.ESP.BoxEnabled = true
    ESPLib.Config.ESP.NameEnabled = true
    ESPLib.Config.ESP.DistanceEnabled = true
    
    -- Refresh UI to reflect changes
    UI:Toggle()
    task.wait(0.1)
    UI:Toggle()
end, Vector2.new(20, 300))

-- Add Credits Tab
local creditsTab = UI:CreateTab("Credits", 360)

UI:CreateLabel(creditsTab, "Universal ESP", Vector2.new(20, 15), true)
UI:CreateLabel(creditsTab, "Version: " .. ESPLib.Version, Vector2.new(20, 50), false)
UI:CreateLabel(creditsTab, "Created by: " .. ESPLib.Author, Vector2.new(20, 80), false)

UI:CreateLabel(creditsTab, "Instructions", Vector2.new(20, 120), true)

local instructionY = 155
local instructions = {
    "• Press [Insert] to show/hide the UI",
    "• Press [End] to completely unload the script",
    "• ESP works on all players by default",
    "• Team Check will ignore players on your team",
    "• Rainbow Mode cycles through colors automatically",
    "• Configure appearance in the Appearance tab"
}

for _, instruction in ipairs(instructions) do
    UI:CreateLabel(creditsTab, instruction, Vector2.new(20, instructionY), false)
    instructionY = instructionY + 30
end

-- Show the UI when script starts
UI:Show()

-- Notify user that ESP is loaded
local notification = Drawing.new("Text")
notification.Text = "Universal ESP Loaded!"
notification.Size = 24
notification.Center = true
notification.Position = Vector2.new(game.Workspace.CurrentCamera.ViewportSize.X / 2, 30)
notification.Color = Theme.EnabledColor
notification.Outline = true
notification.OutlineColor = Color3.fromRGB(0, 0, 0)
notification.Visible = true

-- Make notification disappear after a short time
task.spawn(function()
    task.wait(3)
    for i = 1, 10 do
        notification.Transparency = 1 - (i / 10)
        task.wait(0.05)
    end
    notification:Remove()
end)

-- Print success message in console
print("Universal ESP with Enhanced UI loaded successfully!")
print("Press INSERT to toggle UI visibility")
print("Press END to unload the ESP completely")
