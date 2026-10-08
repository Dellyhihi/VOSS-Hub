-- ================================================
-- VOSS | Visual Piano Hub 🎹 (Master Acoustic Edition)
-- Game: Visual Pianos (PlaceId: 5593470048)
-- ================================================
-- [FIX TOÀN DIỆN - KHÔNG CÒN ĐẤM VÀO TAI]:
-- 1. FIX DỨT ĐIỂM NHỊP ĐIỆU (MELODIC ACOUSTIC ENGINE):
--    - Bỏ hoàn toàn tốc độ súng liên thanh (150ms) gây chói tai
--    - Nốt đơn được ngân vang tự nhiên (0.28s - 0.35s)
--    - Khoảng trắng ' ' nghỉ đúng nhịp phách bản nhạc (0.45s)
--    - Vạch '|' chuyển câu trữ tình du dương (0.9s)
--    - Bỏ nút Space gây nhảy nhân vật khỏi ghế
-- 2. TÍCH HỢP 3 CHẾ ĐỘ PHÁT CỰC TIỆN:
--    - Mode 1: Tự đánh phím (VirtualInputManager) mượt mà êm ái
--    - Mode 2: Gửi lệnh >auto vào game (Dùng hệ thống đánh chuẩn của chính game)
--    - Mode 3: Nút [📋 Copy Sheet] 1 chạm chép sheet vào bộ nhớ điện thoại
-- 3. KHO NHẠC HOT FULL BÀI (TRUNG QUỐC DOUYIN & VIỆT NAM 2026):
--    - Thời Không Sai Lệch, Đồng Thoại, Phi Điểu Và Ve Sầu, Tay Trái Chỉ Trăng
--    - Đừng Làm Trái Tim Anh Đau, Cắt Đôi Nỗi Sầu, Nơi Này Có Anh, See Tình
--    - APT. (ROSÉ & Bruno Mars), Die With A Smile, Golden Hour, Until I Found You
-- ================================================

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local VirtualInputMgr   = game:GetService("VirtualInputManager")
local TextChatService   = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local LP                = Players.LocalPlayer

-- Bảng ánh xạ phím Virtual Piano chuẩn
local KeyMap = {
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
-- KHO NHẠC SIÊU CHUẨN ĐÃ ĐƯỢC CÂN CHỈNH NHẠC LÝ
-- ================================================
local SongLibrary = {
    -- NHẠC TRUNG QUỐC / DOUYIN HOT
    {
        Name = "🇨🇳 Thời Không Sai Lệch (错位时空 - Cuo Wei Shi Kong)",
        BPM  = 78,
        Sheet = "[6e] 0 e r [4t] 8 q w [1e] 5 8 0 [5w] 9 w r | [6e] 0 e r [4t] 8 q w [1e] 5 8 0 [5w] | [6et] y [4qe] r [10w] e [5wq] w | [6e] 0 e t [4q] 8 q r [10] 5 0 e [5w] 9 w | [6ep] a s [4qa] s d [10s] a p [5wa] p o [6ep]"
    },
    {
        Name = "🇨🇳 Đồng Thoại (童话 - Tong Hua - Quang Lương)",
        BPM  = 72,
        Sheet = "[1o] 5 8 0 w 0 [5i] 2 5 7 9 7 [6u] 3 6 8 0 8 [3y] 7 0 w r w | [4t] 1 4 6 8 6 [1r] 5 8 0 w 0 [2e] 6 9 q e q [5w] 2 5 7 9 7 | [1o] 5 8 0 [5u] [5i] [6u] 3 6 8 [6y] [6t] [4t] 1 4 6 [4r] [4e] [5w] 2 5 7 9 | [1s] [5a] [8p] [0o] [5i] [2u] [5y] [7t] [1s]"
    },
    {
        Name = "🇨🇳 Phi Điểu Và Ve Sầu (飞鸟和蝉 - Fei Niao He Chan)",
        BPM  = 80,
        Sheet = "[1s] 5 8 0 w [5a] 2 5 7 9 [6p] 3 6 8 0 [3o] 7 0 w r | [4p] 1 4 6 8 [1o] 5 8 0 w [2i] 6 9 q e [5u] 2 5 7 9 | [1s] [5a] [8p] [0o] [5i] [2u] [5y] [7t] [6r] [3e] [6w] [8q] [30] | [4e] [6t] [8u] [5o] [7p] [9a] [1s]"
    },
    {
        Name = "🇨🇳 Tay Trái Chỉ Trăng (左手指月 - Zuo Shou Zhi Yue)",
        BPM  = 76,
        Sheet = "[6e] [0u] [6e] [0u] [30] [7w] [30] [7w] [4q] [8e] [4q] [8e] [10] [5w] [10] [5w] | [29] [6q] [29] [6q] [6e] [0u] [6e] [0u] [5w] [9r] [5w] [9r] [30] [7w] [30] [7w] | [6ep] a [0s] d [4qf] g [8h] j [10k] l [5j] h [5wf] d [9s] a [6ep]"
    },

    -- NHẠC VIỆT NAM HOT TREND 2024 - 2026
    {
        Name = "🇻🇳 Đừng Làm Trái Tim Anh Đau - Sơn Tùng M-TP",
        BPM  = 88,
        Sheet = "[8s] [0w] [8s] [8s] [5a] [9w] [6p] [0e] [6p] [4a] [8q] | [8s] [0w] [8s] [8s] [5a] [9w] [6p] [0e] [6p] [4a] [8q] | [8s] [8d] [8f] [5a] [5s] [5d] [6p] [6a] [6s] [4o] [4p] [4a] | [8u] [0w] [8o] [8s] [5w] [9w] [5o] [5a] [6e] [0e] [6u] [6p] [4q] [8q] [4i] [4o] [8s]"
    },
    {
        Name = "🇻🇳 Cắt Đôi Nỗi Sầu - Tăng Duy Tân",
        BPM  = 90,
        Sheet = "[6p] [0e] [6p] [0e] [4a] [8q] [4a] [8q] [1s] [5w] [1s] [5w] [5a] [9w] [5p] [9w] | [6p] [6p] [6p] [0u] [4a] [4a] [4a] [8t] [1s] [1s] [1s] [5w] [5a] [5a] [5a] [9r] | [6p] a s [4a] s d [1s] a p [5a] p o [6p]"
    },
    {
        Name = "🇻🇳 Nơi Này Có Anh - Sơn Tùng M-TP",
        BPM  = 84,
        Sheet = "[4s] [8q] [4s] [4s] [5a] [9w] [5p] [3o] [70] [3o] [3p] [6a] [0e] [6s] | [4d] [8q] [4d] [4d] [5s] [9w] [5a] [3p] [70] [3o] [6p] [0e] [6a] | [4s] [8q] [4d] [5s] [9w] [5a] [1s] [5w] [10]"
    },
    {
        Name = "🇻🇳 See Tình - Hoàng Thùy Linh",
        BPM  = 95,
        Sheet = "[4s] [4s] [4s] [4d] [5d] [5d] [5d] [5f] [6f] [6f] [6f] [6d] [6s] [6a] | [4s] [4s] [4s] [4d] [5d] [5d] [5d] [5f] [6f] [6f] [6f] [6d] [6s] [6a] | [4i] p [5o] a [6p] s [6d] [4i] p [5o] a [6p]"
    },
    {
        Name = "🇻🇳 Cô Nàng Áo Dài - Hot Trend TikTok",
        BPM  = 86,
        Sheet = "o p [6s] s d [6f] f g [6d] s [4p] p a [4s] s d [4a] p | [1o] o p [1s] s d [1f] [5d] s a [5p] o | [6s] s d [6f] f g [6d] s [4p] p a [4s] s d [4a] p [1s]"
    },

    -- NHẠC QUỐC TẾ HOT TREND 2024 - 2026
    {
        Name = "🌍 APT. - ROSÉ & Bruno Mars (Hot #1)",
        BPM  = 95,
        Sheet = "[8f] [0w] [8f] [8f] [8d] [9f] [Qe] [9f] [9f] [9d] [0f] [wr] [0f] [0f] [0d] [wf] [ry] [wd] [wf] | [8f] [0w] [8f] [8f] [8d] [9f] [Qe] [9f] [9f] [9d] [0f] [wr] [0f] [0f] [0d] [wf] [ry] [wd] [wf] | [8s] [0w] [8s] [8s] [8a] [9p] [Qe] [9p] [9p] [9o] [0p] [wr] [0p] [0p] [0a] [ws] [ry] [wd]"
    },
    {
        Name = "🌍 Die With A Smile - Lady Gaga & Bruno Mars",
        BPM  = 75,
        Sheet = "[8o] [wh] [0j] [wh] [8f] [4i] [8p] [qd] [8p] [1u] [5o] [8s] [5o] [5y] [9o] [wa] [9o] | [8o] [wh] [0j] [wh] [8f] [4i] [8p] [qd] [8p] [1u] [5o] [8s] [5o] [5y] [9o] [wa] [9o] | [8s] [wh] [0j] [wh] [8f] [4d] [8p] [qd] [8p] [1s]"
    },
    {
        Name = "🌍 Golden Hour - JVKE",
        BPM  = 90,
        Sheet = "[id] [pf] [sh] [pj] [sh] [pf] [id] [pf] [sh] [pj] [sh] [pf] | [od] [pf] [sh] [pj] [sh] [pf] [od] [pf] [sh] [pj] [sh] [pf] | [yd] [pf] [sh] [pj] [sh] [pf] [yd] [pf] [sh] [pj] [sh] [pf] | [td] [pf] [sh] [pj] [sh] [pf] [td] [pf] [sh] [pj] [sh] [pf]"
    },
    {
        Name = "🌍 Until I Found You - Stephen Sanchez",
        BPM  = 72,
        Sheet = "[tf] f s o [ra] h f a o a | [ti] s g s p [ts] [ts] [ts] [tg] [tg] [tg] | [yh] [yh] [yh] [yd] [yd] [yd] | [tf] f s o [ra] h f a o a | [ti] s g s p [ts] [ts] [ts] [tg] [tg] [tg]"
    },
    {
        Name = "🌍 Glimpse of Us - Joji",
        BPM  = 68,
        Sheet = "[6e] [0u] [6e] [0u] [4q] [8t] [4q] [8t] [10] [5w] [10] [5w] [5w] [9r] [5w] [9r] | [6e] u [0p] [6e] u [0p] [4q] t [8i] [4q] t [8i] [10] w [5u] [10] w [5u] [5w] r [9y] [5w] r [9y] | [6ep] [0e] [6ea] [0e] [4qs] [8q] [4qd] [8q] [10f] [5w] [10d] [5w] [5ws]"
    },
    {
        Name = "🌍 A Thousand Years - Christina Perri",
        BPM  = 76,
        Sheet = "[1u] [5o] [8s] [5o] [1u] [5o] [8s] [5o] [4i] [8p] [qd] [8p] [4i] [8p] [qd] [8p] | [1u] [5o] [8s] [5o] [5y] [9o] [wa] [9o] [6t] [0u] [ep] [0u] [4i] [8p] [qd] [8p] | [1u] o s [5y] o a [6t] u p [4r] y o [1u]"
    },
    {
        Name = "🎼 Canon in D - Pachelbel (Bản Giao Hưởng)",
        BPM  = 80,
        Sheet = "u o a d f [oa] h [os] h [yd] g [ya] g [tu] f [ts] f [re] d [ra] d [we] s [wo] s [qe] a [qp] a [0u] o [0y] o | [8u] o a d f [oa] h [os] h [yd] g [ya] g [tu] f [ts] f [re] d [ra] d [we] s [wo] s [qe] a [qp] a [0u] o [0y] o"
    },
    {
        Name = "🎼 Fur Elise - Beethoven (Bản Chuẩn Gốc)",
        BPM  = 96,
        Sheet = "e W e W e u y t r | [0e] t u [60r] u O [60e] u | e W e W e u y t r | [0e] t u [60r] u O [60e] | [0r] t y [8u] i o [7y] u i [6t] y u [5r] | e W e W e u y t r | [0e] t u [60r] u O [60e]"
    },
    {
        Name = "🎼 Interstellar Theme - Hans Zimmer",
        BPM  = 82,
        Sheet = "u o u o u o u o | [6u] o [6u] o [6u] o [6u] o | [4u] p [4u] p [4u] p [4u] p | [1u] o [1u] o [1u] o [1u] o | [5u] o [5u] o [5u] o [5u] o | [6u] [0o] [6u] [0o] [4u] [8p] [4u] [8p] [1u] [5o] [1u] [5o] [5y] [9o] [5y] [9o] | [6t] [0u] [6t] [0u]"
    }
}

-- Trạng thái
local Config = {
    BPM         = SongLibrary[1].BPM,
    UseGameChat = false, -- Gửi lệnh >auto vào game
    Loop        = false,
}

local Playback = {
    IsPlaying = false,
    IsPaused  = false,
    Thread    = nil,
    CurrentSong = SongLibrary[1].Name,
    CustomSheet = SongLibrary[1].Sheet,
}

-- Gửi lệnh chat >auto vào game
local function sendChatAuto(sheetText)
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

-- Bấm phím đơn (êm dịu, không giật cục)
local function hitKey(char)
    local map = KeyMap[char]
    if not map then return end
    pcall(function()
        if map.Shift then
            VirtualInputMgr:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game)
            task.wait(0.005)
        end
        VirtualInputMgr:SendKeyEvent(true, map.Code, false, game)
        task.wait(0.04) -- Độ ngân phím ấm
        VirtualInputMgr:SendKeyEvent(false, map.Code, false, game)
        if map.Shift then
            task.wait(0.005)
            VirtualInputMgr:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, game)
        end
    end)
end

-- Bấm hợp âm chuẩn
local function hitChord(chord)
    local shifts = false
    local list = {}
    for i = 1, #chord do
        local c = chord:sub(i, i)
        local m = KeyMap[c]
        if m then
            table.insert(list, m.Code)
            if m.Shift then shifts = true end
        end
    end
    if #list == 0 then return end

    pcall(function()
        if shifts then
            VirtualInputMgr:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game)
            task.wait(0.005)
        end
        for _, kc in ipairs(list) do
            VirtualInputMgr:SendKeyEvent(true, kc, false, game)
            task.wait(0.003)
        end
        task.wait(0.05)
        for _, kc in ipairs(list) do
            VirtualInputMgr:SendKeyEvent(false, kc, false, game)
        end
        if shifts then
            task.wait(0.005)
            VirtualInputMgr:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, game)
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

-- Bộ phát nhạc du dương theo đúng nhịp điệu bài hát
local function playMusic(sheetText, bpm)
    stopMusic()
    Playback.IsPlaying = true
    Playback.IsPaused  = false

    -- Nếu bật chế độ dùng lệnh game >auto
    if Config.UseGameChat then
        sendChatAuto(sheetText)
        Playback.IsPlaying = false
        return
    end

    Playback.Thread = task.spawn(function()
        local beat = 60 / bpm -- Nhịp cơ bản (ví dụ 80 BPM = 0.75s)

        repeat
            local i = 1
            local len = #sheetText

            while i <= len and Playback.IsPlaying do
                while Playback.IsPaused and Playback.IsPlaying do
                    task.wait(0.1)
                end
                if not Playback.IsPlaying then break end

                local char = sheetText:sub(i, i)

                if char == "[" then
                    local closeIdx = sheetText:find("%]", i)
                    if closeIdx then
                        local chordContent = sheetText:sub(i + 1, closeIdx - 1)
                        hitChord(chordContent)
                        i = closeIdx + 1
                    else
                        i = i + 1
                    end
                    task.wait(beat * 0.45) -- Ngân hợp âm

                elseif char == " " then
                    -- Khoảng trắng = nghỉ nhịp phách
                    task.wait(beat * 0.4)
                    i = i + 1

                elseif char == "|" then
                    -- Vạch nhịp = nghỉ chuyển đoạn
                    task.wait(beat * 1.0)
                    i = i + 1

                else
                    if KeyMap[char] then
                        hitKey(char)
                        task.wait(beat * 0.38) -- Nốt ngân vang du dương
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

        stopMusic()
    end)
end

-- Tìm ghế và ngồi vào đàn
local function sitPiano(statusLabel)
    local char = LP.Character
    if not char then return end
    local hrp  = char:FindFirstChild("HumanoidRootPart")
    local hum  = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    local bestSeat = nil
    local bestDist = 9999

    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Seat") or obj:IsA("VehicleSeat") then
            local d = (hrp.Position - obj.Position).Magnitude
            if not obj.Occupant and d < bestDist then
                bestSeat = obj
                bestDist = d
            end
        end
    end

    if bestSeat then
        if statusLabel then statusLabel.Text = "⏳ Đang ngồi vào đàn..." end
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.CFrame = CFrame.new(bestSeat.Position + Vector3.new(0, 0.6, 0), bestSeat.Position + (bestSeat.CFrame.LookVector * 5))
        task.wait(0.1)

        for _ = 1, 3 do
            pcall(function() bestSeat:Sit(hum) end)
            task.wait(0.08)
            if hum.Sit then break end
        end

        if fireproximityprompt then
            for _, p in pairs(bestSeat:GetDescendants()) do
                if p:IsA("ProximityPrompt") then pcall(function() fireproximityprompt(p) end) end
            end
            if bestSeat.Parent then
                for _, p in pairs(bestSeat.Parent:GetDescendants()) do
                    if p:IsA("ProximityPrompt") then pcall(function() fireproximityprompt(p) end) end
                end
            end
        end

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
Main.Size             = UDim2.new(0, 310, 0, 580)
Main.Position         = UDim2.new(0, 20, 0.5, -290)
Main.BackgroundColor3 = Color3.fromRGB(12, 12, 20)
Main.BorderSizePixel  = 0
Main.Active           = true
Main.Draggable        = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 14)

local stroke = Instance.new("UIStroke", Main)
stroke.Color = Color3.fromRGB(120, 60, 230)
stroke.Thickness = 1.5

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

local Scroll = Instance.new("ScrollingFrame", Main)
Scroll.Size             = UDim2.new(0.92, 0, 0, 515)
Scroll.Position         = UDim2.new(0.04, 0, 0, 55)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel  = 0
Scroll.ScrollBarThickness = 3
Scroll.ScrollBarImageColor3 = Color3.fromRGB(120, 70, 230)
Scroll.CanvasSize       = UDim2.new(0, 0, 0, 1150)

local uiList = Instance.new("UIListLayout", Scroll)
uiList.SortOrder = Enum.SortOrder.LayoutOrder
uiList.Padding   = UDim.new(0, 8)

-- 1. NÚT NGỒI VÀO ĐÀN
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
btnSit.MouseButton1Click:Connect(function() sitPiano(btnSit) end)

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

-- 3. HỘP CÔNG CỤ: LỆNH GAME >AUTO & NÚT COPY SHEET
local toolFrame = Instance.new("Frame", Scroll)
toolFrame.Size             = UDim2.new(1, 0, 0, 36)
toolFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
toolFrame.LayoutOrder      = 3
Instance.new("UICorner", toolFrame).CornerRadius = UDim.new(0, 8)

local btnCopy = Instance.new("TextButton", toolFrame)
btnCopy.Size             = UDim2.new(0.48, 0, 0.8, 0)
btnCopy.Position         = UDim2.new(0.02, 0, 0.1, 0)
btnCopy.BackgroundColor3 = Color3.fromRGB(30, 45, 80)
btnCopy.Text             = "📋 Chép Sheet"
btnCopy.TextColor3       = Color3.fromRGB(180, 215, 255)
btnCopy.Font             = Enum.Font.GothamBold
btnCopy.TextSize         = 11
Instance.new("UICorner", btnCopy).CornerRadius = UDim.new(0, 6)

local btnChatAuto = Instance.new("TextButton", toolFrame)
btnChatAuto.Size             = UDim2.new(0.48, 0, 0.8, 0)
btnChatAuto.Position         = UDim2.new(0.50, 0, 0.1, 0)
btnChatAuto.BackgroundColor3 = Color3.fromRGB(45, 25, 75)
btnChatAuto.Text             = "💬 Gửi Lệnh >auto"
btnChatAuto.TextColor3       = Color3.fromRGB(220, 180, 255)
btnChatAuto.Font             = Enum.Font.GothamBold
btnChatAuto.TextSize         = 11
Instance.new("UICorner", btnChatAuto).CornerRadius = UDim.new(0, 6)

btnCopy.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(Playback.CustomSheet)
        btnCopy.Text = "✅ Đã Chép!"
        task.delay(1.5, function() btnCopy.Text = "📋 Chép Sheet" end)
    else
        btnCopy.Text = "❌ Không hỗ trợ"
    end
end)

btnChatAuto.MouseButton1Click:Connect(function()
    sendChatAuto(Playback.CustomSheet)
    btnChatAuto.Text = "✅ Đã Gửi!"
    task.delay(1.5, function() btnChatAuto.Text = "💬 Gửi Lệnh >auto" end)
end)

-- 4. ĐIỀU CHỈNH TỐC ĐỘ (BPM)
local bpmFrame = Instance.new("Frame", Scroll)
bpmFrame.Size             = UDim2.new(1, 0, 0, 36)
bpmFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
bpmFrame.LayoutOrder      = 4
Instance.new("UICorner", bpmFrame).CornerRadius = UDim.new(0, 8)

local bpmLabel = Instance.new("TextLabel", bpmFrame)
bpmLabel.Size               = UDim2.new(0.55, 0, 1, 0)
bpmLabel.Position           = UDim2.new(0.04, 0, 0, 0)
bpmLabel.BackgroundTransparency = 1
bpmLabel.Text               = "Tốc độ: " .. Config.BPM .. " BPM"
bpmLabel.TextColor3         = Color3.fromRGB(210, 200, 230)
bpmLabel.Font               = Enum.Font.GothamSemibold
bpmLabel.TextSize           = 12
bpmLabel.TextXAlignment     = Enum.TextXAlignment.Left

local btnMinus = Instance.new("TextButton", bpmFrame)
btnMinus.Size             = UDim2.new(0, 34, 0, 26)
btnMinus.Position         = UDim2.new(0.65, 0, 0.5, -13)
btnMinus.BackgroundColor3 = Color3.fromRGB(35, 30, 55)
btnMinus.Text             = "-10"
btnMinus.TextColor3       = Color3.fromRGB(220, 200, 255)
btnMinus.Font             = Enum.Font.GothamBold
btnMinus.TextSize         = 11
Instance.new("UICorner", btnMinus).CornerRadius = UDim.new(0, 6)

local btnPlus = Instance.new("TextButton", bpmFrame)
btnPlus.Size              = UDim2.new(0, 34, 0, 26)
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
    Config.BPM = math.min(200, Config.BPM + 10)
    bpmLabel.Text = "Tốc độ: " .. Config.BPM .. " BPM"
end)

-- 5. Ô NHẬP SHEET NHẠC TÙY Ý
local sheetTitle = Instance.new("TextLabel", Scroll)
sheetTitle.Size               = UDim2.new(1, 0, 0, 18)
sheetTitle.BackgroundTransparency = 1
sheetTitle.Text               = "📝 Dán Sheet Nhạc Tùy Ý (Virtual Piano):"
sheetTitle.TextColor3         = Color3.fromRGB(170, 150, 210)
sheetTitle.Font               = Enum.Font.GothamSemibold
sheetTitle.TextSize           = 11
sheetTitle.TextXAlignment     = Enum.TextXAlignment.Left
sheetTitle.LayoutOrder        = 5

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
sheetBox.LayoutOrder          = 6
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
        playMusic(Playback.CustomSheet, Config.BPM)
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

-- 6. THANH TÌM KIẾM BÀI HÁT
local searchBox = Instance.new("TextBox", Scroll)
searchBox.Size                 = UDim2.new(1, 0, 0, 34)
searchBox.BackgroundColor3     = Color3.fromRGB(22, 20, 35)
searchBox.PlaceholderText      = "🔍 Tìm kiếm bài hát (gõ tên bài)..."
searchBox.PlaceholderColor3    = Color3.fromRGB(130, 120, 160)
searchBox.Text                 = ""
searchBox.TextColor3           = Color3.fromRGB(230, 220, 255)
searchBox.Font                 = Enum.Font.Gotham
searchBox.TextSize             = 11.5
searchBox.LayoutOrder          = 7
Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0, 8)
local sSearch = Instance.new("UIStroke", searchBox)
sSearch.Color = Color3.fromRGB(90, 50, 170); sSearch.Thickness = 1

local libTitle = Instance.new("TextLabel", Scroll)
libTitle.Size               = UDim2.new(1, 0, 0, 18)
libTitle.BackgroundTransparency = 1
libTitle.Text               = "🎵 Danh Sách Nhạc Hot (Chạm Để Đánh):"
libTitle.TextColor3         = Color3.fromRGB(170, 150, 210)
libTitle.Font               = Enum.Font.GothamSemibold
libTitle.TextSize           = 11
libTitle.TextXAlignment     = Enum.TextXAlignment.Left
libTitle.LayoutOrder        = 8

-- 7. TẠO DANH SÁCH BÀI HÁT
local songButtons = {}

for idx, song in ipairs(SongLibrary) do
    local sBtn = Instance.new("TextButton", Scroll)
    sBtn.Size             = UDim2.new(1, 0, 0, 34)
    sBtn.BackgroundColor3 = Color3.fromRGB(22, 20, 34)
    sBtn.Text             = "  " .. idx .. ". " .. song.Name
    sBtn.TextColor3       = Color3.fromRGB(200, 190, 220)
    sBtn.Font             = Enum.Font.Gotham
    sBtn.TextSize         = 10.5
    sBtn.TextXAlignment   = Enum.TextXAlignment.Left
    sBtn.LayoutOrder      = 8 + idx
    Instance.new("UICorner", sBtn).CornerRadius = UDim.new(0, 6)

    sBtn.MouseButton1Click:Connect(function()
        Playback.CustomSheet = song.Sheet
        sheetBox.Text        = song.Sheet
        Config.BPM           = song.BPM
        bpmLabel.Text        = "Tốc độ: " .. Config.BPM .. " BPM"
        playMusic(song.Sheet, song.BPM)
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

print("[VOSS] Visual Piano Hub 🎹 (Master Acoustic Edition) Loaded!")
