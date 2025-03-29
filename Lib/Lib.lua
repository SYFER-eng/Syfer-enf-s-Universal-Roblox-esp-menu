--[[
    Roblox ESP Library
    A comprehensive ESP library with customizable UI components
    
    Features:
    - Universal ESP for all players in game
    - Toggle functionality with cleanup
    - Modern UI components (tabs, toggles, sliders, color pickers)
    - Animated elements with hover effects
    - External executor compatibility
    
    Author: Advanced Lua Script Library
]]

-- Main library table
local ESPLib = {
    Version = "1.0.0",
    Author = "Advanced Lua Script Library",
    Config = {
        ESP = {
            Enabled = false,
            BoxEnabled = true,
            NameEnabled = true,
            DistanceEnabled = true,
            TracerEnabled = true,
            HealthEnabled = true,
            BoxColor = Color3.fromRGB(255, 0, 0),
            BoxThickness = 1,
            TextColor = Color3.fromRGB(255, 255, 255),
            TextSize = 13,
            TextOutline = true,
            TracerColor = Color3.fromRGB(255, 0, 0),
            TracerThickness = 1,
            TracerOrigin = "Bottom", -- "Bottom", "Center", "Mouse"
            MaxDistance = 1000,
            TeamCheck = false,
            TeamColor = false,
            RainbowMode = false
        },
        UI = {
            Title = "Universal ESP",
            Theme = {
                Background = Color3.fromRGB(25, 25, 35),
                TopBar = Color3.fromRGB(30, 30, 45),
                TextColor = Color3.fromRGB(255, 255, 255),
                TabColor = Color3.fromRGB(35, 35, 50),
                TabTextColor = Color3.fromRGB(255, 255, 255),
                TabActiveColor = Color3.fromRGB(40, 120, 255),
                AccentColor = Color3.fromRGB(40, 120, 255),
                EnabledColor = Color3.fromRGB(40, 200, 120),
                DisabledColor = Color3.fromRGB(200, 60, 60),
                ButtonColor = Color3.fromRGB(45, 45, 65),
                ButtonHoverColor = Color3.fromRGB(55, 55, 75),
                SliderColor = Color3.fromRGB(40, 120, 255),
                BorderColor = Color3.fromRGB(60, 60, 80),
                Shadow = Color3.fromRGB(0, 0, 0)
            },
            Animation = {
                Speed = 0.2,
                EasingStyle = "Quad", -- Can be "Linear", "Quad", "Cubic", "Sine"
                EnableEffects = true
            }
        }
    },
    Drawing = {}, -- Drawing utility functions
    UI = {}, -- UI components
    ESP = {}, -- ESP functionality
    Utils = {}, -- Utility functions
    Events = {} -- Event system
}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Constants
local SHADOW_OFFSET = Vector2.new(2, 2)

-- Variables for runtime data
local ESPObjects = {}
local UIElements = {}
local Tabs = {}
local ActiveTab = nil
local ScriptActive = true
local LastUpdateTime = 0
local Rainbow = {
    Hue = 0,
    Color = Color3.fromRGB(255, 0, 0)
}

-- Check if DrawingLib is available
if not pcall(function() return Drawing.new end) then
    warn("DrawingLib is not available! ESP features will not work.")
    return nil
end

-- Utility Functions --

-- Easing functions for animations
ESPLib.Utils.Easing = {
    Linear = function(t) return t end,
    
    Quad = {
        In = function(t) return t * t end,
        Out = function(t) return t * (2 - t) end,
        InOut = function(t)
            t = t * 2
            if t < 1 then return t * t / 2 end
            t = t - 1
            return -0.5 * (t * (t - 2) - 1)
        end
    },
    
    Sine = {
        In = function(t) return 1 - math.cos(t * math.pi / 2) end,
        Out = function(t) return math.sin(t * math.pi / 2) end,
        InOut = function(t) return -0.5 * (math.cos(math.pi * t) - 1) end
    },
    
    Cubic = {
        In = function(t) return t * t * t end,
        Out = function(t) return (t - 1) * (t - 1) * (t - 1) + 1 end,
        InOut = function(t)
            t = t * 2
            if t < 1 then return t * t * t / 2 end
            t = t - 2
            return 0.5 * (t * t * t + 2)
        end
    }
}

-- Interpolate between two values using easing
function ESPLib.Utils.Lerp(a, b, t, easingType)
    local easing
    
    if easingType == "Linear" then
        easing = ESPLib.Utils.Easing.Linear
    elseif easingType == "Quad" then
        easing = ESPLib.Utils.Easing.Quad.Out
    elseif easingType == "Cubic" then
        easing = ESPLib.Utils.Easing.Cubic.Out
    elseif easingType == "Sine" then
        easing = ESPLib.Utils.Easing.Sine.Out
    else
        easing = ESPLib.Utils.Easing.Quad.Out -- Default
    end
    
    local easedT = easing(t)
    return a + (b - a) * easedT
end

-- Interpolate between two Vector2 values
function ESPLib.Utils.LerpVector2(a, b, t, easingType)
    local x = ESPLib.Utils.Lerp(a.X, b.X, t, easingType)
    local y = ESPLib.Utils.Lerp(a.Y, b.Y, t, easingType)
    return Vector2.new(x, y)
end

-- Interpolate between two Color3 values
function ESPLib.Utils.LerpColor3(a, b, t, easingType)
    local r = ESPLib.Utils.Lerp(a.R, b.R, t, easingType)
    local g = ESPLib.Utils.Lerp(a.G, b.G, t, easingType)
    local bl = ESPLib.Utils.Lerp(a.B, b.B, t, easingType)
    return Color3.new(r, g, bl)
end

-- Convert 3D world position to 2D screen position
function ESPLib.Utils.WorldToScreen(position)
    local screenPos, onScreen = Camera:WorldToScreenPoint(position)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen, screenPos.Z
end

-- Check if a player is valid for ESP
function ESPLib.Utils.ValidatePlayer(player)
    if player == LocalPlayer then return false end
    if not player.Character then return false end
    if not player.Character:FindFirstChild("HumanoidRootPart") then return false end
    if not player.Character:FindFirstChild("Humanoid") then return false end
    if player.Character.Humanoid.Health <= 0 then return false end
    
    local distance = (player.Character.HumanoidRootPart.Position - Camera.CFrame.Position).Magnitude
    if distance > ESPLib.Config.ESP.MaxDistance then return false end
    
    if ESPLib.Config.ESP.TeamCheck and player.Team == LocalPlayer.Team then return false end
    
    return true
end

-- Get the color for a player's ESP
function ESPLib.Utils.GetPlayerColor(player)
    if ESPLib.Config.ESP.RainbowMode then
        return Rainbow.Color
    end
    
    if ESPLib.Config.ESP.TeamColor and player.Team then
        return player.TeamColor.Color
    end
    
    return ESPLib.Config.ESP.BoxColor
end

-- Calculate the corner positions for the ESP box
function ESPLib.Utils.CalculateCorners(character)
    local hrp = character.HumanoidRootPart
    local head = character:FindFirstChild("Head")
    if not head then return nil end
    
    local torso = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
    if not torso then return nil end
    
    local rootPosition = hrp.Position
    local headPosition = head.Position
    
    local legPos = rootPosition - Vector3.new(0, 3, 0)
    local topPos = headPosition + Vector3.new(0, 0.5, 0)
    
    local size = (topPos - legPos).magnitude / 2
    local cf = CFrame.new(rootPosition, rootPosition + Camera.CFrame.LookVector)
    
    local corners = {
        topLeft = cf * CFrame.new(-size, size, 0),
        topRight = cf * CFrame.new(size, size, 0),
        bottomLeft = cf * CFrame.new(-size, -size, 0),
        bottomRight = cf * CFrame.new(size, -size, 0)
    }
    
    local screenCorners = {}
    for name, position in pairs(corners) do
        local screenPos, onScreen = ESPLib.Utils.WorldToScreen(position.Position)
        if not onScreen then return nil end
        screenCorners[name] = screenPos
    end
    
    return screenCorners
end

-- Update rainbow color
function ESPLib.Utils.UpdateRainbow(deltaTime)
    Rainbow.Hue = (Rainbow.Hue + deltaTime * 0.1) % 1
    
    -- HSV to RGB conversion
    local h, s, v = Rainbow.Hue, 1, 1
    local r, g, b
    
    local hi = math.floor(h * 6) % 6
    local f = h * 6 - hi
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    
    if hi == 0 then r, g, b = v, t, p
    elseif hi == 1 then r, g, b = q, v, p
    elseif hi == 2 then r, g, b = p, v, t
    elseif hi == 3 then r, g, b = p, q, v
    elseif hi == 4 then r, g, b = t, p, v
    elseif hi == 5 then r, g, b = v, p, q
    end
    
    Rainbow.Color = Color3.fromRGB(r * 255, g * 255, b * 255)
end

-- Create a circular pattern for rounded corners
function ESPLib.Utils.CreateCirclePattern(segments)
    local points = {}
    for i = 0, segments do
        local angle = math.rad(i / segments * 360)
        table.insert(points, {
            X = math.cos(angle),
            Y = math.sin(angle)
        })
    end
    return points
end

-- Create a drop shadow for UI elements
function ESPLib.Drawing.CreateShadow(parent, size, position, radius)
    local shadow = Drawing.new("Square")
    shadow.Size = size + Vector2.new(4, 4)
    shadow.Position = position + SHADOW_OFFSET
    shadow.Color = ESPLib.Config.UI.Theme.Shadow
    shadow.Filled = true
    shadow.Transparency = 0.4
    shadow.Visible = parent.Visible
    
    return shadow
end

-- Create a rounded rectangle using polygons
function ESPLib.Drawing.CreateRoundedRect(size, position, radius, color, filled, transparency, visible)
    -- Create background
    local rect = Drawing.new("Square")
    rect.Size = size
    rect.Position = position
    rect.Color = color
    rect.Filled = filled
    rect.Transparency = transparency
    rect.Visible = visible
    
    return rect
end

-- ESP Class --
ESPLib.ESP.Object = {}
ESPLib.ESP.Object.__index = ESPLib.ESP.Object

-- Create a new ESP object for a player
function ESPLib.ESP.Object.new(player)
    local self = setmetatable({
        Player = player,
        Name = nil,
        Box = nil,
        BoxFill = nil,
        Tracer = nil,
        Distance = nil,
        Health = nil,
        HealthBar = nil,
        HealthBarBackground = nil,
        Objects = {},
        Visible = false
    }, ESPLib.ESP.Object)
    
    self:Create()
    return self
end

-- Create the drawing objects for ESP
function ESPLib.ESP.Object:Create()
    -- Box outline
    self.BoxOutline = Drawing.new("Square")
    self.BoxOutline.Visible = false
    self.BoxOutline.Color = Color3.fromRGB(0, 0, 0)
    self.BoxOutline.Thickness = ESPLib.Config.ESP.BoxThickness + 1
    self.BoxOutline.Transparency = 0.8
    self.BoxOutline.Filled = false
    
    -- Box
    self.Box = Drawing.new("Square")
    self.Box.Visible = false
    self.Box.Color = ESPLib.Config.ESP.BoxColor
    self.Box.Thickness = ESPLib.Config.ESP.BoxThickness
    self.Box.Transparency = 1
    self.Box.Filled = false
    
    -- Box fill (for partially transparent fill)
    self.BoxFill = Drawing.new("Square")
    self.BoxFill.Visible = false
    self.BoxFill.Color = ESPLib.Config.ESP.BoxColor
    self.BoxFill.Transparency = 0.15
    self.BoxFill.Filled = true
    
    -- Name
    self.Name = Drawing.new("Text")
    self.Name.Visible = false
    self.Name.Color = ESPLib.Config.ESP.TextColor
    self.Name.Size = ESPLib.Config.ESP.TextSize
    self.Name.Center = true
    self.Name.Outline = ESPLib.Config.ESP.TextOutline
    self.Name.OutlineColor = Color3.fromRGB(0, 0, 0)
    self.Name.Text = self.Player.Name
    
    -- Distance
    self.Distance = Drawing.new("Text")
    self.Distance.Visible = false
    self.Distance.Color = ESPLib.Config.ESP.TextColor
    self.Distance.Size = ESPLib.Config.ESP.TextSize
    self.Distance.Center = true
    self.Distance.Outline = ESPLib.Config.ESP.TextOutline
    self.Distance.OutlineColor = Color3.fromRGB(0, 0, 0)
    
    -- Health bar background
    self.HealthBarBackground = Drawing.new("Square")
    self.HealthBarBackground.Visible = false
    self.HealthBarBackground.Color = Color3.fromRGB(35, 35, 35)
    self.HealthBarBackground.Filled = true
    self.HealthBarBackground.Thickness = 1
    self.HealthBarBackground.Transparency = 0.8
    
    -- Health bar
    self.HealthBar = Drawing.new("Square")
    self.HealthBar.Visible = false
    self.HealthBar.Color = Color3.fromRGB(0, 255, 0)
    self.HealthBar.Filled = true
    self.HealthBar.Thickness = 1
    self.HealthBar.Transparency = 1
    
    -- Health text
    self.Health = Drawing.new("Text")
    self.Health.Visible = false
    self.Health.Color = ESPLib.Config.ESP.TextColor
    self.Health.Size = ESPLib.Config.ESP.TextSize - 2
    self.Health.Center = true
    self.Health.Outline = ESPLib.Config.ESP.TextOutline
    self.Health.OutlineColor = Color3.fromRGB(0, 0, 0)
    
    -- Tracer
    self.Tracer = Drawing.new("Line")
    self.Tracer.Visible = false
    self.Tracer.Color = ESPLib.Config.ESP.TracerColor
    self.Tracer.Thickness = ESPLib.Config.ESP.TracerThickness
    self.Tracer.Transparency = 1
    
    -- Add to objects list
    self.Objects = {
        BoxOutline = self.BoxOutline,
        Box = self.Box,
        BoxFill = self.BoxFill,
        Name = self.Name,
        Distance = self.Distance,
        Health = self.Health,
        HealthBar = self.HealthBar,
        HealthBarBackground = self.HealthBarBackground,
        Tracer = self.Tracer
    }
end

-- Update the ESP elements
function ESPLib.ESP.Object:Update()
    if not ESPLib.Config.ESP.Enabled then
        self:SetVisible(false)
        return
    end
    
    if not ESPLib.Utils.ValidatePlayer(self.Player) then
        self:SetVisible(false)
        return
    end
    
    local character = self.Player.Character
    if not character then
        self:SetVisible(false)
        return
    end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    if not hrp or not humanoid then
        self:SetVisible(false)
        return
    end
    
    -- Calculate distance
    local distance = (hrp.Position - Camera.CFrame.Position).Magnitude
    local distanceText = string.format("%.0f studs", distance)
    
    -- Calculate box corners
    local corners = ESPLib.Utils.CalculateCorners(character)
    if not corners then
        self:SetVisible(false)
        return
    end
    
    -- Get health percentage
    local healthPercentage = humanoid.Health / humanoid.MaxHealth
    local healthText = string.format("%.0f HP", humanoid.Health)
    
    -- Get health bar color based on percentage
    local healthColor
    if healthPercentage > 0.7 then
        healthColor = Color3.fromRGB(0, 255, 0) -- Green
    elseif healthPercentage > 0.3 then
        healthColor = Color3.fromRGB(255, 255, 0) -- Yellow
    else
        healthColor = Color3.fromRGB(255, 0, 0) -- Red
    end
    
    -- Update box
    if ESPLib.Config.ESP.BoxEnabled then
        local boxSize = Vector2.new(
            corners.topRight.X - corners.topLeft.X,
            corners.bottomLeft.Y - corners.topLeft.Y
        )
        
        self.BoxOutline.Size = boxSize
        self.BoxOutline.Position = corners.topLeft
        self.BoxOutline.Visible = true
        
        self.Box.Size = boxSize
        self.Box.Position = corners.topLeft
        self.Box.Color = ESPLib.Utils.GetPlayerColor(self.Player)
        self.Box.Visible = true
        
        self.BoxFill.Size = boxSize
        self.BoxFill.Position = corners.topLeft
        self.BoxFill.Color = ESPLib.Utils.GetPlayerColor(self.Player)
        self.BoxFill.Visible = true
    else
        self.BoxOutline.Visible = false
        self.Box.Visible = false
        self.BoxFill.Visible = false
    end
    
    -- Update name
    if ESPLib.Config.ESP.NameEnabled then
        self.Name.Position = Vector2.new(
            (corners.topLeft.X + corners.topRight.X) / 2,
            corners.topLeft.Y - 20
        )
        self.Name.Visible = true
    else
        self.Name.Visible = false
    end
    
    -- Update distance
    if ESPLib.Config.ESP.DistanceEnabled then
        self.Distance.Text = distanceText
        self.Distance.Position = Vector2.new(
            (corners.bottomLeft.X + corners.bottomRight.X) / 2,
            corners.bottomLeft.Y + 5
        )
        self.Distance.Visible = true
    else
        self.Distance.Visible = false
    end
    
    -- Update health bar
    if ESPLib.Config.ESP.HealthEnabled then
        local barWidth = 4
        local barHeight = corners.bottomLeft.Y - corners.topLeft.Y
        
        self.HealthBarBackground.Size = Vector2.new(barWidth, barHeight)
        self.HealthBarBackground.Position = Vector2.new(corners.topLeft.X - barWidth - 3, corners.topLeft.Y)
        self.HealthBarBackground.Visible = true
        
        self.HealthBar.Size = Vector2.new(barWidth, barHeight * healthPercentage)
        self.HealthBar.Position = Vector2.new(
            corners.topLeft.X - barWidth - 3,
            corners.topLeft.Y + barHeight * (1 - healthPercentage)
        )
        self.HealthBar.Color = healthColor
        self.HealthBar.Visible = true
        
        self.Health.Text = healthText
        self.Health.Position = Vector2.new(
            corners.topLeft.X - barWidth - 3 - 20,
            corners.topLeft.Y + barHeight / 2
        )
        self.Health.Visible = true
    else
        self.HealthBarBackground.Visible = false
        self.HealthBar.Visible = false
        self.Health.Visible = false
    end
    
    -- Update tracer
    if ESPLib.Config.ESP.TracerEnabled then
        local tracerOrigin
        if ESPLib.Config.ESP.TracerOrigin == "Bottom" then
            tracerOrigin = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
        elseif ESPLib.Config.ESP.TracerOrigin == "Center" then
            tracerOrigin = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        elseif ESPLib.Config.ESP.TracerOrigin == "Mouse" then
            tracerOrigin = UserInputService:GetMouseLocation()
        end
        
        local targetPos = Vector2.new(
            (corners.bottomLeft.X + corners.bottomRight.X) / 2,
            corners.bottomLeft.Y
        )
        
        self.Tracer.From = tracerOrigin
        self.Tracer.To = targetPos
        self.Tracer.Color = ESPLib.Utils.GetPlayerColor(self.Player)
        self.Tracer.Visible = true
    else
        self.Tracer.Visible = false
    end
    
    self.Visible = true
end

-- Set visibility of all ESP elements
function ESPLib.ESP.Object:SetVisible(visible)
    self.Visible = visible
    for _, object in pairs(self.Objects) do
        if object then
            object.Visible = visible and (
                (object == self.BoxOutline and ESPLib.Config.ESP.BoxEnabled) or
                (object == self.Box and ESPLib.Config.ESP.BoxEnabled) or
                (object == self.BoxFill and ESPLib.Config.ESP.BoxEnabled) or
                (object == self.Name and ESPLib.Config.ESP.NameEnabled) or
                (object == self.Distance and ESPLib.Config.ESP.DistanceEnabled) or
                (object == self.Health and ESPLib.Config.ESP.HealthEnabled) or
                (object == self.HealthBar and ESPLib.Config.ESP.HealthEnabled) or
                (object == self.HealthBarBackground and ESPLib.Config.ESP.HealthEnabled) or
                (object == self.Tracer and ESPLib.Config.ESP.TracerEnabled)
            )
        end
    end
end

-- Remove ESP object and clean up
function ESPLib.ESP.Object:Remove()
    for _, object in pairs(self.Objects) do
        if object then
            object:Remove()
        end
    end
    self.Objects = {}
end

-- ESP Manager
ESPLib.ESP.Manager = {}

-- Initialize the ESP system
function ESPLib.ESP.Manager.Init()
    -- Create ESP objects for existing players
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            ESPObjects[player.Name] = ESPLib.ESP.Object.new(player)
        end
    end
    
    -- Handle player joining
    Players.PlayerAdded:Connect(function(player)
        ESPObjects[player.Name] = ESPLib.ESP.Object.new(player)
    end)
    
    -- Handle player leaving
    Players.PlayerRemoving:Connect(function(player)
        if ESPObjects[player.Name] then
            ESPObjects[player.Name]:Remove()
            ESPObjects[player.Name] = nil
        end
    end)
    
    -- Update ESP objects
    RunService:BindToRenderStep("ESP", 200, function()
        local currentTime = tick()
        local deltaTime = currentTime - LastUpdateTime
        LastUpdateTime = currentTime
        
        if ESPLib.Config.ESP.RainbowMode then
            ESPLib.Utils.UpdateRainbow(deltaTime)
        end
        
        for _, espObject in pairs(ESPObjects) do
            if ESPLib.Config.ESP.Enabled then
                espObject:Update()
            else
                espObject:SetVisible(false)
            end
        end
    end)
end

-- Toggle ESP functionality
function ESPLib.ESP.Manager.Toggle()
    ESPLib.Config.ESP.Enabled = not ESPLib.Config.ESP.Enabled
    
    if not ESPLib.Config.ESP.Enabled then
        -- Clean up all ESP objects
        for _, espObject in pairs(ESPObjects) do
            espObject:SetVisible(false)
        end
    end
    
    return ESPLib.Config.ESP.Enabled
end

-- Clean up ESP system
function ESPLib.ESP.Manager.Cleanup()
    RunService:UnbindFromRenderStep("ESP")
    for _, espObject in pairs(ESPObjects) do
        espObject:Remove()
    end
    ESPObjects = {}
end

-- UI Component Base Class
ESPLib.UI.Base = {}
ESPLib.UI.Base.__index = ESPLib.UI.Base

-- UI Framework
ESPLib.UI.Framework = {}
ESPLib.UI.Framework.__index = ESPLib.UI.Framework

-- Create a new UI framework
function ESPLib.UI.Framework.new()
    local self = setmetatable({
        Tabs = {},
        ActiveTab = nil,
        Visible = false,
        Draggable = true,
        Elements = {},
        Position = Vector2.new(100, 100),
        Size = Vector2.new(500, 380),
        Theme = ESPLib.Config.UI.Theme
    }, ESPLib.UI.Framework)
    
    self:Create()
    return self
end

-- Create the UI elements
function ESPLib.UI.Framework:Create()
    -- Main frame shadow
    self.MainShadow = Drawing.new("Square")
    self.MainShadow.Size = self.Size + Vector2.new(10, 10)
    self.MainShadow.Position = self.Position + Vector2.new(-5, -5)
    self.MainShadow.Color = Color3.fromRGB(0, 0, 0)
    self.MainShadow.Filled = true
    self.MainShadow.Transparency = 0.4
    self.MainShadow.Visible = false
    
    -- Main frame
    self.MainFrame = Drawing.new("Square")
    self.MainFrame.Size = self.Size
    self.MainFrame.Position = self.Position
    self.MainFrame.Color = self.Theme.Background
    self.MainFrame.Filled = true
    self.MainFrame.Transparency = 0.9
    self.MainFrame.Visible = false
    
    -- Main frame border
    self.MainBorder = Drawing.new("Square")
    self.MainBorder.Size = self.Size
    self.MainBorder.Position = self.Position
    self.MainBorder.Color = self.Theme.BorderColor
    self.MainBorder.Filled = false
    self.MainBorder.Thickness = 1
    self.MainBorder.Transparency = 0.5
    self.MainBorder.Visible = false
    
    -- Title bar
    self.TitleBar = Drawing.new("Square")
    self.TitleBar.Size = Vector2.new(self.Size.X, 30)
    self.TitleBar.Position = self.Position
    self.TitleBar.Color = self.Theme.TopBar
    self.TitleBar.Filled = true
    self.TitleBar.Transparency = 1
    self.TitleBar.Visible = false
    
    -- Title bar accent
    self.TitleAccent = Drawing.new("Square")
    self.TitleAccent.Size = Vector2.new(self.Size.X, 2)
    self.TitleAccent.Position = Vector2.new(self.Position.X, self.Position.Y + 30)
    self.TitleAccent.Color = self.Theme.AccentColor
    self.TitleAccent.Filled = true
    self.TitleAccent.Transparency = 1
    self.TitleAccent.Visible = false
    
    -- Title text
    self.TitleText = Drawing.new("Text")
    self.TitleText.Text = ESPLib.Config.UI.Title
    self.TitleText.Size = 20
    self.TitleText.Position = Vector2.new(self.Position.X + 10, self.Position.Y + 5)
    self.TitleText.Color = self.Theme.TextColor
    self.TitleText.Outline = true
    self.TitleText.OutlineColor = Color3.fromRGB(0, 0, 0)
    self.TitleText.Visible = false
    
    -- Version text
    self.VersionText = Drawing.new("Text")
    self.VersionText.Text = "v" .. ESPLib.Version
    self.VersionText.Size = 14
    self.VersionText.Position = Vector2.new(
        self.Position.X + self.Size.X - 70,
        self.Position.Y + 8
    )
    self.VersionText.Color = Color3.fromRGB(150, 150, 150)
    self.VersionText.Outline = false
    self.VersionText.Visible = false
    
    -- Close button
    self.CloseButton = Drawing.new("Square")
    self.CloseButton.Size = Vector2.new(20, 20)
    self.CloseButton.Position = Vector2.new(
        self.Position.X + self.Size.X - 25,
        self.Position.Y + 5
    )
    self.CloseButton.Color = Color3.fromRGB(255, 70, 70)
    self.CloseButton.Filled = true
    self.CloseButton.Transparency = 1
    self.CloseButton.Visible = false
    
    -- Close button X
    self.CloseX = Drawing.new("Text")
    self.CloseX.Text = "×"
    self.CloseX.Size = 24
    self.CloseX.Center = true
    self.CloseX.Position = Vector2.new(
        self.Position.X + self.Size.X - 15,
        self.Position.Y + 2
    )
    self.CloseX.Color = Color3.fromRGB(255, 255, 255)
    self.CloseX.Outline = false
    self.CloseX.Visible = false
    
    -- Tab bar
    self.TabBar = Drawing.new("Square")
    self.TabBar.Size = Vector2.new(self.Size.X, 40)
    self.TabBar.Position = Vector2.new(self.Position.X, self.Position.Y + 32)
    self.TabBar.Color = self.Theme.TabColor
    self.TabBar.Filled = true
    self.TabBar.Transparency = 1
    self.TabBar.Visible = false
    
    -- Tab content area
    self.ContentArea = Drawing.new("Square")
    self.ContentArea.Size = Vector2.new(self.Size.X, self.Size.Y - 72)
    self.ContentArea.Position = Vector2.new(self.Position.X, self.Position.Y + 72)
    self.ContentArea.Color = self.Theme.Background
    self.ContentArea.Filled = true
    self.ContentArea.Transparency = 0.5
    self.ContentArea.Visible = false
    
    -- Build the UI elements list
    self.Elements = {
        self.MainShadow,
        self.MainFrame,
        self.MainBorder,
        self.TitleBar,
        self.TitleAccent,
        self.TitleText,
        self.VersionText,
        self.CloseButton,
        self.CloseX,
        self.TabBar,
        self.ContentArea
    }
    
    -- Create tabs
    self:CreateTabs()
    
    -- Set up input handling for dragging and buttons
    self:SetupInput()
end

-- Create a tab
function ESPLib.UI.Framework:CreateTab(name, offset)
    local tabWidth = 100
    local tabPosition = Vector2.new(self.Position.X + offset, self.Position.Y + 32)
    
    -- Tab button background
    local tabBg = Drawing.new("Square")
    tabBg.Size = Vector2.new(tabWidth, 40)
    tabBg.Position = tabPosition
    tabBg.Color = self.Theme.TabColor
    tabBg.Filled = true
    tabBg.Transparency = 1
    tabBg.Visible = false
    
    -- Tab button text
    local tabText = Drawing.new("Text")
    tabText.Text = name
    tabText.Size = 16
    tabText.Center = true
    tabText.Position = Vector2.new(tabPosition.X + tabWidth/2, tabPosition.Y + 10)
    tabText.Color = self.Theme.TabTextColor
    tabText.Outline = true
    tabText.OutlineColor = Color3.fromRGB(0, 0, 0)
    tabText.Visible = false
    
    -- Tab indicator (active indicator)
    local tabIndicator = Drawing.new("Square")
    tabIndicator.Size = Vector2.new(tabWidth, 4)
    tabIndicator.Position = Vector2.new(tabPosition.X, tabPosition.Y + 36)
    tabIndicator.Color = self.Theme.AccentColor
    tabIndicator.Filled = true
    tabIndicator.Transparency = 0
    tabIndicator.Visible = false
    
    -- Tab button with its elements
    local tabButton = {
        Square = tabBg,
        Text = tabText,
        Indicator = tabIndicator,
        Position = tabPosition,
        Size = Vector2.new(tabWidth, 40),
        Active = false,
        Hovering = false
    }
    
    -- Create tab with elements
    local tab = {
        Name = name,
        Button = tabButton,
        Elements = {tabBg, tabText, tabIndicator},
        Position = self.ContentArea.Position,
        Size = self.ContentArea.Size,
        Visible = false
    }
    
    -- Add tab to tabs list
    table.insert(self.Tabs, tab)
    
    -- Set first tab as active by default
    if #self.Tabs == 1 then
        self:SetActiveTab(tab)
    end
    
    return tab
end

-- Set active tab
function ESPLib.UI.Framework:SetActiveTab(tab)
    -- Deactivate current active tab
    if self.ActiveTab then
        self.ActiveTab.Button.Active = false
        self.ActiveTab.Button.Indicator.Transparency = 0
        self.ActiveTab.Visible = false
        
        -- Hide all elements in the previously active tab
        for _, element in pairs(self.ActiveTab.Elements) do
            if element ~= self.ActiveTab.Button.Square and 
               element ~= self.ActiveTab.Button.Text and
               element ~= self.ActiveTab.Button.Indicator then
                if type(element) == "table" and element.Type then
                    -- Handle UI components
                    for _, obj in pairs(element.Objects) do
                        if obj then obj.Visible = false end
                    end
                elseif element and element.Visible ~= nil then
                    -- Handle drawing objects
                    element.Visible = false
                end
            end
        end
    end
    
    -- Activate new tab
    self.ActiveTab = tab
    self.ActiveTab.Button.Active = true
    self.ActiveTab.Button.Indicator.Transparency = 1
    self.ActiveTab.Visible = true
    
    -- Show all elements in the active tab
    if self.Visible then
        for _, element in pairs(self.ActiveTab.Elements) do
            if element ~= self.ActiveTab.Button.Square and 
               element ~= self.ActiveTab.Button.Text and
               element ~= self.ActiveTab.Button.Indicator then
                if type(element) == "table" and element.Type then
                    -- Handle UI components
                    for _, obj in pairs(element.Objects) do
                        if obj then obj.Visible = true end
                    end
                elseif element and element.Visible ~= nil then
                    -- Handle drawing objects
                    element.Visible = true
                end
            end
        end
    end
end

-- Create a toggle button
function ESPLib.UI.Framework:CreateToggle(tab, text, initialValue, callback, position)
    -- Create toggle track (background)
    local toggleTrack = Drawing.new("Square")
    toggleTrack.Size = Vector2.new(40, 20)
    toggleTrack.Position = Vector2.new(self.ContentArea.Position.X + position.X, self.ContentArea.Position.Y + position.Y)
    toggleTrack.Color = Color3.fromRGB(60, 60, 60)
    toggleTrack.Filled = true
    toggleTrack.Transparency = 1
    toggleTrack.Visible = false
    
    -- Create toggle track rounded corners
    local toggleTrackOutline = Drawing.new("Square")
    toggleTrackOutline.Size = Vector2.new(42, 22)
    toggleTrackOutline.Position = Vector2.new(self.ContentArea.Position.X + position.X - 1, self.ContentArea.Position.Y + position.Y - 1)
    toggleTrackOutline.Color = self.Theme.BorderColor
    toggleTrackOutline.Filled = false
    toggleTrackOutline.Thickness = 1
    toggleTrackOutline.Transparency = 0.5
    toggleTrackOutline.Visible = false
    
    -- Create toggle knob (slider)
    local toggleKnob = Drawing.new("Square")
    toggleKnob.Size = Vector2.new(16, 16)
    toggleKnob.Position = Vector2.new(
        self.ContentArea.Position.X + position.X + (initialValue and 22 or 2), 
        self.ContentArea.Position.Y + position.Y + 2
    )
    toggleKnob.Color = Color3.fromRGB(255, 255, 255)
    toggleKnob.Filled = true
    toggleKnob.Transparency = 1
    toggleKnob.Visible = false
    
    -- Create indicator
    local toggleIndicator = Drawing.new("Square")
    toggleIndicator.Size = Vector2.new(40, 20)
    toggleIndicator.Position = Vector2.new(self.ContentArea.Position.X + position.X, self.ContentArea.Position.Y + position.Y)
    toggleIndicator.Color = initialValue and self.Theme.EnabledColor or self.Theme.DisabledColor
    toggleIndicator.Filled = true
    toggleIndicator.Transparency = 0.7
    toggleIndicator.Visible = false
    
    -- Create toggle text
    local toggleText = Drawing.new("Text")
    toggleText.Text = text
    toggleText.Size = 18
    toggleText.Position = Vector2.new(self.ContentArea.Position.X + position.X + 50, self.ContentArea.Position.Y + position.Y + 1)
    toggleText.Color = self.Theme.TextColor
    toggleText.Outline = true
    toggleText.OutlineColor = Color3.fromRGB(0, 0, 0)
    toggleText.Visible = false
    
    -- Create status text
    local statusText = Drawing.new("Text")
    statusText.Text = initialValue and "ON" or "OFF"
    statusText.Size = 14
    statusText.Position = Vector2.new(self.ContentArea.Position.X + position.X + 150, self.ContentArea.Position.Y + position.Y + 3)
    statusText.Color = initialValue and self.Theme.EnabledColor or self.Theme.DisabledColor
    statusText.Outline = true
    statusText.OutlineColor = Color3.fromRGB(0, 0, 0)
    statusText.Visible = false
    
    -- Add animation properties and functions
    local toggle = {
        Type = "Toggle",
        Value = initialValue,
        Track = toggleTrack,
        TrackOutline = toggleTrackOutline,
        Knob = toggleKnob,
        Indicator = toggleIndicator,
        Text = toggleText,
        Status = statusText,
        Position = position,
        Size = Vector2.new(40, 20),
        Callback = callback,
        IsAnimating = false,
        LastUpdateTime = 0,
        Hovering = false,
        Objects = {}
    }
    
    -- Add all objects to the toggle's object list
    toggle.Objects = {
        toggleTrack,
        toggleTrackOutline,
        toggleKnob,
        toggleIndicator,
        toggleText,
        statusText
    }
    
    -- Function to update toggle state with animation
    function toggle:SetValue(value)
        self.Value = value
        self.Status.Text = value and "ON" or "OFF"
        self.Status.Color = value and ESPLib.Config.UI.Theme.EnabledColor or ESPLib.Config.UI.Theme.DisabledColor
        self.Indicator.Color = value and ESPLib.Config.UI.Theme.EnabledColor or ESPLib.Config.UI.Theme.DisabledColor
        self.IsAnimating = true
        self.LastUpdateTime = tick()
        
        self.Callback(value)
    end
    
    -- Function to update toggle visual state
    function toggle:Update()
        if self.IsAnimating then
            local elapsed = tick() - self.LastUpdateTime
            local duration = ESPLib.Config.UI.Animation.Speed
            local progress = math.min(elapsed / duration, 1)
            
            local easingStyle = ESPLib.Config.UI.Animation.EasingStyle
            local startX = self.Value and 2 or 22
            local endX = self.Value and 22 or 2
            local currentX = ESPLib.Utils.Lerp(startX, endX, progress, easingStyle)
            
            self.Knob.Position = Vector2.new(
                self.Track.Position.X + currentX,
                self.Knob.Position.Y
            )
            
            if progress >= 1 then
                self.IsAnimating = false
            end
        end
        
        if self.Hovering then
            self.TrackOutline.Transparency = 0.8
            self.Text.Size = 19
        else
            self.TrackOutline.Transparency = 0.5
            self.Text.Size = 18
        end
    end
    
    -- Add all elements to the tab
    table.insert(tab.Elements, toggle)
    
    return toggle
end

-- Create a color picker
function ESPLib.UI.Framework:CreateColorPicker(tab, text, initialColor, callback, position)
    local pickerSize = Vector2.new(30, 30)
    
    -- Create color picker label
    local colorLabel = Drawing.new("Text")
    colorLabel.Text = text
    colorLabel.Size = 18
    colorLabel.Position = Vector2.new(self.ContentArea.Position.X + position.X, self.ContentArea.Position.Y + position.Y)
    colorLabel.Color = self.Theme.TextColor
    colorLabel.Outline = true
    colorLabel.OutlineColor = Color3.fromRGB(0, 0, 0)
    colorLabel.Visible = false
    
    -- Create color picker display
    local colorDisplay = Drawing.new("Square")
    colorDisplay.Size = pickerSize
    colorDisplay.Position = Vector2.new(self.ContentArea.Position.X + position.X, self.ContentArea.Position.Y + position.Y + 25)
    colorDisplay.Color = initialColor
    colorDisplay.Filled = true
    colorDisplay.Transparency = 1
    colorDisplay.Visible = false
    
    -- Create color picker outline
    local colorOutline = Drawing.new("Square")
    colorOutline.Size = Vector2.new(pickerSize.X + 2, pickerSize.Y + 2)
    colorOutline.Position = Vector2.new(self.ContentArea.Position.X + position.X - 1, self.ContentArea.Position.Y + position.Y + 24)
    colorOutline.Color = self.Theme.BorderColor
    colorOutline.Filled = false
    colorOutline.Thickness = 1
    colorOutline.Transparency = 0.7
    colorOutline.Visible = false
    
    -- Create RGB values text
    local rgbText = Drawing.new("Text")
    rgbText.Text = string.format("RGB: %d, %d, %d", 
        math.floor(initialColor.R * 255),
        math.floor(initialColor.G * 255),
        math.floor(initialColor.B * 255)
    )
    rgbText.Size = 14
    rgbText.Position = Vector2.new(self.ContentArea.Position.X + position.X + 40, self.ContentArea.Position.Y + position.Y + 30)
    rgbText.Color = self.Theme.TextColor
    rgbText.Outline = true
    rgbText.OutlineColor = Color3.fromRGB(0, 0, 0)
    rgbText.Visible = false
    
    -- Create color picker panels (hidden by default, shown when clicked)
    local huePicker = Drawing.new("Image")
    huePicker.Size = Vector2.new(150, 20)
    huePicker.Position = Vector2.new(self.ContentArea.Position.X + position.X, self.ContentArea.Position.Y + position.Y + 65)
    huePicker.Transparency = 1
    huePicker.Visible = false
    
    local colorPanel = Drawing.new("Square")
    colorPanel.Size = Vector2.new(150, 150)
    colorPanel.Position = Vector2.new(self.ContentArea.Position.X + position.X, self.ContentArea.Position.Y + position.Y + 90)
    colorPanel.Color = initialColor
    colorPanel.Filled = true
    colorPanel.Transparency = 1
    colorPanel.Visible = false
    
    -- Create color picker component
    local colorPicker = {
        Type = "ColorPicker",
        Value = initialColor,
        IsOpen = false,
        Label = colorLabel,
        Display = colorDisplay,
        Outline = colorOutline,
        RGBText = rgbText,
        HuePicker = huePicker,
        ColorPanel = colorPanel,
        Position = position,
        Size = pickerSize,
        Callback = callback,
        Hovering = false,
        Active = false,
        Objects = {
            colorLabel,
            colorDisplay,
            colorOutline,
            rgbText,
            huePicker,
            colorPanel
        }
    }
    
    -- Function to update the color
    function colorPicker:SetColor(color)
        self.Value = color
        self.Display.Color = color
        self.RGBText.Text = string.format("RGB: %d, %d, %d", 
            math.floor(color.R * 255),
            math.floor(color.G * 255),
            math.floor(color.B * 255)
        )
        self.Callback(color)
    end
    
    -- Function to toggle the color picker panel
    function colorPicker:Toggle()
        self.IsOpen = not self.IsOpen
        self.HuePicker.Visible = self.IsOpen
        self.ColorPanel.Visible = self.IsOpen
    end
    
    -- Function to update visual state
    function colorPicker:Update()
        if self.Hovering then
            self.Outline.Transparency = 1
            self.Label.Size = 19
        else
            self.Outline.Transparency = 0.7
            self.Label.Size = 18
        end
    end
    
    -- Add elements to the tab
    table.insert(tab.Elements, colorPicker)
    
    return colorPicker
end

-- Create a slider
function ESPLib.UI.Framework:CreateSlider(tab, text, min, max, initialValue, callback, position)
    local sliderWidth = 200
    local sliderHeight = 10
    
    -- Create slider text
    local sliderText = Drawing.new("Text")
    sliderText.Text = text .. ": " .. tostring(initialValue)
    sliderText.Size = 18
    sliderText.Position = Vector2.new(self.ContentArea.Position.X + position.X, self.ContentArea.Position.Y + position.Y)
    sliderText.Color = self.Theme.TextColor
    sliderText.Outline = true
    sliderText.OutlineColor = Color3.fromRGB(0, 0, 0)
    sliderText.Visible = false
    
    -- Create slider background
    local sliderBackground = Drawing.new("Square")
    sliderBackground.Size = Vector2.new(sliderWidth, sliderHeight)
    sliderBackground.Position = Vector2.new(self.ContentArea.Position.X + position.X, self.ContentArea.Position.Y + position.Y + 25)
    sliderBackground.Color = Color3.fromRGB(60, 60, 60)
    sliderBackground.Filled = true
    sliderBackground.Transparency = 1
    sliderBackground.Visible = false
    
    -- Create slider outline
    local sliderOutline = Drawing.new("Square")
    sliderOutline.Size = Vector2.new(sliderWidth + 2, sliderHeight + 2)
    sliderOutline.Position = Vector2.new(self.ContentArea.Position.X + position.X - 1, self.ContentArea.Position.Y + position.Y + 24)
    sliderOutline.Color = self.Theme.BorderColor
    sliderOutline.Filled = false
    sliderOutline.Thickness = 1
    sliderOutline.Transparency = 0.5
    sliderOutline.Visible = false
    
    -- Create slider fill
    local fillWidth = (initialValue - min) / (max - min) * sliderWidth
    local sliderFill = Drawing.new("Square")
    sliderFill.Size = Vector2.new(fillWidth, sliderHeight)
    sliderFill.Position = Vector2.new(self.ContentArea.Position.X + position.X, self.ContentArea.Position.Y + position.Y + 25)
    sliderFill.Color = self.Theme.SliderColor
    sliderFill.Filled = true
    sliderFill.Transparency = 1
    sliderFill.Visible = false
    
    -- Create slider knob
    local sliderKnob = Drawing.new("Square")
    sliderKnob.Size = Vector2.new(10, 20)
    sliderKnob.Position = Vector2.new(
        self.ContentArea.Position.X + position.X + fillWidth - 5,
        self.ContentArea.Position.Y + position.Y + 20
    )
    sliderKnob.Color = Color3.fromRGB(255, 255, 255)
    sliderKnob.Filled = true
    sliderKnob.Transparency = 1
    sliderKnob.Visible = false
    
    -- Create slider min max text
    local sliderMinText = Drawing.new("Text")
    sliderMinText.Text = tostring(min)
    sliderMinText.Size = 14
    sliderMinText.Position = Vector2.new(self.ContentArea.Position.X + position.X, self.ContentArea.Position.Y + position.Y + 40)
    sliderMinText.Color = Color3.fromRGB(150, 150, 150)
    sliderMinText.Outline = false
    sliderMinText.Visible = false
    
    local sliderMaxText = Drawing.new("Text")
    sliderMaxText.Text = tostring(max)
    sliderMaxText.Size = 14
    sliderMaxText.Position = Vector2.new(
        self.ContentArea.Position.X + position.X + sliderWidth - 20,
        self.ContentArea.Position.Y + position.Y + 40
    )
    sliderMaxText.Color = Color3.fromRGB(150, 150, 150)
    sliderMaxText.Outline = false
    sliderMaxText.Visible = false
    
    -- Create slider component
    local slider = {
        Type = "Slider",
        Value = initialValue,
        Min = min,
        Max = max,
        Text = sliderText,
        Background = sliderBackground,
        Outline = sliderOutline,
        Fill = sliderFill,
        Knob = sliderKnob,
        MinText = sliderMinText,
        MaxText = sliderMaxText,
        Position = position,
        Size = Vector2.new(sliderWidth, sliderHeight),
        Callback = callback,
        Dragging = false,
        Hovering = false,
        Objects = {
            sliderText,
            sliderBackground,
            sliderOutline,
            sliderFill,
            sliderKnob,
            sliderMinText,
            sliderMaxText
        }
    }
    
    -- Function to update slider value
    function slider:SetValue(value, fromUserInput)
        value = math.clamp(value, self.Min, self.Max)
        self.Value = value
        
        -- Update text
        self.Text.Text = text .. ": " .. string.format("%.1f", value)
        
        -- Update fill and knob
        local fillWidth = (value - self.Min) / (self.Max - self.Min) * self.Size.X
        self.Fill.Size = Vector2.new(fillWidth, self.Size.Y)
        
        self.Knob.Position = Vector2.new(
            self.Background.Position.X + fillWidth - 5,
            self.Knob.Position.Y
        )
        
        -- Call callback if the change came from user input
        if fromUserInput then
            self.Callback(value)
        end
    end
    
    -- Function to update visual state
    function slider:Update()
        if self.Hovering or self.Dragging then
            self.Outline.Transparency = 0.8
            self.Text.Size = 19
        else
            self.Outline.Transparency = 0.5
            self.Text.Size = 18
        end
    end
    
    -- Add elements to the tab
    table.insert(tab.Elements, slider)
    
    return slider
end

-- Create dropdown
function ESPLib.UI.Framework:CreateDropdown(tab, text, options, initialValue, callback, position)
    local dropdownWidth = 200
    local dropdownHeight = 30
    
    -- Create dropdown text
    local dropdownText = Drawing.new("Text")
    dropdownText.Text = text
    dropdownText.Size = 18
    dropdownText.Position = Vector2.new(self.ContentArea.Position.X + position.X, self.ContentArea.Position.Y + position.Y)
    dropdownText.Color = self.Theme.TextColor
    dropdownText.Outline = true
    dropdownText.OutlineColor = Color3.fromRGB(0, 0, 0)
    dropdownText.Visible = false
    
    -- Create dropdown background
    local dropdownBackground = Drawing.new("Square")
    dropdownBackground.Size = Vector2.new(dropdownWidth, dropdownHeight)
    dropdownBackground.Position = Vector2.new(self.ContentArea.Position.X + position.X, self.ContentArea.Position.Y + position.Y + 25)
    dropdownBackground.Color = self.Theme.ButtonColor
    dropdownBackground.Filled = true
    dropdownBackground.Transparency = 1
    dropdownBackground.Visible = false
    
    -- Create dropdown outline
    local dropdownOutline = Drawing.new("Square")
    dropdownOutline.Size = Vector2.new(dropdownWidth + 2, dropdownHeight + 2)
    dropdownOutline.Position = Vector2.new(self.ContentArea.Position.X + position.X - 1, self.ContentArea.Position.Y + position.Y + 24)
    dropdownOutline.Color = self.Theme.BorderColor
    dropdownOutline.Filled = false
    dropdownOutline.Thickness = 1
    dropdownOutline.Transparency = 0.5
    dropdownOutline.Visible = false
    
    -- Create dropdown value text
    local valueText = Drawing.new("Text")
    valueText.Text = initialValue
    valueText.Size = 16
    valueText.Position = Vector2.new(self.ContentArea.Position.X + position.X + 10, self.ContentArea.Position.Y + position.Y + 30)
    valueText.Color = self.Theme.TextColor
    valueText.Outline = true
    valueText.OutlineColor = Color3.fromRGB(0, 0, 0)
    valueText.Visible = false
    
    -- Create dropdown arrow
    local dropdownArrow = Drawing.new("Text")
    dropdownArrow.Text = "▼"
    dropdownArrow.Size = 14
    dropdownArrow.Position = Vector2.new(
        self.ContentArea.Position.X + position.X + dropdownWidth - 20,
        self.ContentArea.Position.Y + position.Y + 30
    )
    dropdownArrow.Color = self.Theme.TextColor
    dropdownArrow.Outline = true
    dropdownArrow.OutlineColor = Color3.fromRGB(0, 0, 0)
    dropdownArrow.Visible = false
    
    -- Create option container (shown when dropdown is open)
    local optionContainer = Drawing.new("Square")
    optionContainer.Size = Vector2.new(dropdownWidth, #options * 25)
    optionContainer.Position = Vector2.new(
        self.ContentArea.Position.X + position.X,
        self.ContentArea.Position.Y + position.Y + 25 + dropdownHeight
    )
    optionContainer.Color = self.Theme.ButtonColor
    optionContainer.Filled = true
    optionContainer.Transparency = 1
    optionContainer.Visible = false
    
    -- Create option container outline
    local optionOutline = Drawing.new("Square")
    optionOutline.Size = Vector2.new(dropdownWidth + 2, #options * 25 + 2)
    optionOutline.Position = Vector2.new(
        self.ContentArea.Position.X + position.X - 1,
        self.ContentArea.Position.Y + position.Y + 24 + dropdownHeight
    )
    optionOutline.Color = self.Theme.BorderColor
    optionOutline.Filled = false
    optionOutline.Thickness = 1
    optionOutline.Transparency = 0.5
    optionOutline.Visible = false
    
    -- Create option texts
    local optionTexts = {}
    local optionBackgrounds = {}
    
    for i, option in ipairs(options) do
        local optionBg = Drawing.new("Square")
        optionBg.Size = Vector2.new(dropdownWidth, 25)
        optionBg.Position = Vector2.new(
            self.ContentArea.Position.X + position.X,
            self.ContentArea.Position.Y + position.Y + 25 + dropdownHeight + (i-1) * 25
        )
        optionBg.Color = self.Theme.ButtonColor
        optionBg.Filled = true
        optionBg.Transparency = option == initialValue and 0.8 or 0.5
        optionBg.Visible = false
        table.insert(optionBackgrounds, optionBg)
        
        local optionText = Drawing.new("Text")
        optionText.Text = option
        optionText.Size = 16
        optionText.Position = Vector2.new(
            self.ContentArea.Position.X + position.X + 10,
            self.ContentArea.Position.Y + position.Y + 27 + dropdownHeight + (i-1) * 25
        )
        optionText.Color = self.Theme.TextColor
        optionText.Outline = true
        optionText.OutlineColor = Color3.fromRGB(0, 0, 0)
        optionText.Visible = false
        table.insert(optionTexts, optionText)
    end
    
    -- Create dropdown component
    local dropdown = {
        Type = "Dropdown",
        Value = initialValue,
        Options = options,
        Text = dropdownText,
        Background = dropdownBackground,
        Outline = dropdownOutline,
        ValueText = valueText,
        Arrow = dropdownArrow,
        OptionContainer = optionContainer,
        OptionOutline = optionOutline,
        OptionBackgrounds = optionBackgrounds,
        OptionTexts = optionTexts,
        Position = position,
        Size = Vector2.new(dropdownWidth, dropdownHeight),
        Callback = callback,
        IsOpen = false,
        Hovering = false,
        Objects = {
            dropdownText,
            dropdownBackground,
            dropdownOutline,
            valueText,
            dropdownArrow,
            optionContainer,
            optionOutline
        }
    }
    
    -- Add option backgrounds and texts to objects
    for _, bg in ipairs(optionBackgrounds) do
        table.insert(dropdown.Objects, bg)
    end
    
    for _, txt in ipairs(optionTexts) do
        table.insert(dropdown.Objects, txt)
    end
    
    -- Function to toggle dropdown
    function dropdown:Toggle()
        self.IsOpen = not self.IsOpen
        self.OptionContainer.Visible = self.IsOpen
        self.OptionOutline.Visible = self.IsOpen
        self.Arrow.Text = self.IsOpen and "▲" or "▼"
        
        -- Show/hide options
        for i = 1, #self.Options do
            self.OptionBackgrounds[i].Visible = self.IsOpen
            self.OptionTexts[i].Visible = self.IsOpen
        end
    end
    
    -- Function to select option
    function dropdown:SelectOption(option)
        if not table.find(self.Options, option) then return end
        
        self.Value = option
        self.ValueText.Text = option
        
        -- Update option backgrounds
        for i, opt in ipairs(self.Options) do
            self.OptionBackgrounds[i].Transparency = opt == option and 0.8 or 0.5
        end
        
        self:Toggle() -- Close dropdown
        self.Callback(option)
    end
    
    -- Function to update visual state
    function dropdown:Update()
        if self.Hovering then
            self.Outline.Transparency = 0.8
            self.Text.Size = 19
        else
            self.Outline.Transparency = 0.5
            self.Text.Size = 18
        end
    end
    
    -- Add elements to the tab
    table.insert(tab.Elements, dropdown)
    
    return dropdown
end

-- Create button
function ESPLib.UI.Framework:CreateButton(tab, text, callback, position)
    local buttonWidth = 200
    local buttonHeight = 35
    
    -- Create button background
    local buttonBackground = Drawing.new("Square")
    buttonBackground.Size = Vector2.new(buttonWidth, buttonHeight)
    buttonBackground.Position = Vector2.new(self.ContentArea.Position.X + position.X, self.ContentArea.Position.Y + position.Y)
    buttonBackground.Color = self.Theme.ButtonColor
    buttonBackground.Filled = true
    buttonBackground.Transparency = 0.8
    buttonBackground.Visible = false
    
    -- Create button outline
    local buttonOutline = Drawing.new("Square")
    buttonOutline.Size = Vector2.new(buttonWidth + 2, buttonHeight + 2)
    buttonOutline.Position = Vector2.new(self.ContentArea.Position.X + position.X - 1, self.ContentArea.Position.Y + position.Y - 1)
    buttonOutline.Color = self.Theme.BorderColor
    buttonOutline.Filled = false
    buttonOutline.Thickness = 1
    buttonOutline.Transparency = 0.5
    buttonOutline.Visible = false
    
    -- Create button text
    local buttonText = Drawing.new("Text")
    buttonText.Text = text
    buttonText.Size = 18
    buttonText.Center = true
    buttonText.Position = Vector2.new(
        self.ContentArea.Position.X + position.X + buttonWidth/2,
        self.ContentArea.Position.Y + position.Y + 8
    )
    buttonText.Color = self.Theme.TextColor
    buttonText.Outline = true
    buttonText.OutlineColor = Color3.fromRGB(0, 0, 0)
    buttonText.Visible = false
    
    -- Create button component
    local button = {
        Type = "Button",
        Text = buttonText,
        Background = buttonBackground,
        Outline = buttonOutline,
        Position = position,
        Size = Vector2.new(buttonWidth, buttonHeight),
        Callback = callback,
        IsClicking = false,
        Hovering = false,
        Objects = {
            buttonBackground,
            buttonOutline,
            buttonText
        }
    }
    
    -- Function to update visual state
    function button:Update()
        if self.IsClicking then
            self.Background.Transparency = 1
            self.Background.Color = self.Hovering and 
                self.Parent.Theme.AccentColor or 
                self.Parent.Theme.ButtonColor
        else
            self.Background.Transparency = 0.8
            self.Background.Color = self.Hovering and 
                self.Parent.Theme.ButtonHoverColor or 
                self.Parent.Theme.ButtonColor
        end
        
        if self.Hovering then
            self.Outline.Transparency = 0.8
            self.Text.Size = 19
        else
            self.Outline.Transparency = 0.5
            self.Text.Size = 18
        end
    end
    
    -- Function to trigger button click
    function button:Click()
        self.IsClicking = true
        self:Update()
        
        self.Callback()
        
        task.delay(0.15, function()
            self.IsClicking = false
            self:Update()
        end)
    end
    
    -- Add parent reference
    button.Parent = self
    
    -- Add elements to the tab
    table.insert(tab.Elements, button)
    
    return button
end

-- Create label
function ESPLib.UI.Framework:CreateLabel(tab, text, position, isHeading)
    -- Create label text
    local labelText = Drawing.new("Text")
    labelText.Text = text
    labelText.Size = isHeading and 22 or 18
    labelText.Position = Vector2.new(self.ContentArea.Position.X + position.X, self.ContentArea.Position.Y + position.Y)
    labelText.Color = isHeading and self.Theme.AccentColor or self.Theme.TextColor
    labelText.Outline = true
    labelText.OutlineColor = Color3.fromRGB(0, 0, 0)
    labelText.Visible = false
    
    -- Create underline for headings
    local underline
    if isHeading then
        underline = Drawing.new("Square")
        underline.Size = Vector2.new(#text * 10, 2)
        underline.Position = Vector2.new(
            self.ContentArea.Position.X + position.X,
            self.ContentArea.Position.Y + position.Y + 25
        )
        underline.Color = self.Theme.AccentColor
        underline.Filled = true
        underline.Transparency = 1
        underline.Visible = false
    end
    
    -- Create label component
    local label = {
        Type = "Label",
        Text = labelText,
        Underline = underline,
        Position = position,
        IsHeading = isHeading,
        Objects = {
            labelText
        }
    }
    
    if underline then
        table.insert(label.Objects, underline)
    end
    
    -- Function to update text
    function label:SetText(newText)
        self.Text.Text = newText
        
        if self.IsHeading and self.Underline then
            self.Underline.Size = Vector2.new(#newText * 10, 2)
        end
    end
    
    -- Add elements to the tab
    table.insert(tab.Elements, label)
    
    return label
end

-- Set up input handling
function ESPLib.UI.Framework:SetupInput()
    -- Variables for tracking mouse position and drag state
    local isDragging = false
    local dragOffset = Vector2.new(0, 0)
    
    -- Input began handler
    UserInputService.InputBegan:Connect(function(input)
        -- Toggle UI visibility with Insert key
        if input.KeyCode == Enum.KeyCode.Insert then
            self:Toggle()
            return
        end
        
        -- Unload script with End key
        if input.KeyCode == Enum.KeyCode.End and ScriptActive then
            -- Notify the user
            local unloadLabel = Drawing.new("Text")
            unloadLabel.Text = "Unloading ESP..."
            unloadLabel.Size = 24
            unloadLabel.Center = true
            unloadLabel.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            unloadLabel.Color = Color3.fromRGB(255, 255, 255)
            unloadLabel.Outline = true
            unloadLabel.OutlineColor = Color3.fromRGB(0, 0, 0)
            unloadLabel.Visible = true
            
            -- Clean up ESP
            ESPLib.ESP.Manager.Cleanup()
            
            -- Remove UI
            self:Remove()
            
            -- Set script as inactive
            ScriptActive = false
            
            -- Remove the notification after a short delay
            task.delay(1.5, function()
                unloadLabel:Remove()
            end)
            
            return
        end
        
        if not self.Visible then return end
        
        -- Handle mouse clicks for UI interactions
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mousePos = UserInputService:GetMouseLocation()
            
            -- Check if clicking the title bar (for dragging)
            if mousePos.X >= self.TitleBar.Position.X and
               mousePos.X <= self.TitleBar.Position.X + self.TitleBar.Size.X and
               mousePos.Y >= self.TitleBar.Position.Y and
               mousePos.Y <= self.TitleBar.Position.Y + self.TitleBar.Size.Y then
                
                isDragging = true
                dragOffset = mousePos - self.TitleBar.Position
            end
            
            -- Check if clicking the close button
            if mousePos.X >= self.CloseButton.Position.X and
               mousePos.X <= self.CloseButton.Position.X + self.CloseButton.Size.X and
               mousePos.Y >= self.CloseButton.Position.Y and
               mousePos.Y <= self.CloseButton.Position.Y + self.CloseButton.Size.Y then
                
                self:Toggle()
                return
            end
            
            -- Check if clicking on a tab button
            for _, tab in pairs(self.Tabs) do
                local button = tab.Button
                if mousePos.X >= button.Position.X and
                   mousePos.X <= button.Position.X + button.Size.X and
                   mousePos.Y >= button.Position.Y and
                   mousePos.Y <= button.Position.Y + button.Size.Y then
                    
                    self:SetActiveTab(tab)
                    return
                end
            end
            
            -- Check for clicking on controls in the active tab
            if self.ActiveTab then
                for _, element in pairs(self.ActiveTab.Elements) do
                    if element.Type == "Toggle" then
                        -- Check for clicks on the entire toggle area
                        if mousePos.X >= element.Track.Position.X - 5 and
                           mousePos.X <= element.Track.Position.X + element.Size.X + 55 and
                           mousePos.Y >= element.Track.Position.Y - 5 and
                           mousePos.Y <= element.Track.Position.Y + element.Size.Y + 5 then
                            
                            -- Toggle the value and update visuals with animation
                            element:SetValue(not element.Value)
                            return
                        end
                    elseif element.Type == "Button" then
                        -- Check for clicks on button area
                        if mousePos.X >= element.Background.Position.X and
                           mousePos.X <= element.Background.Position.X + element.Size.X and
                           mousePos.Y >= element.Background.Position.Y and
                           mousePos.Y <= element.Background.Position.Y + element.Size.Y then
                            
                            element:Click()
                            return
                        end
                    elseif element.Type == "Slider" then
                        -- Check for clicks on slider background
                        if mousePos.X >= element.Background.Position.X and
                           mousePos.X <= element.Background.Position.X + element.Size.X and
                           mousePos.Y >= element.Background.Position.Y - 5 and
                           mousePos.Y <= element.Background.Position.Y + element.Size.Y + 5 then
                            
                            element.Dragging = true
                            
                            -- Calculate and set the new value based on mouse position
                            local relX = mousePos.X - element.Background.Position.X
                            local fraction = math.clamp(relX / element.Size.X, 0, 1)
                            local newValue = element.Min + fraction * (element.Max - element.Min)
                            
                            element:SetValue(newValue, true)
                            return
                        end
                    elseif element.Type == "Dropdown" then
                        -- Check for clicks on dropdown header
                        if mousePos.X >= element.Background.Position.X and
                           mousePos.X <= element.Background.Position.X + element.Size.X and
                           mousePos.Y >= element.Background.Position.Y and
                           mousePos.Y <= element.Background.Position.Y + element.Size.Y then
                            
                            element:Toggle()
                            return
                        end
                        
                        -- Check for clicks on dropdown options if open
                        if element.IsOpen then
                            for i, option in ipairs(element.Options) do
                                local optBg = element.OptionBackgrounds[i]
                                
                                if mousePos.X >= optBg.Position.X and
                                   mousePos.X <= optBg.Position.X + optBg.Size.X and
                                   mousePos.Y >= optBg.Position.Y and
                                   mousePos.Y <= optBg.Position.Y + optBg.Size.Y then
                                    
                                    element:SelectOption(option)
                                    return
                                end
                            end
                        end
                    elseif element.Type == "ColorPicker" then
                        -- Check for clicks on color display to toggle picker
                        if mousePos.X >= element.Display.Position.X and
                           mousePos.X <= element.Display.Position.X + element.Size.X and
                           mousePos.Y >= element.Display.Position.Y and
                           mousePos.Y <= element.Display.Position.Y + element.Size.Y then
                            
                            element:Toggle()
                            return
                        end
                    end
                end
            end
        end
    end)
    
    -- Input ended handler
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = false
            
            -- Stop dragging sliders
            if self.ActiveTab then
                for _, element in pairs(self.ActiveTab.Elements) do
                    if element.Type == "Slider" then
                        element.Dragging = false
                    end
                end
            end
        end
    end)
    
    -- Input changed handler for dragging and hover effects
    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            local mousePos = UserInputService:GetMouseLocation()
            
            -- Update UI position when dragging
            if self.Visible and isDragging then
                local newPosition = mousePos - dragOffset
                self:SetPosition(newPosition)
            end
            
            -- Update slider value when dragging
            if self.Visible and self.ActiveTab then
                for _, element in pairs(self.ActiveTab.Elements) do
                    if element.Type == "Slider" and element.Dragging then
                        local relX = mousePos.X - element.Background.Position.X
                        local fraction = math.clamp(relX / element.Size.X, 0, 1)
                        local newValue = element.Min + fraction * (element.Max - element.Min)
                        
                        element:SetValue(newValue, true)
                    end
                end
            end
            
            -- Update hover states for interactive elements
            if self.Visible and self.ActiveTab then
                for _, element in pairs(self.ActiveTab.Elements) do
                    if element.Type == "Toggle" then
                        -- Check if mouse is over the toggle element
                        local isHovering = 
                            mousePos.X >= element.Track.Position.X - 5 and
                            mousePos.X <= element.Track.Position.X + element.Size.X + 55 and
                            mousePos.Y >= element.Track.Position.Y - 5 and
                            mousePos.Y <= element.Track.Position.Y + element.Size.Y + 5
                            
                        element.Hovering = isHovering
                    elseif element.Type == "Button" then
                        -- Check if mouse is over the button
                        local isHovering = 
                            mousePos.X >= element.Background.Position.X and
                            mousePos.X <= element.Background.Position.X + element.Size.X and
                            mousePos.Y >= element.Background.Position.Y and
                            mousePos.Y <= element.Background.Position.Y + element.Size.Y
                            
                        element.Hovering = isHovering
                    elseif element.Type == "Slider" then
                        -- Check if mouse is over the slider
                        local isHovering = 
                            mousePos.X >= element.Background.Position.X and
                            mousePos.X <= element.Background.Position.X + element.Size.X and
                            mousePos.Y >= element.Background.Position.Y - 10 and
                            mousePos.Y <= element.Background.Position.Y + element.Size.Y + 10
                            
                        element.Hovering = isHovering
                    elseif element.Type == "Dropdown" then
                        -- Check if mouse is over the dropdown
                        local isHovering = 
                            mousePos.X >= element.Background.Position.X and
                            mousePos.X <= element.Background.Position.X + element.Size.X and
                            mousePos.Y >= element.Background.Position.Y and
                            mousePos.Y <= element.Background.Position.Y + element.Size.Y
                            
                        element.Hovering = isHovering
                    elseif element.Type == "ColorPicker" then
                        -- Check if mouse is over the color picker
                        local isHovering = 
                            mousePos.X >= element.Display.Position.X - 5 and
                            mousePos.X <= element.Display.Position.X + element.Size.X + 5 and
                            mousePos.Y >= element.Display.Position.Y - 5 and
                            mousePos.Y <= element.Display.Position.Y + element.Size.Y + 5
                            
                        element.Hovering = isHovering
                    end
                end
            end
        end
    end)
    
    -- Update animations for interactive elements
    RunService:BindToRenderStep("UI_Animations", 100, function()
        if self.Visible and self.ActiveTab then
            for _, element in pairs(self.ActiveTab.Elements) do
                if element.Update then
                    element:Update()
                end
            end
        end
    end)
end

-- Set the position of the UI
function ESPLib.UI.Framework:SetPosition(position)
    -- Calculate the offset from current position
    local offset = position - self.Position
    self.Position = position
    
    -- Update positions of main UI elements
    for _, element in pairs(self.Elements) do
        element.Position = element.Position + offset
    end
    
    -- Update tab buttons and their elements
    for _, tab in pairs(self.Tabs) do
        tab.Button.Position = tab.Button.Position + offset
        tab.Button.Square.Position = tab.Button.Position
        tab.Button.Text.Position = Vector2.new(
            tab.Button.Position.X + tab.Button.Size.X/2,
            tab.Button.Position.Y + 10
        )
        tab.Button.Indicator.Position = Vector2.new(
            tab.Button.Position.X,
            tab.Button.Position.Y + 36
        )
        
        -- Update all elements in each tab
        for _, element in pairs(tab.Elements) do
            if element.Type then
                -- Handle UI components
                for _, obj in pairs(element.Objects) do
                    if obj and obj.Position then
                        obj.Position = obj.Position + offset
                    end
                end
            elseif element ~= tab.Button.Square and 
                   element ~= tab.Button.Text and
                   element ~= tab.Button.Indicator and
                   element.Position then
                -- Handle raw drawing objects
                element.Position = element.Position + offset
            end
        end
    end
end

-- Toggle UI visibility
function ESPLib.UI.Framework:Toggle()
    self.Visible = not self.Visible
    
    -- Update visibility of all elements
    for _, element in pairs(self.Elements) do
        element.Visible = self.Visible
    end
    
    -- Update visibility of active tab button indicators
    for _, tab in pairs(self.Tabs) do
        tab.Button.Square.Visible = self.Visible
        tab.Button.Text.Visible = self.Visible
        tab.Button.Indicator.Visible = self.Visible and tab.Button.Active
    end
    
    -- Update visibility of active tab elements
    if self.ActiveTab then
        for _, element in pairs(self.ActiveTab.Elements) do
            if element.Type then
                -- Toggle UI components
                for name, obj in pairs(element.Objects) do
                    if obj then
                        -- Special handling for dropdown options - only show when dropdown is open
                        local isDropdownOption = element.Type == "Dropdown" and 
                                               (name == "OptionContainer" or name == "OptionOutline" or
                                                string.find(tostring(name), "OptionBackground") or
                                                string.find(tostring(name), "OptionText"))
                        
                        if isDropdownOption then
                            obj.Visible = self.Visible and element.IsOpen
                        else
                            obj.Visible = self.Visible
                        end
                    end
                end
            elseif element ~= self.ActiveTab.Button.Square and 
                   element ~= self.ActiveTab.Button.Text and
                   element ~= self.ActiveTab.Button.Indicator then
                -- Toggle raw drawing objects
                element.Visible = self.Visible
            end
        end
    end
end

-- Show UI
function ESPLib.UI.Framework:Show()
    if not self.Visible then
        self:Toggle()
    end
end

-- Hide UI
function ESPLib.UI.Framework:Hide()
    if self.Visible then
        self:Toggle()
    end
end

-- Remove UI and clean up
function ESPLib.UI.Framework:Remove()
    -- Unbind render step for animations
    RunService:UnbindFromRenderStep("UI_Animations")
    
    -- Remove main UI elements
    for _, element in pairs(self.Elements) do
        element:Remove()
    end
    
    -- Remove tab elements
    for _, tab in pairs(self.Tabs) do
        -- Remove tab buttons
        for _, buttonElement in pairs({tab.Button.Square, tab.Button.Text, tab.Button.Indicator}) do
            if buttonElement then buttonElement:Remove() end
        end
        
        -- Remove tab content elements
        for _, element in pairs(tab.Elements) do
            if element.Type then
                -- Handle UI components
                for _, obj in pairs(element.Objects) do
                    if obj and type(obj.Remove) == "function" then
                        obj:Remove()
                    end
                end
            elseif element ~= tab.Button.Square and 
                   element ~= tab.Button.Text and 
                   element ~= tab.Button.Indicator and
                   type(element.Remove) == "function" then
                -- Handle raw drawing objects
                element:Remove()
            end
        end
    end
    
    self.Elements = {}
    self.Tabs = {}
    self.ActiveTab = nil
end

-- Create and initialize the ESP Library
function ESPLib.Init()
    -- Initialize ESP system
    ESPLib.ESP.Manager.Init()
    
    return ESPLib
end

return ESPLib
