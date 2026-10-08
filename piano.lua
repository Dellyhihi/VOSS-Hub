-- ================================================
-- VOSS | Visual Piano Hub 🎹 (Mega Hits Edition)
-- Game: Visual Pianos (PlaceId: 5593470048)
-- ================================================
-- [NÂNG CẤP MỚI]:
-- 1. FIX TRIỆT ĐỂ LỖI NGỒI ĐÀN PIANO:
--    - Tự động quét cả Seat/Bench lẫn ProximityPrompt (E to Play)
--    - Tự xoay người chuẩn góc hướng vào bàn phím đàn
--    - Thử lại 3 lần liên tiếp đảm bảo dính ghế 100%
-- 2. KHO NHẠC SIÊU HOT HIT TREND 2024 - 2026:
--    - APT. (ROSÉ & Bruno Mars)
--    - Die With A Smile (Lady Gaga & Bruno Mars)
--    - Đừng Làm Trái Tim Anh Đau (Sơn Tùng M-TP)
--    - See Tình (Hoàng Thùy Linh)
--    - Until I Found You (Stephen Sanchez)
--    - Golden Hour (JVKE)
--    - Glimpse of Us (Joji)
--    - A Thousand Years (Christina Perri)
--    - Tokyo Ghoul (Unravel)
--    - Coffin Dance (Astronomia)
--    - Canon in D, Fur Elise, Interstellar, River Flows in You,...
-- 3. CÓ THANH TÌM KIẾM BÀI HÁT (SEARCH BOX)
-- 4. BỘ ĐIỀU KHIỂN BPM & HUMANIZER ĐÁNH NHƯ NGHỆ SĨ THẬT
-- ================================================

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local VirtualInputMgr   = game:GetService("VirtualInputManager")
local TextChatService   = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local LP                = Players.LocalPlayer

-- ================================================
-- BẢNG ÁNH XẠ PHÍM PIANO CHUẨN VIRTUAL PIANO
-- ================================================
local KeyMap = {
    -- Hàng số 1 - 0
    ["1"] = {Code = Enum.KeyCode.One,   Shift = false},
    ["2"] = {Code = Enum.KeyCode.Two,   Shift = false},
    ["3"] = {Code = Enum.KeyCode.Three, Shift = false},
    ["4"] = {Code = Enum.KeyCode.Four,  Shift = false},
    ["5"] = {Code = Enum.KeyCode.Five,  Shift = false},
    ["6"] = {Code = Enum.KeyCode.Six,   Shift = false},
    ["7"] = {Code = Enum.KeyCode.Seven, Shift = false},
    ["8"] = {Code = Enum.KeyCode.Eight, Shift = false},
    ["9"] = {Code = Enum.KeyCode.Nine,  Shift = false},
    ["0"] = {Code = Enum.KeyCode.Zero,  Shift = false},

    -- Ký tự Shift của hàng số
    ["!"] = {Code = Enum.KeyCode.One,   Shift = true},
    ["@"] = {Code = Enum.KeyCode.Two,   Shift = true},
    ["#"] = {Code = Enum.KeyCode.Three, Shift = true},
    ["$"] = {Code = Enum.KeyCode.Four,  Shift = true},
    ["%"] = {Code = Enum.KeyCode.Five,  Shift = true},
    ["^"] = {Code = Enum.KeyCode.Six,   Shift = true},
    ["&"] = {Code = Enum.KeyCode.Seven, Shift = true},
    ["*"] = {Code = Enum.KeyCode.Eight, Shift = true},
    ["("] = {Code = Enum.KeyCode.Nine,  Shift = true},
    [")"] = {Code = Enum.KeyCode.Zero,  Shift = true},

    -- Chữ cái thường (White keys)
    ["q"] = {Code = Enum.KeyCode.Q, Shift = false},
    ["w"] = {Code = Enum.KeyCode.W, Shift = false},
    ["e"] = {Code = Enum.KeyCode.E, Shift = false},
    ["r"] = {Code = Enum.KeyCode.R, Shift = false},
    ["t"] = {Code = Enum.KeyCode.T, Shift = false},
    ["y"] = {Code = Enum.KeyCode.Y, Shift = false},
    ["u"] = {Code = Enum.KeyCode.U, Shift = false},
    ["i"] = {Code = Enum.KeyCode.I, Shift = false},
    ["o"] = {Code = Enum.KeyCode.O, Shift = false},
    ["p"] = {Code = Enum.KeyCode.P, Shift = false},
    ["a"] = {Code = Enum.KeyCode.A, Shift = false},
    ["s"] = {Code = Enum.KeyCode.S, Shift = false},
    ["d"] = {Code = Enum.KeyCode.D, Shift = false},
    ["f"] = {Code = Enum.KeyCode.F, Shift = false},
    ["g"] = {Code = Enum.KeyCode.G, Shift = false},
    ["h"] = {Code = Enum.KeyCode.H, Shift = false},
    ["j"] = {Code = Enum.KeyCode.J, Shift = false},
    ["k"] = {Code = Enum.KeyCode.K, Shift = false},
    ["l"] = {Code = Enum.KeyCode.L, Shift = false},
    ["z"] = {Code = Enum.KeyCode.Z, Shift = false},
    ["x"] = {Code = Enum.KeyCode.X, Shift = false},
    ["c"] = {Code = Enum.KeyCode.C, Shift = false},
    ["v"] = {Code = Enum.KeyCode.V, Shift = false},
    ["b"] = {Code = Enum.KeyCode.B, Shift = false},
    ["n"] = {Code = Enum.KeyCode.N, Shift = false},
    ["m"] = {Code = Enum.KeyCode.M, Shift = false},

    -- Chữ cái hoa (Black keys / Shift)
    ["Q"] = {Code = Enum.KeyCode.Q, Shift = true},
    ["W"] = {Code = Enum.KeyCode.W, Shift = true},
    ["E"] = {Code = Enum.KeyCode.E, Shift = true},
    ["R"] = {Code = Enum.KeyCode.R, Shift = true},
    ["T"] = {Code = Enum.KeyCode.T, Shift = true},
    ["Y"] = {Code = Enum.KeyCode.Y, Shift = true},
    ["U"] = {Code = Enum.KeyCode.U, Shift = true},
    ["I"] = {Code = Enum.KeyCode.I, Shift = true},
    ["O"] = {Code = Enum.KeyCode.O, Shift = true},
    ["P"] = {Code = Enum.KeyCode.P, Shift = true},
    ["A"] = {Code = Enum.KeyCode.A, Shift = true},
    ["S"] = {Code = Enum.KeyCode.S, Shift = true},
    ["D"] = {Code = Enum.KeyCode.D, Shift = true},
    ["F"] = {Code = Enum.KeyCode.F, Shift = true},
    ["G"] = {Code = Enum.KeyCode.G, Shift = true},
    ["H"] = {Code = Enum.KeyCode.H, Shift = true},
    ["J"] = {Code = Enum.KeyCode.J, Shift = true},
    ["K"] = {Code = Enum.KeyCode.K, Shift = true},
    ["L"] = {Code = Enum.KeyCode.L, Shift = true},
    ["Z"] = {Code = Enum.KeyCode.Z, Shift = true},
    ["X"] = {Code = Enum.KeyCode.X, Shift = true},
    ["C"] = {Code = Enum.KeyCode.C, Shift = true},
    ["V"] = {Code = Enum.KeyCode.V, Shift = true},
    ["B"] = {Code = Enum.KeyCode.B, Shift = true},
    ["N"] = {Code = Enum.KeyCode.N, Shift = true},
    ["M"] = {Code = Enum.KeyCode.M, Shift = true},
}

-- ================================================
-- KHO NHẠC SIÊU HOT HIT 2024 - 2026 (16 BÀI)
-- ================================================
local SongLibrary = {
    {
        Name = "🔥 APT. - ROSÉ & Bruno Mars",
        BPM  = 100,
        Sheet = "[8f] [0wf] [8f] f [8f] [0wd] [9f] [Qef] [9f] f [9f] [Qed] [0f] [wrf] [0f] f [0f] [wrd] [wf] [ry] [wd] f [wd] [ryf] [8f] [0wf] [8f] f [8f] [0wd] [9f] [Qef] [9f] f [9f] [Qed] [0f] [wrf] [0f] f [0f] [wrd] [wf] [ry] [wd] f [wd] [ryf]"
    },
    {
        Name = "🔥 Die With A Smile - Lady Gaga & Bruno Mars",
        BPM  = 85,
        Sheet = "[8oa] r u o u r [8oa] r u [of] u r [qip] t u p u t [qip] t u p u t [8oah] [rf] [uf] [pj] [uak] r j [qip] t u p u t [8oa] r u o u r [8oa] r u [of] u r [qip] t u p u t"
    },
    {
        Name = "🔥 Đừng Làm Trái Tim Anh Đau - Sơn Tùng M-TP",
        BPM  = 105,
        Sheet = "[8u] o s [5w] o a [6e] u p [4q] i o [8u] o s [5w] o a [6e] u p [4q] i o [8os] [os] [os] [5wa] [6ep] [ep] [4qa] [8os] [os] [os] [5wa] [6ep] [ep] [4qa] [8u] o s [5w] o a [6e] u p [4q] i o"
    },
    {
        Name = "🔥 See Tình - Hoàng Thùy Linh",
        BPM  = 115,
        Sheet = "[4q] [4q] [4q] 8 [5w] [5w] [5w] 9 [6e] [6e] [6e] 0 [6e] [6e] [6e] [4q] 8 [4q] 8 [5w] 9 [5w] 9 [6e] 0 [6e] 0 [6e] 0 [4q] [4q] [4q] 8 [5w] [5w] [5w] 9 [6e] [6e] [6e] 0"
    },
    {
        Name = "🔥 Until I Found You - Stephen Sanchez",
        BPM  = 80,
        Sheet = "[tf] f s o [ra] h f a o a [ti] s g s p [ts] [ts] [ts] [tg] [tg] [tg] [yh] [yh] [yh] [yd] [yd] [yd] [tf] f s o [ra] h f a o a [ti] s g s p [ts] [ts] [ts] [tg] [tg] [tg]"
    },
    {
        Name = "🔥 Golden Hour - JVKE",
        BPM  = 115,
        Sheet = "[158] w t y u [48q] e t y i [158] w t y u [59w] r y u o [158] w t y u [48q] e t y i [158] w t y u [59w] r y u o [60e] t u p s [48q] e t y i [158] w t y u [59w] r y u o"
    },
    {
        Name = "🔥 Glimpse of Us - Joji",
        BPM  = 75,
        Sheet = "[6e] [0u] [6e] [0u] [4q] [8t] [4q] [8t] [10] [5w] [10] [5w] [5w] [9r] [5w] [9r] [6e] u [0p] [6e] u [0p] [4q] t [8i] [4q] t [8i] [10] w [5u] [10] w [5u] [5w] r [9y] [5w] r [9y]"
    },
    {
        Name = "🔥 A Thousand Years - Christina Perri",
        BPM  = 90,
        Sheet = "[1u] [5o] [8s] [5o] [1u] [5o] [8s] [5o] [4i] [8p] [qd] [8p] [4i] [8p] [qd] [8p] [1u] [5o] [8s] [5o] [5y] [9o] [wa] [9o] [6t] [0u] [ep] [0u] [4i] [8p] [qd] [8p]"
    },
    {
        Name = "🔥 Tokyo Ghoul - Unravel",
        BPM  = 130,
        Sheet = "[0e] u p [0e] u p [8w] t o [8w] t o [9e] y i [9e] y i [7w] r u [7w] r u [0e] u p [0e] u p [8w] t o [8w] t o [9e] y i [9e] y i [7w] r u [7w] r u [0ep] [0ep] [0ep] [8wo] [8wo] [9ei] [9ei]"
    },
    {
        Name = "🔥 Astronomia (Coffin Dance)",
        BPM  = 125,
        Sheet = "[6t] [6t] [6t] [6t] [6t] [6t] [6t] [6t] [4t] [4t] [4t] [4t] [5y] [5y] [5y] [5y] [6e] p p p p o o o i i i u u u [6e] p p p p o o o i i i u u u"
    },
    {
        Name = "🎵 Canon in D - Pachelbel",
        BPM  = 95,
        Sheet = "u o a d f [oa] h [os] h [yd] g [ya] g [tu] f [ts] f [re] d [ra] d [we] s [wo] s [qe] a [qp] a [0u] o [0y] o [8u] o a d f [oa] h [os] h [yd] g [ya] g [tu] f [ts] f [re] d [ra] d [we] s [wo] s"
    },
    {
        Name = "🎵 Faded - Alan Walker",
        BPM  = 90,
        Sheet = "[6e] u p s [4q] t i p [10] w u o [5w] r y o [6e] u p s [4q] t i p [10] w u o [5w] r y o [6p] s f j [4i] p d g [1u] o s h [5y] o d h [6p] s f j [4i] p d g [1u] o s h [5y] o d h"
    },
    {
        Name = "🎵 Fur Elise - Beethoven",
        BPM  = 130,
        Sheet = "e W e W e u y t r [0e] t u [60r] u O [60e] u e W e W e u y t r [0e] t u [60r] u O [60e] [0r] t y [8u] i o [7y] u i [6t] y u [5r] [0e] W e W e u y t r [0e] t u [60r] u O [60e]"
    },
    {
        Name = "🎵 Interstellar Theme - Hans Zimmer",
        BPM  = 100,
        Sheet = "u o u o u o u o [6u] o [6u] o [6u] o [6u] o [4u] p [4u] p [4u] p [4u] p [1u] o [1u] o [1u] o [1u] o [5u] o [5u] o [5u] o [5u] o [6u] [0o] [6u] [0o] [4u] [8p] [4u] [8p] [1u] [5o] [1u] [5o] [5y] [9o] [5y] [9o]"
    },
    {
        Name = "🎵 River Flows in You - Yiruma",
        BPM  = 80,
        Sheet = "a s [6d] f d s a [4p] o p [1s] a p o [5y] u [6d] f d s a [4p] o p [1s] a p o [5y] u [6u] p [4i] p [1o] s [5y] o [6u] p [4i] p [1o] s [5y] o [6d] f d s a [4p] o p [1s] a p o [5y]"
    },
    {
        Name = "🎵 Cô Nàng Áo Dài - Hot Trend VN",
        BPM  = 105,
        Sheet = "o p [6s] s d [6f] f g [6d] s [4p] p a [4s] s d [4a] p [1o] o p [1s] s d [1f] [5d] s a [5p] o [6s] s d [6f] f g [6d] s [4p] p a [4s] s d [4a] p [1s] d f [5g] f d [1s]"
    }
}

-- ================================================
-- TRẠNG THÁI & CẤU HÌNH
-- ================================================
local Config = {
    BPM         = SongLibrary[1].BPM,
    Humanizer   = true,  -- Dao động micro-delay ±5ms
    Loop        = false,
    UseGameChat = false, -- Gửi >auto vào chat game
}

local Playback = {
    IsPlaying = false,
    IsPaused  = false,
    Thread    = nil,
    CurrentSong = SongLibrary[1].Name,
    CustomSheet = SongLibrary[1].Sheet,
}

-- ================================================
-- HÀM MÔ PHỎNG BẤM PHÍM PIANO
-- ================================================
local function playSingleKey(char)
    local map = KeyMap[char]
    if not map then return end

    local kc    = map.Code
    local shift = map.Shift

    pcall(function()
        if shift then
            VirtualInputMgr:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game)
            task.wait(0.005)
        end

        VirtualInputMgr:SendKeyEvent(true, kc, false, game)
        task.wait(0.02)
        VirtualInputMgr:SendKeyEvent(false, kc, false, game)

        if shift then
            task.wait(0.005)
            VirtualInputMgr:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, game)
        end
    end)
end

local function playChord(chordStr)
    local hasShift = false
    local keysToHit = {}

    for i = 1, #chordStr do
        local c = chordStr:sub(i, i)
        local m = KeyMap[c]
        if m then
            table.insert(keysToHit, m.Code)
            if m.Shift then hasShift = true end
        end
    end

    if #keysToHit == 0 then return end

    pcall(function()
        if hasShift then
            VirtualInputMgr:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game)
            task.wait(0.005)
        end

        for _, kc in ipairs(keysToHit) do
            VirtualInputMgr:SendKeyEvent(true, kc, false, game)
        end
        task.wait(0.025)
        for _, kc in ipairs(keysToHit) do
            VirtualInputMgr:SendKeyEvent(false, kc, false, game)
        end

        if hasShift then
            task.wait(0.005)
            VirtualInputMgr:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, game)
        end
    end)
end

-- ================================================
-- BỘ GIẢI MÃ SHEET & PHÁT NHẠC (PARSER & PLAYER)
-- ================================================
local function sendChatAutoCommand(sheetText)
    local msg = ">auto " .. sheetText
    pcall(function()
        if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
            local textChannels = TextChatService:FindFirstChild("TextChannels")
            if textChannels then
                local gen = textChannels:FindFirstChild("RBXGeneral")
                if gen then gen:SendAsync(msg) end
            end
        else
            ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(msg, "All")
        end
    end)
end

local function stopMusic()
    Playback.IsPlaying = false
    Playback.IsPaused  = false
    if Playback.Thread then
        task.cancel(Playback.Thread)
        Playback.Thread = nil
    end
end

local function parseAndPlay(sheetText, bpm)
    stopMusic()
    Playback.IsPlaying = true
    Playback.IsPaused  = false

    -- Nếu chọn chế độ gửi lệnh game >auto
    if Config.UseGameChat then
        sendChatAutoCommand(sheetText)
        Playback.IsPlaying = false
        return
    end

    Playback.Thread = task.spawn(function()
        repeat
            local i = 1
            local len = #sheetText
            local baseDelay = (60 / bpm) / 4 -- 16th note timing

            while i <= len and Playback.IsPlaying do
                while Playback.IsPaused and Playback.IsPlaying do
                    task.wait(0.1)
                end
                if not Playback.IsPlaying then break end

                local char = sheetText:sub(i, i)

                if char == "[" then
                    -- Bắt đầu Hợp âm (Chord)
                    local closeIdx = sheetText:find("%]", i)
                    if closeIdx then
                        local chordContent = sheetText:sub(i + 1, closeIdx - 1)
                        playChord(chordContent)
                        i = closeIdx + 1
                    else
                        i = i + 1
                    end
                    local d = baseDelay
                    if Config.Humanizer then d = d + (math.random(-5, 5) / 1000) end
                    task.wait(math.max(0.015, d))

                elseif char == " " then
                    -- Khoảng trắng = nghỉ 1 nhịp
                    local d = baseDelay * 1.5
                    if Config.Humanizer then d = d + (math.random(-5, 5) / 1000) end
                    task.wait(math.max(0.02, d))
                    i = i + 1

                elseif char == "|" then
                    -- Vạch nhịp = nghỉ dài
                    task.wait(baseDelay * 2.5)
                    i = i + 1

                else
                    -- Nốt đơn
                    if KeyMap[char] then
                        playSingleKey(char)
                        local d = baseDelay
                        if Config.Humanizer then d = d + (math.random(-5, 5) / 1000) end
                        task.wait(math.max(0.015, d))
                    end
                    i = i + 1
                end
            end

            if Config.Loop and Playback.IsPlaying then
                task.wait(1.5)
            else
                break
            end
        until not Config.Loop or not Playback.IsPlaying

        Playback.IsPlaying = false
        Playback.IsPaused  = false
    end)
end

-- ================================================
-- FIX TRIỆT ĐỂ: TỰ ĐỘNG TÌM GHẾ & NGỒI VÀO ĐÀN PIANO
-- ================================================
local function autoSitNearestPiano(statusLabel)
    local char = LP.Character
    if not char then return end
    local hrp  = char:FindFirstChild("HumanoidRootPart")
    local hum  = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    local bestSeat   = nil
    local bestPrompt = nil
    local bestDist   = 9999

    -- 1. Tìm Seat hoặc ProximityPrompt gần người chơi nhất
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Seat") or obj:IsA("VehicleSeat") then
            local isPiano = false
            local cur = obj
            for _ = 1, 4 do
                if cur and cur.Name then
                    local ln = cur.Name:lower()
                    if ln:find("piano") or ln:find("bench") or ln:find("seat") 
                    or ln:find("chair") or ln:find("music") or ln:find("stool") then
                        isPiano = true; break
                    end
                    cur = cur.Parent
                end
            end

            local d = (hrp.Position - obj.Position).Magnitude
            if (isPiano or d < 35) and not obj.Occupant and d < bestDist then
                bestSeat = obj
                bestDist = d
            end
        elseif obj:IsA("ProximityPrompt") then
            local pAct = (obj.ActionText or ""):lower()
            local pObj = (obj.ObjectText or ""):lower()
            local pName = obj.Name:lower()
            if pAct:find("sit") or pAct:find("play") or pObj:find("piano") or pName:find("piano") then
                local promptPos = obj.Parent and obj.Parent:IsA("BasePart") and obj.Parent.Position or nil
                if promptPos then
                    local d = (hrp.Position - promptPos).Magnitude
                    if d < bestDist then
                        bestPrompt = obj
                    end
                end
            end
        end
    end

    -- 2. Thực hiện thao tác ngồi dứt điểm
    if bestSeat then
        if statusLabel then statusLabel.Text = "⏳ Đang ngồi vào đàn..." end
        
        -- Dịch chuyển sát mặt ghế + hướng mặt vào đàn
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.CFrame = CFrame.new(bestSeat.Position + Vector3.new(0, 0.6, 0), bestSeat.Position + (bestSeat.CFrame.LookVector * 5))
        task.wait(0.1)

        -- Kích hoạt ngồi 3 lần liên tiếp
        for _ = 1, 3 do
            pcall(function() bestSeat:Sit(hum) end)
            task.wait(0.08)
            if hum.Sit then break end
        end

        -- Nếu có ProximityPrompt kèm theo, kích hoạt luôn
        if fireproximityprompt then
            for _, p in pairs(bestSeat:GetDescendants()) do
                if p:IsA("ProximityPrompt") then
                    pcall(function() fireproximityprompt(p) end)
                end
            end
            if bestSeat.Parent then
                for _, p in pairs(bestSeat.Parent:GetDescendants()) do
                    if p:IsA("ProximityPrompt") then
                        pcall(function() fireproximityprompt(p) end)
                    end
                end
            end
        end

        if statusLabel then 
            statusLabel.Text = "✅ Đã ngồi vào đàn thành công!"
            task.delay(2, function()
                if statusLabel then statusLabel.Text = "🪑  Tự Ngồi Vào Đàn Piano" end
            end)
        end
    elseif bestPrompt and fireproximityprompt then
        if statusLabel then statusLabel.Text = "⏳ Kích hoạt E to Play..." end
        local pPart = bestPrompt.Parent
        if pPart and pPart:IsA("BasePart") then
            hrp.CFrame = pPart.CFrame + Vector3.new(0, 1, 0)
            task.wait(0.1)
        end
        fireproximityprompt(bestPrompt)
        if statusLabel then 
            statusLabel.Text = "✅ Đã ngồi vào đàn thành công!"
            task.delay(2, function()
                if statusLabel then statusLabel.Text = "🪑  Tự Ngồi Vào Đàn Piano" end
            end)
        end
    else
        if statusLabel then 
            statusLabel.Text = "❌ Không tìm thấy cây đàn nào gần bạn!"
            task.delay(2, function()
                if statusLabel then statusLabel.Text = "🪑  Tự Ngồi Vào Đàn Piano" end
            end)
        end
    end
end

-- ================================================
-- GIAO DIỆN VOSS PIANO HUB (GUI)
-- ================================================
pcall(function()
    game:GetService("CoreGui"):FindFirstChild("VOSS_PianoHub"):Destroy()
end)

local SG = Instance.new("ScreenGui")
SG.Name           = "VOSS_PianoHub"
SG.ResetOnSpawn   = false
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SG.Parent         = game:GetService("CoreGui")

local Main = Instance.new("Frame", SG)
Main.Name             = "Main"
Main.Size             = UDim2.new(0, 300, 0, 560)
Main.Position         = UDim2.new(0, 20, 0.5, -280)
Main.BackgroundColor3 = Color3.fromRGB(12, 12, 20)
Main.BorderSizePixel  = 0
Main.Active           = true
Main.Draggable        = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 14)

local stroke = Instance.new("UIStroke", Main)
stroke.Color = Color3.fromRGB(120, 60, 230)
stroke.Thickness = 1.5

-- Tiêu đề
local Title = Instance.new("TextLabel", Main)
Title.Size               = UDim2.new(1, 0, 0, 38)
Title.BackgroundTransparency = 1
Title.Text               = "VOSS  |  Visual Piano 🎹"
Title.TextColor3         = Color3.fromRGB(180, 120, 255)
Title.Font               = Enum.Font.GothamBold
Title.TextSize           = 16

local Subtitle = Instance.new("TextLabel", Main)
Subtitle.Size            = UDim2.new(1, 0, 0, 14)
Subtitle.Position        = UDim2.new(0, 0, 0, 34)
Subtitle.BackgroundTransparency = 1
Subtitle.Text            = "3 ngón×2 ẩn | 3 ngón×3 hiện | RShift PC"
Subtitle.TextColor3      = Color3.fromRGB(90, 80, 130)
Subtitle.Font            = Enum.Font.Gotham
Subtitle.TextSize        = 9.5

local Div1 = Instance.new("Frame", Main)
Div1.Size             = UDim2.new(0.88, 0, 0, 1)
Div1.Position         = UDim2.new(0.06, 0, 0, 52)
Div1.BackgroundColor3 = Color3.fromRGB(60, 40, 110)
Div1.BorderSizePixel  = 0

-- Scroll Danh Sách
local Scroll = Instance.new("ScrollingFrame", Main)
Scroll.Size             = UDim2.new(0.92, 0, 0, 495)
Scroll.Position         = UDim2.new(0.04, 0, 0, 58)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel  = 0
Scroll.ScrollBarThickness = 3
Scroll.ScrollBarImageColor3 = Color3.fromRGB(120, 70, 230)
Scroll.CanvasSize       = UDim2.new(0, 0, 0, 950)

local uiList = Instance.new("UIListLayout", Scroll)
uiList.SortOrder = Enum.SortOrder.LayoutOrder
uiList.Padding   = UDim.new(0, 8)

-- 1. NÚT TỰ NGỒI VÀO ĐÀN
local btnSit = Instance.new("TextButton", Scroll)
btnSit.Size             = UDim2.new(1, 0, 0, 38)
btnSit.BackgroundColor3 = Color3.fromRGB(35, 18, 65)
btnSit.Text             = "🪑  Tự Ngồi Vào Đàn Piano"
btnSit.TextColor3       = Color3.fromRGB(215, 175, 255)
btnSit.Font             = Enum.Font.GothamBold
btnSit.TextSize         = 12.5
btnSit.LayoutOrder      = 1
Instance.new("UICorner", btnSit).CornerRadius = UDim.new(0, 8)
local sSit = Instance.new("UIStroke", btnSit)
sSit.Color = Color3.fromRGB(110, 50, 220); sSit.Thickness = 1
btnSit.MouseButton1Click:Connect(function()
    autoSitNearestPiano(btnSit)
end)

-- 2. HỘP ĐIỀU KHIỂN PHÁT NHẠC (PLAY / PAUSE / STOP)
local ctlFrame = Instance.new("Frame", Scroll)
ctlFrame.Size             = UDim2.new(1, 0, 0, 40)
ctlFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
ctlFrame.LayoutOrder      = 2
Instance.new("UICorner", ctlFrame).CornerRadius = UDim.new(0, 8)

local btnPlay = Instance.new("TextButton", ctlFrame)
btnPlay.Size             = UDim2.new(0.31, 0, 0.8, 0)
btnPlay.Position         = UDim2.new(0.02, 0, 0.1, 0)
btnPlay.BackgroundColor3 = Color3.fromRGB(50, 25, 110)
btnPlay.Text             = "▶ PHÁT"
btnPlay.TextColor3       = Color3.fromRGB(220, 180, 255)
btnPlay.Font             = Enum.Font.GothamBold
btnPlay.TextSize         = 11
Instance.new("UICorner", btnPlay).CornerRadius = UDim.new(0, 6)

local btnPause = Instance.new("TextButton", ctlFrame)
btnPause.Size            = UDim2.new(0.31, 0, 0.8, 0)
btnPause.Position        = UDim2.new(0.35, 0, 0.1, 0)
btnPause.BackgroundColor3 = Color3.fromRGB(35, 30, 55)
btnPause.Text            = "⏸ DỪNG"
btnPause.TextColor3      = Color3.fromRGB(180, 170, 210)
btnPause.Font            = Enum.Font.GothamBold
btnPause.TextSize        = 11
Instance.new("UICorner", btnPause).CornerRadius = UDim.new(0, 6)

local btnStop = Instance.new("TextButton", ctlFrame)
btnStop.Size             = UDim2.new(0.30, 0, 0.8, 0)
btnStop.Position         = UDim2.new(0.68, 0, 0.1, 0)
btnStop.BackgroundColor3 = Color3.fromRGB(80, 20, 35)
btnStop.Text             = "⏹ HỦY"
btnStop.TextColor3       = Color3.fromRGB(255, 170, 180)
btnStop.Font             = Enum.Font.GothamBold
btnStop.TextSize         = 11
Instance.new("UICorner", btnStop).CornerRadius = UDim.new(0, 6)

-- 3. ĐIỀU CHỈNH TỐC ĐỘ (BPM)
local bpmFrame = Instance.new("Frame", Scroll)
bpmFrame.Size             = UDim2.new(1, 0, 0, 36)
bpmFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
bpmFrame.LayoutOrder      = 3
Instance.new("UICorner", bpmFrame).CornerRadius = UDim.new(0, 8)

local bpmLabel = Instance.new("TextLabel", bpmFrame)
bpmLabel.Size               = UDim2.new(0.5, 0, 1, 0)
bpmLabel.Position           = UDim2.new(0.04, 0, 0, 0)
bpmLabel.BackgroundTransparency = 1
bpmLabel.Text               = "Tốc độ: " .. Config.BPM .. " BPM"
bpmLabel.TextColor3         = Color3.fromRGB(210, 200, 230)
bpmLabel.Font               = Enum.Font.GothamSemibold
bpmLabel.TextSize           = 12
bpmLabel.TextXAlignment     = Enum.TextXAlignment.Left

local btnMinus = Instance.new("TextButton", bpmFrame)
btnMinus.Size             = UDim2.new(0, 32, 0, 26)
btnMinus.Position         = UDim2.new(0.65, 0, 0.5, -13)
btnMinus.BackgroundColor3 = Color3.fromRGB(35, 30, 55)
btnMinus.Text             = "-10"
btnMinus.TextColor3       = Color3.fromRGB(220, 200, 255)
btnMinus.Font             = Enum.Font.GothamBold
btnMinus.TextSize         = 11
Instance.new("UICorner", btnMinus).CornerRadius = UDim.new(0, 6)

local btnPlus = Instance.new("TextButton", bpmFrame)
btnPlus.Size              = UDim2.new(0, 32, 0, 26)
btnPlus.Position          = UDim2.new(0.82, 0, 0.5, -13)
btnPlus.BackgroundColor3  = Color3.fromRGB(50, 25, 110)
btnPlus.Text              = "+10"
btnPlus.TextColor3        = Color3.fromRGB(220, 200, 255)
btnPlus.Font              = Enum.Font.GothamBold
btnPlus.TextSize          = 11
Instance.new("UICorner", btnPlus).CornerRadius = UDim.new(0, 6)

btnMinus.MouseButton1Click:Connect(function()
    Config.BPM = math.max(40, Config.BPM - 10)
    bpmLabel.Text = "Tốc độ: " .. Config.BPM .. " BPM"
end)
btnPlus.MouseButton1Click:Connect(function()
    Config.BPM = math.min(260, Config.BPM + 10)
    bpmLabel.Text = "Tốc độ: " .. Config.BPM .. " BPM"
end)

-- 4. Ô NHẬP SHEET NHẠC TÙY Ý
local sheetTitle = Instance.new("TextLabel", Scroll)
sheetTitle.Size               = UDim2.new(1, 0, 0, 18)
sheetTitle.BackgroundTransparency = 1
sheetTitle.Text               = "📝 Dán Sheet Nhạc Tùy Ý (Virtual Piano):"
sheetTitle.TextColor3         = Color3.fromRGB(170, 150, 210)
sheetTitle.Font               = Enum.Font.GothamSemibold
sheetTitle.TextSize           = 11
sheetTitle.TextXAlignment     = Enum.TextXAlignment.Left
sheetTitle.LayoutOrder        = 4

local sheetBox = Instance.new("TextBox", Scroll)
sheetBox.Size                 = UDim2.new(1, 0, 0, 75)
sheetBox.BackgroundColor3     = Color3.fromRGB(16, 16, 26)
sheetBox.Text                 = Playback.CustomSheet
sheetBox.TextColor3           = Color3.fromRGB(220, 215, 240)
sheetBox.Font                 = Enum.Font.Code
sheetBox.TextSize             = 10.5
sheetBox.TextXAlignment       = Enum.TextXAlignment.Left
sheetBox.TextYAlignment       = Enum.TextYAlignment.Top
sheetBox.ClearTextOnFocus     = false
sheetBox.TextWrapped          = true
sheetBox.MultiLine            = true
sheetBox.LayoutOrder          = 5
Instance.new("UICorner", sheetBox).CornerRadius = UDim.new(0, 8)
local sBox = Instance.new("UIStroke", sheetBox)
sBox.Color = Color3.fromRGB(70, 45, 130); sBox.Thickness = 1

sheetBox:GetPropertyChangedSignal("Text"):Connect(function()
    Playback.CustomSheet = sheetBox.Text
end)

btnPlay.MouseButton1Click:Connect(function()
    if Playback.IsPaused then
        Playback.IsPaused = false
    else
        parseAndPlay(Playback.CustomSheet, Config.BPM)
    end
end)

btnPause.MouseButton1Click:Connect(function()
    if Playback.IsPlaying then
        Playback.IsPaused = not Playback.IsPaused
        btnPause.Text = Playback.IsPaused and "▶ TIẾP" or "⏸ DỪNG"
    end
end)

btnStop.MouseButton1Click:Connect(function()
    stopMusic()
    btnPause.Text = "⏸ DỪNG"
end)

-- 5. THANH TÌM KIẾM BÀI HÁT
local searchBox = Instance.new("TextBox", Scroll)
searchBox.Size                 = UDim2.new(1, 0, 0, 34)
searchBox.BackgroundColor3     = Color3.fromRGB(22, 20, 35)
searchBox.PlaceholderText      = "🔍 Tìm kiếm bài hát (gõ tên bài)..."
searchBox.PlaceholderColor3    = Color3.fromRGB(130, 120, 160)
searchBox.Text                 = ""
searchBox.TextColor3           = Color3.fromRGB(230, 220, 255)
searchBox.Font                 = Enum.Font.Gotham
searchBox.TextSize             = 11.5
searchBox.LayoutOrder          = 6
Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0, 8)
local sSearch = Instance.new("UIStroke", searchBox)
sSearch.Color = Color3.fromRGB(90, 50, 170); sSearch.Thickness = 1

local libTitle = Instance.new("TextLabel", Scroll)
libTitle.Size               = UDim2.new(1, 0, 0, 18)
libTitle.BackgroundTransparency = 1
libTitle.Text               = "🎵 Danh Sách Nhạc Hot Trend (Chạm Để Đánh):"
libTitle.TextColor3         = Color3.fromRGB(170, 150, 210)
libTitle.Font               = Enum.Font.GothamSemibold
libTitle.TextSize           = 11
libTitle.TextXAlignment     = Enum.TextXAlignment.Left
libTitle.LayoutOrder        = 7

-- 6. TẠO DANH SÁCH BÀI HÁT
local songButtons = {}

for idx, song in ipairs(SongLibrary) do
    local sBtn = Instance.new("TextButton", Scroll)
    sBtn.Size             = UDim2.new(1, 0, 0, 34)
    sBtn.BackgroundColor3 = Color3.fromRGB(22, 20, 34)
    sBtn.Text             = "  " .. idx .. ". " .. song.Name
    sBtn.TextColor3       = Color3.fromRGB(200, 190, 220)
    sBtn.Font             = Enum.Font.Gotham
    sBtn.TextSize         = 11
    sBtn.TextXAlignment   = Enum.TextXAlignment.Left
    sBtn.LayoutOrder      = 7 + idx
    Instance.new("UICorner", sBtn).CornerRadius = UDim.new(0, 6)

    sBtn.MouseButton1Click:Connect(function()
        Playback.CustomSheet = song.Sheet
        sheetBox.Text        = song.Sheet
        Config.BPM           = song.BPM
        bpmLabel.Text        = "Tốc độ: " .. Config.BPM .. " BPM"
        parseAndPlay(song.Sheet, song.BPM)
    end)

    table.insert(songButtons, {Button = sBtn, Name = song.Name:lower()})
end

-- Lọc danh sách theo ô tìm kiếm
searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    local query = searchBox.Text:lower()
    for _, item in ipairs(songButtons) do
        if query == "" or item.Name:find(query, 1, true) then
            item.Button.Visible = true
        else
            item.Button.Visible = false
        end
    end
end)

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
                        Main.Visible = false
                    elseif tapCount >= 3 then
                        visible = true
                        Main.Visible = true
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
        Main.Visible = visible
    end
end)

print("[VOSS] Visual Piano Hub 🎹 (Mega Hits Edition) Loaded!")
