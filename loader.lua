-- VOSS | Abyss Expedition v13
-- Fix bất tử hoàn chỉnh:
--   BUG 1: clearImmortalConns() disconnect luôn CharacterAdded → chết lần 2 mất hết
--   BUG 2: Không hook StunOverlayEvent + DebuffStatusEvent → server kill trước khi kịp phản
--   BUG 3: OnClientEvent args sai → check isRagdoll luôn nil
--   BUG 4: Speed/Fly mất sau khi chết
--
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
-- IMMORTAL v13 — COMPLETE REWRITE
-- ================================================
-- Connection pools — tách riêng để không tự disconnect
local eventConns    = {}   -- hook remote events (có thể clear & rehook)
local heartbeatConn = nil  -- heartbeat HP lock
local charAddedConn = nil  -- CharacterAdded — KHÔNG BAO GIỜ clear
local healthConn    = nil  -- HealthChanged signal
local diedConn      = nil  -- Humanoid.Died signal

local savedPos      = nil
local stateEv       = nil
local deathEv       = nil

-- clear CHỈ event connections, KHÔNG clear CharacterAdded
local function clearEventConns()
    for _, c in pairs(eventConns) do
        pcall(function() c:Disconnect() end)
    end
    eventConns = {}
end

local function clearHeartbeat()
    if heartbeatConn then
        pcall(function() heartbeatConn:Disconnect() end)
        heartbeatConn = nil
    end
end

local function clearHealthHooks()
    if healthConn then
        pcall(function() healthConn:Disconnect() end)
        healthConn = nil
    end
    if diedConn then
        pcall(function() diedConn:Disconnect() end)
        diedConn = nil
    end
end

local function lockHP()
    if not Hum then return end
    pcall(function()
        Hum.MaxHealth = math.huge
        Hum.Health    = math.huge
    end)
end

local function applyImmortalProps()
    if not Hum then return end
    pcall(function()
        Hum.MaxHealth          = math.huge
        Hum.Health             = math.huge
        Hum.BreakJointsOnDeath = false
        Hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
        Hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        Hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    end)
end

local function fireAlive()
    -- fire StateUpdateEvent lên server với isAlive = true
    -- thử nhiều format vì không biết server expect gì
    if stateEv then
        pcall(function() stateEv:FireServer({isAlive = true}) end)
        pcall(function() stateEv:FireServer({isAlive = true, isNormal = true}) end)
    end
    -- reset HP client-side ngay
    lockHP()
end

-- Forward declare startFly (dùng ở CharacterAdded)
local startFly

local function hookEvents()
    clearEventConns()  -- clear cũ trước khi hook mới

    -- tìm remotes
    stateEv  = findRemoteEvent("StateUpdateEvent")
    deathEv  = findRemoteEvent("DeathEvent")
    local stunEv   = findRemoteEvent("StunOverlayEvent")
    local debuffEv = findRemoteEvent("DebuffStatusEvent")
    local dmgFb    = findRemoteEvent("DamageFeedback")

    -- ===== HOOK 1: StateUpdateEvent =====
    -- Scanner cho thấy: OnClientEvent fire (playerName, tableData)
    -- Roblox OnClientEvent KHÔNG gửi player arg → arg1 = playerName, arg2 = tableData
    if stateEv then
        local c = stateEv.OnClientEvent:Connect(function(...)
            if not State.immortal then return end
            local args = {...}

            -- parse data: có thể là (string, table) hoặc (table)
            local data = nil
            for _, a in ipairs(args) do
                if type(a) == "table" then
                    data = a
                    break
                end
            end

            if data then
                -- nếu có isRagdoll = bắt đầu chuỗi chết → chặn ngay
                if data.isRagdoll then
                    task.defer(fireAlive)
                    task.delay(0.05, fireAlive)
                    task.delay(0.1, fireAlive)
                end
                -- nếu data chứa bất kỳ field nào liên quan death
                if data.isDead or data.isKilled then
                    task.defer(fireAlive)
                    task.delay(0.05, fireAlive)
                end
            end

            -- LUÔN reset HP sau mỗi StateUpdateEvent
            task.defer(lockHP)
        end)
        table.insert(eventConns, c)
    end

    -- ===== HOOK 2: DeathEvent =====
    if deathEv then
        local c = deathEv.OnClientEvent:Connect(function(...)
            if not State.immortal then return end
            -- fire alive liên tục
            for i = 0, 4 do
                task.delay(i * 0.05, fireAlive)
            end
        end)
        table.insert(eventConns, c)
    end

    -- ===== HOOK 3: StunOverlayEvent — CÁI NÀY QUAN TRỌNG =====
    -- Scanner: StunOverlayEvent | true → fire TRƯỚC khi chết
    -- Nếu bị stun → sắp chết → fire alive ngay
    if stunEv then
        local c = stunEv.OnClientEvent:Connect(function(...)
            if not State.immortal then return end
            -- stun = sắp chết → counter ngay
            task.defer(fireAlive)
            task.delay(0.05, fireAlive)
            task.delay(0.15, fireAlive)
            -- cố gắng unstun
            pcall(function()
                if Hum then
                    Hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                end
            end)
        end)
        table.insert(eventConns, c)
    end

    -- ===== HOOK 4: DebuffStatusEvent =====
    -- Scanner: DebuffStatusEvent | INJURED → damage incoming
    if debuffEv then
        local c = debuffEv.OnClientEvent:Connect(function(...)
            if not State.immortal then return end
            local args = {...}
            for _, a in ipairs(args) do
                if type(a) == "string" and (a == "INJURED" or a:find("DEAD") or a:find("KILL")) then
                    task.defer(fireAlive)
                    task.delay(0.05, fireAlive)
                    break
                end
            end
            task.defer(lockHP)
        end)
        table.insert(eventConns, c)
    end

    -- ===== HOOK 5: DamageFeedback =====
    if dmgFb then
        local c = dmgFb.OnClientEvent:Connect(function(...)
            if not State.immortal then return end
            task.defer(lockHP)
        end)
        table.insert(eventConns, c)
    end
end

local function hookHumanoidSignals()
    clearHealthHooks()
    if not Hum then return end

    -- HealthChanged: bất cứ khi nào HP giảm → lock lại ngay
    healthConn = Hum.HealthChanged:Connect(function(newHP)
        if not State.immortal then return end
        if newHP < math.huge then
            task.defer(function()
                lockHP()
                fireAlive()
            end)
        end
    end)

    -- Died: nếu bằng cách nào đó vẫn chết → fire alive
    diedConn = Hum.Died:Connect(function()
        if not State.immortal then return end
        for i = 0, 6 do
            task.delay(i * 0.05, fireAlive)
        end
    end)
end

local function startHeartbeat()
    clearHeartbeat()
    heartbeatConn = RunService.Heartbeat:Connect(function()
        if not State.immortal then return end
        -- save position (khi đang đứng yên/di chuyển nhẹ)
        if HRP then
            local vel = HRP.AssemblyLinearVelocity
            if math.abs(vel.Y) < 4 and vel.Magnitude < 10 then
                savedPos = HRP.CFrame
            end
        end
        -- HP lock liên tục
        if Hum then
            pcall(function()
                if Hum.Health < math.huge then
                    Hum.MaxHealth = math.huge
                    Hum.Health    = math.huge
                end
            end)
        end
    end)
end

local function startImmortal()
    -- apply props
    applyImmortalProps()

    -- hook remote events
    hookEvents()

    -- hook humanoid signals
    hookHumanoidSignals()

    -- start heartbeat
    startHeartbeat()

    -- CharacterAdded — CHỈ TẠO 1 LẦN, KHÔNG bỏ vào pool có thể clear
    if charAddedConn then
        pcall(function() charAddedConn:Disconnect() end)
        charAddedConn = nil
    end

    charAddedConn = LP.CharacterAdded:Connect(function(c)
        if not State.immortal then
            refreshChar(c)
            return
        end

        local retPos = savedPos
        task.wait(0.1)
        refreshChar(c)

        -- apply props ngay cho char mới
        applyImmortalProps()

        -- teleport về vị trí cũ
        if retPos then
            for i = 1, 8 do
                task.wait(0.05)
                if HRP then HRP.CFrame = retPos end
            end
        end

        -- rehook events cho char mới (KHÔNG clear CharacterAdded)
        hookEvents()

        -- rehook humanoid signals cho Hum mới
        hookHumanoidSignals()

        -- restart heartbeat
        startHeartbeat()

        -- restore speed
        if State.speed and Hum then
            pcall(function() Hum.WalkSpeed = CFG.walkspeed end)
        end

        -- restore fly
        if State.fly then
            task.wait(0.2)
            if startFly then startFly() end
        end
    end)
end

local function stopImmortal()
    -- clear event hooks
    clearEventConns()
    clearHeartbeat()
    clearHealthHooks()

    -- disconnect CharacterAdded
    if charAddedConn then
        pcall(function() charAddedConn:Disconnect() end)
        charAddedConn = nil
    end

    -- reset HP về bình thường
    if Hum then
        pcall(function()
            Hum.MaxHealth = 100
            Hum.Health    = 100
            Hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
            Hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
            Hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
        end)
    end
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

local function stopFly()
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

-- Assign to the forward-declared local
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
    if State.immortal then return end  -- immortal có hook riêng
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
Title.Text               = "VOSS  |  Abyss  v13"
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

makeToggle("☠  Bất Tử",               "immortal", startImmortal, stopImmortal)
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

print("[VOSS] v13 loaded — full event intercept: StateUpdate + Death + Stun + Debuff")
