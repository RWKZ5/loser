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

-- ============================================
-- [ إنشاء وتحديث دائرة الـ FOV ]
-- ============================================
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
-- [ تصميم الواجهة الرسومية (GUI) المخصصة للجوال ]
-- ============================================
local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 220, 0, 150)
MainFrame.Position = UDim2.new(0.5, -110, 0.15, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
MainFrame.Active = true
MainFrame.Draggable = true -- تتيح لك سحب القائمة في أي مكان بالشاشة
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

-- زر التشغيل والإيقاف
local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0, 180, 0, 35)
ToggleBtn.Position = UDim2.new(0.5, -90, 0, 20)
ToggleBtn.Text = "الأيم بوت: مفعل"
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 90)
ToggleBtn.TextColor3 = Color3.new(1, 1, 1)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 12
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 6)

-- نص السلايدر الخاص بالـ FOV
local SliderLabel = Instance.new("TextLabel", MainFrame)
SliderLabel.Size = UDim2.new(1, 0, 0, 25)
SliderLabel.Position = UDim2.new(0, 0, 0, 65)
SliderLabel.Text = "حجم الـ FOV: 150"
SliderLabel.TextColor3 = Color3.new(1, 1, 1)
SliderLabel.BackgroundTransparency = 1
SliderLabel.Font = Enum.Font.Gotham
SliderLabel.TextSize = 11

-- خلفية السلايدر
local SliderBg = Instance.new("Frame", MainFrame)
SliderBg.Size = UDim2.new(0, 180, 0, 6)
SliderBg.Position = UDim2.new(0.5, -90, 0, 95)
SliderBg.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
Instance.new("UICorner", SliderBg)

-- زر السحب الخاص بالسلايدر
local SliderBtn = Instance.new("TextButton", SliderBg)
SliderBtn.Size = UDim2.new(0, 18, 0, 18)
SliderBtn.Position = UDim2.new(0.3, -9, 0.5, -9) -- يبدأ من قيمة 150 تقريباً
SliderBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
SliderBtn.Text = ""
Instance.new("UICorner", SliderBtn).CornerRadius = UDim.new(1, 0)

-- زر التصغير [-] لإخفاء القائمة أثناء اللعب
local MinButton = Instance.new("TextButton", MainFrame)
MinButton.Size = UDim2.new(0, 25, 0, 25)
MinButton.Position = UDim2.new(1, -30, 0, 5)
MinButton.Text = "[-]"
MinButton.BackgroundTransparency = 1
MinButton.TextColor3 = Color3.fromRGB(255, 50, 50)
MinButton.Font = Enum.Font.GothamBold
MinButton.TextSize = 14

-- زر الفتح العائم الصغير (يظهر عند تصغير القائمة)
local OpenButton = Instance.new("TextButton", ScreenGui)
OpenButton.Size = UDim2.new(0, 80, 0, 30)
OpenButton.Position = UDim2.new(0, 10, 0, 10)
OpenButton.Text = "فتح القائمة"
OpenButton.Visible = false
OpenButton.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
OpenButton.TextColor3 = Color3.fromRGB(0, 200, 255)
OpenButton.Font = Enum.Font.GothamBold
OpenButton.TextSize = 11
Instance.new("UICorner", OpenButton)

-- ============================================
-- [ منطق عمل السلايدر باللمس والسحب للجوال ]
-- ============================================
local dragging = false
SliderBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

RunService.RenderStepped:Connect(function()
    if dragging then
        local inputPos = UserInputService:GetMouseLocation()
        local relativeX = math.clamp((inputPos.X - SliderBg.AbsolutePosition.X) / SliderBg.AbsoluteSize.X, 0, 1)
        SliderBtn.Position = UDim2.new(relativeX, -9, 0.5, -9)
        
        -- تغيير حجم الـ FOV من 50 كحد أدنى إلى 500 كحد أقصى
        FOV_Radius = math.floor(50 + (relativeX * 450))
        SliderLabel.Text = "حجم الـ FOV: " .. tostring(FOV_Radius)
        if FOVCircle then
            FOVCircle.Radius = FOV_Radius
        end
    end
end)

-- تفاعل أزرار التصغير والفتح
MinButton.MouseButton1Click:Connect(function() MainFrame.Visible = false; OpenButton.Visible = true end)
OpenButton.MouseButton1Click:Connect(function() MainFrame.Visible = true; OpenButton.Visible = false end)

-- تفاعل زر تشغيل وإيقاف الأيم بوت
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
    
    if raycastResult and raycastResult.Instance:IsDescendantOf(targetPart.Parent) then
        return true
    end
    return false
end

local function getBestVisiblePart(character)
    local preferredParts = {"Head", "UpperTorso", "Torso", "HumanoidRootPart"}
    
    for _, partName in ipairs(preferredParts) do
        local part = character:FindFirstChild(partName)
        if part and isPartVisible(part) then
            return part 
        end
    end
    
    local bestAlternativePart = nil
    local shortestDistanceToCenter = math.huge
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    for _, part in ipairs(character:GetChildren()) do
        if part:IsA("BasePart") and not part.Parent:IsA("Accessory") and not part.Parent:IsA("Hat") and isPartVisible(part) then
            local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
            if onScreen then
                local distanceToCenter = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                if distanceToCenter < shortestDistanceToCenter then
                    shortestDistanceToCenter = distanceToCenter
                    bestAlternativePart = part
                end
            end
        end
    end
    
    return bestAlternativePart
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
        if targetPart then
            return closestTarget, targetPart
        end
    end
    
    return nil, nil
end

-- ============================================
-- [ حلقة التحديث الفوري المربوطة بالفيزياء ]
-- ============================================
RunService.Heartbeat:Connect(function(dt)
    if FOVCircle and FOVCircle.Visible then
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    end
    
    if AimbotEnabled then
        local targetPlayer, targetPart = getClosestPlayer()
        if targetPlayer and targetPart then
            local finalTargetPos = getPredictedTargetPosition(targetPlayer, targetPart, dt)
            -- توجيه فوري وسريع جداً 100%
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, finalTargetPos)
        end
    end
end)

Players.PlayerRemoving:Connect(function(player)
    lastVelocities[player] = nil
end)

