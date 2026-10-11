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
    autoboss      = false, -- Ưu tiên diệt Boss trước
    autoskill     = true,  -- Tự xả chiêu 1, 2, 3, 4
    autodash      = true,  -- Tự lướt Dash (Q) né chiêu
    autodoor      = true,  -- Tự đi qua cửa phòng tiếp theo
    autochest     = true,  -- Tự nhặt rương kho báu
    autoreplay    = true,  -- Tự bấm Replay khi thắng trận
    noclip        = true,  -- Đi xuyên tường khi farm chống kẹt
    speed         = false,
    fly           = false,
    nofall        = true,
    esp_mobs      = false,
    esp_chests    = false,
    targetWorld   = "1",    -- "1", "2", "3", "4", "5", "tower", "abyss"
    targetLevel   = "AUTO", -- "AUTO", "1", "2", "3", "4", "5"
    statusText    = isLobbyPlace and "📍 Đang ở Sảnh Chờ (Lobby)" or "⚔️ Đang trong ải hầm ngục",
}

local CFG = {
    walkspeed   = 55,
    flyspeed    = 50,
    glideSpeed  = 50,
    m1Delay     = 0.12,
    skillDelay  = 1.3,
    dashDelay   = 4.0,
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
                autoboss   = State.autoboss,
                autoskill  = State.autoskill,
                autodash   = State.autodash,
                autodoor   = State.autodoor,
                autochest  = State.autochest,
                autoreplay = State.autoreplay,
                noclip     = State.noclip,
                speed      = State.speed,
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
end
loadSettings()

-- Nếu đang ở trong map ải và đã bật autoafk thì luôn kích hoạt farm
if not isLobbyPlace then
    State.autofarm = true
    if State.autoafk then
        State.statusText = "⚔️ Đã vào map ải! Đang tự động tìm và diệt quái..."
    end
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

-- Noclip tự động khi Auto Farm để không bao giờ bị kẹt
RunService.Stepped:Connect(function()
    if (State.autoafk or State.autofarm) and State.noclip and Char then
        for _, part in ipairs(Char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end)

-- Duy trì tốc độ và chống rơi
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
-- DI CHUYỂN MƯỢT MÀ CHỐNG KẸT (NOCLIP GLIDE PATHING)
-- ================================================
local function glideTo(targetPos, stopDist, maxSeconds)
    if not HRP or not Hum or Hum.Health <= 0 then return false end
    stopDist   = stopDist or 3.0
    maxSeconds = maxSeconds or 5.0

    local startTime = tick()
    Hum.PlatformStand = false

    while (tick() - startTime) < maxSeconds do
        if not HRP or not Hum or Hum.Health <= 0 then break end

        local curPos = HRP.Position
        local diff   = targetPos - curPos
        local dist   = diff.Magnitude

        if dist <= stopDist then
            return true
        end

        local stepSpeed = math.min(CFG.glideSpeed, dist * 6)
        local dir = diff.Unit
        local nextPos = curPos + (dir * (stepSpeed * 0.05))

        HRP.AssemblyLinearVelocity = Vector3.zero
        HRP.CFrame = CFrame.new(nextPos, Vector3.new(targetPos.X, nextPos.Y, targetPos.Z))

        task.wait(0.04)
    end

    if HRP then
        return (HRP.Position - targetPos).Magnitude <= (stopDist + 2.5)
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

local function getAllRoomEnemies()
    local enemies = {}
    local seen = {}
    if not HRP then return enemies end

    local myPos = HRP.Position

    -- 1. Quét mọi Humanoid còn sống trong toàn bộ workspace
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Humanoid") and obj.Health > 0 then
            local model = obj.Parent
            if model and model:IsA("Model") and not seen[model] and model ~= Char then
                -- Bỏ qua người chơi thật
                if not Players:GetPlayerFromCharacter(model) then
                    seen[model] = true
                    local nLower = model.Name:lower()

                    -- Kiểm tra nếu là NPC sảnh
                    local isLobbyNPC = false
                    for _, b in ipairs(LOBBY_BLACKLIST) do
                        if nLower:find(b) then isLobbyNPC = true; break end
                    end

                    if not isLobbyNPC then
                        local root = model.PrimaryPart 
                            or model:FindFirstChild("HumanoidRootPart") 
                            or model:FindFirstChild("Torso") 
                            or model:FindFirstChild("UpperTorso")
                            or model:FindFirstChildWhichIsA("BasePart")

                        if root then
                            local dist = (myPos - root.Position).Magnitude
                            local isBoss = nLower:find("boss") or (obj.MaxHealth > 2500) or nLower:find("queen") or nLower:find("king")

                            table.insert(enemies, {
                                model = model,
                                root  = root,
                                hum   = obj,
                                boss  = isBoss,
                                dist  = dist
                            })
                        end
                    end
                end
            end
        end
    end

    -- 2. Dự phòng: Quét quái dùng Value Object HP
    if #enemies == 0 then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if (obj:IsA("IntValue") or obj:IsA("NumberValue")) and (obj.Name:lower() == "health" or obj.Name:lower() == "hp") and obj.Value > 0 then
                local model = obj.Parent
                if model and model:IsA("Model") and not seen[model] and model ~= Char and not Players:GetPlayerFromCharacter(model) then
                    seen[model] = true
                    local root = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
                    if root then
                        table.insert(enemies, {
                            model = model,
                            root  = root,
                            boss  = false,
                            dist  = (myPos - root.Position).Magnitude
                        })
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
            local t = bp:FindFirstChildOfClass("Tool")
            if t and Hum then pcall(function() Hum:EquipTool(t) end) end
        end
    end
end

local lastM1    = 0
local lastSkill = 0
local lastDash  = 0

local function triggerMobileSkillButtons()
    local pGui = LP:FindFirstChild("PlayerGui")
    if not pGui then return end
    for _, gui in ipairs(pGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled and not isOurGui(gui) then
            for _, btn in ipairs(gui:GetDescendants()) do
                if (btn:IsA("ImageButton") or btn:IsA("TextButton")) and btn.Visible and not isOurGui(btn) then
                    local bName = (btn.Name .. " " .. (btn:IsA("TextButton") and btn.Text or "")):lower()
                    if bName:find("skill") or bName:find("ability") or bName:find("spell") or bName == "1" or bName == "2" or bName == "3" or bName == "4" then
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

local function attackTarget(targetModel, targetRoot)
    local now = tick()
    if (now - lastM1) < CFG.m1Delay then return end
    lastM1 = now

    equipWeapon()

    -- 1. Kích hoạt Tool vũ khí nếu có
    local tool = Char and Char:FindFirstChildOfClass("Tool")
    if tool then pcall(function() tool:Activate() end) end

    -- 2. Kích hoạt M1 thông qua VirtualUser & MouseEvent ở tọa độ an toàn (120, 120)
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton1(Vector2.new(120, 120))
        VirtualUser:Button1Down(Vector2.new(120, 120))
        task.wait(0.01)
        VirtualUser:Button1Up(Vector2.new(120, 120))
    end)

    pcall(function()
        VirtualInputMgr:SendMouseButtonEvent(120, 120, 0, true, game, 1)
        task.wait(0.01)
        VirtualInputMgr:SendMouseButtonEvent(120, 120, 0, false, game, 1)
    end)

    -- 3. Bắn Remote Combat tới Server
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

    -- 4. Xả Kỹ Năng 1, 2, 3, 4 (Phím bàn phím + Nút cảm ứng Mobile)
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
            task.wait(0.03)
            VirtualInputMgr:SendKeyEvent(true, Enum.KeyCode.Four, false, game)
            task.wait(0.02)
            VirtualInputMgr:SendKeyEvent(false, Enum.KeyCode.Four, false, game)
        end)
        triggerMobileSkillButtons()
    end

    -- 5. Lướt Dash (Q) né đòn
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
-- QUA CỬA PHÒNG KẾ & NHẶT RƯƠNG (NEXT ROOM & CHEST)
-- ================================================
local lastDoorAdvanceTime = 0

local function lootChest()
    if not State.autochest or not HRP then return end

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
        glideTo(chestPart.Position, 2.5, 4.0)

        local prompt = chestPart:FindFirstChildOfClass("ProximityPrompt") or chestPart.Parent:FindFirstChildOfClass("ProximityPrompt")
        if prompt then pcall(function() fireproximityprompt(prompt) end) end
        task.wait(0.3)
    end
end

local function clickNextRoomVote()
    local pGui = LP:FindFirstChild("PlayerGui")
    if not pGui then return end

    for _, gui in ipairs(pGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled and not isOurGui(gui) then
            for _, btn in ipairs(gui:GetDescendants()) do
                if (btn:IsA("TextButton") or btn:IsA("ImageButton")) and btn.Visible and not isOurGui(btn) then
                    local bText = (btn.Name .. " " .. (btn:IsA("TextButton") and btn.Text or "")):lower()
                    if bText:find("vote") or bText:find("yes") or bText:find("ready") or bText:find("proceed") or bText:find("tiếp") or bText:find("đồng ý") or bText:find("next") or bText:find("ok") then
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

local function advanceNextRoom()
    if not State.autodoor or not HRP then return end

    -- Tránh spam cửa liên tục khi cửa chưa mở
    local now = tick()
    if (now - lastDoorAdvanceTime) < 3.0 then return end
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
    end
end

local function clickReplayButton()
    if not State.autoreplay then return end
    local pGui = LP:FindFirstChild("PlayerGui")
    if not pGui then return end

    for _, gui in ipairs(pGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled and not isOurGui(gui) then
            local gName = gui.Name:lower()
            if gName:find("victory") or gName:find("result") or gName:find("clear") or gName:find("gameover") or gName:find("win") or gName:find("end") then
                for _, btn in ipairs(gui:GetDescendants()) do
                    if (btn:IsA("TextButton") or btn:IsA("ImageButton")) and btn.Visible and not isOurGui(btn) then
                        local bText = (btn.Name .. " " .. (btn:IsA("TextButton") and btn.Text or "")):lower()
                        if bText:find("replay") or bText:find("retry") or bText:find("again") or bText:find("chơi lại") or bText:find("continue") then
                            pcall(function()
                                firesignal(btn.MouseButton1Click)
                                firesignal(btn.Activated)
                            end)
                            State.statusText = "🏆 Thắng trận! Đang bấm chơi lại (Replay)..."
                            task.wait(2.5)
                            return
                        end
                    end
                end
            end
        end
    end
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
    -- Cấm cả các chế độ đặc biệt khác nếu không phải mục tiêu
    if targetW ~= "tower" then
        table.insert(conflictingKeywords, "tower")
        table.insert(conflictingKeywords, "tháp")
    end
    if targetW ~= "abyss" then
        table.insert(conflictingKeywords, "abyss")
        table.insert(conflictingKeywords, "vực sâu")
    end
    table.insert(conflictingKeywords, "pvp")
    table.insert(conflictingKeywords, "arena")
    table.insert(conflictingKeywords, "event")
    table.insert(conflictingKeywords, "raid")

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
    local targetKeywords = WORLD_KEYWORDS[targetW] or WORLD_KEYWORDS["1"]
    local targetLvlStr = tostring(State.targetLevel or "AUTO"):lower()

    -- BƯỚC 1: Chọn Thế Giới (World / Chapter Tab) chuẩn xác
    for _, gui in ipairs(pGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled and not isOurGui(gui) then
            for _, btn in ipairs(gui:GetDescendants()) do
                if (btn:IsA("TextButton") or btn:IsA("ImageButton")) and btn.Visible and not isOurGui(btn) then
                    local bText = (btn.Name .. " " .. (btn:IsA("TextButton") and btn.Text or "")):lower()
                    for _, kw in ipairs(targetKeywords) do
                        if bText:find(kw) then
                            pcall(function()
                                firesignal(btn.MouseButton1Click)
                                firesignal(btn.Activated)
                            end)
                            task.wait(0.25)
                            break
                        end
                    end
                end
            end
        end
    end

    task.wait(0.3)

    -- BƯỚC 2: Chọn Cấp Độ / Ải (Level / Stage)
    if targetLvlStr ~= "auto" then
        for _, gui in ipairs(pGui:GetChildren()) do
            if gui:IsA("ScreenGui") and gui.Enabled and not isOurGui(gui) then
                for _, btn in ipairs(gui:GetDescendants()) do
                    if (btn:IsA("TextButton") or btn:IsA("ImageButton")) and btn.Visible and not isOurGui(btn) then
                        local bText = (btn.Name .. " " .. (btn:IsA("TextButton") and btn.Text or "")):lower()
                        if bText:find("level " .. targetLvlStr) or bText:find("lv " .. targetLvlStr) or bText:find("cấp " .. targetLvlStr) or bText:find("stage " .. targetLvlStr) or bText:find("ải " .. targetLvlStr) or btn.Name:lower() == targetLvlStr then
                            pcall(function()
                                firesignal(btn.MouseButton1Click)
                                firesignal(btn.Activated)
                            end)
                            task.wait(0.25)
                            break
                        end
                    end
                end
            end
        end
    end

    task.wait(0.3)

    -- BƯỚC 3: Bấm nút Bắt đầu / Solo / Start / Create / Play
    local started = false
    for _, gui in ipairs(pGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled and not isOurGui(gui) then
            for _, btn in ipairs(gui:GetDescendants()) do
                if (btn:IsA("TextButton") or btn:IsA("ImageButton")) and btn.Visible and not isOurGui(btn) then
                    local bText = (btn.Name .. " " .. (btn:IsA("TextButton") and btn.Text or "")):lower()
                    if not bText:find("close") and not bText:find("cancel") and not bText:find("hủy") and not bText:find("đóng") and not bText:find("back") and not bText:find("shop") then
                        if bText:find("solo") or bText:find("start") or bText:find("create") or bText:find("play") or bText:find("bắt đầu") or bText:find("chơi") or bText:find("tạo phòng") or bText:find("enter") or bText:find("ready") then
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
            end
            if started then break end
        end
    end

    return started
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
        glideTo(part.Position, 3.0, 6.0)

        if HRP then
            HRP.CFrame = CFrame.new(part.Position.X, HRP.Position.Y, part.Position.Z)
        end

        if prompt then
            pcall(function() fireproximityprompt(prompt) end)
        end

        if firetouchinterest and part then
            pcall(function()
                firetouchinterest(HRP, part, 0)
                task.wait(0.05)
                firetouchinterest(HRP, part, 1)
            end)
        end

        task.wait(0.6)
    else
        -- Dự phòng: Nếu không thấy cổng thì thử Teleport trực tiếp qua PlaceId
        if targetInfo and targetInfo.id then
            State.statusText = "🚀 Đang dịch chuyển trực tiếp sang " .. targetInfo.name .. "..."
            pcall(function()
                game:GetService("TeleportService"):Teleport(targetInfo.id, LP)
            end)
        end
    end

    handleLobbyMenu()

    task.wait(3.0)
    isLobbyBusy = false
end

-- ================================================
-- LUỒNG ĐIỀU PHỐI CHÍNH (MASTER AUTO FARM LOOP)
-- ================================================
task.spawn(function()
    while true do
        task.wait(0.12)
        if not HRP or not Hum or Hum.Health <= 0 then continue end

        -- PHÂN BIỆT RÕ RÀNG: Ở SẢNH CHỜ HAY TRONG ẢI HẦM NGỤC
        if isLobbyPlace then
            -- 1. TRƯỜNG HỢP: ĐANG Ở SẢNH CHỜ (LOBBY PLACE)
            if State.autoafk then
                runLobbyEnter()
            end
        else
            -- 2. TRƯỜNG HỢP: ĐANG TRONG ẢI (THẾ GIỚI 1, 2, 3...)
            if State.autoafk or State.autofarm then
                local enemies = getAllRoomEnemies()

                if #enemies > 0 then
                    -- CÒN QUÁI TRONG PHÒNG -> LƯỚT ÁP SÁT SAU LƯNG CHÉM DIỆT QUÁI
                    local target = enemies[1]

                    if target and target.root then
                        local mobRoot = target.root
                        local mobCF   = mobRoot.CFrame
                        local mobPos  = mobRoot.Position
                        local myPos   = HRP.Position

                        local hpText = (target.hum and target.hum.Health) and ("HP: " .. math.floor(target.hum.Health)) or "Sống"
                        State.statusText = "⚔️ Diệt: " .. target.model.Name .. " (" .. hpText .. " • Còn " .. #enemies .. " quái)"

                        local behindPos = mobPos - (mobCF.LookVector * 2.5)
                        behindPos = Vector3.new(behindPos.X, mobPos.Y, behindPos.Z)

                        local dist = (myPos - behindPos).Magnitude
                        if dist > 4.5 then
                            glideTo(behindPos, 3.5, 2.5)
                        else
                            HRP.AssemblyLinearVelocity = Vector3.zero
                            HRP.CFrame = CFrame.lookAt(behindPos, Vector3.new(mobPos.X, behindPos.Y, mobPos.Z))
                        end

                        attackTarget(target.model, mobRoot)
                    end
                else
                    -- PHÒNG SẠCH QUÁI: Nhặt rương -> Sang cửa phòng kế -> Replay
                    State.statusText = "✅ Phòng sạch quái! Đang kiểm tra rương và cửa phòng kế..."
                    if State.autochest then lootChest() end
                    if State.autodoor  then advanceNextRoom() end
                    if State.autoreplay then clickReplayButton() end
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

createActionButton("🚀 Vào Thẳng Thế Giới 1", "Dịch chuyển trực tiếp vào ải Thế Giới 1 (Bỏ qua đi cổng)", "VÀO THẲNG", function()
    local targetInfo = WORLD_PLACES[State.targetWorld or "1"] or WORLD_PLACES["1"]
    if targetInfo and targetInfo.id then
        State.statusText = "🚀 Đang dịch chuyển trực tiếp sang " .. targetInfo.name .. "..."
        pcall(function()
            game:GetService("TeleportService"):Teleport(targetInfo.id, LP)
        end)
    else
        runLobbyEnter()
    end
end, 6)

createActionButton("Dịch Chuyển Vào Cổng Sảnh", "Lướt tới cổng chuẩn xác và mở bảng hầm ngục", "VÀO CỔNG", function()
    runLobbyEnter()
end, 7)

createActionButton("Lướt Qua Cửa Phòng Kế", "Lướt thẳng qua cửa phòng tiếp theo tức thì", "QUA CỬA", function()
    advanceNextRoom()
end, 8)

-- CÀY CẤP & CHIẾN ĐẤU CHI TIẾT
createCategory("⚔️ TÙY CHỌN CHIẾN ĐẤU & QUA ẢI", 10)

createToggle("Auto Chém Quái (Noclip Glide)", "Lướt xuyên vật cản đến sát lưng quái chém trúng 100%", State.autofarm, function(val)
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
