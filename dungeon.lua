-- ================================================
-- VOSS | Dungeon Hunters Hub v3.0 (Ground Navigation Edition)
-- Game: Thợ Săn Hầm Ngục [UPD] - The Evac Syndicate
-- ================================================
-- [KHẮC PHỤC TRIỆT ĐỂ TOÀN BỘ CÁC VẤN ĐỀ]:
-- 1. TRIỆT TIÊU LỖI BAY LÊN TRỜI:
--    - Loại bỏ hoàn toàn việc nhận nhầm tượng / NPC sảnh trên trời làm quái
--    - Cơ chế ĐỨNG ĐẤT 100% (Ground Combat): Luôn bám sát mặt đất (Y bằng mặt đất), tuyệt đối không bay lên trời
--    - Hum.PlatformStand luôn giữ = false khi chiến đấu để hai chân nhân vật đứng vững trên mặt sàn
-- 2. TỰ ĐỘNG ĐI BỘ VÀO MAP (NATURAL WALK NAVIGATION):
--    - Không dùng tele giật cục: Nhân vật tự động ĐI BỘ (Hum:MoveTo) mượt mà đến cổng hầm ngục ở sảnh
--    - Tự động bước vào vùng cổng, mở bảng hầm ngục, chọn Cấp 1 (hoặc cấp mong muốn), bấm Bắt đầu (Solo/Start)
-- 3. ĐÁNH QUÁI DÍNH ĐÒN 100% (M1 GROUND BEHIND):
--    - Đi bộ tiếp cận quái -> Áp sát cách 2 studs sau lưng quái trên mặt sàn
--    - Mặt quay thẳng vào quái: Mỗi đòn chém M1, kỹ năng 1-3, lướt Q đều trúng mục tiêu 100%
-- 4. TỰ ĐỘNG ĐI BỘ QUA CỬA & NHẶT RƯƠNG:
--    - Khi sạch bóng quái trong phòng -> Tự đi bộ nhặt rương -> Tự đi bộ ra cửa bước sang phòng kế tiếp
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
    autofarm      = false,
    autoboss      = false,
    autoskill     = true,
    autodash      = true,
    autodungeon   = false, -- Tự động đi bộ vào cổng từ sảnh
    autodoor      = true,  -- Tự đi bộ qua cửa khi sạch quái
    autochest     = true,  -- Tự đi bộ nhặt rương sau mỗi phòng
    autoreplay    = true,  -- Tự bấm Replay khi thắng hầm ngục
    speed         = false,
    fly           = false,
    nofall        = true,
    esp_mobs      = false,
    esp_chests    = false,
    targetLevel   = "AUTO", -- "AUTO", "1", "2", "3", "4", "5"
    statusText    = "Đang chờ lệnh...",
}

local CFG = {
    walkspeed   = 55,
    flyspeed    = 50,
    m1Delay     = 0.12,
    skillDelay  = 1.3,
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

-- Duy trì tốc độ chạy
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
-- HÀM TỰ ĐỘNG ĐI BỘ TRÊN MẶT ĐẤT (NATURAL WALK ENGINE)
-- ================================================
local isWalking = false

local function naturalWalkTo(targetPos, stopDistance, maxWaitSeconds)
    if not HRP or not Hum or Hum.Health <= 0 then return false end
    stopDistance   = stopDistance or 3.5
    maxWaitSeconds = maxWaitSeconds or 8.0

    isWalking = true
    local startTime = tick()

    while (tick() - startTime) < maxWaitSeconds do
        if not HRP or not Hum or Hum.Health <= 0 then break end
        local dist = (Vector3.new(HRP.Position.X, 0, HRP.Position.Z) - Vector3.new(targetPos.X, 0, targetPos.Z)).Magnitude
        if dist <= stopDistance then
            break
        end

        -- Tự động đi bộ đến mục tiêu
        Hum:MoveTo(targetPos)
        task.wait(0.08)
    end

    isWalking = false
    if HRP then
        return (Vector3.new(HRP.Position.X, 0, HRP.Position.Z) - Vector3.new(targetPos.X, 0, targetPos.Z)).Magnitude <= (stopDistance + 2)
    end
    return false
end

-- ================================================
-- BỘ LỌC QUÁI CHUẨN XÁC 100% (LOẠI BỎ TƯỢNG, NPC SẢNH)
-- ================================================
local NPC_BLACKLIST = {
    "npc", "dummy", "shop", "summon", "gacha", "leaderboard", "statue",
    "guide", "portal", "board", "merchant", "blacksmith", "trainer", "quest",
    "safezone", "spawn", "display", "vip", "reward", "code"
}

local function isNameBlacklisted(name)
    local n = name:lower()
    for _, b in ipairs(NPC_BLACKLIST) do
        if n:find(b) then return true end
    end
    return false
end

local function getRealDungeonEnemies()
    local list = {}
    local seen = {}
    if not HRP then return list end

    local function addIfRealEnemy(model)
        if not model or not model:IsA("Model") or seen[model] then return end
        if model == Char then return end
        if Players:GetPlayerFromCharacter(model) then return end
        if isNameBlacklisted(model.Name) then return end

        local mHum = model:FindFirstChildOfClass("Humanoid")
        local mHRP = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso")

        if mHum and mHRP and mHum.Health > 0 then
            -- Bắt buộc độ cao Y không được lệch quá 30 studs so với nhân vật (chống bắt nhầm model trên trời)
            local yDiff = math.abs(mHRP.Position.Y - HRP.Position.Y)
            if yDiff > 35 then return end

            seen[model] = true
            local isBoss = false
            local nameLower = model.Name:lower()
            if nameLower:find("boss") or (mHum.MaxHealth > 5000) then
                isBoss = true
            end

            table.insert(list, {
                model = model,
                root  = mHRP,
                hum   = mHum,
                boss  = isBoss
            })
        end
    end

    -- 1. Ưu tiên quét trong các thư mục Hầm Ngục chính thức
    for _, folderName in ipairs({"Enemies", "Mobs", "Monsters", "DungeonMobs", "Entities", "RoomEnemies", "CurrentRoom"}) do
        local f = workspace:FindFirstChild(folderName, true)
        if f then
            for _, child in ipairs(f:GetChildren()) do addIfRealEnemy(child) end
        end
    end

    -- 2. Quét trong cấu trúc Dungeon / Rooms
    for _, containerName in ipairs({"Dungeon", "Rooms", "Map"}) do
        local container = workspace:FindFirstChild(containerName)
        if container then
            for _, desc in ipairs(container:GetDescendants()) do
                if desc:IsA("Model") and desc:FindFirstChildOfClass("Humanoid") then
                    addIfRealEnemy(desc)
                end
            end
        end
    end

    return list
end

local function isPlayerInLobby()
    -- Nếu có quái thực sự trong bán kính 100 studs -> Chắc chắn đang trong hầm ngục
    local enemies = getRealDungeonEnemies()
    if #enemies > 0 then return false end

    -- Kiểm tra đặc điểm sảnh
    for _, name in ipairs({"Lobby", "SpawnLocation", "TrainingDummy", "Summon", "Gacha", "DungeonPortal", "Shop"}) do
        if workspace:FindFirstChild(name, true) then
            return true
        end
    end
    return true
end

-- ================================================
-- VŨ KHÍ & TẤN CÔNG M1 THỰC THỤ
-- ================================================
local combatRemotesCache = {}
local lastRemoteScan = 0

local function scanRemotes()
    local remotes = {}
    local keywords = {"attack", "hit", "damage", "swing", "slash", "combat", "m1", "skill", "cast", "strike", "weapon"}
    for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local n = obj.Name:lower()
            for _, kw in ipairs(keywords) do
                if n:find(kw) then
                    table.insert(remotes, obj)
                    break
                end
            end
        end
    end
    combatRemotesCache = remotes
    lastRemoteScan = tick()
end
scanRemotes()

local function equipBestWeapon()
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

local function triggerAttackM1(targetModel, targetRoot)
    local now = tick()
    if now - lastM1 < CFG.m1Delay then return end
    lastM1 = now

    equipBestWeapon()

    local vp = Cam.ViewportSize
    local cx, cy = vp.X / 2, vp.Y / 2

    -- 1. Click chuột trái vào giữa màn hình
    pcall(function()
        VirtualInputMgr:SendMouseButtonEvent(cx, cy, 0, true, game, 1)
        task.wait(0.02)
        VirtualInputMgr:SendMouseButtonEvent(cx, cy, 0, false, game, 1)
    end)

    -- 2. Chạm cảm ứng màn hình Mobile
    pcall(function()
        VirtualInputMgr:SendTouchEvent(1, 0, cx, cy)
        task.wait(0.02)
        VirtualInputMgr:SendTouchEvent(1, 2, cx, cy)
    end)

    -- 3. VirtualUser Button1
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:Button1Down(Vector2.new(cx, cy), Cam.CFrame)
        task.wait(0.02)
        VirtualUser:Button1Up(Vector2.new(cx, cy), Cam.CFrame)
    end)

    -- 4. Bấm nút Attack trên màn hình game (nếu có)
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

    -- 5. Kích hoạt Tool
    local tool = Char:FindFirstChildOfClass("Tool")
    if tool then pcall(function() tool:Activate() end) end

    -- 6. Bắn remote combat
    if now - lastRemoteScan > 6 then scanRemotes() end
    for _, r in ipairs(combatRemotesCache) do
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

    -- 7. Xả chiêu thức 1, 2, 3
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

    -- 8. Lướt Dash (Q) né đòn
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
-- HỆ THỐNG TỰ ĐỘNG ĐI BỘ VÀO HẦM NGỤC Ở SẢNH (LOBBY WALK)
-- ================================================
local isNavigatingLobby = false

local function startLobbyWalkToDungeon()
    if isNavigatingLobby then return end
    isNavigatingLobby = true
    State.statusText = "Đang tìm cổng hầm ngục ở sảnh..."
    print("[VOSS] " .. State.statusText)

    -- 1. Tìm vị trí Cổng / Bảng Hầm Ngục gần mặt đất nhất ở sảnh
    local portalTarget = nil
    local minGroundDist = 999999

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local n = obj.Name:lower()
            if (n:find("dungeonportal") or n:find("dungeongate") or n:find("dungeonboard") or n:find("portal") or n:find("gate") or n:find("matchmaking")) and not n:find("exit") then
                local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                if part and HRP then
                    local yDiff = math.abs(part.Position.Y - HRP.Position.Y)
                    if yDiff < 15 then -- Phải nằm sát mặt đất, không được trên trời!
                        local dist = (HRP.Position - part.Position).Magnitude
                        if dist < minGroundDist then
                            portalTarget = part
                            minGroundDist = dist
                        end
                    end
                end
            end
        end
    end

    if portalTarget and HRP then
        State.statusText = "Đang tự đi bộ đến cổng hầm ngục..."
        print("[VOSS] " .. State.statusText)

        -- Đi bộ mượt mà đến cổng trên mặt đất
        local arrived = naturalWalkTo(portalTarget.Position, 3.5, 10)
        task.wait(0.4)

        -- Bước hẳn vào tâm cổng
        if HRP then
            HRP.CFrame = CFrame.new(portalTarget.Position.X, HRP.Position.Y, portalTarget.Position.Z)
            task.wait(0.3)
        end
    end

    -- 2. Kích hoạt ProximityPrompt nếu có
    for _, prompt in ipairs(workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") then
            local pText = (prompt.ActionText .. " " .. prompt.ObjectText):lower()
            if pText:find("enter") or pText:find("play") or pText:find("start") or pText:find("dungeon") or pText:find("vào") then
                pcall(function() fireproximityprompt(prompt) end)
                task.wait(0.3)
            end
        end
    end

    -- 3. Xử lý menu chọn cấp độ hầm ngục
    task.wait(0.8)
    local pGui = LP:FindFirstChild("PlayerGui")
    if pGui then
        State.statusText = "Đang chọn cấp độ: " .. State.targetLevel
        print("[VOSS] " .. State.statusText)

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

        -- 4. Bấm nút Bắt đầu / Solo / Start / Create
        for _, btn in ipairs(pGui:GetDescendants()) do
            if (btn:IsA("TextButton") or btn:IsA("ImageButton")) and btn.Visible then
                local bText = (btn.Name .. " " .. (btn:IsA("TextButton") and btn.Text or "")):lower()
                if bText:find("start") or bText:find("solo") or bText:find("create") or bText:find("play") or bText:find("bắt đầu") or bText:find("ready") or bText:find("confirm") then
                    pcall(function()
                        firesignal(btn.MouseButton1Click)
                        firesignal(btn.Activated)
                    end)
                    State.statusText = "Đã bấm bắt đầu! Đang vào hầm ngục..."
                    print("[VOSS] " .. State.statusText)
                    task.wait(0.4)
                    break
                end
            end
        end
    end

    task.wait(4.0)
    isNavigatingLobby = false
end

-- ================================================
-- VÒNG LẶP ĐIỀU KHIỂN CHÍNH (GROUND COMBAT & PROGRESSION)
-- ================================================
local isBusyWithChest = false
local isBusyWithDoor  = false

RunService.Heartbeat:Connect(function()
    if not HRP or not Hum or Hum.Health <= 0 then return end

    -- ============================================
    -- TRƯỜNG HỢP 1: Ở SẢNH CHỜ (LOBBY)
    -- ============================================
    if isPlayerInLobby() then
        if State.autodungeon and not isNavigatingLobby then
            startLobbyWalkToDungeon()
        else
            if not isNavigatingLobby then
                State.statusText = "Đang ở Sảnh Chờ (Sẵn sàng vào map)"
            end
        end
        return
    end

    -- ============================================
    -- TRƯỜNG HỢP 2: TRONG HẦM NGỤC (DUNGEON)
    -- ============================================
    local realEnemies = getRealDungeonEnemies()

    -- --------------------------------------------
    -- BƯỚC 1: CÒN QUÁI TRONG PHÒNG -> ĐỨNG ĐẤT CHÉM SAU LƯNG
    -- --------------------------------------------
    if #realEnemies > 0 and (State.autofarm or State.autoboss) then
        isBusyWithChest = false
        isBusyWithDoor  = false

        -- Tìm quái gần nhất
        local target = nil
        local bestDist = 999999
        for _, e in ipairs(realEnemies) do
            if not State.autoboss or e.boss then
                local dist = (HRP.Position - e.root.Position).Magnitude
                if dist < bestDist then
                    target = e
                    bestDist = dist
                end
            end
        end
        if not target and State.autoboss then
            target = realEnemies[1]
        end

        if target and target.root and target.hum and target.hum.Health > 0 then
            local mobRoot  = target.root
            local mobCF    = mobRoot.CFrame
            local mobPos   = mobRoot.Position
            local myPos    = HRP.Position

            State.statusText = "Đang chiến đấu: " .. target.model.Name .. " (HP: " .. math.floor(target.hum.Health) .. ")"

            -- Giữ nhân vật ĐỨNG ĐẤT BÌNH THƯỜNG (không bay lên trời!)
            Hum.PlatformStand = false

            -- Tính vị trí sau lưng quái TRÊN MẶT ĐẤT
            local behindPos = mobPos - (mobCF.LookVector * 2.0)
            -- Đảm bảo độ cao Y trùng với mặt đất chân quái
            behindPos = Vector3.new(behindPos.X, mobPos.Y, behindPos.Z)

            local distToMob = (myPos - behindPos).Magnitude

            if distToMob > 5.0 then
                -- Nếu còn cách xa hơn 5 studs: Tự đi bộ tiếp cận nhanh chóng
                Hum:MoveTo(behindPos)
            else
                -- Khi đã áp sát trong phạm vi 5 studs: Đứng vững sau lưng, mặt quay thẳng vào quái
                HRP.AssemblyLinearVelocity = Vector3.zero
                HRP.CFrame = CFrame.lookAt(behindPos, Vector3.new(mobPos.X, behindPos.Y, mobPos.Z))
            end

            -- Kích hoạt đòn chém M1 và chiêu thức
            triggerAttackM1(target.model, mobRoot)
            return
        end
    end

    -- --------------------------------------------
    -- BƯỚC 2: PHÒNG SẠCH QUÁI -> TỰ ĐI BỘ NHẶT RƯƠNG
    -- --------------------------------------------
    if #realEnemies == 0 and State.autochest and not isBusyWithChest and not isBusyWithDoor then
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
            isBusyWithChest = true
            State.statusText = "Đang đi bộ nhặt rương kho báu..."
            naturalWalkTo(chestPart.Position, 3.0, 5.0)

            local prompt = chestPart:FindFirstChildOfClass("ProximityPrompt") or chestPart.Parent:FindFirstChildOfClass("ProximityPrompt")
            if prompt then pcall(function() fireproximityprompt(prompt) end) end
            task.wait(0.6)
            isBusyWithChest = false
            return
        end
    end

    -- --------------------------------------------
    -- BƯỚC 3: PHÒNG SẠCH QUÁI -> TỰ ĐI BỘ RA CỬA QUA ẢI
    -- --------------------------------------------
    if #realEnemies == 0 and State.autodoor and not isBusyWithDoor then
        isBusyWithDoor = true

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
            State.statusText = "Đang đi bộ qua cửa phòng tiếp theo..."
            naturalWalkTo(doorPart.Position, 3.0, 6.0)

            local prompt = doorPart:FindFirstChildOfClass("ProximityPrompt") or doorPart.Parent:FindFirstChildOfClass("ProximityPrompt")
            if prompt then pcall(function() fireproximityprompt(prompt) end) end
        end

        -- Xác nhận nút Vote trên màn hình
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
        isBusyWithDoor = false
    end

    -- --------------------------------------------
    -- BƯỚC 4: HOÀN THÀNH HẦM NGỤC -> TỰ CHƠI LẠI (REPLAY)
    -- --------------------------------------------
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
                        State.statusText = "Hầm ngục hoàn tất! Đang chơi lại..."
                        task.wait(0.5)
                        break
                    end
                end
            end
        end
    end
end)

-- ================================================
-- HỆ THỐNG BAY 3D MOBILE [▲ Lên] [▼ Xuống]
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
FloatBtn.Text             = "⚔️\nVOSS"
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
Title.Text               = "VOSS | Thợ Săn Hầm Ngục v3 ⚔️"
Title.TextColor3         = Color3.fromRGB(220, 180, 255)
Title.Font               = Enum.Font.GothamBold
Title.TextSize           = 14
Title.TextXAlignment     = Enum.TextXAlignment.Left

local SubTitle = Instance.new("TextLabel", Header)
SubTitle.Size               = UDim2.new(1, -50, 0, 16)
SubTitle.Position           = UDim2.new(0, 16, 0, 28)
SubTitle.BackgroundTransparency = 1
SubTitle.Text               = "Đứng Đất Chém Sau Lưng • Tự Đi Bộ Vào Map"
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

-- Thanh hiển thị Trạng thái trực tiếp (Status Banner)
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

-- Cập nhật trạng thái theo chu kỳ
task.spawn(function()
    while task.wait(0.5) do
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

local function createToggle(title, desc, defaultState, callback, order)
    local f = Instance.new("Frame", Scroll)
    f.Size             = UDim2.new(1, -6, 0, 48)
    f.BackgroundColor3 = Color3.fromRGB(20, 18, 32)
    f.LayoutOrder      = order
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)

    local stroke = Instance.new("UIStroke", f)
    stroke.Color = defaultState and Color3.fromRGB(130, 70, 240) or Color3.fromRGB(45, 40, 65)
    stroke.Thickness = 1

    local tLbl = Instance.new("TextLabel", f)
    tLbl.Size               = UDim2.new(1, -65, 0, 22)
    tLbl.Position           = UDim2.new(0, 12, 0, 5)
    tLbl.BackgroundTransparency = 1
    tLbl.Text               = title
    tLbl.TextColor3         = Color3.fromRGB(230, 225, 250)
    tLbl.Font               = Enum.Font.GothamBold
    tLbl.TextSize           = 13
    tLbl.TextXAlignment     = Enum.TextXAlignment.Left

    local dLbl = Instance.new("TextLabel", f)
    dLbl.Size               = UDim2.new(1, -65, 0, 16)
    dLbl.Position           = UDim2.new(0, 12, 0, 26)
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

local function createBigButton(title, desc, color, callback, order)
    local btn = Instance.new("TextButton", Scroll)
    btn.Size             = UDim2.new(1, -6, 0, 50)
    btn.BackgroundColor3 = color or Color3.fromRGB(80, 40, 160)
    btn.LayoutOrder      = order
    btn.Text             = ""
    btn.AutoButtonColor  = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)

    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = Color3.fromRGB(160, 100, 255); stroke.Thickness = 1.5

    local tLbl = Instance.new("TextLabel", btn)
    tLbl.Size               = UDim2.new(1, -20, 0, 24)
    tLbl.Position           = UDim2.new(0, 12, 0, 4)
    tLbl.BackgroundTransparency = 1
    tLbl.Text               = title
    tLbl.TextColor3         = Color3.fromRGB(255, 255, 255)
    tLbl.Font               = Enum.Font.GothamBold
    tLbl.TextSize           = 13
    tLbl.TextXAlignment     = Enum.TextXAlignment.Left

    local dLbl = Instance.new("TextLabel", btn)
    dLbl.Size               = UDim2.new(1, -20, 0, 16)
    dLbl.Position           = UDim2.new(0, 12, 0, 26)
    dLbl.BackgroundTransparency = 1
    dLbl.Text               = desc
    dLbl.TextColor3         = Color3.fromRGB(210, 190, 250)
    dLbl.Font               = Enum.Font.Gotham
    dLbl.TextSize           = 10
    dLbl.TextXAlignment     = Enum.TextXAlignment.Left

    btn.MouseButton1Click:Connect(function()
        callback()
    end)
    return btn
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
    tLbl.Text               = "🎯 Chọn Cấp Hầm Ngục Muốn Đi:"
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

-- NHÓM 1: ĐI BỘ VÀO HẦM NGỤC Ở SẢNH
createCategory("🏛️ TẠI SẢNH CHỜ (LOBBY)", 1)

createLevelSelector(2)

createBigButton("▶ TỰ ĐI BỘ VÀO HẦM NGỤC", "Tự đi bộ đến cổng sảnh, mở bảng, chọn cấp & vào map", Color3.fromRGB(90, 45, 180), function()
    task.spawn(function()
        startLobbyWalkToDungeon()
    end)
end, 3)

createToggle("Tự Vào Lại Khi Về Sảnh", "Tự động đi bộ vào hầm ngục tiếp mỗi khi về lại sảnh", State.autodungeon, function(val)
    State.autodungeon = val
end, 4)

-- NHÓM 2: TRONG HẦM NGỤC (GROUND COMBAT)
createCategory("⚔️ TRONG HẦM NGỤC (GROUND COMBAT)", 10)

createToggle("Auto Farm (Đứng Đất Chém Sau Lưng)", "Đứng sát mặt đất 2 studs sau lưng quái chém M1 (Không bay trời)", State.autofarm, function(val)
    State.autofarm = val
end, 11)

createToggle("Ưu Tiên Săn Boss", "Tập trung diệt Boss phòng trước", State.autoboss, function(val)
    State.autoboss = val
end, 12)

createToggle("Auto Xả Kỹ Năng (1, 2, 3)", "Tự động kích hoạt chiêu thức dồn sát thương liên tục", State.autoskill, function(val)
    State.autoskill = val
end, 13)

createToggle("Auto Lướt Dash (Q) Né Đòn", "Lướt né chiêu diện rộng của quái", State.autodash, function(val)
    State.autodash = val
end, 14)

createToggle("Auto Đi Bộ Qua Cửa (Next Room)", "Chỉ khi phòng sạch quái mới tự đi bộ qua cửa phòng tiếp", State.autodoor, function(val)
    State.autodoor = val
end, 15)

createToggle("Auto Đi Bộ Nhặt Rương", "Sau khi sạch quái tự đi bộ nhặt rương kho báu & vàng", State.autochest, function(val)
    State.autochest = val
end, 16)

createToggle("Auto Chơi Lại (Replay)", "Thắng trận tự bấm Replay tạo vòng lặp cày vô tận", State.autoreplay, function(val)
    State.autoreplay = val
end, 17)

-- NHÓM 3: BỔ TRỢ NHÂN VẬT & BAY LƯỢN MOBILE
createCategory("⚡ BỔ TRỢ NHÂN VẬT & BAY LƯỢN", 20)

createToggle("Tốc Độ Chạy Cao (Speed 55)", "Tăng tốc độ chạy bộ mượt mà", State.speed, function(val)
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

-- NHÓM 4: RADAR ĐỊNH VỊ
createCategory("👁️ RADAR ĐỊNH VỊ (ESP)", 30)

createToggle("ESP Quái & Boss", "Hiện tên quái (Đỏ) và Boss (Vàng) xuyên tường", State.esp_mobs, function(val)
    State.esp_mobs = val
    if not val then clearESP() end
end, 31)

createToggle("ESP Rương Kho Báu", "Hiện vị trí toàn bộ rương kho báu trong phòng", State.esp_chests, function(val)
    State.esp_chests = val
    if not val then clearESP() end
end, 32)

-- CỬ CHỈ ĐIỀU KHIỂN CẢM ỨNG 3 NGÓN
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

print("[VOSS] Dungeon Hunters Hub v3.0 (Ground Navigation Edition) Loaded Successfully! ⚔️")
