-- ================================================
-- VOSS HUB | Universal Smart Loader 🚀
-- ================================================
-- Tự động nhận diện game bạn đang chơi để tải script phù hợp:
-- • Visual Pianos (Đàn piano hình ảnh 🎹) -> Tải Piano Autoplayer Hub
-- • Abyss Expedition (Thám hiểm vực sâu 🧗) -> Tải Abyss Immortality & Fly Hub
-- ================================================

local placeId = game.PlaceId
local baseUrl = "https://raw.githubusercontent.com/Dellyhihi/VOSS-Hub/main/"

print("[VOSS] Detecting Game... PlaceId:", placeId)

-- 1. Game Visual Pianos (Đàn piano hình ảnh)
if placeId == 5593470048 or string.find(string.lower(game:GetService("MarketplaceService"):GetProductInfo(placeId).Name), "piano") then
    print("[VOSS] Game detected: Visual Pianos 🎹 -> Loading Piano Hub...")
    loadstring(game:HttpGet(baseUrl .. "piano.lua"))()

-- 2. Game Abyss Expedition (Thám hiểm vực sâu)
elseif placeId == 11528400088 or string.find(string.lower(game:GetService("MarketplaceService"):GetProductInfo(placeId).Name), "abyss") then
    print("[VOSS] Game detected: Abyss Expedition 🧗 -> Loading Abyss Hub v17...")
    loadstring(game:HttpGet(baseUrl .. "abyss.lua"))()

-- 3. Mặc định / Game khác: Tự động chạy Piano nếu không rõ
else
    print("[VOSS] Game unrecognized, checking context...")
    local success, _ = pcall(function()
        loadstring(game:HttpGet(baseUrl .. "piano.lua"))()
    end)
    if not success then
        loadstring(game:HttpGet(baseUrl .. "abyss.lua"))()
    end
end
