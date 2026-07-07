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
-- [ تصميم واجهة جديد ومطور - UI Redesign ]
-- ============================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "WhipNexusV3" -- اسم جديد تماماً لتجنب الكاش
ScreenGui.Parent = game:GetService("CoreGui") 

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 240, 0, 280)
MainFrame.Position = UDim2.new(0.5, -120, 0.5, -140)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25) -- لون خلفية جديد (كحلي داكن)
MainFrame.BackgroundTransparency = 0.2
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

-- إضافة إطار جمالي (Stroke) للواجهة الجديدة
local FrameStroke = Instance.new("UIStroke", MainFrame)
FrameStroke.Color = Color3.fromRGB(0, 170, 255) -- حواف زرقاء مضيئة للتأكد من التغيير
FrameStroke.Thickness = 1.5

local HeaderTitle = Instance.new("TextLabel", MainFrame)
HeaderTitle.Size = UDim2.new(1, 0, 0, 35)
HeaderTitle.Position = UDim2.new(0, 0, 0, 0)
HeaderTitle.BackgroundTransparency = 1
HeaderTitle.Text = "NEXUS WHIP - V3"
HeaderTitle.TextColor3 = Color3.fromRGB(0, 170, 255)
HeaderTitle.Font = Enum.Font.GothamBold
HeaderTitle.TextSize = 14
HeaderTitle.TextXAlignment = Enum.TextXAlignment.Center

local TargetInput = Instance.new("TextBox", MainFrame)
TargetInput.Size = UDim2.new(0, 200, 0, 30)
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

local AttackCount = Instance.new("TextBox", MainFrame)
AttackCount.Size = UDim2.new(0, 200, 0, 30)
AttackCount.Position = UDim2.new(0.5, -100, 0, 85)
AttackCount.PlaceholderText = "عدد الضربات"
AttackCount.Text = "5000"
AttackCount.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
AttackCount.TextColor3 = Color3.new(1, 1, 1)
AttackCount.PlaceholderColor3 = Color3.fromRGB(120, 120, 140)
AttackCount.Font = Enum.Font.Gotham
AttackCount.TextSize = 12
AttackCount.ClearTextOnFocus = false
Instance.new("UICorner", AttackCount).CornerRadius = UDim.new(0, 6)

local CustomDelay = Instance.new("TextBox", MainFrame)
CustomDelay.Size = UDim2.new(0, 200, 0, 30)
CustomDelay.Position = UDim2.new(0.5, -100, 0, 125)
CustomDelay.PlaceholderText = "تأخير الأمان (افتراضي: 0.1)"
CustomDelay.Text = "0.1" -- قيمة افتراضية آمنة لتجنب طرد الحماية الفوري
CustomDelay.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
CustomDelay.TextColor3 = Color3.new(1, 1, 1)
CustomDelay.PlaceholderColor3 = Color3.fromRGB(120, 120, 140)
CustomDelay.Font = Enum.Font.Gotham
CustomDelay.TextSize = 12
CustomDelay.ClearTextOnFocus = false
Instance.new("UICorner", CustomDelay).CornerRadius = UDim.new(0, 6)

local ActionButton = Instance.new("TextButton", MainFrame)
ActionButton.Size = UDim2.new(0, 200, 0, 35)
ActionButton.Position = UDim2.new(0.5, -100, 0, 170)
ActionButton.Text = "بدء الهجوم المطور"
ActionButton.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
ActionButton.TextColor3 = Color3.new(1, 1, 1)
ActionButton.Font = Enum.Font.GothamBold
ActionButton.TextSize = 13
Instance.new("UICorner", ActionButton).CornerRadius = UDim.new(0, 6)

local ToggleTrack = Instance.new("TextButton", MainFrame)
ToggleTrack.Size = UDim2.new(0, 200, 0, 35)
ToggleTrack.Position = UDim2.new(0.5, -100, 0, 215)
ToggleTrack.Text = "حالة التتبع: معطل"
ToggleTrack.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
ToggleTrack.TextColor3 = Color3.new(1, 1, 1)
ToggleTrack.Font = Enum.Font.GothamBold
ToggleTrack.TextSize = 12
Instance.new("UICorner", ToggleTrack).CornerRadius = UDim.new(0, 6)

-- ============================================
-- [ States ]
-- ============================================
local trackingEnabled = false
local attackActive = false
local attackThread = nil
local savedCFrame = nil
local currentSelectorTool = nil

-- ============================================
-- [ Functions ]
-- ============================================
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

local function executeWhipAttack(targetPlayer, count, track, delayTime)
    local targetChar = targetPlayer.Character
    if not targetChar or not targetChar:FindFirstChild("HumanoidRootPart") then return false end
    
    local myChar = LocalPlayer.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return false end

    local myRoot = myChar.HumanoidRootPart  
    local targetRoot = targetChar.HumanoidRootPart  

    savedCFrame = myRoot.CFrame  
    myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 0)     
    task.wait(0.1)  

    attackThread = task.spawn(function()
        -- محاولة جلب أي أداة حقيقية كخطوة احترازية للتحقق
        local weapon = nil
        for _, t in ipairs(LocalPlayer.Backpack:GetChildren()) do
            if t:IsA("Tool") and t.Name ~= "تحديد العدو" then
                weapon = t
                break
            end
        end

        for i = 1, count do  
            if not attackActive then break end  

            if track and targetRoot and targetRoot.Parent then  
                myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 0)     
            end  

            if not myChar or not myChar.Parent or not myRoot or not myRoot.Parent then break end          

            local dir = Vector3.new(math.random(-100, 100) / 100, 0, math.random(-100, 100) / 100)  
            if targetChar and targetChar.Parent and WhipRemote then  
                pcall(function()
                    WhipRemote:FireServer(weapon, targetChar, dir)
                end)
            end  
              
            task.wait(delayTime)  
        end  
    end)  
    return true
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
ActionButton.MouseButton1Click:Connect(function()
    if attackActive then
        attackActive = false
        if attackThread then 
            task.cancel(attackThread)
            attackThread = nil 
        end
        local myChar = LocalPlayer.Character  
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")  
        if myRoot and savedCFrame then 
            myRoot.CFrame = savedCFrame     
        end
        ActionButton.Text = "بدء الهجوم المطور"  
        ActionButton.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
        return  
    end  

    local nameInput = TargetInput.Text  
    if #nameInput < 3 then return end  
    
    local target = getPlayerByName(nameInput)  
    if not target then return end   

    local count = tonumber(AttackCount.Text) or 5000  
    local delayTime = tonumber(CustomDelay.Text) or 0.1  

    attackActive = true  
    executeWhipAttack(target, count, trackingEnabled, delayTime)  
    ActionButton.Text = "إيقاف الهجوم"
    ActionButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
end)

ToggleTrack.MouseButton1Click:Connect(function()
    trackingEnabled = not trackingEnabled
    if trackingEnabled then
        ToggleTrack.Text = "حالة التتبع: مفعل"
        ToggleTrack.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
    else
        ToggleTrack.Text = "حالة التتبع: معطل"
        ToggleTrack.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    end
end)
