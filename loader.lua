-- ================================================
-- VOSS HUB | Universal Smart Loader 🚀
-- ================================================
-- Tự động nhận diện game bạn đang chơi để tải script phù hợp:
-- • Thợ Săn Hầm Ngục (Dungeon Hunters ⚔️) -> Tải Dungeon Hunters Hub
-- • Visual Pianos (Đàn piano hình ảnh 🎹) -> Tải Piano Autoplayer Hub
-- • Abyss Expedition (Thám hiểm vực sâu 🧗) -> Tải Abyss Immortality & Fly Hub
-- ================================================

local placeId = game.PlaceId
local baseUrl = "https://raw.githubusercontent.com/Dellyhihi/VOSS-Hub/main/"

print("[VOSS] Detecting Game... PlaceId:", placeId)

local gameName = ""
pcall(function()
    gameName = string.lower(game:GetService("MarketplaceService"):GetProductInfo(placeId).Name)
end)

-- 1. Game Thợ Săn Hầm Ngục [UPD] (Dungeon Hunters by The Evac Syndicate)
if placeId == 120217704230083 
   or string.find(gameName, "dungeon") 
   or string.find(gameName, "hầm ngục") 
   or string.find(gameName, "hunter") then
    print("[VOSS] Game detected: Dungeon Hunters (Thợ Săn Hầm Ngục) ⚔️ -> Loading Dungeon Hub...")
    loadstring(game:HttpGet(baseUrl .. "dungeon.lua"))()

-- 2. Game Visual Pianos (Đàn piano hình ảnh)
elseif placeId == 5593470048 or string.find(gameName, "piano") then
    print("[VOSS] Game detected: Visual Pianos 🎹 -> Loading Piano Hub...")
    loadstring(game:HttpGet(baseUrl .. "piano.lua"))()

-- 3. Game Abyss Expedition (Thám hiểm vực sâu)
elseif placeId == 11528400088 or string.find(gameName, "abyss") then
    print("[VOSS] Game detected: Abyss Expedition 🧗 -> Loading Abyss Hub v17...")
    loadstring(game:HttpGet(baseUrl .. "abyss.lua"))()

-- 4. Mặc định / Dự phòng
else
    print("[VOSS] Game unrecognized, trying Dungeon Hub fallback...")
    local success, _ = pcall(function()
        loadstring(game:HttpGet(baseUrl .. "dungeon.lua"))()
    end)
    if not success then
        pcall(function()
            loadstring(game:HttpGet(baseUrl .. "piano.lua"))()
        end)
    end
end
