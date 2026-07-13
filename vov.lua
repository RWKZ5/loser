-- ============================================
-- [ أيم بوت - نسخة دلتا Executor ]
-- ============================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")

-- ============================================
-- [ إعدادات ]
-- ============================================
local AimbotEnabled = true
local FOV_Radius = 250
local Smoothness = 0.08
local BulletSpeed = 3500

local lastVelocities = {}

-- ============================================
-- [ دائرة FOV - GUI بسيط ]
-- ============================================
local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui") or Instance.new("ScreenGui", LocalPlayer)

local FOVCircle = Instance.new("ImageLabel")
FOVCircle.Size = UDim2.new(0, FOV_Radius * 2, 0, FOV_Radius * 2)
FOVCircle.Position = UDim2.new(0.5, -FOV_Radius, 0.5, -FOV_Radius)
FOVCircle.BackgroundTransparency = 1
FOVCircle.Image = "rbxassetid://0"
FOVCircle.Parent = PlayerGui

local circleFrame = Instance.new("Frame", FOVCircle)
circleFrame.Size = UDim2.new(1, 0, 1, 0)
circleFrame.BackgroundTransparency = 0.85
circleFrame.BorderSizePixel = 2
circleFrame.BorderColor3 = Color3.fromRGB(0, 255, 150)
Instance.new("UICorner", circleFrame).CornerRadius = UDim.new(1, 0)

-- علامة تقاطع
local crosshairH = Instance.new("Frame", FOVCircle)
crosshairH.Size = UDim2.new(0, 20, 0, 1)
crosshairH.Position = UDim2.new(0.5, -10, 0.5, -0.5)
crosshairH.BackgroundColor3 = Color3.fromRGB(0, 255, 150)

local crosshairV = Instance.new("Frame", FOVCircle)
crosshairV.Size = UDim2.new(0, 1, 0, 20)
crosshairV.Position = UDim2.new(0.5, -0.5, 0.5, -10)
crosshairV.BackgroundColor3 = Color3.fromRGB(0, 255, 150)

-- ============================================
-- [ واجهة التحكم ]
-- ============================================
local ScreenGui = Instance.new("ScreenGui", PlayerGui)

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 200, 0, 160)
MainFrame.Position = UDim2.new(0.5, -100, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
MainFrame.BackgroundTransparency = 0.3
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

-- زر التبديل
local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0, 180, 0, 35)
ToggleBtn.Position = UDim2.new(0.5, -90, 0, 10)
ToggleBtn.Text = "🔴 إيقاف"
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 90)
ToggleBtn.TextColor3 = Color3.new(1, 1, 1)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 12
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 6)

ToggleBtn.MouseButton1Click:Connect(function()
    AimbotEnabled = not AimbotEnabled
    ToggleBtn.Text = AimbotEnabled and "🔴 إيقاف" or "🟢 تشغيل"
    ToggleBtn.BackgroundColor3 = AimbotEnabled and Color3.fromRGB(0, 150, 90) or Color3.fromRGB(150, 30, 30)
    FOVCircle.Visible = AimbotEnabled
end)

-- سلايدر FOV
local FOVSliderLabel = Instance.new("TextLabel", MainFrame)
FOVSliderLabel.Size = UDim2.new(1, 0, 0, 20)
FOVSliderLabel.Position = UDim2.new(0, 0, 0, 55)
FOVSliderLabel.Text = "FOV: " .. tostring(FOV_Radius)
FOVSliderLabel.TextColor3 = Color3.new(1, 1, 1)
FOVSliderLabel.BackgroundTransparency = 1
FOVSliderLabel.Font = Enum.Font.Gotham
FOVSliderLabel.TextSize = 11

local FOVSlider = Instance.new("Frame", MainFrame)
FOVSlider.Size = UDim2.new(0, 180, 0, 4)
FOVSlider.Position = UDim2.new(0.5, -90, 0, 80)
FOVSlider.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
Instance.new("UICorner", FOVSlider)

-- سلايدر السرعة
local SpeedSliderLabel = Instance.new("TextLabel", MainFrame)
SpeedSliderLabel.Size = UDim2.new(1, 0, 0, 20)
SpeedSliderLabel.Position = UDim2.new(0, 0, 0, 100)
SpeedSliderLabel.Text = "Speed: " .. string.format("%.2f", Smoothness)
SpeedSliderLabel.TextColor3 = Color3.new(1, 1, 1)
SpeedSliderLabel.BackgroundTransparency = 1
SpeedSliderLabel.Font = Enum.Font.Gotham
SpeedSliderLabel.TextSize = 11

local SpeedSlider = Instance.new("Frame", MainFrame)
SpeedSlider.Size = UDim2.new(0, 180, 0, 4)
SpeedSlider.Position = UDim2.new(0.5, -90, 0, 125)
SpeedSlider.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
Instance.new("UICorner", SpeedSlider)

-- ============================================
-- [ التحكم بالسلايدرات (باستخدام اللمس) ]
-- ============================================
local draggingFOV = false
local draggingSpeed = false

FOVSlider.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        draggingFOV = true
    end
end)

FOVSlider.InputEnded:Connect(function()
    draggingFOV = false
end)

SpeedSlider.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        draggingSpeed = true
    end
end)

SpeedSlider.InputEnded:Connect(function()
    draggingSpeed = false
end)

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        if draggingFOV then
            local relativeX = math.clamp((input.Position.X - FOVSlider.AbsolutePosition.X) / FOVSlider.AbsoluteSize.X, 0, 1)
            FOV_Radius = math.floor(50 + (relativeX * 450))
            FOVSliderLabel.Text = "FOV: " .. tostring(FOV_Radius)
            FOVCircle.Size = UDim2.new(0, FOV_Radius * 2, 0, FOV_Radius * 2)
            FOVCircle.Position = UDim2.new(0.5, -FOV_Radius, 0.5, -FOV_Radius)
        end
        
        if draggingSpeed then
            local relativeX = math.clamp((input.Position.X - SpeedSlider.AbsolutePosition.X) / SpeedSlider.AbsoluteSize.X, 0, 1)
            Smoothness = relativeX * 0.3
            SpeedSliderLabel.Text = "Speed: " .. string.format("%.2f", Smoothness)
        end
    end
end)

-- ============================================
-- [ المنطق الأساسي ]
-- ============================================
local function isTargetValid(player)
    if not player or not player.Character then return false end
    local hum = player.Character:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function isPartVisible(part)
    local origin = Camera.CFrame.Position
    local direction = (part.Position - origin)
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {LocalPlayer.Character}
    params.FilterType = Enum.RaycastFilterType.Exclude
    local result = workspace:Raycast(origin, direction, params)
    if not result then return true end
    return result.Instance:IsDescendantOf(part.Parent)
end

local function getBestPart(character)
    local parts = {"Head", "UpperTorso", "Torso", "HumanoidRootPart"}
    for _, name in ipairs(parts) do
        local part = character:FindFirstChild(name)
        if part and isPartVisible(part) then
            return part
        end
    end
    return nil
end

local function getPredictedPos(player, part, dt)
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return part.Position end
    local vel = hrp.AssemblyLinearVelocity
    local dist = (part.Position - Camera.CFrame.Position).Magnitude
    local time = dist / BulletSpeed
    local prev = lastVelocities[player] or vel
    local accel = (vel - prev) / math.max(dt, 0.01)
    lastVelocities[player] = vel
    return part.Position + (vel * time) + (0.5 * accel * (time ^ 2))
end

local function getClosest()
    local bestPlayer = nil
    local bestDist = FOV_Radius
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            local hrp = player.Character:FindFirstChild("HumanoidRootPart") or player.Character:FindFirstChild("Torso")
            if hum and hum.Health > 0 and hrp then
                local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    if dist < bestDist then
                        local part = getBestPart(player.Character)
                        if part then
                            bestPlayer = player
                            bestDist = dist
                        end
                    end
                end
            end
        end
    end
    return bestPlayer
end

-- ============================================
-- [ التشغيل ]
-- ============================================
RunService.Heartbeat:Connect(function(dt)
    if not AimbotEnabled then return end
    
    local target = getClosest()
    if target and isTargetValid(target) then
        local part = getBestPart(target.Character)
        if part then
            local targetPos = getPredictedPos(target, part, dt)
            local targetCFrame = CFrame.new(Camera.CFrame.Position, targetPos)
            Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, Smoothness)
        end
    end
end)

Players.PlayerRemoving:Connect(function(p)
    lastVelocities[p] = nil
end)

print("✅ أيم بوت دلتا يعمل!")
