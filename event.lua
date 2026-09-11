
-- =========================================================================
-- THE RIFT EVENT SUBSYSTEM (STANDALONE MODULE)
-- Modularized from SAE Black UI New Method Upgrade
-- Compatible with Volt / Potassium / Standard Roblox Executors
-- =========================================================================

local ctx = ... or {}
local UI = ctx.UI or (getgenv and getgenv().__UI) or _G.__UI
local UIX = ctx.UIX or (getgenv and getgenv().__UIX) or _G.__UIX or {}
local ST = ctx.ST or (getgenv and getgenv().__STEALFIX) or _G.__STEALFIX or {}
local ui = ctx.ui or {}

local gg = getgenv and getgenv() or _G
local EPOCH = gg.__STEALFIX_EPOCH or 1
local function alive()
    if ctx.alive then return ctx.alive() end
    if UI and UI.isAlive then return UI.isAlive() end
    return true
end

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer or game:GetService("Players").LocalPlayer
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

local Theme = ctx.Theme or (UI and UI.Theme) or {
    Background    = Color3.fromRGB(11, 14, 20),
    Window        = Color3.fromRGB(11, 14, 20),
    TopBar        = Color3.fromRGB(13, 17, 24),
    Sidebar       = Color3.fromRGB(13, 17, 24),
    Card          = Color3.fromRGB(16, 20, 30),
    Control       = Color3.fromRGB(22, 28, 42),
    CardHover     = Color3.fromRGB(28, 36, 52),
    CardActive    = Color3.fromRGB(36, 46, 68),
    Border        = Color3.fromRGB(34, 44, 65),
    BorderLight   = Color3.fromRGB(120, 160, 210),
    Text          = Color3.fromRGB(255, 255, 255),
    SubText       = Color3.fromRGB(130, 150, 180),
    TextSecondary = Color3.fromRGB(145, 165, 192),
    TextDisabled  = Color3.fromRGB(75, 90, 115),
    Accent        = Color3.fromRGB(240, 248, 255),
    AccentDim     = Color3.fromRGB(26, 34, 50),
    AccentGlow    = Color3.fromRGB(170, 220, 255),
    Money         = Color3.fromRGB(160, 225, 255),
    Success       = Color3.fromRGB(52, 211, 153),
    Danger        = Color3.fromRGB(248, 113, 113),
    Warn          = Color3.fromRGB(255, 180, 50),
}
if Theme.Warn == nil then Theme.Warn = Color3.fromRGB(255, 180, 50) end

local Icons = ctx.Icons or (UI and UI.Icons) or {}
local FONT = ctx.FONT or (UI and UI.FONT) or Enum.Font.GothamMedium
local FONT_BOLD = ctx.FONT_BOLD or (UI and UI.FONT_BOLD) or Enum.Font.GothamBold

local showToast = ctx.showToast or (UI and UI.showToast) or function(msg) print("[Rift]", msg) end
local showCenterModalWarning = ctx.showCenterModalWarning or (UI and UI.showCenterModalWarning) or function(title, msg, onOk) if onOk then onOk() end end
local saveConfig = ctx.saveConfig or function() end

local makePage = (UI and UI.makePage)
local sectionLabel = (UI and UI.sectionLabel)
local textRow = (UI and UI.textRow)
local buttonRow = (UI and UI.buttonRow)
local toggleRow = (UI and UI.toggleRow)
local toggleDual = (UI and UI.toggleDual)
local sliderRow = (UI and UI.sliderRow)
local dropdownMulti = (UI and UI.dropdownMulti)
local dropdownSingle = (UI and UI.dropdownSingle)
local dualRow = (UI and UI.dualRow)
local new = (UI and UI.new) or function(t, p, c) local i = Instance.new(t); for k,v in pairs(p or {}) do i[k]=v end; for _,ch in ipairs(c or {}) do ch.Parent=i end; return i end
local corner = (UI and UI.corner) or function(r) return new("UICorner", { CornerRadius = UDim.new(0, r or 8) }) end
local stroke = (UI and UI.stroke) or function(c, t) return new("UIStroke", { Color = c, Thickness = t or 1 }) end
local PillLabel = (UI and UI.PillLabel)
local getCurrentCard = (UI and UI.getCurrentCard)
local ScreenGui = ctx.ScreenGui or (UI and UI.ScreenGui) or LP.PlayerGui:FindFirstChild("StealAnEggGui")

local function req(m)
    if not m then return nil end
    local ok, res = pcall(require, m)
    return ok and res or nil
end

local function child(parent, ...)
    local cur = parent
    for _, n in ipairs({ ... }) do
        if not cur then return nil end
        cur = cur:FindFirstChild(n)
    end
    return cur
end

local RemotesMod = ctx.RemotesMod or req(RS:FindFirstChild("Shared") and RS.Shared:FindFirstChild("Remotes"))
local SaveMod = ctx.SaveMod or req(RS:FindFirstChild("Shared") and RS.Shared:FindFirstChild("Save")) or req(child(RS:FindFirstChild("Data"), "Save"))
local EggStateMod = ctx.EggStateMod or req(RS:FindFirstChild("Client") and RS.Client:FindFirstChild("EggState"))
local EggCmds = ctx.EggCmds or {}
local AssetsDir = ctx.AssetsDir or req(RS:FindFirstChild("Data") and RS.Data:FindFirstChild("Assets"))
local RarityMod = ctx.RarityMod or req(RS:FindFirstChild("Data") and RS.Data:FindFirstChild("Rarity"))
local MutMod = ctx.MutMod or req(RS:FindFirstChild("Shared") and RS.Shared:FindFirstChild("Modules") and RS.Shared.Modules:FindFirstChild("Mutations"))
local STRIP = ctx.STRIP or CFrame.new(515.00, 74, -362.8)

local function hrp()
    if ctx.hrp then return ctx.hrp() end
    local c = LP.Character
    if not c then return nil end
    return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("RootPart") or c.PrimaryPart
end

local function itemsOf(arr)
    local t = {}
    for i, v in ipairs(arr or {}) do t[i] = { key = v, label = v } end
    return t
end

local WallMod = req(RS:FindFirstChild("Client") and RS.Client:FindFirstChild("AreaEggResetWall"))
local function wallSealed()
    if ctx.wallSealed then return ctx.wallSealed() end
    if not (WallMod and type(WallMod.IsSealed) == "function") then return false end
    local ok, s = pcall(WallMod.IsSealed)
    return ok and s == true
end

local function waitWallOpen(maxWait)
    if ctx.waitWallOpen then return ctx.waitWallOpen(maxWait) end
    if not wallSealed() then return true end
    local t0 = os.clock()
    while wallSealed() and (os.clock() - t0) < (maxWait or 15) do
        local sisa = math.max(0, math.ceil((maxWait or 15) - (os.clock() - t0)))
        ST.activity = ("area closed - waiting for gate open (%ds)"):format(sisa)
        task.wait(0.1)
    end
    if wallSealed() then return false end
    ST.activity = "gate open - be ready!"
    task.wait(0.55)
    return not wallSealed()
end

local statTiles = ctx.statTiles or (UI and UI.statTiles) or (UIX and UIX.statTiles)
if not statTiles then
    statTiles = function(page, order, defs)
        local target = page:IsA("ScrollingFrame") and (getCurrentCard and getCurrentCard(page, order) or page) or page
        local grid = new("Frame", { Parent = target, Size = UDim2.new(1, 0, 0, 0), LayoutOrder = order,
            AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 })
        new("UIGridLayout", { Parent = grid, CellSize = UDim2.new(0.5, -5, 0, 56), CellPadding = UDim2.new(0, 10, 0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder, FillDirectionMaxCells = 2, HorizontalAlignment = Enum.HorizontalAlignment.Left })
        local refs = {}
        for i, d in ipairs(defs) do
            local card = new("Frame", { Parent = grid, LayoutOrder = i, BackgroundColor3 = Color3.fromRGB(20, 26, 38),
                BackgroundTransparency = 0 }, { corner(10), stroke(Color3.fromRGB(40, 52, 75), 1) })
            new("TextLabel", { Parent = card, Size = UDim2.new(1, -20, 0, 14), Position = UDim2.new(0, 12, 0, 6),
                BackgroundTransparency = 1, Font = FONT_BOLD, Text = string.upper(d.label), TextColor3 = Color3.fromRGB(120, 145, 175), TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Left })
            local num = new("TextLabel", { Parent = card, Size = UDim2.new(1, -50, 0, 26), Position = UDim2.new(0, 12, 0, 22),
                BackgroundTransparency = 1, Font = FONT_BOLD, Text = "0", TextColor3 = d.color or Color3.fromRGB(255, 255, 255), TextSize = 22,
                TextXAlignment = Enum.TextXAlignment.Left })
            refs[d.key] = num
        end
        local obj = {}
        function obj:update(data)
            for k, lbl in pairs(refs) do
                if data[k] ~= nil then
                    lbl.Text = tostring(data[k])
                end
            end
        end
        return obj
    end
end

-- ==================== THE RIFT EVENT ====================
-- Sistem Trade-In (Sacrifice) otomatis, rotasi banner realtime, auto-reroll, & integrasi auto steal
local riftPage = (UI and UI.Pages and UI.Pages["The Rift Event"]) or (makePage and makePage("The Rift Event"))
    do
        local o = 0
        local function n() o = o + 1; return o end

        -- Remote Helper Safe Finder
        local function getRiftRemotes()
            local RemotesMod = req(RS:FindFirstChild("Shared") and RS.Shared:FindFirstChild("Remotes"))
            local net = RS:FindFirstChild("Packages") and RS.Packages:FindFirstChild("Networking")
            local r = {}
            r.AskState = (RemotesMod and RemotesMod.Rift and RemotesMod.Rift.AskState) or (net and net:FindFirstChild("RF/Rift/AskState"))
            r.AskTradeIn = (RemotesMod and RemotesMod.Rift and RemotesMod.Rift.AskTradeIn) or (net and net:FindFirstChild("RF/Rift/AskTradeIn"))
            r.AskFinishReveal = (RemotesMod and RemotesMod.Rift and RemotesMod.Rift.AskFinishReveal) or (net and net:FindFirstChild("RF/Rift/AskFinishReveal"))
            r.AskRefresh = (RemotesMod and RemotesMod.Rift and RemotesMod.Rift.AskRefresh) or (net and net:FindFirstChild("RF/Rift/AskRefresh"))
            r.BannerRotated = (RemotesMod and RemotesMod.Rift and RemotesMod.Rift.BannerRotated) or (net and net:FindFirstChild("RE/Rift/BannerRotated"))
            r.AskBuyShopItem = (RemotesMod and RemotesMod.BossMastery and RemotesMod.BossMastery.AskBuyShopItem) or (net and net:FindFirstChild("RF/BossMastery/AskBuyShopItem"))
            r.AskClaimMilestone = (RemotesMod and RemotesMod.BossMastery and RemotesMod.BossMastery.AskClaimMilestone) or (net and net:FindFirstChild("RF/BossMastery/AskClaimMilestone"))
            return r
        end

        UIX.riftState = nil
        UIX.riftLastFetch = 0
        UIX.riftFetching = false

        function UIX.fetchRiftState(force)
            local now = os.clock()
            if not force and UIX.riftState and (now - UIX.riftLastFetch < 4) then
                return UIX.riftState
            end
            if UIX.riftFetching then return UIX.riftState end
            UIX.riftFetching = true
            pcall(function()
                local rems = getRiftRemotes()
                if rems.AskState then
                    local res = rems.AskState:InvokeServer()
                    if type(res) == "table" then
                        UIX.riftState = res
                        UIX.riftLastFetch = os.clock()
                    end
                end
            end)
            UIX.riftFetching = false
            return UIX.riftState
        end

        -- ===== CAP: 1 TELUR PER PET RESEP (jangan keambil berkali-kali) =====
        -- Versi lama cuma cek "nama pet ada di Requirements?" -> SEMUA telur jenis itu
        -- diloloskan terus-terusan. Sekarang dibatasi JUMLAH: berhenti diprioritasin
        -- begitu yang kita pegang udah nyukupin resep.
        --
        -- Yang dihitung "udah dipegang":
        --   1) pet di Inventory (field `Category`) yang KEPAKAI buat trade-in —
        --      bukan equipped / locked / favorite / lagi fuse (mirror findPetsForRift).
        --   2) telur di EggInventory (field `AssetCategory`) yang bakal netas jadi pet itu.
        -- Telur masuk EggInventory begitu claim beres, jadi 1 telur keambil -> jenis itu
        -- langsung berhenti diprioritasin. Itu inti "cuma ambil 1 per pet".
        --
        -- Di-cache 1 detik: isRiftNeededPet dipanggil PER TELUR pas filter, sedangkan
        -- inventory bisa ratusan entri — tanpa cache ini jadi ribuan iterasi per scan.
        local riftHaveCache, riftHaveCacheAt = nil, 0
        local function riftHaveMap()
            local now = os.clock()
            if riftHaveCache and (now - riftHaveCacheAt) < 1.0 then return riftHaveCache end
            local map = {}
            local sd = SaveMod and SaveMod.Get and SaveMod.Get()
            if sd then
                -- Hitung SEMUA pet milik user di inventory (equipped, locked, dll tetep dihitung agar tidak colong duplikat)
                for _, pet in pairs(sd.Inventory or sd.PetInventory or {}) do
                    if type(pet) == "table" then
                        local cat = pet.Category or pet.AssetCategory or pet.Name or (pet.ItemData and pet.ItemData.Category)
                        if cat then
                            local k = tostring(cat):lower():match("^%s*(.-)%s*$")
                            map[k] = (map[k] or 0) + 1
                        end
                    end
                end
                -- Hitung SEMUA telur di EggInventory (telur yang belum menetas juga dihitung agar tidak nyolong lagi)
                for _, egg in pairs(sd.EggInventory or {}) do
                    if type(egg) == "table" then
                        local cat = egg.AssetCategory or egg.Category or (egg.ItemData and egg.ItemData.Category)
                        if cat then
                            local k = tostring(cat):lower():match("^%s*(.-)%s*$")
                            map[k] = (map[k] or 0) + 1
                        end
                    end
                end
            end
            riftHaveCache, riftHaveCacheAt = map, now
            return map
        end
        UIX.riftHaveMap = riftHaveMap

        -- Helper: normalisasi nama untuk matching resep Rift (lowercase, trim, strip suffix 'egg')
        local function normRiftName(s)
            if not s then return "" end
            local str = tostring(s):lower():match("^%s*(.-)%s*$") or ""
            return str:gsub("%s*egg$", "")
        end

        -- Cek apakah kategori/nama telur ini cocok dengan salah satu resep Rift aktif
        function UIX.isRiftRecipeEgg(catOrName)
            if not catOrName then return false end
            local st = UIX.riftState or (UIX.fetchRiftState and UIX.fetchRiftState(false))
            if not st or not st.Requirements or #st.Requirements == 0 then return false end
            local cStr = normRiftName(catOrName)
            if cStr == "" then return false end
            for _, req in ipairs(st.Requirements) do
                local rStr = normRiftName(req)
                if rStr ~= "" then
                    if cStr == rStr or cStr:find(rStr, 1, true) or rStr:find(cStr, 1, true) then
                        return true
                    end
                end
            end
            return false
        end

        -- return: butuh (dari resep, bisa >1 kalau namanya dobel), punya (pet + telur pending)
        function UIX.riftNeedInfo(petName)
            local st = UIX.riftState or UIX.fetchRiftState(false)
            local need = 0
            local pNorm = normRiftName(petName)
            for _, reqName in ipairs((st and st.Requirements) or {}) do
                local rNorm = normRiftName(reqName)
                if rNorm == pNorm or (pNorm ~= "" and rNorm ~= "" and (pNorm:find(rNorm, 1, true) or rNorm:find(pNorm, 1, true))) then
                    need = need + 1
                end
            end
            local haveMap = riftHaveMap()
            local pLower = tostring(petName or ""):lower():match("^%s*(.-)%s*$") or ""
            local have = haveMap[pLower] or haveMap[pNorm] or 0
            if have == 0 and pNorm ~= "" then
                for k, v in pairs(haveMap) do
                    local kNorm = normRiftName(k)
                    if kNorm == pNorm or kNorm:find(pNorm, 1, true) or pNorm:find(kNorm, 1, true) then
                        have = have + v
                    end
                end
            end
            return need, have
        end

        -- Daftar banner Rift yang tersedia
        function UIX.listRiftBanners()
            local list = { "Verdant", "Umbral", "Radiant" }
            local st = UIX.riftState
            if st and st.BannerOdds then
                for _, b in ipairs(st.BannerOdds) do
                    if b.Id and not table.find(list, b.Id) then
                        table.insert(list, b.Id)
                    end
                end
            end
            return list
        end

        -- Validasi apakah banner yang sedang aktif di Rift termasuk yang dipilih user
        function UIX.isRiftBannerAllowed()
            local st = UIX.riftState or (UIX.fetchRiftState and UIX.fetchRiftState(false))
            local currentBanner = st and st.BannerId
            if not currentBanner then return true end
            if not ST.riftBanners or next(ST.riftBanners) == nil then
                return true
            end
            return ST.riftBanners[currentBanner] == true
        end

        function UIX.listRiftShopItems()
            return {
                { key = "MutationConsumable", label = "Mutation Consumable (400)" },
                { key = "TreadmillBooster", label = "2x Treadmill Booster (200)" },
                { key = "SpeedBoost", label = "1.25x Speed (225)" },
                { key = "CashBooster", label = "2x Cash Booster (175)" },
            }
        end

        function UIX.buyRiftShopItem(itemId, silent)
            local rems = getRiftRemotes()
            if not rems.AskBuyShopItem then
                if not silent then showToast("Boss Shop remote not found!", 2) end
                return false
            end
            local ok, res, err = pcall(function()
                return rems.AskBuyShopItem:InvokeServer(itemId)
            end)
            if ok and res then
                if not silent then
                    local names = {
                        MutationConsumable = "Mutation Consumable",
                        TreadmillBooster = "2x Treadmill Booster",
                        SpeedBoost = "1.25x Speed",
                        CashBooster = "2x Cash Booster"
                    }
                    showToast("Purchased " .. (names[itemId] or itemId) .. "!", 2)
                end
                if UIX.updateRiftUI then pcall(UIX.updateRiftUI) end
                return true
            else
                if not silent then
                    showToast("Purchase failed: " .. tostring(err or res or "Insufficient tokens"), 2)
                end
                return false
            end
        end

        function UIX.claimAllBossMilestones(silent)
            local rems = getRiftRemotes()
            if not rems.AskClaimMilestone then return 0 end
            local sd = SaveMod and SaveMod.Get and SaveMod.Get()
            local bm = sd and sd.BossMastery
            if not bm then return 0 end
            local mastery = bm.Mastery or 0
            local claimed = bm.ClaimedMilestoneIds or {}
            local BossMasteryMod = req(RS:FindFirstChild("Data") and RS.Data:FindFirstChild("BossMastery"))
            local claimedCount = 0

            if BossMasteryMod and BossMasteryMod.Milestones then
                for _, m in ipairs(BossMasteryMod.Milestones) do
                    local reqKills = (BossMasteryMod.GetMilestoneKills and BossMasteryMod.GetMilestoneKills(m)) or m.Kills or 0
                    if reqKills <= mastery and not claimed[m.Id] then
                        local ok, res = pcall(function()
                            return rems.AskClaimMilestone:InvokeServer(m.Id)
                        end)
                        if ok and res then
                            claimedCount = claimedCount + 1
                            task.wait(0.2)
                        end
                    end
                end
            end

            if BossMasteryMod and BossMasteryMod.ClaimableInfiniteCount then
                local infCount = BossMasteryMod.ClaimableInfiniteCount(bm) or 0
                while infCount > 0 do
                    local ok, res = pcall(function()
                        return rems.AskClaimMilestone:InvokeServer(BossMasteryMod.InfiniteMilestoneId or "Infinite")
                    end)
                    if ok and res then
                        claimedCount = claimedCount + 1
                        infCount = infCount - 1
                        task.wait(0.2)
                    else
                        break
                    end
                end
            end

            if claimedCount > 0 and not silent then
                showToast("Claimed " .. claimedCount .. " Boss Milestone(s)!", 2.5)
                if UIX.updateRiftUI then pcall(UIX.updateRiftUI) end
            elseif not silent and claimedCount == 0 then
                showToast("No unclaimed Boss Milestones available.", 2)
            end
            return claimedCount
        end

        function UIX.placeRiftEggsToPen(silent)
            local st = UIX.riftState or (UIX.fetchRiftState and UIX.fetchRiftState(false))
            if not st or not st.Requirements or #st.Requirements == 0 then
                if not silent then showToast("Cannot read Rift recipe!") end
                return 0
            end

            local sd = SaveMod and SaveMod.Get and SaveMod.Get()
            if not (sd and sd.EggInventory) then
                if not silent then showToast("Egg inventory empty!") end
                return 0
            end

            local unplaced = {}
            for uid, egg in pairs(sd.EggInventory) do
                if egg.Placement == nil then
                    local cat = egg.AssetCategory or egg.Category or (egg.ItemData and egg.ItemData.Category)
                    if cat and UIX.isRiftRecipeEgg and UIX.isRiftRecipeEgg(cat) then
                        unplaced[#unplaced + 1] = uid
                    end
                end
            end

            if #unplaced == 0 then
                if not silent then showToast("No unplaced Rift eggs in inventory!") end
                return 0
            end

            if not silent then
                showToast(string.format("Placing %d Rift egg(s) to pen...", #unplaced), 3)
            end

            task.spawn(function()
                if UIX.doAutoPlace then
                    UIX.doAutoPlace(true, nil, not silent, "rift")
                elseif doAutoPlace then
                    doAutoPlace(true, nil, not silent, "rift")
                end
                if not silent then
                    task.wait(0.5)
                    if UIX.updateRiftUI then UIX.updateRiftUI() end
                    showToast("Rift eggs planted in Pen! Incubating now.", 3)
                end
            end)
            return #unplaced
        end

        function UIX.isRiftNeededPet(petName)
            if not ST.riftPrioritizeSteal then return false end
            local need, have = UIX.riftNeedInfo(petName)
            if need <= 0 then return false end
            return have < need
        end

        -- Cari 3 pet di inventory yang cocok dengan resep (eksklusif pet unequipped & unlocked)
        function UIX.findPetsForRift(requirements)
            if not requirements or #requirements < 3 then return nil, {} end
            local sd = SaveMod and SaveMod.Get and SaveMod.Get()
            local inv = sd and (sd.Inventory or sd.PetInventory)
            if not inv then return nil, {} end

            local counts = {}
            for _, r in ipairs(requirements) do counts[r] = 0 end

            local available = {}
            for uid, pet in pairs(inv) do
                local cat = pet.AssetCategory or pet.Category or pet.Name or (pet.ItemData and pet.ItemData.Category)
                if cat and counts[cat] ~= nil then
                    counts[cat] = counts[cat] + 1
                    local isEquipped = (pet.Equipped == true)
                    local isLocked = (pet.Locked == true or pet.Favorite == true)
                    if not isEquipped and not isLocked then
                        available[cat] = available[cat] or {}
                        table.insert(available[cat], tostring(uid))
                    end
                end
            end

            local uids = {}
            local used = {}
            for i = 1, 3 do
                local targetName = requirements[i]
                local list = available[targetName]
                local chosenUid = nil
                if list then
                    for _, uid in ipairs(list) do
                        if not used[uid] then
                            chosenUid = uid
                            used[uid] = true
                            break
                        end
                    end
                end
                if not chosenUid then
                    return nil, counts
                end
                table.insert(uids, chosenUid)
            end

            return uids, counts
        end

        function UIX.doRiftTradeIn(silent)
            local st = UIX.fetchRiftState(true)
            if not st or not st.Requirements then
                if not silent then showToast("Failed to connect to Rift Server!") end
                return false
            end

            local uids, counts = UIX.findPetsForRift(st.Requirements)
            if not uids or #uids < 3 then
                if not silent then
                    local missing = {}
                    for _, rName in ipairs(st.Requirements) do
                        local cnt = counts[rName] or 0
                        if cnt == 0 then table.insert(missing, rName) end
                    end
                    showToast("Missing Rift pets: " .. (#missing > 0 and table.concat(missing, ", ") or "Need 3 pets!"), 3)
                end
                return false
            end

            local rems = getRiftRemotes()
            if not rems.AskTradeIn then
                if not silent then showToast("Trade-In remote not found!") end
                return false
            end

            local ok, res = pcall(function()
                return rems.AskTradeIn:InvokeServer(uids)
            end)

            if ok then
                -- Instant fast reveal bypass
                pcall(function()
                    if rems.AskFinishReveal then
                        rems.AskFinishReveal:InvokeServer()
                    end
                end)

                ST.riftTrades = (ST.riftTrades or 0) + 1
                if ui.riftStats and ui.riftStats.update then ui.riftStats.update() end
                showToast("Rift Sacrifice Success! Claimed Rift Egg.", 3)
                UIX.fetchRiftState(true)
                return true
            else
                if not silent then showToast("Sacrifice failed: " .. tostring(res), 3) end
                return false
            end
        end

        function UIX.doRiftReroll(silent)
            local st = UIX.fetchRiftState(false)
            local freeRem = st and (st.FreeRefreshesRemaining or 0) or 0
            if freeRem <= 0 then
                if not silent then showToast("No free rerolls left today!") end
                return false
            end

            local rems = getRiftRemotes()
            if not rems.AskRefresh then
                if not silent then showToast("Refresh remote not found!") end
                return false
            end

            local ok, res = pcall(function()
                return rems.AskRefresh:InvokeServer()
            end)

            if ok then
                UIX.fetchRiftState(true)
                showToast("Rift Recipe Rerolled!", 2)
                return true
            else
                if not silent then showToast("Reroll failed: " .. tostring(res)) end
                return false
            end
        end

        function UIX.teleportToRift()
            local r = hrp()
            if r then
                r.CFrame = CFrame.new(533.4, 70, -330) * CFrame.Angles(0, math.rad(180), 0)
                showToast("Teleported to The Rift Machine!")
            else
                showToast("Character not found!")
            end
        end

        UIX.bossSnapshot = nil
        UIX.bossLastFetch = 0
        UIX.batTraceSeq = 0
        local _bossMoveToken = 0
        function UIX.cancelBossMove()
            _bossMoveToken = _bossMoveToken + 1
        end

        function UIX.fetchBossSnapshot(force)
            local now = os.clock()
            if not force and UIX.bossSnapshot and (now - UIX.bossLastFetch) < 1.0 then
                return UIX.bossSnapshot
            end
            local RemotesMod = req(RS:FindFirstChild("Shared") and RS.Shared:FindFirstChild("Remotes"))
            local askSnap = (RemotesMod and RemotesMod.BossEvent and RemotesMod.BossEvent.AskSnapshot)
                or (RemotesMod and RemotesMod.AbyssOverlord and RemotesMod.AbyssOverlord.AskBossSnapshot)
            if not askSnap then
                local net = RS:FindFirstChild("Packages") and RS.Packages:FindFirstChild("Networking")
                askSnap = net and (net:FindFirstChild("RF/BossEvent/AskSnapshot") or net:FindFirstChild("RF/AbyssOverlord/AskBossSnapshot"))
            end
            if askSnap then
                local ok, snap = pcall(function() return askSnap:InvokeServer() end)
                if ok and type(snap) == "table" then
                    UIX.bossSnapshot = snap
                    UIX.bossLastFetch = now
                    return snap
                end
            end
            return UIX.bossSnapshot
        end

        -- ==================== BOSS SKILL HITBOX & PARTICLE NEUTRALIZER ====================
        -- Menghapus partikel hit (ParticleEmitter/Beam/Trail/Highlight) dan mematikan Hitbox dari semua skill Rift Boss
        -- (BossBlackHole, BossHazards, BossSlam, rotating beams, expanding rings, thrown projectiles)
        local function cleanBossSkillInstance(inst)
            if not inst then return end
            -- 1. Hapus / Matikan Hitbox dan Collision
            if inst:IsA("BasePart") then
                local name = inst.Name:lower()
                -- Jangan sentuh Floor, Crystal, PlayerSpawn, BossShopStand, atau part arena penting
                if not (name:find("floor") or name:find("crystal") or name:find("playerspawn") or name:find("bossspawn") or name:find("stand") or name:find("leave") or name:find("portal") or name:find("map")) then
                    pcall(function()
                        inst.CanTouch = false
                        inst.CanCollide = false
                        inst.CanQuery = false
                    end)
                    -- Jika ini hazard, black hole, ring, beam, slam, atau projectile, netralkan hitbox total
                    if name:find("hazard") or name:find("blackhole") or name:find("ring") or name:find("beam") or name:find("slam") or name:find("rock") or name:find("projectile") then
                        pcall(function()
                            inst.Transparency = 1
                            inst.Size = Vector3.zero
                            local ti = inst:FindFirstChildOfClass("TouchTransmitter")
                            if ti then ti:Destroy() end
                        end)
                    end
                end
            end

            -- 2. Hapus / Matikan Semua Partikel Hit & Visual Effects
            if inst:IsA("ParticleEmitter") then
                pcall(function()
                    inst.Enabled = false
                    inst.Rate = 0
                    inst:Destroy()
                end)
            elseif inst:IsA("Beam") or inst:IsA("Trail") or inst:IsA("Highlight") or inst:IsA("Smoke") or inst:IsA("Fire") or inst:IsA("Sparkles") then
                pcall(function()
                    inst.Enabled = false
                    inst:Destroy()
                end)
            end
        end

        local function cleanBossArenaHazards()
            local ba = Workspace:FindFirstChild("BossArena")
            if not ba then return end

            -- Clean BossHazards folder
            local hazards = ba:FindFirstChild("BossHazards")
            if hazards then
                for _, h in ipairs(hazards:GetDescendants()) do
                    cleanBossSkillInstance(h)
                end
            end

            -- Clean BossBlackHole di arena / workspace
            local bh = ba:FindFirstChild("BossBlackHole") or Workspace:FindFirstChild("BossBlackHole")
            if bh then
                for _, d in ipairs(bh:GetDescendants()) do
                    cleanBossSkillInstance(d)
                end
                cleanBossSkillInstance(bh)
            end

            -- Clean particles dan skill objects di BossArena
            for _, c in ipairs(ba:GetChildren()) do
                local n = c.Name:lower()
                if n:find("hazard") or n:find("blackhole") or n:find("vfx") or n:find("slam") or n:find("projectile") then
                    for _, d in ipairs(c:GetDescendants()) do
                        cleanBossSkillInstance(d)
                    end
                    cleanBossSkillInstance(c)
                end
            end
        end

        -- Background Auto-Neutralizer & Real-time DescendantAdded listener
        task.spawn(function()
            local baConn, hazardConn
                -- [DIHAPUS] hookmetamethod(game,"__namecall") buat drop HazardHit/BlackHoleHit.
                -- Ini hook metamethod GLOBAL: tiap namecall di seluruh client lewat closure kita.
                -- Permukaan deteksi paling gede di file ini dan persis pola pemicu BAC-4333.
                -- Konsekuensi yang diterima: damage hazard/blackhole boss sekarang KEBACA server.
                -- Mitigasi tetap jalan lewat cleanBossSkillInstance + DescendantAdded di bawah,
                -- yang cuma mindahin/ngilangin instance skill secara lokal (nol hook).

            while EPOCH == gg.__STEALFIX_EPOCH do
                local ba = Workspace:FindFirstChild("BossArena")
                if ba then
                    if not baConn then
                        baConn = ba.DescendantAdded:Connect(function(d)
                            cleanBossSkillInstance(d)
                        end)
                    end
                    local hazards = ba:FindFirstChild("BossHazards")
                    if hazards and not hazardConn then
                        hazardConn = hazards.ChildAdded:Connect(function(c)
                            cleanBossSkillInstance(c)
                            for _, d in ipairs(c:GetDescendants()) do
                                cleanBossSkillInstance(d)
                            end
                        end)
                    end
                    cleanBossArenaHazards()
                end
                task.wait(0.15)
            end
            if baConn then baConn:Disconnect() end
            if hazardConn then hazardConn:Disconnect() end
        end)

        function UIX.isInBossArena()
            if LP:GetAttribute("InBossArena") == true then return true end
            local r = hrp()
            if not r then return false end
            local ba = Workspace:FindFirstChild("BossArena")
            if ba and r:IsDescendantOf(ba) then return true end
            return (r.Position - Vector3.new(-14905, 98, -223)).Magnitude < 2500
        end

        -- [ADAPTIVE ANTI-FALLBACK GLIDE ENGINE]
        -- Dirancang khusus agar low-device (15 - 30 FPS) tidak terkena server rollback/fallback!
        -- 1. Step Distance Capping: perpindahan per frame dibatasi maks 9.5 studs (threshold server ~12).
        -- 2. Adaptive FPS Governor: otomatis menyesuaikan cruise speed secara dinamis dengan FPS riil device.
        -- 3. Server Rollback Detection & Self-Healing: jika server menarik posisi, otomatis reset CFrame & stabilize.
        -- 4. Velocity & State Clamping: mencegah gravitasi & Humanoid state machine bentrok dengan lerp.
        function UIX.bossGlideTo(targetCFrame, speedOverride, isCancelledFn)
            local char = LP.Character
            local h = hrp()
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if not h then return false end
            if isCancelledFn and isCancelledFn() then return true end

            _bossMoveToken = _bossMoveToken + 1
            local myToken = _bossMoveToken
            local startCF = h.CFrame
            local total = (targetCFrame.Position - startCF.Position).Magnitude
            if total < 0.2 then
                h.CFrame = targetCFrame
                h.AssemblyLinearVelocity = Vector3.zero
                h.AssemblyAngularVelocity = Vector3.zero
                return true
            end

            -- Base speed: dari speedOverride, ST.bossGlideSpeed, atau default 350
            local baseCruise = (speedOverride and speedOverride > 0) and speedOverride 
                or (tonumber(ST.bossGlideSpeed) or 350)

            -- [SPOOF PRIMING]: Pasang hover pad & acquire spoof sebelum frame pertama
            local SPh = (gg and gg.__SF_SPOOF) or (getgenv and getgenv().__SF_SPOOF)
            if SPh then
                SPh.keepPad(0.75, baseCruise)
                if hum then SPh.acquire(hum, h, baseCruise) end
            end

            local travelled = 0
            local lastWrittenPos = h.Position
            local RunS = game:GetService("RunService")

            while travelled < total do
                if _bossMoveToken ~= myToken then return false end
                if isCancelledFn and isCancelledFn() then return false end
                if not (alive and alive()) then return false end
                local dt = RunS.Heartbeat:Wait()
                if _bossMoveToken ~= myToken then return false end
                if not (alive and alive()) or not h.Parent then return false end

                -- Deteksi Server Rollback (Fallback): jika server menarik karakter mundur > 25 stud
                if (h.Position - lastWrittenPos).Magnitude > 25 then
                    startCF = h.CFrame
                    travelled = 0
                    total = (targetCFrame.Position - startCF.Position).Magnitude
                    lastWrittenPos = h.Position
                    h.AssemblyLinearVelocity = Vector3.zero
                    h.AssemblyAngularVelocity = Vector3.zero
                    if SPh then
                        SPh.keepPad(0.75, baseCruise)
                        SPh.syncPad(h.Position)
                        if hum then SPh.acquire(hum, h, baseCruise) end
                    end
                    if total < 0.5 then break end
                    task.wait(0.03)
                end

                -- Langkah per frame = speed * dt apa adanya (gaya Zeroin / Kalibrasi Glide),
                -- plafon 250 stud per frame untuk kasus lag spike/freeze
                local stepDist = math.min(total - travelled, math.min(baseCruise * dt, 250))
                travelled = math.min(total, travelled + stepDist)
                local progress = total > 0 and (travelled / total) or 1
                local baseCF = startCF:Lerp(targetCFrame, progress)

                -- Parabolic Obstacle Clearance Arc (Anti Tembus Batu & Karang):
                local arcY = 0
                if total > 8 then
                    local maxArc = math.clamp(total * 0.16, 3, 11)
                    arcY = math.sin(progress * math.pi) * maxArc
                end

                -- Forward Raycast Obstacle Detection:
                if total > 5 and progress < 0.92 then
                    local moveDir = (targetCFrame.Position - startCF.Position).Unit
                    local rayParams = RaycastParams.new()
                    rayParams.FilterType = Enum.RaycastFilterType.Exclude
                    local ignoreList = { char }
                    local arena = Workspace:FindFirstChild("BossArena")
                    if arena then
                        local boss = arena:FindFirstChild("Boss")
                        if boss then table.insert(ignoreList, boss) end
                        local floor = arena:FindFirstChild("Floor")
                        if floor then table.insert(ignoreList, floor) end
                    end
                    rayParams.FilterDescendantsInstances = ignoreList

                    local hit = Workspace:Raycast(h.Position, moveDir * 8, rayParams)
                    if hit and hit.Instance and hit.Instance.CanCollide then
                        local topY = hit.Position.Y + (hit.Instance.Size.Y * 0.5) + 3.5
                        if topY > (baseCF.Y + arcY) then
                            arcY = topY - baseCF.Y
                        end
                    end
                end

                local curPos = baseCF.Position + Vector3.new(0, arcY, 0)
                local nextCF = CFrame.new(curPos, curPos + baseCF.LookVector)

                if not (alive and alive()) or not h.Parent then return false end
                h.CFrame = nextCF
                lastWrittenPos = nextCF.Position
                h.AssemblyLinearVelocity = Vector3.zero
                h.AssemblyAngularVelocity = Vector3.zero

                -- [SYNC ZEROIN ANTI-CHEAT SPOOF]:
                -- Update pad posisi & sinkronkan velocity nol agar SupportRaycast tidak pernah rollback
                if SPh then
                    SPh.keepPad(0.75, baseCruise)
                    SPh.syncPad(nextCF.Position)
                    if hum and not SPh.refresh(hum, h, baseCruise, Vector3.zero) then
                        SPh.acquire(hum, h, baseCruise)
                    end
                end

                if hum and hum.Health > 0 and hum.PlatformStand then
                    hum.PlatformStand = false
                end
            end

            h.AssemblyLinearVelocity = Vector3.zero
            h.AssemblyAngularVelocity = Vector3.zero
            return true
        end

        -- ==================== BOSS RIFT SUBSYSTEM ====================
        local _batSwingSeq = 0

        local function getBatTool()
            local c = LP.Character
            if not c then return nil end
            for _, t in ipairs(c:GetChildren()) do
                if t:IsA("Tool") and string.find(string.lower(t.Name), "bat") then
                    return t
                end
            end
            local bp = LP:FindFirstChild("Backpack")
            if bp then
                for _, t in ipairs(bp:GetChildren()) do
                    if t:IsA("Tool") and string.find(string.lower(t.Name), "bat") then
                        local hum = c:FindFirstChildOfClass("Humanoid")
                        if hum then
                            hum:EquipTool(t)
                            task.wait(0.1)
                        end
                        return t
                    end
                end
            end
            pcall(function()
                local RF = RS:FindFirstChild("Packages")
                local Net = RF and RF:FindFirstChild("Networking")
                local RFNode = Net and Net:FindFirstChild("RF")
                local Codex = RFNode and RFNode:FindFirstChild("Codex")
                local WearBat = Codex and Codex:FindFirstChild("AskWearFieldBat")
                if WearBat then WearBat:InvokeServer() end
            end)
            return c:FindFirstChildOfClass("Tool")
        end

        -- [AUTO BOSS RIFT: ENTER] Tweens directly to BossArenaTeleport and enters
        function UIX.enterBossArena(silent)
            local c = LP.Character
            local h = hrp()
            local hum = c and c:FindFirstChildOfClass("Humanoid")
            if not c or not h or not hum then return false end

            -- USER REQUIREMENT: Kalau portal baru muncul, nunggu wall putih down!
            if wallSealed and wallSealed() then
                ST.activity = "boss: waiting for white wall to drop"
                local opened = waitWallOpen(15)
                if not opened or (wallSealed and wallSealed()) then
                    return false
                end
            end

            local bat = Workspace:FindFirstChild("BossArenaTeleport")
            if not bat then
                if not silent then showToast("Boss portal not open yet", 2) end
                return false
            end

            local hb = bat:FindFirstChild("Hitbox") or bat:FindFirstChildWhichIsA("BasePart", true)
            local targetCF = hb and hb.CFrame or bat:GetPivot()
            if not targetCF then return false end

            -- PURE GLIDE: no raw teleport! (Adaptive Anti-Fallback)
            if (h.Position - targetCF.Position).Magnitude > 6 then
                UIX.bossGlideTo(targetCF, ST.bossGlideSpeed or 350, function()
                    return not ST.autoBossRift
                end)
            end

            if h and h.Parent then
                h.CFrame = targetCF
                h.AssemblyLinearVelocity = Vector3.zero
                if hb then
                    pcall(function()
                        hb.CanTouch = true
                        h.CanTouch = true
                        firetouchinterest(h, hb, 0)
                        task.wait(0.05)
                        firetouchinterest(h, hb, 1)
                    end)
                end
                pcall(function()
                    local Rem = req(RS:FindFirstChild("Shared") and RS.Shared:FindFirstChild("Remotes"))
                    if Rem and Rem.BossEvent and Rem.BossEvent.AskEnter then
                        Rem.BossEvent.AskEnter:InvokeServer()
                    end
                end)
                local t0 = os.clock()
                while os.clock() - t0 < 3 do
                    if LP:GetAttribute("InBossArena") == true or (UIX.isInBossArena and UIX.isInBossArena()) then
                        if not silent then showToast("Entered Boss Arena!", 2) end
                        return true
                    end
                    task.wait(0.1)
                end
            end
            if not silent then showToast("Failed to enter arena via portal", 2) end
            return false
        end

        -- [BOSS EXIT PORTAL RESOLVER] Menemukan portal keluar dengan scanning komprehensif
        function UIX.findBossExitPortal()
            local arena = Workspace:FindFirstChild("BossArena")
            -- 1. Direct names inside arena or Workspace
            local candidates = {
                arena and arena:FindFirstChild("BossArenaLeaveTeleport"),
                Workspace:FindFirstChild("BossArenaLeaveTeleport"),
                arena and arena:FindFirstChild("LeaveTeleport", true),
                arena and arena:FindFirstChild("ReturnToLobby", true),
                arena and arena:FindFirstChild("LobbyTeleport", true),
                arena and arena:FindFirstChild("Portal", true),
                arena and arena:FindFirstChild("VoidPortal", true),
                arena and arena:FindFirstChild("Exit", true),
                arena and arena:FindFirstChild("BossArenaTeleport")
            }
            for _, c in ipairs(candidates) do
                if c and (c:IsA("Model") or c:IsA("BasePart") or c:IsA("Folder")) then
                    return c
                end
            end

            -- 2. Search SurfaceGui / BillboardGui text for "LOBBY", "RETURN", "EXIT" inside arena
            if arena then
                for _, g in ipairs(arena:GetDescendants()) do
                    if g:IsA("TextLabel") or g:IsA("TextButton") then
                        local txt = string.upper(g.Text or "")
                        if string.find(txt, "LOBBY") or string.find(txt, "RETURN") or string.find(txt, "EXIT") then
                            local anc = g:FindFirstAncestorWhichIsA("Model") or g:FindFirstAncestorWhichIsA("BasePart")
                            if anc and anc ~= arena then return anc end
                        end
                    end
                end
            end

            -- 3. Search models/folders in arena whose name matches portal keywords
            if arena then
                for _, child in ipairs(arena:GetChildren()) do
                    local n = string.lower(child.Name)
                    if not string.find(n, "crystal") and not string.find(n, "hazard") and not string.find(n, "boss") and child.Name ~= "Floor" then
                        if string.find(n, "leave") or string.find(n, "portal") or string.find(n, "exit") or string.find(n, "lobby") or string.find(n, "teleport") then
                            return child
                        end
                    end
                end
            end

            -- 4. Search Workspace for any portal model located near the boss arena coords
            for _, child in ipairs(Workspace:GetChildren()) do
                if child:IsA("Model") then
                    local n = string.lower(child.Name)
                    if string.find(n, "portal") or string.find(n, "teleport") or string.find(n, "leave") or string.find(n, "exit") then
                        local piv = child:GetPivot()
                        if piv and (piv.Position - Vector3.new(-14905, 98, -223)).Magnitude < 2500 then
                            return child
                        end
                    end
                end
            end

            -- 5. Search for any part in arena that has a TouchTransmitter or ProximityPrompt
            if arena then
                for _, part in ipairs(arena:GetDescendants()) do
                    if part:IsA("BasePart") and part.Name ~= "Floor" and not part:FindFirstAncestor("Boss") and not part:FindFirstAncestor("CrystalTowers") then
                        if part:FindFirstChildWhichIsA("TouchTransmitter") or part:FindFirstChildWhichIsA("ProximityPrompt") then
                            return part:FindFirstAncestorWhichIsA("Model") or part
                        end
                    end
                end
            end

            return nil
        end

        -- [AUTO RETURN TO SAFE ZONE AFTER BOSS] Leaves via BossArenaLeaveTeleport then returns to safe zone
        function UIX.leaveBossArena(silent)
            local c = LP.Character
            local h = hrp()
            if not c or not h then return false end

            -- USER REQUIREMENT: Portal keluar nunggu status boss mati!
            local bSnap = UIX.fetchBossSnapshot and UIX.fetchBossSnapshot()
            local hp = (bSnap and bSnap.BossHealth) or 0
            local open = bSnap and (bSnap.Open == true)
            local isDead = (bSnap and bSnap.BossHealth ~= nil and bSnap.BossHealth <= 0)
            if not isDead and hp > 0 and open then
                -- Boss masih hidup, dilarang keluar!
                return false
            end

            -- 1. Polling mencari portal keluar (server butuh 1-3 detik setelah boss mati agar portal muncul)
            local leave = UIX.findBossExitPortal and UIX.findBossExitPortal()
            local findStart = os.clock()
            while not leave and (os.clock() - findStart < 4) do
                task.wait(0.3)
                leave = UIX.findBossExitPortal and UIX.findBossExitPortal()
                if not (LP:GetAttribute("InBossArena") == true or (UIX.isInBossArena and UIX.isInBossArena())) then
                    break
                end
            end

            -- Jika sudah di luar arena dari awal, langsung return to safe zone
            local currentlyInArena = (LP:GetAttribute("InBossArena") == true) or (UIX.isInBossArena and UIX.isInBossArena())
            if not currentlyInArena then
                local shouldReturn = ST.returnAfterBoss
                if shouldReturn == nil and ST.autoBossRift then shouldReturn = true end
                if shouldReturn then
                    local safePos = STRIP
                    if (h.Position - safePos.Position).Magnitude > 10 then
                        UIX.bossGlideTo(safePos, ST.bossGlideSpeed or 350)
                    end
                    if not silent then showToast("Returned to Safe Zone!", 2) end
                end
                return true
            end

            if not leave then
                if not silent then showToast("Waiting for leave portal to spawn...", 2) end
                return false
            end

            -- 2. Kumpulkan SEMUA BaseParts dan ProximityPrompts di portal
            local touchParts = {}
            local prompts = {}
            local targetPos = nil

            if leave:IsA("BasePart") then
                table.insert(touchParts, leave)
                targetPos = leave.Position
                local p = leave:FindFirstChildWhichIsA("ProximityPrompt", true)
                if p then table.insert(prompts, p) end
            else
                for _, desc in ipairs(leave:GetDescendants()) do
                    if desc:IsA("BasePart") then
                        table.insert(touchParts, desc)
                        local n = string.lower(desc.Name)
                        if (string.find(n, "hitbox") or string.find(n, "touch") or string.find(n, "pad") or string.find(n, "root") or string.find(n, "inner")) and not targetPos then
                            targetPos = desc.Position
                        end
                    elseif desc:IsA("ProximityPrompt") then
                        table.insert(prompts, desc)
                    end
                end
                if not targetPos then
                    pcall(function() targetPos = leave:GetPivot().Position end)
                end
                if not targetPos and touchParts[1] then
                    targetPos = touchParts[1].Position
                end
            end

            if not targetPos then
                if not silent then showToast("Portal position not found", 2) end
                return false
            end

            -- 3. GLIDE masuk ke dalam portal keluar (NO raw teleport across arena!)
            local portalCenterCF = CFrame.new(targetPos + Vector3.new(0, 1.5, 0))
            if (h.Position - targetPos).Magnitude > 4 then
                UIX.bossGlideTo(portalCenterCF, ST.bossGlideSpeed or 350)
            end

            -- 4. Masuk ke pusat portal dan sentuh SEMUA parts & picu prompts
            local function triggerPortal()
                local curH = hrp()
                if not curH then return end
                curH.CanTouch = true
                if c then
                    for _, cp in ipairs(c:GetChildren()) do
                        if cp:IsA("BasePart") then pcall(function() cp.CanTouch = true end) end
                    end
                end

                curH.CFrame = CFrame.new(targetPos + Vector3.new(0, 1.2, 0))
                curH.AssemblyLinearVelocity = Vector3.new(0, -1, 0)
                
                -- Pastikan CanTouch = true pada SEMUA BasePart milik portal model
                -- (Server mematikan CanTouch = false pada Hitbox portal, sehingga wajib diaktifkan agar touch event terpicu!)
                for _, p in ipairs(touchParts) do
                    if p and p.Parent then
                        pcall(function()
                            p.CanTouch = true
                            firetouchinterest(curH, p, 0)
                            task.wait(0.02)
                            firetouchinterest(curH, p, 1)
                        end)
                    end
                end

                -- Picu semua ProximityPrompt jika ada
                for _, pr in ipairs(prompts) do
                    if pr and pr.Parent then
                        pcall(function()
                            fireproximityprompt(pr)
                        end)
                    end
                end
            end

            triggerPortal()

            -- 5. Tunggu server melakukan transfer teleportasi keluar arena (timeout 6 detik)
            local t0 = os.clock()
            local exited = false
            while os.clock() - t0 < 6 do
                if LP:GetAttribute("InBossArena") ~= true and not (UIX.isInBossArena and UIX.isInBossArena()) then
                    exited = true
                    break
                end
                triggerPortal()
                task.wait(0.2)
            end

            -- 6. EVALUASI HASIL KELUAR ARENA
            if not exited and (LP:GetAttribute("InBossArena") == true or (UIX.isInBossArena and UIX.isInBossArena())) then
                -- CRITICAL BUGFIX: JIKA BELUM KELUAR ARENA, DILARANG KERAS GLIDE KE STRIP!
                -- Memaksa nyebrang ke safe zone lewat langit dari arena (jarak 15.000 stud)
                -- menyebabkan karakter terbang melayang dan bolak-balik ditarik kembali!
                if not silent then showToast("Waiting for exit portal transfer...", 2) end
                return false
            end

            -- 7. SUDAH BERHASIL KELUAR KE LOBBY!
            if not silent then showToast("Exited Boss Arena to Lobby!", 2) end

            local shouldReturn = ST.returnAfterBoss
            if shouldReturn == nil and ST.autoBossRift then shouldReturn = true end
            if shouldReturn then
                local safePos = STRIP
                local curH = hrp()
                if curH and (curH.Position - safePos.Position).Magnitude > 10 then
                    UIX.bossGlideTo(safePos, ST.bossGlideSpeed or 350)
                end
                if not silent then showToast("Returned to Safe Zone!", 2) end
            end
            return true
        end

        -- [AUTO DESTROY CRYSTAL & HIT BOSS] CrystalTowers -> UpperHand1.R/L Hand -> Bat Swing + Touch + Remote Trigger
        -- Zero Dodge: Langsung serang Crystal aktif, lalu lanjut hajar Boss Hand tanpa kabur/menghindar
        function UIX.autoFightStep()
            if not UIX.isInBossArena() then return end
            local c = LP.Character
            local h = hrp()
            local hum = c and c:FindFirstChildOfClass("Humanoid")
            if not c or not h or not hum or hum.Health <= 0 then return end

            local arena = Workspace:FindFirstChild("BossArena")
            if not arena then return end

            local floor = arena:FindFirstChild("Floor")
            local floorY = floor and (floor.Position.Y + 3.5) or (h.Position.Y)

            -- 1. Cek CrystalTowers dulu (destroy active crystal with Health > 0)
            local towers = arena:FindFirstChild("CrystalTowers")
            local activeCrystal = nil
            if towers then
                for _, t in ipairs(towers:GetChildren()) do
                    local hb = t:FindFirstChild("Hitbox")
                    if hb then
                        local hp = hb:GetAttribute("Health")
                        if hp ~= nil and hp > 0 then
                            activeCrystal = hb
                            break
                        end
                    end
                end
            end

            local targetPart = nil
            local targetCF = nil

            if activeCrystal then
                targetPart = activeCrystal
                local floorCenter = floor and floor.Position or Vector3.new(-15094, floorY, -247)
                local dirToCenter = (Vector3.new(floorCenter.X, 0, floorCenter.Z) - Vector3.new(activeCrystal.Position.X, 0, activeCrystal.Position.Z)).Unit
                if dirToCenter.Magnitude < 0.1 then dirToCenter = Vector3.new(0, 0, 1) end

                local halfSize = (activeCrystal:IsA("BasePart") and activeCrystal.Size.X / 2) or 27.5
                -- Berdiri tepat di samping crystal menghadap crystal dalam jangkauan bat
                local standY = math.max(floorY + 2.5, activeCrystal.Position.Y)
                local outsidePos = activeCrystal.Position + dirToCenter * (halfSize + 2.5)
                outsidePos = Vector3.new(outsidePos.X, standY, outsidePos.Z)
                targetCF = CFrame.lookAt(outsidePos, activeCrystal.Position)
            else
                -- 2. Boss Hand / Bone Targeting (UpperHand1.R / UpperHand1.L) - Langsung Serang Tanpa Dodge
                local boss = arena:FindFirstChild("Boss") or arena:FindFirstChild("Abyss Overlord") or arena:FindFirstChild("AbyssOverlord")
                if not boss then
                    for _, ch in ipairs(arena:GetChildren()) do
                        if ch:IsA("Model") and (ch.Name:find("Boss") or ch.Name:find("Abyss") or ch.Name:find("Overlord")) then
                            boss = ch
                            break
                        end
                    end
                end

                if boss then
                    targetPart = boss:FindFirstChild("RootPart") or boss.PrimaryPart or boss:FindFirstChildWhichIsA("BasePart", true)
                    local bPos = targetPart and targetPart.Position or Vector3.new(-15034, 98, -146)

                    local rightHand = boss:FindFirstChild("UpperHand1.R", true)
                    local leftHand = boss:FindFirstChild("UpperHand1.L", true)

                    -- Cari tangan yang sedang di lantai arena atau bone tangan aktif
                    local activeHand = nil
                    if rightHand and rightHand:IsA("Bone") and rightHand.WorldPosition then
                        local ry = rightHand.WorldPosition.Y
                        if ry <= floorY + 8.5 then
                            activeHand = rightHand
                        end
                    end
                    if not activeHand and leftHand and leftHand:IsA("Bone") and leftHand.WorldPosition then
                        local ly = leftHand.WorldPosition.Y
                        if ly <= floorY + 8.5 then
                            activeHand = leftHand
                        end
                    end

                    if activeHand then
                        -- Tangan sedang TURUN di lantai -> Meluncur dekat tangan dan serang!
                        local hw = activeHand.WorldPosition
                        targetCF = CFrame.lookAt(Vector3.new(hw.X, floorY + 2.5, hw.Z), bPos)
                    elseif rightHand and rightHand:IsA("Bone") and rightHand.WorldPosition then
                        local hw = rightHand.WorldPosition
                        targetCF = CFrame.lookAt(Vector3.new(hw.X, math.clamp(hw.Y, floorY, floorY + 4), hw.Z), bPos)
                    elseif leftHand and leftHand:IsA("Bone") and leftHand.WorldPosition then
                        local hw = leftHand.WorldPosition
                        targetCF = CFrame.lookAt(Vector3.new(hw.X, math.clamp(hw.Y, floorY, floorY + 4), hw.Z), bPos)
                    else
                        targetCF = CFrame.lookAt(Vector3.new(bPos.X, floorY + 2.5, bPos.Z), bPos)
                    end
                end

                if not targetCF then
                    local spawnPart = arena:FindFirstChild("BossSpawn") or arena:FindFirstChild("Floor")
                    if spawnPart and spawnPart:IsA("BasePart") then
                        targetPart = spawnPart
                        targetCF = CFrame.new(spawnPart.Position + Vector3.new(0, 3.5, 0))
                    end
                end
            end

            if targetCF then
                local dist = (h.Position - targetCF.Position).Magnitude
                if dist > 4 then
                    UIX.bossGlideTo(targetCF, ST.bossGlideSpeed or 350, function()
                        return not (ST.autoBossRift or ST.autoAttackBoss) or (LP:GetAttribute("InBossArena") ~= true)
                    end)
                end
                if h and h.Parent then
                    h.CFrame = targetCF
                    h.AssemblyLinearVelocity = Vector3.zero
                    h.AssemblyAngularVelocity = Vector3.zero

                    local bat = c:FindFirstChildOfClass("Tool")
                    if not bat or not string.find(string.lower(bat.Name), "bat") then
                        bat = getBatTool()
                    end
                    if bat then
                        pcall(function() bat:Activate() end)
                        local handle = bat:FindFirstChild("Handle") or bat:FindFirstChildWhichIsA("BasePart")
                        if handle and targetPart and targetPart:IsA("BasePart") then
                            pcall(function()
                                handle.CanTouch = true
                                targetPart.CanTouch = true
                                firetouchinterest(handle, targetPart, 0)
                                task.wait(0.02)
                                firetouchinterest(handle, targetPart, 1)
                            end)
                        end
                    end
                    pcall(function()
                        _batSwingSeq = (_batSwingSeq or 0) + 1
                        local trace = string.format("%d:%d:%d", LP.UserId, _batSwingSeq, math.floor(Workspace:GetServerTimeNow() * 1000))
                        -- Direct Remote resolution bypass require() untuk kompatibilitas Delta Android & Potassium PC
                        local net = RS:FindFirstChild("Packages") and RS.Packages:FindFirstChild("Networking")
                        local batRemote = (net and net:FindFirstChild("RE/BatSwing/Trigger"))
                        if not batRemote then
                            local Rem = req(RS:FindFirstChild("Shared") and RS.Shared:FindFirstChild("Remotes"))
                            batRemote = Rem and Rem.BatSwing and Rem.BatSwing.Trigger
                        end
                        if batRemote then
                            if targetPart then
                                batRemote:FireServer(targetPart, trace)
                            else
                                batRemote:FireServer(nil, trace)
                            end
                        end
                    end)
                end
            end
        end

        function UIX.attackBossOnce()
            UIX.autoFightStep()
            showToast("Bat swing executed!")
        end

        function UIX.openBossShop()
            local ok = pcall(function()
                local Tabs = require(game:GetService("ReplicatedStorage").Client.Tabs)
                Tabs.Toggle("BossShop")
            end)
            if not ok then
                pcall(function()
                    local bs = game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("BossShop")
                    if bs then
                        bs.Enabled = not bs.Enabled
                        if bs:FindFirstChild("Main") then
                            bs.Main.Visible = bs.Enabled
                            bs.Main.Position = UDim2.new(0.5, 0, 0.5, 0)
                        end
                    end
                end)
            end
        end

        local autoBuyModal = nil
        function UIX.toggleAutoBuyModal()
            if ScreenGui:FindFirstChild("AutoBuyBossShopModal") and not autoBuyModal then
                pcall(function() ScreenGui.AutoBuyBossShopModal:Destroy() end)
            end
            if not autoBuyModal or not autoBuyModal.Parent then
                local modalWin = new("Frame", {
                    Name = "AutoBuyBossShopModal",
                    Parent = ScreenGui,
                    Size = UDim2.new(0, 420, 0, 440),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(0.5, 50, 0.5, 0),
                    BackgroundColor3 = Theme.Background,
                    BorderSizePixel = 0,
                    ZIndex = 80,
                    Visible = true,
                }, {
                    corner(12),
                    stroke(Theme.BorderLight or Color3.fromRGB(50, 50, 60), 1.5),
                })

                local topBar = new("Frame", {
                    Name = "TopBar",
                    Parent = modalWin,
                    Size = UDim2.new(1, 0, 0, 38),
                    BackgroundColor3 = Theme.TopBar,
                    BorderSizePixel = 0,
                    ZIndex = 81,
                }, {
                    corner(12),
                    new("Frame", {
                        Size = UDim2.new(1, 0, 0, 1),
                        Position = UDim2.new(0, 0, 1, -1),
                        BackgroundColor3 = Theme.Border,
                        BorderSizePixel = 0,
                        ZIndex = 82,
                    })
                })

                new("TextLabel", {
                    Parent = topBar,
                    Size = UDim2.new(1, -70, 1, 0),
                    Position = UDim2.new(0, 14, 0, 0),
                    BackgroundTransparency = 1,
                    Font = FONT_BOLD,
                    Text = "Auto Buy Boss Shop",
                    TextColor3 = Theme.Text,
                    TextSize = 15,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 83,
                })

                local closeBtn = new("TextButton", {
                    Parent = topBar,
                    Size = UDim2.fromOffset(26, 26),
                    Position = UDim2.new(1, -32, 0.5, -13),
                    BackgroundColor3 = Theme.CardHover,
                    BackgroundTransparency = 0.4,
                    AutoButtonColor = false,
                    Font = FONT_BOLD,
                    Text = "X",
                    TextColor3 = Theme.TextSecondary,
                    TextSize = 13,
                    ZIndex = 84,
                }, {
                    corner(6),
                    stroke(Theme.Border, 1, 0.5),
                })
                closeBtn.MouseButton1Click:Connect(function()
                    modalWin.Visible = false
                end)

                local dragging, dragStart, startPos = false, nil, nil
                topBar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                        dragStart = input.Position
                        startPos = modalWin.Position
                        input.Changed:Connect(function()
                            if input.UserInputState == Enum.UserInputState.End then
                                dragging = false
                            end
                        end)
                    end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        local delta = input.Position - dragStart
                        modalWin.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                    end
                end)

                local body = new("ScrollingFrame", {
                    Name = "Body",
                    Parent = modalWin,
                    Position = UDim2.new(0, 0, 0, 39),
                    Size = UDim2.new(1, 0, 1, -39),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    CanvasSize = UDim2.new(0, 0, 0, 0),
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    ScrollBarThickness = 4,
                    ScrollBarImageColor3 = Theme.Border,
                    ZIndex = 81,
                })
                new("UIListLayout", { Parent = body, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })
                new("UIPadding", { Parent = body, PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 14), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) })

                local mOrder = 0
                local function mn() mOrder = mOrder + 1; return mOrder end

                sectionLabel(body, "Live Boss Balance", mn())
                local modalBalLabel = textRow(body, "Boss Tokens: -- | Mutations: --", mn(), Theme.Money)
                local function updateModalBal()
                    local sd = SaveMod and SaveMod.Get and SaveMod.Get()
                    local tokens = sd and sd.BossTokens or 0
                    local muts = sd and sd.BossMastery and sd.BossMastery.MutationConsumables or 0
                    local sTok = tostring(math.floor(tokens))
                    while true do
                        local sTok2, k = string.gsub(sTok, "^(-?%d+)(%d%d%d)", "%1,%2")
                        sTok = sTok2
                        if k == 0 then break end
                    end
                    modalBalLabel.Text = string.format("Tokens: %s | Mutations: %d", sTok, muts)
                end
                pcall(updateModalBal)

                sectionLabel(body, "Automation Settings", mn())

                toggleRow(body, "Auto Buy Rift Shop Items (Boss Tokens)", mn(), function(on)
                    ST.riftAutoBuy = on; saveConfig()
                    if on then showToast("Auto Buy Rift Shop Items Active") end
                end, ST.riftAutoBuy)

                dropdownMulti(body, "Rift Items to Auto Buy", mn(), function()
                    return UIX.listRiftShopItems()
                end, ST.riftBuyItems, saveConfig)

                toggleRow(body, "Auto Claim Boss Milestones", mn(), function(on)
                    ST.riftAutoClaimMilestones = on; saveConfig()
                    if on then
                        showToast("Auto Claim Milestones Active")
                        task.spawn(function() UIX.claimAllBossMilestones(false) end)
                    end
                end, ST.riftAutoClaimMilestones)

                sectionLabel(body, "Quick Actions", mn())

                buttonRow(body, "Buy 1x Mutation Consumable", mn(), function()
                    UIX.buyRiftShopItem("MutationConsumable", false)
                    pcall(updateModalBal)
                end)

                buttonRow(body, "Claim All Available Milestones", mn(), function()
                    UIX.claimAllBossMilestones(false)
                    pcall(updateModalBal)
                end)

                buttonRow(body, "Open In-Game Boss Shop UI", mn(), function()
                    UIX.openBossShop()
                end)

                autoBuyModal = modalWin
                UIX.autoBuyModal = modalWin
                UIX.updateModalBal = updateModalBal
            else
                autoBuyModal.Visible = not autoBuyModal.Visible
                if autoBuyModal.Visible and UIX.updateModalBal then
                    pcall(UIX.updateModalBal)
                end
            end
        end

        -- ==================== UI RENDERING ====================
        local statusCard = sectionLabel(riftPage, "Rift Live Status & Rotation", n())

        local bannerRow = new("Frame", {
            Parent = statusCard,
            Size = UDim2.new(1, 0, 0, 26),
            LayoutOrder = n(),
            BackgroundTransparency = 1,
        })

        ui.riftBannerLabel = new("TextLabel", {
            Parent = bannerRow,
            Size = UDim2.new(1, -78, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            Font = FONT,
            Text = "Banner: Checking server...",
            TextColor3 = Theme.Money,
            TextSize = 14.5,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
        })

        local refreshBtn = new("TextButton", {
            Parent = bannerRow,
            Size = UDim2.new(0, 72, 0, 24),
            Position = UDim2.new(1, -72, 0, 1),
            BackgroundColor3 = Theme.CardHover,
            BackgroundTransparency = 0.3,
            Font = FONT,
            Text = "Refresh",
            TextColor3 = Theme.Accent,
            TextSize = 12,
            AutoButtonColor = true,
        })
        new("UICorner", { Parent = refreshBtn, CornerRadius = UDim.new(0, 5) })
        refreshBtn.MouseButton1Click:Connect(function()
            pcall(function()
                UIX.fetchRiftState(true)
                UIX.updateRiftUI()
                showToast("Rift status refreshed!")
            end)
        end)

        ui.riftTimerLabel = textRow(riftPage, "Rotation in: --", n(), Theme.SubText)
        ui.riftDemandsLabel = textRow(riftPage, "Demands: --", n(), Theme.Warn)
        ui.riftStockLabel = textRow(riftPage, "Inventory: --", n(), Theme.SubText)
        pcall(function() ui.riftStockLabel.AutomaticSize = Enum.AutomaticSize.Y end)
        ui.riftAreaLabel = textRow(riftPage, "Area: Checking...", n(), Theme.SubText)
        pcall(function() ui.riftAreaLabel.AutomaticSize = Enum.AutomaticSize.Y end)
        ui.riftPityLabel = textRow(riftPage, "Pity: --/50 | Free Rerolls: --", n(), Theme.Accent)
        ui.riftTokensLabel = textRow(riftPage, "Boss Tokens: -- | Mutations: --", n(), Theme.Money)

        dualRow(riftPage, n(),
            function(host)
                buttonRow(host, "Open Boss Shop", 1, function()
                    UIX.openBossShop()
                end)
            end,
            function(host)
                buttonRow(host, "Auto Buy Boss Shop", 1, function()
                    UIX.toggleAutoBuyModal()
                end)
            end
        )

        UIX.BANNER_COLORS = {
            Verdant = Color3.fromRGB(126, 217, 130),
            Umbral = Color3.fromRGB(168, 122, 255),
            Radiant = Color3.fromRGB(255, 205, 84)
        }

        function UIX.updateRiftUI()
            local st = UIX.riftState
            if st then

            -- 1. Banner Info
            local bId = st.BannerId or "Unknown"
            local bName = st.BannerDisplayName or bId
            local bCol = (UIX.BANNER_COLORS and UIX.BANNER_COLORS[bId]) or Theme.Money
            local hasFilter = ST.riftBanners and next(ST.riftBanners) ~= nil
            local isAllowed = UIX.isRiftBannerAllowed()
            local filterTag = hasFilter and (isAllowed and " [Selected]" or " [Ignored]") or ""

            if ui.riftBannerLabel then
                ui.riftBannerLabel.Text = string.format("Banner: [%s] %s%s", bId, bName, filterTag)
                ui.riftBannerLabel.TextColor3 = isAllowed and bCol or Theme.SubText
            end

            -- 2. Countdown Timer
            local sec = st.SecondsUntilRotation or 0
            local now = os.clock()
            if UIX.riftLastFetch > 0 then
                sec = math.max(0, sec - (now - UIX.riftLastFetch))
            end
            local h = math.floor(sec / 3600)
            local m = math.floor((sec % 3600) / 60)
            local s = math.floor(sec % 60)
            if ui.riftTimerLabel then
                ui.riftTimerLabel.Text = string.format("Rotation in: %02dh %02dm %02ds", h, m, s)
            end

            if ui.riftTokensLabel then
                local sd = SaveMod and SaveMod.Get and SaveMod.Get()
                local tokens = sd and sd.BossTokens or 0
                local muts = sd and sd.BossMastery and sd.BossMastery.MutationConsumables or 0
                local sTok = tostring(math.floor(tokens))
                while true do
                    local sTok2, k = string.gsub(sTok, "^(-?%d+)(%d%d%d)", "%1,%2")
                    sTok = sTok2
                    if k == 0 then break end
                end
                ui.riftTokensLabel.Text = string.format("Boss Tokens: %s | Mutations: %d", sTok, muts)
            end

            if UIX.updateModalBal then
                pcall(UIX.updateModalBal)
            end

            -- 3. Demands & Inventory Stock
            local reqs = st.Requirements or {}
            local _, counts = UIX.findPetsForRift(reqs)
            if ui.riftDemandsLabel then
                ui.riftDemandsLabel.Text = "Demands: " .. (#reqs > 0 and table.concat(reqs, " • ") or "None")
            end

            local sd = SaveMod and SaveMod.Get and SaveMod.Get()
            local stockEntries = {}
            local allPetsReady = (#reqs == 3)
            local totalPendingEggs = 0
            for _, rName in ipairs(reqs) do
                local rLower = tostring(rName):lower():match("^%s*(.-)%s*$")
                local petCount = 0
                local eggCount = 0

                if sd then
                    for _, p in pairs(sd.Inventory or sd.PetInventory or {}) do
                        if type(p) == "table" and (p.Locked ~= true and p.Favorite ~= true and p.IsFavorite ~= true and p.Equipped ~= true) then
                            local cat = p.Category or p.AssetCategory or p.Name or (p.ItemData and p.ItemData.Category)
                            local cLower = cat and tostring(cat):lower():match("^%s*(.-)%s*$")
                            if cLower == rLower then petCount = petCount + 1 end
                        end
                    end
                    for _, e in pairs(sd.EggInventory or {}) do
                        if type(e) == "table" then
                            local cat = e.AssetCategory or e.Category or (e.ItemData and e.ItemData.Category)
                            local cLower = cat and tostring(cat):lower():match("^%s*(.-)%s*$")
                            if cLower == rLower then eggCount = eggCount + 1 end
                        end
                    end
                end

                if petCount == 0 then allPetsReady = false end
                totalPendingEggs = totalPendingEggs + eggCount

                local entry = string.format("%s: %d pets", rName, petCount)
                if eggCount > 0 then entry = entry .. string.format(" (+%d eggs)", eggCount) end
                table.insert(stockEntries, entry)
            end

            if ui.riftStockLabel then
                local stockStr = #stockEntries > 0 and table.concat(stockEntries, " | ") or "--"
                if allPetsReady then
                    ui.riftStockLabel.Text = "Inventory: " .. stockStr .. "  ✅ [Ready to Trade-In]"
                    ui.riftStockLabel.TextColor3 = Color3.fromRGB(100, 255, 120)
                elseif totalPendingEggs > 0 then
                    local eggWord = totalPendingEggs == 1 and "egg is" or "eggs are"
                    ui.riftStockLabel.Text = "Inventory: " .. stockStr .. "\n⚠️ Recipe " .. eggWord .. " still unhatched! Must hatch into pets before Trade-In."
                    ui.riftStockLabel.TextColor3 = Color3.fromRGB(255, 185, 80)
                else
                    ui.riftStockLabel.Text = "Inventory: " .. stockStr
                    ui.riftStockLabel.TextColor3 = Theme.SubText
                end
            end

            -- 3b. Demands Available in Game Areas (Live Field Snapshot)
            if ui.riftAreaLabel then
                local fieldRecs = {}
                pcall(function()
                    if EggStateMod and EggStateMod.ReadFieldEggs then
                        local snap = EggStateMod.ReadFieldEggs()
                        if snap and snap.Records and #snap.Records > 0 then fieldRecs = snap.Records end
                    elseif EggCmds and EggCmds.GetAreaEggSnapshot then
                        local snap = EggCmds.GetAreaEggSnapshot()
                        if snap and snap.Records and #snap.Records > 0 then fieldRecs = snap.Records end
                    end
                    if #fieldRecs == 0 then
                        local RS = game:GetService("ReplicatedStorage")
                        pcall(function()
                            local rsMod = require(RS.Client.EggState)
                            if rsMod and rsMod.ReadFieldEggs then
                                local snap = rsMod.ReadFieldEggs()
                                if snap and snap.Records and #snap.Records > 0 then fieldRecs = snap.Records end
                            end
                        end)
                    end
                    if #fieldRecs == 0 then
                        local RS = game:GetService("ReplicatedStorage")
                        pcall(function()
                            local RemotesMod = require(RS.Shared.Remotes)
                            local snap = RemotesMod and RemotesMod.EggWorld and RemotesMod.EggWorld.AskFieldEggSnapshot and RemotesMod.EggWorld.AskFieldEggSnapshot:InvokeServer()
                            if snap and snap.Records and #snap.Records > 0 then fieldRecs = snap.Records end
                        end)
                    end
                end)

                local myUid = (LocalPlayer and LocalPlayer.UserId) or (game:GetService("Players").LocalPlayer and game:GetService("Players").LocalPlayer.UserId)
                local areaEntries = {}
                local hasAnyInArea = false
                for _, rName in ipairs(reqs) do
                    local rLower = tostring(rName):lower():match("^%s*(.-)%s*$")
                    local cnt = 0
                    local areaSet = {}
                    for _, r in ipairs(fieldRecs) do
                        local cat = r.AssetCategory or r.Category or (r.ItemData and r.ItemData.Category)
                        local cLower = cat and tostring(cat):lower():match("^%s*(.-)%s*$")
                        if cLower == rLower and (r.State == "Slot" or r.State == "Dropped") and (not r.CarrierUserId or r.CarrierUserId == myUid) then
                            cnt = cnt + 1
                            local a = r.AreaId or "Unknown"
                            areaSet[a] = true
                        end
                    end
                    if cnt > 0 then
                        hasAnyInArea = true
                        local aList = {}
                        for a in pairs(areaSet) do table.insert(aList, a) end
                        table.sort(aList)
                        local aStr = " in " .. table.concat(aList, "/")
                        table.insert(areaEntries, string.format("%s (%d%s)", rName, cnt, aStr))
                    else
                        table.insert(areaEntries, string.format("%s (0)", rName))
                    end
                end

                ui.riftAreaLabel.Text = "Area: " .. (#areaEntries > 0 and table.concat(areaEntries, " | ") or "--")
                ui.riftAreaLabel.TextColor3 = hasAnyInArea and Color3.fromRGB(100, 220, 255) or Theme.SubText
            end

            -- 4. Pity & Rerolls
            local pity = st.PityCount or 0
            local pThresh = st.PityThreshold or 50
            local freeRerolls = st.FreeRefreshesRemaining or 0
            if ui.riftPityLabel then
                ui.riftPityLabel.Text = string.format("Pity: %d/%d (Guaranteed Pool) | Free Rerolls: %d", pity, pThresh, freeRerolls)
            end

            end

            -- 5. Boss Event Info (Runs independently of riftState)
            local bSnap = UIX.fetchBossSnapshot()
            local nowS = workspace:GetServerTimeNow()
            if bSnap then
                local bOpen = bSnap.Open == true
                local bHp = bSnap.BossHealth or 0
                local bMax = bSnap.BossMaxHealth or 7000
                local bCloses = bSnap.ClosesAt or 0
                local bOpens = bSnap.OpensAt or 0

                if ui.bossStatusLabel then
                    if bOpen and bHp > 0 then
                        ui.bossStatusLabel.Text = "Boss: Abyss Overlord (PORTAL OPEN!)"
                        ui.bossStatusLabel.TextColor3 = Color3.fromRGB(255, 60, 60)
                    elseif bOpen and bHp <= 0 then
                        ui.bossStatusLabel.Text = "Boss: DEFEATED (Arena Closing)"
                        ui.bossStatusLabel.TextColor3 = Color3.fromRGB(255, 205, 84)
                    else
                        ui.bossStatusLabel.Text = "Boss: Abyss Overlord (Portal Closed)"
                        ui.bossStatusLabel.TextColor3 = Theme.SubText
                    end
                end

                if ui.bossHpLabel then
                    if bOpen then
                        local pct = bMax > 0 and math.floor((bHp / bMax) * 100) or 0
                        ui.bossHpLabel.Text = string.format("Boss HP: %d / %d (%d%%)", bHp, bMax, pct)
                        ui.bossHpLabel.TextColor3 = bHp > 0 and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(100, 255, 120)
                    else
                        ui.bossHpLabel.Text = "Boss HP: Waiting for spawn..."
                        ui.bossHpLabel.TextColor3 = Theme.SubText
                    end
                end

                if ui.bossTimerLabel then
                    if bOpen and bHp > 0 then
                        local rem = math.max(0, bCloses - nowS)
                        ui.bossTimerLabel.Text = string.format("Portal closes in: %02dm %02ds", math.floor(rem / 60), math.floor(rem % 60))
                        ui.bossTimerLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
                    else
                        local nextSec = (bOpens > nowS) and (bOpens - nowS) or (1800 - (nowS % 1800))
                        ui.bossTimerLabel.Text = string.format("Next Boss in: %02dm %02ds", math.floor(nextSec / 60), math.floor(nextSec % 60))
                        ui.bossTimerLabel.TextColor3 = Theme.SubText
                    end
                end
            else
                local nextSec = 1800 - (nowS % 1800)
                if ui.bossStatusLabel then
                    ui.bossStatusLabel.Text = "Boss: Abyss Overlord (Portal Closed)"
                    ui.bossStatusLabel.TextColor3 = Theme.SubText
                end
                if ui.bossHpLabel then
                    ui.bossHpLabel.Text = "Boss HP: Waiting for spawn..."
                    ui.bossHpLabel.TextColor3 = Theme.SubText
                end
                if ui.bossTimerLabel then
                    ui.bossTimerLabel.Text = string.format("Next Boss in: %02dm %02ds", math.floor(nextSec / 60), math.floor(nextSec % 60))
                    ui.bossTimerLabel.TextColor3 = Theme.SubText
                end
            end
        end

        sectionLabel(riftPage, "Automation", n())

        toggleRow(riftPage, "Auto Trade-In (Sacrifice)", n(), function(on)
            ST.riftAutoTrade = on; saveConfig()
            if on then showToast("Auto Trade-In Active") end
        end, ST.riftAutoTrade)

        toggleRow(riftPage, "Auto Free Reroll If Missing Pets", n(), function(on)
            ST.riftAutoReroll = on; saveConfig()
            if on then showToast("Auto Free Reroll Active") end
        end, ST.riftAutoReroll)

        toggleRow(riftPage, "Prioritize Rift Pets in Auto Steal", n(), function(on)
            ST.riftPrioritizeSteal = on
            if on then
                ST._searchExhausted = false
                pcall(function() if UIX.fetchRiftState then UIX.fetchRiftState(true) end end)
                task.spawn(function()
                    task.wait(0.2)
                    if UIX.placeRiftEggsToPen then
                        UIX.placeRiftEggsToPen(false)
                    end
                end)
            end
            saveConfig()
            if on then showToast("Auto Steal will prioritize Rift Recipe Eggs!") end
        end, ST.riftPrioritizeSteal)

        dropdownMulti(riftPage, "Target Banners (none = all)", n(), function()
            return itemsOf(UIX.listRiftBanners())
        end, ST.riftBanners, function()
            saveConfig()
            if UIX.updateRiftUI then UIX.updateRiftUI() end
        end)

        -- ==================== BOSS RIFT SECTION ====================
        sectionLabel(riftPage, "Boss Rift (Abyss Overlord)", n())

        ui.bossStatusLabel = textRow(riftPage, "Boss: Checking status...", n(), Theme.Money)
        ui.bossTimerLabel = textRow(riftPage, "Next Boss in: --", n(), Theme.SubText)
        ui.bossHpLabel = textRow(riftPage, "Boss HP: --", n(), Theme.Warn)
        pcall(function() if UIX.updateRiftUI then UIX.updateRiftUI() end end)

        local toggleReturnAfterBoss
        local toggleAttackBoss

        toggleRow(riftPage, "Auto Boss Rift (Enter & Fight)", n(), function(on)
            ST.autoBossRift = on
            if on then
                ST.returnAfterBoss = true
                ST.autoAttackBoss = true
                if toggleReturnAfterBoss and toggleReturnAfterBoss.Set then
                    toggleReturnAfterBoss.Set(true)
                end
                if toggleAttackBoss and toggleAttackBoss.Set then
                    toggleAttackBoss.Set(true)
                end
                showToast("Auto Boss Rift Active (Fight & Safe Zone Return ON)!")
            end
            saveConfig()
        end, ST.autoBossRift)

        toggleAttackBoss = toggleRow(riftPage, "Auto Destroy Crystals & Hit Boss", n(), function(on)
            ST.autoAttackBoss = on; saveConfig()
        end, ST.autoAttackBoss)

        toggleReturnAfterBoss = toggleRow(riftPage, "Auto Return to Safe Zone After Boss", n(), function(on)
            ST.returnAfterBoss = on; saveConfig()
        end, ST.returnAfterBoss)

        sliderRow(riftPage, "Boss Glide Speed (studs/s)", n(), 150, 450, ST.bossGlideSpeed or 350, function(v)
            ST.bossGlideSpeed = v
            saveConfig()
        end, " studs/s")

        buttonRow(riftPage, "Enter Boss Arena Now", n(), function()
            UIX.enterBossArena(false)
        end)

        buttonRow(riftPage, "Leave Boss Arena (To Safe Zone)", n(), function()
            UIX.leaveBossArena()
        end)

        buttonRow(riftPage, "Manual Attack (Equip Bat & Swing)", n(), function()
            UIX.attackBossOnce()
        end)

        sectionLabel(riftPage, "Quick Actions", n())

        buttonRow(riftPage, "Place Rift Eggs to Pen", n(), function()
            UIX.placeRiftEggsToPen()
        end)

        buttonRow(riftPage, "Instant Trade-In Once", n(), function()
            UIX.doRiftTradeIn(false)
        end)

        buttonRow(riftPage, "Use Free Reroll Now", n(), function()
            UIX.doRiftReroll(false)
        end)

        buttonRow(riftPage, "Buy 1x Mutation Consumable", n(), function()
            UIX.buyRiftShopItem("MutationConsumable", false)
        end)

        buttonRow(riftPage, "Claim All Available Milestones", n(), function()
            UIX.claimAllBossMilestones(false)
        end)

        buttonRow(riftPage, "Teleport to Rift Machine", n(), function()
            UIX.teleportToRift()
        end)

        buttonRow(riftPage, "Refresh Status", n(), function()
            UIX.fetchRiftState(true)
            UIX.updateRiftUI()
            showToast("Rift Status Refreshed!")
        end)

        sectionLabel(riftPage, "Session Stats", n())

        ui.riftStats = statTiles(riftPage, n(), {
            { key = "riftTrades", label = "Rift Sacrifices", color = Color3.fromRGB(196, 130, 255) },
        })

        -- Listener BannerRotated
        pcall(function()
            local rems = getRiftRemotes()
            if rems.BannerRotated then
                rems.BannerRotated.OnClientEvent:Connect(function()
                    UIX.fetchRiftState(true)
                    UIX.updateRiftUI()
                    showToast("The Rift has rotated to a new Banner!", 4)
                end)
            end
        end)

        -- Listener BossEvent.HealthShifted & StateShifted (Realtime Boss UI)
        pcall(function()
            local Rem = req(RS:FindFirstChild("Shared") and RS.Shared:FindFirstChild("Remotes"))
            local hpShifted = Rem and Rem.BossEvent and Rem.BossEvent.HealthShifted
            local stateShifted = Rem and Rem.BossEvent and Rem.BossEvent.StateShifted
            if not hpShifted then
                local net = RS:FindFirstChild("Packages") and RS.Packages:FindFirstChild("Networking")
                hpShifted = net and net:FindFirstChild("RE/BossEvent/HealthShifted")
                stateShifted = net and net:FindFirstChild("RE/BossEvent/StateShifted")
            end
            if hpShifted then
                hpShifted.OnClientEvent:Connect(function(newHp)
                    if UIX.bossSnapshot then
                        UIX.bossSnapshot.BossHealth = tonumber(newHp) or UIX.bossSnapshot.BossHealth
                        if (tonumber(newHp) or 0) <= 0 then
                            UIX.bossSnapshot.Open = false
                        end
                    end
                    if UIX.updateRiftUI then UIX.updateRiftUI() end
                end)
            end
            if stateShifted then
                stateShifted.OnClientEvent:Connect(function()
                    UIX.fetchBossSnapshot(true)
                    if UIX.updateRiftUI then UIX.updateRiftUI() end
                end)
            end
        end)

        -- Initial Fetch
        task.defer(function()
            UIX.fetchRiftState(true)
            UIX.updateRiftUI()
        end)

        -- Background loop untuk Automation (Trade-In, Reroll, & Auto Boss)
        task.spawn(function()
            while alive() do
                task.wait(1.2)
                if ST.riftAutoTrade or ST.riftAutoReroll then
                    local st = UIX.fetchRiftState(false)
                    if st and st.Requirements and #st.Requirements == 3 then
                        local uids, counts = UIX.findPetsForRift(st.Requirements)
                        if uids and #uids == 3 then
                            if ST.riftAutoTrade then
                                UIX.doRiftTradeIn(true)
                                task.wait(1.5)
                            end
                        else
                            if ST.riftAutoReroll and (st.FreeRefreshesRemaining or 0) > 0 then
                                UIX.doRiftReroll(true)
                                task.wait(2)
                            end
                        end
                    end
                end

                -- Auto Buy Rift Items (Boss Tokens)
                if ST.riftAutoBuy then
                    local sd = SaveMod and SaveMod.Get and SaveMod.Get()
                    local tokens = sd and sd.BossTokens or 0
                    local itemPrices = {
                        { id = "MutationConsumable", price = 400 },
                        { id = "TreadmillBooster", price = 200 },
                        { id = "SpeedBoost", price = 225 },
                        { id = "CashBooster", price = 175 },
                    }
                    local buyItems = ST.riftBuyItems or { MutationConsumable = true }
                    local batchLimit = 5
                    local boughtAny = false
                    for _, item in ipairs(itemPrices) do
                        if buyItems[item.id] == true then
                            while batchLimit > 0 and tokens >= item.price do
                                local bought = UIX.buyRiftShopItem(item.id, true)
                                if bought then
                                    tokens = tokens - item.price
                                    batchLimit = batchLimit - 1
                                    boughtAny = true
                                    task.wait(0.15)
                                else
                                    break
                                end
                            end
                        end
                        if batchLimit <= 0 then break end
                    end
                    if boughtAny and UIX.updateRiftUI then
                        pcall(UIX.updateRiftUI)
                    end
                end

                -- Auto Claim Boss Milestones
                if ST.riftAutoClaimMilestones then
                    pcall(function()
                        UIX.claimAllBossMilestones(true)
                    end)
                end

                -- (Boss Rift Automation dipindah ke loop khusus di bawah — di sini
                --  ke-throttle task.wait(1.2), jauh kelewat lambat buat fight.)
            end
        end)

        -- ===== BOSS RIFT AUTOMATION =====
        task.spawn(function()
            local bSnap, snapAt, sawBoss = nil, 0, false
            while EPOCH == gg.__STEALFIX_EPOCH do
                if alive() then
                local bossActive = (ST.autoBossRift or ST.autoAttackBoss)
                if not bossActive then
                    task.wait(0.5)
                else
                    local now = os.clock()
                    if not bSnap or (now - snapAt) > 1.0 then
                        bSnap = UIX.fetchBossSnapshot()
                        snapAt = now
                    end
                    local open = bSnap and (bSnap.Open == true)
                    local hp = (bSnap and bSnap.BossHealth) or 0
                    if hp > 0 then sawBoss = true end
                    local bossDead = (sawBoss and hp <= 0) or (bSnap and bSnap.BossHealth ~= nil and bSnap.BossHealth <= 0 and not open)

                    local inArena = (LP:GetAttribute("InBossArena") == true) or (UIX.isInBossArena and UIX.isInBossArena())
                    local portalUp = Workspace:FindFirstChild("BossArenaTeleport") ~= nil

                    if open and not bossDead and (inArena or portalUp) then
                        if not inArena then
                            if ST.autoBossRift then
                                -- USER: nunggu wall putih down sebelum masuk portal
                                if wallSealed and wallSealed() then
                                    ST.activity = "boss: waiting for white wall to drop"
                                    waitWallOpen(15)
                                end
                                if not (wallSealed and wallSealed()) then
                                    ST.activity = "boss: entering portal (glide)"
                                    pcall(UIX.enterBossArena, true)
                                    snapAt = 0
                                end
                            end
                            task.wait(0.5)
                        else
                            ST.activity = "boss: crystals / hitting boss"
                            pcall(UIX.autoFightStep)
                            task.wait(0.1)
                        end
                    elseif inArena then
                        local shouldReturn = ST.returnAfterBoss
                        if shouldReturn == nil or ST.autoBossRift then shouldReturn = true end
                        -- USER: kalau portal keluar nunggu boss status nya mati!
                        if bossDead and shouldReturn then
                            ST.activity = "boss: defeated - entering exit portal (glide)"
                            task.wait(0.8)
                            local ok, res = pcall(UIX.leaveBossArena, true)
                            if ok and res == true then
                                sawBoss = false
                            end
                        elseif not open and not sawBoss and shouldReturn then
                            ST.activity = "boss: arena closed - entering exit portal (glide)"
                            task.wait(0.5)
                            local ok, res = pcall(UIX.leaveBossArena, true)
                            if ok and res == true then
                                sawBoss = false
                            end
                        else
                            -- Boss masih hidup! Terus serang crystals / boss hand!
                            ST.activity = "boss: crystals / hitting boss"
                            pcall(UIX.autoFightStep)
                            task.wait(0.1)
                        end
                        task.wait(0.5)
                    else
                        task.wait(0.5)
                    end
                end
            else
                task.wait(0.5)
            end
        end
    end)

        -- Background loop untuk UI Timer updates
        task.spawn(function()
            while alive() do
                task.wait(1)
                pcall(function()
                    if UIX.updateRiftUI then
                        UIX.updateRiftUI()
                    end
                end)
            end
        end)
    end


return riftPage
