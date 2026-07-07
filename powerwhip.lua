local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")

-- تأمين الـ Remote
local WhipRemote = nil
pcall(function()
    if RS:FindFirstChild("7lb") then
        WhipRemote = RS["7lb"].Tools.Whip.Init
    end
end)

-- ============================================
-- [ تصميم واجهة جديد - تحكم بقوة الضربة وزر التصغير ]
-- ============================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "WhipNexusV4"
ScreenGui.Parent = game:GetService("CoreGui") 

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 240, 0, 240)
MainFrame.Position = UDim2.new(0.5, -120, 0.5, -120)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
MainFrame.BackgroundTransparency = 0.2
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

local FrameStroke = Instance.new("UIStroke", MainFrame)
FrameStroke.Color = Color3.fromRGB(0, 170, 255)
FrameStroke.Thickness = 1.5

local HeaderTitle = Instance.new("TextLabel", MainFrame)
HeaderTitle.Size = UDim2.new(1, -40, 0, 35)
HeaderTitle.Position = UDim2.new(0, 10, 0, 0)
HeaderTitle.BackgroundTransparency = 1
HeaderTitle.Text = "NEXUS WHIP - V4"
HeaderTitle.TextColor3 = Color3.fromRGB(0, 170, 255)
HeaderTitle.Font = Enum.Font.GothamBold
HeaderTitle.TextSize = 13
HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left

-- زر فتح الواجهة بعد تصغيرها (مخفي في البداية)
local OpenButton = Instance.new("TextButton", ScreenGui)
OpenButton.Size = UDim2.new(0, 80, 0, 30)
OpenButton.Position = UDim2.new(0, 10, 0, 10) -- في زاوية الشاشة فوق يسار
OpenButton.Text = "فتح القائمة"
OpenButton.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
OpenButton.TextColor3 = Color3.fromRGB(0, 170, 255)
OpenButton.Font = Enum.Font.GothamBold
OpenButton.TextSize = 12
OpenButton.Visible = false
Instance.new("UICorner", OpenButton).CornerRadius = UDim.new(0, 6)
local OpenStroke = Instance.new("UIStroke", OpenButton)
OpenStroke.Color = Color3.fromRGB(0, 170, 255)

-- زر التصغير [-] داخل الواجهة الرئيسية
local MinButton = Instance.new("TextButton", MainFrame)
MinButton.Size = UDim2.new(0, 30, 0, 30)
MinButton.Position = UDim2.new(1, -35, 0, 2)
MinButton.Text = "[-]"
MinButton.BackgroundTransparency = 1
MinButton.TextColor3 = Color3.fromRGB(255, 50, 50)
MinButton.Font = Enum.Font.GothamBold
MinButton.TextSize = 14

local TargetInput = Instance.new("TextBox", MainFrame)
TargetInput.Size = UDim2.new(0, 200, 0, 32)
TargetInput.Position = UDim2.new(0.5, -100, 0, 45)
TargetInput.PlaceholderText = "اسم الهدف (3 حروف أو أكثر)"
TargetInput.Text = ""
TargetInput.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
TargetInput.TextColor3 = Color3.new(1, 1, 1)
TargetInput.PlaceholderColor3 = Color3.fromRGB(120, 120, 140)
TargetInput.Font = Enum.Font.Gotham
TargetInput.TextSize = 12
TargetInput.ClearTextOnFocus = false
Instance.new("UICorner", TargetInput).CornerRadius = UDim.new(0, 6)

local PowerInput = Instance.new("TextBox", MainFrame)
PowerInput.Size = UDim2.new(0, 200, 0, 32)
PowerInput.Position = UDim2.new(0.5, -100, 0, 90)
PowerInput.PlaceholderText = "قوة الإطاحة/الطيران (مثلاً: 100)"
PowerInput.Text = "100"
PowerInput.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
PowerInput.TextColor3 = Color3.new(1, 1, 1)
PowerInput.PlaceholderColor3 = Color3.fromRGB(120, 120, 140)
PowerInput.Font = Enum.Font.Gotham
PowerInput.TextSize = 12
PowerInput.ClearTextOnFocus = false
Instance.new("UICorner", PowerInput).CornerRadius = UDim.new(0, 6)

local ActionButton = Instance.new("TextButton", MainFrame)
ActionButton.Size = UDim2.new(0, 200, 0, 40)
ActionButton.Position = UDim2.new(0.5, -100, 0, 145)
ActionButton.Text = "إطلاق الضربة القاضية 💥"
ActionButton.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
ActionButton.TextColor3 = Color3.new(1, 1, 1)
ActionButton.Font = Enum.Font.GothamBold
ActionButton.TextSize = 13
Instance.new("UICorner", ActionButton).CornerRadius = UDim.new(0, 6)

local ToggleTrack = Instance.new("TextButton", MainFrame)
ToggleTrack.Size = UDim2.new(0, 200, 0, 30)
ToggleTrack.Position = UDim2.new(0.5, -100, 0, 195)
ToggleTrack.Text = "حالة الانتقال للهدف: معطل"
ToggleTrack.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
ToggleTrack.TextColor3 = Color3.new(1, 1, 1)
ToggleTrack.Font = Enum.Font.GothamBold
ToggleTrack.TextSize = 11
Instance.new("UICorner", ToggleTrack).CornerRadius = UDim.new(0, 6)

-- ============================================
-- [ States & Functions ]
-- ============================================
local teleportToTarget = false
local savedCFrame = nil
local currentSelectorTool = nil

local function getPlayerByName(name)
    local lower = name:lower():gsub(" ", "")
    if #lower < 3 then return nil end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Name:lower():gsub(" ", "") == lower then
            return plr
        end
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Name:lower():gsub(" ", ""):sub(1, #lower) == lower then
            return plr
        end
    end
    return nil
end

local function launchSingleHit(targetPlayer, powerValue)
    local targetChar = targetPlayer.Character
    if not targetChar or not targetChar:FindFirstChild("HumanoidRootPart") then return end
    
    local myChar = LocalPlayer.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return end

    local myRoot = myChar.HumanoidRootPart  
    local targetRoot = targetChar.HumanoidRootPart  

    if teleportToTarget then
        savedCFrame = myRoot.CFrame  
        myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 2)     
        task.wait(0.05)
    end

    local weapon = nil
    for _, t in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if t:IsA("Tool") and t.Name ~= "تحديد العدو" then
            weapon = t
            break
        end
    end

    local dir = Vector3.new(0, 1, 0) * powerValue 
    
    if WhipRemote then
        pcall(function()
            WhipRemote:FireServer(weapon, targetChar, dir)
        end)
    end

    if teleportToTarget and savedCFrame then
        task.wait(0.1)
        myRoot.CFrame = savedCFrame
    end
end

-- ============================================
-- [ Selector Tool Setup ]
-- ============================================
local function giveSelectorTool()
    if currentSelectorTool and currentSelectorTool.Parent then
        currentSelectorTool:Destroy()
    end
    local backpack = LocalPlayer:FindFirstChild("Backpack")  
    if not backpack then return end  

    local tool = Instance.new("Tool")  
    tool.Name = "تحديد العدو"  
    tool.RequiresHandle = false  
    
    tool.Activated:Connect(function()  
        local mouse = LocalPlayer:GetMouse()  
        local target = mouse.Target  
        if not target then return end  
        local char = target:FindFirstAncestorWhichIsA("Model")  
        if char then  
            local plr = Players:GetPlayerFromCharacter(char)  
            if plr and plr ~= LocalPlayer then  
                TargetInput.Text = plr.Name   
            end  
        end  
    end)  
    tool.Parent = backpack  
    currentSelectorTool = tool  
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.2)
    giveSelectorTool()
end)
giveSelectorTool()

-- ============================================
-- [ UI Listeners ]
-- ============================================
-- منطق أزرار التصغير والتكبير
MinButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    OpenButton.Visible = true
end)

OpenButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    OpenButton.Visible = false
end)

ActionButton.MouseButton1Click:Connect(function()
    local nameInput = TargetInput.Text  
    if #nameInput < 3 then return end  
    
    local target = getPlayerByName(nameInput)  
    if not target then return end   

    local powerValue = tonumber(PowerInput.Text) or 100
    launchSingleHit(target, powerValue)
end)

ToggleTrack.MouseButton1Click:Connect(function()
    teleportToTarget = not teleportToTarget
    if teleportToTarget then
        ToggleTrack.Text = "حالة الانتقال للهدف: مفعل"
        ToggleTrack.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
    else
        ToggleTrack.Text = "حالة الانتقال للهدف: معطل"
        ToggleTrack.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    end
end)
