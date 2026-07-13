-- ============================================
-- [ الأيم بوت - النسخة النهائية للجوال مع حماية الموت ]
-- ============================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ============================================
-- [ الإعدادات ]
-- ============================================
local AimbotEnabled = true
local BulletSpeed = 3500
local FOV_Radius = 150
local Camera_Smoothness = 0.05

local lastVelocities = {}
local radarPool = {}
local currentTarget = nil
local MAX_DOTS = 20

-- ============================================
-- [ دائرة FOV ]
-- ============================================
local FOVCircle = Instance.new("ImageLabel")
FOVCircle.Size = UDim2.new(0, FOV_Radius * 2, 0, FOV_Radius * 2)
FOVCircle.Position = UDim2.new(0.5, -FOV_Radius, 0.5, -FOV_Radius)
FOVCircle.BackgroundTransparency = 1
FOVCircle.Image = "rbxassetid://0"
FOVCircle.ZIndex = 0
FOVCircle.Parent = LocalPlayer:WaitForChild("PlayerGui")

local circleFrame = Instance.new("Frame", FOVCircle)
circleFrame.Size = UDim2.new(1, 0, 1, 0)
circleFrame.BackgroundTransparency = 1
circleFrame.BorderSizePixel = 3
circleFrame.BorderColor3 = Color3.fromRGB(0, 255, 150)
Instance.new("UICorner", circleFrame).CornerRadius = UDim.new(1, 0)

local crosshairH = Instance.new("Frame", FOVCircle)
crosshairH.Size = UDim2.new(0, 20, 0, 2)
crosshairH.Position = UDim2.new(0.5, -10, 0.5, -1)
crosshairH.BackgroundColor3 = Color3.fromRGB(0, 255, 150)
crosshairH.BackgroundTransparency = 0.5
crosshairH.BorderSizePixel = 0

local crosshairV = Instance.new("Frame", FOVCircle)
crosshairV.Size = UDim2.new(0, 2, 0, 20)
crosshairV.Position = UDim2.new(0.5, -1, 0.5, -10)
crosshairV.BackgroundColor3 = Color3.fromRGB(0, 255, 150)
crosshairV.BackgroundTransparency = 0.5
crosshairV.BorderSizePixel = 0

FOVCircle.Visible = true

-- ============================================
-- [ الواجهة الرسومية ]
-- ============================================
local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 240, 0, 280)
MainFrame.Position = UDim2.new(0.5, -120, 0.15, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
MainFrame.BackgroundTransparency = 0.85
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

-- نظام السحب اليدوي
local draggingFrame = false
local dragOffset = Vector2.new()

MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingFrame = true
        dragOffset = Vector2.new(input.Position.X - MainFrame.AbsolutePosition.X, input.Position.Y - MainFrame.AbsolutePosition.Y)
    end
end)

MainFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingFrame = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if draggingFrame and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) then
        local newPos = input.Position - dragOffset
        MainFrame.Position = UDim2.new(0, newPos.X, 0, newPos.Y)
    end
end)

-- زر التبديل
local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0, 200, 0, 35)
ToggleBtn.Position = UDim2.new(0.5, -100, 0, 15)
ToggleBtn.Text = "الأيم بوت: مفعل"
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 90)
ToggleBtn.TextColor3 = Color3.new(1, 1, 1)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 12
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 6)
ToggleBtn.Activated:Connect(function()
    AimbotEnabled = not AimbotEnabled
    ToggleBtn.Text = AimbotEnabled and "الأيم بوت: مفعل" or "الأيم بوت: معطل"
    ToggleBtn.BackgroundColor3 = AimbotEnabled and Color3.fromRGB(0, 150, 90) or Color3.fromRGB(150, 30, 30)
    FOVCircle.Visible = AimbotEnabled
end)

-- سلايدر FOV
local FOVSliderLabel = Instance.new("TextLabel", MainFrame)
FOVSliderLabel.Size = UDim2.new(1, 0, 0, 20)
FOVSliderLabel.Position = UDim2.new(0, 0, 0, 60)
FOVSliderLabel.Text = "حجم الـ FOV: 150"
FOVSliderLabel.TextColor3 = Color3.new(1, 1, 1)
FOVSliderLabel.BackgroundTransparency = 1
FOVSliderLabel.Font = Enum.Font.Gotham
FOVSliderLabel.TextSize = 11

local FOVSliderBg = Instance.new("Frame", MainFrame)
FOVSliderBg.Size = UDim2.new(0, 200, 0, 6)
FOVSliderBg.Position = UDim2.new(0.5, -100, 0, 85)
FOVSliderBg.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
Instance.new("UICorner", FOVSliderBg)

local FOVSliderBtn = Instance.new("TextButton", FOVSliderBg)
FOVSliderBtn.Size = UDim2.new(0, 20, 0, 20)
FOVSliderBtn.Position = UDim2.new(0.25, -10, 0.5, -10)
FOVSliderBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
FOVSliderBtn.Text = ""
Instance.new("UICorner", FOVSliderBtn).CornerRadius = UDim.new(1, 0)

-- سلايدر السرعة
local SpeedSliderLabel = Instance.new("TextLabel", MainFrame)
SpeedSliderLabel.Size = UDim2.new(1, 0, 0, 20)
SpeedSliderLabel.Position = UDim2.new(0, 0, 0, 125)
SpeedSliderLabel.Text = "سرعة اللفة: 0.05"
SpeedSliderLabel.TextColor3 = Color3.new(1, 1, 1)
SpeedSliderLabel.BackgroundTransparency = 1
SpeedSliderLabel.Font = Enum.Font.Gotham
SpeedSliderLabel.TextSize = 11

local SpeedSliderBg = Instance.new("Frame", MainFrame)
SpeedSliderBg.Size = UDim2.new(0, 200, 0, 6)
SpeedSliderBg.Position = UDim2.new(0.5, -100, 0, 150)
SpeedSliderBg.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
Instance.new("UICorner", SpeedSliderBg)

local SpeedSliderBtn = Instance.new("TextButton", SpeedSliderBg)
SpeedSliderBtn.Size = UDim2.new(0, 20, 0, 20)
SpeedSliderBtn.Position = UDim2.new(0.5, -10, 0.5, -10)
SpeedSliderBtn.BackgroundColor3 = Color3.fromRGB(255, 150, 0)
SpeedSliderBtn.Text = ""
Instance.new("UICorner", SpeedSliderBtn).CornerRadius = UDim.new(1, 0)

-- الرادار
local RadarFrame = Instance.new("Frame", MainFrame)
RadarFrame.Size = UDim2.new(0, 80, 0, 80)
RadarFrame.Position = UDim2.new(0.5, -40, 0, 180)
RadarFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
RadarFrame.BorderColor3 = Color3.fromRGB(0, 255, 150)
Instance.new("UICorner", RadarFrame).CornerRadius = UDim.new(0, 4)

local CenterDot = Instance.new("Frame", RadarFrame)
CenterDot.Size = UDim2.new(0, 4, 0, 4)
CenterDot.Position = UDim2.new(0.5, -2, 0.5, -2)
CenterDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", CenterDot)

-- Object Pooling للرادار
for i = 1, MAX_DOTS do
    local dot = Instance.new("Frame", RadarFrame)
    dot.Size = UDim2.new(0, 4, 0, 4)
    dot.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    dot.Visible = false
    Instance.new("UICorner", dot)
    radarPool[i] = dot
end

-- زر التصغير
local MinButton = Instance.new("TextButton", MainFrame)
MinButton.Size = UDim2.new(0, 25, 0, 25)
MinButton.Position = UDim2.new(1, -30, 0, 5)
MinButton.Text = "[-]"
MinButton.BackgroundTransparency = 1
MinButton.TextColor3 = Color3.fromRGB(255, 50, 50)
MinButton.Font = Enum.Font.GothamBold
MinButton.TextSize = 14
MinButton.Activated:Connect(function() MainFrame.Visible = false end)

-- زر الفتح العائم
local OpenButton = Instance.new("TextButton", ScreenGui)
OpenButton.Size = UDim2.new(0, 90, 0, 30)
OpenButton.Position = UDim2.new(0, 10, 0, 10)
OpenButton.Text = "تعديل السكربت"
OpenButton.Visible = false
OpenButton.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
OpenButton.TextColor3 = Color3.fromRGB(0, 200, 255)
OpenButton.Font = Enum.Font.GothamBold
OpenButton.TextSize = 11
Instance.new("UICorner", OpenButton)
OpenButton.Activated:Connect(function()
    MainFrame.Visible = true
    OpenButton.Visible = false
end)

-- ============================================
-- [ نظام السلايدرات ]
-- ============================================
local draggingFOV = false
local draggingSpeed = false

local function setupSlider(sliderBtn)
    sliderBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            if sliderBtn == FOVSliderBtn then draggingFOV = true else draggingSpeed = true end
        end
    end)
    
    sliderBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            if sliderBtn == FOVSliderBtn then draggingFOV = false else draggingSpeed = false end
        end
    end)
end

setupSlider(FOVSliderBtn)
setupSlider(SpeedSliderBtn)

-- ============================================
-- [ حلقة التحديث ]
-- ============================================
RunService.RenderStepped:Connect(function()
    local mousePos = UserInputService:GetMouseLocation()
    
    if draggingFOV then
        local bgAbsPos = FOVSliderBg.AbsolutePosition
        local bgAbsSize = FOVSliderBg.AbsoluteSize.X
        if bgAbsSize > 0 then
            local relativeX = math.clamp((mousePos.X - bgAbsPos.X) / bgAbsSize, 0, 1)
            FOVSliderBtn.Position = UDim2.new(relativeX, -10, 0.5, -10)
            FOV_Radius = math.floor(50 + (relativeX * 450))
            FOVSliderLabel.Text = "حجم الـ FOV: " .. tostring(FOV_Radius)
            FOVCircle.Size = UDim2.new(0, FOV_Radius * 2, 0, FOV_Radius * 2)
            FOVCircle.Position = UDim2.new(0.5, -FOV_Radius, 0.5, -FOV_Radius)
        end
    end
    
    if draggingSpeed then
        local bgAbsPos = SpeedSliderBg.AbsolutePosition
        local bgAbsSize = SpeedSliderBg.AbsoluteSize.X
        if bgAbsSize > 0 then
            local relativeX = math.clamp((mousePos.X - bgAbsPos.X) / bgAbsSize, 0, 1)
            SpeedSliderBtn.Position = UDim2.new(relativeX, -10, 0.5, -10)
            Camera_Smoothness = relativeX * 0.3
            SpeedSliderLabel.Text = string.format("سرعة اللفة: %.3f", Camera_Smoothness)
        end
    end
    
    -- تحديث الرادار
    local localHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local dotIndex = 1
    
    if MainFrame.Visible and localHrp then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Team ~= LocalPlayer.Team then
                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                if hrp and dotIndex <= MAX_DOTS then
                    local relPos = Camera.CFrame:ToObjectSpace(hrp.CFrame).Position
                    local x = math.clamp(relPos.X * 0.4, -38, 38)
                    local z = math.clamp(relPos.Z * 0.4, -38, 38)
                    
                    local dot = radarPool[dotIndex]
                    dot.Position = UDim2.new(0.5, x - 2, 0.5, z - 2)
                    dot.Visible = true
                    dotIndex = dotIndex + 1
                end
            end
        end
    end
    
    for i = dotIndex, MAX_DOTS do
        radarPool[i].Visible = false
    end
end)

-- ============================================
-- [ حماية الموت - التحقق من صحة الهدف ]
-- ============================================
local function isTargetValid(player)
    if not player or not player.Character then return false end
    local hum = player.Character:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

-- مراقبة الهدف الحالي
RunService.Heartbeat:Connect(function()
    if currentTarget and not isTargetValid(currentTarget) then
        currentTarget = nil
    end
end)

-- ============================================
-- [ المنطق الأساسي ]
-- ============================================
local function isPartVisible(targetPart)
    local rayOrigin = Camera.CFrame.Position
    local rayDirection = (targetPart.Position - rayOrigin)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    
    local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    
    if not result then
        return true
    end
    
    return result.Instance:IsDescendantOf(targetPart.Parent)
end

local function getBestVisiblePart(character)
    local parts = {"Head", "UpperTorso", "Torso", "HumanoidRootPart"}
    for _, name in ipairs(parts) do
        local part = character:FindFirstChild(name)
        if part and isPartVisible(part) then
            return part
        end
    end
    return nil
end

local function getPredictedPosition(targetPlayer, targetPart, dt)
    local hrp = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return targetPart.Position end
    
    local currentVel = hrp.AssemblyLinearVelocity
    local distance = (targetPart.Position - Camera.CFrame.Position).Magnitude
    local timeToReach = distance / BulletSpeed
    
    local prevVel = lastVelocities[targetPlayer] or currentVel
    local acceleration = (currentVel - prevVel) / math.max(dt, 0.001)
    lastVelocities[targetPlayer] = currentVel
    
    return targetPart.Position + (currentVel * timeToReach) + (0.5 * acceleration * (timeToReach ^ 2))
end

local function getClosestTarget()
    local bestPlayer, bestPart = nil, nil
    local bestDist = FOV_Radius
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Team ~= LocalPlayer.Team then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            
            -- ✅ شرط الحياة مضاف هنا
            if hum and hum.Health > 0 and hrp then
                local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    local distFromCenter = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                    if distFromCenter < bestDist then
                        local targetPart = getBestVisiblePart(player.Character)
                        if targetPart then
                            bestPlayer, bestPart, bestDist = player, targetPart, distFromCenter
                        end
                    end
                end
            end
        end
    end
    
    currentTarget = bestPlayer
    return bestPlayer, bestPart
end

-- ============================================
-- [ التشغيل الأساسي مع حماية إضافية ]
-- ============================================
RunService.Heartbeat:Connect(function(dt)
    if not AimbotEnabled then return end
    
    local targetPlayer, targetPart = getClosestTarget()
    
    -- ✅ تأكد إضافي: لا تصوب إذا كان الهدف ميتاً
    if targetPlayer and targetPart and isTargetValid(targetPlayer) then
        local targetPos = getPredictedPosition(targetPlayer, targetPart, dt)
        local targetCFrame = CFrame.new(Camera.CFrame.Position, targetPos)
        
        if Camera_Smoothness == 0 then
            Camera.CFrame = targetCFrame
        else
            Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, Camera_Smoothness)
        end
    else
        -- إذا مات الهدف أو اختفى، حرر الكاميرا
        currentTarget = nil
    end
end)

Players.PlayerRemoving:Connect(function(p)
    lastVelocities[p] = nil
    if currentTarget == p then currentTarget = nil end
end)
