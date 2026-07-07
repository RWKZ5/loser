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
-- [ UI Setup ]
-- ============================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "WhipCuffsBypass"
ScreenGui.Parent = game:GetService("CoreGui") 

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 220, 0, 260)
Frame.Position = UDim2.new(0.5, -110, 0.5, -130)
Frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Frame.BackgroundTransparency = 0.5
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 14)

local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1, 0, 0, 26)
Title.Position = UDim2.new(0, 0, 0, 2)
Title.BackgroundTransparency = 1
Title.Text = "وابل السوط وثغرة الكلبشة"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.TextXAlignment = Enum.TextXAlignment.Center

local Divider = Instance.new("Frame", Frame)
Divider.Size = UDim2.new(1, 0, 0, 2)
Divider.Position = UDim2.new(0, 0, 0, 30)
Divider.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
Divider.BackgroundTransparency = 0.6

local CountBox = Instance.new("TextBox", Frame)
CountBox.Size = UDim2.new(0, 180, 0, 28)
CountBox.Position = UDim2.new(0.5, -90, 0, 40)
CountBox.PlaceholderText = "عدد الضربات"
CountBox.Text = "50000"
CountBox.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
CountBox.BackgroundTransparency = 0.4
CountBox.TextColor3 = Color3.new(1, 1, 1)
CountBox.PlaceholderColor3 = Color3.fromRGB(160, 160, 160)
CountBox.Font = Enum.Font.Gotham
CountBox.TextSize = 12
CountBox.ClearTextOnFocus = false
Instance.new("UICorner", CountBox).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", CountBox).Color = Color3.fromRGB(180, 180, 180)

local SpeedBox = Instance.new("TextBox", Frame)
SpeedBox.Size = UDim2.new(0, 180, 0, 28)
SpeedBox.Position = UDim2.new(0.5, -90, 0, 72)
SpeedBox.PlaceholderText = "سرعة الضربات (0 = فوري)"
SpeedBox.Text = "0"
SpeedBox.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
SpeedBox.BackgroundTransparency = 0.4
SpeedBox.TextColor3 = Color3.new(1, 1, 1)
SpeedBox.PlaceholderColor3 = Color3.fromRGB(160, 160, 160)
SpeedBox.Font = Enum.Font.Gotham
SpeedBox.TextSize = 12
SpeedBox.ClearTextOnFocus = false
Instance.new("UICorner", SpeedBox).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", SpeedBox).Color = Color3.fromRGB(180, 180, 180)

local DistBox = Instance.new("TextBox", Frame)
DistBox.Size = UDim2.new(0, 180, 0, 28)  
DistBox.Position = UDim2.new(0.5, -90, 0, 104) 
DistBox.PlaceholderText = "مسافة التتبع (0 = داخل الهدف)"
DistBox.Text = "0"
DistBox.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
DistBox.BackgroundTransparency = 0.4
DistBox.TextColor3 = Color3.new(1, 1, 1)
DistBox.PlaceholderColor3 = Color3.fromRGB(160, 160, 160)
DistBox.Font = Enum.Font.Gotham
DistBox.TextSize = 12
DistBox.ClearTextOnFocus = false
Instance.new("UICorner", DistBox).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", DistBox).Color = Color3.fromRGB(180, 180, 180)

local NameBox = Instance.new("TextBox", Frame)
NameBox.Size = UDim2.new(0, 180, 0, 28)
NameBox.Position = UDim2.new(0.5, -90, 0, 136) 
NameBox.PlaceholderText = "الاسم كامل أو أول 3 حروف"
NameBox.Text = ""
NameBox.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
NameBox.BackgroundTransparency = 0.4
NameBox.TextColor3 = Color3.new(1, 1, 1)
NameBox.PlaceholderColor3 = Color3.fromRGB(160, 160, 160)
NameBox.Font = Enum.Font.Gotham
NameBox.TextSize = 12
NameBox.ClearTextOnFocus = false
Instance.new("UICorner", NameBox).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", NameBox).Color = Color3.fromRGB(180, 180, 180)

local FireBtn = Instance.new("TextButton", Frame)
FireBtn.Size = UDim2.new(0, 180, 0, 30)
FireBtn.Position = UDim2.new(0.5, -90, 0, 170)
FireBtn.Text = "أطلق وابل السوط"
FireBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
FireBtn.BackgroundTransparency = 0.7
FireBtn.TextColor3 = Color3.new(1, 1, 1)
FireBtn.Font = Enum.Font.GothamBold
FireBtn.TextSize = 12
Instance.new("UICorner", FireBtn).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", FireBtn).Color = Color3.fromRGB(180, 180, 180)

local TrackBtn = Instance.new("TextButton", Frame)
TrackBtn.Size = UDim2.new(0, 180, 0, 30)
TrackBtn.Position = UDim2.new(0.5, -90, 0, 206)
TrackBtn.Text = "التعقب : OFF"
TrackBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
TrackBtn.BackgroundTransparency = 0.7
TrackBtn.TextColor3 = Color3.new(1, 1, 1)
TrackBtn.Font = Enum.Font.GothamBold
TrackBtn.TextSize = 12
Instance.new("UICorner", TrackBtn).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", TrackBtn).Color = Color3.fromRGB(180, 180, 180)

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

-- دالة البحث عن أداة الكلبشة الحقيقية في حقيبتك أو يدك لتجاوز فحص السيرفر
local function findHandcuffs()
    local char = LocalPlayer.Character
    if char then
        -- البحث في اليد أولاً
        local tool = char:FindFirstChildOfClass("Tool")
        if tool and (tool.Name:lower():find("cuff") or tool.Name:find("كلبش")) then
            return tool
        end
        -- البحث في الحقيبة
        for _, t in ipairs(LocalPlayer.Backpack:GetChildren()) do
            if t:IsA("Tool") and (t.Name:lower():find("cuff") or t.Name:find("كلبش")) then
                return t
            end
        end
    end
    return nil
end

local function whipBarrage(targetPlayer, count, track, distance, speed)
    local targetChar = targetPlayer.Character
    if not targetChar or not targetChar:FindFirstChild("HumanoidRootPart") then return false end
    
    local myChar = LocalPlayer.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return false end

    local myRoot = myChar.HumanoidRootPart  
    local targetRoot = targetChar.HumanoidRootPart  

    -- البحث عن أداة الكلبشة الحقيقية في حسابك للاعتماد عليها
    local cuffsTool = findHandcuffs()
    if not cuffsTool then
        -- إذا لم يجدها، يبحث عن أول أداة حقيقية بالحقيبة كخيار احتياطي
        for _, t in ipairs(LocalPlayer.Backpack:GetChildren()) do
            if t:IsA("Tool") and t.Name ~= "تحديد العدو" then
                cuffsTool = t
                break
            end
        end
    end

    savedCFrame = myRoot.CFrame  
    myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, distance)     
    task.wait()  

    attackThread = task.spawn(function()
        for i = 1, count do  
            if not attackActive then break end  

            if track and targetRoot and targetRoot.Parent then  
                myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, distance)     
            end  

            if not myChar or not myChar.Parent or not myRoot or not myRoot.Parent then break end          

            local dir = Vector3.new(math.random(-100, 100) / 100, 0, math.random(-100, 100) / 100)  
            if targetChar and targetChar.Parent and WhipRemote and cuffsTool then  
                pcall(function()
                    -- [الخدعة العبقرية] السيرفر يشوف أداة كلبشة حقيقية يملكها اللاعب فيمرر الضربة فوراً بدون طرد!
                    WhipRemote:FireServer(cuffsTool, targetChar, dir)
                end)
            end  
              
            if speed > 0 then   
                task.wait(speed)
            else  
                -- انتظار ميكرو ثانية آمن لمنع حماية سبام الطلبات
                task.wait(0.01)  
            end  
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
                NameBox.Text = plr.Name   
            end  
        end  
    end)  
    
    tool.Parent = backpack  
    currentSelectorTool = tool  

    task.spawn(function()  
        local char = LocalPlayer.Character  
        if not char then return end  
        local humanoid = char:FindFirstChildOfClass("Humanoid")  
        if humanoid and currentSelectorTool then  
            task.wait(0.1)  
            humanoid:EquipTool(currentSelectorTool)  
        end  
    end)
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.2)
    giveSelectorTool()
end)
giveSelectorTool()

-- ============================================
-- [ UI Listeners ]
-- ============================================
FireBtn.MouseButton1Click:Connect(function()
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

        FireBtn.Text = "أطلق وابل السوط"  
        task.wait(0.1)  
        giveSelectorTool()  
        return  
    end  

    local nameInput = NameBox.Text  
    if #nameInput < 3 then 
        warn("⚠️ اكتب 3 حروف على الأقل") 
        return 
    end  
    
    local target = getPlayerByName(nameInput)  
    if not target then 
        warn("❌ لا يوجد لاعب بهذا الاسم") 
        return 
    end   

    local count = tonumber(CountBox.Text) or 50000  
    if count <= 0 then count = 50000 end  

    local distance = tonumber(DistBox.Text) or 0   
    if distance < 0 then distance = 0 end  

    local speed = tonumber(SpeedBox.Text) or 0  
    if speed < 0 then speed = 0 end  

    attackActive = true  
    whipBarrage(target, count, trackingEnabled, distance, speed)  
    FireBtn.Text = "إيقاف الوابل"
end)

TrackBtn.MouseButton1Click:Connect(function()
    trackingEnabled = not trackingEnabled
    TrackBtn.Text = trackingEnabled and "التعقب : ON" or "التعقب : OFF"
end)
