-- Universal Bone ESP
-- Made by Sourcegraph Cody

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Create ESP container
local ESPContainer = Instance.new("Folder")
ESPContainer.Name = "BoneESP"
ESPContainer.Parent = CoreGui

-- Bone ESP Settings
local Settings = {
    BoneColor = Color3.fromRGB(255, 0, 0),  -- Red bones
    BoneTransparency = 0.2,                 -- More visible (lower transparency)
    BoneThickness = 3                       -- Thicker bones
}

-- Bone connections (R6 and R15 compatible)
local BoneConnections = {
    -- Head to Torso
    {"Head", "UpperTorso"},
    {"Head", "Torso"},
    
    -- Torso to limbs (R15)
    {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "RightUpperArm"},
    {"UpperTorso", "LeftUpperArm"},
    {"LowerTorso", "RightUpperLeg"},
    {"LowerTorso", "LeftUpperLeg"},
    
    -- Torso to limbs (R6)
    {"Torso", "Right Arm"},
    {"Torso", "Left Arm"},
    {"Torso", "Right Leg"},
    {"Torso", "Left Leg"},
    
    -- Arms (R15)
    {"RightUpperArm", "RightLowerArm"},
    {"RightLowerArm", "RightHand"},
    {"LeftUpperArm", "LeftLowerArm"},
    {"LeftLowerArm", "LeftHand"},
    
    -- Legs (R15)
    {"RightUpperLeg", "RightLowerLeg"},
    {"RightLowerLeg", "RightFoot"},
    {"LeftUpperLeg", "LeftLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"}
}

-- Create bone ESP for a player
local function CreateBoneESP(player)
    local ESP = Instance.new("Folder")
    ESP.Name = player.Name
    ESP.Parent = ESPContainer
    
    -- Create lines for each bone connection
    for i, _ in ipairs(BoneConnections) do
        local Line = Instance.new("LineHandleAdornment")
        Line.Name = "Bone" .. i
        Line.Thickness = Settings.BoneThickness
        Line.Color3 = Settings.BoneColor
        Line.AlwaysOnTop = true
        Line.ZIndex = 10
        Line.Transparency = Settings.BoneTransparency
        Line.Parent = ESP
    end
    
    return ESP
end

-- Update bone ESP for a player
local function UpdateBoneESP(player, esp)
    if not player.Character then return end
    
    local character = player.Character
    
    -- Update each bone line
    for i, connection in ipairs(BoneConnections) do
        local part1 = character:FindFirstChild(connection[1])
        local part2 = character:FindFirstChild(connection[2])
        
        local line = esp:FindFirstChild("Bone" .. i)
        if line and part1 and part2 then
            line.Adornee = workspace
            line.Length = (part1.Position - part2.Position).Magnitude
            
            -- Calculate the midpoint between the two parts
            local midPoint = (part1.Position + part2.Position) / 2
            
            -- Create a CFrame that looks from part1 to part2
            local lookAt = CFrame.lookAt(part1.Position, part2.Position)
            
            -- Position the line at the midpoint, oriented along the direction from part1 to part2
            line.CFrame = CFrame.new(midPoint) * lookAt * CFrame.new(0, 0, -line.Length/2)
            line.Visible = true
        else
            if line then
                line.Visible = false
            end
        end
    end
end

-- Remove bone ESP for a player
local function RemoveBoneESP(player)
    local esp = ESPContainer:FindFirstChild(player.Name)
    if esp then
        esp:Destroy()
    end
end

-- Create bone ESP for all players
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        CreateBoneESP(player)
    end
end

-- Handle player joining
Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        CreateBoneESP(player)
    end
end)

-- Handle player leaving
Players.PlayerRemoving:Connect(function(player)
    RemoveBoneESP(player)
end)

-- Update bone ESP
RunService.RenderStepped:Connect(function()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local esp = ESPContainer:FindFirstChild(player.Name)
            if not esp then
                esp = CreateBoneESP(player)
            end
            UpdateBoneESP(player, esp)
        end
    end
end)

-- Notification that bone ESP is active
local function notify(text)
    game.StarterGui:SetCore("SendNotification", {
        Title = "Bone ESP",
        Text = text,
        Duration = 3
    })
end

notify("Bone ESP is now active!")
