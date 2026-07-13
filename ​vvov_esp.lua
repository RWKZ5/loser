local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ============================================
-- [ الإعدادات الأساسية ]
-- ============================================
local AimbotEnabled = true
local BulletSpeed = 650     -- سرعة الرصاصة (ارفعها لـ 3000+ لو الأسلحة تصيب فوراً Hitscan)
local Smoothness = 0.08     -- سلاسة التتبع (كل ما قلّ الرقم صار الأيم أسرع وأقوى)
local FOV_Radius = 150      -- حجم دائرة الـ FOV

-- التحقق الآمن من وجود Drawing API لضمان التوافق مع Delta
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
-- [ 1. فحص الجدران والعوائق (Raycast الحديث) ]
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

-- ============================================
-- [ 2. اختيار أفضل جزء مكشوف (R6 + R15 + تصفية الإكسسوارات) ]
-- ============================================
local function getBestVisiblePart(character)
    -- دعم المشغلات المشتركة لـ R6 و R15 بالترتيب
    local preferredParts = {"Head", "UpperTorso", "Torso", "HumanoidRootPart", "LowerTorso"}
    
    for _, partName in ipairs(preferredParts) do
        local part = character:FindFirstChild(partName)
        if part and isPartVisible(part) then
            return part 
        end
    end
    
    -- الحل البديل: اختيار الجزء المكشوف الأمثل والأقرب لمركز الشاشة (مع استبعاد القبعات والإكسسوارات)
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
    
    -- تنظيف الذاكرة فور خروج أي لاعب
    return bestAlternativePart
end

-- ============================================
-- [ 3. التنبؤ الفيزيائي المستقر والمطور ]
-- ============================================
local function getPredictedTargetPosition(targetPlayer, targetPart, dt)
    local hrp = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return targetPart.Position end

    local currentPosition = targetPart.Position
    local currentVelocity = hrp.AssemblyLinearVelocity
    
    local distance = (currentPosition - Camera.CFrame.Position).Magnitude
    local timeToReach = distance / BulletSpeed
    
    local previousVelocity = lastVelocities[targetPlayer] or currentVelocity
    local safeDeltaTime = math.max(dt, 0.0001)
    
    -- حساب التسارع اللحظي بناءً على الـ dt الفعلي
    local acceleration = (currentVelocity - previousVelocity) / safeDeltaTime
    lastVelocities[targetPlayer] = currentVelocity
    
    -- معادلة التنبؤ بالمسار المنحني والمراوغة
    return currentPosition + (currentVelocity * timeToReach) + (0.5 * acceleration * (timeToReach ^ 2))
end

-- ============================================
-- [ 4. جلب اللاعب الأقرب (Raycast خارج الحلقة للأداء العالي) ]
-- ============================================
local function getClosestPlayer()
    local closestTarget = nil
    local shortestDistance = FOV_Radius
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    -- الفرز السريع بناءً على مسافة الشاشة لتوفير موارد المعالج
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
    
    -- إطلاق الـ Raycast فقط على اللاعب الأقرب الذي تم اختياره
    if closestTarget then
        local targetPart = getBestVisiblePart(closestTarget.Character)
        if targetPart then
            return closestTarget, targetPart
        end
    end
    
    return nil, nil
end

-- ============================================
-- [ 5. حلقة التحديث المستمرة المتوافقة مع فيزياء روبلوكس ]
-- ============================================
RunService.Heartbeat:Connect(function(dt)
    if FOVCircle then
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    end
    
    if AimbotEnabled then
        local targetPlayer, targetPart = getClosestPlayer()
        if targetPlayer and targetPart then
            local finalTargetPos = getPredictedTargetPosition(targetPlayer, targetPart, dt)
            -- تحريك الكاميرا بسلاسة فائقة بدون تقطيع
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, finalTargetPos), Smoothness)
        end
    end
end)

-- تنظيف الذاكرة فور خروج أي لاعب
Players.PlayerRemoving:Connect(function(player)
    lastVelocities[player] = nil
end)


-- ============================================
-- [ إدراج نظام الـ ESP كشف مربعات ومسافات عبر الجدران ]
-- ============================================
local function HighlightPlayer(player)
    local Highlight = Instance.new("Highlight")
    Highlight.Name = "ESP_Highlight"
    Highlight.FillTransparency = 0.5 -- شفافية التعبئة الداخلية
    Highlight.OutlineTransparency = 0 -- وضوح الخط الخارجي للمربع
    
    -- تحديد الألوان بناءً على الفريق أو الحالة (مثل الصورة)
    Highlight.FillColor = Color3.fromRGB(255, 50, 50)  -- أحمر كإعداد افتراضي للأعداء
    Highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    
    local Billboard = Instance.new("BillboardGui")
    Billboard.Name = "ESP_Distance"
    Billboard.Size = UDim2.new(0, 100, 0, 30)
    Billboard.AlwaysOnTop = true -- تجعلها تظهر فوق الجدران
    Billboard.ExtentsOffset = Vector3.new(0, 3.5, 0) -- يظهر النص فوق رأس اللاعب
    
    local TextLabel = Instance.new("TextLabel", Billboard)
    TextLabel.Size = UDim2.new(1, 0, 1, 0)
    TextLabel.BackgroundTransparency = 1
    TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TextLabel.TextStrokeTransparency = 0 -- خلفية سوداء خفيفة للحرف ليكون واضحاً
    TextLabel.Font = Enum.Font.GothamBold
    TextLabel.TextSize = 10
    TextLabel.Text = "0m"

    local function ApplyESP(character)
        if character then
            Highlight.Parent = character
            local hrp = character:WaitForChild("HumanoidRootPart", 3)
            if hrp then
                Billboard.Parent = hrp
            end
        end
    end

    ApplyESP(player.Character)
    player.CharacterAdded:Connect(ApplyESP)

    -- تحديث المسافة بشكل مستمر لكل لاعب فريم بفريم
    local connection
    connection = RunService.RenderStepped:Connect(function()
        if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local targetHrp = player.Character.HumanoidRootPart
            local myHrp = LocalPlayer.Character.HumanoidRootPart
            
            -- حساب المسافة الفعلية بالمتر (Studs إلى أمتار تقريبية)
            local distance = math.floor((targetHrp.Position - myHrp.Position).Magnitude)
            TextLabel.Text = tostring(distance) .. "m"
            
            -- تغيير لون المربع ديناميكياً بناءً على رؤية الأيم بوت له (أحمر مكشوف / أخضر وراء جدار)
            local head = player.Character:FindFirstChild("Head")
            ifHeadAndVisible = head and isPartVisible(head)
            if ifHeadAndVisible then
                Highlight.FillColor = Color3.fromRGB(0, 255, 100) -- أخضر إذا كان مكشوفاً للأيم بوت
            else
                Highlight.FillColor = Color3.fromRGB(255, 50, 50)  -- أحمر إذا كان خلف جدار
            end
        else
            -- تنظيف إذا مات اللاعب أو اختفى
            Highlight:Destroy()
            Billboard:Destroy()
            connection:Disconnect()
        end
    end)
end

-- تفعيل الكشف على جميع اللاعبين الأعداء الحاليين والقادمين
local function checkAndApply(player)
    if player ~= LocalPlayer then
        -- إذا كان نظام اللعبة يحتوي على فرق (Teams)، يتم كشف العدو فقط
        if player.Team ~= LocalPlayer.Team then
            HighlightPlayer(player)
        end
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    checkAndApply(player)
end
Players.PlayerAdded:Connect(checkAndApply)
