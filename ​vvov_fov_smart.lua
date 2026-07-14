local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Teams = game:GetService("Teams")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ============================================
-- [ الإعدادات الأساسية فائقة التوافق ]
-- ============================================
local AimbotEnabled = true
local BulletSpeed = 1000     -- سرعة الرصاصة للتنبؤ الفيزيائي
local Smoothness = 0.35      -- سرعة الالتصاق التام بالرأس (تثبيت قوي وسريع)
local FOV_Radius = 150       -- قطر دائرة الأيم بوت

-- جدول عالمي لتعقب اتصالات ومربعات الـ ESP لكل لاعب ومنع التكرار
local ActiveESPs = {}
local lastVelocities = {}

-- [ إنشاء دائرة الـ FOV وإظهارها ]
local FOVCircle = nil
if Drawing then
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Visible = true
    FOVCircle.Radius = FOV_Radius
    FOVCircle.Color = Color3.fromRGB(0, 255, 150)
    FOVCircle.Thickness = 1
    FOVCircle.Filled = false
else
    -- تنبيه احتياطي في حال عدم دعم المفسر للرسم
    warn("Drawing library not supported by your executor!")
end

-- [ فحص الذكاء الاصطناعي للفرق والأصدقاء ]
local function isValidTarget(player)
    if not player or player == LocalPlayer then return false end
    
    -- التحقق هل الماب يحتوي على تيمات حقيقية ونشطة
    local totalTeams = Teams:GetTeams()
    local hasRealTeams = #totalTeams > 1
    
    -- إذا كان هناك تيمات حقيقية في الماب وكان اللاعب في نفس تيمك، يتم استبعاده (خويك)
    if hasRealTeams and player.Team and LocalPlayer.Team then
        if player.Team == LocalPlayer.Team then
            return false -- صديق (خويك)، لا تستهدفه
        end
    end
    
    return true -- عدو (يتم استهدافه بالـ ESP والأيم بوت)
end

-- [ 1. فحص الجدران والعوائق ]
local function isPartVisible(targetPart)
    if not targetPart then return false end
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

-- [ 2. اختيار أفضل جزء مكشوف ]
local function getBestVisiblePart(character)
    if not character then return nil end
    local preferredParts = {"Head", "UpperTorso", "Torso", "HumanoidRootPart", "LowerTorso"}
    for _, partName in ipairs(preferredParts) do
        local part = character:FindFirstChild(partName)
        if part and isPartVisible(part) then return part end
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

-- [ 3. التنبؤ الفيزيائي المستقر ]
local function getPredictedTargetPosition(targetPlayer, targetPart, dt)
    if not targetPlayer or not targetPart then return nil end
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

-- [ 4. جلب اللاعب الأقرب ]
local function getClosestPlayer()
    local closestTarget = nil
    local shortestDistance = FOV_Radius
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    for _, player in ipairs(Players:GetPlayers()) do
        if isValidTarget(player) and player.Character then
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

-- [ 5. حلقة التحديث المستمرة للأيم بوت والدائرة ]
RunService.Heartbeat:Connect(function(dt)
    -- تحديث موقع الدائرة في منتصف الشاشة دائماً
    if FOVCircle then
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    end
    
    if AimbotEnabled then
        local targetPlayer, targetPart = getClosestPlayer()
        if targetPlayer and targetPart then
            local finalTargetPos = getPredictedTargetPosition(targetPlayer, targetPart, dt)
            if finalTargetPos then
                Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, finalTargetPos), Smoothness)
            end
        end
    end
end)

Players.PlayerRemoving:Connect(function(player)
    lastVelocities[player] = nil
end)


-- ============================================
-- [ نظام الـ Box ESP الجديد فائق الثبات والديناميكية ]
-- ============================================

-- دالة المسح الصارم للـ ESP القديم
local function RemoveESP(player)
    if ActiveESPs[player] then
        if ActiveESPs[player].Gui then
            ActiveESPs[player].Gui:Destroy()
        end
        if ActiveESPs[player].Connection then
            ActiveESPs[player].Connection:Disconnect()
        end
        ActiveESPs[player] = nil
    end
end

local function CreateBoxESP(player)
    if not player then return end
    
    -- تنظيف فوري لأي تكرار قديم قبل البدء
    RemoveESP(player)

    local BoxGui = Instance.new("BillboardGui")
    BoxGui.Name = "ESP_Box"
    BoxGui.AlwaysOnTop = true
    BoxGui.Size = UDim2.new(4.5, 0, 6, 0)
    BoxGui.Enabled = false -- نبدأ بوضع الإخفاء حتى تكتمل شروط الظهور

    local Frame = Instance.new("Frame", BoxGui)
    Frame.Size = UDim2.new(1, 0, 1, 0)
    Frame.BackgroundTransparency = 1
    
    local Stroke = Instance.new("UIStroke", Frame)
    Stroke.Thickness = 1.5
    Stroke.Color = Color3.fromRGB(255, 50, 50)

    local DistanceLabel = Instance.new("TextLabel", BoxGui)
    DistanceLabel.Size = UDim2.new(1, 0, 0, 15)
    DistanceLabel.Position = UDim2.new(0, 0, 1, 2)
    DistanceLabel.BackgroundTransparency = 1
    DistanceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    DistanceLabel.TextStrokeTransparency = 0
    DistanceLabel.Font = Enum.Font.GothamBold
    DistanceLabel.TextSize = 10
    DistanceLabel.Text = "0m"

    local function ApplyESP(character)
        if not character then return end
        local hrp = character:WaitForChild("HumanoidRootPart", 10)
        if hrp then
            BoxGui.Parent = hrp
            BoxGui.Adornee = hrp -- تثبيت المربع بدقة متناهية في منتصف اللاعب
        end
    end

    if player.Character then
        ApplyESP(player.Character)
    end

    -- تحديث فريم بفريم بشكل ديناميكي كامل ومستقر
    local connection
    connection = RunService.RenderStepped:Connect(function()
        if player and player.Parent and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            
            -- فحص مستمر وحي لحالة الاستهداف (يتتبع تغيرات التيم والفرندز ديناميكياً)
            if isValidTarget(player) then
                BoxGui.Enabled = true -- إظهار المربع فوراً للخصوم
                
                local targetHrp = player.Character.HumanoidRootPart
                local myHrp = LocalPlayer.Character.HumanoidRootPart
                
                local distance = math.floor((targetHrp.Position - myHrp.Position).Magnitude)
                DistanceLabel.Text = tostring(distance) .. "m"
                
                local head = player.Character:FindFirstChild("Head")
                if head and isPartVisible(head) then
                    Stroke.Color = Color3.fromRGB(0, 255, 100) -- أخضر مكشوف
                else
                    Stroke.Color = Color3.fromRGB(255, 50, 50)  -- أحمر خلف جدار
                end
            else
                BoxGui.Enabled = false -- إخفاء المربع فوراً لو كان صديقاً/خوياً دون تعطيل الاتصال
            end
        else
            BoxGui.Enabled = false
        end
    end)

    -- حفظ الكائنات داخل الجدول العالمي للوصول السريع والتنظيف الصارم
    ActiveESPs[player] = {
        Gui = BoxGui,
        Connection = connection
    }
end

-- دالة الربط والتأمين
local function checkAndApply(player)
    if player == LocalPlayer then return end
    
    if player.Character then
        CreateBoxESP(player)
    end
    
    -- إعادة البناء التلقائي عند رسبنة اللاعب لضمان تحديث الـ Adornee
    player.CharacterAdded:Connect(function()
        CreateBoxESP(player)
    end)
end

-- تفعيل فوري ومستقر للاعبين الحاليين
for _, player in ipairs(Players:GetPlayers()) do
    checkAndApply(player)
end

-- مراقبة انضمام اللاعبين الجدد بأمان
Players.PlayerAdded:Connect(checkAndApply)

-- مسح وتنظيف السكربت عند مغادرة أي لاعب فوراً لمنع تعليق المربعات
Players.PlayerRemoving:Connect(RemoveESP)

