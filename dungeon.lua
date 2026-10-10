-- ================================================
-- VOSS | Dungeon Hunters Hub ⚔️ (Thợ Săn Hầm Ngục)
-- Game: Dungeon Hunters [UPD] - The Evac Syndicate
-- ================================================
-- [TÍNH NĂNG ĐỘT PHÁ]:
-- 1. AUTO FARM QUÁI & BOSS (CÀY CẤP SIÊU TỐC):
--    - Tự động tìm kiếm quái gần nhất (Enemies, Mobs, Monsters, DungeonMobs...)
--    - Chế độ Bay An Toàn Trên Đầu Quái (+4.5 Studs): Quái không thể chạm hoặc gây sát thương!
--    - Tự động khóa vận tốc (Zero Velocity) chống giật, chống văng map, chống rơi vực
--    - Đa tầng tấn công: Tự động cầm vũ khí, kích hoạt đòn đánh, quét và bắn Remote combat
--    - Auto Dùng Kỹ Năng (Auto Skills): Xoay tua kỹ năng gây sát thương dồn cực mạnh
-- 2. AUTO VÀO MAP & QUA CỬA (AUTO DUNGEON & ROOMS):
--    - Tự động vào map hầm ngục từ sảnh (Auto Lobby Portal / Auto Queue / Auto Prompt)
--    - Tự động bình chọn qua ải / mở cửa tiếp theo (Auto Vote Door / Auto Next Room)
--    - Tự động nhặt rương kho báu & vật phẩm rơi (Auto Collect Chests & Drops)
--    - Tự động chơi lại / đi tiếp khi hoàn thành hầm ngục (Auto Replay Dungeon)
-- 3. HỖ TRỢ NGƯỜI CHƠI & MOBILE CẢM ỨNG:
--    - Tốc độ chạy siêu tốc (Speed Hack) có khóa chống game reset về 16
--    - Bay 3D (Fly Hack) có sẵn 2 NÚT CẢM ỨNG [▲ Lên] và [▼ Xuống] trực tiếp trên màn hình
--    - Chống sát thương rơi (No Fall Damage)
--    - ESP Radar: Định vị Quái (Đỏ), Boss (Tím/Vàng), Rương (Vàng), Cửa ải (Xanh lam)
--    - Công cụ Deep Scanner tích hợp: Quét sạch mọi Remote/Folder của game khi cần
--    - Phím tắt mở/đóng: Nút tròn cảm ứng trên màn hình + Chạm 3 ngón tay + Phím RightShift
-- ================================================

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local VirtualUser       = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local LP                = Players.LocalPlayer
local Cam               = workspace.CurrentCamera

-- Trạng thái tính năng
local State = {
    autofarm      = false,
    autoboss      = false,
    autoskill     = false,
    autodungeon   = false, -- Tự động vào map từ sảnh
    autodoor      = false, -- Tự động qua cửa / vote door
    autochest     = false, -- Tự động nhặt rương / đồ rơi
    autoreplay    = false, -- Tự động chơi lại sau khi xong
    speed         = false,
    fly           = false,
    nofall        = true,
    esp_mobs      = false,
    esp_chests    = false,
    esp_doors     = false,
}

local CFG = {
    walkspeed    = 60,
    flyspeed     = 50,
    hoverHeight  = 4.5,   -- Chiều cao bay phía trên đầu quái
    attackDelay  = 0.12,  -- Tốc độ chém
    skillDelay   = 1.5,   -- Giãn cách dùng kỹ năng
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
        pcall(function()
            Hum.BreakJointsOnDeath = false
        end)

        -- Khóa tốc độ chạy chống game hạ về 16
        local cSpeed = Hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
            if State.speed and Hum.WalkSpeed ~= CFG.walkspeed then
                pcall(function() Hum.WalkSpeed = CFG.walkspeed end)
            end
        end)
        table.insert(humConns, cSpeed)

        if State.speed then
            pcall(function() Hum.WalkSpeed = CFG.walkspeed end)
        end

        -- Chống rơi mất máu
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
    task.wait(0.25)
    setupCharacter(newChar)
    if State.speed and Hum then
        pcall(function() Hum.WalkSpeed = CFG.walkspeed end)
    end
end)

-- Vòng lặp duy trì tốc độ & chống ngã
RunService.Heartbeat:Connect(function()
    if HRP and Hum and Hum.Health > 0 then
        if State.speed and Hum.WalkSpeed ~= CFG.walkspeed then
            pcall(function() Hum.WalkSpeed = CFG.walkspeed end)
        end
        if State.nofall and HRP.AssemblyLinearVelocity.Y < -26 then
            local v = HRP.AssemblyLinearVelocity
            HRP.AssemblyLinearVelocity = Vector3.new(v.X, -16, v.Z)
        end
    end
end)

-- ================================================
-- HỆ THỐNG SCAN REMOTE TỰ ĐỘNG
-- ================================================
local function findCombatRemotes()
    local remotes = {}
    local keywords = {"attack", "hit", "damage", "swing", "slash", "combat", "m1", "skill", "cast", "ability", "weapon", "strike"}
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
    -- Kiểm tra cả trong nhân vật người chơi
    if Char then
        for _, obj in pairs(Char:GetDescendants()) do
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
    end
    return remotes
end

local function findDungeonRemotes()
    local remotes = {}
    local keywords = {"dungeon", "enter", "start", "queue", "join", "vote", "door", "next", "room", "replay", "chest"}
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
    return remotes
end

-- ================================================
-- TÌM KIẾM QUÁI & BOSS THÔNG MINH
-- ================================================
local MOB_FOLDER_NAMES = {
    "Enemies", "Mobs", "Monsters", "DungeonMobs", "Entities", 
    "NPCs", "SpawnedEnemies", "RoomEnemies", "Boss", "Bosses"
}

local function getAllEnemies()
    local list = {}
    local seen = {}

    local function checkAndAdd(model)
        if not model or not model:IsA("Model") or seen[model] then return end
        if model == Char then return end
        -- Bỏ qua nhân vật người chơi khác
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

    -- 1. Tìm trong các thư mục phổ biến
    for _, folderName in ipairs(MOB_FOLDER_NAMES) do
        local f = workspace:FindFirstChild(folderName, true)
        if f then
            for _, child in ipairs(f:GetChildren()) do
                checkAndAdd(child)
            end
        end
    end

    -- 2. Tìm trong cấu trúc hầm ngục Dungeon / Rooms
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

    -- 3. Quét toàn bộ workspace nếu các thư mục trên trống
    if #list == 0 then
        for _, obj in ipairs(workspace:GetChildren()) do
            checkAndAdd(obj)
        end
    end

    return list
end

local function getBestEnemy(bossOnly)
    if not HRP then return nil end
    local enemies = getAllEnemies()
    local best = nil
    local bestDist = 999999

    for _, e in ipairs(enemies) do
        if not bossOnly or e.boss then
            local dist = (HRP.Position - e.root.Position).Magnitude
            if dist < bestDist then
                best = e
                bestDist = dist
            end
        end
    end

    -- Nếu bật bossOnly mà không thấy boss, tự chuyển sang đánh quái thường
    if not best and bossOnly then
        return getBestEnemy(false)
    end

    return best
end

-- ================================================
-- VŨ KHÍ & TẤN CÔNG
-- ================================================
local function equipBestWeapon()
    if not Char then return end
    local currentTool = Char:FindFirstChildOfClass("Tool")
    if not currentTool then
        local bp = LP:FindFirstChild("Backpack")
        if bp then
            local tool = bp:FindFirstChildOfClass("Tool")
            if tool and Hum then
                pcall(function() Hum:EquipTool(tool) end)
            end
        end
    end
end

local lastSkillTime = 0
local function castSkills()
    local now = tick()
    if now - lastSkillTime < CFG.skillDelay then return end
    lastSkillTime = now

    -- 1. Thử gửi VirtualKey số 1, 2, 3, 4 (Phím chiêu thức)
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        vim:SendKeyEvent(true, Enum.KeyCode.One, false, game)
        task.wait(0.02)
        vim:SendKeyEvent(false, Enum.KeyCode.One, false, game)
        vim:SendKeyEvent(true, Enum.KeyCode.Two, false, game)
        task.wait(0.02)
        vim:SendKeyEvent(false, Enum.KeyCode.Two, false, game)
    end)

    -- 2. Thử bắn các Remote skill
    local remotes = findCombatRemotes()
    for _, r in ipairs(remotes) do
        local n = r.Name:lower()
        if n:find("skill") or n:find("cast") or n:find("ability") then
            pcall(function()
                if r:IsA("RemoteEvent") then
                    r:FireServer(1)
                    r:FireServer(2)
                    r:FireServer("Q")
                    r:FireServer("E")
                end
            end)
        end
    end
end

-- ================================================
-- AUTO FARM ENGINE (CHẠY MƯỢT, 0 LỖI VẶT)
-- ================================================
local farmConnection = nil
local combatRemotesCache = {}
local lastRemoteRefresh = 0

local function startFarmLoop()
    if farmConnection then return end

    farmConnection = RunService.Heartbeat:Connect(function()
        if not State.autofarm and not State.autoboss then return end
        if not HRP or not Hum or Hum.Health <= 0 then return end

        local target = getBestEnemy(State.autoboss)
        if not target or not target.root or not target.hum or target.hum.Health <= 0 then
            return
        end

        -- Tự động cầm vũ khí
        equipBestWeapon()

        -- Bay an toàn phía trên đầu quái
        local targetPos = target.root.Position
        local safeCFrame = CFrame.new(targetPos + Vector3.new(0, CFG.hoverHeight, 0), targetPos)

        HRP.AssemblyLinearVelocity = Vector3.zero
        HRP.AssemblyAngularVelocity = Vector3.zero
        HRP.CFrame = safeCFrame

        -- Kích hoạt đòn đánh (Tool + Virtual Mouse)
        local tool = Char:FindFirstChildOfClass("Tool")
        if tool then
            pcall(function() tool:Activate() end)
        end

        pcall(function()
            VirtualUser:Button1Down(Vector2.new(0, 0), Cam.CFrame)
            VirtualUser:Button1Up(Vector2.new(0, 0), Cam.CFrame)
        end)

        -- Bắn remote combat
        local now = tick()
        if now - lastRemoteRefresh > 5 then
            combatRemotesCache = findCombatRemotes()
            lastRemoteRefresh = now
        end

        for _, r in ipairs(combatRemotesCache) do
            pcall(function()
                if r:IsA("RemoteEvent") then
                    r:FireServer(target.model, target.root.Position)
                    r:FireServer(target.model)
                    r:FireServer(target.root)
                    r:FireServer()
                elseif r:IsA("RemoteFunction") then
                    r:InvokeServer(target.model, target.root.Position)
                end
            end)
        end

        -- Kích hoạt kỹ năng nếu bật
        if State.autoskill then
            castSkills()
        end
    end)
end

local function stopFarmLoop()
    if farmConnection then
        farmConnection:Disconnect()
        farmConnection = nil
    end
end

-- ================================================
-- AUTO VÀO MAP & QUA CỬA (AUTO DUNGEON / ROOMS / REPLAY)
-- ================================================
local dungeonTaskActive = false

local function runDungeonAutomation()
    if dungeonTaskActive then return end
    dungeonTaskActive = true

    task.spawn(function()
        while task.wait(1.0) do
            if not HRP or not Hum or Hum.Health <= 0 then continue end

            -- --------------------------------------------
            -- 1. AUTO VÀO MAP TỪ SẢNH (LOBBY PORTAL)
            -- --------------------------------------------
            if State.autodungeon then
                -- Tìm các Cổng / Portal / Gate / Teleport ở Lobby
                local portalKeywords = {"portal", "gate", "enter", "dungeonportal", "matchmaking", "start", "elevator"}
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("BasePart") or obj:IsA("Model") then
                        local n = obj.Name:lower()
                        for _, kw in ipairs(portalKeywords) do
                            if n:find(kw) then
                                local targetPart = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                                if targetPart and (targetPart.Position - HRP.Position).Magnitude > 6 then
                                    -- Teleport chạm vào cổng
                                    HRP.CFrame = targetPart.CFrame + Vector3.new(0, 2, 0)
                                    task.wait(0.3)
                                    break
                                end
                            end
                        end
                    end
                end

                -- Tự động bấm ProximityPrompt vào map
                for _, prompt in ipairs(workspace:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") then
                        local text = (prompt.ActionText .. " " .. prompt.ObjectText):lower()
                        if text:find("enter") or text:find("join") or text:find("play") or text:find("start") or text:find("vào") then
                            pcall(function() fireproximityprompt(prompt) end)
                        end
                    end
                end

                -- Tự động bấm nút UI "Start" / "Play" / "Ready" / "Vào"
                local pGui = LP:FindFirstChild("PlayerGui")
                if pGui then
                    for _, btn in ipairs(pGui:GetDescendants()) do
                        if btn:IsA("TextButton") or btn:IsA("ImageButton") then
                            local bText = (btn.Name .. " " .. (btn:IsA("TextButton") and btn.Text or "")):lower()
                            if bText:find("start") or bText:find("play") or bText:find("solo") or bText:find("ready") or bText:find("queue") or bText:find("confirm") then
                                if btn.Visible then
                                    pcall(function()
                                        firesignal(btn.MouseButton1Click)
                                        firesignal(btn.Activated)
                                    end)
                                end
                            end
                        end
                    end
                end
            end

            -- --------------------------------------------
            -- 2. AUTO QUA CỬA / VOTE CỬA TRONG HẦM NGỤC
            -- --------------------------------------------
            if State.autodoor then
                -- Nếu trong phòng đã hết quái thì tiến về cửa ra
                local enemies = getAllEnemies()
                if #enemies == 0 then
                    local doorKeywords = {"door", "nextroom", "gate", "exit", "next", "portal"}
                    for _, obj in ipairs(workspace:GetDescendants()) do
                        if obj:IsA("BasePart") or obj:IsA("Model") then
                            local n = obj.Name:lower()
                            for _, kw in ipairs(doorKeywords) do
                                if n:find(kw) and not n:find("lobby") then
                                    local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                                    if part then
                                        HRP.CFrame = part.CFrame + Vector3.new(0, 3, 0)
                                        task.wait(0.2)
                                        break
                                    end
                                end
                            end
                        end
                    end
                end

                -- Tự động vote Door Remote
                for _, r in ipairs(ReplicatedStorage:GetDescendants()) do
                    if r:IsA("RemoteEvent") or r:IsA("RemoteFunction") then
                        local n = r.Name:lower()
                        if n:find("door") or n:find("vote") or n:find("next") or n:find("proceed") then
                            pcall(function()
                                if r:IsA("RemoteEvent") then
                                    r:FireServer(1)
                                    r:FireServer(true)
                                    r:FireServer("Yes")
                                else
                                    r:InvokeServer(1)
                                end
                            end)
                        end
                    end
                end

                -- Tự bấm nút Vote trên màn hình
                local pGui = LP:FindFirstChild("PlayerGui")
                if pGui then
                    for _, btn in ipairs(pGui:GetDescendants()) do
                        if btn:IsA("TextButton") or btn:IsA("ImageButton") then
                            local bText = (btn.Name .. " " .. (btn:IsA("TextButton") and btn.Text or "")):lower()
                            if bText:find("vote") or bText:find("yes") or bText:find("ready") or bText:find("next") or bText:find("continue") then
                                pcall(function()
                                    firesignal(btn.MouseButton1Click)
                                    firesignal(btn.Activated)
                                end)
                            end
                        end
                    end
                end
            end

            -- --------------------------------------------
            -- 3. AUTO NHẶT RƯƠNG & ĐỒ RƠI (CHESTS & DROPS)
            -- --------------------------------------------
            if State.autochest then
                local chestKeywords = {"chest", "treasure", "drop", "reward", "gold", "loot"}
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("Model") or obj:IsA("BasePart") then
                        local n = obj.Name:lower()
                        for _, kw in ipairs(chestKeywords) do
                            if n:find(kw) then
                                local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                                if part and HRP then
                                    -- Teleport lại gần rương
                                    HRP.CFrame = part.CFrame + Vector3.new(0, 2, 0)
                                    task.wait(0.1)

                                    -- Kích hoạt prompt nếu có
                                    local prompt = obj:FindFirstChildOfClass("ProximityPrompt") or part:FindFirstChildOfClass("ProximityPrompt")
                                    if prompt then
                                        pcall(function() fireproximityprompt(prompt) end)
                                    end
                                    break
                                end
                            end
                        end
                    end
                end
            end

            -- --------------------------------------------
            -- 4. AUTO CHƠI LẠI (AUTO REPLAY)
            -- --------------------------------------------
            if State.autoreplay then
                local pGui = LP:FindFirstChild("PlayerGui")
                if pGui then
                    for _, btn in ipairs(pGui:GetDescendants()) do
                        if btn:IsA("TextButton") or btn:IsA("ImageButton") then
                            local bText = (btn.Name .. " " .. (btn:IsA("TextButton") and btn.Text or "")):lower()
                            if bText:find("replay") or bText:find("again") or bText:find("chơi lại") or bText:find("retry") then
                                pcall(function()
                                    firesignal(btn.MouseButton1Click)
                                    firesignal(btn.Activated)
                                end)
                            end
                        end
                    end
                end

                for _, r in ipairs(ReplicatedStorage:GetDescendants()) do
                    if r:IsA("RemoteEvent") then
                        local n = r.Name:lower()
                        if n:find("replay") or n:find("restart") or n:find("retry") then
                            pcall(function() r:FireServer() end)
                        end
                    end
                end
            end
        end
    end)
end

runDungeonAutomation()

-- ================================================
-- HỆ THỐNG BAY 3D (CÓ NÚT CẢM ỨNG MOBILE [▲] [▼])
-- ================================================
local flyConn     = nil
local flyObjects  = {}
local mobileFlyGui = nil
local mobileUpDown = 0

local function cleanFlyObjects()
    for _, obj in pairs(flyObjects) do
        pcall(function() obj:Destroy() end)
    end
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

    -- Nút Bay Lên [▲]
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

    -- Nút Bay Xuống [▼]
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
-- HỆ THỐNG ESP RADAR (QUÁI, BOSS, RƯƠNG, CỬA)
-- ================================================
local ESPCache = {}

local function clearESP()
    for k, v in pairs(ESPCache) do
        pcall(function() v:Destroy() end)
        ESPCache[k] = nil
    end
end

RunService.Heartbeat:Connect(function()
    if not State.esp_mobs and not State.esp_chests and not State.esp_doors then
        if next(ESPCache) then clearESP() end
        return
    end

    local seen = {}

    -- 1. ESP Quái & Boss
    if State.esp_mobs then
        local enemies = getAllEnemies()
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

    -- 2. ESP Rương
    if State.esp_chests then
        for _, obj in ipairs(workspace:GetDescendants()) do
            local n = obj.Name:lower()
            if (n:find("chest") or n:find("treasure") or n:find("reward")) and (obj:IsA("BasePart") or obj:IsA("Model")) then
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

    -- Dọn dẹp ESP cũ
    for k, v in pairs(ESPCache) do
        if not seen[k] then
            pcall(function() v:Destroy() end)
            ESPCache[k] = nil
        end
    end
end)

-- ================================================
-- DEEP SCANNER (CÔNG CỤ PHÂN TÍCH LIVE CHO NGƯỜI CHƠI)
-- ================================================
local function runDeepScan()
    print("========================================")
    print("🚀 [VOSS SCANNER] BẮT ĐẦU QUÉT DỮ LIỆU GAME...")
    print("PlaceId:", game.PlaceId)
    print("JobId:", game.JobId)

    local remotes = {}
    for _, v in pairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            table.insert(remotes, v.ClassName .. ": " .. v:GetFullName())
        end
    end
    print("[VOSS] Đã tìm thấy " .. #remotes .. " Remote trong ReplicatedStorage:")
    for i = 1, math.min(#remotes, 25) do
        print("  ->", remotes[i])
    end

    local enemies = getAllEnemies()
    print("[VOSS] Số lượng quái hiện tại trong tầm quét: " .. #enemies)
    for i = 1, math.min(#enemies, 10) do
        print("  -> Quái: " .. enemies[i].model.Name .. " (HP: " .. math.floor(enemies[i].hum.Health) .. "/" .. enemies[i].hum.MaxHealth .. ")")
    end
    print("========================================")
end

-- ================================================
-- GIAO DIỆN VOSS HUB (LUXURY DARK - NEON PURPLE)
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

-- 1. NÚT MỞ NHANH TRÊN MÀN HÌNH (MOBILE FLOATING BUTTON)
local FloatBtn = Instance.new("TextButton", SG)
FloatBtn.Name             = "FloatBtn"
FloatBtn.Size             = UDim2.new(0, 50, 0, 50)
FloatBtn.Position         = UDim2.new(0, 15, 0.4, 0)
FloatBtn.BackgroundColor3 = Color3.fromRGB(20, 15, 35)
FloatBtn.Text             = "⚡\nVOSS"
FloatBtn.TextColor3       = Color3.fromRGB(200, 150, 255)
FloatBtn.Font             = Enum.Font.GothamBold
FloatBtn.TextSize         = 11
FloatBtn.Active           = true
FloatBtn.Draggable        = true
Instance.new("UICorner", FloatBtn).CornerRadius = UDim.new(0, 25)
local fbStroke = Instance.new("UIStroke", FloatBtn)
fbStroke.Color = Color3.fromRGB(140, 70, 255); fbStroke.Thickness = 2

-- 2. KHUNG MENU CHÍNH
local MainFrame = Instance.new("Frame", SG)
MainFrame.Name             = "MainFrame"
MainFrame.Size             = UDim2.new(0, 310, 0, 480)
MainFrame.Position         = UDim2.new(0.5, -155, 0.5, -240)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
MainFrame.BorderSizePixel  = 0
MainFrame.Active           = true
MainFrame.Draggable        = true
MainFrame.ClipsDescendants = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 14)

local mfStroke = Instance.new("UIStroke", MainFrame)
mfStroke.Color = Color3.fromRGB(120, 60, 230); mfStroke.Thickness = 2

-- Tiêu đề Header
local Header = Instance.new("Frame", MainFrame)
Header.Size             = UDim2.new(1, 0, 0, 50)
Header.BackgroundColor3 = Color3.fromRGB(18, 16, 28)
Header.BorderSizePixel  = 0
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 14)

local Title = Instance.new("TextLabel", Header)
Title.Size               = UDim2.new(1, -50, 0, 30)
Title.Position           = UDim2.new(0, 16, 0, 4)
Title.BackgroundTransparency = 1
Title.Text               = "VOSS | Thợ Săn Hầm Ngục ⚔️"
Title.TextColor3         = Color3.fromRGB(215, 175, 255)
Title.Font               = Enum.Font.GothamBold
Title.TextSize           = 15
Title.TextXAlignment     = Enum.TextXAlignment.Left

local SubTitle = Instance.new("TextLabel", Header)
SubTitle.Size               = UDim2.new(1, -50, 0, 16)
SubTitle.Position           = UDim2.new(0, 16, 0, 28)
SubTitle.BackgroundTransparency = 1
SubTitle.Text               = "Dungeon Hunters [UPD] - The Evac Syndicate"
SubTitle.TextColor3         = Color3.fromRGB(120, 110, 160)
SubTitle.Font               = Enum.Font.Gotham
SubTitle.TextSize           = 10
SubTitle.TextXAlignment     = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", Header)
CloseBtn.Size             = UDim2.new(0, 28, 0, 28)
CloseBtn.Position         = UDim2.new(1, -38, 0, 11)
CloseBtn.BackgroundColor3 = Color3.fromRGB(40, 25, 60)
CloseBtn.Text             = "✕"
CloseBtn.TextColor3       = Color3.fromRGB(255, 180, 180)
CloseBtn.Font             = Enum.Font.GothamBold
CloseBtn.TextSize         = 13
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)

CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
end)

FloatBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- Danh sách cuộn chứa chức năng
local Scroll = Instance.new("ScrollingFrame", MainFrame)
Scroll.Size             = UDim2.new(1, -16, 1, -62)
Scroll.Position         = UDim2.new(0, 8, 0, 56)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel  = 0
Scroll.ScrollBarThickness = 4
Scroll.ScrollBarImageColor3 = Color3.fromRGB(120, 70, 220)
Scroll.CanvasSize       = UDim2.new(0, 0, 0, 680)

local UIList = Instance.new("UIListLayout", Scroll)
UIList.Padding = UDim.new(0, 8)
UIList.SortOrder = Enum.SortOrder.LayoutOrder

-- Hàm tạo mục phân cách nhóm tính năng
local function createCategory(text, order)
    local lbl = Instance.new("TextLabel", Scroll)
    lbl.Size             = UDim2.new(1, 0, 0, 24)
    lbl.LayoutOrder      = order
    lbl.BackgroundTransparency = 1
    lbl.Text             = text
    lbl.TextColor3       = Color3.fromRGB(180, 140, 255)
    lbl.Font             = Enum.Font.GothamBold
    lbl.TextSize         = 12
    lbl.TextXAlignment   = Enum.TextXAlignment.Left
    return lbl
end

-- Hàm tạo Toggle Switch
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

-- Hàm tạo Nút Bấm Thực Thi
local function createButton(title, desc, callback, order)
    local btn = Instance.new("TextButton", Scroll)
    btn.Size             = UDim2.new(1, -6, 0, 44)
    btn.BackgroundColor3 = Color3.fromRGB(28, 22, 46)
    btn.LayoutOrder      = order
    btn.Text             = ""
    btn.AutoButtonColor  = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)

    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = Color3.fromRGB(90, 50, 170); stroke.Thickness = 1

    local tLbl = Instance.new("TextLabel", btn)
    tLbl.Size               = UDim2.new(1, -20, 0, 22)
    tLbl.Position           = UDim2.new(0, 12, 0, 4)
    tLbl.BackgroundTransparency = 1
    tLbl.Text               = title
    tLbl.TextColor3         = Color3.fromRGB(215, 180, 255)
    tLbl.Font               = Enum.Font.GothamBold
    tLbl.TextSize           = 13
    tLbl.TextXAlignment     = Enum.TextXAlignment.Left

    local dLbl = Instance.new("TextLabel", btn)
    dLbl.Size               = UDim2.new(1, -20, 0, 16)
    dLbl.Position           = UDim2.new(0, 12, 0, 24)
    dLbl.BackgroundTransparency = 1
    dLbl.Text               = desc
    dLbl.TextColor3         = Color3.fromRGB(140, 130, 175)
    dLbl.Font               = Enum.Font.Gotham
    dLbl.TextSize           = 10
    dLbl.TextXAlignment     = Enum.TextXAlignment.Left

    btn.MouseButton1Click:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(60, 35, 110)
        task.delay(0.15, function()
            btn.BackgroundColor3 = Color3.fromRGB(28, 22, 46)
        end)
        callback()
    end)
    return btn
end

-- ================================================
-- KHỞI TẠO CÁC NÚT ĐIỀU KHIỂN
-- ================================================

-- NHÓM 1: CÀY CẤP & AUTO FARM
createCategory("⚔️ CÀY CẤP & CHIẾN ĐẤU (AUTO FARM)", 1)

createToggle("Auto Farm Quái", "Bay trên đầu quái chém liên tục (An toàn 100%)", State.autofarm, function(val)
    State.autofarm = val
    if val then startFarmLoop() else if not State.autoboss then stopFarmLoop() end end
end, 2)

createToggle("Ưu Tiên Săn Boss", "Tập trung diệt Boss trước để nhận đồ quý", State.autoboss, function(val)
    State.autoboss = val
    if val then startFarmLoop() else if not State.autofarm then stopFarmLoop() end end
end, 3)

createToggle("Auto Dùng Kỹ Năng", "Tự động xả chiêu thức 1, 2, Q, E liên tục", State.autoskill, function(val)
    State.autoskill = val
end, 4)

-- NHÓM 2: HẦM NGỤC & VÀO MAP TỰ ĐỘNG
createCategory("🚪 HẦM NGỤC & VÀO MAP TỰ ĐỘNG", 10)

createToggle("Auto Vào Map (Lobby)", "Tự động bước vào cổng / xác nhận bắt đầu ở sảnh", State.autodungeon, function(val)
    State.autodungeon = val
end, 11)

createToggle("Auto Qua Cửa / Vote Ải", "Hết quái tự đến cửa hoặc bình chọn qua phòng tiếp", State.autodoor, function(val)
    State.autodoor = val
end, 12)

createToggle("Auto Nhặt Rương & Đồ Rơi", "Tự động dịch chuyển nhặt rương kho báu & vàng", State.autochest, function(val)
    State.autochest = val
end, 13)

createToggle("Auto Chơi Lại (Replay)", "Hết màn tự động bấm chơi lại hoặc đi map tiếp", State.autoreplay, function(val)
    State.autoreplay = val
end, 14)

-- NHÓM 3: HỖ TRỢ NHÂN VẬT & BAY
createCategory("⚡ BỔ TRỢ NHÂN VẬT & BAY LƯỢN", 20)

createToggle("Tốc Độ Chạy Cao (Speed 60)", "Tăng tốc độ di chuyển siêu mượt, không bị hạ tốc", State.speed, function(val)
    State.speed = val
    if Hum then pcall(function() Hum.WalkSpeed = val and CFG.walkspeed or 16 end) end
end, 21)

createToggle("Bay 3D (Fly Hack Mobile)", "Kèm 2 nút cảm ứng [▲ Lên] [▼ Xuống] trên màn hình", State.fly, function(val)
    State.fly = val
    if val then startFly() else stopFly() end
end, 22)

createToggle("Chống Sát Thương Rơi", "Hãm tốc rơi tự do, không bị mất máu oan", State.nofall, function(val)
    State.nofall = val
end, 23)

-- NHÓM 4: RADAR & ESP
createCategory("👁️ RADAR ĐỊNH VỊ (ESP)", 30)

createToggle("ESP Quái & Boss", "Hiện tên, khoảng cách và thanh máu quái xuyên tường", State.esp_mobs, function(val)
    State.esp_mobs = val
    if not val then clearESP() end
end, 31)

createToggle("ESP Rương Kho Báu", "Hiện vị trí toàn bộ rương kho báu trong map", State.esp_chests, function(val)
    State.esp_chests = val
    if not val then clearESP() end
end, 32)

-- NHÓM 5: TIỆN ÍCH & QUÉT HỆ THỐNG
createCategory("🔍 TIỆN ÍCH & QUÉT GAME", 40)

createButton("🚀 Quét Dữ Liệu Game (Deep Scan)", "Quét toàn bộ Remote, Quái, Thư mục ra F9 Console", function()
    runDeepScan()
end, 41)

createButton("⚔️ Cầm Lại Vũ Khí", "Trang bị lại vũ khí từ túi đồ ngay lập tức", function()
    equipBestWeapon()
end, 42)

-- ================================================
-- CỬ CHỈ ĐIỀU KHIỂN MOBILE & PC
-- ================================================
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

print("[VOSS] Dungeon Hunters Hub v1.0 Loaded Successfully! ⚔️")
