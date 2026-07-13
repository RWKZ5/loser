local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ============================================
-- [ الإعدادات الافتراضية ]
-- ============================================
local AimbotEnabled = true
local BulletSpeed = 3500     
local FOV_Radius = 150      
local Camera_Smoothness = 0.05 -- القيمة الافتراضية للسرعة (كل ما صغرت صار أسرع)

-- [ إنشاء وتحديث دائرة الـ FOV ]
local FOVCircle = nil
if Drawing then
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Visible = true
    FOVCircle.Radius = FOV_Radius
    FOVCircle.Color = Color3.fromRGB(0, 255, 150)
    FOVCircle.Thickness = 1
    FOVCircle.Filled = false
end

local lastVelocities = {}

-- ============================================
-- [ تصميم الواجهة الرسومية (GUI) مع الرادار والسلايدرات ]
-- ============================================
local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))

-- النافذة الرئيسية
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 240, 0, 240)
MainFrame.Position = UDim2.new(0.5, -120, 0.15, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
MainFrame.Active = true
MainFrame.Draggable = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

-- زر التشغيل والإيقاف
local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0, 200, 0, 35)
ToggleBtn.Position = UDim2.new(0.5, -100, 0, 15)
ToggleBtn.Text = "الأيم بوت: مفعل"
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 90)
ToggleBtn.TextColor3 = Color3.new(1, 1, 1)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 12
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 6)

-- [ سلايدر الـ FOV ]
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
FOVSliderBtn.Size = UDim2.new(0, 16, 0, 16)
FOVSliderBtn.Position = UDim2.new(0.25, -8, 0.5, -8)
FOVSliderBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
FOVSliderBtn.Text = ""
Instance.new("UICorner", FOVSliderBtn).CornerRadius = UDim.new(1, 0)

-- [ سلايدر سرعة لفة الكاميرا ]
local SpeedSliderLabel = Instance.new("TextLabel", MainFrame)
SpeedSliderLabel.Size = UDim2.new(1, 0, 0, 20)
SpeedSliderLabel.Position = UDim2.new(0, 0, 0, 105)
SpeedSliderLabel.Text = "سرعة اللفة (Smoothness): 0.05"
SpeedSliderLabel.TextColor3 = Color3.new(1, 1, 1)
SpeedSliderLabel.BackgroundTransparency = 1
SpeedSliderLabel.Font = Enum.Font.Gotham
SpeedSliderLabel.TextSize = 11

local SpeedSliderBg = Instance.new("Frame", MainFrame)
SpeedSliderBg.Size = UDim2.new(0, 200, 0, 6)
SpeedSliderBg.Position = UDim2.new(0.5, -100, 0, 130)
SpeedSliderBg.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
Instance.new("UICorner", SpeedSliderBg)

local SpeedSliderBtn = Instance.new("TextButton", SpeedSliderBg)
SpeedSliderBtn.Size = UDim2.new(0, 16, 0, 16)
SpeedSliderBtn.Position = UDim2.new(0.5, -8, 0.5, -8)
SpeedSliderBtn.BackgroundColor3 = Color3.fromRGB(255, 150, 0)
SpeedSliderBtn.Text = ""
Instance.new("UICorner", SpeedSliderBtn).CornerRadius = UDim.new(1, 0)

-- [ نافذة الرادار المدمجة الماركة ]
local RadarFrame = Instance.new("Frame", MainFrame)
RadarFrame.Size = UDim2.new(0, 80, 0, 80)
RadarFrame.Position = UDim2.new(0.5, -40, 0, 150)
RadarFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
RadarFrame.BorderColor3 = Color3.fromRGB(0, 255, 150)
Instance.new("UICorner", RadarFrame).CornerRadius = UDim.new(0, 4)

-- نقطة اللاعب المركزية بالرادار
local CenterDot = Instance.new("Frame", RadarFrame)
CenterDot.Size = UDim2.new(0, 4, 0, 4)
CenterDot.Position = UDim2.new(0.5, -2, 0.5, -2)
CenterDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", CenterDot)

-- زر التصغير [-]
local MinButton = Instance.new("TextButton", MainFrame)
MinButton.Size = UDim2.new(0, 25, 0, 25)
MinButton.Position = UDim2.new(1, -30, 0, 5)
MinButton.Text = "[-]"
MinButton.BackgroundTransparency = 1
MinButton.TextColor3 = Color3.fromRGB(255, 50, 50)
MinButton.Font = Enum.Font.GothamBold
MinButton.TextSize = 14

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

-- ============================================
-- [ منطق عمل السلايدرات واللمس للجوال ]
-- ============================================
local draggingFOV = false
local draggingSpeed = false

FOVSliderBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingFOV = true end
end)
SpeedSliderBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingSpeed = true end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
        draggingFOV = false 
        draggingSpeed = false
    end
end)

-- تحديث السلايدرات والرادار فريم بفريم
local radarDots = {}

RunService.RenderStepped:Connect(function()
    local mousePos = UserInputService:GetMouseLocation()
    
    -- حساب سلايدر الـ FOV
    if draggingFOV then
        local relativeX = math.clamp((mousePos.X - FOVSliderBg.AbsolutePosition.X) / FOVSliderBg.AbsoluteSize.X, 0, 1)
        FOVSliderBtn.Position = UDim2.new(relativeX, -8, 0.5, -8)
        FOV_Radius = math.floor(50 + (relativeX * 450))
        FOVSliderLabel.Text = "حجم الـ FOV: " .. tostring(FOV_Radius)
        if FOVCircle then FOVCircle.Radius = FOV_Radius end
    end
    
    -- حساب سلايدر السرعة (تغيير الـ Smoothness من 0 إلى 0.3)
    if draggingSpeed then
        local relativeX = math.clamp((mousePos.X - SpeedSliderBg.AbsolutePosition.X) / SpeedSliderBg.AbsoluteSize.X, 0, 1)
        SpeedSliderBtn.Position = UDim2.new(relativeX, -8, 0.5, -8)
        Camera_Smoothness = relativeX * 0.3
        SpeedSliderLabel.Text = string.format("سرعة اللفة (Smoothness): %.3f", Camera_Smoothness)
    end
    
    -- تحديث دائرة الـ FOV العادية
    if FOVCircle and FOVCircle.Visible then
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    end
    
    -- [ تحديث نقاط الرادار ]
    for _, dot in pairs(radarDots) do dot:Destroy() end
    radarDots = {}
    
    if MainFrame.Visible then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Team ~= LocalPlayer.Team then
                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                local localHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                
                if hrp and localHrp then
                    -- حساب المسافة النسبية والاتجاه بالنسبة للاعب
                    local relPos = Camera.CFrame:ToObjectSpace(hrp.CFrame).Position
                    local x = relPos.X * 0.4 -- مقياس الرسم داخل المربع
                    local z = relPos.Z * 0.4
                    
                    -- التأكد من أن النقطة تقع ضمن حدود صندوق الرادار الصغير
                    if math.abs(x) < 38 and math.abs(z) < 38 then
                        local dot = Instance.new("Frame", RadarFrame)
                        dot.Size = UDim2.new(0, 4, 0, 4)
                        dot.Position = UDim2.new(0.5, x - 2, 0.5, z - 2)
                        dot.BackgroundColor3 = Color3.fromRGB(255, 50, 50) -- نقطة حمراء للأعداء
                        Instance.new("UICorner", dot)
                        table.insert(radarDots, dot)
                    end
                end
            end
        end
    end
end)

MinButton.MouseButton1Click:Connect(function() MainFrame.Visible = false; OpenButton.Visible = true end)
OpenButton.MouseButton1Click:Connect(function() MainFrame.Visible = true; OpenButton.Visible = false end)

ToggleBtn.MouseButton1Click:Connect(function()
    AimbotEnabled = not AimbotEnabled
    if AimbotEnabled then
        ToggleBtn.Text = "الأيم بوت: مفعل"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 90)
        if FOVCircle then FOVCircle.Visible = true end
    else
        ToggleBtn.Text = "الأيم بوت: معطل"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
        if FOVCircle then FOVCircle.Visible = false end
    end
end)

-- ============================================
-- [ المنطق البرمجي للأيم بوت (فحص جدران + اختيار أجزاء مكشوفة) ]
-- ============================================
local function isPartVisible(targetPart)
    local rayOrigin = Camera.CFrame.Position
    local rayDirection = (targetPart.Position - rayOrigin)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    
    local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    if raycastResult and raycastResult.Instance:IsDescendantOf(targetPart.Parent) then return true end
    return false
end

local function getBestVisiblePart(character)
    local preferredParts = {"Head", "UpperTorso", "Torso", "HumanoidRootPart"}
    for _, partName in ipairs(preferredParts) do
        local part = character:FindFirstChild(partName)
        if part and isPartVisible(part) then return part end
    end
    return nil
end

local function getPredictedTargetPosition(targetPlayer, targetPart, dt)
    local hrp = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return targetPart.Position end
    local currentPosition = targetPart.Position
    local currentVelocity = hrp.AssemblyLinearVelocity
    local distance = (currentPosition - Camera.CFrame.Position).Magnitude
    local timeToReach = distance / BulletSpeed
    local previousVelocity = lastVelocities[targetPlayer] or currentVelocity
    local safeDeltaTime = math.max(dt, 0.0001)
    local acceleration = (currentVelocity - previousVelocity) / safeDeltaTime
    lastVelocities[targetPlayer] = currentVelocity
    return currentPosition + (currentVelocity * timeToReach) + (0.5 * acceleration * (timeToReach ^ 2))
end

local function getClosestPlayer()
    local closestTarget = nil
    local shortestDistance = FOV_Radius
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Team ~= LocalPlayer.Team then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            local hrp = player.Character:FindFirstChild("HumanoidRootPart") or player.Character:FindFirstChild("Torso")
            if humanoid and humanoid.Health > 0 and hrp then
                local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    local distanceFromCenter = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                    if distanceFromCenter < shortestDistance then
                        closestTarget = player
                        shortestDistance = distanceFromCenter
                    end
                end
            end
        end
    end
    
    if closestTarget then
        local targetPart = getBestVisiblePart(closestTarget.Character)
        if targetPart then return closestTarget, targetPart end
    end
    return nil, nil
end

-- حلقة التحديث المربوطة بالفيزياء والسلاسة المتغيرة
RunService.Heartbeat:Connect(function(dt)
    if AimbotEnabled then
        local targetPlayer, targetPart = getClosestPlayer()
        if targetPlayer and targetPart then
            local finalTargetPos = getPredictedTargetPosition(targetPlayer, targetPart, dt)
            
            if Camera_Smoothness == 0 then
                -- لفة فورية 100%
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, finalTargetPos)
            else
                -- لفة ناعمة تعتمد على القيمة التي اخترتها من السلايدر البرتقالي
                Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, finalTargetPos), Camera_Smoothness)
            end
        end
    end
end)

Players.PlayerRemoving:Connect(function(player) lastVelocities[player] = nil end)
