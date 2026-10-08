-- ================================================
-- VOSS | Abyss Expedition v16 (Anti-Oan Edition)
-- ================================================
-- [NÂNG CẤP v16]:
-- 1. CHỐNG RƠI XUYÊN MAP (StreamingEnabled):
--    - Tự động gọi RequestStreamAroundAsync ép tải map trước khi đáp
--    - Tạo bệ đỡ vô hình (SafePlatform) 16x16 studs dưới chân 3.5s
--    - Neo nhân vật (Anchored = true) 0.35s đầu để map load xong 100%
-- 2. TỰ TRÁNH BẪY & CHỖ CHẾT LẶP LẠI (Blacklist Lethal Spots):
--    - Lưu lịch sử các vị trí an toàn (safeHistory)
--    - Nếu chết < 4 giây sau khi tele đến điểm A → điểm A bị cấm
--    - Tự động lùi về vị trí an toàn trước đó trong lịch sử, không chết lặp
-- 3. RAYCAST XÁC NHẬN MẶT ĐẤT VỮNG CHẮC:
--    - Chỉ lưu vị trí khi Raycast bắn xuống thấy sàn cứng CanCollide = true
--    - Cooldown 4 giây sau hồi sinh không lưu pos mới (tránh lưu chỗ nguy hiểm)
-- 4. BẢO VỆ TẠM THỜI SAU KHI TELEPORT:
--    - Tạm khóa HumanoidStateType.Dead trong 1.5s đầu
--    - Triệt tiêu hoàn toàn quán tính rơi
-- 5. CHỐNG SÁT THƯƠNG RƠI (No Fall Damage) & SPEED KHÔNG MẤT
-- ================================================

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local LP                = Players.LocalPlayer
local Cam               = workspace.CurrentCamera

-- Trạng thái toàn cục
local State = {
    immortal = false,
    nofall   = true,   -- Mặc định bật chống sát thương rơi
    esp      = false,
    autofarm = false,
    speed    = false,
    fly      = false,
}
local CFG = { 
    walkspeed = 70, 
    flyspeed  = 55 
}

-- Quản lý Nhân Vật & Vị Trí An Toàn
local Char, HRP, Hum
local lastGroundPos       = nil   -- Vị trí sàn an toàn hiện tại
local safeHistory         = {}    -- Danh sách lịch sử các vị trí an toàn đã kiểm chứng
local blacklistedPoints   = {}    -- Các điểm bẫy / điểm rơi làm người chơi chết < 4s
local lastTeleportTime    = 0     -- Thời điểm vừa tele xong
local justTeleported      = false -- Đang trong giai đoạn bảo vệ sau tele
local humConns            = {}

local function clearHumConns()
    for _, c in pairs(humConns) do
        pcall(function() c:Disconnect() end)
    end
    humConns = {}
end

-- ================================================
-- UTILS
-- ================================================
local function findRemoteEvent(name)
    for _, v in pairs(game:GetDescendants()) do
        if v:IsA("RemoteEvent") and v.Name == name then
            return v
        end
    end
    return nil
end

-- Bắn Raycast kiểm tra dưới chân có sàn cứng không
local function isSolidGroundBelow(pos)
    if not Char then return false end
    local rayOrigin = pos + Vector3.new(0, 1, 0)
    local rayDir    = Vector3.new(0, -10, 0)
    local params    = RaycastParams.new()
    params.FilterDescendantsInstances = {Char}
    params.FilterType = RaycastFilterType.Exclude

    local result = workspace:Raycast(rayOrigin, rayDir, params)
    if result and result.Instance and result.Instance.CanCollide then
        return true, result.Position
    end
    return false, nil
end

-- Kiểm tra xem vị trí có gần điểm chết độc hại nào không
local function isBlacklisted(cf)
    if not cf then return true end
    local p = cf.Position
    for _, bPos in ipairs(blacklistedPoints) do
        if (p - bPos).Magnitude < 30 then
            return true
        end
    end
    return false
end

-- Thêm vị trí vào lịch sử an toàn (nếu cách xa điểm cũ > 25 studs)
local function pushSafeHistory(cf)
    if not cf or isBlacklisted(cf) then return end
    if #safeHistory == 0 then
        table.insert(safeHistory, cf)
    else
        local last = safeHistory[#safeHistory]
        if (cf.Position - last.Position).Magnitude > 25 then
            table.insert(safeHistory, cf)
            if #safeHistory > 10 then
                table.remove(safeHistory, 1) -- Giữ tối đa 10 điểm gần nhất
            end
        end
    end
end

-- Lấy điểm an toàn tốt nhất (không bị dính bẫy)
local function getBestSafePoint()
    -- Thử điểm gần nhất trước
    if lastGroundPos and not isBlacklisted(lastGroundPos) then
        return lastGroundPos
    end
    -- Lùi dần trong lịch sử
    for i = #safeHistory, 1, -1 do
        local cf = safeHistory[i]
        if not isBlacklisted(cf) then
            return cf
        end
    end
    return lastGroundPos -- Nếu cùng đường mới dùng điểm này
end

-- Tạo bệ đỡ an toàn tạm thời (chống rơi xuyên map khi chưa kịp load chunk)
local function spawnSafePlatform(cf)
    local plat = Instance.new("Part")
    plat.Name         = "VOSS_SafePlatform"
    plat.Size         = Vector3.new(16, 1.5, 16)
    plat.CFrame       = cf - Vector3.new(0, 2.5, 0)
    plat.Anchored     = true
    plat.CanCollide   = true
    plat.Transparency = 1
    plat.Material     = Enum.Material.SmoothPlastic
    plat.Parent       = workspace

    -- Tự hủy sau 3.5 giây khi map thật đã load xong
    task.delay(3.5, function()
        pcall(function() plat:Destroy() end)
    end)
    return plat
end

-- Forward declaration
local startFly, stopFly

-- ================================================
-- HỆ THỐNG XỬ LÝ NHÂN VẬT & SỰ KIỆN
-- ================================================
local function onCharacterSetup(newChar)
    Char = newChar
    HRP  = newChar:WaitForChild("HumanoidRootPart", 10)
    Hum  = newChar:WaitForChild("Humanoid", 10)

    clearHumConns()

    if Hum then
        -- Khóa BreakJoints để tránh vỡ xác client
        pcall(function()
            Hum.BreakJointsOnDeath = false
        end)

        -- 1. Duy trì tốc độ chạy liên tục, chống game reset về 16
        local cSpeed = Hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
            if State.speed and Hum.WalkSpeed ~= CFG.walkspeed then
                pcall(function() Hum.WalkSpeed = CFG.walkspeed end)
            end
        end)
        table.insert(humConns, cSpeed)

        if State.speed then
            pcall(function() Hum.WalkSpeed = CFG.walkspeed end)
        end

        -- 2. Chống sốc khi chạm đất (No Fall Damage)
        local cState = Hum.StateChanged:Connect(function(_, newState)
            if newState == Enum.HumanoidStateType.Landed then
                if (State.nofall or State.immortal) and HRP then
                    pcall(function()
                        local v = HRP.AssemblyLinearVelocity
                        HRP.AssemblyLinearVelocity = Vector3.new(v.X, 0, v.Z)
                    end)
                end
            end
        end)
        table.insert(humConns, cState)
    end
end

-- Khởi tạo ban đầu
if LP.Character then
    onCharacterSetup(LP.Character)
    if HRP then
        lastGroundPos = HRP.CFrame
        pushSafeHistory(HRP.CFrame)
    end
end

-- ================================================
-- VÒNG LẶP CHÍNH (HEARTBEAT)
-- ================================================
local ESPCache    = {}
local MOB_FOLDERS = {"Mobs","Enemies","Monsters","Entities","NPCs","Boss","Enemy"}
local groundCheckTimer = 0

RunService.Heartbeat:Connect(function(dt)
    if HRP and Hum and Hum.Health > 0 then
        -- Chỉ ghi nhận vị trí mặt đất khi KHÔNG đang trong 4s cooldown sau tele
        if not justTeleported then
            groundCheckTimer = groundCheckTimer + dt
            if groundCheckTimer >= 0.25 then
                groundCheckTimer = 0
                local floor = Hum.FloorMaterial
                if floor and floor ~= Enum.Material.Air then
                    local isSolid, hitPos = isSolidGroundBelow(HRP.Position)
                    if isSolid then
                        lastGroundPos = HRP.CFrame
                        pushSafeHistory(HRP.CFrame)
                    end
                end
            end
        end

        -- Ép tốc độ chạy
        if State.speed and Hum.WalkSpeed ~= CFG.walkspeed then
            pcall(function() Hum.WalkSpeed = CFG.walkspeed end)
        end

        -- Chống sát thương rơi: kìm hãm tốc độ rơi tự do
        if (State.nofall or State.immortal) then
            local vel = HRP.AssemblyLinearVelocity
            if vel.Y < -25 then
                HRP.AssemblyLinearVelocity = Vector3.new(vel.X, -18, vel.Z)
            end
        end
    end

    -- ESP logic
    if not State.esp then
        if next(ESPCache) then
            for k, v in pairs(ESPCache) do
                pcall(function() v:Destroy() end)
                ESPCache[k] = nil
            end
        end
        return
    end

    local seen = {}
    for _, fname in pairs(MOB_FOLDERS) do
        local f = workspace:FindFirstChild(fname)
        if f then
            for _, mob in pairs(f:GetChildren()) do
                local mh  = mob:FindFirstChild("HumanoidRootPart")
                local mhu = mob:FindFirstChildOfClass("Humanoid")
                local key = tostring(mob)
                if mh and mhu and mhu.Health > 0 then
                    seen[key] = true
                    if not ESPCache[key] then
                        local bb = Instance.new("BillboardGui")
                        bb.AlwaysOnTop = true
                        bb.Size        = UDim2.new(0,130,0,26)
                        bb.StudsOffset = Vector3.new(0,3.5,0)
                        bb.Adornee     = mh
                        bb.Parent      = mh
                        local lbl = Instance.new("TextLabel", bb)
                        lbl.Size                   = UDim2.new(1,0,1,0)
                        lbl.BackgroundTransparency = 1
                        lbl.TextColor3             = Color3.fromRGB(255,70,70)
                        lbl.TextStrokeTransparency = 0
                        lbl.Font                   = Enum.Font.GothamBold
                        lbl.TextScaled             = true
                        lbl.Text                   = mob.Name
                        ESPCache[key] = bb
                    end
                end
            end
        end
    end

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local ph  = p.Character:FindFirstChild("HumanoidRootPart")
            local key = "p_"..p.Name
            if ph then
                seen[key] = true
                if not ESPCache[key] then
                    local bb = Instance.new("BillboardGui")
                    bb.AlwaysOnTop = true
                    bb.Size        = UDim2.new(0,130,0,26)
                    bb.StudsOffset = Vector3.new(0,3.5,0)
                    bb.Adornee     = ph
                    bb.Parent      = ph
                    local lbl = Instance.new("TextLabel", bb)
                    lbl.Size                   = UDim2.new(1,0,1,0)
                    lbl.BackgroundTransparency = 1
                    lbl.TextColor3             = Color3.fromRGB(80,255,80)
                    lbl.TextStrokeTransparency = 0
                    lbl.Font                   = Enum.Font.GothamBold
                    lbl.TextScaled             = true
                    lbl.Text                   = p.Name
                    ESPCache[key] = bb
                end
            end
        end
    end

    for k, v in pairs(ESPCache) do
        if not seen[k] then
            pcall(function() v:Destroy() end)
            ESPCache[k] = nil
        end
    end
end)

-- ================================================
-- HỒI SINH TẠI CHỖ CHUẨN XÁC & BẢO VỆ TUYỆT ĐỐI (v16)
-- ================================================
LP.CharacterAdded:Connect(function(newChar)
    local now = tick()

    -- 1. KIỂM TRA ĐIỂM CHẾT OAN / BẪY:
    -- Nếu chết trong vòng 4 giây sau lần teleport vừa rồi:
    -- ĐIỂM ĐÓ LÀ BẪY HOẶC VỰC SÂU ĐỘC HẠI!
    if justTeleported and (now - lastTeleportTime) < 4.0 then
        if lastGroundPos then
            table.insert(blacklistedPoints, lastGroundPos.Position)
            -- Loại bỏ điểm này khỏi lịch sử
            for i = #safeHistory, 1, -1 do
                if (safeHistory[i].Position - lastGroundPos.Position).Magnitude < 30 then
                    table.remove(safeHistory, i)
                end
            end
        end
    end

    -- 2. Chọn điểm hồi sinh tốt nhất (không nằm trong blacklist)
    local targetCFrame = getBestSafePoint()

    -- 3. Setup nhân vật mới
    task.wait(0.2)
    onCharacterSetup(newChar)

    -- 4. Thực hiện Hồi Sinh Teleport
    if State.immortal and targetCFrame and HRP then
        justTeleported   = true
        lastTeleportTime = tick()

        -- Ép engine tải map chunk ở điểm đích (tránh rơi xuyên sàn)
        pcall(function()
            LP:RequestStreamAroundAsync(targetCFrame.Position)
        end)

        -- Tạo bệ đỡ an toàn dưới chân đề phòng map chưa nạp xong
        spawnSafePlatform(targetCFrame)

        task.wait(0.12)
        if HRP then
            -- Triệt tiêu hoàn toàn vận tốc
            HRP.AssemblyLinearVelocity  = Vector3.zero
            HRP.AssemblyAngularVelocity = Vector3.zero

            -- Neo tạm 0.35s để nạp vật lý mặt đất
            HRP.Anchored = true
            HRP.CFrame   = targetCFrame + Vector3.new(0, 3.2, 0)

            -- Khóa tạm trạng thái Dead để tránh game kích hoạt chết nhầm
            if Hum then
                pcall(function()
                    Hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
                    Hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                end)
            end

            task.delay(0.35, function()
                if HRP then
                    HRP.Anchored = false
                    HRP.AssemblyLinearVelocity  = Vector3.zero
                    HRP.AssemblyAngularVelocity = Vector3.zero
                end
                -- Mở lại Dead state sau 1.5s an toàn
                task.delay(1.2, function()
                    if Hum then
                        pcall(function()
                            Hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
                        end)
                    end
                end)
            end)

            -- Backup check: Nếu game giật người chơi về điểm spawn ở Layer 1
            task.delay(0.5, function()
                if State.immortal and HRP and targetCFrame then
                    local dist = (HRP.Position - targetCFrame.Position).Magnitude
                    if dist > 35 then
                        HRP.AssemblyLinearVelocity = Vector3.zero
                        HRP.CFrame = targetCFrame + Vector3.new(0, 3.2, 0)
                    end
                end
            end)
        end

        -- Sau 4 giây sống sót an toàn mới bắt đầu ghi nhận lại vị trí an toàn mới
        task.delay(4.0, function()
            justTeleported = false
        end)
    else
        justTeleported = false
    end

    -- 5. Khôi phục Speed Hack ngay lập tức
    if State.speed and Hum then
        pcall(function() Hum.WalkSpeed = CFG.walkspeed end)
    end

    -- 6. Khôi phục Fly (nếu đang bật)
    if State.fly then
        task.wait(0.3)
        if startFly then startFly() end
    end
end)

-- ================================================
-- IMMORTAL TOGGLE CALLBACKS
-- ================================================
local function startImmortal()
    if HRP then
        lastGroundPos = HRP.CFrame
        pushSafeHistory(HRP.CFrame)
    end
end

local function stopImmortal()
    blacklistedPoints = {}
end

-- ================================================
-- FLY (HỖ TRỢ CẢ MOBILE & PC)
-- ================================================
local flyConn    = nil
local flyObjects = {}

local function cleanFlyObjects()
    for _, obj in pairs(flyObjects) do
        pcall(function() obj:Destroy() end)
    end
    flyObjects = {}
    if HRP then
        for _, n in pairs({"VOSS_BV","VOSS_BG"}) do
            local o = HRP:FindFirstChild(n)
            if o then pcall(function() o:Destroy() end) end
        end
    end
end

stopFly = function()
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    cleanFlyObjects()
    if Hum then
        pcall(function()
            Hum.PlatformStand = false
            Hum.AutoRotate    = true
        end)
    end
end

local function getFlyDirection()
    local dir = Vector3.zero
    -- Hỗ trợ Mobile cần điều khiển ảo & WASD PC
    if Hum and Hum.MoveDirection.Magnitude > 0 then
        dir = Hum.MoveDirection
    end

    -- Phím Space (bay lên) & Ctrl/C (hạ xuống)
    local uis = UserInputService
    if uis:IsKeyDown(Enum.KeyCode.Space) then
        dir = dir + Vector3.new(0, 1, 0)
    end
    if uis:IsKeyDown(Enum.KeyCode.LeftControl) or uis:IsKeyDown(Enum.KeyCode.C) then
        dir = dir + Vector3.new(0, -1, 0)
    end
    return dir
end

startFly = function()
    stopFly()
    task.wait(0.05)
    if not HRP or not Hum then return end

    Hum.PlatformStand = true
    Hum.AutoRotate    = false

    local bv = Instance.new("BodyVelocity")
    bv.Name     = "VOSS_BV"
    bv.Velocity = Vector3.zero
    bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    bv.P        = 1e4
    bv.Parent   = HRP
    table.insert(flyObjects, bv)

    local bg = Instance.new("BodyGyro")
    bg.Name      = "VOSS_BG"
    bg.MaxTorque = Vector3.new(0, 4e5, 0)
    bg.P         = 2e4
    bg.D         = 200
    bg.CFrame    = HRP.CFrame
    bg.Parent    = HRP
    table.insert(flyObjects, bg)

    flyConn = RunService.RenderStepped:Connect(function()
        if not State.fly or not HRP or not Hum then 
            stopFly()
            return 
        end
        local bv2 = HRP:FindFirstChild("VOSS_BV")
        local bg2 = HRP:FindFirstChild("VOSS_BG")
        if not bv2 or not bg2 then 
            stopFly()
            return 
        end

        local fDir = getFlyDirection()
        bv2.Velocity = fDir.Magnitude > 0 and (fDir.Unit * CFG.flyspeed) or Vector3.zero

        local look = Vector3.new(Cam.CFrame.LookVector.X, 0, Cam.CFrame.LookVector.Z)
        if look.Magnitude > 0.01 then
            bg2.CFrame = CFrame.new(HRP.Position, HRP.Position + look)
        end
    end)
end

-- ================================================
-- AUTO FARM
-- ================================================
local farmConn

local function findAttackRemotes()
    local found = {}
    for _, v in pairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            local n = v.Name:lower()
            if n:find("attack") or n:find("hit") or n:find("damage")
            or n:find("skill")  or n:find("combat") or n:find("cast") then
                table.insert(found, v)
            end
        end
    end
    return found
end

local function nearestEnemy()
    local best, bd = nil, 9999
    if not HRP then return nil end
    for _, fname in pairs(MOB_FOLDERS) do
        local f = workspace:FindFirstChild(fname)
        if f then
            for _, mob in pairs(f:GetChildren()) do
                local mh  = mob:FindFirstChild("HumanoidRootPart")
                local mhu = mob:FindFirstChildOfClass("Humanoid")
                if mh and mhu and mhu.Health > 0 then
                    local d = (HRP.Position - mh.Position).Magnitude
                    if d < bd then best = mob; bd = d end
                end
            end
        end
    end
    return best
end

local function teleportToNearest()
    local mob = nearestEnemy()
    if not mob or not HRP then return end
    local mh = mob:FindFirstChild("HumanoidRootPart")
    if mh then 
        HRP.AssemblyLinearVelocity = Vector3.zero
        HRP.CFrame = mh.CFrame + Vector3.new(4, 4.5, 0) 
    end
end

local function startFarm()
    if farmConn then return end
    local remotes = findAttackRemotes()
    local last = 0
    farmConn = RunService.Heartbeat:Connect(function()
        if not State.autofarm then return end
        local now = tick()
        if now - last < 0.15 then return end
        last = now
        local mob = nearestEnemy()
        if not mob or not HRP then return end
        local mh = mob:FindFirstChild("HumanoidRootPart")
        if not mh then return end
        
        HRP.AssemblyLinearVelocity = Vector3.zero
        HRP.CFrame = mh.CFrame + Vector3.new(3, 4, 0)
        for _, r in pairs(remotes) do
            pcall(function()
                if r:IsA("RemoteEvent") then 
                    r:FireServer(mob, mh.Position)
                else 
                    r:InvokeServer(mob, mh.Position) 
                end
            end)
        end
    end)
end

local function stopFarm()
    if farmConn then farmConn:Disconnect(); farmConn = nil end
end

-- ================================================
-- GUI TỰ ĐỘNG CÂN CHỈNH
-- ================================================
pcall(function()
    game:GetService("CoreGui"):FindFirstChild("VOSS_Hub"):Destroy()
end)

local SG = Instance.new("ScreenGui")
SG.Name           = "VOSS_Hub"
SG.ResetOnSpawn   = false
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SG.Parent         = game:GetService("CoreGui")

local Panel = Instance.new("Frame", SG)
Panel.Name             = "Panel"
Panel.Size             = UDim2.new(0, 260, 0, 560)
Panel.Position         = UDim2.new(0, 20, 0.5, -280)
Panel.BackgroundColor3 = Color3.fromRGB(10, 10, 16)
Panel.BorderSizePixel  = 0
Panel.Active           = true
Panel.Draggable        = true
Instance.new("UICorner", Panel).CornerRadius = UDim.new(0, 12)

local sk = Instance.new("UIStroke", Panel)
sk.Color = Color3.fromRGB(90, 50, 210)
sk.Thickness = 1.5

local Title = Instance.new("TextLabel", Panel)
Title.Size               = UDim2.new(1, 0, 0, 42)
Title.BackgroundTransparency = 1
Title.Text               = "VOSS  |  Abyss  v16"
Title.TextColor3         = Color3.fromRGB(165, 110, 255)
Title.Font               = Enum.Font.GothamBold
Title.TextSize           = 17

local Hint = Instance.new("TextLabel", Panel)
Hint.Size                = UDim2.new(1, 0, 0, 16)
Hint.Position            = UDim2.new(0, 0, 0, 42)
Hint.BackgroundTransparency = 1
Hint.Text                = "3 ngón×2 ẩn  |  3 ngón×3 hiện  |  RShift PC"
Hint.TextColor3          = Color3.fromRGB(85, 85, 125)
Hint.Font                = Enum.Font.Gotham
Hint.TextSize            = 10

local Div = Instance.new("Frame", Panel)
Div.Size             = UDim2.new(0.85, 0, 0, 1)
Div.Position         = UDim2.new(0.075, 0, 0, 62)
Div.BackgroundColor3 = Color3.fromRGB(70, 45, 140)
Div.BorderSizePixel  = 0

local btnY = 70

local function makeToggle(label, key, onEnable, onDisable)
    local frame = Instance.new("Frame", Panel)
    frame.Size             = UDim2.new(0.88, 0, 0, 44)
    frame.Position         = UDim2.new(0.06, 0, 0, btnY)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    frame.BorderSizePixel  = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    btnY = btnY + 52

    local lbl = Instance.new("TextLabel", frame)
    lbl.Size               = UDim2.new(0.65, 0, 1, 0)
    lbl.Position           = UDim2.new(0.05, 0, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text               = label
    lbl.TextColor3         = Color3.fromRGB(200, 195, 220)
    lbl.Font               = Enum.Font.GothamSemibold
    lbl.TextSize           = 12.5
    lbl.TextXAlignment     = Enum.TextXAlignment.Left

    local pill = Instance.new("Frame", frame)
    pill.Size             = UDim2.new(0, 44, 0, 22)
    pill.Position         = UDim2.new(1, -52, 0.5, -11)
    pill.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    pill.BorderSizePixel  = 0
    Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)

    local dot = Instance.new("Frame", pill)
    dot.Size             = UDim2.new(0, 18, 0, 18)
    dot.Position         = UDim2.new(0, 2, 0.5, -9)
    dot.BackgroundColor3 = Color3.fromRGB(90, 70, 160)
    dot.BorderSizePixel  = 0
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    local btn = Instance.new("TextButton", frame)
    btn.Size               = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text               = ""

    local function refresh()
        local on = State[key]
        TweenService:Create(pill, TweenInfo.new(0.14), {
            BackgroundColor3 = on and Color3.fromRGB(75, 45, 195) or Color3.fromRGB(35, 35, 50)
        }):Play()
        TweenService:Create(dot, TweenInfo.new(0.14), {
            Position = on and UDim2.new(0, 24, 0.5, -9) or UDim2.new(0, 2, 0.5, -9),
            BackgroundColor3 = on and Color3.fromRGB(195, 160, 255) or Color3.fromRGB(90, 70, 160)
        }):Play()
    end

    btn.MouseButton1Click:Connect(function()
        State[key] = not State[key]
        refresh()
        if State[key] then
            if onEnable then onEnable() end
        else
            if onDisable then onDisable() end
        end
    end)

    refresh()
end

local function makeAction(label, callback)
    local frame = Instance.new("Frame", Panel)
    frame.Size             = UDim2.new(0.88, 0, 0, 44)
    frame.Position         = UDim2.new(0.06, 0, 0, btnY)
    frame.BackgroundColor3 = Color3.fromRGB(30, 15, 50)
    frame.BorderSizePixel  = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    btnY = btnY + 52

    local sk2 = Instance.new("UIStroke", frame)
    sk2.Color = Color3.fromRGB(120, 60, 255)
    sk2.Thickness = 1

    local btn = Instance.new("TextButton", frame)
    btn.Size               = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text               = label
    btn.TextColor3         = Color3.fromRGB(200, 160, 255)
    btn.Font               = Enum.Font.GothamSemibold
    btn.TextSize           = 13
    btn.MouseButton1Click:Connect(callback)
end

-- Tạo các nút chức năng
makeToggle("☠  Bất Tử (Hồi Sinh Tránh Oan)", "immortal", startImmortal, stopImmortal)
makeToggle("🪂  Chống Rơi (No Fall)",          "nofall")
makeToggle("⚡  Speed Hack (Không Mất)",        "speed")
makeToggle("🕊  Bay (Cần Ảo Mobile / WASD)",   "fly", startFly, stopFly)
makeToggle("👁  ESP Quái & Người",              "esp")
makeToggle("⚔  Auto Farm",                     "autofarm", startFarm, stopFarm)
makeAction("📍 Tele → Mob Gần Nhất",           teleportToNearest)

-- ================================================
-- CỬ CHỈ ĐIỀU KHIỂN (3 NGÓN TAY MOBILE & RSHIFT PC)
-- ================================================
local visible       = true
local tapCount      = 0
local lastTapTime   = 0
local activeTouches = {}
local peakCount     = 0

UserInputService.TouchStarted:Connect(function(touch)
    activeTouches[touch] = true
    local cnt = 0
    for _ in pairs(activeTouches) do cnt = cnt + 1 end
    if cnt > peakCount then peakCount = cnt end
end)

UserInputService.TouchEnded:Connect(function(touch)
    activeTouches[touch] = nil
    local remaining = 0
    for _ in pairs(activeTouches) do remaining = remaining + 1 end
    if remaining == 0 then
        if peakCount >= 3 then
            local now = tick()
            if tapCount == 0 or (now - lastTapTime) < 0.8 then
                tapCount    = tapCount + 1
                lastTapTime = now
            end
            task.delay(0.8, function()
                if (tick() - lastTapTime) >= 0.75 then
                    if tapCount == 2 then
                        visible = false
                        Panel.Visible = false
                    elseif tapCount >= 3 then
                        visible = true
                        Panel.Visible = true
                    end
                    tapCount = 0
                end
            end)
        end
        peakCount = 0
    end
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        visible = not visible
        Panel.Visible = visible
    end
end)

print("[VOSS] v16 loaded — Chống rơi map, Tự tránh bẫy chết, Bệ đỡ an toàn!")
