
local LEPAS = false

local Players = game:GetService("Players")
local RS = game:GetService("RunService")
local ws = workspace
local LP = Players.LocalPlayer

-- MARGIN 0: dengan 6, garis safe zone (y73) -> telur (y72) ikut kena lantai
-- `BOTTOM` (sampai y66+6) dan titik antara tidak pernah terpilih. Terukur
-- MCP 6/6 hidup dengan 0.
local KV = { MARGIN = 0, TAHAN = 0.2, TAHAN_UJUNG = 0.15, kotak = nil }
-- Titik antara telur <-> pohon (terukur, lihat `R.Boost` di bawah).
KV.UJUNG = Vector3.new(4320, 74, -362)
KV.ANTARA = {
    Vector3.new(515, 73, -362),
    Vector3.new(471, 76, -283),
}

function KV.Kotak()
    if KV.kotak and #KV.kotak > 0 then
        local utuh = true
        for _, b in ipairs(KV.kotak) do
            if not b.part.Parent then utuh = false break end
        end
        if utuh then return KV.kotak end
    end
    local out = {}
    local c = ws:FindFirstChild("World")
    c = c and c:FindFirstChild("Build")
    c = c and c:FindFirstChild("1")
    c = c and c:FindFirstChild("COLLISIONS")
    c = c and c:FindFirstChild("COLL2")
    if c then
        local m = Vector3.new(KV.MARGIN, KV.MARGIN, KV.MARGIN)
        for _, d in ipairs(c:GetDescendants()) do
            if d:IsA("BasePart") then
                out[#out + 1] = { part = d, cf = d.CFrame, h = d.Size / 2 + m }
            end
        end
    end
    KV.kotak = out
    return out
end

-- Uji slab segmen vs kotak berorientasi.
local function potong(a, b, box)
    local la = box.cf:PointToObjectSpace(a)
    local d = box.cf:PointToObjectSpace(b) - la
    local t0, t1 = 0, 1
    for _, ax in ipairs({ "X", "Y", "Z" }) do
        local p, v, hh = la[ax], d[ax], box.h[ax]
        if math.abs(v) < 1e-9 then
            if p < -hh or p > hh then return false end
        else
            local u0, u1 = (-hh - p) / v, (hh - p) / v
            if u0 > u1 then u0, u1 = u1, u0 end
            if u0 > t0 then t0 = u0 end
            if u1 < t1 then t1 = u1 end
            if t0 > t1 then return false end
        end
    end
    return true
end

function KV.Bersih(a, b)
    for _, box in ipairs(KV.Kotak()) do
        if potong(a, b, box) then return false end
    end
    return true
end

-- Titik antara pertama yang membuat a -> W -> b bersih; nil kalau a -> b
-- sudah bersih atau tidak ada yang cocok.
function KV.Antara(a, b)
    if KV.Bersih(a, b) then return nil end
    for _, w in ipairs(KV.ANTARA) do
        if KV.Bersih(a, w) and KV.Bersih(w, b) then return w end
    end
    return nil
end

local function hrp()
    local ch = LP.Character
    return ch and ch:FindFirstChild("HumanoidRootPart")
end

-- Semua ENG yang masih hidup di memori (SAE lama yang belum dibuang juga).
local daftar = {}
for _, v in ipairs(getgc(true)) do
    if type(v) == "table" and rawget(v, "FLOW") and rawget(v, "RUANG") and rawget(v, "TM") then
        daftar[#daftar + 1] = v
    end
end

local function pasang(ENG)
    local R = ENG.RUANG
    local asli = rawget(R, "BoostAsli") or R.Boost
    if type(asli) ~= "function" then return false end
    R.BoostAsli = asli
    if LEPAS then
        R.Boost = asli
        R.BoostAsli = nil
        ENG.KV = nil
        return true
    end
    ENG.KV = KV
    -- Urutan Teleport Steal ditulis ulang di sini (aslinya `tahanDi` lokal,
    -- tidak bisa disisipi dari luar). Sama dengan file utama, plus:
    --   1. titik antara sebelum ke telur kalau garisnya memotong kotak;
    --   2. telur <-> pohon lewat UJUNG JALUR (4320,-362). Garis telur ->
    --      pohon memotong `WALL RIGHT`; terukur MCP lurus mati 2/5, lewat
    --      ujung jalur hidup 15/15 (5 telur x 2 + 5).
    R.Boost = function(tujuan, ...)
        local ts = ENG.FLOW and ENG.FLOW.MilikAutoSteal and not ENG.FLOW.MilikAutoSteal()
        if not (ts and typeof(tujuan) == "Vector3") then return asli(tujuan, ...) end
        R.T = {}
        local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if not (hrp() and h) then return false end
        local T = R.TS or {}
        local telur = CFrame.new(tujuan + Vector3.new(0, 1.2, 0))
        local function tahanDi(cf, detik)
            local batas = os.clock() + detik
            while os.clock() < batas do
                if not ENG.Running then return false end
                local rr = hrp()
                if not (rr and rr.Parent) then return false end
                ENG.Tulis(rr, cf, false)
                pcall(ENG.SpoofNow)
                RS.Heartbeat:Wait()
            end
            return true
        end
        local ok, sampai = pcall(function()
            ENG.SpoofStart()
            pcall(ENG.PadStart)
            RS.PreSimulation:Wait()
            local pohon = Vector3.new(5846.0, 17010.1, 15699.4)
            pcall(function()
                local m = ws.World.Build.EnchantedTreeInterior.Markers.Spawn
                if m and m:IsA("BasePart") then pohon = m.Position end
            end)
            local r0 = hrp()
            if (T.DIAM or 0) > 0 and not tahanDi(r0.CFrame, T.DIAM) then return false end
            local w = KV.Antara(hrp().Position, telur.Position)
            if w then
                KV.terakhir = ("antara %d,%d,%d @%.1f"):format(w.X, w.Y, w.Z, os.clock())
                if not tahanDi(CFrame.new(w), KV.TAHAN) then return false end
            end
            if not tahanDi(telur, T.TELUR or 0.48) then return false end
            local x = (not KV.Bersih(telur.Position, pohon)) and KV.UJUNG or nil
            local cfX = x and CFrame.new(x)
            if cfX and not tahanDi(cfX, KV.TAHAN_UJUNG) then return false end
            if not tahanDi(CFrame.new(pohon), T.POHON or 0.18) then return false end
            if cfX and not tahanDi(cfX, KV.TAHAN_UJUNG) then return false end
            if not tahanDi(telur, T.BALIK or 0.18) then return false end
            return true
        end)
        if not (ok and sampai) then return false end
        local rNow = hrp()
        local jarak = rNow and ((rNow.Position - tujuan) * Vector3.new(1, 0, 1)).Magnitude or 1e9
        R.T.jarak = math.floor(jarak)
        R.T.jalur = "boost_tree_sky_kv"
        return jarak <= (R.BOOST_DEKAT or 12), jarak
    end
    return true
end

local n = 0
for _, ENG in ipairs(daftar) do
    if pcall(pasang, ENG) then n = n + 1 end
end
LP:SetAttribute("__kvAddon", (LEPAS and "lepas " or "pasang ") .. n)
task.delay(5, function() LP:SetAttribute("__kvAddon", nil) end)
