local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Teams = game:GetService("Teams")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ============================================
-- [ الإعدادات النهائية فائقة التوافق ]
-- ============================================
local AimbotEnabled = true
local BulletSpeed = 1000     -- سرعة التنبؤ الفيزيائي
local Smoothness = 0.35      -- سرعة الالتصاق التام بالرأس
local FOV_Radius = 150       -- قطر دائرة الأيم بوت

-- التحقق الآمن لإنشاء دائرة الـ FOV
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

-- [ فحص الاستهداف الذكي والآمن لمنع استهداف خوياك ]
local function isValidTarget(player)
    if not player or player == LocalPlayer then return false end
    
    -- تحقق من وجود نظام تيمات رسمي ونشط في الماب
    local totalTeams = Teams:GetTeams()
    local hasActiveTeams = #totalTeams > 1
    
    -- إذا كان الماب يحتوي على فرق وكان هذا اللاعب معك في نفس التيم (خويك) -> لا تستهدفه أبداً
    if hasActiveTeams and player.Team and LocalPlayer.Team then
        if player.Team == LocalPlayer.Team then
            return false
        end
    end
    
    -- فحص حماية إضافي في حال كانت اللعبة تستخدم ألواناً لتمييز الفرق
    if hasActiveTeams and player.TeamColor == LocalPlayer.TeamColor then
        return false
    end
    
    return true -- استهداف الأعداء فقط بشكل مضمون وتلقائي
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

-- [ 5. حلقة التحديث المستمرة للأيم بوت ]
RunService.Heartbeat:Connect(function(dt)
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
-- [ نظام الـ Box ESP المضمون لجميع الألعاب ]
-- ============================================
local function CreateBoxESP(player)
    if not player then return end
    
    local function cleanExistingESP(char)
        if char then
            local existing = char:FindFirstChild("ESP_Box", true)
            if existing then existing:Destroy() end
        end
    end

    local BoxGui = Instance.new("BillboardGui")
    BoxGui.Name = "ESP_Box"
    BoxGui.AlwaysOnTop = true
    BoxGui.Size = UDim2.new(4.5, 0, 6, 0)

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
        cleanExistingESP(character)
        
        local hrp = character:WaitForChild("HumanoidRootPart", 10)
        if hrp then
            BoxGui.Parent = hrp
        end
    end

    if player.Character then
        ApplyESP(player.Character)
    end
    player.CharacterAdded:Connect(ApplyESP)

    local connection
    connection = RunService.RenderStepped:Connect(function()
        if player and player.Parent and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            -- فحص مستمر لشرط الاستهداف (يخفي الـ ESP تلقائياً إذا أصبح اللاعب خويك)
            if not isValidTarget(player) then
                BoxGui:Destroy()
                if connection then connection:Disconnect() end
                return
            end

            local targetHrp = player.Character.HumanoidRootPart
            local myHrp = LocalPlayer.Character.HumanoidRootPart
            
            local distance = math.floor((targetHrp.Position - myHrp.Position).Magnitude)
            DistanceLabel.Text = tostring(distance) .. "m"
            
            local head = player.Character:FindFirstChild("Head")
            if head and isPartVisible(head) then
                Stroke.Color = Color3.fromRGB(0, 255, 100) -- أخضر (مكشوف)
            else
                Stroke.Color = Color3.fromRGB(255, 50, 50)  -- أحمر (خلف عائق)
            end
        else
            BoxGui:Destroy()
            if connection then connection:Disconnect() end
        end
    end)
end

local function checkAndApply(player)
    if player == LocalPlayer then return end
    
    local function onCharacterReady()
        if isValidTarget(player) then
            CreateBoxESP(player)
        end
    end
    
    if player.Character then
        onCharacterReady()
    end
    player.CharacterAdded:Connect(onCharacterReady)
end

-- تفعيل فوري ومباشر
for _, player in ipairs(Players:GetPlayers()) do
    checkAndApply(player)
end

Players.PlayerAdded:Connect(checkAndApply)
