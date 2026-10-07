-- ================================================
-- VOSS | Abyss Expedition v15 (Ultimate Edition)
-- ================================================
-- [FIXES v15]:
-- 1. Hồi sinh tại chỗ chuẩn 100%:
--    - Lưu vị trí mặt đất an toàn (lastGroundPos) & vị trí chết (lastDeathPos)
--    - Rơi xuống vực sâu: tự hồi sinh trên mép đá/nền an toàn trước khi rơi, KHÔNG bị loop chết
--    - Teleport 1 lần dứt khoát + reset vận tốc (0 cà giật)
-- 2. Chống sát thương rơi (No Fall Damage) tích hợp:
--    - Giới hạn tốc độ rơi tối đa, triệt tiêu chấn động khi chạm đất
--    - Không bao giờ chết vì "couldn't survive the descent"
-- 3. Chạy nhanh (Speed Hack) không bao giờ mất:
--    - Hook GetPropertyChangedSignal("WalkSpeed") chặn game reset về 16
--    - Tự phục hồi ngay microsecond đầu tiên sau khi hồi sinh
-- 4. Bay (Fly) mượt mà cả Mobile (cần ảo) & PC (WASD/Space/Ctrl)
-- 5. 1 listener CharacterAdded duy nhất, không xung đột
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

-- Quản lý Nhân Vật
local Char, HRP, Hum
local lastGroundPos      = nil  -- Vị trí đứng trên mặt đất gần nhất
local lastAlivePos       = nil  -- Vị trí sống cuối cùng
local lastExactDeathPos  = nil  -- Vị trí lúc chết
local deathCountAtPos    = 0    -- Đếm số lần chết gần vị trí cũ
local lastDeathCheckTime = 0
local humConns           = {}

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

        -- 2. Bắt khoảnh khắc chết để lưu vị trí chính xác
        local cDied = Hum.Died:Connect(function()
            if HRP then
                lastExactDeathPos = HRP.CFrame
            end
        end)
        table.insert(humConns, cDied)

        -- 3. Chống sốc khi chạm đất (No Fall Damage)
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
        lastAlivePos  = HRP.CFrame
    end
end

-- Hook sự kiện chết của Server game
local deathRemote = findRemoteEvent("DeathEvent")
if deathRemote then
    deathRemote.OnClientEvent:Connect(function()
        if HRP then
            lastExactDeathPos = HRP.CFrame
        end
    end)
end

-- ================================================
-- VÒNG LẶP CHÍNH (HEARTBEAT)
-- ================================================
local ESPCache    = {}
local MOB_FOLDERS = {"Mobs","Enemies","Monsters","Entities","NPCs","Boss","Enemy"}

RunService.Heartbeat:Connect(function()
    -- Cập nhật nhân vật & vị trí
    if HRP and Hum and Hum.Health > 0 then
        -- Lưu vị trí mặt đất khi đang đứng trên sàn (không phải đang rơi trong không khí)
        local floor = Hum.FloorMaterial
        if floor and floor ~= Enum.Material.Air then
            lastGroundPos = HRP.CFrame
        end
        lastAlivePos = HRP.CFrame

        -- Ép tốc độ chạy
        if State.speed and Hum.WalkSpeed ~= CFG.walkspeed then
            pcall(function() Hum.WalkSpeed = CFG.walkspeed end)
        end

        -- Chống sát thương rơi: giới hạn vận tốc rơi tối đa (-28)
        if (State.nofall or State.immortal) then
            local vel = HRP.AssemblyLinearVelocity
            if vel.Y < -28 then
                HRP.AssemblyLinearVelocity = Vector3.new(vel.X, -20, vel.Z)
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
-- SINGLE UNIFIED CHARACTER RESPAWN HANDLER
-- ================================================
LP.CharacterAdded:Connect(function(newChar)
    -- 1. Lưu lại điểm hồi sinh mục tiêu TRƯỚC KHI setup char mới
    local targetCFrame = lastGroundPos or lastExactDeathPos or lastAlivePos
    local now = tick()

    -- Kiểm tra loop chết: nếu chết tại cùng 1 vị trí trong 10 giây
    if targetCFrame and lastExactDeathPos then
        local dist = (targetCFrame.Position - lastExactDeathPos.Position).Magnitude
        if dist < 25 and (now - lastDeathCheckTime) < 10 then
            deathCountAtPos = deathCountAtPos + 1
            if deathCountAtPos >= 2 then
                -- Lùi lại 12 studs an toàn để không spawn trong tầm đánh boss / hố sâu
                targetCFrame = targetCFrame * CFrame.new(0, 4, 12)
            end
        else
            deathCountAtPos = 0
        end
    end
    lastDeathCheckTime = now

    -- 2. Đợi nhân vật spawn & setup
    task.wait(0.2)
    onCharacterSetup(newChar)

    -- 3. Xử lý teleport hồi sinh tại chỗ (nếu Bất Tử bật)
    if State.immortal and targetCFrame and HRP then
        task.wait(0.15)
        if HRP then
            -- Triệt tiêu vận tốc rơi trước khi tele
            HRP.AssemblyLinearVelocity  = Vector3.zero
            HRP.AssemblyAngularVelocity = Vector3.zero
            HRP.CFrame = targetCFrame + Vector3.new(0, 3.5, 0)

            -- Sau 0.35s check lại phòng trường hợp game giật về spawn
            task.delay(0.35, function()
                if State.immortal and HRP and targetCFrame then
                    local currentDist = (HRP.Position - targetCFrame.Position).Magnitude
                    if currentDist > 30 then
                        HRP.AssemblyLinearVelocity = Vector3.zero
                        HRP.CFrame = targetCFrame + Vector3.new(0, 3.5, 0)
                    end
                end
            end)
        end
    end

    -- 4. Khôi phục Speed Hack ngay lập tức
    if State.speed and Hum then
        pcall(function() Hum.WalkSpeed = CFG.walkspeed end)
    end

    -- 5. Khôi phục Fly (nếu đang bật)
    if State.fly then
        task.wait(0.25)
        if startFly then startFly() end
    end
end)

-- ================================================
-- IMMORTAL TOGGLE CALLBACKS
-- ================================================
local function startImmortal()
    if HRP then
        lastGroundPos = HRP.CFrame
        lastAlivePos  = HRP.CFrame
    end
end

local function stopImmortal()
    deathCountAtPos = 0
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
Title.Text               = "VOSS  |  Abyss  v15"
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
makeToggle("☠  Bất Tử (Hồi Sinh Tại Chỗ)", "immortal", startImmortal, stopImmortal)
makeToggle("🪂  Chống Rơi (No Fall)",       "nofall")
makeToggle("⚡  Speed Hack (Không Mất)",     "speed")
makeToggle("🕊  Bay (Cần Ảo Mobile / WASD)","fly", startFly, stopFly)
makeToggle("👁  ESP Quái & Người",           "esp")
makeToggle("⚔  Auto Farm",                  "autofarm", startFarm, stopFarm)
makeAction("📍 Tele → Mob Gần Nhất",        teleportToNearest)

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

print("[VOSS] v15 loaded — Hồi sinh chuẩn xác, Chống rơi No Fall, Speed không mất!")
