-- ================================================
-- VOSS | Visual Piano Hub 🎹 (Pro Musician Edition)
-- Game: Visual Pianos (PlaceId: 5593470048)
-- ================================================
-- [NÂNG CẤP ĐỈNH CAO]:
-- 1. BỘ TỰ ĐỘNG CHỈNH CAO ĐỘ (AUTO TRANSPOSE ENGINE):
--    - Tự động dịch chuyển nửa cung (Semitones -12 đến +12)
--    - Mỗi bài nhạc tự động chuyển về đúng tông chuẩn của bài hát
--    - Có nút [-1 Tông] và [+1 Tông] để tự do nâng hạ cao độ theo sở thích
-- 2. TỰ ĐỘNG ĐẠP BÀN ĐẠP NGÂN ÂM (AUTO SUSTAIN PEDAL):
--    - Giữ bàn đạp vang âm giúp giai điệu ngân nga, mượt mà, xóa bỏ tiếng cộc cằn
-- 3. KHO NHẠC SIÊU TO KHỔNG LỒ (20 BÀI FULL ĐIỆP KHÚC):
--    - Nhạc Trung Quốc Hot Douyin (Thời Không Sai Lệch, Đồng Thoại, Phi Điểu Và Ve Sầu,...)
--    - Nhạc Việt Nam 2024 - 2026 (Đừng Làm Trái Tim Anh Đau, Cắt Đôi Nỗi Sầu, Nơi Này Có Anh,...)
--    - Nhạc Quốc Tế Triệu View (APT., Die With A Smile, Golden Hour, Until I Found You,...)
-- 4. FIX TRIỆT ĐỂ LỖI NGỒI ĐÀN & TÌM KIẾM BÀI HÁT TỨC THÌ
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
-- BẢNG PHÍM VIRTUAL PIANO CHUẨN 61/88 PHÍM (CHROMATIC)
-- ================================================
local ChromaticKeys = {
    "1","!","2","@","3","4","$","5","%","6","^","7","8","*","9","(","0",
    "q","Q","w","W","e","E","r","R","t","T","y","Y","u","i","I","o","O","p","P",
    "a","A","s","S","d","D","f","g","G","h","H","j","J","k","K","l","L",
    "z","Z","x","c","C","v","V","b","B","n","N","m"
}

local ChromaticIndex = {}
for i, c in ipairs(ChromaticKeys) do
    ChromaticIndex[c] = i
end

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

-- Thuật toán dịch chuyển cao độ (Transpose)
local function transposeChar(c, semitones)
    if semitones == 0 then return c end
    local idx = ChromaticIndex[c]
    if not idx then return c end
    local newIdx = math.clamp(idx + semitones, 1, #ChromaticKeys)
    return ChromaticKeys[newIdx]
end

-- ================================================
-- KHO NHẠC SIÊU HOT HIT TREND 2024 - 2026 (20 BÀI FULL)
-- ================================================
local SongLibrary = {
    -- NHẠC TRUNG QUỐC / DOUYIN HOT
    {
        Name = "🇨🇳 Thời Không Sai Lệch (错位时空 - Cuo Wei Shi Kong)",
        BPM  = 92,
        Transpose = 0,
        Sheet = "[6e] 0 e r t [4q] 8 q w e [10] 5 0 w r [5w] 9 w e r | [6et] y u [4qe] r t [10w] e r [5wq] w e | [6e] 0 e [0t] [4q] 8 q [8r] [10] 5 0 [5e] [5w] 9 w [9w] | [6ep] [0e] [6ep] [0e] [4qa] [8q] [4qa] [8q] [10s] [5w] [10s] [5w] [5wa] [9w] [5wp] [9w] | [6ep] a s [4qa] s d [10s] a p [5wa] p o [6ep]"
    },
    {
        Name = "🇨🇳 Đồng Thoại (童话 - Tong Hua - Guang Liang)",
        BPM  = 78,
        Transpose = 0,
        Sheet = "[1o] 5 8 0 w 0 [5i] 2 5 7 9 7 [6u] 3 6 8 0 8 [3y] 7 0 w r w | [4t] 1 4 6 8 6 [1r] 5 8 0 w 0 [2e] 6 9 q e q [5w] 2 5 7 9 7 | [1o] 5 8 0 [5u] [5i] [6u] 3 6 8 [6y] [6t] [4t] 1 4 6 [4r] [4e] [5w] 2 5 7 9 | [1s] [5a] [8p] [0o] [5i] [2u] [5y] [7t] [1s]"
    },
    {
        Name = "🇨🇳 Phi Điểu Và Ve Sầu (飞鸟和蝉 - Fei Niao He Chan)",
        BPM  = 95,
        Transpose = 0,
        Sheet = "[1s] 5 8 0 w [5a] 2 5 7 9 [6p] 3 6 8 0 [3o] 7 0 w r | [4p] 1 4 6 8 [1o] 5 8 0 w [2i] 6 9 q e [5u] 2 5 7 9 | [1s] [5a] [8p] [0o] [5i] [2u] [5y] [7t] [6r] [3e] [6w] [8q] [30] | [4e] [6t] [8u] [5o] [7p] [9a] [1s]"
    },
    {
        Name = "🇨🇳 Tay Trái Chỉ Trăng (左手指月 - Zuo Shou Zhi Yue)",
        BPM  = 85,
        Transpose = -1,
        Sheet = "[6e] [0u] [6e] [0u] [30] [7w] [30] [7w] [4q] [8e] [4q] [8e] [10] [5w] [10] [5w] | [29] [6q] [29] [6q] [6e] [0u] [6e] [0u] [5w] [9r] [5w] [9r] [30] [7w] [30] [7w] | [6ep] a [0s] d [4qf] g [8h] j [10k] l [5j] h [5wf] d [9s] a [6ep]"
    },
    {
        Name = "🇨🇳 Yến Vô Hiết (燕无歇 - Yan Wu Xie)",
        BPM  = 110,
        Transpose = 0,
        Sheet = "[6ep] [0e] [6ep] [0e] [4qa] [8q] [4qa] [8q] [10s] [5w] [10s] [5w] [5wd] [9w] [5wd] [9w] | [6ef] [0e] [6ed] [0e] [4qs] [8q] [4qa] [8q] [10p] [5w] [10o] [5w] [5wp] [9w] [5wa] [9w] | [6ep] [0e] [6ep] [0e] [4qa] [8q] [4qa] [8q] [6ep]"
    },
    {
        Name = "🇨🇳 Mang Chủng (芒种 - Grain in Ear)",
        BPM  = 120,
        Transpose = 0,
        Sheet = "[6e] [0e] [6e] [0e] [4q] [8q] [4q] [8q] [10] [5w] [10] [5w] [5w] [9w] [5w] [9w] | [6eu] [0i] [6eo] [0p] [4qa] [8s] [4qd] [8f] [10g] [5f] [10d] [5s] [5wa] [9p] [5wo] [9i] | [6eu] [0e] [6eu] [0e] [4qi] [8q] [4qi] [8q] [6eu]"
    },

    -- NHẠC VIỆT NAM HOT TREND 2024 - 2026
    {
        Name = "🇻🇳 Đừng Làm Trái Tim Anh Đau - Sơn Tùng M-TP",
        BPM  = 105,
        Transpose = 0,
        Sheet = "[8u] o s [5w] o a [6e] u p [4q] i o [8u] o s [5w] o a [6e] u p [4q] i o | [8os] [os] [os] [5wa] [6ep] [ep] [4qa] [8os] [os] [os] [5wa] [6ep] [ep] [4qa] | [8u] [8o] [8s] [5w] [5o] [5a] [6e] [6u] [6p] [4q] [4i] [4o] | [8u] o s d f [5w] o a s d [6e] u p a s [4q] i o p a [8s] [0w] [5a] [9w] [6p] [0e] [4o] [8q] [8s]"
    },
    {
        Name = "🇻🇳 Cắt Đôi Nỗi Sầu - Tăng Duy Tân",
        BPM  = 110,
        Transpose = -2,
        Sheet = "[6e] [0u] [6e] [0u] [4q] [8t] [4q] [8t] [10] [5w] [10] [5w] [5w] [9r] [5w] [9r] | [6ep] [0e] [6ep] [0e] [4qa] [8q] [4qa] [8q] [10s] [5w] [10s] [5w] [5wa] [9w] [5wp] [9w] | [6ep] [6e] [6e] [0u] [4qa] [4q] [4q] [8t] [10s] [10] [10] [5w] [5wa] [5w] [5w] [9r] | [6ep] a s [4qa] s d [10s] a p [5wa] p o [6ep]"
    },
    {
        Name = "🇻🇳 Nơi Này Có Anh - Sơn Tùng M-TP",
        BPM  = 98,
        Transpose = 0,
        Sheet = "[4q] [8t] [4q] [8t] [5w] [9y] [5w] [9y] [30] [7r] [30] [7r] [6e] [0u] [6e] [0u] | [4qi] o p [5wo] p a [30u] i o [6ep] a s | [4qd] [8q] [4qd] [8q] [5ws] [9w] [5wa] [9w] [30p] [70] [30o] [70] [6ep] [0e] [6ea] [0e] | [4qs] [8q] [4qd] [8q] [5ws] [9w] [5wa] [9w] [10s] [5w] [10s]"
    },
    {
        Name = "🇻🇳 See Tình - Hoàng Thùy Linh",
        BPM  = 115,
        Transpose = 0,
        Sheet = "[4q] [4q] [4q] 8 [5w] [5w] [5w] 9 [6e] [6e] [6e] 0 [6e] [6e] [6e] | [4q] 8 [4q] 8 [5w] 9 [5w] 9 [6e] 0 [6e] 0 [6e] 0 | [4q] [4q] [4q] 8 [5w] [5w] [5w] 9 [6e] [6e] [6e] 0 | [4qi] p [5wo] a [6ep] s [6ed] [4qi] p [5wo] a [6ep] | [4q] 8 [5w] 9 [6e] 0 [6e]"
    },
    {
        Name = "🇻🇳 Waiting For You - MONO",
        BPM  = 108,
        Transpose = 0,
        Sheet = "[6e] [0u] [6e] [0u] [4q] [8t] [4q] [8t] [10] [5w] [10] [5w] [5w] [9r] [5w] [9r] | [6ep] [0e] [6ep] [0e] [4qa] [8q] [4qa] [8q] [10s] [5w] [10s] [5w] [5wa] [9w] [5wp] [9w] | [6eu] [0p] [6es] [0d] [4qf] [8d] [4qs] [8a] [10p] [5o] [10i] [5u] [6ep]"
    },
    {
        Name = "🇻🇳 Cô Nàng Áo Dài - Hot Trend VN",
        BPM  = 105,
        Transpose = 0,
        Sheet = "o p [6s] s d [6f] f g [6d] s [4p] p a [4s] s d [4a] p [1o] o p [1s] s d [1f] [5d] s a [5p] o [6s] s d [6f] f g [6d] s [4p] p a [4s] s d [4a] p [1s] d f [5g] f d [1s]"
    },

    -- NHẠC QUỐC TẾ HOT TREND 2024 - 2026
    {
        Name = "🌍 APT. - ROSÉ & Bruno Mars (Hot #1)",
        BPM  = 105,
        Transpose = 0,
        Sheet = "[8f] [0wf] [8f] f [8f] [0wd] [9f] [Qef] [9f] f [9f] [Qed] [0f] [wrf] [0f] f [0f] [wrd] [wf] [ry] [wd] f [wd] [ryf] | [8f] [0wf] [8f] f [8f] [0wd] [9f] [Qef] [9f] f [9f] [Qed] [0f] [wrf] [0f] f [0f] [wrd] [wf] [ry] [wd] f [wd] [ryf] | [8s] [0w] [8s] [8s] [8a] [9p] [Qe] [9p] [9p] [9o] [0p] [wr] [0p] [0p] [0a] [ws] [ry] [wd] [wf]"
    },
    {
        Name = "🌍 Die With A Smile - Lady Gaga & Bruno Mars",
        BPM  = 85,
        Transpose = 0,
        Sheet = "[8oa] r u o u r [8oa] r u [of] u r [qip] t u p u t [qip] t u p u t | [8oah] [rf] [uf] [pj] [uak] r j [qip] t u p u t | [8oa] r u o u r [8oa] r u [of] u r [qip] t u p u t [qip] t u p u t | [8f] [wh] [0j] [wh] [8f] [qd] [ti] [qd] [ti] [8f] [wh] [0j] [wh] [8f] [5d] [9y] [5d] [8s]"
    },
    {
        Name = "🌍 Golden Hour - JVKE",
        BPM  = 115,
        Transpose = 0,
        Sheet = "[158] w t y u [48q] e t y i [158] w t y u [59w] r y u o [158] w t y u [48q] e t y i [158] w t y u [59w] r y u o | [60e] t u p s [48q] e t y i [158] w t y u [59w] r y u o | [18] [5w] [8t] [0y] [wu] [4q] [8e] [qt] [8y] [ei] [18] [5w] [8t] [0y] [wu] [5w] [9r] [wy] [9u] [ro]"
    },
    {
        Name = "🌍 Until I Found You - Stephen Sanchez",
        BPM  = 80,
        Transpose = -2,
        Sheet = "[tf] f s o [ra] h f a o a [ti] s g s p [ts] [ts] [ts] [tg] [tg] [tg] [yh] [yh] [yh] [yd] [yd] [yd] | [tf] f s o [ra] h f a o a [ti] s g s p [ts] [ts] [ts] [tg] [tg] [tg] | [4qf] [8f] [qs] [8o] [5wa] [9h] [wf] [9a] [10s] [5g] [0s] [5p] [6es] [0s] [es] [0s]"
    },
    {
        Name = "🌍 Glimpse of Us - Joji",
        BPM  = 75,
        Transpose = 0,
        Sheet = "[6e] [0u] [6e] [0u] [4q] [8t] [4q] [8t] [10] [5w] [10] [5w] [5w] [9r] [5w] [9r] | [6e] u [0p] [6e] u [0p] [4q] t [8i] [4q] t [8i] [10] w [5u] [10] w [5u] [5w] r [9y] [5w] r [9y] | [6ep] [0e] [6ea] [0e] [4qs] [8q] [4qd] [8q] [10f] [5w] [10d] [5w] [5ws] [9w] [5wa] [9w] [6ep]"
    },
    {
        Name = "🌍 A Thousand Years - Christina Perri",
        BPM  = 90,
        Transpose = 0,
        Sheet = "[1u] [5o] [8s] [5o] [1u] [5o] [8s] [5o] [4i] [8p] [qd] [8p] [4i] [8p] [qd] [8p] | [1u] [5o] [8s] [5o] [5y] [9o] [wa] [9o] [6t] [0u] [ep] [0u] [4i] [8p] [qd] [8p] | [1u] o s [5y] o a [6t] u p [4r] y o [1u] o s [5y] o a [6t] u p"
    },
    {
        Name = "🎼 Canon in D - Pachelbel (Bản Giao Hưởng)",
        BPM  = 95,
        Transpose = 0,
        Sheet = "u o a d f [oa] h [os] h [yd] g [ya] g [tu] f [ts] f [re] d [ra] d [we] s [wo] s [qe] a [qp] a [0u] o [0y] o [8u] o a d f [oa] h [os] h [yd] g [ya] g [tu] f [ts] f [re] d [ra] d [we] s [wo] s [qe] a [qp] a [0u] o [0y] o | [18] [5w] [80] [5w] [60] [30] [68] [30] [48] [18] [46] [18] [5w] [2w] [57] [2w] [18]"
    },
    {
        Name = "🎼 Fur Elise - Beethoven (Bản Chuẩn Gốc)",
        BPM  = 130,
        Transpose = 0,
        Sheet = "e W e W e u y t r [0e] t u [60r] u O [60e] u e W e W e u y t r [0e] t u [60r] u O [60e] [0r] t y [8u] i o [7y] u i [6t] y u [5r] [0e] W e W e u y t r [0e] t u [60r] u O [60e] | [0e] u p a [0s] d f g [6a] p o i [6u] y t r [0e] W e W e"
    }
}

-- ================================================
-- TRẠNG THÁI & CẤU HÌNH
-- ================================================
local Config = {
    BPM         = SongLibrary[1].BPM,
    Transpose   = SongLibrary[1].Transpose, -- Độ cao (-12 đến +12)
    Sustain     = true,  -- Tự động giữ bàn đạp ngân âm Space
    Humanizer   = true,  -- Dao động micro-delay ±4ms
    Loop        = false,
    UseGameChat = false,
}

local Playback = {
    IsPlaying = false,
    IsPaused  = false,
    Thread    = nil,
    CurrentSong = SongLibrary[1].Name,
    CustomSheet = SongLibrary[1].Sheet,
}

-- ================================================
-- HÀM MÔ PHỎNG BẤM PHÍM PIANO (CHUẨN ÂM THANH)
-- ================================================
local function playSingleKey(char)
    local actualChar = transposeChar(char, Config.Transpose)
    local map = KeyMap[actualChar]
    if not map then return end

    local kc    = map.Code
    local shift = map.Shift

    pcall(function()
        if shift then
            VirtualInputMgr:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game)
            task.wait(0.003)
        end

        VirtualInputMgr:SendKeyEvent(true, kc, false, game)
        task.wait(0.035) -- Giữ phím đủ lâu để âm thanh vang lên đầy đủ
        VirtualInputMgr:SendKeyEvent(false, kc, false, game)

        if shift then
            task.wait(0.003)
            VirtualInputMgr:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, game)
        end
    end)
end

local function playChord(chordStr)
    local hasShift = false
    local keysToHit = {}

    for i = 1, #chordStr do
        local c = chordStr:sub(i, i)
        local actualChar = transposeChar(c, Config.Transpose)
        local m = KeyMap[actualChar]
        if m then
            table.insert(keysToHit, m.Code)
            if m.Shift then hasShift = true end
        end
    end

    if #keysToHit == 0 then return end

    pcall(function()
        if hasShift then
            VirtualInputMgr:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game)
            task.wait(0.003)
        end

        -- Nhấn lần lượt cách nhau 3ms để engine bắt đủ tất cả các nốt hợp âm
        for _, kc in ipairs(keysToHit) do
            VirtualInputMgr:SendKeyEvent(true, kc, false, game)
            task.wait(0.003)
        end
        task.wait(0.035)
        for _, kc in ipairs(keysToHit) do
            VirtualInputMgr:SendKeyEvent(false, kc, false, game)
        end

        if hasShift then
            task.wait(0.003)
            VirtualInputMgr:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, game)
        end
    end)
end

-- ================================================
-- BỘ GIẢI MÃ SHEET & PHÁT NHẠC
-- ================================================
local function stopMusic()
    Playback.IsPlaying = false
    Playback.IsPaused  = false
    if Playback.Thread then
        task.cancel(Playback.Thread)
        Playback.Thread = nil
    end
    -- Nhả bàn đạp ngân âm
    pcall(function()
        VirtualInputMgr:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
    end)
end

local function parseAndPlay(sheetText, bpm)
    stopMusic()
    Playback.IsPlaying = true
    Playback.IsPaused  = false

    Playback.Thread = task.spawn(function()
        -- Kích hoạt Bàn đạp ngân âm (Sustain Pedal Space)
        if Config.Sustain then
            pcall(function()
                VirtualInputMgr:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
            end)
        end

        repeat
            local i = 1
            local len = #sheetText
            local baseDelay = (60 / bpm) / 4

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
                        playChord(chordContent)
                        i = closeIdx + 1
                    else
                        i = i + 1
                    end
                    local d = baseDelay
                    if Config.Humanizer then d = d + (math.random(-4, 4) / 1000) end
                    task.wait(math.max(0.02, d))

                elseif char == " " then
                    local d = baseDelay * 1.6
                    if Config.Humanizer then d = d + (math.random(-4, 4) / 1000) end
                    task.wait(math.max(0.03, d))
                    i = i + 1

                elseif char == "|" then
                    task.wait(baseDelay * 2.8)
                    i = i + 1

                else
                    if KeyMap[char] or KeyMap[char:lower()] or KeyMap[char:upper()] then
                        playSingleKey(char)
                        local d = baseDelay
                        if Config.Humanizer then d = d + (math.random(-4, 4) / 1000) end
                        task.wait(math.max(0.02, d))
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

-- ================================================
-- FIX TRIỆT ĐỂ: TỰ ĐỘNG TÌM GHẾ & NGỒI VÀO ĐÀN
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
Main.Size             = UDim2.new(0, 310, 0, 570)
Main.Position         = UDim2.new(0, 20, 0.5, -285)
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

local Div1 = Instance.new("Frame", Main)
Div1.Size             = UDim2.new(0.88, 0, 0, 1)
Div1.Position         = UDim2.new(0.06, 0, 0, 52)
Div1.BackgroundColor3 = Color3.fromRGB(60, 40, 110)
Div1.BorderSizePixel  = 0

local Scroll = Instance.new("ScrollingFrame", Main)
Scroll.Size             = UDim2.new(0.92, 0, 0, 505)
Scroll.Position         = UDim2.new(0.04, 0, 0, 58)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel  = 0
Scroll.ScrollBarThickness = 3
Scroll.ScrollBarImageColor3 = Color3.fromRGB(120, 70, 230)
Scroll.CanvasSize       = UDim2.new(0, 0, 0, 1150)

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

-- 2. HỘP ĐIỀU KHIỂN PHÁT NHẠC
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

-- 3. BỘ CHỈNH CAO ĐỘ (TRANSPOSE)
local transFrame = Instance.new("Frame", Scroll)
transFrame.Size             = UDim2.new(1, 0, 0, 36)
transFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
transFrame.LayoutOrder      = 3
Instance.new("UICorner", transFrame).CornerRadius = UDim.new(0, 8)

local transLabel = Instance.new("TextLabel", transFrame)
transLabel.Size               = UDim2.new(0.55, 0, 1, 0)
transLabel.Position           = UDim2.new(0.04, 0, 0, 0)
transLabel.BackgroundTransparency = 1
transLabel.Text               = "Cao độ: " .. (Config.Transpose >= 0 and "+" or "") .. Config.Transpose .. " Tông"
transLabel.TextColor3         = Color3.fromRGB(210, 200, 230)
transLabel.Font               = Enum.Font.GothamSemibold
transLabel.TextSize           = 12
transLabel.TextXAlignment     = Enum.TextXAlignment.Left

local btnTransMinus = Instance.new("TextButton", transFrame)
btnTransMinus.Size             = UDim2.new(0, 34, 0, 26)
btnTransMinus.Position         = UDim2.new(0.65, 0, 0.5, -13)
btnTransMinus.BackgroundColor3 = Color3.fromRGB(35, 30, 55)
btnTransMinus.Text             = "-1"
btnTransMinus.TextColor3       = Color3.fromRGB(220, 200, 255)
btnTransMinus.Font             = Enum.Font.GothamBold
btnTransMinus.TextSize         = 11
Instance.new("UICorner", btnTransMinus).CornerRadius = UDim.new(0, 6)

local btnTransPlus = Instance.new("TextButton", transFrame)
btnTransPlus.Size              = UDim2.new(0, 34, 0, 26)
btnTransPlus.Position          = UDim2.new(0.82, 0, 0.5, -13)
btnTransPlus.BackgroundColor3  = Color3.fromRGB(50, 25, 110)
btnTransPlus.Text              = "+1"
btnTransPlus.TextColor3        = Color3.fromRGB(220, 200, 255)
btnTransPlus.Font              = Enum.Font.GothamBold
btnTransPlus.TextSize          = 11
Instance.new("UICorner", btnTransPlus).CornerRadius = UDim.new(0, 6)

btnTransMinus.MouseButton1Click:Connect(function()
    Config.Transpose = math.max(-12, Config.Transpose - 1)
    transLabel.Text = "Cao độ: " .. (Config.Transpose >= 0 and "+" or "") .. Config.Transpose .. " Tông"
end)
btnTransPlus.MouseButton1Click:Connect(function()
    Config.Transpose = math.min(12, Config.Transpose + 1)
    transLabel.Text = "Cao độ: " .. (Config.Transpose >= 0 and "+" or "") .. Config.Transpose .. " Tông"
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
    Config.BPM = math.min(260, Config.BPM + 10)
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
libTitle.Text               = "🎵 Danh Sách Nhạc Hot Trend (20 Bài Full):"
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
        Config.Transpose     = song.Transpose or 0
        bpmLabel.Text        = "Tốc độ: " .. Config.BPM .. " BPM"
        transLabel.Text      = "Cao độ: " .. (Config.Transpose >= 0 and "+" or "") .. Config.Transpose .. " Tông"
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

print("[VOSS] Visual Piano Hub 🎹 (Pro Musician Edition) Loaded!")
