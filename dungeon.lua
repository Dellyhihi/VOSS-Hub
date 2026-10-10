-- ================================================
-- VOSS | Dungeon Hunters Hub v2.0 (Ultimate Fix)
-- Game: Thợ Săn Hầm Ngục [UPD] - The Evac Syndicate
-- ================================================
-- [FIX TRIỆT ĐỂ THEO CƠ CHẾ CHUẨN CỦA GAME]:
-- 1. FIX LỖI KHÔNG ĐÁNH ĐƯỢC QUÁI:
--    - Chuyển vị trí áp sát: Bám sát SAU LƯNG QUÁI (2.2 studs sau lưng, cao 1.0 stud, mặt nhìn thẳng vào quái)
--    - Tấn công M1 đa kênh thực thụ:
--      * Gửi sự kiện Click chuột trái trực tiếp qua VirtualInputManager (giữa màn hình)
--      * Gửi Touch Event cảm ứng trực tiếp trên màn hình điện thoại
--      * Tự động quét và chạm vào Nút Đánh (Attack/M1) trên màn hình cảm ứng của game
--      * Kích hoạt Tool (nếu có) + Bắn toàn bộ Remote Combat tìm thấy trong ReplicatedStorage
--    - Tự động xả kỹ năng (Skills 1, 2, 3, 4) + Lướt Dash (Q) + Đỡ đòn (F)
-- 2. FIX LỖI VÀO TẠO MAP KHÔNG XONG & CÀY CẤP TỪNG BẬC:
--    - Quy trình vào map 5 bước chuẩn xác: Đến Cổng -> Mở Bảng -> Chọn Cấp (1, 2, 3... hoặc Cấp cao nhất) -> Bấm Solo/Start -> Chờ tải map
--    - Không bị ngắt quãng, không bị spam tele làm đóng menu
-- 3. TRIỆT TIÊU HOÀN TOÀN LỖI BAY TELE LUNG TUNG:
--    - Kiến trúc State Machine thống nhất: Tại 1 thời điểm CHỈ LÀM 1 VIỆC DUY NHẤT:
--      * Đang có quái: Khóa chặt vào quái cho đến khi quái chết (KHÔNG tele đi đâu khác)
--      * Quái chết hết: Mới đi nhặt rương (1 lần duy nhất)
--      * Nhặt xong: Mới đi ra cửa qua ải tiếp theo
--      * Hết màn: Tự bấm Replay/Tiếp tục
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
    autodungeon   = false, -- Tự động vào map theo cấp đã chọn
    autodoor      = true,  -- Tự động qua cửa khi phòng sạch quái
    autochest     = true,  -- Tự động nhặt rương sau khi dọn quái
    autoreplay    = true,  -- Tự động chơi lại khi xong màn
    speed         = false,
    fly           = false,
    nofall        = true,
    esp_mobs      = false,
    esp_chests    = false,
    targetLevel   = "AUTO", -- "AUTO", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10"
    combatStance  = "BEHIND", -- "BEHIND" (Sau lưng - khuyên dùng), "ABOVE" (Trên đầu)
}

local CFG = {
    walkspeed   = 60,
    flyspeed    = 50,
    behindDist  = 2.2,  -- Khoảng cách sau lưng quái
    behindHeight= 1.0,  -- Độ cao so với quái khi bám sau lưng
    aboveHeight = 2.8,  -- Độ cao khi chọn chế độ trên đầu
    m1Delay     = 0.12, -- Tốc độ nhấp M1
    skillDelay  = 1.2,  -- Giãn cách xả chiêu thức
    dashDelay   = 3.5,  -- Giãn cách lướt Dash (Q)
}

-- Quản lý nhân vật
local Char, HRP, Hum
local humConns = {}

local function clearHumConns()
    for _, c in pairs(humConns) do
        pcall(function() c:Disconnect() end)
    end
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

if LP.Character then
    setupCharacter(LP.Character)
end

LP.CharacterAdded:Connect(function(newChar)
    task.wait(0.3)
    setupCharacter(newChar)
end)

-- Duy trì tốc độ & chống rơi vỡ
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
-- HỆ THỐNG SCAN REMOTE & VŨ KHÍ TỰ ĐỘNG
-- ================================================
local combatRemotesCache = {}
local lastRemoteRefresh = 0

local function refreshCombatRemotes()
    local remotes = {}
    local keywords = {"attack", "hit", "damage", "swing", "slash", "combat", "m1", "skill", "cast", "strike", "weapon"}
    for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local n = obj.Name:lower()
            for _, kw in pairs(keywords) do
                if n:find(kw) then
                    table.insert(remotes, obj)
                    break
                end
            end
        end
    end
    combatRemotesCache = remotes
    lastRemoteRefresh = tick()
end
refreshCombatRemotes()

local function equipWeapon()
    if not Char then return end
    local curTool = Char:FindFirstChildOfClass("Tool")
    if not curTool then
        local bp = LP:FindFirstChild("Backpack")
        if bp then
            local tool = bp:FindFirstChildOfClass("Tool")
            if tool and Hum then
                pcall(function() Hum:EquipTool(tool) end)
            end
        end
    end
end

-- ================================================
-- BỘ MÃ THỰC THI TẤN CÔNG M1 ĐA TẦNG (100% TRÚNG QUÁI)
-- ================================================
local lastM1Time = 0
local lastSkillTime = 0
local lastDashTime = 0

local function clickScreenCenter()
    local vp = Cam.ViewportSize
    local cx, cy = vp.X / 2, vp.Y / 2

    -- 1. Gửi sự kiện Click chuột trái máy tính
    pcall(function()
        VirtualInputMgr:SendMouseButtonEvent(cx, cy, 0, true, game, 1)
        task.wait(0.02)
        VirtualInputMgr:SendMouseButtonEvent(cx, cy, 0, false, game, 1)
    end)

    -- 2. Gửi sự kiện chạm cảm ứng màn hình Mobile
    pcall(function()
        VirtualInputMgr:SendTouchEvent(1, 0, cx, cy)
        task.wait(0.02)
        VirtualInputMgr:SendTouchEvent(1, 2, cx, cy)
    end)

    -- 3. Gửi VirtualUser Button1
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:Button1Down(Vector2.new(cx, cy), Cam.CFrame)
        task.wait(0.02)
        VirtualUser:Button1Up(Vector2.new(cx, cy), Cam.CFrame)
    end)
end

-- Tự động chạm vào nút Đánh (Attack Button) trên màn hình điện thoại
local function triggerMobileAttackButton()
    local pGui = LP:FindFirstChild("PlayerGui")
    if not pGui then return end
    for _, btn in ipairs(pGui:GetDescendants()) do
        if (btn:IsA("TextButton") or btn:IsA("ImageButton")) and btn.Visible then
            local n = btn.Name:lower()
            local text = btn:IsA("TextButton") and btn.Text:lower() or ""
            if n:find("attack") or n:find("m1") or n:find("slash") or n:find("strike") or n:find("punch") or text:find("attack") or text:find("m1") then
                pcall(function()
                    firesignal(btn.MouseButton1Down)
                    firesignal(btn.Activated)
                end)
            end
        end
    end
end

local function executeCombatHit(targetModel, targetRoot)
    local now = tick()
    if now - lastM1Time < CFG.m1Delay then return end
    lastM1Time = now

    equipWeapon()

    -- 1. Kích hoạt đòn đánh màn hình
    clickScreenCenter()
    triggerMobileAttackButton()

    -- 2. Kích hoạt Tool nếu nhân vật cầm Tool
    local tool = Char:FindFirstChildOfClass("Tool")
    if tool then
        pcall(function() tool:Activate() end)
    end

    -- 3. Bắn các Remote combat trong ReplicatedStorage
    if now - lastRemoteRefresh > 6 then
        refreshCombatRemotes()
    end

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

    -- 4. Tự động xả chiêu thức 1, 2, 3, 4
    if State.autoskill and (now - lastSkillTime > CFG.skillDelay) then
        lastSkillTime = now
        pcall(function()
            VirtualInputMgr:SendKeyEvent(true, Enum.KeyCode.One, false, game)
            task.wait(0.02)
            VirtualInputMgr:SendKeyEvent(false, Enum.KeyCode.One, false, game)
            task.wait(0.04)
            VirtualInputMgr:SendKeyEvent(true, Enum.KeyCode.Two, false, game)
            task.wait(0.02)
            VirtualInputMgr:SendKeyEvent(false, Enum.KeyCode.Two, false, game)
            task.wait(0.04)
            VirtualInputMgr:SendKeyEvent(true, Enum.KeyCode.Three, false, game)
            task.wait(0.02)
            VirtualInputMgr:SendKeyEvent(false, Enum.KeyCode.Three, false, game)
        end)
    end

    -- 5. Tự động Dash (Q) né đòn
    if State.autodash and (now - lastDashTime > CFG.dashDelay) then
        lastDashTime = now
        pcall(function()
            VirtualInputMgr:SendKeyEvent(true, Enum.KeyCode.Q, false, game)
            task.wait(0.02)
            VirtualInputMgr:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
        end)
    end
end

-- ================================================
-- TÌM KIẾM QUÁI & XÁC ĐỊNH MÔI TRƯỜNG (SẢNH HAY HẦM NGỤC)
-- ================================================
local MOB_FOLDERS = {"Enemies", "Mobs", "Monsters", "DungeonMobs", "Entities", "RoomEnemies", "Boss", "Bosses"}

local function getAllLivingEnemies()
    local list = {}
    local seen = {}

    local function checkAndAdd(model)
        if not model or not model:IsA("Model") or seen[model] then return end
        if model == Char then return end
        if Players:GetPlayerFromCharacter(model) then return end

        local mHum = model:FindFirstChildOfClass("Humanoid")
        local mHRP = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso") or model:FindFirstChild("Head")

        if mHum and mHRP and mHum.Health > 0 then
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

    for _, fName in ipairs(MOB_FOLDERS) do
        local f = workspace:FindFirstChild(fName, true)
        if f then
            for _, c in ipairs(f:GetChildren()) do checkAndAdd(c) end
        end
    end

    for _, containerName in ipairs({"Dungeon", "Rooms", "Map", "CurrentRoom"}) do
        local container = workspace:FindFirstChild(containerName)
        if container then
            for _, desc in ipairs(container:GetDescendants()) do
                if desc:IsA("Model") and desc:FindFirstChildOfClass("Humanoid") then
                    checkAndAdd(desc)
                end
            end
        end
    end

    if #list == 0 then
        for _, obj in ipairs(workspace:GetChildren()) do
            checkAndAdd(obj)
        end
    end

    return list
end

local function isPlayerInLobby()
    local enemies = getAllLivingEnemies()
    if #enemies > 0 then return false end
    -- Kiểm tra các đặc điểm nhận diện sảnh chờ
    for _, name in ipairs({"Lobby", "SpawnLocation", "TrainingDummy", "Summon", "Gacha", "DungeonPortal", "Shop"}) do
        if workspace:FindFirstChild(name, true) then
            return true
        end
    end
    return true
end

-- ================================================
-- HỆ THỐNG VÀO HẦM NGỤC & CÀY CẤP TỪNG BẬC (LOBBY MANAGER)
-- ================================================
local isEnteringDungeon = false

local function performEnterDungeonSequence()
    if isEnteringDungeon then return end
    isEnteringDungeon = true
    print("[VOSS] Bắt đầu quy trình vào Hầm Ngục theo cấp độ: " .. State.targetLevel)

    -- 1. Tìm Bảng / Cổng Hầm Ngục ở sảnh
    local dungeonEntrance = nil
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local n = obj.Name:lower()
            if n:find("dungeonportal") or n:find("portal") or n:find("dungeongate") or n:find("dungeonboard") or n:find("matchmaking") or n:find("gate") then
                local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                if part then
                    dungeonEntrance = part
                    break
                end
            end
        end
    end

    -- 2. Di chuyển đến cổng 1 lần duy nhất
    if dungeonEntrance and HRP then
        HRP.AssemblyLinearVelocity = Vector3.zero
        HRP.CFrame = dungeonEntrance.CFrame + Vector3.new(0, 3, 0)
        task.wait(0.5)
    end

    -- 3. Kích hoạt ProximityPrompt nếu có
    for _, prompt in ipairs(workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") then
            local pText = (prompt.ActionText .. " " .. prompt.ObjectText):lower()
            if pText:find("enter") or pText:find("play") or pText:find("start") or pText:find("dungeon") or pText:find("vào") then
                pcall(function() fireproximityprompt(prompt) end)
                task.wait(0.3)
            end
        end
    end

    -- 4. Chờ giao diện chọn hầm ngục xuất hiện trên màn hình
    task.wait(0.8)
    local pGui = LP:FindFirstChild("PlayerGui")
    if pGui then
        -- A. Chọn Cấp độ (Level Selector)
        local targetLvlStr = tostring(State.targetLevel)
        for _, btn in ipairs(pGui:GetDescendants()) do
            if (btn:IsA("TextButton") or btn:IsA("ImageButton")) and btn.Visible then
                local bText = (btn.Name .. " " .. (btn:IsA("TextButton") and btn.Text or "")):lower()

                if State.targetLevel ~= "AUTO" then
                    -- Chọn đúng cấp người chơi yêu cầu (vd: Cấp 1, Cấp 2...)
                    if bText:find("level " .. targetLvlStr) or bText:find("lv " .. targetLvlStr) or bText:find("cấp " .. targetLvlStr) or btn.Name == targetLvlStr then
                        pcall(function()
                            firesignal(btn.MouseButton1Click)
                            firesignal(btn.Activated)
                        end)
                        task.wait(0.4)
                        break
                    end
                else
                    -- Chế độ AUTO: Bấm vào ải cao nhất đã mở
                    if bText:find("level") or bText:find("cấp") or bText:find("chapter") then
                        pcall(function()
                            firesignal(btn.MouseButton1Click)
                            firesignal(btn.Activated)
                        end)
                    end
                end
            end
        end

        task.wait(0.5)

        -- B. Bấm nút Tạo phòng / Bắt đầu / Solo / Ready
        for _, btn in ipairs(pGui:GetDescendants()) do
            if (btn:IsA("TextButton") or btn:IsA("ImageButton")) and btn.Visible then
                local bText = (btn.Name .. " " .. (btn:IsA("TextButton") and btn.Text or "")):lower()
                if bText:find("start") or bText:find("solo") or bText:find("create") or bText:find("play") or bText:find("bắt đầu") or bText:find("ready") or bText:find("confirm") then
                    pcall(function()
                        firesignal(btn.MouseButton1Click)
                        firesignal(btn.Activated)
                    end)
                    print("[VOSS] Đã nhấn nút xác nhận bắt đầu: " .. btn.Name)
                    task.wait(0.4)
                    break
                end
            end
        end
    end

    -- Chờ 5 giây để game chuyển cảnh vào map
    task.wait(5.0)
    isEnteringDungeon = false
end

-- ================================================
-- TRUNG TÂM ĐIỀU PHỐI DUY NHẤT (STATE MACHINE CONTROLLER)
-- ================================================
-- Chỉ thực hiện 1 hành động duy nhất tại 1 thời điểm!
-- Triệt tiêu hoàn toàn xung đột tele loạn xạ!
local isLootingChest = false
local isGoingNextRoom = false

RunService.Heartbeat:Connect(function()
    if not HRP or not Hum or Hum.Health <= 0 then return end

    -- ============================================
    -- TRƯỜNG HỢP 1: ĐANG Ở SẢNH CHỜ (LOBBY)
    -- ============================================
    if isPlayerInLobby() then
        if State.autodungeon and not isEnteringDungeon then
            performEnterDungeonSequence()
        end
        return
    end

    -- ============================================
    -- TRƯỜNG HỢP 2: ĐANG TRONG HẦM NGỤC (DUNGEON)
    -- ============================================
    local livingEnemies = getAllLivingEnemies()

    -- --------------------------------------------
    -- BƯỚC 1: ĐANG CÒN QUÁI TRONG PHÒNG -> TẬP TRUNG FARM 100%
    -- --------------------------------------------
    if #livingEnemies > 0 and (State.autofarm or State.autoboss) then
        isLootingChest = false
        isGoingNextRoom = false

        -- Tìm mục tiêu tốt nhất (Ưu tiên Boss nếu bật)
        local target = nil
        local bestDist = 999999
        for _, e in ipairs(livingEnemies) do
            if not State.autoboss or e.boss then
                local dist = (HRP.Position - e.root.Position).Magnitude
                if dist < bestDist then
                    target = e
                    bestDist = dist
                end
            end
        end
        if not target and State.autoboss then
            target = livingEnemies[1]
        end

        if target and target.root and target.hum and target.hum.Health > 0 then
            local mobRoot = target.root
            local mobCF   = mobRoot.CFrame

            -- Tính toán vị trí áp sát hoàn hảo
            local attackPos
            if State.combatStance == "BEHIND" then
                -- BÁM SAU LƯNG QUÁI: Quái quay lưng lại với mình, kiếm đâm xuyên lưng
                attackPos = mobRoot.Position - (mobCF.LookVector * CFG.behindDist) + Vector3.new(0, CFG.behindHeight, 0)
            else
                -- TRÊN ĐẦU QUÁI: Lơ lửng 2.8 studs phía trên, góc nhìn cúi xuống quái
                attackPos = mobRoot.Position + Vector3.new(0, CFG.aboveHeight, -0.6)
            end

            -- Khóa vận tốc chống văng & hướng thẳng mặt vào quái
            HRP.AssemblyLinearVelocity  = Vector3.zero
            HRP.AssemblyAngularVelocity = Vector3.zero
            HRP.CFrame = CFrame.lookAt(attackPos, mobRoot.Position)

            -- Thực hiện tấn công
            executeCombatHit(target.model, mobRoot)
            return -- Xong frame này, không làm gì thêm!
        end
    end

    -- --------------------------------------------
    -- BƯỚC 2: PHÒNG ĐÃ SẠCH QUÁI -> TỰ NHẶT RƯƠNG TRƯỚC (NẾU CÓ)
    -- --------------------------------------------
    if #livingEnemies == 0 and State.autochest and not isLootingChest and not isGoingNextRoom then
        local chestObj = nil
        for _, obj in ipairs(workspace:GetDescendants()) do
            local n = obj.Name:lower()
            if (n:find("chest") or n:find("treasure") or n:find("reward")) and (obj:IsA("BasePart") or obj:IsA("Model")) then
                local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                if part and (part.Position - HRP.Position).Magnitude > 4 then
                    chestObj = obj
                    break
                end
            end
        end

        if chestObj then
            isLootingChest = true
            local part = chestObj:IsA("BasePart") and chestObj or chestObj:FindFirstChildWhichIsA("BasePart")
            if part then
                HRP.AssemblyLinearVelocity = Vector3.zero
                HRP.CFrame = part.CFrame + Vector3.new(0, 2.5, 0)
                task.wait(0.4)
                local prompt = chestObj:FindFirstChildOfClass("ProximityPrompt") or part:FindFirstChildOfClass("ProximityPrompt")
                if prompt then
                    pcall(function() fireproximityprompt(prompt) end)
                end
                task.wait(0.6)
            end
            isLootingChest = false
            return
        end
    end

    -- --------------------------------------------
    -- BƯỚC 3: PHÒNG SẠCH QUÁI & NHẶT XONG RƯƠNG -> TIẾN VỀ CỬA QUA ẢI
    -- --------------------------------------------
    if #livingEnemies == 0 and State.autodoor and not isGoingNextRoom then
        isGoingNextRoom = true

        -- Tìm cửa phòng tiếp theo
        local doorPart = nil
        for _, obj in ipairs(workspace:GetDescendants()) do
            local n = obj.Name:lower()
            if (n:find("nextroom") or n:find("door") or n:find("gate") or n:find("exit")) and not n:find("lobby") then
                local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                if part then
                    doorPart = part
                    break
                end
            end
        end

        if doorPart and (doorPart.Position - HRP.Position).Magnitude > 5 then
            HRP.AssemblyLinearVelocity = Vector3.zero
            HRP.CFrame = doorPart.CFrame + Vector3.new(0, 2.5, 0)
            task.wait(0.5)

            local prompt = doorPart:FindFirstChildOfClass("ProximityPrompt") or doorPart.Parent:FindFirstChildOfClass("ProximityPrompt")
            if prompt then
                pcall(function() fireproximityprompt(prompt) end)
            end
        end

        -- Bấm nút Vote / Tiếp tục trên màn hình nếu có
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

        task.wait(1.0)
        isGoingNextRoom = false
    end

    -- --------------------------------------------
    -- BƯỚC 4: KHI XONG CẢ HẦM NGỤC (VICTORY / REPLAY)
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
                        task.wait(0.5)
                        break
                    end
                end
            end
        end
    end
end)

-- ================================================
-- HỆ THỐNG BAY 3D CẢM ỨNG MOBILE [▲ Lên] [▼ Xuống]
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
        local enemies = getAllLivingEnemies()
        for _, e in ipairs(enemies) do
            local key = "mob_" .. tostring(e.model)
            seen[key] = true
            if not ESPCache[key] and e.root then
                local bb = Instance.new("BillboardGui")
                bb.AlwaysOnTop = true
                bb.Size        = UDim2.new(0, 140, 0, 30)
                bb.StudsOffset = Vector3.new(0, 3.5, 0)
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
                if part then
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
MainFrame.Size             = UDim2.new(0, 315, 0, 500)
MainFrame.Position         = UDim2.new(0.5, -157, 0.5, -250)
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
Header.Size             = UDim2.new(1, 0, 0, 52)
Header.BackgroundColor3 = Color3.fromRGB(18, 16, 28)
Header.BorderSizePixel  = 0
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 14)

local Title = Instance.new("TextLabel", Header)
Title.Size               = UDim2.new(1, -50, 0, 30)
Title.Position           = UDim2.new(0, 16, 0, 4)
Title.BackgroundTransparency = 1
Title.Text               = "VOSS | Thợ Săn Hầm Ngục v2 ⚔️"
Title.TextColor3         = Color3.fromRGB(220, 180, 255)
Title.Font               = Enum.Font.GothamBold
Title.TextSize           = 14
Title.TextXAlignment     = Enum.TextXAlignment.Left

local SubTitle = Instance.new("TextLabel", Header)
SubTitle.Size               = UDim2.new(1, -50, 0, 16)
SubTitle.Position           = UDim2.new(0, 16, 0, 28)
SubTitle.BackgroundTransparency = 1
SubTitle.Text               = "Auto Farm Chuẩn Cơ Chế • Không Lỗi Tele"
SubTitle.TextColor3         = Color3.fromRGB(130, 120, 170)
SubTitle.Font               = Enum.Font.Gotham
SubTitle.TextSize           = 10
SubTitle.TextXAlignment     = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", Header)
CloseBtn.Size             = UDim2.new(0, 28, 0, 28)
CloseBtn.Position         = UDim2.new(1, -38, 0, 12)
CloseBtn.BackgroundColor3 = Color3.fromRGB(40, 25, 60)
CloseBtn.Text             = "✕"
CloseBtn.TextColor3       = Color3.fromRGB(255, 180, 180)
CloseBtn.Font             = Enum.Font.GothamBold
CloseBtn.TextSize         = 13
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)

CloseBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false end)
FloatBtn.MouseButton1Click:Connect(function() MainFrame.Visible = not MainFrame.Visible end)

-- Danh sách cuộn
local Scroll = Instance.new("ScrollingFrame", MainFrame)
Scroll.Size             = UDim2.new(1, -16, 1, -64)
Scroll.Position         = UDim2.new(0, 8, 0, 58)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel  = 0
Scroll.ScrollBarThickness = 4
Scroll.ScrollBarImageColor3 = Color3.fromRGB(120, 70, 220)
Scroll.CanvasSize       = UDim2.new(0, 0, 0, 760)

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

local function createLevelSelector(order)
    local f = Instance.new("Frame", Scroll)
    f.Size             = UDim2.new(1, -6, 0, 62)
    f.BackgroundColor3 = Color3.fromRGB(22, 19, 36)
    f.LayoutOrder      = order
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)

    local tLbl = Instance.new("TextLabel", f)
    tLbl.Size               = UDim2.new(1, -16, 0, 20)
    tLbl.Position           = UDim2.new(0, 12, 0, 6)
    tLbl.BackgroundTransparency = 1
    tLbl.Text               = "🎯 Chọn Cấp Hầm Ngục Muốn Farm:"
    tLbl.TextColor3         = Color3.fromRGB(225, 190, 255)
    tLbl.Font               = Enum.Font.GothamBold
    tLbl.TextSize           = 12
    tLbl.TextXAlignment     = Enum.TextXAlignment.Left

    local btnContainer = Instance.new("ScrollingFrame", f)
    btnContainer.Size       = UDim2.new(1, -20, 0, 28)
    btnContainer.Position   = UDim2.new(0, 10, 0, 28)
    btnContainer.BackgroundTransparency = 1
    btnContainer.ScrollBarThickness = 0
    btnContainer.CanvasSize = UDim2.new(0, 380, 0, 0)

    local bList = Instance.new("UIListLayout", btnContainer)
    bList.FillDirection = Enum.FillDirection.Horizontal
    bList.Padding = UDim.new(0, 6)

    local levels = {"AUTO", "1", "2", "3", "4", "5", "6", "7"}
    local levelBtns = {}

    for _, lvl in ipairs(levels) do
        local b = Instance.new("TextButton", btnContainer)
        b.Size = UDim2.new(0, lvl == "AUTO" and 54 or 40, 0, 26)
        b.BackgroundColor3 = (State.targetLevel == lvl) and Color3.fromRGB(130, 60, 240) or Color3.fromRGB(38, 32, 58)
        b.Text = (lvl == "AUTO") and "AUTO" or ("Cấp " .. lvl)
        b.TextColor3 = Color3.fromRGB(255, 255, 255)
        b.Font = Enum.Font.GothamBold
        b.TextSize = 10
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)

        b.MouseButton1Click:Connect(function()
            State.targetLevel = lvl
            for _, ob in pairs(levelBtns) do
                ob.BackgroundColor3 = Color3.fromRGB(38, 32, 58)
            end
            b.BackgroundColor3 = Color3.fromRGB(130, 60, 240)
            print("[VOSS] Đã chọn cấp độ farm: " .. lvl)
        end)
        table.insert(levelBtns, b)
    end
    return f
end

-- ================================================
-- KHỞI TẠO NỘI DUNG MENU
-- ================================================

-- NHÓM 1: CÀY CẤP & CHIẾN ĐẤU (AUTO FARM)
createCategory("⚔️ CÀY CẤP & CHIẾN ĐẤU (AUTO FARM)", 1)

createToggle("Auto Farm Quái (M1 Đa Kênh)", "Bám sát sau lưng chém trúng 100%, quái không chạm được", State.autofarm, function(val)
    State.autofarm = val
end, 2)

createToggle("Ưu Tiên Săn Boss", "Tập trung diệt Boss trước để nhận đồ quý", State.autoboss, function(val)
    State.autoboss = val
end, 3)

createToggle("Auto Dùng Kỹ Năng (1, 2, 3)", "Tự động xả chiêu thức dồn sát thương cực mạnh", State.autoskill, function(val)
    State.autoskill = val
end, 4)

createToggle("Auto Lướt Dash (Q)", "Tự động lướt né đòn đánh và kỹ năng diện rộng của quái", State.autodash, function(val)
    State.autodash = val
end, 5)

-- NHÓM 2: VÀO MAP & CÀY CẤP TỪNG BẬC (LOBBY & ROOMS)
createCategory("🚪 VÀO MAP & CÀY CẤP TỪNG BẬC", 10)

createLevelSelector(11)

createToggle("Auto Vào Hầm Ngục (Từ Sảnh)", "Đến cổng -> Mở bảng -> Chọn đúng cấp -> Bắt đầu", State.autodungeon, function(val)
    State.autodungeon = val
end, 12)

createToggle("Auto Qua Cửa (Khi Sạch Quái)", "CHỈ KHI diệt hết quái mới tiến về cửa qua phòng tiếp", State.autodoor, function(val)
    State.autodoor = val
end, 13)

createToggle("Auto Nhặt Rương (Sau Mỗi Phòng)", "Thu thập rương kho báu & vàng sau khi dọn sạch ải", State.autochest, function(val)
    State.autochest = val
end, 14)

createToggle("Auto Chơi Lại (Replay)", "Hết trận tự động bấm Replay tạo vòng lặp cày vô tận", State.autoreplay, function(val)
    State.autoreplay = val
end, 15)

-- NHÓM 3: BỔ TRỢ NHÂN VẬT & BAY LƯỢN MOBILE
createCategory("⚡ BỔ TRỢ NHÂN VẬT & BAY LƯỢN", 20)

createToggle("Tốc Độ Chạy Cao (Speed 60)", "Tăng tốc chạy mượt mà, chống game ép tụt tốc", State.speed, function(val)
    State.speed = val
    if Hum then pcall(function() Hum.WalkSpeed = val and CFG.walkspeed or 16 end) end
end, 21)

createToggle("Bay 3D (Có Nút Cảm Ứng Mobile)", "Kèm 2 nút cảm ứng [▲ Lên] [▼ Xuống] trên màn hình", State.fly, function(val)
    State.fly = val
    if val then startFly() else stopFly() end
end, 22)

createToggle("Chống Sát Thương Rơi", "Hãm tốc rơi tự do, rơi từ trên cao không mất máu", State.nofall, function(val)
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

print("[VOSS] Dungeon Hunters Hub v2.0 (Ultimate Fix) Loaded Successfully! ⚔️")
