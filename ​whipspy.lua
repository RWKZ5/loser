-- سكربت فحص وتجسس على ريموت السوط لكشف القيم الصحيحة
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("🔍 تم تشغيل سكربت الفحص المطور.. انتظر استخدام السوط في الماب")

local function hookRemote()
    local WhipRemote = nil
    if ReplicatedStorage:FindFirstChild("7lb") then
        WhipRemote = ReplicatedStorage["7lb"].Tools.Whip.Init
    end

    if WhipRemote and WhipRemote:IsA("RemoteEvent") then
        -- عمل جلب وتجسس على الطلبات المرسلة للسيرفر
        local oldOnServerEvent
        local mt = getrawmetatable(game)
        local namecall = mt.__namecall
        setreadonly(mt, false)

        mt.__namecall = newcclosure(function(self, ...)
            local args = {...}
            local method = getnamecallmethod()
            
            -- إذا تم استدعاء ريموت السوط
            if self == WhipRemote and method == "FireServer" then
                print("====================================")
                print("🎯 [تم التقاط أمر السوط بنجاح!]")
                for index, value in ipairs(args) do
                    print("المعطى رقم (" .. tostring(index) .. "):", value, "| النوع:", typeof(value))
                end
                print("====================================")
            end
            return namecall(self, ...)
        end)
        setreadonly(mt, true)
    else
        warn("❌ لم يتم العثور على ريموت السوط بعد، تأكد من وجوده في ReplicatedStorage")
    end
end

pcall(hookRemote)

