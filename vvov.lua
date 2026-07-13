local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ============================================
-- [ الإعدادات المحسنة للسرعة الفورية ]
-- ============================================
local AimbotEnabled = true
local BulletSpeed = 3500     -- سرعة عالية جداً لجعل التنبؤ فوري ومباشر
local FOV_Radius = 150       -- حجم دائرة الـ FOV

-- التحقق الآمن من وجود Drawing API
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

-- [1] فحص الجدران والعوائق
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

-- [2] اختيار أفضل جزء مكشوف
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

-- [3] التنبؤ الفيزيائي المستقر
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

-- [4] جلب اللاعب الأقرب
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
-- [ 5. حلقة التحديث الفوري (تم إزالة الـ Lerp تماماً) ]
-- ============================================
RunService.Heartbeat:Connect(function(dt)
    if FOVCircle then
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    end
    
    if AimbotEnabled then
        local targetPlayer, targetPart = getClosestPlayer()
        if targetPlayer and targetPart then
            local finalTargetPos = getPredictedTargetPosition(targetPlayer, targetPart, dt)
            
            -- [ تعديل جوهري ]: الكاميرا الآن تلتفت فوراً وبسرعة 100% بدون أي تأخير أو مظهر بطيء
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, finalTargetPos)
        end
    end
end)

Players.PlayerRemoving:Connect(function(player)
    lastVelocities[player] = nil
end)

