-- Clean Universal Bone ESP Script for Roblox
-- No UI, no boxes, just bone lines

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ESP Settings
local ESP = {
    Enabled = true,
    Color = Color3.fromRGB(255, 0, 0), -- Red
    Thickness = 2,
}

-- Create a table to store all drawings
local drawings = {}

-- Function to create a new drawing
local function CreateDrawing(id)
    if drawings[id] then
        return drawings[id]
    end
    
    local drawing = Drawing.new("Line")
    drawing.Visible = false
    drawing.Thickness = ESP.Thickness
    drawing.Color = ESP.Color
    drawing.Transparency = 1
    drawings[id] = drawing
    return drawing
end

-- Simple bone connections for R15
local boneConnections = {
    -- Torso
    {"Head", "UpperTorso"},
    {"UpperTorso", "LowerTorso"},
    
    -- Left Arm
    {"UpperTorso", "LeftUpperArm"},
    {"LeftUpperArm", "LeftLowerArm"},
    {"LeftLowerArm", "LeftHand"},
    
    -- Right Arm
    {"UpperTorso", "RightUpperArm"},
    {"RightUpperArm", "RightLowerArm"},
    {"RightLowerArm", "RightHand"},
    
    -- Left Leg
    {"LowerTorso", "LeftUpperLeg"},
    {"LeftUpperLeg", "LeftLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"},
    
    -- Right Leg
    {"LowerTorso", "RightUpperLeg"},
    {"RightUpperLeg", "RightLowerLeg"},
    {"RightLowerLeg", "RightFoot"},
}

-- R6 connections
local r6Connections = {
    {"Head", "Torso"},
    {"Torso", "Left Arm"},
    {"Torso", "Right Arm"},
    {"Torso", "Left Leg"},
    {"Torso", "Right Leg"},
}

-- Main ESP function
local function UpdateESP()
    -- Hide all drawings first
    for _, drawing in pairs(drawings) do
        drawing.Visible = false
    end
    
    -- Loop through all players
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character = player.Character
            if character and character:FindFirstChildOfClass("Humanoid") then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid.Health > 0 then
                    -- Determine if R15 or R6
                    local connections = boneConnections
                    if character:FindFirstChild("Torso") then
                        connections = r6Connections
                    end
                    
                    -- Draw bones
                    for i, bone in ipairs(connections) do
                        local part1 = character:FindFirstChild(bone[1])
                        local part2 = character:FindFirstChild(bone[2])
                        
                        if part1 and part2 then
                            local pos1, vis1 = Camera:WorldToViewportPoint(part1.Position)
                            local pos2, vis2 = Camera:WorldToViewportPoint(part2.Position)
                            
                            if vis1 and vis2 then
                                local drawingId = player.Name .. i
                                local line = CreateDrawing(drawingId)
                                
                                line.From = Vector2.new(pos1.X, pos1.Y)
                                line.To = Vector2.new(pos2.X, pos2.Y)
                                line.Visible = true
                            end
                        end
                    end
                end
            end
        end
    end
end

-- Connect the ESP function to RenderStepped
RunService:BindToRenderStep("CleanESP", Enum.RenderPriority.Camera.Value, UpdateESP)

-- Keep the script running and always enabled
spawn(function()
    while true do
        wait(1)
        ESP.Enabled = true
    end
end)
