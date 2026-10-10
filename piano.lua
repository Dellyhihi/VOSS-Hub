-- ================================================
-- VOSS | Visual Piano Hub 🎹 (Screen Touch Edition)
-- Game: Visual Pianos (PlaceId: 5593470048)
-- ================================================
-- [FIX TRIỆT ĐỂ LỖI ĐÁNH LINH TINH]:
-- 1. TỰ ĐỘNG CHẠM PHÍM ĐÀN TRÊN MÀN HÌNH (SCREEN KEY DETECTOR):
--    - Tự động nhận diện toàn bộ các phím đàn đang mở trên màn hình điện thoại
--    - Sắp xếp từ trái qua phải chuẩn xác 88 phím (từ C1 đến C8)
--    - Bấm nốt nào là phím đàn TRÊN MÀN HÌNH TỰ ĐỘNG CHẠM NỐT ĐÓ!
--    - Không dùng phím số máy tính tránh bị nhảy Quãng Tám 8 ngoài cùng bên phải!
-- 2. TÍCH HỢP 3 CHẾ ĐỘ PHÁT TỐI THƯỢNG:
--    - Chế độ 1: Tự Chạm Phím Trên Màn Hình (Âm thanh chuẩn 100%, đèn xanh sáng đúng nốt)
--    - Chế độ 2: Gửi Lệnh >auto vào chat game (Bộ phòng thu gốc của Visual Pianos)
--    - Chế độ 3: [📋 Chép Sheet] 1 chạm để bạn dán vào icon [🎼] trên màn hình
-- 3. KHO NHẠC HOT TREND ĐẦY ĐỦ (TRUNG QUỐC DOUYIN & VIỆT NAM 2026)
-- ================================================

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local VirtualInputMgr   = game:GetService("VirtualInputManager")
local VirtualUser       = game:GetService("VirtualUser")
local TextChatService   = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local LP                = Players.LocalPlayer

-- ================================================
-- BẢNG ÁNH XẠ CHUẨN: KÝ TỰ VIRTUAL PIANO -> VỊ TRÍ PHÍM ĐÀN TRÊN MÀN HÌNH (88 KEYS)
-- ================================================
-- Trên đàn 88 phím:
-- Key 1 = A0, Key 4 = C1, Key 16 = C2 (VP "1"), Key 28 = C3 (VP "8"),
-- Key 40 = C4 (Middle C, VP "t"), Key 52 = C5 (VP "s"), Key 64 = C6 (VP "l"), Key 76 = C7 (VP "m")
local VPtoIndex = {
    -- Quãng 2 (C2 -> B2)
    ["1"] = 16, ["!"] = 17, ["2"] = 18, ["@"] = 19, ["3"] = 20,
    ["4"] = 21, ["$"] = 22, ["5"] = 23, ["%"] = 24, ["6"] = 25,
    ["^"] = 26, ["7"] = 27,

    -- Quãng 3 (C3 -> B3)
    ["8"] = 28, ["*"] = 29, ["9"] = 30, ["("] = 31, ["0"] = 32,
    ["q"] = 33, ["Q"] = 34, ["w"] = 35, ["W"] = 36, ["e"] = 37,
    ["E"] = 38, ["r"] = 39,

    -- Quãng 4 (C4 Middle C -> B4)
    ["t"] = 40, ["T"] = 41, ["y"] = 42, ["Y"] = 43, ["u"] = 44,
    ["i"] = 45, ["I"] = 46, ["o"] = 47, ["O"] = 48, ["p"] = 49,
    ["P"] = 50, ["a"] = 51,

    -- Quãng 5 (C5 -> B5)
    ["s"] = 52, ["S"] = 53, ["d"] = 54, ["D"] = 55, ["f"] = 56,
    ["g"] = 57, ["G"] = 58, ["h"] = 59, ["H"] = 60, ["j"] = 61,
    ["J"] = 62, ["k"] = 63,

    -- Quãng 6 (C6 -> B6)
    ["l"] = 64, ["L"] = 65, ["z"] = 66, ["Z"] = 67, ["x"] = 68,
    ["c"] = 69, ["C"] = 70, ["v"] = 71, ["V"] = 72, ["b"] = 73,
    ["B"] = 74, ["n"] = 75,

    -- Quãng 7 (C7)
    ["m"] = 76
}

-- Bảng KeyCode dự phòng khi không có phím cảm ứng trên màn hình
local KeyMap = {
    ["1"] = {Code = Enum.KeyCode.One, Shift = false}, ["2"] = {Code = Enum.KeyCode.Two, Shift = false},
    ["3"] = {Code = Enum.KeyCode.Three, Shift = false}, ["4"] = {Code = Enum.KeyCode.Four, Shift = false},
    ["5"] = {Code = Enum.KeyCode.Five, Shift = false}, ["6"] = {Code = Enum.KeyCode.Six, Shift = false},
    ["7"] = {Code = Enum.KeyCode.Seven, Shift = false}, ["8"] = {Code = Enum.KeyCode.Eight, Shift = false},
    ["9"] = {Code = Enum.KeyCode.Nine, Shift = false}, ["0"] = {Code = Enum.KeyCode.Zero, Shift = false},
    ["!"] = {Code = Enum.KeyCode.One, Shift = true}, ["@"] = {Code = Enum.KeyCode.Two, Shift = true},
    ["#"] = {Code = Enum.KeyCode.Three, Shift = true}, ["$"] = {Code = Enum.KeyCode.Four, Shift = true},
    ["%"] = {Code = Enum.KeyCode.Five, Shift = true}, ["^"] = {Code = Enum.KeyCode.Six, Shift = true},
    ["&"] = {Code = Enum.KeyCode.Seven, Shift = true}, ["*"] = {Code = Enum.KeyCode.Eight, Shift = true},
    ["("] = {Code = Enum.KeyCode.Nine, Shift = true}, [")"] = {Code = Enum.KeyCode.Zero, Shift = true},
    ["q"] = {Code = Enum.KeyCode.Q, Shift = false}, ["w"] = {Code = Enum.KeyCode.W, Shift = false},
    ["e"] = {Code = Enum.KeyCode.E, Shift = false}, ["r"] = {Code = Enum.KeyCode.R, Shift = false},
    ["t"] = {Code = Enum.KeyCode.T, Shift = false}, ["y"] = {Code = Enum.KeyCode.Y, Shift = false},
    ["u"] = {Code = Enum.KeyCode.U, Shift = false}, ["i"] = {Code = Enum.KeyCode.I, Shift = false},
    ["o"] = {Code = Enum.KeyCode.O, Shift = false}, ["p"] = {Code = Enum.KeyCode.P, Shift = false},
    ["a"] = {Code = Enum.KeyCode.A, Shift = false}, ["s"] = {Code = Enum.KeyCode.S, Shift = false},
    ["d"] = {Code = Enum.KeyCode.D, Shift = false}, ["f"] = {Code = Enum.KeyCode.F, Shift = false},
    ["g"] = {Code = Enum.KeyCode.G, Shift = false}, ["h"] = {Code = Enum.KeyCode.H, Shift = false},
    ["j"] = {Code = Enum.KeyCode.J, Shift = false}, ["k"] = {Code = Enum.KeyCode.K, Shift = false},
    ["l"] = {Code = Enum.KeyCode.L, Shift = false}, ["z"] = {Code = Enum.KeyCode.Z, Shift = false},
    ["x"] = {Code = Enum.KeyCode.X, Shift = false}, ["c"] = {Code = Enum.KeyCode.C, Shift = false},
    ["v"] = {Code = Enum.KeyCode.V, Shift = false}, ["b"] = {Code = Enum.KeyCode.B, Shift = false},
    ["n"] = {Code = Enum.KeyCode.N, Shift = false}, ["m"] = {Code = Enum.KeyCode.M, Shift = false},
    ["Q"] = {Code = Enum.KeyCode.Q, Shift = true}, ["W"] = {Code = Enum.KeyCode.W, Shift = true},
    ["E"] = {Code = Enum.KeyCode.E, Shift = true}, ["R"] = {Code = Enum.KeyCode.R, Shift = true},
    ["T"] = {Code = Enum.KeyCode.T, Shift = true}, ["Y"] = {Code = Enum.KeyCode.Y, Shift = true},
    ["U"] = {Code = Enum.KeyCode.U, Shift = true}, ["I"] = {Code = Enum.KeyCode.I, Shift = true},
    ["O"] = {Code = Enum.KeyCode.O, Shift = true}, ["P"] = {Code = Enum.KeyCode.P, Shift = true},
    ["A"] = {Code = Enum.KeyCode.A, Shift = true}, ["S"] = {Code = Enum.KeyCode.S, Shift = true},
    ["D"] = {Code = Enum.KeyCode.D, Shift = true}, ["F"] = {Code = Enum.KeyCode.F, Shift = true},
    ["G"] = {Code = Enum.KeyCode.G, Shift = true}, ["H"] = {Code = Enum.KeyCode.H, Shift = true},
    ["J"] = {Code = Enum.KeyCode.J, Shift = true}, ["K"] = {Code = Enum.KeyCode.K, Shift = true},
    ["L"] = {Code = Enum.KeyCode.L, Shift = true}, ["Z"] = {Code = Enum.KeyCode.Z, Shift = true},
    ["X"] = {Code = Enum.KeyCode.X, Shift = true}, ["C"] = {Code = Enum.KeyCode.C, Shift = true},
    ["V"] = {Code = Enum.KeyCode.V, Shift = true}, ["B"] = {Code = Enum.KeyCode.B, Shift = true},
    ["N"] = {Code = Enum.KeyCode.N, Shift = true}, ["M"] = {Code = Enum.KeyCode.M, Shift = true},
}

-- ================================================
-- KHO NHẠC SIÊU HOT HIT
-- ================================================
local SongLibrary = {
    -- NHẠC TRUNG QUỐC / DOUYIN HOT
    {
        Name = "🇨🇳 Thời Không Sai Lệch (错位时空 - Cuo Wei Shi Kong)",
        BPM  = 78,
        Sheet = "[6e] 0 e r [4t] 8 q w [1e] 5 8 0 [5w] 9 w r [6e] 0 e r [4t] 8 q w [1e] 5 8 0 [5w] [6et] y [4qe] r [10w] e [5wq] w [6e] 0 e t [4q] 8 q r [10] 5 0 e [5w] 9 w [6ep] a s [4qa] s d [10s] a p [5wa] p o [6ep]"
    },
    {
        Name = "🇨🇳 Đồng Thoại (童话 - Tong Hua - Quang Lương)",
        BPM  = 72,
        Sheet = "[1o] 5 8 0 w 0 [5i] 2 5 7 9 7 [6u] 3 6 8 0 8 [3y] 7 0 w r w [4t] 1 4 6 8 6 [1r] 5 8 0 w 0 [2e] 6 9 q e q [5w] 2 5 7 9 7 [1o] 5 8 0 [5u] [5i] [6u] 3 6 8 [6y] [6t] [4t] 1 4 6 [4r] [4e] [5w] 2 5 7 9 [1s] [5a] [8p] [0o] [5i] [2u] [5y] [7t] [1s]"
    },
    {
        Name = "🇨🇳 Phi Điểu Và Ve Sầu (飞鸟和蝉 - Fei Niao He Chan)",
        BPM  = 80,
        Sheet = "[1s] 5 8 0 w [5a] 2 5 7 9 [6p] 3 6 8 0 [3o] 7 0 w r [4p] 1 4 6 8 [1o] 5 8 0 w [2i] 6 9 q e [5u] 2 5 7 9 [1s] [5a] [8p] [0o] [5i] [2u] [5y] [7t] [6r] [3e] [6w] [8q] [30] [4e] [6t] [8u] [5o] [7p] [9a] [1s]"
    },
    {
        Name = "🇨🇳 Tay Trái Chỉ Trăng (左手指月 - Zuo Shou Zhi Yue)",
        BPM  = 76,
        Sheet = "[6e] [0u] [6e] [0u] [30] [7w] [30] [7w] [4q] [8e] [4q] [8e] [10] [5w] [10] [5w] [29] [6q] [29] [6q] [6e] [0u] [6e] [0u] [5w] [9r] [5w] [9r] [30] [7w] [30] [7w] [6ep] a [0s] d [4qf] g [8h] j [10k] l [5j] h [5wf] d [9s] a [6ep]"
    },

    -- NHẠC VIỆT NAM HOT TREND 2024 - 2026
    {
        Name = "🇻🇳 Đừng Làm Trái Tim Anh Đau - Sơn Tùng M-TP",
        BPM  = 88,
        Sheet = "[8s] [0w] [8s] [8s] [5a] [9w] [6p] [0e] [6p] [4a] [8q] [8s] [0w] [8s] [8s] [5a] [9w] [6p] [0e] [6p] [4a] [8q] [8s] [8d] [8f] [5a] [5s] [5d] [6p] [6a] [6s] [4o] [4p] [4a] [8u] [0w] [8o] [8s] [5w] [9w] [5o] [5a] [6e] [0e] [6u] [6p] [4q] [8q] [4i] [4o] [8s]"
    },
    {
        Name = "🇻🇳 Cắt Đôi Nỗi Sầu - Tăng Duy Tân",
        BPM  = 90,
        Sheet = "[6p] [0e] [6p] [0e] [4a] [8q] [4a] [8q] [1s] [5w] [1s] [5w] [5a] [9w] [5p] [9w] [6p] [6p] [6p] [0u] [4a] [4a] [4a] [8t] [1s] [1s] [1s] [5w] [5a] [5a] [5a] [9r] [6p] a s [4a] s d [1s] a p [5a] p o [6p]"
    },
    {
        Name = "🇻🇳 Nơi Này Có Anh - Sơn Tùng M-TP",
        BPM  = 84,
        Sheet = "[4s] [8q] [4s] [4s] [5a] [9w] [5p] [3o] [70] [3o] [3p] [6a] [0e] [6s] [4d] [8q] [4d] [4d] [5s] [9w] [5a] [3p] [70] [3o] [6p] [0e] [6a] [4s] [8q] [4d] [5s] [9w] [5a] [1s] [5w] [10]"
    },
    {
        Name = "🇻🇳 See Tình - Hoàng Thùy Linh",
        BPM  = 95,
        Sheet = "[4s] [4s] [4s] [4d] [5d] [5d] [5d] [5f] [6f] [6f] [6f] [6d] [6s] [6a] [4s] [4s] [4s] [4d] [5d] [5d] [5d] [5f] [6f] [6f] [6f] [6d] [6s] [6a] [4i] p [5o] a [6p] s [6d] [4i] p [5o] a [6p]"
    },
    {
        Name = "🇻🇳 Cô Nàng Áo Dài - Hot Trend TikTok",
        BPM  = 86,
        Sheet = "o p [6s] s d [6f] f g [6d] s [4p] p a [4s] s d [4a] p [1o] o p [1s] s d [1f] [5d] s a [5p] o [6s] s d [6f] f g [6d] s [4p] p a [4s] s d [4a] p [1s]"
    },

    -- NHẠC QUỐC TẾ HOT TREND 2024 - 2026
    {
        Name = "🌍 APT. - ROSÉ & Bruno Mars (Hot #1)",
        BPM  = 95,
        Sheet = "[8f] [0w] [8f] [8f] [8d] [9f] [Qe] [9f] [9f] [9d] [0f] [wr] [0f] [0f] [0d] [wf] [ry] [wd] [wf] [8f] [0w] [8f] [8f] [8d] [9f] [Qe] [9f] [9f] [9d] [0f] [wr] [0f] [0f] [0d] [wf] [ry] [wd] [wf] [8s] [0w] [8s] [8s] [8a] [9p] [Qe] [9p] [9p] [9o] [0p] [wr] [0p] [0p] [0a] [ws] [ry] [wd]"
    },
    {
        Name = "🌍 Die With A Smile - Lady Gaga & Bruno Mars",
        BPM  = 75,
        Sheet = "[8o] [wh] [0j] [wh] [8f] [4i] [8p] [qd] [8p] [1u] [5o] [8s] [5o] [5y] [9o] [wa] [9o] [8o] [wh] [0j] [wh] [8f] [4i] [8p] [qd] [8p] [1u] [5o] [8s] [5o] [5y] [9o] [wa] [9o] [8s] [wh] [0j] [wh] [8f] [4d] [8p] [qd] [8p] [1s]"
    },
    {
        Name = "🌍 Golden Hour - JVKE",
        BPM  = 90,
        Sheet = "[id] [pf] [sh] [pj] [sh] [pf] [id] [pf] [sh] [pj] [sh] [pf] [od] [pf] [sh] [pj] [sh] [pf] [od] [pf] [sh] [pj] [sh] [pf] [yd] [pf] [sh] [pj] [sh] [pf] [yd] [pf] [sh] [pj] [sh] [pf] [td] [pf] [sh] [pj] [sh] [pf] [td] [pf] [sh] [pj] [sh] [pf]"
    },
    {
        Name = "🌍 Until I Found You - Stephen Sanchez",
        BPM  = 72,
        Sheet = "[tf] f s o [ra] h f a o a [ti] s g s p [ts] [ts] [ts] [tg] [tg] [tg] [yh] [yh] [yh] [yd] [yd] [yd] [tf] f s o [ra] h f a o a [ti] s g s p [ts] [ts] [ts] [tg] [tg] [tg]"
    },
    {
        Name = "🌍 Glimpse of Us - Joji",
        BPM  = 68,
        Sheet = "[6e] [0u] [6e] [0u] [4q] [8t] [4q] [8t] [10] [5w] [10] [5w] [5w] [9r] [5w] [9r] [6e] u [0p] [6e] u [0p] [4q] t [8i] [4q] t [8i] [10] w [5u] [10] w [5u] [5w] r [9y] [5w] r [9y] [6ep] [0e] [6ea] [0e] [4qs] [8q] [4qd] [8q] [10f] [5w] [10d] [5w] [5ws]"
    },
    {
        Name = "🌍 A Thousand Years - Christina Perri",
        BPM  = 76,
        Sheet = "[1u] [5o] [8s] [5o] [1u] [5o] [8s] [5o] [4i] [8p] [qd] [8p] [4i] [8p] [qd] [8p] [1u] [5o] [8s] [5o] [5y] [9o] [wa] [9o] [6t] [0u] [ep] [0u] [4i] [8p] [qd] [8p] [1u] o s [5y] o a [6t] u p [4r] y o [1u]"
    },
    {
        Name = "🎼 Canon in D - Pachelbel (Bản Giao Hưởng)",
        BPM  = 80,
        Sheet = "u o a d f [oa] h [os] h [yd] g [ya] g [tu] f [ts] f [re] d [ra] d [we] s [wo] s [qe] a [qp] a [0u] o [0y] o [8u] o a d f [oa] h [os] h [yd] g [ya] g [tu] f [ts] f [re] d [ra] d [we] s [wo] s [qe] a [qp] a [0u] o [0y] o"
    },
    {
        Name = "🎼 Fur Elise - Beethoven (Bản Chuẩn Gốc)",
        BPM  = 96,
        Sheet = "e W e W e u y t r [0e] t u [60r] u O [60e] u e W e W e u y t r [0e] t u [60r] u O [60e] [0r] t y [8u] i o [7y] u i [6t] y u [5r] e W e W e u y t r [0e] t u [60r] u O [60e]"
    },
    {
        Name = "🎼 Interstellar Theme - Hans Zimmer",
        BPM  = 82,
        Sheet = "u o u o u o u o [6u] o [6u] o [6u] o [6u] o [4u] p [4u] p [4u] p [4u] p [1u] o [1u] o [1u] o [1u] o [5u] o [5u] o [5u] o [5u] o [6u] [0o] [6u] [0o] [4u] [8p] [4u] [8p] [1u] [5o] [1u] [5o] [5y] [9o] [5y] [9o] [6t] [0u] [6t] [0u]"
    }
}

-- Trạng thái
local Config = {
    BPM = SongLibrary[1].BPM,
}

local Playback = {
    IsPlaying = false,
    Thread    = nil,
    CurrentSong = SongLibrary[1].Name,
    CustomSheet = SongLibrary[1].Sheet,
}

-- ================================================
-- THUẬT TOÁN QUÉT TÌM PHÍM ĐÀN TRÊN MÀN HÌNH (SCREEN KEYS)
-- ================================================
local cachedScreenKeys = nil
local lastKeyScanTime  = 0

local function scanOnScreenPianoKeys()
    local now = tick()
    if cachedScreenKeys and #cachedScreenKeys >= 50 and (now - lastKeyScanTime) < 5 then
        return cachedScreenKeys
    end

    local pGui = LP:FindFirstChild("PlayerGui")
    if not pGui then return {} end

    -- 1. Tìm container chứa các phím đàn (50 đến 88 phím)
    for _, container in pairs(pGui:GetDescendants()) do
        if container:IsA("Frame") or container:IsA("ScrollingFrame") then
            local children = container:GetChildren()
            local tempKeys = {}
            for _, ch in ipairs(children) do
                if ch:IsA("GuiObject") then
                    local sz = ch.AbsoluteSize
                    if sz.Y > 25 and sz.X > 2 then
                        table.insert(tempKeys, ch)
                    end
                end
            end

            if #tempKeys >= 50 then
                -- Sắp xếp toàn bộ phím từ trái qua phải theo trục X màn hình
                table.sort(tempKeys, function(a, b)
                    return a.AbsolutePosition.X < b.AbsolutePosition.X
                end)
                cachedScreenKeys = tempKeys
                lastKeyScanTime  = now
                return tempKeys
            end
        end
    end

    -- 2. Dự phòng: quét toàn bộ GuiButton liên quan đến piano
    local fallbackKeys = {}
    for _, btn in pairs(pGui:GetDescendants()) do
        if btn:IsA("GuiButton") then
            local n = btn.Name:lower()
            local pn = btn.Parent and btn.Parent.Name:lower() or ""
            if n:find("key") or n:find("note") or pn:find("key") or pn:find("piano") or pn:find("keyboard") then
                table.insert(fallbackKeys, btn)
            end
        end
    end

    if #fallbackKeys >= 50 then
        table.sort(fallbackKeys, function(a, b)
            return a.AbsolutePosition.X < b.AbsolutePosition.X
        end)
        cachedScreenKeys = fallbackKeys
        lastKeyScanTime  = now
        return fallbackKeys
    end

    return {}
end

-- ================================================
-- HÀM CHẠM VÀO PHÍM ĐÀN TRÊN MÀN HÌNH (VẬT LÝ CẢM ỨNG)
-- ================================================
local function pressScreenKey(guiObj)
    if not guiObj then return end

    -- Kích hoạt bằng tín hiệu Event của phím
    if firesignal then
        pcall(function() firesignal(guiObj.InputBegan, {UserInputType = Enum.UserInputType.Touch, UserInputState = Enum.UserInputState.Begin}) end)
        pcall(function() firesignal(guiObj.MouseButton1Down) end)
        pcall(function() firesignal(guiObj.Activated) end)
        task.delay(0.045, function()
            pcall(function() firesignal(guiObj.InputEnded, {UserInputType = Enum.UserInputType.Touch, UserInputState = Enum.UserInputState.End}) end)
            pcall(function() firesignal(guiObj.MouseButton1Up) end)
        end)
    end

    -- Mô phỏng chạm ảo vào tâm phím
    pcall(function()
        local center = guiObj.AbsolutePosition + (guiObj.AbsoluteSize / 2)
        VirtualUser:Button1Down(center)
        task.delay(0.045, function()
            VirtualUser:Button1Up(center)
        end)
    end)
end

-- Bấm phím dự phòng qua VirtualInputManager
local function hitKeyFallback(char)
    local map = KeyMap[char]
    if not map then return end
    pcall(function()
        if map.Shift then
            VirtualInputMgr:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game)
            task.wait(0.005)
        end
        VirtualInputMgr:SendKeyEvent(true, map.Code, false, game)
        task.wait(0.04)
        VirtualInputMgr:SendKeyEvent(false, map.Code, false, game)
        if map.Shift then
            task.wait(0.005)
            VirtualInputMgr:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, game)
        end
    end)
end

-- Hàm phát 1 nốt đơn (Ưu tiên chạm phím màn hình)
local function playSingleNote(char)
    local targetIdx = VPtoIndex[char]
    local keys = scanOnScreenPianoKeys()

    if #keys >= 50 and targetIdx and keys[targetIdx] then
        pressScreenKey(keys[targetIdx])
    else
        hitKeyFallback(char)
    end
end

-- Hàm phát 1 hợp âm (Chạm nhiều phím màn hình cùng lúc)
local function playChordNotes(chordStr)
    local keys = scanOnScreenPianoKeys()
    local hasScreen = (#keys >= 50)

    for i = 1, #chordStr do
        local c = chordStr:sub(i, i)
        local targetIdx = VPtoIndex[c]

        if hasScreen and targetIdx and keys[targetIdx] then
            pressScreenKey(keys[targetIdx])
        else
            hitKeyFallback(c)
        end
        task.wait(0.004)
    end
end

-- ================================================
-- HÀM TIỆN ÍCH GỬI CHAT & CHÉP CLIPBOARD
-- ================================================
local function sendChatCommand(msg)
    pcall(function()
        if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
            local textChannels = TextChatService:FindFirstChild("TextChannels")
            if textChannels then
                local gen = textChannels:FindFirstChild("RBXGeneral")
                if gen then gen:SendAsync(msg); return end
            end
        end
        local sayEvent = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
        if sayEvent and sayEvent:FindFirstChild("SayMessageRequest") then
            sayEvent.SayMessageRequest:FireServer(msg, "All")
            return
        end
    end)
end

local function copySheetToClipboard(text)
    if setclipboard then
        setclipboard(text); return true
    elseif toclipboard then
        toclipboard(text); return true
    end
    return false
end

local function stopMusic()
    Playback.IsPlaying = false
    if Playback.Thread then
        task.cancel(Playback.Thread)
        Playback.Thread = nil
    end
end

-- ================================================
-- VÒNG LẶP PHÁT NHẠC DU DƯƠNG CHUẨN NHỊP PHÁCH
-- ================================================
local function startPlayingMusic(sheetText, bpm)
    stopMusic()
    Playback.IsPlaying = true

    Playback.Thread = task.spawn(function()
        local beat = 60 / bpm
        local i = 1
        local len = #sheetText

        while i <= len and Playback.IsPlaying do
            local char = sheetText:sub(i, i)

            if char == "[" then
                local closeIdx = sheetText:find("%]", i)
                if closeIdx then
                    local chordContent = sheetText:sub(i + 1, closeIdx - 1)
                    playChordNotes(chordContent)
                    i = closeIdx + 1
                else
                    i = i + 1
                end
                task.wait(beat * 0.48)

            elseif char == " " then
                task.wait(beat * 0.40)
                i = i + 1

            elseif char == "|" then
                task.wait(beat * 1.0)
                i = i + 1

            else
                if VPtoIndex[char] or KeyMap[char] then
                    playSingleNote(char)
                    task.wait(beat * 0.40)
                end
                i = i + 1
            end
        end

        stopMusic()
    end)
end

-- ================================================
-- TỰ ĐỘNG TÌM GHẾ & NGỒI VÀO ĐÀN
-- ================================================
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
Title.Size               = UDim2.new(1, 0, 0, 36)
Title.BackgroundTransparency = 1
Title.Text               = "VOSS  |  Visual Piano 🎹"
Title.TextColor3         = Color3.fromRGB(180, 120, 255)
Title.Font               = Enum.Font.GothamBold
Title.TextSize           = 16

local Subtitle = Instance.new("TextLabel", Main)
Subtitle.Size            = UDim2.new(1, 0, 0, 14)
Subtitle.Position        = UDim2.new(0, 0, 0, 32)
Subtitle.BackgroundTransparency = 1
Subtitle.Text            = "3 ngón×2 ẩn | 3 ngón×3 hiện | RShift PC"
Subtitle.TextColor3      = Color3.fromRGB(90, 80, 130)
Subtitle.Font            = Enum.Font.Gotham
Subtitle.TextSize        = 9.5

local Scroll = Instance.new("ScrollingFrame", Main)
Scroll.Size             = UDim2.new(0.92, 0, 0, 520)
Scroll.Position         = UDim2.new(0.04, 0, 0, 50)
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
btnSit.Size             = UDim2.new(1, 0, 0, 36)
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

-- 2. HƯỚNG DẪN ĐÁNH CẢM ỨNG MÀN HÌNH
local tipFrame = Instance.new("Frame", Scroll)
tipFrame.Size             = UDim2.new(1, 0, 0, 54)
tipFrame.BackgroundColor3 = Color3.fromRGB(25, 20, 42)
tipFrame.LayoutOrder      = 2
Instance.new("UICorner", tipFrame).CornerRadius = UDim.new(0, 8)
local sTip = Instance.new("UIStroke", tipFrame)
sTip.Color = Color3.fromRGB(90, 60, 160); sTip.Thickness = 1

local tipLabel = Instance.new("TextLabel", tipFrame)
tipLabel.Size               = UDim2.new(0.92, 0, 1, 0)
tipLabel.Position           = UDim2.new(0.04, 0, 0, 0)
tipLabel.BackgroundTransparency = 1
tipLabel.Text               = "✨ NÂNG CẤP V18: Tự động chạm trực tiếp vào phím đàn trên màn hình ➔ Âm thanh 100% chuẩn, không bị nhảy quãng 8!"
tipLabel.TextColor3         = Color3.fromRGB(210, 190, 255)
tipLabel.Font               = Enum.Font.GothamSemibold
tipLabel.TextSize           = 10
tipLabel.TextWrapped        = true

-- 3. CÁC NÚT ĐIỀU KHIỂN PHÁT NHẠC
local ctlFrame = Instance.new("Frame", Scroll)
ctlFrame.Size             = UDim2.new(1, 0, 0, 42)
ctlFrame.BackgroundTransparency = 1
ctlFrame.LayoutOrder      = 3

local btnPlayTouch = Instance.new("TextButton", ctlFrame)
btnPlayTouch.Size             = UDim2.new(0.58, 0, 1, 0)
btnPlayTouch.BackgroundColor3 = Color3.fromRGB(60, 25, 130)
btnPlayTouch.Text             = "▶ Tự Chạm Đánh Phím"
btnPlayTouch.TextColor3       = Color3.fromRGB(240, 215, 255)
btnPlayTouch.Font             = Enum.Font.GothamBold
btnPlayTouch.TextSize         = 11.5
Instance.new("UICorner", btnPlayTouch).CornerRadius = UDim.new(0, 8)
local sPt = Instance.new("UIStroke", btnPlayTouch)
sPt.Color = Color3.fromRGB(150, 80, 255); sPt.Thickness = 1

local btnStopTouch = Instance.new("TextButton", ctlFrame)
btnStopTouch.Size             = UDim2.new(0.39, 0, 1, 0)
btnStopTouch.Position         = UDim2.new(0.61, 0, 0, 0)
btnStopTouch.BackgroundColor3 = Color3.fromRGB(75, 20, 35)
btnStopTouch.Text             = "⏹ Dừng Đàn"
btnStopTouch.TextColor3       = Color3.fromRGB(255, 170, 180)
btnStopTouch.Font             = Enum.Font.GothamBold
btnStopTouch.TextSize         = 11.5
Instance.new("UICorner", btnStopTouch).CornerRadius = UDim.new(0, 8)
local sSt = Instance.new("UIStroke", btnStopTouch)
sSt.Color = Color3.fromRGB(180, 50, 70); sSt.Thickness = 1

btnPlayTouch.MouseButton1Click:Connect(function()
    startPlayingMusic(Playback.CustomSheet, Config.BPM)
end)

btnStopTouch.MouseButton1Click:Connect(function()
    stopMusic()
end)

-- 4. HỘP CÔNG CỤ PHỤ: CHÉP SHEET VÀ GỬI LỆNH >AUTO
local subActFrame = Instance.new("Frame", Scroll)
subActFrame.Size             = UDim2.new(1, 0, 0, 36)
subActFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
subActFrame.LayoutOrder      = 4
Instance.new("UICorner", subActFrame).CornerRadius = UDim.new(0, 8)

local btnCopySheet = Instance.new("TextButton", subActFrame)
btnCopySheet.Size             = UDim2.new(0.48, 0, 0.8, 0)
btnCopySheet.Position         = UDim2.new(0.02, 0, 0.1, 0)
btnCopySheet.BackgroundColor3 = Color3.fromRGB(30, 45, 85)
btnCopySheet.Text             = "📋 Chép Sheet"
btnCopySheet.TextColor3       = Color3.fromRGB(190, 220, 255)
btnCopySheet.Font             = Enum.Font.GothamBold
btnCopySheet.TextSize         = 11
Instance.new("UICorner", btnCopySheet).CornerRadius = UDim.new(0, 6)

local btnAutoChat = Instance.new("TextButton", subActFrame)
btnAutoChat.Size             = UDim2.new(0.48, 0, 0.8, 0)
btnAutoChat.Position         = UDim2.new(0.50, 0, 0.1, 0)
btnAutoChat.BackgroundColor3 = Color3.fromRGB(45, 25, 75)
btnAutoChat.Text             = "💬 Gửi Lệnh >auto"
btnAutoChat.TextColor3       = Color3.fromRGB(220, 180, 255)
btnAutoChat.Font             = Enum.Font.GothamBold
btnAutoChat.TextSize         = 11
Instance.new("UICorner", btnAutoChat).CornerRadius = UDim.new(0, 6)

btnCopySheet.MouseButton1Click:Connect(function()
    copySheetToClipboard(Playback.CustomSheet)
    btnCopySheet.Text = "✅ Đã Chép!"
    task.delay(1.5, function() btnCopySheet.Text = "📋 Chép Sheet" end)
end)

btnAutoChat.MouseButton1Click:Connect(function()
    sendChatCommand(">auto " .. Playback.CustomSheet)
    btnAutoChat.Text = "✅ Đã Gửi!"
    task.delay(1.5, function() btnAutoChat.Text = "💬 Gửi Lệnh >auto" end)
end)

-- 5. ĐIỀU CHỈNH TỐC ĐỘ (BPM)
local bpmFrame = Instance.new("Frame", Scroll)
bpmFrame.Size             = UDim2.new(1, 0, 0, 36)
bpmFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
bpmFrame.LayoutOrder      = 5
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
    Config.BPM = math.min(180, Config.BPM + 10)
    bpmLabel.Text = "Tốc độ: " .. Config.BPM .. " BPM"
end)

-- 6. Ô NHẬP SHEET NHẠC TÙY Ý
local sheetTitle = Instance.new("TextLabel", Scroll)
sheetTitle.Size               = UDim2.new(1, 0, 0, 18)
sheetTitle.BackgroundTransparency = 1
sheetTitle.Text               = "📝 Bản Sheet Hiện Tại:"
sheetTitle.TextColor3         = Color3.fromRGB(170, 150, 210)
sheetTitle.Font               = Enum.Font.GothamSemibold
sheetTitle.TextSize           = 11
sheetTitle.TextXAlignment     = Enum.TextXAlignment.Left
sheetTitle.LayoutOrder        = 6

local sheetBox = Instance.new("TextBox", Scroll)
sheetBox.Size                 = UDim2.new(1, 0, 0, 70)
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
sheetBox.LayoutOrder          = 7
Instance.new("UICorner", sheetBox).CornerRadius = UDim.new(0, 8)
local sBox = Instance.new("UIStroke", sheetBox)
sBox.Color = Color3.fromRGB(70, 45, 130); sBox.Thickness = 1

sheetBox:GetPropertyChangedSignal("Text"):Connect(function()
    Playback.CustomSheet = sheetBox.Text
end)

-- 7. THANH TÌM KIẾM BÀI HÁT
local searchBox = Instance.new("TextBox", Scroll)
searchBox.Size                 = UDim2.new(1, 0, 0, 34)
searchBox.BackgroundColor3     = Color3.fromRGB(22, 20, 35)
searchBox.PlaceholderText      = "🔍 Tìm kiếm bài hát (gõ tên bài)..."
searchBox.PlaceholderColor3    = Color3.fromRGB(130, 120, 160)
searchBox.Text                 = ""
searchBox.TextColor3           = Color3.fromRGB(230, 220, 255)
searchBox.Font                 = Enum.Font.Gotham
searchBox.TextSize             = 11.5
searchBox.LayoutOrder          = 8
Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0, 8)
local sSearch = Instance.new("UIStroke", searchBox)
sSearch.Color = Color3.fromRGB(90, 50, 170); sSearch.Thickness = 1

local libTitle = Instance.new("TextLabel", Scroll)
libTitle.Size               = UDim2.new(1, 0, 0, 18)
libTitle.BackgroundTransparency = 1
libTitle.Text               = "🎵 Danh Sách Nhạc (Chạm Là Tự Động Đánh):"
libTitle.TextColor3         = Color3.fromRGB(170, 150, 210)
libTitle.Font               = Enum.Font.GothamSemibold
libTitle.TextSize           = 11
libTitle.TextXAlignment     = Enum.TextXAlignment.Left
libTitle.LayoutOrder        = 9

-- 8. TẠO DANH SÁCH BÀI HÁT
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
    sBtn.LayoutOrder      = 9 + idx
    Instance.new("UICorner", sBtn).CornerRadius = UDim.new(0, 6)

    sBtn.MouseButton1Click:Connect(function()
        Playback.CustomSheet = song.Sheet
        sheetBox.Text        = song.Sheet
        Config.BPM           = song.BPM
        bpmLabel.Text        = "Tốc độ: " .. Config.BPM .. " BPM"
        
        -- Tự động đánh qua phím cảm ứng màn hình
        startPlayingMusic(song.Sheet, song.BPM)
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

print("[VOSS] Visual Piano Hub 🎹 (Screen Touch Edition) Loaded!")
