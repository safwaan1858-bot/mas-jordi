-- Universal Camlock Script - Sticky Edition
-- Strong camlock that sticks tightly to targets

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Configuration - Optimized for strong stickiness
local Settings = {
    Enabled = false,
    TeamCheck = true,
    VisibilityCheck = true,
    Smoothness = 0.4, -- Higher smoothness for stronger stick
    FOV = 80, -- Smaller FOV for more precise targeting
    Prediction = 0.16,
    TargetPart = "Head",
    AutoTarget = false,
    HoldToTarget = false,
    StickStrength = 1.0, -- New: How strongly it sticks to target
    MaxStickDistance = 200 -- New: Maximum distance to stick to target
}

-- UI Variables
local FOVCircle = nil
local MobileGUI = nil
local TouchToggle = nil
local SettingsButton = nil
local SettingsFrame = nil
local CurrentTarget = nil
local StickStartTime = 0

-- Check if device is mobile
local IS_MOBILE = UserInputService.TouchEnabled

-- Create FOV Circle
local function CreateFOVCircle()
    if FOVCircle then FOVCircle:Remove() end
    
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Visible = Settings.Enabled
    FOVCircle.Radius = Settings.FOV
    FOVCircle.Color = IS_MOBILE and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(0, 255, 0)
    FOVCircle.Thickness = 2
    FOVCircle.Filled = false
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
end

-- Get closest player to screen center (mobile) or touch position
local function GetClosestPlayer()
    local closestPlayer = nil
    local shortestDistance = Settings.FOV
    
    local referencePoint = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild(Settings.TargetPart) then
            -- Team check
            if Settings.TeamCheck and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
                continue
            end
            
            -- Distance check
            local distance = (player.Character[Settings.TargetPart].Position - Camera.CFrame.Position).Magnitude
            if distance > Settings.MaxStickDistance then
                continue
            end
            
            -- Visibility check
            if Settings.VisibilityCheck then
                local character = player.Character
                local targetPart = character[Settings.TargetPart]
                local raycastParams = RaycastParams.new()
                raycastParams.FilterDescendantsInstances = {character, LocalPlayer.Character}
                raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
                
                local raycastResult = Workspace:Raycast(
                    Camera.CFrame.Position,
                    (targetPart.Position - Camera.CFrame.Position).Unit * Settings.MaxStickDistance,
                    raycastParams
                )
                
                if raycastResult and raycastResult.Instance:IsDescendantOf(character) == false then
                    continue
                end
            end
            
            local screenPoint, onScreen = Camera:WorldToViewportPoint(player.Character[Settings.TargetPart].Position)
            
            if onScreen then
                local distance = (Vector2.new(screenPoint.X, screenPoint.Y) - referencePoint).Magnitude
                
                if distance < shortestDistance then
                    shortestDistance = distance
                    closestPlayer = player
                end
            end
        end
    end
    
    return closestPlayer
end

-- Check if we should switch targets
local function ShouldSwitchTargets(newTarget)
    if not CurrentTarget then return true end
    if not newTarget then return false end
    
    -- Don't switch if current target is still valid and close
    if CurrentTarget.Character and CurrentTarget.Character:FindFirstChild(Settings.TargetPart) then
        local currentDistance = (CurrentTarget.Character[Settings.TargetPart].Position - Camera.CFrame.Position).Magnitude
        local newDistance = (newTarget.Character[Settings.TargetPart].Position - Camera.CFrame.Position).Magnitude
        
        -- Stick to current target unless new target is significantly closer
        if currentDistance < newDistance * 0.7 then -- 30% closer threshold to switch
            return false
        end
    end
    
    return true
end

-- Strong sticky camlock function
local function StrongCamlock()
    if not Settings.Enabled or not LocalPlayer.Character then 
        CurrentTarget = nil
        return 
    end
    
    local targetPlayer = GetClosestPlayer()
    
    -- If we have a current target, check if it's still valid
    if CurrentTarget then
        if not CurrentTarget.Character or not CurrentTarget.Character:FindFirstChild(Settings.TargetPart) then
            CurrentTarget = nil
        else
            local distance = (CurrentTarget.Character[Settings.TargetPart].Position - Camera.CFrame.Position).Magnitude
            if distance > Settings.MaxStickDistance then
                CurrentTarget = nil
            end
        end
    end
    
    -- Switch to new target if needed
    if targetPlayer and ShouldSwitchTargets(targetPlayer) then
        CurrentTarget = targetPlayer
        StickStartTime = tick()
    end
    
    -- Apply camlock to current target
    if CurrentTarget and CurrentTarget.Character and CurrentTarget.Character:FindFirstChild(Settings.TargetPart) then
        local targetPart = CurrentTarget.Character[Settings.TargetPart]
        
        -- Enhanced prediction with velocity and acceleration
        local targetVelocity = targetPart.Velocity
        local predictedPosition = targetPart.Position + (targetVelocity * Settings.Prediction)
        
        -- Calculate stick strength based on how long we've been locked
        local stickTime = tick() - StickStartTime
        local dynamicStickStrength = math.min(Settings.StickStrength + (stickTime * 0.1), 2.0)
        
        -- Very strong smoothing that sticks tightly
        local currentCFrame = Camera.CFrame
        local targetCFrame = CFrame.lookAt(
            currentCFrame.Position,
            predictedPosition
        )
        
        -- Aggressive lerping for strong stick effect
        local lerpAlpha = math.min(Settings.Smoothness * dynamicStickStrength, 0.9)
        Camera.CFrame = currentCFrame:Lerp(targetCFrame, lerpAlpha)
        
        -- Visual feedback - change FOV color when locked
        if FOVCircle then
            FOVCircle.Color = Color3.fromRGB(255, 0, 0) -- Red when locked
        end
    else
        -- No target - reset FOV color
        if FOVCircle then
            FOVCircle.Color = IS_MOBILE and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(0, 255, 0)
        end
    end
end

-- Update FOV circle
local function UpdateFOVCircle()
    if FOVCircle then
        FOVCircle.Radius = Settings.FOV
        FOVCircle.Visible = Settings.Enabled
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    end
end

-- Toggle camlock function
local function ToggleCamlock()
    Settings.Enabled = not Settings.Enabled
    CurrentTarget = nil -- Reset target when toggling
    
    if TouchToggle then
        TouchToggle.Text = Settings.Enabled and "LOCK" or "OFF"
        TouchToggle.BackgroundColor3 = Settings.Enabled and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(100, 0, 0)
        
        local statusIndicator = TouchToggle:FindFirstChild("StatusIndicator")
        if statusIndicator then
            statusIndicator.BackgroundColor3 = Settings.Enabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
        end
    end
    
    if FOVCircle then
        FOVCircle.Visible = Settings.Enabled
        FOVCircle.Color = IS_MOBILE and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(0, 255, 0)
    end
end

-- Create Mobile GUI
local function CreateMobileGUI()
    if MobileGUI then MobileGUI:Destroy() end
    
    MobileGUI = Instance.new("ScreenGui")
    MobileGUI.Name = "StickyCamlockUI"
    MobileGUI.ResetOnSpawn = false
    MobileGUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Main Toggle Button
    TouchToggle = Instance.new("TextButton")
    TouchToggle.Name = "ToggleButton"
    TouchToggle.Size = UDim2.new(0, 90, 0, 90)
    TouchToggle.Position = UDim2.new(0.85, 0, 0.7, 0)
    TouchToggle.BackgroundColor3 = Settings.Enabled and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(100, 0, 0)
    TouchToggle.BackgroundTransparency = 0.2
    TouchToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    TouchToggle.Text = Settings.Enabled and "LOCK" or "OFF"
    TouchToggle.TextScaled = true
    TouchToggle.Font = Enum.Font.GothamBold
    TouchToggle.Parent = MobileGUI
    
    -- Add corner for better look
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 15)
    toggleCorner.Parent = TouchToggle
    
    -- Status indicator
    local StatusIndicator = Instance.new("Frame")
    StatusIndicator.Name = "StatusIndicator"
    StatusIndicator.Size = UDim2.new(1, 0, 0.1, 0)
    StatusIndicator.Position = UDim2.new(0, 0, 0.9, 0)
    StatusIndicator.BackgroundColor3 = Settings.Enabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
    StatusIndicator.BorderSizePixel = 0
    StatusIndicator.Parent = TouchToggle
    
    -- Settings Button
    SettingsButton = Instance.new("TextButton")
    SettingsButton.Name = "SettingsButton"
    SettingsButton.Size = UDim2.new(0, 70, 0, 70)
    SettingsButton.Position = UDim2.new(0.92, 0, 0.8, 0)
    SettingsButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    SettingsButton.BackgroundTransparency = 0.2
    SettingsButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    SettingsButton.Text = "⚙"
    SettingsButton.TextScaled = true
    SettingsButton.Font = Enum.Font.GothamBold
    SettingsButton.Parent = MobileGUI
    
    local settingsCorner = Instance.new("UICorner")
    settingsCorner.CornerRadius = UDim.new(0, 10)
    settingsCorner.Parent = SettingsButton
    
    -- Settings Frame
    SettingsFrame = Instance.new("Frame")
    SettingsFrame.Name = "SettingsFrame"
    SettingsFrame.Size = UDim2.new(0, 300, 0, 350)
    SettingsFrame.Position = UDim2.new(0.5, -150, 0.5, -175)
    SettingsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    SettingsFrame.BackgroundTransparency = 0.1
    SettingsFrame.Visible = false
    SettingsFrame.Parent = MobileGUI
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 10)
    Corner.Parent = SettingsFrame
    
    -- Settings Title
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Size = UDim2.new(1, 0, 0, 40)
    Title.Position = UDim2.new(0, 0, 0, 0)
    Title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.Text = "STICKY CAMLOCK"
    Title.TextScaled = true
    Title.Font = Enum.Font.GothamBold
    Title.Parent = SettingsFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 10)
    titleCorner.Parent = Title
    
    -- Close Settings Button
    local CloseButton = Instance.new("TextButton")
    CloseButton.Name = "CloseButton"
    CloseButton.Size = UDim2.new(0, 120, 0, 35)
    CloseButton.Position = UDim2.new(0.5, -60, 0.92, 0)
    CloseButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseButton.Text = "Close"
    CloseButton.TextScaled = true
    CloseButton.Parent = SettingsFrame
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = CloseButton
    
    -- Settings Options
    local settingsOptions = {
        {"TeamCheck", "Team Check", 0.12},
        {"VisibilityCheck", "Wall Check", 0.22},
    }
    
    local targetParts = {"Head", "UpperTorso", "HumanoidRootPart"}
    local targetPartIndex = 1
    for i, part in ipairs(targetParts) do
        if part == Settings.TargetPart then
            targetPartIndex = i
            break
        end
    end
    
    -- Create toggle buttons for settings
    for i, option in ipairs(settingsOptions) do
        local settingName, displayName, yPosition = option[1], option[2], option[3]
        
        local ToggleFrame = Instance.new("Frame")
        ToggleFrame.Size = UDim2.new(0.8, 0, 0, 30)
        ToggleFrame.Position = UDim2.new(0.1, 0, yPosition, 0)
        ToggleFrame.BackgroundTransparency = 1
        ToggleFrame.Parent = SettingsFrame
        
        local ToggleLabel = Instance.new("TextLabel")
        ToggleLabel.Size = UDim2.new(0.7, 0, 1, 0)
        ToggleLabel.Position = UDim2.new(0, 0, 0, 0)
        ToggleLabel.BackgroundTransparency = 1
        ToggleLabel.Text = displayName
        ToggleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
        ToggleLabel.TextScaled = true
        ToggleLabel.Parent = ToggleFrame
        
        local ToggleButton = Instance.new("TextButton")
        ToggleButton.Size = UDim2.new(0.25, 0, 0.8, 0)
        ToggleButton.Position = UDim2.new(0.75, 0, 0.1, 0)
        ToggleButton.BackgroundColor3 = Settings[settingName] and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(100, 0, 0)
        ToggleButton.Text = Settings[settingName] and "ON" or "OFF"
        ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        ToggleButton.TextScaled = true
        ToggleButton.Parent = ToggleFrame
        
        local toggleBtnCorner = Instance.new("UICorner")
        toggleBtnCorner.CornerRadius = UDim.new(0, 6)
        toggleBtnCorner.Parent = ToggleButton
        
        ToggleButton.MouseButton1Click:Connect(function()
            Settings[settingName] = not Settings[settingName]
            ToggleButton.BackgroundColor3 = Settings[settingName] and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(100, 0, 0)
            ToggleButton.Text = Settings[settingName] and "ON" or "OFF"
        end)
    end
    
    -- Target Part Selection
    local TargetPartFrame = Instance.new("Frame")
    TargetPartFrame.Size = UDim2.new(0.8, 0, 0, 40)
    TargetPartFrame.Position = UDim2.new(0.1, 0, 0.32, 0)
    TargetPartFrame.BackgroundTransparency = 1
    TargetPartFrame.Parent = SettingsFrame
    
    local TargetLabel = Instance.new("TextLabel")
    TargetLabel.Size = UDim2.new(1, 0, 0.5, 0)
    TargetLabel.Position = UDim2.new(0, 0, 0, 0)
    TargetLabel.BackgroundTransparency = 1
    TargetLabel.Text = "Target Part:"
    TargetLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TargetLabel.TextXAlignment = Enum.TextXAlignment.Left
    TargetLabel.TextScaled = true
    TargetLabel.Parent = TargetPartFrame
    
    local TargetButton = Instance.new("TextButton")
    TargetButton.Size = UDim2.new(1, 0, 0.5, 0)
    TargetButton.Position = UDim2.new(0, 0, 0.5, 0)
    TargetButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    TargetButton.Text = Settings.TargetPart
    TargetButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    TargetButton.TextScaled = true
    TargetButton.Parent = TargetPartFrame
    
    local targetCorner = Instance.new("UICorner")
    targetCorner.CornerRadius = UDim.new(0, 6)
    targetCorner.Parent = TargetButton
    
    TargetButton.MouseButton1Click:Connect(function()
        targetPartIndex = (targetPartIndex % #targetParts) + 1
        Settings.TargetPart = targetParts[targetPartIndex]
        TargetButton.Text = Settings.TargetPart
        CurrentTarget = nil -- Reset target when changing part
    end)
    
    -- FOV Slider
    local FOVFrame = Instance.new("Frame")
    FOVFrame.Size = UDim2.new(0.8, 0, 0, 50)
    FOVFrame.Position = UDim2.new(0.1, 0, 0.45, 0)
    FOVFrame.BackgroundTransparency = 1
    FOVFrame.Parent = SettingsFrame
    
    local FOVLabel = Instance.new("TextLabel")
    FOVLabel.Size = UDim2.new(1, 0, 0.4, 0)
    FOVLabel.Position = UDim2.new(0, 0, 0, 0)
    FOVLabel.BackgroundTransparency = 1
    FOVLabel.Text = "FOV: " .. Settings.FOV
    FOVLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    FOVLabel.TextXAlignment = Enum.TextXAlignment.Left
    FOVLabel.TextScaled = true
    FOVLabel.Parent = FOVFrame
    
    local FOVSlider = Instance.new("Frame")
    FOVSlider.Size = UDim2.new(1, 0, 0.3, 0)
    FOVSlider.Position = UDim2.new(0, 0, 0.5, 0)
    FOVSlider.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    FOVSlider.Parent = FOVFrame
    
    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(0, 4)
    sliderCorner.Parent = FOVSlider
    
    local FOVFill = Instance.new("Frame")
    FOVFill.Size = UDim2.new((Settings.FOV - 30) / 120, 0, 1, 0)
    FOVFill.Position = UDim2.new(0, 0, 0, 0)
    FOVFill.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    FOVFill.Parent = FOVSlider
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 4)
    fillCorner.Parent = FOVFill
    
    local FOVButton = Instance.new("TextButton")
    FOVButton.Size = UDim2.new(1, 0, 1, 0)
    FOVButton.Position = UDim2.new(0, 0, 0, 0)
    FOVButton.BackgroundTransparency = 1
    FOVButton.Text = ""
    FOVButton.Parent = FOVSlider
    
    FOVButton.MouseButton1Down:Connect(function()
        local connection
        connection = RunService.Heartbeat:Connect(function()
            local mouse = UserInputService:GetMouseLocation()
            local relativeX = math.clamp((mouse.X - FOVSlider.AbsolutePosition.X) / FOVSlider.AbsoluteSize.X, 0, 1)
            Settings.FOV = math.floor(30 + relativeX * 120)
            FOVLabel.Text = "FOV: " .. Settings.FOV
            FOVFill.Size = UDim2.new(relativeX, 0, 1, 0)
        end)
        
        local release
        release = UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                connection:Disconnect()
                release:Disconnect()
            end
        end)
    end)
    
    -- Stick Strength Slider
    local StickFrame = Instance.new("Frame")
    StickFrame.Size = UDim2.new(0.8, 0, 0, 50)
    StickFrame.Position = UDim2.new(0.1, 0, 0.6, 0)
    StickFrame.BackgroundTransparency = 1
    StickFrame.Parent = SettingsFrame
    
    local StickLabel = Instance.new("TextLabel")
    StickLabel.Size = UDim2.new(1, 0, 0.4, 0)
    StickLabel.Position = UDim2.new(0, 0, 0, 0)
    StickLabel.BackgroundTransparency = 1
    StickLabel.Text = "Stick Strength: " .. string.format("%.1f", Settings.StickStrength)
    StickLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    StickLabel.TextXAlignment = Enum.TextXAlignment.Left
    StickLabel.TextScaled = true
    StickLabel.Parent = StickFrame
    
    local StickSlider = Instance.new("Frame")
    StickSlider.Size = UDim2.new(1, 0, 0.3, 0)
    StickSlider.Position = UDim2.new(0, 0, 0.5, 0)
    StickSlider.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    StickSlider.Parent = StickFrame
    
    local stickSliderCorner = Instance.new("UICorner")
    stickSliderCorner.CornerRadius = UDim.new(0, 4)
    stickSliderCorner.Parent = StickSlider
    
    local StickFill = Instance.new("Frame")
    StickFill.Size = UDim2.new(Settings.StickStrength / 2, 0, 1, 0)
    StickFill.Position = UDim2.new(0, 0, 0, 0)
    StickFill.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
    StickFill.Parent = StickSlider
    
    local stickFillCorner = Instance.new("UICorner")
    stickFillCorner.CornerRadius = UDim
