-- ================================================
-- VOSS HUB | Universal Smart Loader 🚀
-- ================================================
-- Tự động nhận diện game bạn đang chơi để tải script phù hợp:
-- • Thợ Săn Hầm Ngục (Dungeon Hunters / Universe 8937254139) -> Tải Dungeon Hunters Hub
-- • Visual Pianos (Đàn piano hình ảnh 🎹) -> Tải Piano Autoplayer Hub
-- • Abyss Expedition (Thám hiểm vực sâu 🧗) -> Tải Abyss Immortality & Fly Hub
-- ================================================

local placeId = game.PlaceId
local gameId  = game.GameId
local baseUrl = "https://raw.githubusercontent.com/Dellyhihi/VOSS-Hub/main/"

print(string.format("[VOSS] Detecting Game... PlaceId: %s | GameId: %s", tostring(placeId), tostring(gameId)))

-- Tự động xếp hàng script chạy tiếp khi teleport qua map mới (World 1, World 2, Replay...)
local qot = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
if qot then
    pcall(function()
        qot([[loadstring(game:HttpGet("https://raw.githubusercontent.com/Dellyhihi/VOSS-Hub/main/loader.lua"))()]])
    end)
end

local gameName = ""
pcall(function()
    gameName = string.lower(game:GetService("MarketplaceService"):GetProductInfo(placeId).Name)
end)

-- 1. Game Thợ Săn Hầm Ngục (Dungeon Hunters by The Evac Syndicate)
-- Khớp UniverseId 8937254139 VÀ tất cả PlaceId của game (Sảnh chính, DH: Thế giới 1..5, Tháp, Vực sâu...)
if gameId == 8937254139
   or placeId == 120217704230083 -- Sảnh chính (Lobby)
   or placeId == 121902496311296 -- DH: Thế giới 1 (World 1)
   or placeId == 123911129955120 -- DH: Thế giới 2 (World 2)
   or placeId == 116991059923076 -- DH: Thế giới 3 (World 3)
   or placeId == 113880247399913 -- DH: Thế giới 4 (World 4)
   or placeId == 121731448247552 -- DH: Thế giới 5 (World 5)
   or string.find(gameName, "dungeon") 
   or string.find(gameName, "hầm ngục") 
   or string.find(gameName, "hunter") 
   or string.find(gameName, "dh:") then
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
