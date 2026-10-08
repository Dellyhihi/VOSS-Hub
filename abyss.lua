-- ================================================
-- VOSS | Abyss Expedition v17 (Ultimate Fix)
-- ================================================
-- [FIXES v17]:
-- 1. HỒI SINH CHUẨN XÁC 100% VỀ ĐÚNG CHỖ CŨ:
--    - Bỏ toàn bộ blacklist/raycast phức tạp làm sai tọa độ về spawn
--    - Lưu liên tục vị trí đứng an toàn (lastSafePos) & vị trí di chuyển (lastMovePos)
--    - Rơi vực thẳm: tự hồi sinh ở mép bờ an toàn trước khi ngã
--    - Chết do quái: tự động hồi sinh lùi 8 studs an toàn tránh bị quái đánh tiếp
--    - Có cơ chế 6-step confirmation để đè bẹp script kéo về spawn của game
--    - Tặng 2.5 giây Khiên Bất Tử (Ghost Shield) ngay sau khi đáp để kịp phản xạ
-- 2. BAY (FLY) DI CHUYỂN LÊN/XUỐNG TRIỆT ĐỂ:
--    - Bay 3D theo hướng nhìn camera (cúi camera xuống đẩy cần = bay chúc xuống đáy vực)
--    - Tự động tạo 2 NÚT CẢM ỨNG trên màn hình Mobile: [▲ Lên] và [▼ Xuống]
--    - Bấm giữ [▼] trên màn hình là bay thẳng xuống dưới siêu mượt
--    - PC: W/S/A/D + Space (lên) + Ctrl/C (xuống)
-- 3. TỐC ĐỘ CHẠY (SPEED HACK) KHÔNG BAO GIỜ MẤT:
--    - Hook GetPropertyChangedSignal("WalkSpeed")
-- 4. CHỐNG SÁT THƯƠNG RƠI (NO FALL DAMAGE) VĨNH VIỄN
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

-- Quản lý Nhân Vật & Vị Trí
local Char, HRP, Hum
local lastSafePos   = nil -- Vị trí an toàn khi đang đứng/đi bình thường (vel.Y nhỏ)
local lastMovePos   = nil -- Vị trí cuối cùng khi còn sống
local humConns      = {}
local isRespawning  = false

local function clearHumConns()
    for _, c in pairs(humConns) do
        pcall(function() c:Disconnect() end)
    end
    humConns = {}
end

-- ================================================
-- HỆ THỐNG XỬ LÝ NHÂN VẬT & TỐC ĐỘ
-- ================================================
local function onCharacterSetup(newChar)
    Char = newChar
    HRP  = newChar:WaitForChild("HumanoidRootPart", 10)
    Hum  = newChar:WaitForChild("Humanoid", 10)

    clearHumConns()

    if Hum then
        -- 1. Chống vỡ khớp khi chết client
        pcall(function()
            Hum.BreakJointsOnDeath = false
        end)

        -- 2. Khóa tốc độ chạy chống game reset về 16
        local cSpeed = Hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
            if State.speed and Hum.WalkSpeed ~= CFG.walkspeed then
                pcall(function() Hum.WalkSpeed = CFG.walkspeed end)
            end
        end)
        table.insert(humConns, cSpeed)

        if State.speed then
            pcall(function() Hum.WalkSpeed = CFG.walkspeed end)
        end

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
        lastSafePos = HRP.CFrame
        lastMovePos = HRP.CFrame
    end
end

-- ================================================
-- VÒNG LẶP THEO DÕI VỊ TRÍ & HỖ TRỢ VẬT LÝ (HEARTBEAT)
-- ================================================
local ESPCache    = {}
local MOB_FOLDERS = {"Mobs","Enemies","Monsters","Entities","NPCs","Boss","Enemy"}

RunService.Heartbeat:Connect(function()
    if HRP and Hum and Hum.Health > 0 and not isRespawning then
        local vel = HRP.AssemblyLinearVelocity
        lastMovePos = HRP.CFrame

        -- Nếu vận tốc Y bình thường (không phải đang lao đầu xuống vực)
        -- Thì đây là vị trí đứng/đi an toàn thực sự
        if math.abs(vel.Y) < 16 then
            lastSafePos = HRP.CFrame
        end

        -- Duy trì tốc độ chạy
        if State.speed and Hum.WalkSpeed ~= CFG.walkspeed then
            pcall(function() Hum.WalkSpeed = CFG.walkspeed end)
        end

        -- Chống sát thương rơi: kìm hãm tốc độ rơi tự do
        if (State.nofall or State.immortal) then
            if vel.Y < -24 then
                HRP.AssemblyLinearVelocity = Vector3.new(vel.X, -16, vel.Z)
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

-- Forward declaration
local startFly, stopFly

-- ================================================
-- HỒI SINH TẠI CHỖ CHUẨN XÁC 100% (v17)
-- ================================================
LP.CharacterAdded:Connect(function(newChar)
    -- Lấy vị trí an toàn trước khi chết (ưu tiên lastSafePos trên bờ, fallback sang lastMovePos)
    local targetPos = lastSafePos or lastMovePos

    isRespawning = true
    task.wait(0.2)
    onCharacterSetup(newChar)

    if State.immortal and targetPos and HRP then
        -- Lùi lại 6 studs theo hướng mặt để không spawn dính sát hitbox quái/boss
        local spawnCFrame = targetPos * CFrame.new(0, 3.5, 6)

        -- 1. Cho game tải map vùng đích
        pcall(function()
            LP:RequestStreamAroundAsync(spawnCFrame.Position)
        end)

        -- 2. Tạm thời khóa Dead state trong 2 giây đầu để tránh bị game quét chết oan
        if Hum then
            pcall(function()
                Hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
                Hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            end)
        end

        -- 3. Đưa về vị trí cũ và xác nhận lặp 5 lần ngắn để đánh bại script kéo về spawn của game
        for step = 1, 6 do
            if HRP and State.immortal then
                HRP.AssemblyLinearVelocity  = Vector3.zero
                HRP.AssemblyAngularVelocity = Vector3.zero
                HRP.CFrame = spawnCFrame
            end
            task.wait(0.08)
        end

        -- 4. Mở lại Dead state sau 2 giây an toàn
        task.delay(2.0, function()
            if Hum then
                pcall(function()
                    Hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
                end)
            end
            isRespawning = false
        end)
    else
        isRespawning = false
    end

    -- Khôi phục Speed Hack
    if State.speed and Hum then
        pcall(function() Hum.WalkSpeed = CFG.walkspeed end)
    end

    -- Khôi phục Fly
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
        lastSafePos = HRP.CFrame
        lastMovePos = HRP.CFrame
    end
end

local function stopImmortal()
    isRespawning = false
end

-- ================================================
-- FLY (HỖ TRỢ BAY LÊN / BAY XUỐNG TRIỆT ĐỂ CHO CẢ MOBILE & PC)
-- ================================================
local flyConn     = nil
local flyObjects  = {}
local mobileFlyGui = nil
local mobileUpDown = 0 -- -1: xuống, 1: lên, 0: không bấm

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
    if mobileFlyGui then
        pcall(function() mobileFlyGui:Destroy() end)
        mobileFlyGui = nil
    end
    mobileUpDown = 0
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

-- Tạo 2 nút cảm ứng LÊN / XUỐNG trên màn hình khi bật Fly
local function createMobileFlyButtons()
    if mobileFlyGui then return end
    local coreGui = game:GetService("CoreGui")

    local mGui = Instance.new("ScreenGui")
    mGui.Name           = "VOSS_FlyControls"
    mGui.ResetOnSpawn   = false
    mGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    mGui.Parent         = coreGui
    mobileFlyGui        = mGui

    local container = Instance.new("Frame", mGui)
    container.Size             = UDim2.new(0, 65, 0, 140)
    container.Position         = UDim2.new(1, -85, 0.5, -70)
    container.BackgroundTransparency = 1

    -- Nút Bay Lên [▲]
    local btnUp = Instance.new("TextButton", container)
    btnUp.Name             = "BtnUp"
    btnUp.Size             = UDim2.new(0, 60, 0, 60)
    btnUp.Position         = UDim2.new(0, 0, 0, 0)
    btnUp.BackgroundColor3 = Color3.fromRGB(45, 25, 95)
    btnUp.Text             = "▲\nLÊN"
    btnUp.TextColor3       = Color3.fromRGB(220, 180, 255)
    btnUp.Font             = Enum.Font.GothamBold
    btnUp.TextSize         = 13
    btnUp.AutoButtonColor  = false
    Instance.new("UICorner", btnUp).CornerRadius = UDim.new(0, 12)
    local sUp = Instance.new("UIStroke", btnUp)
    sUp.Color = Color3.fromRGB(130, 80, 255); sUp.Thickness = 1.5

    -- Nút Bay Xuống [▼]
    local btnDown = Instance.new("TextButton", container)
    btnDown.Name             = "BtnDown"
    btnDown.Size             = UDim2.new(0, 60, 0, 60)
    btnDown.Position         = UDim2.new(0, 0, 0, 75)
    btnDown.BackgroundColor3 = Color3.fromRGB(45, 25, 95)
    btnDown.Text             = "▼\nXUỐNG"
    btnDown.TextColor3       = Color3.fromRGB(220, 180, 255)
    btnDown.Font             = Enum.Font.GothamBold
    btnDown.TextSize         = 13
    btnDown.AutoButtonColor  = false
    Instance.new("UICorner", btnDown).CornerRadius = UDim.new(0, 12)
    local sDown = Instance.new("UIStroke", btnDown)
    sDown.Color = Color3.fromRGB(130, 80, 255); sDown.Thickness = 1.5

    -- Sự kiện chạm/giữ nút Lên
    btnUp.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            mobileUpDown = 1
            btnUp.BackgroundColor3 = Color3.fromRGB(90, 50, 190)
        end
    end)
    btnUp.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            if mobileUpDown == 1 then mobileUpDown = 0 end
            btnUp.BackgroundColor3 = Color3.fromRGB(45, 25, 95)
        end
    end)

    -- Sự kiện chạm/giữ nút Xuống
    btnDown.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            mobileUpDown = -1
            btnDown.BackgroundColor3 = Color3.fromRGB(90, 50, 190)
        end
    end)
    btnDown.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            if mobileUpDown == -1 then mobileUpDown = 0 end
            btnDown.BackgroundColor3 = Color3.fromRGB(45, 25, 95)
        end
    end)
end

-- Tính toán hướng bay 3D chuẩn xác
local function getFlyDirection()
    local dir   = Vector3.zero
    local camCF = Cam.CFrame
    local uis   = UserInputService

    -- 1. ƯU TIÊN HỖ TRỢ MOBILE CẦN GẠT ẢO & HƯỚNG NHÌN CAMERA:
    if Hum and Hum.MoveDirection.Magnitude > 0 then
        local look  = camCF.LookVector
        local right = camCF.RightVector

        -- Tính thành phần tiến/lùi và sang trái/phải dựa theo cần gạt
        local flatLook  = Vector3.new(look.X, 0, look.Z).Unit
        local flatRight = Vector3.new(right.X, 0, right.Z).Unit

        local fDot = Hum.MoveDirection:Dot(flatLook)
        local rDot = Hum.MoveDirection:Dot(flatRight)

        -- Bay 3D theo hướng camera: nhìn xuống đẩy tới = bay cắm xuống đáy vực!
        dir = (look * fDot) + (right * rDot)
    else
        -- 2. HỖ TRỢ BÀN PHÍM PC (W/S/A/D)
        local moveZ, moveX = 0, 0
        if uis:IsKeyDown(Enum.KeyCode.W) then moveZ = moveZ + 1 end
        if uis:IsKeyDown(Enum.KeyCode.S) then moveZ = moveZ - 1 end
        if uis:IsKeyDown(Enum.KeyCode.A) then moveX = moveX - 1 end
        if uis:IsKeyDown(Enum.KeyCode.D) then moveX = moveX + 1 end

        dir = (camCF.LookVector * moveZ) + (camCF.RightVector * moveX)
    end

    -- 3. TÍNH NĂNG BAY LÊN / BAY XUỐNG ĐỘC LẬP:
    -- Trên Mobile: Dùng nút cảm ứng [▲ Lên] và [▼ Xuống]
    if mobileUpDown == 1 then
        dir = dir + Vector3.new(0, 1, 0)
    elseif mobileUpDown == -1 then
        dir = dir + Vector3.new(0, -1, 0)
    end

    -- Trên PC: Dùng Space (lên) và LeftControl / C (xuống)
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

    -- Tạo nút điều khiển lên/xuống cho Mobile
    createMobileFlyButtons()

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
Title.Text               = "VOSS  |  Abyss  v17"
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
makeToggle("☠  Bất Tử (Hồi Sinh Đúng Chỗ)", "immortal", startImmortal, stopImmortal)
makeToggle("🪂  Chống Rơi (No Fall)",         "nofall")
makeToggle("⚡  Speed Hack (Không Mất)",       "speed")
makeToggle("🕊  Bay (3D Cam + Nút Lên/Xuống)","fly", startFly, stopFly)
makeToggle("👁  ESP Quái & Người",             "esp")
makeToggle("⚔  Auto Farm",                    "autofarm", startFarm, stopFarm)
makeAction("📍 Tele → Mob Gần Nhất",          teleportToNearest)

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

print("[VOSS] v17 loaded — Hồi sinh đúng chỗ cũ 100%, Bay 3D có nút Lên/Xuống trên màn hình!")
