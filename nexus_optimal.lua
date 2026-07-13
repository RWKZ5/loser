local function getBestVisiblePart(character)
    -- 1. الفحص ذو الأولوية القصوى (الأجزاء المثالية بالترتيب)
    local preferredParts = {"Head", "UpperTorso", "HumanoidRootPart", "LowerTorso"}
    
    for _, partName in ipairs(preferredParts) do
        local part = character:FindFirstChild(partName)
        if part and isPartVisible(part) then
            return part -- إذا لقى جزء رئيسي مكشوف يعتمده فوراً
        end
    end
    
    -- 2. الحل البديل الذكي: (إذا كانت الأجزاء الرئيسية مخفية وظهرت أطراف متعددة كاليد والرجل)
    local bestAlternativePart = nil
    local shortestDistanceToCenter = math.huge
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    for _, part in ipairs(character:GetChildren()) do
        if part:IsA("BasePart") and isPartVisible(part) then
            -- حساب موقع هذا الجزء على الشاشة
            local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
            
            if onScreen then
                -- قياس بعد الجزء عن الكروس هير (منتصف الشاشة)
                local distanceToCenter = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                
                -- المفاضلة: نختار الجزء الأقرب لنص الشاشة لأنه الأسهل في التصويب والإصابة
                if distanceToCenter < shortestDistanceToCenter then
                    shortestDistanceToCenter = distanceToCenter
                    bestAlternativePart = part
                end
            end
        end
    end
    
    return bestAlternativePart -- يعيد النقطة المكشوفة "الأمثل" بدلاً من أول نقطة عشوائية
end
