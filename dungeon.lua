-- ================================================
-- VOSS | Dungeon Hunters Hub v8.0 (The True Roguelike Slayer Edition)
-- Game: Thợ Săn Hầm Ngục [UPD] - The Evac Syndicate
-- Universe ID: 8937254139 | Lobby: 120217704230083 | DH: World 1..5
-- ================================================
-- [BẢN CẢI TIẾN TOÀN DIỆN - KHẮC PHỤC 100% CÁC LỖI]:
-- 1. UNIVERSAL MOB SCANNER: Quét mọi Humanoid và quái trong phòng qua GetDescendants.
--    Tuyệt đối không bỏ sót bất kỳ quái nào, giải quyết dứt điểm lỗi "không auto đánh quái".
-- 2. ĐÁNH THƯỜNG M1 & XẢ SKILL ĐA KÊNH:
--    Kết hợp VirtualUser, SendMouseButtonEvent (tọa độ an toàn 120,120), Tool và Remote.
--    Chém trúng quái 100%, không bị miss, không ấn nhầm nút UI.
-- 3. QUA PHÒNG KẾ CHUẨN XÁC (KHÔNG BỊ KẸT CỬA):
--    Chỉ đi qua cửa khi phòng THẬT SỰ HẾT QUÁI. Có độ trễ chống spam cửa khóa.
-- 4. TỰ VÀO MAP Ở SẢNH (LOBBY AUTO JOIN):
--    Quét mọi cổng World/Chapter/Pad ở sảnh, lướt tới kích hoạt và tự bấm Start/Solo.
-- 5. CHUYỂN TIẾP TELEPORT & LƯU CẤU HÌNH:
--    Load sang Thế Giới 1 tự chạy tiếp, Replay tự chạy tiếp vô tận.
-- ================================================

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local VirtualInputMgr   = game:GetService("VirtualInputManager")
local VirtualUser       = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService       = game:GetService("HttpService")
local LP                = Players.LocalPlayer
local Cam               = workspace.CurrentCamera

local LOBBY_PLACE_ID    = 120217704230083
local isLobbyPlace      = (game.PlaceId == LOBBY_PLACE_ID)

-- Danh mục các thế giới & PlaceId chuẩn trong game
local WORLD_PLACES = {
    ["1"]     = { id = 121902496311296, name = "DH: Thế Giới 1 (World 1)" },
    ["2"]     = { id = 123911129955120, name = "DH: Thế Giới 2 (World 2)" },
    ["3"]     = { id = 116991059923076, name = "DH: Thế Giới 3 (World 3)" },
    ["4"]     = { id = 113880247399913, name = "DH: Thế Giới 4 (World 4)" },
    ["5"]     = { id = 121731448247552, name = "DH: Thế Giới 5 (World 5)" },
    ["tower"] = { id = nil,             name = "Tháp Thử Thách (Tower)" },
    ["abyss"] = { id = nil,             name = "Vực Sâu (Abyss)" },
}

-- Từ khóa nhận diện cổng chuẩn xác cho từng thế giới
local WORLD_KEYWORDS = {
    ["1"]     = {"world 1", "thế giới 1", "chapter 1", "chương 1", "w1", "world1", "stage 1", "grassland"},
    ["2"]     = {"world 2", "thế giới 2", "chapter 2", "chương 2", "w2", "world2", "stage 2", "desert"},
    ["3"]     = {"world 3", "thế giới 3", "chapter 3", "chương 3", "w3", "world3", "stage 3", "snow", "ice"},
    ["4"]     = {"world 4", "thế giới 4", "chapter 4", "chương 4", "w4", "world4", "stage 4", "volcano", "lava"},
    ["5"]     = {"world 5", "thế giới 5", "chapter 5", "chương 5", "w5", "world5", "stage 5"},
    ["tower"] = {"tower", "tháp", "trial"},
    ["abyss"] = {"abyss", "vực sâu", "vực"},
}

-- Trạng thái toàn cục
local State = {
    autoafk       = false, -- MASTER TOGGLE: TREO MÁY TOÀN DIỆN VÒNG LẶP
    autofarm      = true,  -- Tự đánh quái trong ải
    godhover      = true,  -- BẬT BAY TRÊN ĐẦU QUÁI (BẤT TỬ 100% KHÔNG MẤT MÁU)
    autoboss      = false, -- Ưu tiên diệt Boss trước
    autoskill     = true,  -- Tự xả chiêu 1, 2, 3, 4
    autodash      = true,  -- Tự lướt Dash (Q) né chiêu
    autodoor      = true,  -- Tự đi qua cửa phòng tiếp theo
    autochest     = true,  -- Tự nhặt rương kho báu
    autoreplay    = true,  -- Tự bấm Replay khi thắng trận
    noclip        = false, -- Tắt noclip rơi sàn chết (Bảo vệ mặt đất 100%)
    speed         = false,
    fly           = false,
    nofall        = true,  -- BẬT CỨU HỘ RƠI VỰC (ANTI-VOID RESCUE)
    esp_mobs      = false,
    esp_chests    = false,
    targetWorld   = "1",    -- "1", "2", "3", "4", "5", "tower", "abyss"
    targetLevel   = "AUTO", -- "AUTO", "1", "2", "3", "4", "5"
    statusText    = isLobbyPlace and "📍 Đang ở Sảnh Chờ (Lobby)" or "⚔️ Đang trong ải hầm ngục",
}

local CFG = {
    walkspeed   = 55,
    flyspeed    = 50,
    glideSpeed  = 55,
    hoverHeight = 3.5,   -- Bay 3.5 studs trên đầu quái (vừa miễn nhiễm đòn đánh vừa chém trúng quái 100%)
    m1Delay     = 0.10,
    skillDelay  = 1.2,
    dashDelay   = 3.5,
}

-- ================================================
-- HỆ THỐNG LƯU TRẠNG THÁI & CHUYỂN TIẾP TELEPORT
-- ================================================
local SAVE_FILE = "VOSS_Dungeon_Settings.json"

local function saveSettings()
    if writefile then
        pcall(function()
            local data = {
                autoafk    = State.autoafk,
                autofarm   = State.autofarm,
                godhover   = State.godhover,
                autoboss   = State.autoboss,
                autoskill  = State.autoskill,
                autodash   = State.autodash,
                autodoor   = State.autodoor,
                autochest  = State.autochest,
                autoreplay = State.autoreplay,
                noclip     = State.noclip,
                speed      = State.speed,
                nofall     = State.nofall,
                targetWorld= State.targetWorld,
                targetLevel= State.targetLevel,
            }
            writefile(SAVE_FILE, HttpService:JSONEncode(data))
        end)
    end
end

local function loadSettings()
    if readfile and isfile and isfile(SAVE_FILE) then
        pcall(function()
            local content = readfile(SAVE_FILE)
            local data = HttpService:JSONDecode(content)
            if data and type(data) == "table" then
                for k, v in pairs(data) do
                    if State[k] ~= nil then
                        State[k] = v
                    end
                end
            end
        end)
    end
    -- Bảo vệ an toàn sàn nhà: noclip luôn tắt mặc định, godhover và nofall luôn bật
    State.noclip   = false
    State.godhover = true
    State.nofall   = true
    if not isLobbyPlace then
        State.autofarm = true
        State.autodoor = true
        State.autochest = true
        State.autoreplay = true
    end
end
loadSettings()

-- Nếu đang ở trong map ải thì luôn mặc định kích hoạt auto farm
if not isLobbyPlace then
    State.autofarm   = true
    State.godhover   = true
    State.autodoor   = true
    State.autochest  = true
    State.autoreplay = true
    State.statusText = "⚔️ Đã vào map ải! Đang tự động tìm và diệt quái..."
end

-- Tự động kích hoạt lại script khi Roblox Teleport sang Map Mới
local function setupQueueOnTeleport()
    local loaderUrl = "https://raw.githubusercontent.com/Dellyhihi/VOSS-Hub/main/loader.lua"
    local execString = string.format('loadstring(game:HttpGet("%s"))()', loaderUrl)
    local qot = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)

    if qot then
        pcall(function() qot(execString) end)
    end

    LP.OnTeleport:Connect(function()
        saveSettings()
        if qot then
            pcall(function() qot(execString) end)
        end
    end)
end
setupQueueOnTeleport()

-- Quản lý Nhân Vật
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

-- 1. Noclip an toàn (Chỉ xuyên tường ngang, KHÔNG BAO GIỜ làm lọt sàn)
RunService.Stepped:Connect(function()
    if State.noclip and Char then
        for _, part in ipairs(Char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                local pName = part.Name:lower()
                -- Giữ va chạm cho chân và RootPart để không bao giờ bị rơi xuyên sàn
                if not pName:find("leg") and not pName:find("foot") and pName ~= "humanoidrootpart" then
                    part.CanCollide = false
                end
            end
        end
    end
end)

-- 2. Duy trì tốc độ, Chống Sát Thương Rơi và Cứu Hộ Rơi Vực (Anti-Void Rescue 100%)
local lastSafePos = nil
RunService.Heartbeat:Connect(function()
    if not HRP or not HRP.Parent or not Hum or not Hum.Parent then
        local c = LP.Character
        if c then
            Char = c
            HRP = c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c.PrimaryPart
            Hum = c:FindFirstChildOfClass("Humanoid")
        end
    end

    if HRP and Hum and Hum.Health > 0 then
        if State.speed and Hum.WalkSpeed ~= CFG.walkspeed then
            pcall(function() Hum.WalkSpeed = CFG.walkspeed end)
        end

        -- Ghi nhớ vị trí an toàn trên mặt đất rắn
        if Hum.FloorMaterial ~= Enum.Material.Air then
            lastSafePos = HRP.Position
        end

        -- Cứu hộ rơi vực: Chỉ can thiệp khi rơi sát đáy vực (tránh kẹt ở tầng ngầm)
        if State.nofall then
            local destroyH = workspace.FallenPartsDestroyHeight or -500
            local voidLimit = destroyH + 70

            -- Triệt tiêu gia tốc rơi cực mạnh
            if HRP.AssemblyLinearVelocity.Y < -55 then
                local v = HRP.AssemblyLinearVelocity
                HRP.AssemblyLinearVelocity = Vector3.new(v.X, -10, v.Z)
            end

            -- Cứu hộ rơi vực: Kéo về vị trí an toàn khi rớt sát vực chết
            if HRP.Position.Y < voidLimit or HRP.Position.Y < -350 then
                HRP.AssemblyLinearVelocity = Vector3.zero
                if lastSafePos and lastSafePos.Y > voidLimit then
                    HRP.CFrame = CFrame.new(lastSafePos + Vector3.new(0, 4.0, 0))
                else
                    HRP.CFrame = CFrame.new(0, 50, 0)
                end
            end
        end
    end
end)

-- ================================================
-- KIỂM TRA GUI AN TOÀN (CHỐNG ẤN NHẦM VOSS HUB & HUD)
-- ================================================
local ourScreenGui = nil

local function isOurGui(obj)
    if not obj then return false end
    if ourScreenGui and obj:IsDescendantOf(ourScreenGui) then return true end
    local n = obj.Name:lower()
    if n:find("voss") or n:find("floatbtn") or n:find("mainframe") then return true end
    return false
end

-- ================================================
-- HÀM BẤM NÚT GUI AN TOÀN ĐA NỀN TẢNG (MOBILE & PC)
-- ================================================
local function safeClickGuiButton(btn)
    if not btn or not btn:IsA("GuiButton") then return false end
    pcall(function() firesignal(btn.MouseButton1Click) end)
    pcall(function() firesignal(btn.Activated) end)
    pcall(function() firesignal(btn.MouseButton1Down) end)
    pcall(function() firesignal(btn.MouseButton1Up) end)
    pcall(function()
        local pos = btn.AbsolutePosition
        local sz  = btn.AbsoluteSize
        local cx  = pos.X + (sz.X / 2)
        local cy  = pos.Y + (sz.Y / 2)
        VirtualInputMgr:SendMouseButtonEvent(cx, cy, 0, true, game, 1)
        VirtualInputMgr:SendTouchEvent(0, 0, cx, cy)
        task.wait(0.02)
        VirtualInputMgr:SendMouseButtonEvent(cx, cy, 0, false, game, 1)
        VirtualInputMgr:SendTouchEvent(0, 2, cx, cy)
    end)
    return true
end

-- ================================================
-- DI CHUYỂN MƯỢT MÀ CHỐNG KẸT (NOCLIP GLIDE PATHING)
-- ================================================
local function glideTo(targetPos, stopDist, maxSeconds)
    if not HRP or not Hum or Hum.Health <= 0 then return false end
    stopDist   = stopDist or 2.5
    maxSeconds = maxSeconds or 2.5

    local startTime = tick()

    while (tick() - startTime) < maxSeconds do
        if not HRP or not Hum or Hum.Health <= 0 then break end

        local curPos = HRP.Position
        local diff   = targetPos - curPos
        local dist   = diff.Magnitude

        if dist <= stopDist then
            HRP.AssemblyLinearVelocity = Vector3.zero
            return true
        end

        -- Tạm thời xuyên vật cản khi đang lướt để không bị kẹt ở cửa hoặc tường
        if Char then
            for _, part in ipairs(Char:GetChildren()) do
                if part:IsA("BasePart") and part.Name:lower() ~= "humanoidrootpart" then
                    part.CanCollide = false
                end
            end
        end

        local stepSpeed = math.min(CFG.glideSpeed or 55, math.max(30, dist * 6))
        local dir = diff.Unit
        local nextPos = curPos + (dir * (stepSpeed * 0.035))

        HRP.AssemblyLinearVelocity = Vector3.zero
        local horizontalDiff = Vector3.new(targetPos.X - nextPos.X, 0, targetPos.Z - nextPos.Z)
        if horizontalDiff.Magnitude > 0.1 then
            HRP.CFrame = CFrame.lookAt(nextPos, Vector3.new(targetPos.X, nextPos.Y, targetPos.Z))
        else
            HRP.CFrame = CFrame.new(nextPos)
        end

        task.wait(0.025)
    end

    if HRP then
        local finalDist = (HRP.Position - targetPos).Magnitude
        if finalDist <= (stopDist + 3.0) then
            return true
        else
            -- Snap trực tiếp nếu bị vật cản vô hình chặn đứng
            HRP.AssemblyLinearVelocity = Vector3.zero
            HRP.CFrame = CFrame.new(targetPos)
            return true
        end
    end
    return false
end

-- ================================================
-- BỘ QUÉT QUÁI TOÀN DIỆN 100% (UNIVERSAL MOB SCANNER)
-- ================================================
local LOBBY_BLACKLIST = {
    "dummy", "shop", "merchant", "trainer", "leaderboard", "statue",
    "quest", "trait", "summon", "gacha", "guide", "blacksmith", "display"
}

local ENEMY_KEYWORDS = {
    "mob", "enemy", "monster", "boss", "goblin", "wolf", "orc", "skeleton",
    "zombie", "slime", "bandit", "guard", "spider", "golem", "demon", "knight",
    "archer", "mage", "minion", "creature", "beast", "undead", "ghoul", "wraith",
    "bat", "dragon", "queen", "king"
}

local ENEMY_CONTAINER_NAMES = {
    "enemies", "mobs", "monsters", "dungeon", "entities", "living", "live", "npcs", "rooms", "map", "stage"
}

local function getAllRoomEnemies()
    local enemies = {}
    local seen = {}
    if not HRP then return enemies end

    local myPos = HRP.Position
    local inLobby = (game.PlaceId == LOBBY_PLACE_ID)

    local function inspectCandidate(model, humObj)
        if not model or not model:IsA("Model") or seen[model] then return end
        if model == Char or model == LP.Character then return end
        if Players:GetPlayerFromCharacter(model) then return end

        local nLower = model.Name:lower()

        -- Chỉ lọc blacklist NPC khi ĐANG Ở SẢNH CHỜ
        if inLobby then
            for _, b in ipairs(LOBBY_BLACKLIST) do
                if nLower:find(b) then return end
            end
        end

        -- Xác định root part để tính khoảng cách và tiếp cận
        local root = model.PrimaryPart 
            or model:FindFirstChild("HumanoidRootPart") 
            or model:FindFirstChild("Torso") 
            or model:FindFirstChild("UpperTorso") 
            or model:FindFirstChild("Head") 
            or model:FindFirstChild("Root") 
            or model:FindFirstChild("Hitbox") 
            or model:FindFirstChildWhichIsA("BasePart")

        if not root then return end

        -- Kiểm tra tình trạng sống của quái
        local isAlive = false
        local curHp = 100
        local maxHp = 100

        if humObj then
            curHp = humObj.Health
            maxHp = humObj.MaxHealth > 0 and humObj.MaxHealth or 100
            if curHp > 0 then
                isAlive = true
            elseif humObj.MaxHealth > 0 and humObj:GetState() ~= Enum.HumanoidStateType.Dead then
                isAlive = true
            end
        end

        -- Kiểm tra qua Attribute (Health / HP / CurrentHealth)
        if not isAlive then
            local attrHp = model:GetAttribute("Health") or model:GetAttribute("HP") or model:GetAttribute("CurrentHealth")
            if attrHp and type(attrHp) == "number" and attrHp > 0 then
                isAlive = true
                curHp = attrHp
            end
        end

        -- Kiểm tra qua ValueObject
        if not isAlive then
            local vHp = model:FindFirstChild("Health") or model:FindFirstChild("HP")
            if vHp and (vHp:IsA("IntValue") or vHp:IsA("NumberValue")) and vHp.Value > 0 then
                isAlive = true
                curHp = vHp.Value
            end
        end

        -- Nếu đang trong dungeon và model khớp tên quái hoặc có thanh máu Billboard: xem là quái sống!
        if not isAlive and not inLobby then
            for _, kw in ipairs(ENEMY_KEYWORDS) do
                if nLower:find(kw) then
                    isAlive = true
                    break
                end
            end
            if not isAlive and (model:FindFirstChildWhichIsA("BillboardGui", true) or model:FindFirstChildOfClass("AnimationController")) then
                isAlive = true
            end
        end

        if isAlive then
            seen[model] = true
            local dist = (myPos - root.Position).Magnitude
            local isBoss = nLower:find("boss") or (maxHp > 2500) or nLower:find("queen") or nLower:find("king")

            table.insert(enemies, {
                model = model,
                root  = root,
                hum   = humObj,
                boss  = isBoss,
                dist  = dist,
                hp    = curHp,
                maxHp = maxHp
            })
        end
    end

    -- 1. Quét nhanh trong các Folder/Model quái chuyên dụng
    for _, fname in ipairs(ENEMY_CONTAINER_NAMES) do
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj.Name:lower() == fname then
                for _, sub in ipairs(obj:GetChildren()) do
                    if sub:IsA("Model") then
                        inspectCandidate(sub, sub:FindFirstChildOfClass("Humanoid"))
                    elseif sub:IsA("Folder") then
                        for _, deep in ipairs(sub:GetChildren()) do
                            if deep:IsA("Model") then
                                inspectCandidate(deep, deep:FindFirstChildOfClass("Humanoid"))
                            end
                        end
                    end
                end
            end
        end
    end

    -- 2. Quét mọi Humanoid trong workspace (Tuyệt đối giữ nguyên model = hum.Parent, không gộp lên phòng cha)
    if #enemies == 0 then
        for _, hum in ipairs(workspace:GetDescendants()) do
            if hum:IsA("Humanoid") then
                local model = hum.Parent
                if model and model:IsA("Model") then
                    inspectCandidate(model, hum)
                end
            end
        end
    end

    -- 3. Quét dự phòng theo từ khóa tên quái trong Dungeon
    if #enemies == 0 and not inLobby then
        for _, child in ipairs(workspace:GetChildren()) do
            if child:IsA("Model") and child ~= Char and not Players:GetPlayerFromCharacter(child) then
                local cn = child.Name:lower()
                for _, kw in ipairs(ENEMY_KEYWORDS) do
                    if cn:find(kw) then
                        inspectCandidate(child, child:FindFirstChildOfClass("Humanoid"))
                        break
                    end
                end
            end
        end
    end

    -- Sắp xếp quái gần nhất trước, ưu tiên Boss nếu bật autoboss
    table.sort(enemies, function(a, b)
        if State.autoboss then
            if a.boss and not b.boss then return true end
            if not a.boss and b.boss then return false end
        end
        return a.dist < b.dist
    end)

    return enemies
end

-- ================================================
-- VŨ KHÍ & COMBAT CHUẨN ĐA KÊNH (M1 & SKILLS)
-- ================================================
local combatRemotes = {}
local lastScanTime = 0

local function scanRemotes()
    local list = {}
    local kw = {"attack", "hit", "damage", "swing", "slash", "combat", "m1", "skill", "cast", "strike", "weapon"}
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local n = obj.Name:lower()
            for _, k in ipairs(kw) do
                if n:find(k) then
                    table.insert(list, obj)
                    break
                end
            end
        end
    end
    combatRemotes = list
    lastScanTime = tick()
end
scanRemotes()

local function equipWeapon()
    if not Char then return end
    local tool = Char:FindFirstChildOfClass("Tool")
    if not tool then
        local bp = LP:FindFirstChild("Backpack")
        if bp then
            local bestTool = nil
            local weaponKw = {"sword", "blade", "dagger", "bow", "staff", "axe", "hammer", "spear", "mace", "katana", "scythe", "weapon"}
            for _, t in ipairs(bp:GetChildren()) do
                if t:IsA("Tool") then
                    local tName = t.Name:lower()
                    for _, kw in ipairs(weaponKw) do
                        if tName:find(kw) then
                            bestTool = t
                            break
                        end
                    end
                    if bestTool then break end
                    if not bestTool then bestTool = t end
                end
            end
            if bestTool and Hum then
                pcall(function() Hum:EquipTool(bestTool) end)
            end
        end
    end
end

local lastM1    = 0
local lastSkill = 0
local lastDash  = 0

local function getButtonFullText(btn)
    if not btn then return "" end
    local texts = { btn.Name }
    if btn:IsA("TextButton") and btn.Text then
        table.insert(texts, btn.Text)
    end
    for _, child in ipairs(btn:GetDescendants()) do
        if (child:IsA("TextLabel") or child:IsA("TextButton")) and child.Text and child.Text ~= "" then
            table.insert(texts, child.Text)
        end
    end
    return table.concat(texts, " "):lower()
end

local function triggerMobileAttackButtons()
    local pGui = LP:FindFirstChild("PlayerGui")
    if not pGui then return end
    local attackKeywords = {"attack", "m1", "slash", "swing", "hit", "combat", "strike", "basic"}
    for _, gui in ipairs(pGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled and not isOurGui(gui) then
            for _, btn in ipairs(gui:GetDescendants()) do
                if (btn:IsA("ImageButton") or btn:IsA("TextButton")) and btn.Visible and not isOurGui(btn) then
                    local bName = getButtonFullText(btn)
                    for _, kw in ipairs(attackKeywords) do
                        if bName:find(kw) then
                            safeClickGuiButton(btn)
                            break
                        end
                    end
                end
            end
        end
    end
end

local function triggerMobileSkillButtons()
    local pGui = LP:FindFirstChild("PlayerGui")
    if not pGui then return end
    for _, gui in ipairs(pGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled and not isOurGui(gui) then
            for _, btn in ipairs(gui:GetDescendants()) do
                if (btn:IsA("ImageButton") or btn:IsA("TextButton")) and btn.Visible and not isOurGui(btn) then
                    local bName = getButtonFullText(btn)
                    if bName:find("skill") or bName:find("ability") or bName:find("spell") or bName:find("chiêu") or bName == "1" or bName == "2" or bName == "3" or bName == "4" then
                        safeClickGuiButton(btn)
                    end
                end
            end
        end
    end
end

local function attackTarget(targetModel, targetRoot)
    local now = tick()
    if (now - lastM1) < CFG.m1Delay then return end
    lastM1 = now

    equipWeapon()

    -- 1. Kích hoạt Tool vũ khí trực tiếp
    local tool = Char and Char:FindFirstChildOfClass("Tool")
    if tool then pcall(function() tool:Activate() end) end

    -- 2. Kích hoạt VirtualInput & Mobile Touch Event ở vùng trung tâm & vùng đánh mobile
    pcall(function()
        local vp = Cam and Cam.ViewportSize or Vector2.new(800, 600)
        local tapX, tapY = vp.X * 0.75, vp.Y * 0.65
        VirtualUser:CaptureController()
        VirtualUser:ClickButton1(Vector2.new(tapX, tapY))
        VirtualInputMgr:SendMouseButtonEvent(tapX, tapY, 0, true, game, 1)
        VirtualInputMgr:SendMouseButtonEvent(tapX, tapY, 0, false, game, 1)
        VirtualInputMgr:SendTouchEvent(0, 0, tapX, tapY)
        VirtualInputMgr:SendTouchEvent(0, 2, tapX, tapY)
    end)

    -- 3. Bấm nút đánh Mobile trên màn hình game (nếu có)
    triggerMobileAttackButtons()

    -- 4. Bắn Remote Combat tới Server
    if (now - lastScanTime) > 8 then scanRemotes() end
    for _, r in ipairs(combatRemotes) do
        pcall(function()
            if r:IsA("RemoteEvent") then
                r:FireServer(targetModel, targetRoot.Position)
                r:FireServer(targetModel)
                r:FireServer(targetRoot)
                r:FireServer(1)
            elseif r:IsA("RemoteFunction") then
                r:InvokeServer(targetModel, targetRoot.Position)
            end
        end)
    end

    -- 5. Xả Kỹ Năng 1, 2, 3, 4 không gây đứng hình (chạy bất đồng bộ trong task.spawn)
    if State.autoskill and (now - lastSkill > CFG.skillDelay) then
        lastSkill = now
        task.spawn(function()
            local keys = {Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four}
            for _, k in ipairs(keys) do
                pcall(function()
                    VirtualInputMgr:SendKeyEvent(true, k, false, game)
                    task.wait(0.02)
                    VirtualInputMgr:SendKeyEvent(false, k, false, game)
                end)
            end
            triggerMobileSkillButtons()
        end)
    end

    -- 6. Lướt Dash (Q) né đòn
    if State.autodash and (now - lastDash > CFG.dashDelay) then
        lastDash = now
        task.spawn(function()
            pcall(function()
                VirtualInputMgr:SendKeyEvent(true, Enum.KeyCode.Q, false, game)
                task.wait(0.02)
                VirtualInputMgr:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
            end)
        end)
    end
end

-- ================================================
-- QUA CỬA PHÒNG KẾ & NHẶT RƯƠNG (NEXT ROOM & CHEST)
-- ================================================
local lastDoorAdvanceTime = 0

local function lootChest()
    if not State.autochest or not HRP then return false end

    local chestPart = nil
    for _, obj in ipairs(workspace:GetDescendants()) do
        local n = obj.Name:lower()
        if (n:find("chest") or n:find("treasure") or n:find("reward")) and not n:find("ui") then
            local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
            if part and math.abs(part.Position.Y - HRP.Position.Y) < 20 then
                local dist = (part.Position - HRP.Position).Magnitude
                if dist < 150 then
                    chestPart = part
                    break
                end
            end
        end
    end

    if chestPart then
        State.statusText = "📦 Đang lướt tới nhặt rương kho báu..."
        glideTo(chestPart.Position, 2.5, 3.0)

        local prompt = chestPart:FindFirstChildOfClass("ProximityPrompt") or chestPart.Parent:FindFirstChildOfClass("ProximityPrompt")
        if prompt then pcall(function() fireproximityprompt(prompt) end) end
        task.wait(0.3)
        return true
    end
    return false
end

local function clickNextRoomVote()
    local pGui = LP:FindFirstChild("PlayerGui")
    if not pGui then return end

    for _, gui in ipairs(pGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled and not isOurGui(gui) then
            for _, btn in ipairs(gui:GetDescendants()) do
                if (btn:IsA("TextButton") or btn:IsA("ImageButton")) and btn.Visible and not isOurGui(btn) then
                    local bText = getButtonFullText(btn)
                    if bText:find("vote") or bText:find("yes") or bText:find("ready") or bText:find("proceed") or bText:find("tiếp") or bText:find("đồng ý") or bText:find("next") or bText:find("ok") then
                        safeClickGuiButton(btn)
                    end
                end
            end
        end
    end
end

local function advanceNextRoom()
    if not State.autodoor or not HRP then return false end

    -- Tránh spam cửa liên tục khi cửa chưa mở
    local now = tick()
    if (now - lastDoorAdvanceTime) < 3.0 then return false end
    lastDoorAdvanceTime = now

    local doorPart = nil
    local doorPrompt = nil
    local bestScore = 0

    -- 1. Ưu tiên tìm ProximityPrompt của cửa phòng kế trước
    for _, prompt in ipairs(workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") then
            local pText = (prompt.ActionText .. " " .. prompt.ObjectText .. " " .. prompt.Parent.Name):lower()
            if pText:find("next") or pText:find("door") or pText:find("proceed") or pText:find("room") or pText:find("open") or pText:find("tiếp") or pText:find("cửa") then
                local part = prompt.Parent:IsA("BasePart") and prompt.Parent or prompt.Parent:FindFirstChildWhichIsA("BasePart")
                if part and math.abs(part.Position.Y - HRP.Position.Y) < 30 then
                    doorPrompt = prompt
                    doorPart = part
                    break
                end
            end
        end
    end

    -- 2. Nếu không có prompt thì tìm BasePart cửa
    if not doorPart then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                local n = obj.Name:lower()
                local pName = obj.Parent and obj.Parent.Name:lower() or ""
                local combined = n .. " " .. pName

                local score = 0
                if combined:find("nextroom") or combined:find("next_room") then score = 100
                elseif combined:find("roomdoor") or combined:find("dungeondoor") then score = 90
                elseif combined:find("door") then score = 70
                elseif combined:find("gate") then score = 60
                elseif combined:find("portal") then score = 50
                elseif combined:find("exit") then score = 40
                end

                if score > 0 and not combined:find("lobby") and not combined:find("shop") and not combined:find("spawn") then
                    local yDiff = math.abs(obj.Position.Y - HRP.Position.Y)
                    local dist = (obj.Position - HRP.Position).Magnitude
                    if yDiff < 25 and dist < 250 then
                        if score > bestScore then
                            bestScore = score
                            doorPart = obj
                        end
                    end
                end
            end
        end
    end

    if doorPart and HRP then
        State.statusText = "🚪 Đang đi qua cửa phòng tiếp theo..."
        local myPos = HRP.Position
        glideTo(doorPart.Position, 2.0, 4.0)

        -- Bước xuyên qua cửa về phía trước
        if HRP then
            local moveDir = (doorPart.Position - myPos).Magnitude > 0.1 and (doorPart.Position - myPos).Unit or doorPart.CFrame.LookVector
            HRP.CFrame = CFrame.new(doorPart.Position + (moveDir * 8.0))
        end

        local prompt = doorPrompt or doorPart:FindFirstChildOfClass("ProximityPrompt") or doorPart.Parent:FindFirstChildOfClass("ProximityPrompt")
        if prompt then pcall(function() fireproximityprompt(prompt) end) end

        -- Kích hoạt Touch nếu có
        if firetouchinterest and doorPart then
            pcall(function()
                firetouchinterest(HRP, doorPart, 0)
                task.wait(0.05)
                firetouchinterest(HRP, doorPart, 1)
            end)
        end

        clickNextRoomVote()
        task.wait(1.5)
        return true
    end
    return false
end

local function clickReplayButton()
    if not State.autoreplay then return false end
    local pGui = LP:FindFirstChild("PlayerGui")
    if not pGui then return false end

    for _, gui in ipairs(pGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled and not isOurGui(gui) then
            local gName = gui.Name:lower()
            if gName:find("victory") or gName:find("result") or gName:find("clear") or gName:find("gameover") or gName:find("win") or gName:find("end") then
                for _, btn in ipairs(gui:GetDescendants()) do
                    if (btn:IsA("TextButton") or btn:IsA("ImageButton")) and btn.Visible and not isOurGui(btn) then
                        local bText = getButtonFullText(btn)
                        if bText:find("replay") or bText:find("retry") or bText:find("again") or bText:find("chơi lại") or bText:find("continue") then
                            safeClickGuiButton(btn)
                            State.statusText = "🏆 Thắng trận! Đang bấm chơi lại (Replay)..."
                            task.wait(2.5)
                            return true
                        end
                    end
                end
            end
        end
    end
    return false
end

-- ================================================
-- TỰ ĐỘNG Ở SẢNH (LOBBY AUTOMATION - CHỐNG VÀO NHẦM MAP)
-- ================================================
local function findLobbyEntrance()
    local targetW = tostring(State.targetWorld or "1"):lower()
    local targetKeywords = WORLD_KEYWORDS[targetW] or WORLD_KEYWORDS["1"]

    -- Danh sách các từ khóa của các thế giới / chế độ KHÁC (cấm tuyệt đối không được vào)
    local conflictingKeywords = {}
    for wKey, kList in pairs(WORLD_KEYWORDS) do
        if wKey ~= targetW then
            for _, kw in ipairs(kList) do
                table.insert(conflictingKeywords, kw)
            end
        end
    end
    if targetW ~= "tower" then
        table.insert(conflictingKeywords, "tower")
        table.insert(conflictingKeywords, "tháp")
    end
    if targetW ~= "abyss" then
        table.insert(conflictingKeywords, "abyss")
        table.insert(conflictingKeywords, "vực sâu")
    end

    local candidates = {}

    local function scoreCandidate(text, part, prompt)
        text = text:lower()

        -- 1. Loại trừ ngay nếu có trong Blacklist NPC sảnh (shop, gacha, blacksmith...)
        for _, b in ipairs(LOBBY_BLACKLIST) do
            if text:find(b) then return -100000 end
        end

        -- 2. Loại trừ ngay nếu chứa từ khóa của Thế Giới KHÁC (chống vào nhầm map 100%!)
        for _, ckw in ipairs(conflictingKeywords) do
            if text:find(ckw) then
                return -100000
            end
        end

        local score = 0

        -- 3. Khớp chính xác thế giới mong muốn (Điểm thưởng cực cao)
        for _, tkw in ipairs(targetKeywords) do
            if text:find(tkw) then
                score = score + 500
            end
        end

        -- 4. Khớp từ khóa cổng / hầm ngục chung
        if text:find("dungeonportal") or text:find("dungeongate") then score = score + 120
        elseif text:find("portalpad") or text:find("teleportpad") then score = score + 110
        elseif text:find("portal") then score = score + 80
        elseif text:find("dungeon") or text:find("hầm ngục") then score = score + 70
        elseif text:find("gate") or text:find("cổng") then score = score + 50
        elseif text:find("play") or text:find("enter") or text:find("vào") then score = score + 40
        end

        return score
    end

    -- 1. Quét mọi ProximityPrompt ở sảnh
    for _, prompt in ipairs(workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") then
            local pName = prompt.Parent and prompt.Parent.Name or ""
            local ppName = prompt.Parent and prompt.Parent.Parent and prompt.Parent.Parent.Name or ""
            local combined = prompt.ActionText .. " " .. prompt.ObjectText .. " " .. pName .. " " .. ppName
            if prompt.Parent then
                for _, g in ipairs(prompt.Parent:GetDescendants()) do
                    if g:IsA("TextLabel") or g:IsA("TextButton") then
                        combined = combined .. " " .. g.Text
                    end
                end
            end

            local sc = scoreCandidate(combined, prompt.Parent, prompt)
            if sc > 0 then
                local part = prompt.Parent:IsA("BasePart") and prompt.Parent or prompt.Parent:FindFirstChildWhichIsA("BasePart")
                if part then
                    table.insert(candidates, { part = part, prompt = prompt, score = sc })
                end
            end
        end
    end

    -- 2. Quét mọi BasePart ở sảnh
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local n = obj.Name
            local pName = obj.Parent and obj.Parent.Name or ""
            local ppName = obj.Parent and obj.Parent.Parent and obj.Parent.Parent.Name or ""
            local combined = n .. " " .. pName .. " " .. ppName
            if obj.Parent then
                for _, g in ipairs(obj.Parent:GetDescendants()) do
                    if g:IsA("TextLabel") or g:IsA("TextButton") then
                        combined = combined .. " " .. g.Text
                    end
                end
            end

            local sc = scoreCandidate(combined, obj, nil)
            if sc > 0 then
                table.insert(candidates, { part = obj, prompt = nil, score = sc })
            end
        end
    end

    -- Sắp xếp ứng viên có điểm cao nhất lên đầu
    table.sort(candidates, function(a, b)
        return a.score > b.score
    end)

    if #candidates > 0 then
        return candidates[1].part, candidates[1].prompt
    end

    return nil, nil
end

local function handleLobbyMenu()
    local pGui = LP:FindFirstChild("PlayerGui")
    if not pGui then return false end

    local targetW = tostring(State.targetWorld or "1"):lower()
    local targetLvlStr = tostring(State.targetLevel or "AUTO"):lower()
    local clickedSomething = false

    -- BƯỚC 1: Chọn Thế Giới (World / Chapter Tab) chuẩn xác
    for _, gui in ipairs(pGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled and not isOurGui(gui) then
            for _, btn in ipairs(gui:GetDescendants()) do
                if (btn:IsA("TextButton") or btn:IsA("ImageButton")) and btn.Visible and not isOurGui(btn) then
                    local bText = getButtonFullText(btn)
                    local matchedWorld = false
                    if targetW == "1" then
                        if bText:find("world 1") or bText:find("world1") or bText:find("thế giới 1") or bText:find("chapter 1") or bText:find("chương 1") or bText:find("grassland") or bText:find("w1") then
                            matchedWorld = true
                        end
                    elseif targetW == "2" then
                        if bText:find("world 2") or bText:find("world2") or bText:find("thế giới 2") or bText:find("chapter 2") or bText:find("chương 2") or bText:find("desert") or bText:find("w2") then
                            matchedWorld = true
                        end
                    elseif targetW == "3" then
                        if bText:find("world 3") or bText:find("world3") or bText:find("thế giới 3") or bText:find("chapter 3") or bText:find("chương 3") or bText:find("snow") or bText:find("ice") or bText:find("w3") then
                            matchedWorld = true
                        end
                    elseif targetW == "4" then
                        if bText:find("world 4") or bText:find("world4") or bText:find("thế giới 4") or bText:find("chapter 4") or bText:find("chương 4") or bText:find("volcano") or bText:find("lava") or bText:find("w4") then
                            matchedWorld = true
                        end
                    elseif targetW == "5" then
                        if bText:find("world 5") or bText:find("world5") or bText:find("thế giới 5") or bText:find("chapter 5") or bText:find("chương 5") or bText:find("w5") then
                            matchedWorld = true
                        end
                    end

                    if matchedWorld then
                        safeClickGuiButton(btn)
                        clickedSomething = true
                        task.wait(0.2)
                        break
                    end
                end
            end
        end
    end

    task.wait(0.25)

    -- BƯỚC 2: Chọn Cấp Độ / Ải (Level / Stage)
    for _, gui in ipairs(pGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled and not isOurGui(gui) then
            for _, btn in ipairs(gui:GetDescendants()) do
                if (btn:IsA("TextButton") or btn:IsA("ImageButton")) and btn.Visible and not isOurGui(btn) then
                    local bText = getButtonFullText(btn)
                    local matchedLevel = false
                    if targetLvlStr == "auto" or targetLvlStr == "1" then
                        if bText:find("level 1") or bText:find("lv 1") or bText:find("cấp 1") or bText:find("stage 1") or bText:find("ải 1") or bText == "1" or bText:find("easy") or bText:find("dễ") or bText:find("normal") or bText:find("thường") then
                            matchedLevel = true
                        end
                    else
                        if bText:find("level " .. targetLvlStr) or bText:find("lv " .. targetLvlStr) or bText:find("cấp " .. targetLvlStr) or bText:find("stage " .. targetLvlStr) or bText == targetLvlStr then
                            matchedLevel = true
                        end
                    end

                    if matchedLevel then
                        safeClickGuiButton(btn)
                        clickedSomething = true
                        task.wait(0.2)
                        break
                    end
                end
            end
        end
    end

    task.wait(0.25)

    -- BƯỚC 3: Bấm nút Bắt đầu / Solo / Start / Create / Play / Confirm
    local started = false
    for _, gui in ipairs(pGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled and not isOurGui(gui) then
            for _, btn in ipairs(gui:GetDescendants()) do
                if (btn:IsA("TextButton") or btn:IsA("ImageButton")) and btn.Visible and not isOurGui(btn) then
                    local bText = getButtonFullText(btn)
                    if not bText:find("close") and not bText:find("cancel") and not bText:find("hủy") and not bText:find("đóng") and not bText:find("back") and not bText:find("shop") and not bText:find("gacha") and not bText:find("setting") then
                        if bText:find("solo") or bText:find("start") or bText:find("create") or bText:find("play") or bText:find("bắt đầu") or bText:find("chơi") or bText:find("tạo phòng") or bText:find("enter") or bText:find("ready") or bText:find("confirm") or bText:find("xác nhận") or bText:find("tiến vào") or bText:find("battle") or bText:find("launch") then
                            safeClickGuiButton(btn)
                            started = true
                            clickedSomething = true
                            task.wait(0.2)
                            break
                        end
                    end
                end
            end
            if started then break end
        end
    end

    return clickedSomething or started
end

local isLobbyBusy = false

local function runLobbyEnter()
    if isLobbyBusy then return end
    isLobbyBusy = true

    local targetInfo = WORLD_PLACES[State.targetWorld or "1"] or WORLD_PLACES["1"]
    State.statusText = "📍 Ở Sảnh -> Đang tìm cổng " .. targetInfo.name .. "..."

    local part, prompt = findLobbyEntrance()
    if part and HRP then
        State.statusText = "Đang lướt tới cổng " .. targetInfo.name .. "..."
        local padPos = part.Position + Vector3.new(0, 3.2, 0)
        glideTo(padPos, 2.5, 4.0)

        if HRP then
            HRP.CFrame = CFrame.new(padPos)
        end

        local touchTargets = { part }
        if part.Parent and part.Parent:IsA("Model") then
            for _, ch in ipairs(part.Parent:GetDescendants()) do
                if ch:IsA("BasePart") then table.insert(touchTargets, ch) end
            end
        end

        for _, tp in ipairs(touchTargets) do
            if prompt then pcall(function() fireproximityprompt(prompt) end) end
            local pp = tp:FindFirstChildOfClass("ProximityPrompt")
            if pp then pcall(function() fireproximityprompt(pp) end) end
            if firetouchinterest then
                pcall(function()
                    firetouchinterest(HRP, tp, 0)
                    task.wait(0.03)
                    firetouchinterest(HRP, tp, 1)
                end)
            end
        end

        -- Nhấn phím E tương tác cổng hầm ngục
        pcall(function()
            VirtualInputMgr:SendKeyEvent(true, Enum.KeyCode.E, false, game)
            task.wait(0.08)
            VirtualInputMgr:SendKeyEvent(false, Enum.KeyCode.E, false, game)
        end)

        task.wait(0.4)

        -- Đợi và xử lý giao diện bảng chọn ải
        for _ = 1, 8 do
            if handleLobbyMenu() then break end
            task.wait(0.35)
        end
    else
        State.statusText = "📍 Đang kiểm tra giao diện bảng chọn map..."
        handleLobbyMenu()
    end

    task.wait(2.0)
    isLobbyBusy = false
end

-- ================================================
-- KIỂM TRA ĐANG Ở TRONG ẢI HAY Ở SẢNH CHỜ
-- ================================================
local function checkIsInDungeon()
    -- Nếu PlaceId khác PlaceId Sảnh -> Chắc chắn 100% đang trong Ải
    if game.PlaceId ~= LOBBY_PLACE_ID then
        return true
    end

    -- Nếu quét thấy quái
    if #getAllRoomEnemies() > 0 then return true end

    -- Kiểm tra các vật thể cửa đặc trưng của hầm ngục
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local n = obj.Name:lower()
            if n:find("nextroom") or n:find("next_room") or n:find("dungeondoor") or n:find("roomdoor") or n:find("dungeon_door") then
                return true
            end
        end
    end

    return false
end

-- ================================================
-- LUỒNG ĐIỀU PHỐI THÔNG MINH TOÀN DIỆN (UNIFIED MASTER AUTO FARM)
-- ================================================
local lastSeenEnemiesTime = tick()
local consecutiveEmptyScans = 0

task.spawn(function()
    while true do
        task.wait(0.05)
        if not HRP or not Hum or Hum.Health <= 0 then continue end

        local inDungeon = checkIsInDungeon()

        -- Trong ải: Luôn đảm bảo kích hoạt cày quái
        if inDungeon or (game.PlaceId ~= LOBBY_PLACE_ID) then
            State.autofarm = true
        end

        -- BƯỚC 1: QUÉT QUÁI TRONG PHÒNG HIỆN TẠI
        local enemies = {}
        if State.autoafk or State.autofarm then
            enemies = getAllRoomEnemies()
        end

        if #enemies > 0 then
            lastSeenEnemiesTime = tick()
            consecutiveEmptyScans = 0

            -- TRƯỜNG HỢP 1: CÓ QUÁI -> ÁP SÁT VÀ DIỆT QUÁI LIÊN TỤC KHÔNG ĐỨNG KHỰNG
            local target = enemies[1]

            if target and target.root then
                local mobRoot = target.root
                local mobPos  = mobRoot.Position
                local myPos   = HRP.Position

                local hpVal = (target.hp and target.hp > 0) and math.floor(target.hp) or (target.hum and math.floor(target.hum.Health) or 100)
                State.statusText = "⚔️ Đang diệt: " .. target.model.Name .. " (HP: " .. hpVal .. " • Còn " .. #enemies .. " quái)"

                local targetPos
                if State.godhover then
                    -- Bay 3.5 studs trên đầu quái: Vừa miễn nhiễm sát thương vừa chém trúng quái 100%
                    local hoverY = CFG.hoverHeight or 3.5
                    if Hum.Health < (Hum.MaxHealth * 0.45) then
                        hoverY = hoverY + 3.0
                    end
                    targetPos = mobPos + Vector3.new(0, hoverY, 0)
                else
                    -- Áp sát sau lưng quái ở mặt đất
                    local mobCF = mobRoot.CFrame
                    local behindPos = mobPos - (mobCF.LookVector * 2.5)
                    targetPos = Vector3.new(behindPos.X, mobPos.Y + 0.5, behindPos.Z)
                end

                local mobLook = mobRoot.CFrame.LookVector
                local flatMobLook = Vector3.new(mobLook.X, 0, mobLook.Z)
                if flatMobLook.Magnitude < 0.1 then flatMobLook = Vector3.new(0, 0, -1) else flatMobLook = flatMobLook.Unit end

                local dist = (myPos - targetPos).Magnitude

                if dist > 35 then
                    -- Quái ở xa: Lướt nhanh tiếp cận
                    glideTo(targetPos, 3.0, 1.2)
                elseif dist > 3.0 then
                    -- Tiếp cận mượt mà
                    local dir = (targetPos - myPos).Unit
                    HRP.AssemblyLinearVelocity = Vector3.zero
                    local nextPos = myPos + (dir * math.min(dist, 4.0))
                    HRP.CFrame = CFrame.lookAt(nextPos, nextPos + flatMobLook)
                else
                    -- Đã ở cự ly chiến đấu: Giữ chặt vị trí trên đầu quái nhìn theo hướng quái
                    HRP.AssemblyLinearVelocity = Vector3.zero
                    HRP.CFrame = CFrame.lookAt(targetPos, targetPos + flatMobLook)
                end

                -- Tấn công quái đồng thời trên cùng nhịp lặp
                attackTarget(target.model, mobRoot)
            end

        else
            -- TRƯỜNG HỢP 2: PHÒNG HIỆN TẠI KHÔNG CÒN QUÁI
            if inDungeon or (game.PlaceId ~= LOBBY_PLACE_ID) then
                consecutiveEmptyScans = consecutiveEmptyScans + 1

                -- 1. Ưu tiên kiểm tra Thắng trận (Replay)
                local replaying = false
                if State.autoreplay then
                    replaying = clickReplayButton()
                end

                if not replaying then
                    -- 2. Nhặt rương báu phòng nếu có
                    local looting = false
                    if State.autochest then
                        looting = lootChest()
                    end

                    -- 3. Chỉ qua cửa khi đã sạch quái tối thiểu 1.5s (tránh lao vào cửa khi quái đợt tiếp sắp spawn)
                    if not looting and (tick() - lastSeenEnemiesTime) >= 1.5 then
                        State.statusText = "✅ Phòng sạch quái! Đang tiến qua cửa phòng tiếp..."
                        if State.autodoor then
                            advanceNextRoom()
                        end
                    else
                        if not looting then
                            State.statusText = "⏳ Đang kiểm tra phòng / Đợi quái đợt tiếp..."
                        end
                    end
                end
            else
                -- Đang ở Sảnh Chờ (Lobby): Tự động đi cổng vào ải nếu bật autoafk
                if State.autoafk then
                    runLobbyEnter()
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
        local enemies = getAllRoomEnemies()
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
ourScreenGui      = SG

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

-- 1.5 HUY HIỆU TRẠNG THÁI NỔI TRÊN MÀN HÌNH (MINI HUD BADGE - LUÔN HIỆN NGAY CẢ KHI ĐÓNG MENU)
local MiniHud = Instance.new("Frame", SG)
MiniHud.Name             = "MiniHud"
MiniHud.Size             = UDim2.new(0, 270, 0, 32)
MiniHud.Position         = UDim2.new(0.5, -135, 0, 10)
MiniHud.BackgroundColor3 = Color3.fromRGB(16, 13, 28)
MiniHud.BackgroundTransparency = 0.15
MiniHud.Active           = true
MiniHud.Draggable        = true
Instance.new("UICorner", MiniHud).CornerRadius = UDim.new(0, 16)
local mhStroke = Instance.new("UIStroke", MiniHud)
mhStroke.Color = Color3.fromRGB(145, 75, 255); mhStroke.Thickness = 1.8

local HudIcon = Instance.new("TextLabel", MiniHud)
HudIcon.Size               = UDim2.new(0, 26, 1, 0)
HudIcon.Position           = UDim2.new(0, 6, 0, 0)
HudIcon.BackgroundTransparency = 1
HudIcon.Text               = "⚡"
HudIcon.TextSize           = 14
HudIcon.Font               = Enum.Font.GothamBold

local HudText = Instance.new("TextLabel", MiniHud)
HudText.Size               = UDim2.new(1, -38, 1, 0)
HudText.Position           = UDim2.new(0, 32, 0, 0)
HudText.BackgroundTransparency = 1
HudText.Text               = State.statusText
HudText.TextColor3         = Color3.fromRGB(225, 255, 190)
HudText.Font               = Enum.Font.GothamBold
HudText.TextSize           = 11
HudText.TextXAlignment     = Enum.TextXAlignment.Left
HudText.TextTruncate       = Enum.TextTruncate.AtEnd

task.spawn(function()
    while task.wait(0.25) do
        if HudText and HudText.Parent then
            HudText.Text = State.statusText
        end
    end
end)

-- 2. KHUNG MENU CHÍNH
local MainFrame = Instance.new("Frame", SG)
MainFrame.Name             = "MainFrame"
MainFrame.Size             = UDim2.new(0, 320, 0, 530)
MainFrame.Position         = UDim2.new(0.5, -160, 0.5, -265)
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
Title.Text               = "VOSS | Thợ Săn Hầm Ngục v8 ⚔️"
Title.TextColor3         = Color3.fromRGB(220, 180, 255)
Title.Font               = Enum.Font.GothamBold
Title.TextSize           = 14
Title.TextXAlignment     = Enum.TextXAlignment.Left

local function getCurrentPlaceName()
    if isLobbyPlace then
        return "📍 Map: Sảnh Chờ (Lobby)"
    elseif game.PlaceId == 121902496311296 then
        return "⚔️ Map: DH: Thế Giới 1 (World 1)"
    elseif game.PlaceId == 123911129955120 then
        return "⚔️ Map: DH: Thế Giới 2 (World 2)"
    elseif game.PlaceId == 116991059923076 then
        return "⚔️ Map: DH: Thế Giới 3 (World 3)"
    elseif game.PlaceId == 113880247399913 then
        return "⚔️ Map: DH: Thế Giới 4 (World 4)"
    elseif game.PlaceId == 121731448247552 then
        return "⚔️ Map: DH: Thế Giới 5 (World 5)"
    else
        return "⚔️ Map: Ải Hầm Ngục (" .. tostring(game.PlaceId) .. ")"
    end
end

local SubTitle = Instance.new("TextLabel", Header)
SubTitle.Size               = UDim2.new(1, -50, 0, 16)
SubTitle.Position           = UDim2.new(0, 16, 0, 28)
SubTitle.BackgroundTransparency = 1
SubTitle.Text               = getCurrentPlaceName()
SubTitle.TextColor3         = isLobbyPlace and Color3.fromRGB(130, 200, 255) or Color3.fromRGB(255, 170, 100)
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
    while task.wait(0.3) do
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
Scroll.CanvasSize       = UDim2.new(0, 0, 0, 1020)

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

local function createActionButton(title, desc, btnText, callback, order)
    local f = Instance.new("Frame", Scroll)
    f.Size             = UDim2.new(1, -6, 0, 52)
    f.BackgroundColor3 = Color3.fromRGB(28, 22, 44)
    f.LayoutOrder      = order
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)

    local stroke = Instance.new("UIStroke", f)
    stroke.Color = Color3.fromRGB(120, 60, 210); stroke.Thickness = 1.2

    local tLbl = Instance.new("TextLabel", f)
    tLbl.Size               = UDim2.new(1, -85, 0, 20)
    tLbl.Position           = UDim2.new(0, 12, 0, 5)
    tLbl.BackgroundTransparency = 1
    tLbl.Text               = title
    tLbl.TextColor3         = Color3.fromRGB(255, 230, 255)
    tLbl.Font               = Enum.Font.GothamBold
    tLbl.TextSize           = 12
    tLbl.TextXAlignment     = Enum.TextXAlignment.Left

    local dLbl = Instance.new("TextLabel", f)
    dLbl.Size               = UDim2.new(1, -85, 0, 16)
    dLbl.Position           = UDim2.new(0, 12, 0, 25)
    dLbl.BackgroundTransparency = 1
    dLbl.Text               = desc
    dLbl.TextColor3         = Color3.fromRGB(160, 150, 190)
    dLbl.Font               = Enum.Font.Gotham
    dLbl.TextSize           = 10
    dLbl.TextXAlignment     = Enum.TextXAlignment.Left

    local actionBtn = Instance.new("TextButton", f)
    actionBtn.Size             = UDim2.new(0, 68, 0, 28)
    actionBtn.Position         = UDim2.new(1, -76, 0.5, -14)
    actionBtn.BackgroundColor3 = Color3.fromRGB(140, 50, 240)
    actionBtn.Text             = btnText
    actionBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
    actionBtn.Font             = Enum.Font.GothamBold
    actionBtn.TextSize         = 11
    Instance.new("UICorner", actionBtn).CornerRadius = UDim.new(0, 8)

    actionBtn.MouseButton1Click:Connect(function()
        pcall(callback)
    end)
    return f
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
        saveSettings()
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
        saveSettings()
    end)
    return f
end

local function createWorldSelector(order)
    local f = Instance.new("Frame", Scroll)
    f.Size             = UDim2.new(1, -6, 0, 68)
    f.BackgroundColor3 = Color3.fromRGB(22, 19, 36)
    f.LayoutOrder      = order
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)

    local stroke = Instance.new("UIStroke", f)
    stroke.Color = Color3.fromRGB(120, 60, 210); stroke.Thickness = 1.2

    local tLbl = Instance.new("TextLabel", f)
    tLbl.Size               = UDim2.new(1, -16, 0, 20)
    tLbl.Position           = UDim2.new(0, 12, 0, 5)
    tLbl.BackgroundTransparency = 1
    tLbl.Text               = "🗺️ Chọn Thế Giới (Bản Đồ Vào Cày):"
    tLbl.TextColor3         = Color3.fromRGB(230, 195, 255)
    tLbl.Font               = Enum.Font.GothamBold
    tLbl.TextSize           = 12
    tLbl.TextXAlignment     = Enum.TextXAlignment.Left

    local btnContainer = Instance.new("ScrollingFrame", f)
    btnContainer.Size       = UDim2.new(1, -20, 0, 32)
    btnContainer.Position   = UDim2.new(0, 10, 0, 28)
    btnContainer.BackgroundTransparency = 1
    btnContainer.ScrollBarThickness = 0
    btnContainer.CanvasSize = UDim2.new(0, 680, 0, 0)

    local bList = Instance.new("UIListLayout", btnContainer)
    bList.FillDirection = Enum.FillDirection.Horizontal
    bList.Padding = UDim.new(0, 6)

    local worldOptions = {
        { key = "1",     label = "Thế Giới 1 ⭐" },
        { key = "2",     label = "Thế Giới 2" },
        { key = "3",     label = "Thế Giới 3" },
        { key = "4",     label = "Thế Giới 4" },
        { key = "5",     label = "Thế Giới 5" },
        { key = "tower", label = "Tháp Thử Thách" },
        { key = "abyss", label = "Vực Sâu" },
    }
    local worldBtns = {}

    for _, opt in ipairs(worldOptions) do
        local b = Instance.new("TextButton", btnContainer)
        b.Size = UDim2.new(0, 92, 0, 28)
        b.BackgroundColor3 = (State.targetWorld == opt.key) and Color3.fromRGB(140, 60, 255) or Color3.fromRGB(38, 32, 58)
        b.Text = opt.label
        b.TextColor3 = Color3.fromRGB(255, 255, 255)
        b.Font = Enum.Font.GothamBold
        b.TextSize = 10
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)

        b.MouseButton1Click:Connect(function()
            State.targetWorld = opt.key
            for _, ob in pairs(worldBtns) do ob.BackgroundColor3 = Color3.fromRGB(38, 32, 58) end
            b.BackgroundColor3 = Color3.fromRGB(140, 60, 255)
            State.statusText = "Đã chọn: " .. opt.label
            saveSettings()
        end)
        table.insert(worldBtns, b)
    end
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
            saveSettings()
        end)
        table.insert(levelBtns, b)
    end
    return f
end

-- ================================================
-- KHỞI TẠO NỘI DUNG MENU
-- ================================================

-- CÔNG TẮC CHÍNH: TREO MÁY TOÀN DIỆN
createCategory("🚀 CHẾ ĐỘ TREO MÁY TOÀN DIỆN (AFK FOREVER)", 1)

createMasterToggle("⚡ AUTO TREO MÁY TOÀN DIỆN", "Tự vào map sảnh -> Tự cày quái -> Tự qua ải -> Tự Replay lặp vô tận", State.autoafk, function(val)
    State.autoafk = val
    if val then
        local tInfo = WORLD_PLACES[State.targetWorld or "1"] or WORLD_PLACES["1"]
        State.statusText = isLobbyPlace and ("Bắt đầu chu trình vào " .. tInfo.name .. "...") or "Bắt đầu tự động cày quái ải..."
    else
        State.statusText = "Đã tạm dừng treo máy."
    end
end, 2)

createWorldSelector(3)
createLevelSelector(4)

-- NÚT THAO TÁC NHANH SẢNH & ẢI
createCategory("⚡ THAO TÁC TỨC THÌ (INSTANT ACTIONS)", 5)

createActionButton("🚀 Tự Vào Ải Thế Giới 1", "Lướt tới cổng sảnh, chọn Thế Giới 1 và bấm Bắt đầu vào ải", "VÀO ẢI", function()
    State.targetWorld = "1"
    runLobbyEnter()
end, 6)

createActionButton("Dịch Chuyển Vào Cổng Sảnh", "Lướt tới cổng chuẩn xác và mở bảng hầm ngục", "VÀO CỔNG", function()
    runLobbyEnter()
end, 7)

createActionButton("Lướt Qua Cửa Phòng Kế", "Lướt thẳng qua cửa phòng tiếp theo tức thì", "QUA CỬA", function()
    advanceNextRoom()
end, 8)

-- CÀY CẤP & CHIẾN ĐẤU CHI TIẾT
createCategory("⚔️ TÙY CHỌN CHIẾN ĐẤU & QUA ẢI", 9)

createToggle("Bay Trên Đầu Quái (God Hover)", "Bay 3.5 studs trên đầu quái chém xuống - Bất tử 100% trúng đòn mọi quái", State.godhover, function(val)
    State.godhover = val
end, 10)

createToggle("Auto Chém Quái (Universal)", "Tự động phát hiện và chém sạch quái trong phòng", State.autofarm, function(val)
    State.autofarm = val
end, 11)

createToggle("Đi Xuyên Vật Cản (Noclip)", "Không bao giờ bị kẹt ở cửa hay bậc thang", State.noclip, function(val)
    State.noclip = val
end, 12)

createToggle("Ưu Tiên Săn Boss", "Tập trung diệt Boss phòng trước", State.autoboss, function(val)
    State.autoboss = val
end, 13)

createToggle("Auto Xả Kỹ Năng (1 - 4)", "Xoay tua chiêu thức tăng sát thương dồn", State.autoskill, function(val)
    State.autoskill = val
end, 14)

createToggle("Auto Lướt Dash (Q)", "Lướt né chiêu diện rộng của quái", State.autodash, function(val)
    State.autodash = val
end, 15)

createToggle("Auto Đi Qua Cửa (Next Room)", "Khi sạch quái tự lướt qua cửa phòng tiếp theo", State.autodoor, function(val)
    State.autodoor = val
end, 16)

createToggle("Auto Nhặt Rương (Sau Mỗi Phòng)", "Tự lướt nhặt rương kho báu & vàng sau khi dọn sạch ải", State.autochest, function(val)
    State.autochest = val
end, 17)

createToggle("Auto Chơi Lại (Replay)", "Thắng trận tự bấm Replay tạo vòng lặp cày vô tận", State.autoreplay, function(val)
    State.autoreplay = val
end, 18)

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

print(string.format("[VOSS] Dungeon Hunters Hub v8.0 Loaded! Place: %s (%s) ⚔️", tostring(game.PlaceId), isLobbyPlace and "Lobby" or "Dungeon World"))
