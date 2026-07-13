local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")

-- ============================================
-- [ إعدادات السكربت الافتراضية ]
-- ============================================
local AimbotEnabled = true
local RadarEnabled = true
local Smoothness = 0.15

-- ============================================
-- [ تصميم واجهة الجوال ]
-- ============================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NexusMobileRadar"
ScreenGui.Parent = game:GetService("CoreGui") 

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 220, 0, 160)
MainFrame.Position = UDim2.new(0.5, -110, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
MainFrame.BackgroundTransparency = 0.2
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

local FrameStroke = Instance.new("UIStroke", MainFrame)
FrameStroke.Color = Color3.fromRGB(255, 0, 100)
FrameStroke.Thickness = 1.5

-- زر التصغير [-]
local MinButton = Instance.new("TextButton", MainFrame)
MinButton.Size = UDim2.new(0, 30, 0, 30)
MinButton.Position = UDim2.new(1, -35, 0, 2)
MinButton.Text = "[-]"
MinButton.BackgroundTransparency = 1
MinButton.TextColor3 = Color3.fromRGB(255, 50, 50)
MinButton.Font = Enum.Font.GothamBold
MinButton.TextSize = 14

-- زر فتح الواجهة
local OpenButton = Instance.new("TextButton", ScreenGui)
OpenButton.Size = UDim2.new(0, 100, 0, 35)
OpenButton.Position = UDim2.new(0, 10, 0, 10)
OpenButton.Text = "فتح الرادار والأيم"
OpenButton.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
OpenButton.TextColor3 = Color3.fromRGB(255, 0, 100)
OpenButton.Font = Enum.Font.GothamBold
OpenButton.TextSize = 11
OpenButton.Visible = false
Instance.new("UICorner", OpenButton).CornerRadius = UDim.new(0, 6)

-- أزرار التحكم
local ToggleAim = Instance.new("TextButton", MainFrame)
ToggleAim.Size = UDim2.new(0, 180, 0, 35)
ToggleAim.Position = UDim2.new(0.5, -90, 0, 45)
ToggleAim.Text = "التثبيت الذكي: مفعل"
ToggleAim.BackgroundColor3 = Color3.fromRGB(0, 150, 90)
ToggleAim.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", ToggleAim).CornerRadius = UDim.new(0, 6)

local ToggleRadar = Instance.new("TextButton", MainFrame)
ToggleRadar.Size = UDim2.new(0, 180, 0, 35)
ToggleRadar.Position = UDim2.new(0.5, -90, 0, 95)
ToggleRadar.Text = "الرادار والـ ESP: مفعل"
ToggleRadar.BackgroundColor3 = Color3.fromRGB(200, 0, 80)
ToggleRadar.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", ToggleRadar).CornerRadius = UDim.new(0, 6)

-- ============================================
-- [ منطق التثبيت الذكي (أقرب نقطة متاحة) ]
-- ============================================
local function getBestPart(character)
    -- الترتيب المفضل للتثبيت: الرأس أولاً، ثم الجسم، ثم بقية النقاط
    local parts = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"}
    for _, partName do
        local part = character:FindFirstChild(partName)
        if part then
            return part -- يعيد أول نقطة متوفرة وصالحة تلقائياً
        end
    end
    -- إذا لم يجد الأجزاء الرئيسية، يثبت على أي جزء متاح داخل جسم اللاعب
    return character:FindFirstChildWhichIsA("BasePart")
end

local function getClosestPlayerToCenter()
    local closestPlayer = nil
    local targetPart = nil
    local shortestDistance = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            -- تجاهل التلقائي للخويا
            if player.Team == LocalPlayer.Team then continue end

            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local part = getBestPart(player.Character)
                if part then
                    local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                    if onScreen then
                        local screenSize = Camera.ViewportSize
                        local screenCenter = Vector2.new(screenSize.X / 2, screenSize.Y / 2)
                        local distance = (Vector2.new(pos.X, pos.Y) - screenCenter).Magnitude
                        
                        if distance < shortestDistance then
                            closestPlayer = player
                            targetPart = part
                            shortestDistance = distance
                        end
                    end
                end
            end
        end
    end
    return closestPlayer, targetPart
end

-- ============================================
-- [ نظام الرادار وصناعة الـ ESP تلقائياً للأعداء ]
-- ============================================
local espObjects = {}

local function createESP(player)
    if player == LocalPlayer then return end
    
    local box = Instance.new("BoxHandleAdornment")
    box.Name = "NexusESP"
    box.AlwaysOnTop = true
    box.ZIndex = 5
    box.Color3 = Color3.fromRGB(255, 0, 100)
    box.Transparency = 0.5
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "NexusName"
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 100, 0, 30)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    
    local nameLabel = Instance.new("TextLabel", billboard)
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 10
    
    espObjects[player] = {Box = box, Billboard = billboard, Label = nameLabel}
end

local function updateESP()
    for player, esp in pairs(espObjects) do
        if RadarEnabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Team ~= LocalPlayer.Team then
            local root = player.Character.HumanoidRootPart
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            
            if humanoid and humanoid.Health > 0 then
                esp.Box.Adornee = player.Character
                esp.Box.Size = player.Character:GetExtentsSize()
                esp.Box.Parent = workspace
                
                esp.Billboard.Adornee = root
                esp.Billboard.Parent = workspace
                
                local dist = math.floor((LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and (LocalPlayer.Character.HumanoidRootPart.Position - root.Position).Magnitude) or 0)
                esp.Label.Text = player.Name .. " [" .. tostring(dist) .. "m]"
            else
                esp.Box.Parent = nil
                esp.Billboard.Parent = nil
            end
        else
            esp.Box.Parent = nil
            esp.Billboard.Parent = nil
        end
    end
end

for _, p in ipairs(Players:GetPlayers()) do createESP(p) end
Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(function(p) if espObjects[p] then espObjects[p] = nil end end)

-- تشغيل الأيم بوت والرادار مع التحديث المستمر
RunService.RenderStepped:Connect(function()
    if AimbotEnabled then
        local target, part = getClosestPlayerToCenter()
        if target and part then
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, part.Position), Smoothness)
        end
    end
    updateESP()
end)

-- ============================================
-- [ التفاعل والتحكم ]
-- ============================================
MinButton.MouseButton1Click:Connect(function() MainFrame.Visible = false; OpenButton.Visible = true end)
OpenButton.MouseButton1Click:Connect(function() MainFrame.Visible = true; OpenButton.Visible = false end)

ToggleAim.MouseButton1Click:Connect(function()
    AimbotEnabled = not AimbotEnabled
    ToggleAim.Text = AimbotEnabled and "التثبيت الذكي: مفعل" or "التثبيت الذكي: معطل"
    ToggleAim.BackgroundColor3 = AimbotEnabled and Color3.fromRGB(0, 150, 90) or Color3.fromRGB(100, 30, 30)
end)

ToggleRadar.MouseButton1Click:Connect(function()
    RadarEnabled = not RadarEnabled
    ToggleRadar.Text = RadarEnabled and "الرادار والـ ESP: مفعل" or "الرادار والـ ESP: معطل"
    ToggleRadar.BackgroundColor3 = RadarEnabled and Color3.fromRGB(200, 0, 80) or Color3.fromRGB(100, 30, 30)
end)
