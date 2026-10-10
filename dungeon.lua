-- ================================================
-- VOSS | Dungeon Hunters Hub v4.0 (Full AFK Loop Edition)
-- Game: Thợ Săn Hầm Ngục [UPD] - The Evac Syndicate
-- ================================================
-- [TỰ ĐỘNG TREO MÁY 100% - KHÔNG CẦN CHẠM TAY]:
-- 1. CHẾ ĐỘ TREO MÁY TOÀN DIỆN (FULL AFK LOOP):
--    - Chỉ cần gạt 1 công tắc duy nhất: Bot tự lo từ A đến Z!
--    - Ở Sảnh (Lobby): Tự đi bộ đến cổng hầm ngục -> Mở bảng -> Chọn Cấp (1, 2, 3.. hoặc AUTO) -> Tự bấm Bắt đầu
--    - Trong Hầm Ngục (Dungeon): Đứng đất chém quái sau lưng trúng 100% -> Hết quái tự nhặt rương -> Tự đi qua cửa tiếp theo -> Diệt Boss
--    - Hết trận: Tự bấm Replay / Tiếp tục -> Nếu về lại sảnh thì TỰ ĐỘNG VÀO TIẾP VÒNG LẶP MỚI VÔ TẬN!
-- 2. ĐI BỘ THỰC THỤ & CHỐNG KẸT (SMART GROUND PATHING):
--    - Tự đi bộ (Hum:MoveTo) mượt mà trên mặt đất.
--    - Nếu gặp vật cản/hàng rào: Tự động nhảy (Jump) và lướt mượt mà vượt chướng ngại vật đến thẳng đích.
--    - Không bao giờ bị bay lên trời, không bị giật lag!
-- 3. ĐÁNH QUÁI M1 TRÚNG 100% (GROUND MELEE HITBOX):
--    - Bám sát sau lưng quái 2 studs trên mặt đất (Y bằng mặt sàn), chém M1 đa kênh, xả kỹ năng 1-3, Dash Q.
-- ================================================

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local VirtualInputMgr   = game:GetService("VirtualInputManager")
local VirtualUser       = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local LP                = Players.LocalPlayer
local Cam               = workspace.CurrentCamera

-- Trạng thái toàn cục
local State = {
    autoafk       = false, -- MASTER TOGGLE: TREO MÁY TOÀN DIỆN
    autofarm      = true,  -- Tự đánh quái trong hầm ngục
    autoboss      = false, -- Ưu tiên diệt Boss trước
    autoskill     = true,  -- Tự xả chiêu 1, 2, 3
    autodash      = true,  -- Tự lướt Dash (Q) né đòn
    autodoor      = true,  -- Tự đi qua cửa khi hết quái phòng
    autochest     = true,  -- Tự nhặt rương sau khi dọn quái
    autoreplay    = true,  -- Tự bấm Replay khi xong hầm ngục
    speed         = false,
    fly           = false,
    nofall        = true,
    esp_mobs      = false,
    esp_chests    = false,
    targetLevel   = "AUTO", -- "AUTO", "1", "2", "3", "4", "5"
    statusText    = "Sẵn sàng treo máy!",
}

local CFG = {
    walkspeed   = 55,
    flyspeed    = 50,
    m1Delay     = 0.12,
    skillDelay  = 1.2,
    dashDelay   = 3.5,
}

-- Quản lý nhân vật
local Char, HRP, Hum
local humConns = {}

local function clearHumConns()
    for _, c in pairs(humConns) do pcall(function() c:Disconnect() end) end
    humConns = {}
end

local function setupCharacter(newChar)
    Char = newChar
    HRP  = newChar:WaitForChild("HumanoidRootPart", 10)
    Hum  = newChar:WaitForChild("Humanoid", 10)

    clearHumConns()

    if Hum then
        pcall(function() Hum.BreakJointsOnDeath = false end)

        local cSpeed = Hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
            if State.speed and Hum.WalkSpeed ~= CFG.walkspeed then
                pcall(function() Hum.WalkSpeed = CFG.walkspeed end)
            end
        end)
        table.insert(humConns, cSpeed)

        if State.speed then
            pcall(function() Hum.WalkSpeed = CFG.walkspeed end)
        end

        local cState = Hum.StateChanged:Connect(function(_, newState)
            if newState == Enum.HumanoidStateType.Landed and State.nofall and HRP then
                pcall(function()
                    local v = HRP.AssemblyLinearVelocity
                    HRP.AssemblyLinearVelocity = Vector3.new(v.X, 0, v.Z)
                end)
            end
        end)
        table.insert(humConns, cState)
    end
end

if LP.Character then setupCharacter(LP.Character) end
LP.CharacterAdded:Connect(function(newChar)
    task.wait(0.3)
    setupCharacter(newChar)
end)

-- Duy trì tốc độ
RunService.Heartbeat:Connect(function()
    if HRP and Hum and Hum.Health > 0 then
        if State.speed and Hum.WalkSpeed ~= CFG.walkspeed then
            pcall(function() Hum.WalkSpeed = CFG.walkspeed end)
        end
        if State.nofall and HRP.AssemblyLinearVelocity.Y < -24 then
            local v = HRP.AssemblyLinearVelocity
            HRP.AssemblyLinearVelocity = Vector3.new(v.X, -14, v.Z)
        end
    end
end)

-- ================================================
-- HỆ THỐNG ĐI BỘ TRÊN MẶT ĐẤT CÓ CHỐNG KẸT (SMART GROUND PATHING)
-- ================================================
local function smartWalkTo(targetPos, stopDistance, maxSeconds)
    if not HRP or not Hum or Hum.Health <= 0 then return false end
    stopDistance = stopDistance or 3.5
    maxSeconds   = maxSeconds or 7.0

    local startTime = tick()
    local lastPos   = HRP.Position
    local stuckTime = 0

    while (tick() - startTime) < maxSeconds do
        if not HRP or not Hum or Hum.Health <= 0 then break end

        local distHorizontal = (Vector3.new(HRP.Position.X, 0, HRP.Position.Z) - Vector3.new(targetPos.X, 0, targetPos.Z)).Magnitude
        if distHorizontal <= stopDistance then
            break
        end

        -- 1. Ra lệnh đi bộ
        Hum:MoveTo(targetPos)

        -- 2. Kiểm tra nếu bị kẹt (vật cản, hàng rào, tường)
        local movedDist = (HRP.Position - lastPos).Magnitude
        if movedDist < 0.3 then
            stuckTime = stuckTime + 0.1
            if stuckTime >= 0.8 then
                -- Nhảy qua vật cản
                Hum.Jump = true
                -- Lướt nhẹ qua
                if HRP then
                    local dir = (Vector3.new(targetPos.X, HRP.Position.Y, targetPos.Z) - HRP.Position).Unit
                    HRP.CFrame = HRP.CFrame + (dir * 2.5)
                end
                stuckTime = 0
            end
        else
            stuckTime = 0
        end

        lastPos = HRP.Position
        task.wait(0.1)
    end

    if HRP then
        return (Vector3.new(HRP.Position.X, 0, HRP.Position.Z) - Vector3.new(targetPos.X, 0, targetPos.Z)).Magnitude <= (stopDistance + 2.5)
    end
    return false
end

-- ================================================
-- TÌM KIẾM QUÁI HẦM NGỤC THỰC SỰ (LOẠI BỎ TƯỢNG, DUMMY SẢNH)
-- ================================================
local BLACKLIST = {
    "npc", "dummy", "shop", "summon", "gacha", "leaderboard", "statue",
    "guide", "portal", "board", "merchant", "blacksmith", "trainer", "quest",
    "safezone", "spawn", "display", "vip", "reward", "code"
}

local function isBlacklisted(name)
    local n = name:lower()
    for _, b in ipairs(BLACKLIST) do
        if n:find(b) then return true end
    end
    return false
end

local function getRealDungeonEnemies()
    local list = {}
    local seen = {}
    if not HRP then return list end

    local function checkAdd(model)
        if not model or not model:IsA("Model") or seen[model] then return end
        if model == Char then return end
        if Players:GetPlayerFromCharacter(model) then return end
        if isBlacklisted(model.Name) then return end

        local mHum = model:FindFirstChildOfClass("Humanoid")
        local mHRP = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso")

        if mHum and mHRP and mHum.Health > 0 then
            -- Không bao giờ nhận quái có độ cao Y lệch quá 30 studs (tránh tượng trên trời)
            local yDiff = math.abs(mHRP.Position.Y - HRP.Position.Y)
            if yDiff > 32 then return end

            seen[model] = true
            local isBoss = false
            local nameLower = model.Name:lower()
            if nameLower:find("boss") or (mHum.MaxHealth > 5000) then isBoss = true end

            table.insert(list, {
                model = model,
                root  = mHRP,
                hum   = mHum,
                boss  = isBoss
            })
        end
    end

    for _, folderName in ipairs({"Enemies", "Mobs", "Monsters", "DungeonMobs", "Entities", "RoomEnemies", "CurrentRoom"}) do
        local f = workspace:FindFirstChild(folderName, true)
        if f then
            for _, child in ipairs(f:GetChildren()) do checkAdd(child) end
        end
    end

    for _, containerName in ipairs({"Dungeon", "Rooms", "Map"}) do
        local container = workspace:FindFirstChild(containerName)
        if container then
            for _, desc in ipairs(container:GetDescendants()) do
                if desc:IsA("Model") and desc:FindFirstChildOfClass("Humanoid") then
                    checkAdd(desc)
                end
            end
        end
    end

    return list
end

local function isPlayerInLobby()
    local enemies = getRealDungeonEnemies()
    if #enemies > 0 then return false end
    for _, name in ipairs({"Lobby", "SpawnLocation", "TrainingDummy", "Summon", "Gacha", "DungeonPortal", "Shop"}) do
        if workspace:FindFirstChild(name, true) then return true end
    end
    return true
end

-- ================================================
-- VŨ KHÍ & ĐÒN ĐÁNH M1 TRÚNG 100%
-- ================================================
local combatRemotes = {}
local lastRemoteRefresh = 0

local function refreshRemotes()
    local found = {}
    local kw = {"attack", "hit", "damage", "swing", "slash", "combat", "m1", "skill", "cast", "strike", "weapon"}
    for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local n = obj.Name:lower()
            for _, k in ipairs(kw) do
                if n:find(k) then
                    table.insert(found, obj)
                    break
                end
            end
        end
    end
    combatRemotes = found
    lastRemoteRefresh = tick()
end
refreshRemotes()

local function equipWeapon()
    if not Char then return end
    local tool = Char:FindFirstChildOfClass("Tool")
    if not tool then
        local bp = LP:FindFirstChild("Backpack")
        if bp then
            local t = bp:FindFirstChildOfClass("Tool")
            if t and Hum then pcall(function() Hum:EquipTool(t) end) end
        end
    end
end

local lastM1 = 0
local lastSkill = 0
local lastDash = 0

local function attackEnemy(targetModel, targetRoot)
    local now = tick()
    if now - lastM1 < CFG.m1Delay then return end
    lastM1 = now

    equipWeapon()

    local vp = Cam.ViewportSize
    local cx, cy = vp.X / 2, vp.Y / 2

    -- Click chuột trái giữa màn hình
    pcall(function()
        VirtualInputMgr:SendMouseButtonEvent(cx, cy, 0, true, game, 1)
        task.wait(0.02)
        VirtualInputMgr:SendMouseButtonEvent(cx, cy, 0, false, game, 1)
    end)

    -- Chạm cảm ứng màn hình điện thoại
    pcall(function()
        VirtualInputMgr:SendTouchEvent(1, 0, cx, cy)
        task.wait(0.02)
        VirtualInputMgr:SendTouchEvent(1, 2, cx, cy)
    end)

    -- VirtualUser Button1
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:Button1Down(Vector2.new(cx, cy), Cam.CFrame)
        task.wait(0.02)
        VirtualUser:Button1Up(Vector2.new(cx, cy), Cam.CFrame)
    end)

    -- Chạm nút Attack trên màn hình game nếu có
    local pGui = LP:FindFirstChild("PlayerGui")
    if pGui then
        for _, btn in ipairs(pGui:GetDescendants()) do
            if (btn:IsA("TextButton") or btn:IsA("ImageButton")) and btn.Visible then
                local n = btn.Name:lower()
                local text = btn:IsA("TextButton") and btn.Text:lower() or ""
                if n:find("attack") or n:find("m1") or n:find("slash") or n:find("strike") or text:find("attack") or text:find("m1") then
                    pcall(function()
                        firesignal(btn.MouseButton1Down)
                        firesignal(btn.Activated)
                    end)
                end
            end
        end
    end

    -- Kích hoạt Tool
    local tool = Char:FindFirstChildOfClass("Tool")
    if tool then pcall(function() tool:Activate() end) end

    -- Bắn remote combat
    if now - lastRemoteRefresh > 6 then refreshRemotes() end
    for _, r in ipairs(combatRemotes) do
        pcall(function()
            if r:IsA("RemoteEvent") then
                r:FireServer(targetModel, targetRoot.Position)
                r:FireServer(targetModel)
                r:FireServer(targetRoot)
                r:FireServer(1)
                r:FireServer()
            elseif r:IsA("RemoteFunction") then
                r:InvokeServer(targetModel, targetRoot.Position)
            end
        end)
    end

    -- Xả kỹ năng 1, 2, 3
    if State.autoskill and (now - lastSkill > CFG.skillDelay) then
        lastSkill = now
        pcall(function()
            VirtualInputMgr:SendKeyEvent(true, Enum.KeyCode.One, false, game)
            task.wait(0.02)
            VirtualInputMgr:SendKeyEvent(false, Enum.KeyCode.One, false, game)
            task.wait(0.03)
            VirtualInputMgr:SendKeyEvent(true, Enum.KeyCode.Two, false, game)
            task.wait(0.02)
            VirtualInputMgr:SendKeyEvent(false, Enum.KeyCode.Two, false, game)
            task.wait(0.03)
            VirtualInputMgr:SendKeyEvent(true, Enum.KeyCode.Three, false, game)
            task.wait(0.02)
            VirtualInputMgr:SendKeyEvent(false, Enum.KeyCode.Three, false, game)
        end)
    end

    -- Lướt Dash (Q) né đòn
    if State.autodash and (now - lastDash > CFG.dashDelay) then
        lastDash = now
        pcall(function()
            VirtualInputMgr:SendKeyEvent(true, Enum.KeyCode.Q, false, game)
            task.wait(0.02)
            VirtualInputMgr:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
        end)
    end
end

-- ================================================
-- HỆ THỐNG VÀO HẦM NGỤC TỰ ĐỘNG Ở SẢNH (LOBBY AUTOMATION)
-- ================================================
local function findLobbyDungeonPortal()
    local bestPart = nil
    local bestScore = 0

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local n = obj.Name:lower()
            local pName = obj.Parent and obj.Parent.Name:lower() or ""
            local combined = n .. " " .. pName

            local score = 0
            if combined:find("dungeonportal") or combined:find("dungeongate") or combined:find("dungeonboard") then score = 100
            elseif combined:find("portal") then score = 80
            elseif combined:find("dungeon") then score = 70
            elseif combined:find("gate") then score = 60
            elseif combined:find("play") or combined:find("start") then score = 50
            elseif combined:find("matchmaking") or combined:find("elevator") then score = 40
            end

            -- Bắt buộc không chứa chữ exit/return
            if score > bestScore and not combined:find("exit") and not combined:find("return") then
                bestScore = score
                bestPart = obj
            end
        end
    end
    return bestPart
end

local function handleDungeonMenuClick()
    local pGui = LP:FindFirstChild("PlayerGui")
    if not pGui then return false end

    -- 1. Bấm chọn cấp độ
    local targetLvlStr = tostring(State.targetLevel)
    for _, btn in ipairs(pGui:GetDescendants()) do
        if (btn:IsA("TextButton") or btn:IsA("ImageButton")) and btn.Visible then
            local bText = (btn.Name .. " " .. (btn:IsA("TextButton") and btn.Text or "")):lower()

            if State.targetLevel ~= "AUTO" then
                if bText:find("level " .. targetLvlStr) or bText:find("lv " .. targetLvlStr) or bText:find("cấp " .. targetLvlStr) or btn.Name == targetLvlStr then
                    pcall(function()
                        firesignal(btn.MouseButton1Click)
                        firesignal(btn.Activated)
                    end)
                    task.wait(0.3)
                    break
                end
            else
                if bText:find("level") or bText:find("cấp") or bText:find("chapter") then
                    pcall(function()
                        firesignal(btn.MouseButton1Click)
                        firesignal(btn.Activated)
                    end)
                end
            end
        end
    end

    task.wait(0.4)

    -- 2. Bấm nút Bắt đầu / Solo / Start / Create
    local started = false
    for _, btn in ipairs(pGui:GetDescendants()) do
        if (btn:IsA("TextButton") or btn:IsA("ImageButton")) and btn.Visible then
            local bText = (btn.Name .. " " .. (btn:IsA("TextButton") and btn.Text or "")):lower()
            if bText:find("start") or bText:find("solo") or bText:find("create") or bText:find("play") or bText:find("bắt đầu") or bText:find("ready") or bText:find("confirm") then
                pcall(function()
                    firesignal(btn.MouseButton1Click)
                    firesignal(btn.Activated)
                end)
                started = true
                task.wait(0.3)
                break
            end
        end
    end

    return started
end

local isLobbyRunning = false

local function executeLobbyRoutine()
    if isLobbyRunning then return end
    isLobbyRunning = true

    State.statusText = "📍 Ở Sảnh Chờ -> Đang tìm cổng hầm ngục..."
    print("[VOSS] " .. State.statusText)

    -- 1. Tìm cổng hầm ngục
    local portal = findLobbyDungeonPortal()
    if portal and HRP then
        State.statusText = "Đang đi bộ đến cổng hầm ngục..."
        print("[VOSS] " .. State.statusText)

        -- Đi bộ trên mặt đất đến cổng (cùng độ cao sàn Y của người chơi)
        local walkTarget = Vector3.new(portal.Position.X, HRP.Position.Y, portal.Position.Z)
        smartWalkTo(walkTarget, 4.0, 9.0)
        task.wait(0.4)

        -- Bước hẳn vào vùng cổng
        if HRP then
            HRP.CFrame = CFrame.new(portal.Position.X, HRP.Position.Y, portal.Position.Z)
            task.wait(0.4)
        end
    end

    -- 2. Kích hoạt ProximityPrompt ở cổng nếu có
    for _, prompt in ipairs(workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") then
            local pText = (prompt.ActionText .. " " .. prompt.ObjectText):lower()
            if pText:find("enter") or pText:find("play") or pText:find("start") or pText:find("dungeon") or pText:find("vào") then
                pcall(function() fireproximityprompt(prompt) end)
                task.wait(0.3)
            end
        end
    end

    -- 3. Bấm menu hầm ngục
    task.wait(0.6)
    handleDungeonMenuClick()

    -- 4. Bắn thử remote tạo phòng nếu có
    for _, r in ipairs(ReplicatedStorage:GetDescendants()) do
        if r:IsA("RemoteEvent") or r:IsA("RemoteFunction") then
            local n = r.Name:lower()
            if n:find("startdungeon") or n:find("createdungeon") or n:find("joindungeon") or n:find("startgame") then
                pcall(function()
                    if r:IsA("RemoteEvent") then
                        r:FireServer(1)
                        r:FireServer(true)
                    else
                        r:InvokeServer(1)
                    end
                end)
            end
        end
    end

    State.statusText = "Đã vào hàng chờ / Đang tải map hầm ngục..."
    task.wait(4.0)
    isLobbyRunning = false
end

-- ================================================
-- VÒNG LẶP TREO MÁY TOÀN DIỆN (FULL AFK LOOP)
-- ================================================
local isBusyChest = false
local isBusyDoor  = false

task.spawn(function()
    while true do
        task.wait(0.6)
        if not State.autoafk then continue end
        if not HRP or not Hum or Hum.Health <= 0 then continue end

        -- NẾU ĐANG Ở SẢNH CHỜ -> TỰ ĐỘNG VÀO HẦM NGỤC
        if isPlayerInLobby() then
            if not isLobbyRunning then
                executeLobbyRoutine()
            end
        end
    end
end)

-- VÒNG LẶP CHIẾN ĐẤU TRONG HẦM NGỤC (HEARTBEAT)
RunService.Heartbeat:Connect(function()
    if not HRP or not Hum or Hum.Health <= 0 then return end

    -- Nếu đang ở sảnh thì để vòng lặp AFK lobby xử lý, không chạy farm
    if isPlayerInLobby() then return end

    -- ĐANG TRONG HẦM NGỤC:
    local enemies = getRealDungeonEnemies()

    -- BƯỚC 1: CÒN QUÁI TRONG PHÒNG -> ĐỨNG ĐẤT CHÉM SAU LƯNG
    if #enemies > 0 and (State.autoafk or State.autofarm) then
        isBusyChest = false
        isBusyDoor  = false

        -- Chọn quái gần nhất
        local target = nil
        local bestDist = 999999
        for _, e in ipairs(enemies) do
            if not State.autoboss or e.boss then
                local dist = (HRP.Position - e.root.Position).Magnitude
                if dist < bestDist then
                    target = e
                    bestDist = dist
                end
            end
        end
        if not target and State.autoboss then target = enemies[1] end

        if target and target.root and target.hum and target.hum.Health > 0 then
            local mobRoot = target.root
            local mobCF   = mobRoot.CFrame
            local mobPos  = mobRoot.Position
            local myPos   = HRP.Position

            State.statusText = "⚔️ Đang diệt: " .. target.model.Name .. " (HP: " .. math.floor(target.hum.Health) .. ")"

            -- Giữ hai chân đứng trên sàn bình thường
            Hum.PlatformStand = false

            -- Đứng sau lưng quái TRÊN MẶT ĐẤT
            local behindPos = mobPos - (mobCF.LookVector * 2.0)
            behindPos = Vector3.new(behindPos.X, mobPos.Y, behindPos.Z)

            local dist = (myPos - behindPos).Magnitude
            if dist > 4.5 then
                -- Còn xa: Đi bộ tiếp cận
                Hum:MoveTo(behindPos)
            else
                -- Đã áp sát: Khóa vị trí đứng sau lưng, chém trực diện
                HRP.AssemblyLinearVelocity = Vector3.zero
                HRP.CFrame = CFrame.lookAt(behindPos, Vector3.new(mobPos.X, behindPos.Y, mobPos.Z))
            end

            -- Tấn công M1
            attackEnemy(target.model, mobRoot)
            return
        end
    end

    -- BƯỚC 2: PHÒNG SẠCH QUÁI -> TỰ NHẶT RƯƠNG
    if #enemies == 0 and State.autochest and not isBusyChest and not isBusyDoor then
        local chestPart = nil
        for _, obj in ipairs(workspace:GetDescendants()) do
            local n = obj.Name:lower()
            if (n:find("chest") or n:find("treasure") or n:find("reward")) and (obj:IsA("BasePart") or obj:IsA("Model")) then
                local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                if part and HRP and math.abs(part.Position.Y - HRP.Position.Y) < 15 then
                    if (part.Position - HRP.Position).Magnitude > 3.5 then
                        chestPart = part
                        break
                    end
                end
            end
        end

        if chestPart then
            isBusyChest = true
            State.statusText = "📦 Đang đi bộ nhặt rương kho báu..."
            smartWalkTo(chestPart.Position, 3.0, 5.0)

            local prompt = chestPart:FindFirstChildOfClass("ProximityPrompt") or chestPart.Parent:FindFirstChildOfClass("ProximityPrompt")
            if prompt then pcall(function() fireproximityprompt(prompt) end) end
            task.wait(0.5)
            isBusyChest = false
            return
        end
    end

    -- BƯỚC 3: PHÒNG SẠCH QUÁI -> TỰ ĐI QUA CỬA PHÒNG KẾ
    if #enemies == 0 and State.autodoor and not isBusyDoor then
        isBusyDoor = true

        local doorPart = nil
        for _, obj in ipairs(workspace:GetDescendants()) do
            local n = obj.Name:lower()
            if (n:find("nextroom") or n:find("door") or n:find("gate") or n:find("exit")) and not n:find("lobby") then
                local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                if part and HRP and math.abs(part.Position.Y - HRP.Position.Y) < 15 then
                    doorPart = part
                    break
                end
            end
        end

        if doorPart and HRP and (doorPart.Position - HRP.Position).Magnitude > 4.0 then
            State.statusText = "🚪 Đang đi bộ qua cửa phòng tiếp theo..."
            smartWalkTo(doorPart.Position, 3.0, 6.0)

            local prompt = doorPart:FindFirstChildOfClass("ProximityPrompt") or doorPart.Parent:FindFirstChildOfClass("ProximityPrompt")
            if prompt then pcall(function() fireproximityprompt(prompt) end) end
        end

        -- Xác nhận nút Vote
        local pGui = LP:FindFirstChild("PlayerGui")
        if pGui then
            for _, btn in ipairs(pGui:GetDescendants()) do
                if (btn:IsA("TextButton") or btn:IsA("ImageButton")) and btn.Visible then
                    local bText = (btn.Name .. " " .. (btn:IsA("TextButton") and btn.Text or "")):lower()
                    if bText:find("vote") or bText:find("yes") or bText:find("ready") or bText:find("next") or bText:find("proceed") then
                        pcall(function()
                            firesignal(btn.MouseButton1Click)
                            firesignal(btn.Activated)
                        end)
                    end
                end
            end
        end

        task.wait(0.8)
        isBusyDoor = false
    end

    -- BƯỚC 4: XONG MÀN -> TỰ REPLAY
    if State.autoreplay then
        local pGui = LP:FindFirstChild("PlayerGui")
        if pGui then
            for _, btn in ipairs(pGui:GetDescendants()) do
                if (btn:IsA("TextButton") or btn:IsA("ImageButton")) and btn.Visible then
                    local bText = (btn.Name .. " " .. (btn:IsA("TextButton") and btn.Text or "")):lower()
                    if bText:find("replay") or bText:find("again") or bText:find("chơi lại") or bText:find("retry") or bText:find("continue") then
                        pcall(function()
                            firesignal(btn.MouseButton1Click)
                            firesignal(btn.Activated)
                        end)
                        State.statusText = "🏆 Thắng trận! Đang chơi lại..."
                        task.wait(0.5)
                        break
                    end
                end
            end
        end
    end
end)

-- ================================================
-- HỆ THỐNG BAY 3D MOBILE
-- ================================================
local flyConn     = nil
local flyObjects  = {}
local mobileFlyGui = nil
local mobileUpDown = 0

local function cleanFlyObjects()
    for _, obj in pairs(flyObjects) do pcall(function() obj:Destroy() end) end
    flyObjects = {}
    if HRP then
        for _, n in pairs({"VOSS_BV", "VOSS_BG"}) do
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

local function stopFly()
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    cleanFlyObjects()
    if Hum then
        pcall(function()
            Hum.PlatformStand = false
            Hum.AutoRotate    = true
        end)
    end
end

local function createMobileFlyButtons()
    if mobileFlyGui then return end
    local coreGui = game:GetService("CoreGui")

    local mGui = Instance.new("ScreenGui")
    mGui.Name           = "VOSS_DungeonFlyControls"
    mGui.ResetOnSpawn   = false
    mGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    mGui.Parent         = coreGui
    mobileFlyGui        = mGui

    local container = Instance.new("Frame", mGui)
    container.Size             = UDim2.new(0, 65, 0, 140)
    container.Position         = UDim2.new(1, -85, 0.5, -70)
    container.BackgroundTransparency = 1

    local btnUp = Instance.new("TextButton", container)
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

    local btnDown = Instance.new("TextButton", container)
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

local function getFlyDirection()
    local dir   = Vector3.zero
    local camCF = Cam.CFrame
    local uis   = UserInputService

    if Hum and Hum.MoveDirection.Magnitude > 0 then
        local look  = camCF.LookVector
        local right = camCF.RightVector
        local flatLook  = Vector3.new(look.X, 0, look.Z).Unit
        local flatRight = Vector3.new(right.X, 0, right.Z).Unit
        local fDot = Hum.MoveDirection:Dot(flatLook)
        local rDot = Hum.MoveDirection:Dot(flatRight)
        dir = (look * fDot) + (right * rDot)
    else
        local moveZ, moveX = 0, 0
        if uis:IsKeyDown(Enum.KeyCode.W) then moveZ = moveZ + 1 end
        if uis:IsKeyDown(Enum.KeyCode.S) then moveZ = moveZ - 1 end
        if uis:IsKeyDown(Enum.KeyCode.A) then moveX = moveX - 1 end
        if uis:IsKeyDown(Enum.KeyCode.D) then moveX = moveX + 1 end
        dir = (camCF.LookVector * moveZ) + (camCF.RightVector * moveX)
    end

    if mobileUpDown == 1 or uis:IsKeyDown(Enum.KeyCode.Space) then
        dir = dir + Vector3.new(0, 1, 0)
    elseif mobileUpDown == -1 or uis:IsKeyDown(Enum.KeyCode.LeftControl) or uis:IsKeyDown(Enum.KeyCode.C) then
        dir = dir + Vector3.new(0, -1, 0)
    end

    return dir
end

local function startFly()
    if flyConn then stopFly() end
    if not HRP or not Hum then return end

    Hum.PlatformStand = true
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
        if not State.fly or not HRP or not Hum then stopFly(); return end
        local bv2 = HRP:FindFirstChild("VOSS_BV")
        local bg2 = HRP:FindFirstChild("VOSS_BG")
        if not bv2 or not bg2 then stopFly(); return end

        local fDir = getFlyDirection()
        bv2.Velocity = fDir.Magnitude > 0 and (fDir.Unit * CFG.flyspeed) or Vector3.zero

        local look = Vector3.new(Cam.CFrame.LookVector.X, 0, Cam.CFrame.LookVector.Z)
        if look.Magnitude > 0.01 then
            bg2.CFrame = CFrame.new(HRP.Position, HRP.Position + look)
        end
    end)
end

-- ================================================
-- HỆ THỐNG ESP RADAR
-- ================================================
local ESPCache = {}

local function clearESP()
    for k, v in pairs(ESPCache) do
        pcall(function() v:Destroy() end)
        ESPCache[k] = nil
    end
end

RunService.Heartbeat:Connect(function()
    if not State.esp_mobs and not State.esp_chests then
        if next(ESPCache) then clearESP() end
        return
    end

    local seen = {}

    if State.esp_mobs then
        local enemies = getRealDungeonEnemies()
        for _, e in ipairs(enemies) do
            local key = "mob_" .. tostring(e.model)
            seen[key] = true
            if not ESPCache[key] and e.root then
                local bb = Instance.new("BillboardGui")
                bb.AlwaysOnTop = true
                bb.Size        = UDim2.new(0, 140, 0, 30)
                bb.StudsOffset = Vector3.new(0, 3.0, 0)
                bb.Adornee     = e.root
                bb.Parent      = e.root

                local lbl = Instance.new("TextLabel", bb)
                lbl.Size                   = UDim2.new(1, 0, 1, 0)
                lbl.BackgroundTransparency = 1
                lbl.TextColor3             = e.boss and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(255, 60, 60)
                lbl.TextStrokeTransparency = 0
                lbl.Font                   = Enum.Font.GothamBold
                lbl.TextScaled             = true
                lbl.Text                   = (e.boss and "👑 [BOSS] " or "👾 ") .. e.model.Name
                ESPCache[key] = bb
            end
        end
    end

    if State.esp_chests then
        for _, obj in ipairs(workspace:GetDescendants()) do
            local n = obj.Name:lower()
            if (n:find("chest") or n:find("treasure")) and (obj:IsA("BasePart") or obj:IsA("Model")) then
                local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                if part and HRP and math.abs(part.Position.Y - HRP.Position.Y) < 20 then
                    local key = "chest_" .. tostring(obj)
                    seen[key] = true
                    if not ESPCache[key] then
                        local bb = Instance.new("BillboardGui")
                        bb.AlwaysOnTop = true
                        bb.Size        = UDim2.new(0, 120, 0, 26)
                        bb.StudsOffset = Vector3.new(0, 2.5, 0)
                        bb.Adornee     = part
                        bb.Parent      = part

                        local lbl = Instance.new("TextLabel", bb)
                        lbl.Size                   = UDim2.new(1, 0, 1, 0)
                        lbl.BackgroundTransparency = 1
                        lbl.TextColor3             = Color3.fromRGB(255, 230, 80)
                        lbl.TextStrokeTransparency = 0
                        lbl.Font                   = Enum.Font.GothamBold
                        lbl.TextScaled             = true
                        lbl.Text                   = "📦 RƯƠNG"
                        ESPCache[key] = bb
                    end
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
-- GIAO DIỆN VOSS HUB (LUXURY DARK & NEON PURPLE)
-- ================================================
pcall(function()
    game:GetService("CoreGui"):FindFirstChild("VOSS_DungeonHub"):Destroy()
end)

local coreGui = game:GetService("CoreGui")
local SG = Instance.new("ScreenGui")
SG.Name           = "VOSS_DungeonHub"
SG.ResetOnSpawn   = false
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SG.Parent         = coreGui

-- 1. NÚT TRÒN CẢM ỨNG NỔI TRÊN MÀN HÌNH
local FloatBtn = Instance.new("TextButton", SG)
FloatBtn.Name             = "FloatBtn"
FloatBtn.Size             = UDim2.new(0, 52, 0, 52)
FloatBtn.Position         = UDim2.new(0, 15, 0.4, 0)
FloatBtn.BackgroundColor3 = Color3.fromRGB(20, 15, 35)
FloatBtn.Text             = "⚡\nVOSS"
FloatBtn.TextColor3       = Color3.fromRGB(210, 160, 255)
FloatBtn.Font             = Enum.Font.GothamBold
FloatBtn.TextSize         = 11
FloatBtn.Active           = true
FloatBtn.Draggable        = true
Instance.new("UICorner", FloatBtn).CornerRadius = UDim.new(0, 26)
local fbStroke = Instance.new("UIStroke", FloatBtn)
fbStroke.Color = Color3.fromRGB(145, 75, 255); fbStroke.Thickness = 2

-- 2. KHUNG MENU CHÍNH
local MainFrame = Instance.new("Frame", SG)
MainFrame.Name             = "MainFrame"
MainFrame.Size             = UDim2.new(0, 320, 0, 520)
MainFrame.Position         = UDim2.new(0.5, -160, 0.5, -260)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
MainFrame.BorderSizePixel  = 0
MainFrame.Active           = true
MainFrame.Draggable        = true
MainFrame.ClipsDescendants = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 14)

local mfStroke = Instance.new("UIStroke", MainFrame)
mfStroke.Color = Color3.fromRGB(125, 65, 235); mfStroke.Thickness = 2

-- Header
local Header = Instance.new("Frame", MainFrame)
Header.Size             = UDim2.new(1, 0, 0, 54)
Header.BackgroundColor3 = Color3.fromRGB(18, 16, 28)
Header.BorderSizePixel  = 0
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 14)

local Title = Instance.new("TextLabel", Header)
Title.Size               = UDim2.new(1, -50, 0, 26)
Title.Position           = UDim2.new(0, 16, 0, 4)
Title.BackgroundTransparency = 1
Title.Text               = "VOSS | Thợ Săn Hầm Ngục v4 ⚔️"
Title.TextColor3         = Color3.fromRGB(220, 180, 255)
Title.Font               = Enum.Font.GothamBold
Title.TextSize           = 14
Title.TextXAlignment     = Enum.TextXAlignment.Left

local SubTitle = Instance.new("TextLabel", Header)
SubTitle.Size               = UDim2.new(1, -50, 0, 16)
SubTitle.Position           = UDim2.new(0, 16, 0, 28)
SubTitle.BackgroundTransparency = 1
SubTitle.Text               = "Auto Treo Máy Toàn Diện • 100% Tự Động"
SubTitle.TextColor3         = Color3.fromRGB(130, 120, 170)
SubTitle.Font               = Enum.Font.Gotham
SubTitle.TextSize           = 10
SubTitle.TextXAlignment     = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", Header)
CloseBtn.Size             = UDim2.new(0, 28, 0, 28)
CloseBtn.Position         = UDim2.new(1, -38, 0, 13)
CloseBtn.BackgroundColor3 = Color3.fromRGB(40, 25, 60)
CloseBtn.Text             = "✕"
CloseBtn.TextColor3       = Color3.fromRGB(255, 180, 180)
CloseBtn.Font             = Enum.Font.GothamBold
CloseBtn.TextSize         = 13
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)

CloseBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false end)
FloatBtn.MouseButton1Click:Connect(function() MainFrame.Visible = not MainFrame.Visible end)

-- Status Banner
local StatusBanner = Instance.new("Frame", MainFrame)
StatusBanner.Size             = UDim2.new(1, -20, 0, 26)
StatusBanner.Position         = UDim2.new(0, 10, 0, 58)
StatusBanner.BackgroundColor3 = Color3.fromRGB(24, 20, 38)
Instance.new("UICorner", StatusBanner).CornerRadius = UDim.new(0, 6)

local StatusLbl = Instance.new("TextLabel", StatusBanner)
StatusLbl.Size               = UDim2.new(1, -12, 1, 0)
StatusLbl.Position           = UDim2.new(0, 8, 0, 0)
StatusLbl.BackgroundTransparency = 1
StatusLbl.Text               = "Trạng thái: " .. State.statusText
StatusLbl.TextColor3         = Color3.fromRGB(200, 255, 180)
StatusLbl.Font               = Enum.Font.GothamBold
StatusLbl.TextSize           = 10
StatusLbl.TextXAlignment     = Enum.TextXAlignment.Left

task.spawn(function()
    while task.wait(0.4) do
        if StatusLbl and StatusLbl.Parent then
            StatusLbl.Text = "Trạng thái: " .. State.statusText
        end
    end
end)

-- Danh sách cuộn
local Scroll = Instance.new("ScrollingFrame", MainFrame)
Scroll.Size             = UDim2.new(1, -16, 1, -94)
Scroll.Position         = UDim2.new(0, 8, 0, 88)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel  = 0
Scroll.ScrollBarThickness = 4
Scroll.ScrollBarImageColor3 = Color3.fromRGB(120, 70, 220)
Scroll.CanvasSize       = UDim2.new(0, 0, 0, 780)

local UIList = Instance.new("UIListLayout", Scroll)
UIList.Padding = UDim.new(0, 8)
UIList.SortOrder = Enum.SortOrder.LayoutOrder

local function createCategory(text, order)
    local lbl = Instance.new("TextLabel", Scroll)
    lbl.Size             = UDim2.new(1, 0, 0, 24)
    lbl.LayoutOrder      = order
    lbl.BackgroundTransparency = 1
    lbl.Text             = text
    lbl.TextColor3       = Color3.fromRGB(185, 145, 255)
    lbl.Font             = Enum.Font.GothamBold
    lbl.TextSize         = 12
    lbl.TextXAlignment   = Enum.TextXAlignment.Left
    return lbl
end

local function createMasterToggle(title, desc, defaultState, callback, order)
    local f = Instance.new("Frame", Scroll)
    f.Size             = UDim2.new(1, -6, 0, 56)
    f.BackgroundColor3 = Color3.fromRGB(35, 25, 55)
    f.LayoutOrder      = order
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 12)

    local stroke = Instance.new("UIStroke", f)
    stroke.Color = defaultState and Color3.fromRGB(180, 80, 255) or Color3.fromRGB(120, 60, 200)
    stroke.Thickness = 2

    local tLbl = Instance.new("TextLabel", f)
    tLbl.Size               = UDim2.new(1, -70, 0, 24)
    tLbl.Position           = UDim2.new(0, 14, 0, 6)
    tLbl.BackgroundTransparency = 1
    tLbl.Text               = title
    tLbl.TextColor3         = Color3.fromRGB(255, 240, 255)
    tLbl.Font               = Enum.Font.GothamBold
    tLbl.TextSize           = 14
    tLbl.TextXAlignment     = Enum.TextXAlignment.Left

    local dLbl = Instance.new("TextLabel", f)
    dLbl.Size               = UDim2.new(1, -70, 0, 18)
    dLbl.Position           = UDim2.new(0, 14, 0, 30)
    dLbl.BackgroundTransparency = 1
    dLbl.Text               = desc
    dLbl.TextColor3         = Color3.fromRGB(190, 175, 225)
    dLbl.Font               = Enum.Font.Gotham
    dLbl.TextSize           = 10
    dLbl.TextXAlignment     = Enum.TextXAlignment.Left

    local switch = Instance.new("TextButton", f)
    switch.Size             = UDim2.new(0, 48, 0, 28)
    switch.Position         = UDim2.new(1, -58, 0.5, -14)
    switch.BackgroundColor3 = defaultState and Color3.fromRGB(160, 60, 255) or Color3.fromRGB(50, 40, 70)
    switch.Text             = defaultState and "ON" or "OFF"
    switch.TextColor3       = Color3.fromRGB(255, 255, 255)
    switch.Font             = Enum.Font.GothamBold
    switch.TextSize         = 11
    Instance.new("UICorner", switch).CornerRadius = UDim.new(0, 14)

    local state = defaultState
    switch.MouseButton1Click:Connect(function()
        state = not state
        switch.Text = state and "ON" or "OFF"
        switch.BackgroundColor3 = state and Color3.fromRGB(160, 60, 255) or Color3.fromRGB(50, 40, 70)
        stroke.Color = state and Color3.fromRGB(200, 100, 255) or Color3.fromRGB(120, 60, 200)
        callback(state)
    end)
    return f
end

local function createToggle(title, desc, defaultState, callback, order)
    local f = Instance.new("Frame", Scroll)
    f.Size             = UDim2.new(1, -6, 0, 46)
    f.BackgroundColor3 = Color3.fromRGB(20, 18, 32)
    f.LayoutOrder      = order
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)

    local stroke = Instance.new("UIStroke", f)
    stroke.Color = defaultState and Color3.fromRGB(130, 70, 240) or Color3.fromRGB(45, 40, 65)
    stroke.Thickness = 1

    local tLbl = Instance.new("TextLabel", f)
    tLbl.Size               = UDim2.new(1, -65, 0, 20)
    tLbl.Position           = UDim2.new(0, 12, 0, 4)
    tLbl.BackgroundTransparency = 1
    tLbl.Text               = title
    tLbl.TextColor3         = Color3.fromRGB(230, 225, 250)
    tLbl.Font               = Enum.Font.GothamBold
    tLbl.TextSize           = 12
    tLbl.TextXAlignment     = Enum.TextXAlignment.Left

    local dLbl = Instance.new("TextLabel", f)
    dLbl.Size               = UDim2.new(1, -65, 0, 16)
    dLbl.Position           = UDim2.new(0, 12, 0, 24)
    dLbl.BackgroundTransparency = 1
    dLbl.Text               = desc
    dLbl.TextColor3         = Color3.fromRGB(130, 125, 155)
    dLbl.Font               = Enum.Font.Gotham
    dLbl.TextSize           = 10
    dLbl.TextXAlignment     = Enum.TextXAlignment.Left

    local switch = Instance.new("TextButton", f)
    switch.Size             = UDim2.new(0, 42, 0, 24)
    switch.Position         = UDim2.new(1, -52, 0.5, -12)
    switch.BackgroundColor3 = defaultState and Color3.fromRGB(130, 60, 240) or Color3.fromRGB(40, 35, 55)
    switch.Text             = defaultState and "ON" or "OFF"
    switch.TextColor3       = Color3.fromRGB(255, 255, 255)
    switch.Font             = Enum.Font.GothamBold
    switch.TextSize         = 10
    Instance.new("UICorner", switch).CornerRadius = UDim.new(0, 12)

    local state = defaultState
    switch.MouseButton1Click:Connect(function()
        state = not state
        switch.Text = state and "ON" or "OFF"
        switch.BackgroundColor3 = state and Color3.fromRGB(130, 60, 240) or Color3.fromRGB(40, 35, 55)
        stroke.Color = state and Color3.fromRGB(130, 70, 240) or Color3.fromRGB(45, 40, 65)
        callback(state)
    end)
    return f
end

local function createLevelSelector(order)
    local f = Instance.new("Frame", Scroll)
    f.Size             = UDim2.new(1, -6, 0, 64)
    f.BackgroundColor3 = Color3.fromRGB(22, 19, 36)
    f.LayoutOrder      = order
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)

    local tLbl = Instance.new("TextLabel", f)
    tLbl.Size               = UDim2.new(1, -16, 0, 20)
    tLbl.Position           = UDim2.new(0, 12, 0, 6)
    tLbl.BackgroundTransparency = 1
    tLbl.Text               = "🎯 Cấp Hầm Ngục Muốn Treo Máy:"
    tLbl.TextColor3         = Color3.fromRGB(225, 190, 255)
    tLbl.Font               = Enum.Font.GothamBold
    tLbl.TextSize           = 12
    tLbl.TextXAlignment     = Enum.TextXAlignment.Left

    local btnContainer = Instance.new("ScrollingFrame", f)
    btnContainer.Size       = UDim2.new(1, -20, 0, 28)
    btnContainer.Position   = UDim2.new(0, 10, 0, 28)
    btnContainer.BackgroundTransparency = 1
    btnContainer.ScrollBarThickness = 0
    btnContainer.CanvasSize = UDim2.new(0, 360, 0, 0)

    local bList = Instance.new("UIListLayout", btnContainer)
    bList.FillDirection = Enum.FillDirection.Horizontal
    bList.Padding = UDim.new(0, 6)

    local levels = {"AUTO", "1", "2", "3", "4", "5"}
    local levelBtns = {}

    for _, lvl in ipairs(levels) do
        local b = Instance.new("TextButton", btnContainer)
        b.Size = UDim2.new(0, lvl == "AUTO" and 54 or 42, 0, 26)
        b.BackgroundColor3 = (State.targetLevel == lvl) and Color3.fromRGB(130, 60, 240) or Color3.fromRGB(38, 32, 58)
        b.Text = (lvl == "AUTO") and "AUTO" or ("Cấp " .. lvl)
        b.TextColor3 = Color3.fromRGB(255, 255, 255)
        b.Font = Enum.Font.GothamBold
        b.TextSize = 10
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)

        b.MouseButton1Click:Connect(function()
            State.targetLevel = lvl
            for _, ob in pairs(levelBtns) do ob.BackgroundColor3 = Color3.fromRGB(38, 32, 58) end
            b.BackgroundColor3 = Color3.fromRGB(130, 60, 240)
            State.statusText = "Đã chọn cấp độ: " .. lvl
        end)
        table.insert(levelBtns, b)
    end
    return f
end

-- ================================================
-- KHỞI TẠO NỘI DUNG MENU
-- ================================================

-- CÔNG TẮC CHÍNH TỐI THƯỢNG: TREO MÁY TOÀN DIỆN
createCategory("🚀 CHẾ ĐỘ TREO MÁY TOÀN DIỆN (AFK FOREVER)", 1)

createMasterToggle("⚡ AUTO TREO MÁY TOÀN DIỆN", "Tự vào map sảnh -> Tự cày quái -> Tự qua ải -> Tự Replay lặp vô tận", State.autoafk, function(val)
    State.autoafk = val
    if val then
        State.statusText = "Bắt đầu chu trình treo máy toàn diện!"
    else
        State.statusText = "Đã tạm dừng treo máy."
    end
end, 2)

createLevelSelector(3)

-- CÀY CẤP & CHIẾN ĐẤU CHI TIẾT
createCategory("⚔️ TÙY CHỌN CHIẾN ĐẤU (GROUND COMBAT)", 10)

createToggle("Auto Chém Quái (M1 Đứng Đất)", "Luôn đứng đất 2 studs sau lưng quái chém trúng 100%", State.autofarm, function(val)
    State.autofarm = val
end, 11)

createToggle("Ưu Tiên Săn Boss", "Tập trung diệt Boss phòng trước", State.autoboss, function(val)
    State.autoboss = val
end, 12)

createToggle("Auto Xả Kỹ Năng (1, 2, 3)", "Xoay tua chiêu thức tăng sát thương dồn", State.autoskill, function(val)
    State.autoskill = val
end, 13)

createToggle("Auto Lướt Dash (Q)", "Lướt né chiêu diện rộng của quái", State.autodash, function(val)
    State.autodash = val
end, 14)

createToggle("Auto Đi Qua Cửa (Next Room)", "Khi sạch quái tự đi qua cửa phòng tiếp theo", State.autodoor, function(val)
    State.autodoor = val
end, 15)

createToggle("Auto Nhặt Rương (Sau Mỗi Phòng)", "Tự đi nhặt rương kho báu & vàng sau khi dọn sạch ải", State.autochest, function(val)
    State.autochest = val
end, 16)

createToggle("Auto Chơi Lại (Replay)", "Thắng trận tự bấm Replay tạo vòng lặp cày vô tận", State.autoreplay, function(val)
    State.autoreplay = val
end, 17)

-- BỔ TRỢ NHÂN VẬT & BAY LƯỢN MOBILE
createCategory("⚡ BỔ TRỢ NHÂN VẬT & BAY LƯỢN", 20)

createToggle("Tốc Độ Chạy Cao (Speed 55)", "Tăng tốc độ di chuyển chạy bộ", State.speed, function(val)
    State.speed = val
    if Hum then pcall(function() Hum.WalkSpeed = val and CFG.walkspeed or 16 end) end
end, 21)

createToggle("Bay 3D (Có Nút Cảm Ứng Mobile)", "Kèm 2 nút cảm ứng [▲ Lên] [▼ Xuống] trên màn hình", State.fly, function(val)
    State.fly = val
    if val then startFly() else stopFly() end
end, 22)

createToggle("Chống Sát Thương Rơi", "Hãm tốc rơi tự do, rơi từ cao không mất máu", State.nofall, function(val)
    State.nofall = val
end, 23)

-- RADAR ĐỊNH VỊ
createCategory("👁️ RADAR ĐỊNH VỊ (ESP)", 30)

createToggle("ESP Quái & Boss", "Hiện tên quái (Đỏ) và Boss (Vàng) xuyên tường", State.esp_mobs, function(val)
    State.esp_mobs = val
    if not val then clearESP() end
end, 31)

createToggle("ESP Rương Kho Báu", "Hiện vị trí toàn bộ rương kho báu trong phòng", State.esp_chests, function(val)
    State.esp_chests = val
    if not val then clearESP() end
end, 32)

-- CỬ CHỈ CẢM ỨNG MOBILE 3 NGÓN
local activeTouches = {}
local tapCount     = 0
local lastTapTime  = 0
local peakCount    = 0

UserInputService.TouchStarted:Connect(function(touch)
    activeTouches[touch] = true
    local current = 0
    for _ in pairs(activeTouches) do current = current + 1 end
    if current > peakCount then peakCount = current end
end)

UserInputService.TouchEnded:Connect(function(touch)
    activeTouches[touch] = nil
    local remaining = 0
    for _ in pairs(activeTouches) do remaining = remaining + 1 end
    if remaining == 0 then
        if peakCount >= 3 then
            local now = tick()
            if tapCount == 0 or (now - lastTapTime) < 0.85 then
                tapCount    = tapCount + 1
                lastTapTime = now
            end
            task.delay(0.85, function()
                if (tick() - lastTapTime) >= 0.8 then
                    if tapCount == 2 then
                        MainFrame.Visible = false
                    elseif tapCount >= 3 then
                        MainFrame.Visible = true
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
        MainFrame.Visible = not MainFrame.Visible
    end
end)

print("[VOSS] Dungeon Hunters Hub v4.0 (Full AFK Loop Edition) Loaded Successfully! ⚔️")
