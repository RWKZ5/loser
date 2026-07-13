local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ============================================
-- [ الإعدادات العامة ]
-- ============================================
local AimbotEnabled = true
local RadarEnabled = true
local Smoothness = 0.15

-- ============================================
-- [ تصميم الواجهة (Universal UI) ]
-- ============================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UniversalNexus"
ScreenGui.Parent = game:GetService("CoreGui") 

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 200, 0, 140)
MainFrame.Position = UDim2.new(0.5, -100, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
MainFrame.BackgroundTransparency = 0.1
MainFrame.Active = true
MainFrame.Draggable = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

local FrameStroke = Instance.new("UIStroke", MainFrame)
FrameStroke.Color = Color3.fromRGB(255, 255, 255)

-- زر التصغير [-]
local MinButton = Instance.new("TextButton", MainFrame)
MinButton.Size = UDim2.new(0, 30, 0, 30)
MinButton.Position = UDim2.new(1, -35, 0, 2)
MinButton.Text = "[-]"
MinButton.BackgroundTransparency = 1
MinButton.TextColor3 = Color3.new(1, 1, 1)

local OpenButton = Instance.new("TextButton", ScreenGui)
OpenButton.Size = UDim2.new(0, 80, 0, 30)
OpenButton.Position = UDim2.new(0, 10, 0, 10)
OpenButton.Text = "فتح السكربت"
OpenButton.Visible = false
Instance.new("UICorner", OpenButton)

-- أزرار التحكم
local ToggleAim = Instance.new("TextButton", MainFrame)
ToggleAim.Size = UDim2.new(0, 160, 0, 35)
ToggleAim.Position = UDim2.new(0.5, -80, 0, 30)
ToggleAim.Text = "أيم بوت: مفعل"
ToggleAim.BackgroundColor3 = Color3.fromRGB(0, 100, 255)
ToggleAim.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", ToggleAim)

local ToggleESP = Instance.new("TextButton", MainFrame)
ToggleESP.Size = UDim2.new(0, 160, 0, 35)
ToggleESP.Position = UDim2.new(0.5, -80, 0, 80)
ToggleESP.Text = "رادار (ESP): مفعل"
ToggleESP.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
ToggleESP.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", ToggleESP)

-- ============================================
-- [ ESP (الرادار) العالمي ]
-- ============================================
local function updateESP()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local highlight = player.Character:FindFirstChild("NexusHighlight")
            
            if RadarEnabled and player.Character:FindFirstChild("HumanoidRootPart") then
                -- تجاهل الفريق (إذا كان الماب يدعم الفرق)
                if player.Team == LocalPlayer.Team then
                    if highlight then highlight:Destroy() end
                    continue
                end

                if not highlight then
                    highlight = Instance.new("Highlight")
                    highlight.Name = "NexusHighlight"
                    highlight.Parent = player.Character
                    highlight.FillColor = Color3.fromRGB(255, 0, 0)
                    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                    highlight.FillTransparency = 0.5
                end
            else
                if highlight then highlight:Destroy() end
            end
        end
    end
end

-- ============================================
-- [ أيم بوت عالمي (يعمل على أي شخص) ]
-- ============================================
local function getClosest()
    local closest, dist = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            -- تجاهل الفريق
            if p.Team == LocalPlayer.Team then continue end
            
            local hum = p.Character:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 then
                local pos, vis = Camera:WorldToViewportPoint(p.Character.HumanoidRootPart.Position)
                if vis then
                    local d = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                    if d < dist then
                        closest, dist = p.Character.HumanoidRootPart, d
                    end
                end
            end
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function()
    if AimbotEnabled then
        local target = getClosest()
        if target then
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, target.Position), Smoothness)
        end
    end
    updateESP()
end)

-- ============================================
-- [ أزرار التفاعل ]
-- ============================================
MinButton.MouseButton1Click:Connect(function() MainFrame.Visible = false; OpenButton.Visible = true end)
OpenButton.MouseButton1Click:Connect(function() MainFrame.Visible = true; OpenButton.Visible = false end)

ToggleAim.MouseButton1Click:Connect(function()
    AimbotEnabled = not AimbotEnabled
    ToggleAim.Text = AimbotEnabled and "أيم بوت: مفعل" or "أيم بوت: معطل"
end)

ToggleESP.MouseButton1Click:Connect(function()
    RadarEnabled = not RadarEnabled
    ToggleESP.Text = RadarEnabled and "رادار (ESP): مفعل" or "رادار (ESP): معطل"
    -- تنظيف فوري عند الإغلاق
    if not RadarEnabled then for _,p in pairs(Players:GetPlayers()) do if p.Character and p.Character:FindFirstChild("NexusHighlight") then p.Character.NexusHighlight:Destroy() end end end
end)
