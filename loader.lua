-- VOSS | Abyss Expedition v14
-- Bất tử kiểu mới: chết → hồi sinh ngay → teleport về chỗ chết
-- Không hack HP, không chống server → KHÔNG bị giật
-- 3 ngón x2 = ẩn | 3 ngón x3 = hiện | RShift PC

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local LP                = Players.LocalPlayer
local Cam               = workspace.CurrentCamera

local Char, HRP, Hum
local function refreshChar(c)
    Char = c
    HRP  = c:WaitForChild("HumanoidRootPart", 10)
    Hum  = c:WaitForChild("Humanoid", 10)
end
refreshChar(LP.Character or LP.CharacterAdded:Wait())

local State = {
    immortal = false,
    esp      = false,
    autofarm = false,
    speed    = false,
    fly      = false,
}
local CFG = { walkspeed = 70, flyspeed = 55 }

-- ================================================
-- UTILS
-- ================================================
local function findRemote(name)
    for _, v in pairs(game:GetDescendants()) do
        if (v:IsA("RemoteEvent") or v:IsA("RemoteFunction"))
        and v.Name == name then
            return v
        end
    end
end

local function findRemoteEvent(name)
    for _, v in pairs(game:GetDescendants()) do
        if v:IsA("RemoteEvent") and v.Name == name then
            return v
        end
    end
end

-- ================================================
-- IMMORTAL v14 — INSTANT RESPAWN AT DEATH POS
-- Cách hoạt động:
--   1) Lưu vị trí liên tục (chỉ khi đang đứng/đi bình thường)
--   2) Khi chết → game tự hồi sinh
--   3) Hồi sinh xong → teleport về vị trí lưu cuối cùng
--   4) Không hack HP, không chống server → 0 giật
-- ================================================
local savedPos       = nil
local immortalActive = false
local posConn        = nil  -- heartbeat lưu vị trí
local charConn       = nil  -- CharacterAdded hook

-- Forward declare
local startFly, stopFly

local function startImmortal()
    immortalActive = true

    -- Lưu vị trí hiện tại ngay
    if HRP then savedPos = HRP.CFrame end

    -- Heartbeat: lưu vị trí liên tục
    if posConn then pcall(function() posConn:Disconnect() end) end
    posConn = RunService.Heartbeat:Connect(function()
        if not State.immortal then return end
        if not HRP then return end
        -- Chỉ lưu khi đang đứng/đi bình thường (không rơi, không bay nhanh)
        local vel = HRP.AssemblyLinearVelocity
        if math.abs(vel.Y) < 8 then
            savedPos = HRP.CFrame
        end
    end)

    -- CharacterAdded: hồi sinh xong → teleport về chỗ chết
    if charConn then pcall(function() charConn:Disconnect() end) end
    charConn = LP.CharacterAdded:Connect(function(c)
        if not State.immortal then
            refreshChar(c)
            return
        end

        local retPos = savedPos  -- lấy vị trí trước khi chết

        -- Đợi char load xong hoàn toàn
        task.wait(0.3)
        refreshChar(c)

        -- Đợi thêm chút cho game xử lý xong spawn
        task.wait(0.2)

        -- Teleport về chỗ chết — 1 lần duy nhất, không loop giật
        if retPos and HRP then
            -- Đợi HRP stable
            task.wait(0.1)
            HRP.CFrame = retPos

            -- Backup: check lại sau 0.3s nếu bị game kéo về spawn
            task.delay(0.3, function()
                if State.immortal and HRP and retPos then
                    local dist = (HRP.Position - retPos.Position).Magnitude
                    if dist > 20 then
                        -- Game đã kéo về spawn → teleport lại
                        HRP.CFrame = retPos
                    end
                end
            end)

            -- Backup 2: check lần nữa
            task.delay(0.8, function()
                if State.immortal and HRP and retPos then
                    local dist = (HRP.Position - retPos.Position).Magnitude
                    if dist > 20 then
                        HRP.CFrame = retPos
                    end
                end
            end)
        end

        -- Restore speed
        if State.speed and Hum then
            pcall(function() Hum.WalkSpeed = CFG.walkspeed end)
        end

        -- Restore fly
        if State.fly then
            task.wait(0.3)
            if startFly then startFly() end
        end
    end)
end

local function stopImmortal()
    immortalActive = false
    if posConn then pcall(function() posConn:Disconnect() end); posConn = nil end
    if charConn then pcall(function() charConn:Disconnect() end); charConn = nil end
    savedPos = nil
end

-- ================================================
-- FLY
-- ================================================
local flyConn    = nil
local flyObjects = {}
local flyMode    = nil

local function cleanFlyObjects()
    for _, obj in pairs(flyObjects) do
        pcall(function() obj:Destroy() end)
    end
    flyObjects = {}
    if HRP then
        for _, n in pairs({"VOSS_BV","VOSS_BG","VOSS_LV","VOSS_AT"}) do
            local o = HRP:FindFirstChild(n)
            if o then pcall(function() o:Destroy() end) end
        end
    end
end

stopFly = function()
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    cleanFlyObjects()
    flyMode = nil
    if Hum then
        pcall(function()
            Hum.PlatformStand = false
            Hum.AutoRotate    = true
        end)
    end
end

local function getFlyDir()
    local cf  = Cam.CFrame
    local dir = Vector3.zero
    local uis = UserInputService
    if uis:IsKeyDown(Enum.KeyCode.W) then
        dir += Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
    end
    if uis:IsKeyDown(Enum.KeyCode.S) then
        dir -= Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
    end
    if uis:IsKeyDown(Enum.KeyCode.A) then
        dir -= Vector3.new(cf.RightVector.X, 0, cf.RightVector.Z)
    end
    if uis:IsKeyDown(Enum.KeyCode.D) then
        dir += Vector3.new(cf.RightVector.X, 0, cf.RightVector.Z)
    end
    if uis:IsKeyDown(Enum.KeyCode.Space) then
        dir += Vector3.new(0,1,0)
    end
    if uis:IsKeyDown(Enum.KeyCode.LeftControl)
    or uis:IsKeyDown(Enum.KeyCode.C) then
        dir += Vector3.new(0,-1,0)
    end
    return dir
end

local function updateGyro()
    if not HRP then return end
    local bg = HRP:FindFirstChild("VOSS_BG")
    if not bg then return end
    local look = Vector3.new(Cam.CFrame.LookVector.X, 0, Cam.CFrame.LookVector.Z)
    if look.Magnitude > 0.01 then
        bg.CFrame = CFrame.new(HRP.Position, HRP.Position + look)
    end
end

local function startFly_BV()
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
        if not State.fly or not HRP then stopFly(); return end
        local bv2 = HRP:FindFirstChild("VOSS_BV")
        if not bv2 then stopFly(); return end
        local dir = getFlyDir()
        bv2.Velocity = dir.Magnitude > 0
            and dir.Unit * CFG.flyspeed
            or  Vector3.zero
        updateGyro()
    end)
    flyMode = "BV"
end

startFly = function()
    stopFly()
    task.wait(0.05)
    startFly_BV()
end

-- ================================================
-- ESP
-- ================================================
local ESPCache    = {}
local MOB_FOLDERS = {"Mobs","Enemies","Monsters","Entities","NPCs","Boss","Enemy"}

local function clearESP()
    for k, v in pairs(ESPCache) do
        pcall(function() v:Destroy() end)
        ESPCache[k] = nil
    end
end

local function makeTag(adornee, text, color)
    local bb = Instance.new("BillboardGui")
    bb.AlwaysOnTop = true
    bb.Size        = UDim2.new(0,130,0,26)
    bb.StudsOffset = Vector3.new(0,3.5,0)
    bb.Adornee     = adornee
    bb.Parent      = adornee
    local lbl = Instance.new("TextLabel", bb)
    lbl.Size                   = UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3             = color
    lbl.TextStrokeTransparency = 0
    lbl.Font                   = Enum.Font.GothamBold
    lbl.TextScaled             = true
    lbl.Text                   = text
    return bb
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
    if mh then HRP.CFrame = mh.CFrame + Vector3.new(4,0,0) end
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
        HRP.CFrame = mh.CFrame + Vector3.new(3,0,0)
        for _, r in pairs(remotes) do
            pcall(function()
                if r:IsA("RemoteEvent") then r:FireServer(mob, mh.Position)
                else r:InvokeServer(mob, mh.Position) end
            end)
        end
    end)
end

local function stopFarm()
    if farmConn then farmConn:Disconnect(); farmConn = nil end
end

-- ================================================
-- MAIN LOOP
-- ================================================
RunService.Heartbeat:Connect(function()
    if Hum then
        pcall(function()
            Hum.WalkSpeed = State.speed and CFG.walkspeed or 16
        end)
    end

    if not State.esp then
        if next(ESPCache) then clearESP() end
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
                        ESPCache[key] = makeTag(mh, mob.Name, Color3.fromRGB(255,70,70))
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
                    ESPCache[key] = makeTag(ph, p.Name, Color3.fromRGB(80,255,80))
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
-- RESPAWN (non-immortal)
-- ================================================
LP.CharacterAdded:Connect(function(c)
    if State.immortal then return end
    task.wait(0.6)
    refreshChar(c)
    if State.speed and Hum then
        pcall(function() Hum.WalkSpeed = CFG.walkspeed end)
    end
    if State.fly then
        task.wait(0.3)
        startFly()
    end
end)

-- ================================================
-- GUI
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
Panel.Size             = UDim2.new(0,260,0,540)
Panel.Position         = UDim2.new(0,20,0.5,-270)
Panel.BackgroundColor3 = Color3.fromRGB(10,10,16)
Panel.BorderSizePixel  = 0
Panel.Active           = true
Panel.Draggable        = true
Instance.new("UICorner", Panel).CornerRadius = UDim.new(0,12)

local sk = Instance.new("UIStroke", Panel)
sk.Color = Color3.fromRGB(90,50,210); sk.Thickness = 1.5

local Title = Instance.new("TextLabel", Panel)
Title.Size               = UDim2.new(1,0,0,42)
Title.BackgroundTransparency = 1
Title.Text               = "VOSS  |  Abyss  v14"
Title.TextColor3         = Color3.fromRGB(155,100,255)
Title.Font               = Enum.Font.GothamBold
Title.TextSize           = 17

local Hint = Instance.new("TextLabel", Panel)
Hint.Size                = UDim2.new(1,0,0,16)
Hint.Position            = UDim2.new(0,0,0,42)
Hint.BackgroundTransparency = 1
Hint.Text                = "3 ngón×2 ẩn  |  3 ngón×3 hiện  |  RShift PC"
Hint.TextColor3          = Color3.fromRGB(85,85,125)
Hint.Font                = Enum.Font.Gotham
Hint.TextSize            = 10

local Div = Instance.new("Frame", Panel)
Div.Size             = UDim2.new(0.85,0,0,1)
Div.Position         = UDim2.new(0.075,0,0,62)
Div.BackgroundColor3 = Color3.fromRGB(70,45,140)
Div.BorderSizePixel  = 0

local btnY = 70

local function makeToggle(label, key, onEnable, onDisable)
    local frame = Instance.new("Frame", Panel)
    frame.Size             = UDim2.new(0.88,0,0,44)
    frame.Position         = UDim2.new(0.06,0,0,btnY)
    frame.BackgroundColor3 = Color3.fromRGB(20,20,30)
    frame.BorderSizePixel  = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0,8)
    btnY = btnY + 52

    local lbl = Instance.new("TextLabel", frame)
    lbl.Size               = UDim2.new(0.65,0,1,0)
    lbl.Position           = UDim2.new(0.05,0,0,0)
    lbl.BackgroundTransparency = 1
    lbl.Text               = label
    lbl.TextColor3         = Color3.fromRGB(200,195,220)
    lbl.Font               = Enum.Font.GothamSemibold
    lbl.TextSize           = 13
    lbl.TextXAlignment     = Enum.TextXAlignment.Left

    local pill = Instance.new("Frame", frame)
    pill.Size             = UDim2.new(0,44,0,22)
    pill.Position         = UDim2.new(1,-52,0.5,-11)
    pill.BackgroundColor3 = Color3.fromRGB(35,35,50)
    pill.BorderSizePixel  = 0
    Instance.new("UICorner", pill).CornerRadius = UDim.new(1,0)

    local dot = Instance.new("Frame", pill)
    dot.Size             = UDim2.new(0,18,0,18)
    dot.Position         = UDim2.new(0,2,0.5,-9)
    dot.BackgroundColor3 = Color3.fromRGB(90,70,160)
    dot.BorderSizePixel  = 0
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1,0)

    local btn = Instance.new("TextButton", frame)
    btn.Size               = UDim2.new(1,0,1,0)
    btn.BackgroundTransparency = 1
    btn.Text               = ""

    local function refresh()
        local on = State[key]
        TweenService:Create(pill, TweenInfo.new(0.14), {
            BackgroundColor3 = on
                and Color3.fromRGB(75,45,195)
                or  Color3.fromRGB(35,35,50)
        }):Play()
        TweenService:Create(dot, TweenInfo.new(0.14), {
            Position = on
                and UDim2.new(0,24,0.5,-9)
                or  UDim2.new(0,2,0.5,-9),
            BackgroundColor3 = on
                and Color3.fromRGB(195,160,255)
                or  Color3.fromRGB(90,70,160)
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
    frame.Size             = UDim2.new(0.88,0,0,44)
    frame.Position         = UDim2.new(0.06,0,0,btnY)
    frame.BackgroundColor3 = Color3.fromRGB(30,15,50)
    frame.BorderSizePixel  = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0,8)
    btnY = btnY + 52
    local sk2 = Instance.new("UIStroke", frame)
    sk2.Color = Color3.fromRGB(120,60,255); sk2.Thickness = 1
    local btn = Instance.new("TextButton", frame)
    btn.Size               = UDim2.new(1,0,1,0)
    btn.BackgroundTransparency = 1
    btn.Text               = label
    btn.TextColor3         = Color3.fromRGB(200,160,255)
    btn.Font               = Enum.Font.GothamSemibold
    btn.TextSize           = 13
    btn.MouseButton1Click:Connect(callback)
end

makeToggle("☠  Bất Tử (Hồi Sinh)",    "immortal", startImmortal, stopImmortal)
makeToggle("👁  ESP",                  "esp")
makeToggle("⚔  Auto Farm",             "autofarm", startFarm, stopFarm)
makeToggle("⚡  Speed Hack",            "speed")
makeToggle("🕊  Bay (W/S/A/D Space/C)","fly", startFly, stopFly)
makeAction("📍 Tele → Mob Gần Nhất",   teleportToNearest)

-- ================================================
-- GESTURE — 3 ngón tay
-- ================================================
local visible       = true
local tapCount      = 0
local lastTapTime   = 0
local activeTouches = {}
local peakCount     = 0

UserInputService.TouchStarted:Connect(function(touch, gpe)
    activeTouches[touch] = true
    local cnt = 0
    for _ in pairs(activeTouches) do cnt = cnt + 1 end
    if cnt > peakCount then peakCount = cnt end
end)

UserInputService.TouchEnded:Connect(function(touch, gpe)
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

print("[VOSS] v14 loaded — chết → hồi sinh ngay tại chỗ chết")
